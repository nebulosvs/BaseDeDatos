------------------------------------------
-- CASO 1: BONIFICACIÓN DE TRABAJADORES --
------------------------------------------
-- SINÓNIMOS PRIVADOS
DROP SYNONYM s_trabajador;
DROP SYNONYM s_bono_antiguedad;
DROP SYNONYM s_tickets_concierto;
--
CREATE SYNONYM s_trabajador       FOR trabajador;
CREATE SYNONYM s_bono_antiguedad  FOR bono_antiguedad;
CREATE SYNONYM s_tickets_concierto FOR tickets_concierto;

-- TABLA BONO ANTIGUEDAD
TRUNCATE TABLE bono_antiguedad;
INSERT INTO bono_antiguedad (id, limite_inferior, limite_superior, porcentaje)
VALUES (1,  2,  8,  0.05);

INSERT INTO bono_antiguedad (id, limite_inferior, limite_superior, porcentaje)
VALUES (2,  9, 15,  0.06);

INSERT INTO bono_antiguedad (id, limite_inferior, limite_superior, porcentaje)
VALUES (3, 16, 19,  0.08);

INSERT INTO bono_antiguedad (id, limite_inferior, limite_superior, porcentaje)
VALUES (4, 20, 30,  0.10);

COMMIT;

-- TABLA DETALLE, RESOLUCION

TRUNCATE TABLE detalle_bonificaciones_trabajador;
INSERT INTO detalle_bonificaciones_trabajador (
    num,
    rut,
    nombre_trabajador,
    sueldo_base,
    num_ticket,
    direccion,
    sistema_salud,
    monto,
    bonif_x_ticket,
    simulacion_x_ticket,
    simulacion_antiguedad
)
SELECT
    seq_det_bonif.NEXTVAL                       AS num,
    q.rut,
    q.nombre_trabajador,
    q.sueldo_base,
    q.num_ticket,
    q.direccion,
    q.sistema_salud,
    q.monto,
    q.bonif_x_ticket,
    q.simulacion_x_ticket,
    q.simulacion_antiguedad
FROM (
    SELECT
        ------------------------------------------------------------------
        -- Datos del trabajador
        ------------------------------------------------------------------
        TO_CHAR(t.numrut) || '-' || t.dvrut            AS rut,

        INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)
                                                        AS nombre_trabajador,

        LPAD(TO_CHAR(t.sueldo_base, 'FM$999G999G999'),
             15, ' ')                                   AS sueldo_base,

        NVL(TO_CHAR(tc.nro_ticket), 'No hay info')     AS num_ticket,

        INITCAP(t.direccion)                           AS direccion,

        -- SIN INITCAP, tal como pediste
        i.nombre_isapre                                AS sistema_salud,

        ------------------------------------------------------------------
        -- Cálculos numéricos (para lógica)
        ------------------------------------------------------------------
        NVL(tc.monto_ticket, 0)                        AS monto_ticket_num,

        CASE
          WHEN tc.nro_ticket IS NULL THEN 0
          WHEN tc.monto_ticket <= 50000 THEN 0
          WHEN tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket * 0.05)
          ELSE ROUND(tc.monto_ticket * 0.07)
        END                                            AS bonif_ticket_num,

        ------------------------------------------------------------------
        -- Campos formateados para el reporte 
        ------------------------------------------------------------------
        LPAD(TO_CHAR(NVL(tc.monto_ticket,0),
                     'FM$999G999G999'),
             12, ' ')                                   AS monto,

        LPAD(
          TO_CHAR(
            CASE
              WHEN tc.nro_ticket IS NULL THEN 0
              WHEN tc.monto_ticket <= 50000 THEN 0
              WHEN tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket * 0.05)
              ELSE ROUND(tc.monto_ticket * 0.07)
            END,
            'FM$999G999G999'
          ),
          15, ' '
        )                                               AS bonif_x_ticket,

        LPAD(
          TO_CHAR(
            ROUND(
              t.sueldo_base +
              CASE
                WHEN tc.nro_ticket IS NULL THEN 0
                WHEN tc.monto_ticket <= 50000 THEN 0
                WHEN tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket * 0.05)
                ELSE ROUND(tc.monto_ticket * 0.07)
              END
            ),
            'FM$999G999G999'
          ),
          12, ' '
        )                                               AS simulacion_x_ticket,

        LPAD(
          TO_CHAR(
            ROUND(
              t.sueldo_base * (1 + ba.porcentaje)
            ),
            'FM$999G999G999'
          ),
          12, ' '
        )                                               AS simulacion_antiguedad

    FROM   s_trabajador t
           JOIN isapre i
             ON t.cod_isapre = i.cod_isapre
           JOIN s_bono_antiguedad ba
             ON TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12)
                BETWEEN ba.limite_inferior AND ba.limite_superior
           -- MUY IMPORTANTE: LEFT JOIN → permite 0, 1 o N tickets por trabajador
           LEFT JOIN s_tickets_concierto tc
             ON tc.numrut_t = t.numrut
    WHERE
           i.porc_descto_isapre > 4                      -- salud > 4%
       AND TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac) / 12) < 50  -- < 50 años
    ORDER BY
           NVL(tc.monto_ticket,0) DESC,                  -- monto desc
           nombre_trabajador ASC                         -- nombre asc
) q;

COMMIT;

SELECT * 
FROM detalle_bonificaciones_trabajador
ORDER BY monto DESC, nombre_trabajador;

--NOTA: LUIS Y PAULA SI DEBEN INCLUIRSE PORQUE TIENEN 8 AÑOS DE ANTIGUEDAD



-- ==========================================================
-- CASO 2 - ETAPA 1: VISTA DE AUMENTOS POR ESTUDIOS
-- Requerimiento: Vista compleja, subconsultas, sinónimos y formatos específicos.
-- ==========================================================

-- 1. Creación de Sinónimos Privados
DROP SYNONYM syn_bono_esc FOR BONO_ESCOLAR;
DROP SYNONYM syn_asig_fam FOR ASIGNACION_FAMILIAR;

CREATE OR REPLACE SYNONYM syn_bono_esc FOR BONO_ESCOLAR;
CREATE OR REPLACE SYNONYM syn_asig_fam FOR ASIGNACION_FAMILIAR;

-- 2. Creación de la Vista V_AUMENTOS_ESTUDIOS
CREATE OR REPLACE VIEW V_AUMENTOS_ESTUDIOS AS
SELECT 
    be.descrip AS "DESCRIP",
    TO_CHAR(t.numrut, '09G999G999') || '-' || t.dvrut AS "RUT_TRABAJADOR",
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "NOMBRE_TRABAJADOR",
    LPAD(be.porc_bono, 7, '0') AS "PCT_ESTUDIOS",
    t.sueldo_base AS "SUELDO_ACTUAL",
    ROUND(t.sueldo_base * (be.porc_bono / 100)) AS "AUMENTO",
    TO_CHAR(t.sueldo_base + ROUND(t.sueldo_base * (be.porc_bono / 100)), '$99G999G999') AS "SUELDO_AUMENTADO"
FROM 
    TRABAJADOR t
    JOIN TIPO_TRABAJADOR tt ON t.id_categoria_t = tt.id_categoria
    JOIN syn_bono_esc be ON t.id_escolaridad_t = be.id_escolar
WHERE 
    tt.desc_categoria = 'CAJERO' 
    AND (
        SELECT COUNT(*) 
        FROM syn_asig_fam af 
        WHERE af.numrut_t = t.numrut
    ) BETWEEN 1 AND 2;

-- 3. Consulta final a la vista (Verificación)
SELECT * FROM V_AUMENTOS_ESTUDIOS
ORDER BY "PCT_ESTUDIOS" ASC, "NOMBRE_TRABAJADOR" ASC;


-- ==========================================================
-- CASO 2 - ETAPA 2: OPTIMIZACIÓN DE CONSULTAS
-- Requerimiento: Crear índices para evitar Full Table Scan al usar UPPER.
-- ==========================================================

CREATE INDEX idx_trab_apmaterno_upper 
ON TRABAJADOR(UPPER(apmaterno));

-- Recopilar estadísticas para forzar al optimizador a ver el nuevo índice
EXEC DBMS_STATS.GATHER_TABLE_STATS('PRY2205_S7', 'TRABAJADOR');

-- Consulta de prueba para verificar optimización (Plan de Ejecución debería mostrar RANGE SCAN)
SELECT numrut, fecnac, nombre, appaterno, apmaterno
FROM trabajador
WHERE UPPER(apmaterno) = 'CASTILLO';

