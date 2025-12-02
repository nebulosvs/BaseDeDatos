--------------------------------------
-- CASO 1: REPORTERÍA DE ASESORÍAS --
--------------------------------------
SELECT
    p.id_profesional                                                AS ID,
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS PROFESIONAL,
    
    -- Banca
    SUM(CASE WHEN e.cod_sector = 3 THEN 1 ELSE 0 END) AS "NRO ASESORIA BANCA",

    LPAD(
        TO_CHAR(
            SUM(
                CASE WHEN e.cod_sector = 3 THEN ROUND(a.honorario) ELSE 0 END
            ), '$999G999G999'
                ),
                   17)                  AS MONTO_TOTAL_BANCA,
    
    -- Retail
    SUM(CASE WHEN e.cod_sector = 4 THEN 1 ELSE 0 END) AS "NRO ASESORIA RETAIL",

    LPAD(
        TO_CHAR(
            SUM(CASE WHEN e.cod_sector = 4 THEN ROUND(a.honorario) ELSE 0 END),
            '$999G999G999'), 17) AS MONTO_TOTAL_RETAIL,
    
    -- Totales
    SUM(CASE WHEN e.cod_sector IN (3,4) THEN 1 ELSE 0 END) AS "TOTAL ASESORIAS",

    LPAD(
        TO_CHAR(
            SUM(CASE WHEN e.cod_sector IN (3,4) THEN ROUND(a.honorario) ELSE 0 END),
            '$999G999G999'),18) AS TOTAL_HONORARIOS

FROM profesional p
JOIN asesoria a ON a.id_profesional = p.id_profesional
JOIN empresa  e ON e.cod_empresa    = a.cod_empresa

WHERE
    e.cod_sector IN (3,4)
    AND p.id_profesional IN (
        SELECT x.id_profesional
        FROM (
            SELECT a1.id_profesional
            FROM asesoria a1 JOIN empresa e1 ON e1.cod_empresa = a1.cod_empresa
            WHERE e1.cod_sector = 3
            INTERSECT
            SELECT a2.id_profesional
            FROM asesoria a2 JOIN empresa e2 ON e2.cod_empresa = a2.cod_empresa
            WHERE e2.cod_sector = 4
        ) x
    )

GROUP BY
    p.id_profesional,
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre)

ORDER BY ID;

-----------------------------------
-- CASO 2: RESUMEN DE HONORARIOS --
-----------------------------------
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE REPORTE_MES PURGE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN  
         RAISE;
      END IF;
END;
/

CREATE TABLE REPORTE_MES (
    id_profesional      NUMBER(10),
    nombre_completo     VARCHAR2(80),
    nombre_profesion    VARCHAR2(25),
    nom_comuna          VARCHAR2(20),
    nro_asesorias       NUMBER(3),
    monto_total         NUMBER(12,0),
    promedio_honorario  NUMBER(12,0),
    honorario_minimo    NUMBER(12,0),
    honorario_maximo    NUMBER(12,0)
);

INSERT INTO reporte_mes (
    id_profesional,
    nombre_completo,
    nombre_profesion,
    nom_comuna,
    nro_asesorias,
    monto_total,
    promedio_honorario,
    honorario_minimo,
    honorario_maximo
)
SELECT
    p.id_profesional AS id_prof,

    INITCAP(
        TRIM(
            NVL(p.appaterno, '') || ' ' ||
            NVL(p.apmaterno, '') || ' ' ||
            NVL(p.nombre,   '')
        )
    ) AS nombre_completo,

    INITCAP(pr.nombre_profesion) AS nombre_profesion,

    INITCAP(c.nom_comuna) AS nom_comuna,

    COUNT(*) AS nro_asesorias,

    ROUND(SUM(NVL(a.honorario, 0))) AS monto_total_honorarios,

    ROUND(AVG(NVL(a.honorario, 0))) AS promedio_honorario,

    ROUND(MIN(NVL(a.honorario, 0))) AS honorario_minimo,

    ROUND(MAX(NVL(a.honorario, 0))) AS honorario_maximo

FROM asesoria a
JOIN profesional p ON p.id_profesional = a.id_profesional
JOIN profesion   pr ON pr.cod_profesion = p.cod_profesion
JOIN comuna      c ON c.cod_comuna      = p.cod_comuna

WHERE
    TO_CHAR(a.fin_asesoria, 'MM') = '04' --abril
    AND TO_CHAR(a.fin_asesoria, 'YYYY') =
        TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')

GROUP BY
    p.id_profesional,
    INITCAP(
        TRIM(
            NVL(p.appaterno, '') || ' ' ||
            NVL(p.apmaterno, '') || ' ' ||
            NVL(p.nombre,   '')
        )
    ),
    INITCAP(pr.nombre_profesion),
    INITCAP(c.nom_comuna)

ORDER BY
    p.id_profesional;


COMMIT;

SELECT * FROM REPORTE_MES
ORDER BY id_profesional;
----------------------------------------
-- CASO 3: MODIFICACIÓN DE HONORARIOS --
----------------------------------------
--------------------
-- REPORTE ANTES --
--------------------

SELECT
    ROUND(SUM(NVL(a.honorario, 0))) AS honorario,
    p.id_profesional                 AS id_profesional,
    p.numrun_prof                    AS numrun_prof,
    p.sueldo                         AS sueldo
FROM profesional p
JOIN asesoria a
    ON a.id_profesional = p.id_profesional
WHERE
    TO_CHAR(a.fin_asesoria, 'MM')   = '03' --marzo
    AND TO_CHAR(a.fin_asesoria, 'YYYY') =
        TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY') -- año pasado
GROUP BY
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY
    p.id_profesional;

COMMIT;
-------------
-- UPDATE --
-------------

UPDATE profesional p
SET p.sueldo =
    ROUND(
        p.sueldo *
        CASE
            WHEN (
                SELECT SUM(a.honorario)
                FROM asesoria a
                WHERE a.id_profesional = p.id_profesional
                  AND TO_CHAR(a.fin_asesoria,'MM')   = '03' --marzo
                  AND TO_CHAR(a.fin_asesoria,'YYYY') =
                      TO_CHAR(ADD_MONTHS(SYSDATE,-12),'YYYY')
            ) < 1000000 -- menor a un millon
            THEN 1.10 -- se incrementa un 10% al sueldo
            ELSE 1.15 -- de lo contrario, incrementa un 15%
        END
    )
WHERE EXISTS (
    SELECT 1
    FROM asesoria a
    WHERE a.id_profesional = p.id_profesional
      AND TO_CHAR(a.fin_asesoria,'MM')   = '03'
      AND TO_CHAR(a.fin_asesoria,'YYYY') =
          TO_CHAR(ADD_MONTHS(SYSDATE,-12),'YYYY')
);

COMMIT;
----------------------
-- REPORTE DESPUÉS --
----------------------
SELECT
    ROUND(SUM(NVL(a.honorario, 0))) AS honorario,
    p.id_profesional                 AS id_profesional,
    p.numrun_prof                    AS numrun_prof,
    p.sueldo                         AS sueldo
FROM profesional p
JOIN asesoria a
    ON a.id_profesional = p.id_profesional
WHERE
    TO_CHAR(a.fin_asesoria, 'MM')   = '03'
    AND TO_CHAR(a.fin_asesoria, 'YYYY') =
        TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY
    p.id_profesional;

