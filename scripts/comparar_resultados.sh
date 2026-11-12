#!/usr/bin/env bash
# Compara los resultados obtenidos en Athena con las referencias suministradas.
# Uso: bash scripts/comparar_resultados.sh inicial|final
set -uo pipefail
cd "$(dirname "$0")/.."
etapa="${1:?Indique la etapa: inicial o final}"
fallos=0

comparar() {
  if diff <(tr -d '\r' < "$2") <(tr -d '\r' < "$1") > /dev/null; then
    echo "IGUAL      $1  ==  $2"
  else
    echo "DIFERENTE  $1  !=  $2"; diff <(tr -d '\r' < "$2") <(tr -d '\r' < "$1") | head -20; fallos=1
  fi
}

comparar "resultados/${etapa}/intentos_por_fecha_estado.csv" "resultados_esperados/intentos_por_fecha_estado_${etapa}.csv"
comparar "resultados/${etapa}/porcentaje_exito_por_fecha_ciudad.csv" "resultados_esperados/porcentaje_exito_por_fecha_ciudad_${etapa}.csv"
if [ "$etapa" = "inicial" ]; then
  comparar "resultados/inicial/duracion_promedio_2026-10-02.csv" "resultados_esperados/duracion_promedio_2026-10-02.csv"
fi
exit $fallos
