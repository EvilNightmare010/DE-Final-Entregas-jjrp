#!/usr/bin/env python3
"""Ejecuta las sentencias de un archivo SQL en Athena, guarda cada resultado como CSV
y registra la ejecucion en evidencias/ejecuciones_athena.csv.

Uso: python3 scripts/ejecutar_athena.py <etapa> <archivo_sql> <resultado1.csv> [resultado2.csv ...]
Hay un archivo de resultado por cada sentencia del SQL (separadas por ';').
"""
import csv
import json
import subprocess
import sys
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def aws(*argumentos):
    proceso = subprocess.run(["aws", *argumentos, "--output", "json"], capture_output=True, text=True)
    if proceso.returncode != 0:
        sys.exit(f"Error en AWS CLI: {proceso.stderr.strip()}")
    return json.loads(proceso.stdout) if proceso.stdout.strip() else {}


def sentencias(texto):
    lineas = [l for l in texto.splitlines() if not l.strip().startswith("--")]
    return [s.strip() for s in "\n".join(lineas).split(";") if s.strip()]


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    etapa, archivo_sql, *resultados = sys.argv[1:]
    salidas = json.loads((RAIZ / "evidencias" / "outputs.json").read_text(encoding="utf-8"))
    workgroup = salidas["workgroup"]["value"]
    base_datos = salidas["base_datos"]["value"]
    region = salidas["region"]["value"]

    consultas = sentencias((RAIZ / archivo_sql).read_text(encoding="utf-8"))
    if len(consultas) != len(resultados):
        sys.exit(f"{archivo_sql} tiene {len(consultas)} sentencias y se indicaron {len(resultados)} archivos de resultado")

    registro = RAIZ / "evidencias" / "ejecuciones_athena.csv"
    registro.parent.mkdir(parents=True, exist_ok=True)
    escribir_encabezado = not registro.exists() or registro.stat().st_size == 0

    for sql, destino in zip(consultas, resultados):
        inicio = aws("athena", "start-query-execution", "--query-string", sql,
                     "--work-group", workgroup,
                     "--query-execution-context", f"Database={base_datos}",
                     "--region", region)
        id_ejecucion = inicio["QueryExecutionId"]
        while True:
            estado = aws("athena", "get-query-execution", "--query-execution-id", id_ejecucion,
                         "--region", region)["QueryExecution"]["Status"]
            if estado["State"] in ("SUCCEEDED", "FAILED", "CANCELLED"):
                break
            time.sleep(1)
        if estado["State"] != "SUCCEEDED":
            sys.exit(f"Consulta {id_ejecucion} {estado['State']}: {estado.get('StateChangeReason', '')}")

        filas, token = [], None
        while True:
            argumentos = ["athena", "get-query-results", "--query-execution-id", id_ejecucion, "--region", region]
            if token:
                argumentos += ["--next-token", token]
            respuesta = aws(*argumentos)
            for fila in respuesta["ResultSet"]["Rows"]:
                filas.append([celda.get("VarCharValue", "") for celda in fila["Data"]])
            token = respuesta.get("NextToken")
            if not token:
                break

        ruta = RAIZ / destino
        ruta.parent.mkdir(parents=True, exist_ok=True)
        with ruta.open("w", newline="", encoding="utf-8") as archivo:
            csv.writer(archivo, lineterminator="\n").writerows(filas)

        with registro.open("a", newline="", encoding="utf-8") as archivo:
            escritor = csv.writer(archivo, lineterminator="\n")
            if escribir_encabezado:
                escritor.writerow(["etapa", "archivo_sql", "id_ejecucion", "archivo_resultado"])
                escribir_encabezado = False
            escritor.writerow([etapa, archivo_sql, id_ejecucion, destino])
        print(f"OK {archivo_sql} -> {destino} ({len(filas) - 1} filas) id={id_ejecucion}")


if __name__ == "__main__":
    main()
