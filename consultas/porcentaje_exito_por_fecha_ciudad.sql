-- Porcentaje de entregas exitosas por fecha y ciudad: 100 * exitosas / total de intentos del grupo.
-- Se usa DOUBLE para evitar division entera y DECIMAL(5,2) para conservar dos decimales.
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(
            100.0 * CAST(SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*),
            2
        ) AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM entregas_jjrp_db.entregas_jjrp
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
