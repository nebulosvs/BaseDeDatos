 -----------------------------------------------------------------
    -- 1. Configuración del entorno de ejecución (SQL)
 ------------------------------------------------------------------
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
 ---------------------------------------------------------------------
    -- 2. Definición de VARIABLE BIND para período de ejecución (SQL)
 ---------------------------------------------------------------------

VARIABLE b_anio NUMBER
EXEC :b_anio := EXTRACT(YEAR FROM SYSDATE)

SET SERVEROUTPUT ON;
---------------------------------------------------------------------
-- COMIENZO DE PL/SQL
---------------------------------------------------------------------
DECLARE
    ----------------------------------------------------------------------
    -- 3. VARRAY: Tipos de transacción permitidos (Avance / Súper Avance)
    ----------------------------------------------------------------------
    TYPE t_tipos_trans IS VARRAY(2) OF NUMBER;
    v_tipos_trans t_tipos_trans := t_tipos_trans(102, 103);

    ------------------------------------------------------------------
    -- 4. Registro PL/SQL para una transacción
    ------------------------------------------------------------------
    TYPE r_transaccion IS RECORD (
        numrun              CLIENTE.numrun%TYPE,
        dvrun               CLIENTE.dvrun%TYPE,
        nro_tarjeta         TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_transaccion     TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_transaccion   TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        monto_total         TRANSACCION_TARJETA_CLIENTE.monto_total_transaccion%TYPE,
        tipo_transaccion    TIPO_TRANSACCION_TARJETA.nombre_tptran_tarjeta%TYPE
    );
    v_reg r_transaccion;

    ------------------------------------------------------------------
    -- 5. Declaración de variables de cálculo
    ------------------------------------------------------------------
    v_porcentaje_aporte   TRAMO_APORTE_SBIF.porc_aporte_sbif%TYPE;
    v_aporte_sbif         NUMBER;

    v_contador            NUMBER := 0;
    v_total_registros     NUMBER;

    ------------------------------------------------------------------
    -- 6. Definición de excepción definida por el usuario
    ------------------------------------------------------------------
    e_monto_invalido EXCEPTION;

    ---------------------------------------------------------------------
    -- 7. Cursor explícito principal (transacciones del año paramétrico)
    -- (contiene SQL interno dado el SELECT)
    ---------------------------------------------------------------------
    CURSOR c_transacciones IS
        SELECT
            c.numrun,
            c.dvrun,
            t.nro_tarjeta,
            t.nro_transaccion,
            t.fecha_transaccion,
            t.monto_total_transaccion,
            tt.nombre_tptran_tarjeta
        FROM TRANSACCION_TARJETA_CLIENTE t
        JOIN TARJETA_CLIENTE tc ON t.nro_tarjeta = tc.nro_tarjeta
        JOIN CLIENTE c ON tc.numrun = c.numrun
        JOIN TIPO_TRANSACCION_TARJETA tt ON t.cod_tptran_tarjeta = tt.cod_tptran_tarjeta
        WHERE t.cod_tptran_tarjeta IN (v_tipos_trans(1), v_tipos_trans(2))
          AND EXTRACT(YEAR FROM t.fecha_transaccion) = :b_anio
        ORDER BY t.fecha_transaccion, c.numrun;

    ------------------------------------------------------------------
    -- 8. Cursor explícito con parámetro (porcentaje SBIF)
    -- (contiene SQL interno dado el SELECT)
    ------------------------------------------------------------------
    CURSOR c_tramo (p_monto NUMBER) IS
        SELECT porc_aporte_sbif
        FROM TRAMO_APORTE_SBIF
        WHERE p_monto BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;

BEGIN
    ------------------------------------------------------------------
    -- 9. Limpieza de tablas destino
    -- (contiene SQL interno)
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';

    ------------------------------------------------------------------
    -- 10. Total de registros a procesar
    -- (contiene SQL interno dado el SELECT)
    ------------------------------------------------------------------
    SELECT COUNT(*)
    INTO v_total_registros
    FROM TRANSACCION_TARJETA_CLIENTE
    WHERE cod_tptran_tarjeta IN (v_tipos_trans(1), v_tipos_trans(2))
      AND EXTRACT(YEAR FROM fecha_transaccion) = :b_anio;

    ------------------------------------------------------------------
    -- 11. Procesamiento principal de transacciones
    ------------------------------------------------------------------
    OPEN c_transacciones;
    LOOP
        FETCH c_transacciones INTO v_reg;
        EXIT WHEN c_transacciones%NOTFOUND;

        IF v_reg.monto_total <= 0 THEN
            RAISE e_monto_invalido;
        END IF;

        ------------------------------------------------------------------
        -- Buscar porcentaje de aporte
        ------------------------------------------------------------------
        OPEN c_tramo(v_reg.monto_total);
        FETCH c_tramo INTO v_porcentaje_aporte;
        CLOSE c_tramo;

        ------------------------------------------------------------------
        -- Cálculo del aporte SBIF (PL/SQL)
        ------------------------------------------------------------------
        v_aporte_sbif := ROUND(v_reg.monto_total * v_porcentaje_aporte / 100);

        ------------------------------------------------------------------
        -- Insertar DETALLE
        -- (contiene SQL interno dado el INSERT)
        ------------------------------------------------------------------
        INSERT INTO DETALLE_APORTE_SBIF (
            numrun, dvrun, nro_tarjeta, nro_transaccion,
            fecha_transaccion, tipo_transaccion,
            monto_transaccion, aporte_sbif
        ) VALUES (
            v_reg.numrun, v_reg.dvrun, v_reg.nro_tarjeta,
            v_reg.nro_transaccion, v_reg.fecha_transaccion,
            v_reg.tipo_transaccion, v_reg.monto_total, v_aporte_sbif
        );

        v_contador := v_contador + 1;

    END LOOP;
    CLOSE c_transacciones;

    ------------------------------------------------------------------
    -- 12. Generar RESUMEN
    -- (contiene SQL interno dado el INSERT, SELECT, GROUP BY)
    ------------------------------------------------------------------
    INSERT INTO RESUMEN_APORTE_SBIF
    SELECT
        TO_CHAR(fecha_transaccion, 'MMYYYY') AS mes_anno,
        tipo_transaccion,
        SUM(monto_transaccion),
        SUM(aporte_sbif)
    FROM DETALLE_APORTE_SBIF
    GROUP BY TO_CHAR(fecha_transaccion, 'MMYYYY'), tipo_transaccion
    ORDER BY mes_anno, tipo_transaccion;

    ------------------------------------------------------------------
    -- 13. Commit controlado
    ------------------------------------------------------------------
    IF v_contador = v_total_registros THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('CASO ejecutado correctamente. Registros: ' || v_contador);
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Rollback ejecutado. Registros incompletos.');
    END IF;

EXCEPTION
    ------------------------------------------------------------------
    -- 14. Excepción predefinida
    ------------------------------------------------------------------
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No existe tramo SBIF para el monto.');

    ------------------------------------------------------------------
    -- 15. Excepción definida por el usuario
    ------------------------------------------------------------------
    WHEN e_monto_invalido THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Monto total inválido.');

    ------------------------------------------------------------------
    -- 16. Excepción no predefinida
    ------------------------------------------------------------------
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END;
/


 ------------------------------------------------------------------
 -- 17. Comprobación / Consultas (SQL)
 ------------------------------------------------------------------
SELECT * 
FROM DETALLE_APORTE_SBIF
ORDER BY fecha_transaccion, numrun;


SELECT *
FROM RESUMEN_APORTE_SBIF
ORDER BY mes_anno, tipo_transaccion;
