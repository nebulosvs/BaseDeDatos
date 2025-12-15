
/* =========================================================
   ADMIN: CREACION USUARIOS Y ROLES
   ========================================================= */
-- Limpieza
DROP USER PRY2205_USER2 CASCADE;
DROP USER PRY2205_USER1 CASCADE;

DROP ROLE PRY2205_ROL_P;
DROP ROLE PRY2205_ROL_D;

-- Al ser publicos, debe hacerlo el admin
DROP PUBLIC SYNONYM syn_libro;
DROP PUBLIC SYNONYM syn_ejemplar;
DROP PUBLIC SYNONYM syn_prestamo;
DROP PUBLIC SYNONYM syn_empleado;
DROP PUBLIC SYNONYM syn_alumno;
DROP PUBLIC SYNONYM syn_carrera;
DROP PUBLIC SYNONYM syn_rebaja_multa;



-- Crear usuarios 
CREATE USER PRY2205_USER1 IDENTIFIED BY "Adminduoc_2025"
    DEFAULT TABLESPACE DATA             -- Tablespace de datos 
    TEMPORARY TABLESPACE TEMP           -- Tablespace temporal
    QUOTA UNLIMITED ON DATA;           -- Cuota de espacio sobre DATA (o valor acotado)
  

CREATE USER PRY2205_USER2 IDENTIFIED BY "Userduoc_2025"
    DEFAULT TABLESPACE DATA             
    TEMPORARY TABLESPACE TEMP           
    QUOTA UNLIMITED ON DATA;    

-- Dar privilegio mínimo para conectarse (ambos necesitan iniciar sesión).
-- Esto NO les da permiso para leer tablas de otros esquemas; solo permite login.       
GRANT CREATE SESSION TO PRY2205_USER1;
GRANT CREATE SESSION TO PRY2205_USER2;

-- Crear roles
CREATE ROLE PRY2205_ROL_D; -- rol de desarrollador
CREATE ROLE PRY2205_ROL_P; -- rol de pruebas/consultas


-- Privilegios: crear tablas, indices y secuencias en SU PROPIO ambiente.
GRANT RESOURCE TO PRY2205_USER1; 
GRANT RESOURCE TO PRY2205_USER2;

/* =========================================================
   PRY2205_USER1: POBLAR EL ESQUEMA
   ========================================================= */

-- Correr antes de correr el esquema: asi puede crear las tablas y poblarlas.
SET ROLE ALL;
-- Crear/poblar tablas del modelo (correr el esquema poblado)

/* =========================================================
   ADMIN: FINALIZACION DE PRIVILEGIOS
   ========================================================= */

-- Privilegios especificos
GRANT CREATE VIEW TO PRY2205_ROL_D;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_ROL_D;
-- Al ser el usuario 1 el owner no es necesario, pero lo especificamos:
GRANT SELECT, INSERT, UPDATE, DELETE ON PRY2205_USER1.libro    TO PRY2205_ROL_D;
GRANT SELECT, INSERT, UPDATE, DELETE ON PRY2205_USER1.prestamo TO PRY2205_ROL_D;


-- SOLO debe conectarse y hacer SELECT sobre lo que el desarrollador exponga.
-- No uso any table porque las instrucciones indican "acceso a tablas necesarias".
GRANT CREATE SESSION TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.LIBRO    TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.PRESTAMO TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.EMPLEADO TO PRY2205_ROL_P;


-- Asignar roles
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

/* =========================================================
   PRY2205_USER1
   CASO 1: SINÓNIMOS PÚBLICOS (para que USER2 consulte sin saber esquema)
   ========================================================= */

-- Volver a correrlo para confirmar que tenga el rol_D.
SET ROLE ALL;

-- Necesarios para Caso 2 (control stock)
CREATE PUBLIC SYNONYM syn_libro    FOR PRY2205_USER1.libro;
CREATE PUBLIC SYNONYM syn_ejemplar FOR PRY2205_USER1.ejemplar;
CREATE PUBLIC SYNONYM syn_prestamo FOR PRY2205_USER1.prestamo;
CREATE PUBLIC SYNONYM syn_empleado FOR PRY2205_USER1.empleado;

-- Necesarios para Caso 3 (vista multas)
CREATE PUBLIC SYNONYM syn_alumno       FOR PRY2205_USER1.alumno;
CREATE PUBLIC SYNONYM syn_carrera      FOR PRY2205_USER1.carrera;
CREATE PUBLIC SYNONYM syn_rebaja_multa FOR PRY2205_USER1.rebaja_multa;


/* =========================================================
   PRY2205_USER2
   CASO 2: SEQ + CONTROL_STOCK_LIBROS (CTAS)
   ========================================================= */
SET ROLE ALL;

-- Limpieza
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CONTROL_STOCK_LIBROS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_CONTROL_STOCK';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/


-- 3.1 Secuencia
CREATE SEQUENCE SEQ_CONTROL_STOCK
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE TABLE CONTROL_STOCK_LIBROS AS
SELECT
    CAST(NULL AS NUMBER(6))                                       AS ID_CONTROL,
    l.libroid                                                     AS LIBRO_ID,
    INITCAP(l.nombre_libro)                                       AS NOMBRE_LIBRO,
    COUNT(e.ejemplarid)                                           AS TOTAL_EJEMPLARES,
    NVL(COUNT(DISTINCT p.ejemplarid),0)                            AS EN_PRESTAMO,
    ( COUNT(e.ejemplarid) - NVL(COUNT(DISTINCT p.ejemplarid),0) )  AS DISPONIBLES,
    ROUND(SUM(CASE WHEN p.prestamoid IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(e.ejemplarid), 0) * 100) AS PORCENTAJE_PRESTAMO,
    CASE
      WHEN ( COUNT(e.ejemplarid) - NVL(COUNT(DISTINCT p.ejemplarid),0) ) > 2 THEN 'S'
      ELSE 'N'
    END                                                           AS STOCK_CRITICO
FROM
    syn_libro    l
    JOIN syn_ejemplar e
      ON e.libroid = l.libroid
    LEFT JOIN syn_prestamo p
      ON p.libroid    = e.libroid
     AND p.ejemplarid = e.ejemplarid
     AND p.empleadoid IN (190, 180, 150)
     AND p.fecha_inicio BETWEEN
         ADD_MONTHS(TRUNC(SYSDATE,'MM'), -24)
         AND LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE,'MM'), -24))
GROUP BY
    l.libroid,
    l.nombre_libro;


UPDATE CONTROL_STOCK_LIBROS
SET ID_CONTROL = SEQ_CONTROL_STOCK.NEXTVAL
WHERE ID_CONTROL IS NULL;

COMMIT; 

SELECT * FROM CONTROL_STOCK_LIBROS 
ORDER BY LIBRO_ID; --como lo piden


/* =========================================================
   PRY2205_USER1
   CASO 3.1: CREACION DE VISTA
   ========================================================= */


CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT
    p.prestamoid AS ID_PRESTAMO,
    INITCAP(a.nombre || ' ' || a.apaterno) AS NOMBRE_ALUMNO,
    INITCAP(c.descripcion) AS NOMBRE_CARRERA,
    l.libroid AS ID_LIBRO,

    -- Valor libro en CLP
    TO_CHAR(NVL(l.precio,0), 'L9G999G999',
            'NLS_CURRENCY=''$'' NLS_NUMERIC_CHARACTERS='',.''') AS VALOR_LIBRO,

    p.fecha_termino AS FECHA_TERMINO,
    p.fecha_entrega AS FECHA_ENTREGA,

    (p.fecha_entrega - p.fecha_termino) AS DIAS_ATRASO,

    -- Multa base en CLP (3% por día)
    TO_CHAR(
      ROUND((p.fecha_entrega - p.fecha_termino) * (NVL(l.precio,0) * 0.03)),
      'L9G999G999',
      'NLS_CURRENCY=''$'' NLS_NUMERIC_CHARACTERS='',.'''
    ) AS VALOR_MULTA,

    -- Porcentaje en formato decimal (ej: 6 -> 0.06)
    CASE
        WHEN NVL(rm.porc_rebaja_multa, 0) = 0 THEN 0
        ELSE ROUND(rm.porc_rebaja_multa / 100, 2)
    END AS PORCENTAJE_REBAJA_MULTA,


    -- Multa final con rebaja en CLP
    TO_CHAR(
      ROUND(
        ROUND((p.fecha_entrega - p.fecha_termino) * (NVL(l.precio,0) * 0.03))
        * (1 - NVL(rm.porc_rebaja_multa,0)/100)
      ),
      'L9G999G999',
      'NLS_CURRENCY=''$'' NLS_NUMERIC_CHARACTERS='',.'''
    ) AS VALOR_REBAJADO

FROM prestamo p
JOIN alumno  a ON a.alumnoid  = p.alumnoid
JOIN carrera c ON c.carreraid = a.carreraid
JOIN libro   l ON l.libroid   = p.libroid
LEFT JOIN rebaja_multa rm ON rm.carreraid = c.carreraid

WHERE
    p.fecha_entrega IS NOT NULL
    AND p.fecha_entrega > p.fecha_termino
    AND EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2;

SELECT *
FROM VW_DETALLE_MULTAS
ORDER BY FECHA_ENTREGA DESC;

/* =========================================================
   PRY2205_USER1
   CASO 3.2: CREACION DE INDICES
   ========================================================= */

-- Limpieza 
BEGIN
  EXECUTE IMMEDIATE 'DROP INDEX IDX_PRESTAMO_FECHA_TERMINO';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP INDEX IDX_PRESTAMO_ALUMNO';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Ver plan
EXPLAIN PLAN FOR
SELECT
  p.prestamoid,
  p.fecha_termino,
  p.fecha_entrega,
  (p.fecha_entrega - p.fecha_termino) AS dias_atraso,
  a.alumnoid,
  c.carreraid,
  l.libroid,
  rm.porc_rebaja_multa
FROM prestamo p
JOIN alumno  a ON a.alumnoid  = p.alumnoid
JOIN carrera c ON c.carreraid = a.carreraid
JOIN libro   l ON l.libroid   = p.libroid
LEFT JOIN rebaja_multa rm ON rm.carreraid = c.carreraid
WHERE
  p.fecha_entrega IS NOT NULL
  AND p.fecha_entrega > p.fecha_termino
  AND p.fecha_termino >= ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -24)
  AND p.fecha_termino <  ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -12)
  AND (p.fecha_entrega - p.fecha_termino) >= 1
 -- AND a.alumnoid = 101  -- elegir algun alumno
ORDER BY
  p.fecha_entrega DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);



-- Índices típicos útiles
-- Crear índice sobre la columna fecha_termino para optimizar el filtro
CREATE INDEX idx_prestamo_fecha_termino
ON PRY2205_USER1.prestamo (fecha_termino);

CREATE INDEX idx_prestamo_alumno
ON prestamo (alumnoid);


-- Ver plan de nuevo
EXPLAIN PLAN FOR
SELECT
  p.prestamoid,
  p.fecha_termino,
  p.fecha_entrega,
  (p.fecha_entrega - p.fecha_termino) AS dias_atraso,
  a.alumnoid,
  c.carreraid,
  l.libroid,
  rm.porc_rebaja_multa
FROM prestamo p
JOIN alumno  a ON a.alumnoid  = p.alumnoid
JOIN carrera c ON c.carreraid = a.carreraid
JOIN libro   l ON l.libroid   = p.libroid
LEFT JOIN rebaja_multa rm ON rm.carreraid = c.carreraid
WHERE
  p.fecha_entrega IS NOT NULL
  AND p.fecha_entrega > p.fecha_termino
  AND p.fecha_termino >= ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -24)
  AND p.fecha_termino <  ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -12)
  AND (p.fecha_entrega - p.fecha_termino) >= 1
  --AND a.alumnoid = 101   -- repetir el mismo alumno
ORDER BY
  p.fecha_entrega DESC;


SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/* =====================================================================================
   Si se ignora el filtro de alumno:
   Aunque se creó un índice sobre la columna fecha_termino, 
   el optimizador de Oracle decide realizar un acceso FULL TABLE SCAN 
   debido al bajo volumen de registros en la tabla PRESTAMO, 
   ya que el costo estimado de leer la tabla completa es menor que el uso del índice. 
   (Lo cual es un comportamiento esperado y correcto en tablas pequeñas)”
   
   Sin embargo, si se añade el filtro de alumno, se usan ambos indices!
   =================================================================================*/