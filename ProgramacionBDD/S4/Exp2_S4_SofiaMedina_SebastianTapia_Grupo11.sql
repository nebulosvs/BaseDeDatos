/*****************************************************
 * CASO 1: CÁLCULO DE PUNTOS CÍRCULO ALL THE BEST
 *****************************************************/
VARIABLE b_rango1_min NUMBER;
VARIABLE b_rango1_max NUMBER;
VARIABLE b_rango2_min NUMBER;
VARIABLE b_rango2_max NUMBER;
VARIABLE b_rango3_min NUMBER;

EXEC :b_rango1_min := 500000;
EXEC :b_rango1_max := 700000;
EXEC :b_rango2_min := 700001;
EXEC :b_rango2_max := 900000;
EXEC :b_rango3_min := 900001;

SET SERVEROUTPUT ON;

DECLARE
    TYPE t_arr_puntos IS VARRAY(4) OF NUMBER;
    v_puntos_arr t_arr_puntos := t_arr_puntos(250, 300, 550, 700);

    TYPE r_transaccion IS RECORD (
        numrun          CLIENTE.numrun%TYPE,
        dvrun           CLIENTE.dvrun%TYPE,
        nro_tarjeta     TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_transaccion TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_trans     TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        monto_trans     TRANSACCION_TARJETA_CLIENTE.monto_transaccion%TYPE,
        cod_tptran      TRANSACCION_TARJETA_CLIENTE.cod_tptran_tarjeta%TYPE,
        nom_tptran      TIPO_TRANSACCION_TARJETA.nombre_tptran_tarjeta%TYPE,
        cod_tp_cliente  CLIENTE.cod_tipo_cliente%TYPE
    );
    v_reg_trans r_transaccion;

    TYPE t_ref_cursor IS REF CURSOR;
    c_meses t_ref_cursor;
    v_mes_anno VARCHAR2(6);

    CURSOR c_detalle_trans (p_mes_anno VARCHAR2) IS
        SELECT 
            c.numrun, c.dvrun, tc.nro_tarjeta,
            ttc.nro_transaccion, ttc.fecha_transaccion,
            ttc.monto_transaccion, ttc.cod_tptran_tarjeta,
            ttt.nombre_tptran_tarjeta, c.cod_tipo_cliente
        FROM TRANSACCION_TARJETA_CLIENTE ttc
        JOIN TARJETA_CLIENTE tc ON ttc.nro_tarjeta = tc.nro_tarjeta
        JOIN CLIENTE c ON tc.numrun = c.numrun
        JOIN TIPO_TRANSACCION_TARJETA ttt ON ttc.cod_tptran_tarjeta = ttt.cod_tptran_tarjeta
        WHERE TO_CHAR(ttc.fecha_transaccion, 'MMYYYY') = p_mes_anno
        ORDER BY ttc.fecha_transaccion, c.numrun, ttc.nro_transaccion;

    v_anno_anterior NUMBER;
    v_puntos_base   NUMBER;
    v_puntos_extra  NUMBER;
    v_puntos_total  NUMBER;
    v_monto_anual   NUMBER;

    v_tot_monto_compra  NUMBER;
    v_tot_pts_compra    NUMBER;
    v_tot_monto_avance  NUMBER;
    v_tot_pts_avance    NUMBER;
    v_tot_monto_savance NUMBER;
    v_tot_pts_savance   NUMBER;

BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_PUNTOS_TARJETA_CATB';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_PUNTOS_TARJETA_CATB';

    v_anno_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

    OPEN c_meses FOR
        SELECT DISTINCT TO_CHAR(fecha_transaccion, 'MMYYYY')
        FROM TRANSACCION_TARJETA_CLIENTE
        WHERE EXTRACT(YEAR FROM fecha_transaccion) = v_anno_anterior
        ORDER BY 1;

    LOOP
        FETCH c_meses INTO v_mes_anno;
        EXIT WHEN c_meses%NOTFOUND;

        v_tot_monto_compra := 0; v_tot_pts_compra := 0;
        v_tot_monto_avance := 0; v_tot_pts_avance := 0;
        v_tot_monto_savance := 0; v_tot_pts_savance := 0;

        OPEN c_detalle_trans(v_mes_anno);
        LOOP
            FETCH c_detalle_trans INTO v_reg_trans;
            EXIT WHEN c_detalle_trans%NOTFOUND;

            v_puntos_base := TRUNC(v_reg_trans.monto_trans / 100000) * v_puntos_arr(1);
            v_puntos_extra := 0;

            /* MONTO ANUAL DEL CLIENTE */
            IF v_reg_trans.cod_tp_cliente IN (40, 50) THEN
                SELECT SUM(ttc.monto_transaccion)
                INTO v_monto_anual
                FROM TRANSACCION_TARJETA_CLIENTE ttc
                JOIN TARJETA_CLIENTE tc ON ttc.nro_tarjeta = tc.nro_tarjeta
                WHERE tc.numrun = v_reg_trans.numrun
                  AND EXTRACT(YEAR FROM ttc.fecha_transaccion) = v_anno_anterior;

                IF v_monto_anual BETWEEN :b_rango1_min AND :b_rango1_max THEN
                    v_puntos_extra := TRUNC(v_reg_trans.monto_trans / 100000) * v_puntos_arr(2);
                ELSIF v_monto_anual BETWEEN :b_rango2_min AND :b_rango2_max THEN
                    v_puntos_extra := TRUNC(v_reg_trans.monto_trans / 100000) * v_puntos_arr(3);
                ELSIF v_monto_anual >= :b_rango3_min THEN
                    v_puntos_extra := TRUNC(v_reg_trans.monto_trans / 100000) * v_puntos_arr(4);
                END IF;
            END IF;

            v_puntos_total := v_puntos_base + v_puntos_extra;

            INSERT INTO DETALLE_PUNTOS_TARJETA_CATB
            VALUES (
                v_reg_trans.numrun, v_reg_trans.dvrun, v_reg_trans.nro_tarjeta,
                v_reg_trans.nro_transaccion, v_reg_trans.fecha_trans,
                v_reg_trans.nom_tptran, v_reg_trans.monto_trans, v_puntos_total
            );

            IF v_reg_trans.nom_tptran LIKE 'Avance%' THEN
                v_tot_monto_avance := v_tot_monto_avance + v_reg_trans.monto_trans;
                v_tot_pts_avance := v_tot_pts_avance + v_puntos_total;
            ELSIF v_reg_trans.nom_tptran LIKE 'Súper%' THEN
                v_tot_monto_savance := v_tot_monto_savance + v_reg_trans.monto_trans;
                v_tot_pts_savance := v_tot_pts_savance + v_puntos_total;
            ELSE
                v_tot_monto_compra := v_tot_monto_compra + v_reg_trans.monto_trans;
                v_tot_pts_compra := v_tot_pts_compra + v_puntos_total;
            END IF;

        END LOOP;
        CLOSE c_detalle_trans;

        INSERT INTO RESUMEN_PUNTOS_TARJETA_CATB
        VALUES (
            v_mes_anno,
            v_tot_monto_compra, v_tot_pts_compra,
            v_tot_monto_avance, v_tot_pts_avance,
            v_tot_monto_savance, v_tot_pts_savance
        );

    END LOOP;
    CLOSE c_meses;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Caso 1 ejecutado correctamente.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error Caso 1: ' || SQLERRM);
END;
/
-- Comprobacion: calculo de puntos por transaccion 
-- multiplicar manualmente TRUNC(monto / 100000) × 250
SELECT 
    monto_transaccion,
    puntos_allthebest
FROM DETALLE_PUNTOS_TARJETA_CATB
FETCH FIRST 10 ROWS ONLY;


/**************************************************************
 * CASO 2: CÁLCULO APORTE SBIF – AVANCES Y SÚPER AVANCES
 * Procesa transacciones del año en curso y genera
 * información DETALLE y RESUMEN para SBIF.
 **************************************************************/

SET SERVEROUTPUT ON;

DECLARE
    /* ===============================
       AÑO DE PROCESO (PARAMÉTRICO)
       =============================== */
    v_anio_proceso NUMBER := EXTRACT(YEAR FROM SYSDATE);

    /* ===============================
       VARIABLES DE CÁLCULO
       =============================== */
    v_porcentaje   NUMBER;
    v_aporte       NUMBER;
    v_mes_anno     VARCHAR2(6);

    /* Acumuladores para RESUMEN */
    v_monto_total_mes  NUMBER := 0;
    v_aporte_total_mes NUMBER := 0;

    /* ===============================
       REGISTRO PL/SQL
       =============================== */
    TYPE r_avance IS RECORD (
        numrun        CLIENTE.numrun%TYPE,
        dvrun         CLIENTE.dvrun%TYPE,
        nro_tarjeta   TRANSACCION_TARJETA_CLIENTE.nro_tarjeta%TYPE,
        nro_trans     TRANSACCION_TARJETA_CLIENTE.nro_transaccion%TYPE,
        fecha_trans   TRANSACCION_TARJETA_CLIENTE.fecha_transaccion%TYPE,
        monto_total   TRANSACCION_TARJETA_CLIENTE.monto_total_transaccion%TYPE,
        cod_tptran    TRANSACCION_TARJETA_CLIENTE.cod_tptran_tarjeta%TYPE
    );
    v_reg r_avance;

    /* ===============================
       CURSOR 1: MESES DEL AÑO
       =============================== */
    CURSOR c_meses IS
        SELECT DISTINCT TO_CHAR(fecha_transaccion, 'MMYYYY') mes_anno
        FROM TRANSACCION_TARJETA_CLIENTE
        WHERE EXTRACT(YEAR FROM fecha_transaccion) = v_anio_proceso
          AND cod_tptran_tarjeta IN (102,103)
        ORDER BY mes_anno;

    /* ===============================
       CURSOR 2: AVANCES / SÚPER AVANCES
       =============================== */
    CURSOR c_avances (p_mes VARCHAR2) IS
        SELECT
            c.numrun,
            c.dvrun,
            t.nro_tarjeta,
            t.nro_transaccion,
            t.fecha_transaccion,
            t.monto_total_transaccion,
            t.cod_tptran_tarjeta
        FROM TRANSACCION_TARJETA_CLIENTE t
        JOIN TARJETA_CLIENTE tc ON t.nro_tarjeta = tc.nro_tarjeta
        JOIN CLIENTE c ON tc.numrun = c.numrun
        WHERE TO_CHAR(t.fecha_transaccion, 'MMYYYY') = p_mes
          AND t.cod_tptran_tarjeta IN (102,103)
        ORDER BY t.fecha_transaccion, c.numrun;

BEGIN
    /* ===============================
       LIMPIEZA DE TABLAS
       =============================== */
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';

    /* ===============================
       PROCESO PRINCIPAL
       =============================== */
    OPEN c_meses;
    LOOP
        FETCH c_meses INTO v_mes_anno;
        EXIT WHEN c_meses%NOTFOUND;

        v_monto_total_mes  := 0;
        v_aporte_total_mes := 0;

        OPEN c_avances(v_mes_anno);
        LOOP
            FETCH c_avances INTO v_reg;
            EXIT WHEN c_avances%NOTFOUND;

            /* ===============================
               OBTENER PORCENTAJE SBIF
               =============================== */
            SELECT porc_aporte_sbif
            INTO v_porcentaje
            FROM TRAMO_APORTE_SBIF
            WHERE v_reg.monto_total
                  BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;

            /* ===============================
               CÁLCULO DEL APORTE (PL/SQL)
               =============================== */
            v_aporte := ROUND(v_reg.monto_total * v_porcentaje / 100);

            /* ===============================
               INSERT DETALLE
               =============================== */
            INSERT INTO DETALLE_APORTE_SBIF (
                numrun,
                dvrun,
                nro_tarjeta,
                nro_transaccion,
                fecha_transaccion,
                tipo_transaccion,
                monto_transaccion,
                aporte_sbif
            ) VALUES (
                v_reg.numrun,
                v_reg.dvrun,
                v_reg.nro_tarjeta,
                v_reg.nro_trans,
                v_reg.fecha_trans,
                CASE v_reg.cod_tptran
                    WHEN 102 THEN 'Avance'
                    WHEN 103 THEN 'Súper Avance'
                END,
                v_reg.monto_total,
                v_aporte
            );

            v_monto_total_mes  := v_monto_total_mes + v_reg.monto_total;
            v_aporte_total_mes := v_aporte_total_mes + v_aporte;

        END LOOP;
        CLOSE c_avances;

        /* ===============================
           INSERT RESUMEN
           =============================== */
        INSERT INTO RESUMEN_APORTE_SBIF (
            mes_anno,
            tipo_transaccion,
            monto_total_transacciones,
            aporte_total_abif
        ) VALUES (
            v_mes_anno,
            'Avance / Súper Avance',
            v_monto_total_mes,
            v_aporte_total_mes
        );

    END LOOP;
    CLOSE c_meses;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('CASO 2 ejecutado correctamente');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error CASO 2: ' || SQLERRM);
END;
/

-- Comprobación: ambos conteos son iguales.
SELECT COUNT(*) 
FROM DETALLE_APORTE_SBIF;


SELECT COUNT(*) 
FROM TRANSACCION_TARJETA_CLIENTE
WHERE cod_tptran_tarjeta IN (102,103)
  AND EXTRACT(YEAR FROM fecha_transaccion) = EXTRACT(YEAR FROM SYSDATE);

-- Comprobacion 2: se esta usando el tramo que corresponde.
SELECT 
    monto_transaccion,
    aporte_sbif,
    ROUND(aporte_sbif / monto_transaccion * 100, 2) AS porcentaje_real
FROM DETALLE_APORTE_SBIF
FETCH FIRST 5 ROWS ONLY;

SELECT *
FROM TRAMO_APORTE_SBIF;



