# Respuestas conceptuales

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla de Glue se creó con *partition projection* desde el despliegue inicial. Esa configuración (`projection.fecha.type = date`, formato `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, intervalo de 1 día y plantilla `s3://<bucket>/entregas/fecha=${fecha}/`) le dice a Athena cómo calcular los valores de `fecha` y su ubicación en S3 en el momento de la consulta, sin leer particiones registradas en el catálogo. El 3 de octubre ya estaba dentro del rango proyectado desde el principio; solo faltaba el objeto en S3. Al subir `entregas/fecha=2026-10-03/entregas.csv`, Athena encontró el archivo en la ubicación proyectada y lo leyó. No fue necesario un crawler, `MSCK REPAIR TABLE`, `ALTER TABLE ADD PARTITION` ni cambios en Terraform. La evidencia está en `evidencias/aplicacion_terraform.txt` (no se crearon particiones), en `resultados/inicial/` (12 registros, sin datos del día 3) y en `resultados/final/` (18 registros y los seis del 2026-10-03), con los identificadores de ejecución en `evidencias/ejecuciones_athena.csv`.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

Con la configuración actual no se vería en las consultas. El archivo quedaría guardado en S3, pero `2026-10-04` está fuera del rango proyectado (`2026-10-01` a `2026-10-03`), así que Athena no calcula esa partición. Las consultas no darían error: simplemente seguirían devolviendo los 18 registros y los mismos resultados agregados, sin ninguna fila del 4 de octubre. Para incluirlo habría que ampliar el rango en la propiedad `projection.fecha.range` de la tabla, es decir, cambiar la variable `fecha_final` a `2026-10-04` en Terraform y aplicar el cambio (`terraform apply`). Esto actualiza solo los metadatos de la tabla. El archivo debe respetar la ruta `entregas/fecha=2026-10-04/entregas.csv` y el mismo esquema de cinco columnas. Otra opción es usar `NOW` como fin del rango (`2026-10-01,NOW`), para que las fechas nuevas se incluyan solas, aunque entonces se proyectarían días sin datos.

---

**Hilo de la IA usado en este examen:** https://claude.ai/share/6c21f893-2e1b-4caf-bf0c-c2350794994c
