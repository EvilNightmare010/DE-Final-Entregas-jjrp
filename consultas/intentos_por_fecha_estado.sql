-- Cantidad de intentos por fecha y estado (todos los intentos).
-- Sin filtro de fechas: cubre todo el rango proyectado; solo devuelve las fechas con archivos en S3.
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_jjrp_db.entregas_jjrp
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
