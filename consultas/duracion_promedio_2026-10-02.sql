-- Duracion promedio de las entregas exitosas del 2026-10-02 (sin contar los intentos fallidos con duracion 0).
SELECT
    fecha,
    CAST(ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2) AS DECIMAL(10, 2)) AS duracion_promedio_minutos
FROM entregas_jjrp_db.entregas_jjrp
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
