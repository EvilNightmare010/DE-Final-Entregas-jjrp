# Final de Ingeniería de Datos, punto 1: entregas con S3, Glue y Athena (partition projection)

Estudiante: Juan José R. P. (`jjrp`). Todos los recursos de AWS llevan `jjrp` en el nombre.

## Arquitectura

CSV locales → Amazon S3 (`entregas/`) → tabla externa en Glue Data Catalog con partition projection → Amazon Athena → Amazon S3 (`resultados-athena/`).

Todo se define con Terraform en `infraestructura/`. Las consultas están en `consultas/`, los resultados de Athena en `resultados/` y las evidencias en `evidencias/`.

## Prerrequisitos

- Ubuntu 22.04 (WSL2), Terraform >= 1.5, AWS CLI v2 y Python 3.
- Credenciales de AWS configuradas en la terminal para el usuario IAM `de-gr02-user-5` (cuenta `802655955683`). No se incluyen en el repositorio.
- Región: `us-east-2`.

```bash
aws sts get-caller-identity
aws configure get region
terraform version
```

## Recursos creados

| Recurso | Nombre |
| --- | --- |
| Bucket S3 privado | `entregas-jjrp-802655955683` |
| Prefijos | `entregas/` y `resultados-athena/` |
| Base de datos Glue | `entregas_jjrp_db` |
| Tabla externa Glue | `entregas_jjrp` (clave de partición `fecha`, tipo `string`) |
| Workgroup Athena | `entregas-jjrp-wg` (resultados en `s3://<bucket>/resultados-athena/`) |

La tabla usa `LazySimpleSerDe` con coma como separador y `skip.header.line.count=1`. Las propiedades de partition projection son: `projection.fecha.type=date`, formato `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, intervalo 1 `DAYS` y `storage.location.template=s3://<bucket>/entregas/fecha=${fecha}/`.

## Pasos

Todos los comandos se ejecutan desde la raíz del repositorio.

### 1. Despliegue

```bash
cd infraestructura
terraform init
terraform validate
terraform apply -auto-approve -no-color 2>&1 | tee ../evidencias/aplicacion_terraform.txt
terraform output -json > ../evidencias/outputs.json
cd ..
BUCKET=$(python3 -c "import json;print(json.load(open('evidencias/outputs.json'))['bucket']['value'])")
echo "$BUCKET"
```

### 2. Carga inicial: solo los días 1 y 2

```bash
aws s3 cp data/entregas/fecha=2026-10-01/entregas.csv s3://$BUCKET/entregas/fecha=2026-10-01/entregas.csv
aws s3 cp data/entregas/fecha=2026-10-02/entregas.csv s3://$BUCKET/entregas/fecha=2026-10-02/entregas.csv
aws s3 ls s3://$BUCKET/entregas/ --recursive
```

### 3. Consultas iniciales

```bash
python3 scripts/ejecutar_athena.py inicial consultas/verificacion_inicial.sql \
  resultados/inicial/verificacion_total_registros.csv resultados/inicial/verificacion_dia3_sin_datos.csv
python3 scripts/ejecutar_athena.py inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
python3 scripts/ejecutar_athena.py inicial consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
python3 scripts/ejecutar_athena.py inicial consultas/duracion_promedio_2026-10-02.sql resultados/inicial/duracion_promedio_2026-10-02.csv
bash scripts/comparar_resultados.sh inicial
```

La tabla devuelve 12 registros y el día 3 devuelve 0, aunque su fecha ya esté dentro del rango proyectado.

### 4. Nueva fecha: día 3 (solo subir el archivo y consultar)

```bash
aws s3 cp data/entregas/fecha=2026-10-03/entregas.csv s3://$BUCKET/entregas/fecha=2026-10-03/entregas.csv
python3 scripts/ejecutar_athena.py final consultas/verificacion_tercer_dia.sql \
  resultados/final/verificacion_tercer_dia.csv resultados/final/verificacion_conteo_estados_tercer_dia.csv resultados/final/verificacion_total_registros.csv
python3 scripts/ejecutar_athena.py final consultas/intentos_por_fecha_estado.sql resultados/final/intentos_por_fecha_estado.csv
python3 scripts/ejecutar_athena.py final consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/final/porcentaje_exito_por_fecha_ciudad.csv
bash scripts/comparar_resultados.sh final
```

No se ejecutaron crawlers, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`, y no se modificó Terraform ni la tabla. Ahora la tabla contiene 18 registros y los seis del 2026-10-03.

Cada ejecución queda registrada en `evidencias/ejecuciones_athena.csv` con las columnas `etapa`, `archivo_sql`, `id_ejecucion` y `archivo_resultado`.

### 5. Limpieza (después de guardar las evidencias y hacer commit)

```bash
cd infraestructura
terraform destroy -auto-approve -no-color 2>&1 | tee ../evidencias/eliminacion_terraform.txt
cd ..
```

El bucket y el workgroup se crean con `force_destroy = true`, de modo que Terraform los elimina aunque contengan datos y resultados de Athena. Después de la limpieza, `aws s3 ls` ya no debe mostrar el bucket.

## Estructura

```text
README.md  .gitignore  respuestas.md
infraestructura/  principal.tf  variables.tf  salidas.tf
consultas/        *.sql
resultados/       inicial/  final/
evidencias/       aplicacion_terraform.txt  outputs.json  ejecuciones_athena.csv  eliminacion_terraform.txt
scripts/          ejecutar_athena.py  comparar_resultados.sh
data/  resultados_esperados/   (material suministrado, sin modificar)
```
