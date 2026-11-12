-- Verificacion del tercer dia. Cada sentencia genera un CSV distinto en resultados/final/.

-- 1) Los seis registros de 2026-10-03.
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM entregas_jjrp_db.entregas_jjrp
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2) Conteo por estado del 2026-10-03.
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas_jjrp_db.entregas_jjrp
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;

-- 3) Total de registros de la tabla (debe ser 18).
SELECT COUNT(*) AS total_registros
FROM entregas_jjrp_db.entregas_jjrp;
