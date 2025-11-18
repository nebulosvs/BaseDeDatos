
--------------------------------------
-- CASO 1: LISTADO DE TRABAJADORES --
--------------------------------------

SELECT
    -- Nombre completo 
    t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno  AS "Nombre Completo Trabajador",
    
    -- RUT con puntos y DV en mayúscula (por si acaso)
    TO_CHAR(t.numrut, '99G999G999') || '-' || UPPER(t.dvrut)       AS "RUT Trabajador",
    
    -- Tipo de trabajador 
    NVL(UPPER(tt.desc_categoria), 'SIN TIPO')                      AS "Tipo Trabajador",
    
    -- Ciudad del trabajador (si viniera nula, mostramos 'Sin ciudad')
    NVL(UPPER(c.nombre_ciudad), 'Sin ciudad')                    AS "Ciudad Trabajador",
    
    -- Sueldo base formateado en CLP
    TO_CHAR(ROUND(t.sueldo_base,0), '$999G999G999')                AS "Sueldo Base"
FROM
    trabajador        t
    JOIN comuna_ciudad     c  ON t.id_ciudad      = c.id_ciudad
    LEFT JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
WHERE
    t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY
    c.nombre_ciudad DESC,
    t.sueldo_base   ASC;

---------------------------------
-- CASO 2: LISTADO DE CAJEROS --
---------------------------------
SELECT
    -- RUT con puntos y DV en mayúscula (por si acaso)
    TO_CHAR(t.numrut, '99G999G999') || '-' || UPPER(t.dvrut)          AS "RUT Trabajador",

    -- Nombre completo
    INITCAP(t.nombre) || ' ' || UPPER(t.appaterno) AS "Nombre Trabajador",

    -- Cantidad de tickets vendidos
    COUNT(tc.nro_ticket)                                             AS "Total Tickets",

    -- Total vendido (tickets) formateado
    TO_CHAR(SUM(tc.monto_ticket), '$999G999G999')                    AS "Total Vendido",

    -- Comisión total (si no hay, muestra 0)
    TO_CHAR(NVL(SUM(ct.valor_comision), 0), '$999G999G999')          AS "Comisión Total",

    -- Tipo de trabajador
    UPPER(tt.desc_categoria)                                         AS "Tipo Trabajador",

    -- Ciudad del trabajador 
    UPPER(c.nombre_ciudad)                                           AS "Ciudad Trabajador"

FROM trabajador t
JOIN tickets_concierto tc
      ON tc.numrut_t = t.numrut
LEFT JOIN comisiones_ticket ct
      ON ct.nro_ticket = tc.nro_ticket
JOIN tipo_trabajador tt
      ON t.id_categoria_t = tt.id_categoria
LEFT JOIN comuna_ciudad c
      ON t.id_ciudad = c.id_ciudad

WHERE
    UPPER(tt.desc_categoria) = 'CAJERO'       -- solo cajeros

GROUP BY
    t.numrut, t.dvrut,
    t.appaterno, t.apmaterno, t.nombre,
    tt.desc_categoria,
    c.nombre_ciudad

HAVING
    SUM(tc.monto_ticket) > 50000             -- total vendido > 50.000

ORDER BY
    SUM(tc.monto_ticket) DESC;               -- orden por Total Vendido desc

----------------------------------------
-- CASO 3: LISTADO DE BONIFICACIONES --
----------------------------------------

SELECT
    -- RUT formateado
    TO_CHAR(t.numrut, '99G999G999') || '-' || UPPER(t.dvrut)          AS "RUT Trabajador",

    -- Nombre
    INITCAP(t.nombre || ' ' || t.appaterno)
                                                                    AS "Trabajador Nombre",

    -- Año de ingreso
    EXTRACT(YEAR FROM t.fecing)                                     AS "Año ingreso",

    -- Años de antigüedad
    TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12)            AS "Años antigüedad",

    -- Número de cargas familiares
    NVL(COUNT(af.numrut_carga), 0)                                  AS "Num. Cargas Familiares",

    -- Isapre / Fonasa
    INITCAP(i.nombre_isapre)                                          AS "Nombre Isapre",

    -- Sueldo base formateado
    TO_CHAR(t.sueldo_base, '$999G999G999')                          AS "Sueldo Base",

    -- Bono Fonasa: 1% del sueldo si es FONASA, si no 0
    CASE
        WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN
            TO_CHAR(ROUND(t.sueldo_base * 0.01, 0), '$999G999G999')
        ELSE
            LPAD('0', 13, ' ')
    END AS "Bono Fonasa",


    -- Bono antigüedad 
    TO_CHAR(
        NVL(ROUND(t.sueldo_base * ba.porcentaje, 0), 0),
        '$999G999G999'
    )                                                               AS "Bono Antigüedad",

    -- AFP
    INITCAP(a.nombre_afp)                                           AS "Nombre AFP",

    -- Estado civil
    UPPER(ec.desc_estcivil)                                       AS "Estado Civil"

FROM
    trabajador t
    JOIN isapre i
        ON t.cod_isapre = i.cod_isapre
    JOIN afp a
        ON t.cod_afp = a.cod_afp
    LEFT JOIN asignacion_familiar af
        ON af.numrut_t = t.numrut
    -- estado civil vigente
    JOIN est_civil ecv
        ON ecv.numrut_t = t.numrut
       AND (ecv.fecter_estcivil IS NULL
            OR ecv.fecter_estcivil > TRUNC(SYSDATE))
    JOIN estado_civil ec
        ON ec.id_estcivil = ecv.id_estcivil_est
    -- tramo de antigüedad
    LEFT JOIN bono_antiguedad ba
        ON TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12)
           BETWEEN ba.limite_inferior AND ba.limite_superior

GROUP BY
    t.numrut, t.dvrut,
    t.nombre, t.appaterno, t.apmaterno,
    t.fecing,
    t.sueldo_base,
    i.nombre_isapre,
    a.nombre_afp,
    ec.desc_estcivil,
    TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), t.fecing) / 12),
    ba.porcentaje

ORDER BY
    t.numrut ASC;