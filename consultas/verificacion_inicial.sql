-- Verificacion inicial (dias 1 y 2): la tabla debe tener 12 registros y el dia 3 aun no debe tener datos.
SELECT COUNT(*) AS total_registros
FROM entregas_jjrp_db.entregas_jjrp;

SELECT COUNT(*) AS registros_2026_10_03
FROM entregas_jjrp_db.entregas_jjrp
WHERE fecha = '2026-10-03';
