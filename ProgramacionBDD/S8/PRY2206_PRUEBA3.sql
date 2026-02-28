SET SERVEROUTPUT ON;

/*=========================================================
                         CASO 1
=========================================================*/
/*=========================================================
 TRIGGER: TRG_TOTAL_CONSUMOS
 Descripción:
 Mantiene actualizada la tabla TOTAL_CONSUMOS
 ante INSERT, UPDATE o DELETE en CONSUMO
=========================================================*/

CREATE OR REPLACE TRIGGER trg_total_consumos
AFTER INSERT OR UPDATE OR DELETE ON consumo
FOR EACH ROW
DECLARE
    v_existe NUMBER;
BEGIN

    /* =========================
       CASO INSERT
       ========================= */
    IF INSERTING THEN

        SELECT COUNT(*)
        INTO v_existe
        FROM total_consumos
        WHERE id_huesped = :NEW.id_huesped;

        IF v_existe = 0 THEN
            INSERT INTO total_consumos
            VALUES (:NEW.id_huesped, :NEW.monto);
        ELSE
            UPDATE total_consumos
            SET monto_consumos = monto_consumos + :NEW.monto
            WHERE id_huesped = :NEW.id_huesped;
        END IF;

    END IF;


    /* =========================
       CASO UPDATE
       ========================= */
    IF UPDATING THEN

        UPDATE total_consumos
        SET monto_consumos = monto_consumos - :OLD.monto + :NEW.monto
        WHERE id_huesped = :OLD.id_huesped;

    END IF;


    /* =========================
       CASO DELETE
       ========================= */
    IF DELETING THEN

        UPDATE total_consumos
        SET monto_consumos = monto_consumos - :OLD.monto
        WHERE id_huesped = :OLD.id_huesped;

    END IF;

END;
/

/*=========================================================
 TRIGGER: TRG_TOTAL_CONSUMOS
 Descripción: Prueba solicitada
=========================================================*/
DECLARE
    v_nueva_id NUMBER;
    v_total NUMBER;
BEGIN

    DBMS_OUTPUT.PUT_LINE('===== INICIO PRUEBA TRIGGER =====');

    /* Obtener siguiente ID */
    SELECT NVL(MAX(id_consumo),0) + 1
    INTO v_nueva_id
    FROM consumo;

    DBMS_OUTPUT.PUT_LINE('Nuevo ID generado: ' || v_nueva_id);

    /* Mostrar total antes del INSERT */
    BEGIN
        SELECT monto_consumos
        INTO v_total
        FROM total_consumos
        WHERE id_huesped = 340006;

        DBMS_OUTPUT.PUT_LINE('Total antes INSERT: ' || v_total);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Total antes INSERT: 0 (no existía registro)');
    END;


    /* ===============================
       INSERT
       =============================== */
    INSERT INTO consumo
    VALUES (v_nueva_id, 1587, 340006, 150);

    DBMS_OUTPUT.PUT_LINE('INSERT realizado: +150');


    /* Mostrar total después INSERT */
    SELECT monto_consumos
    INTO v_total
    FROM total_consumos
    WHERE id_huesped = 340006;

    DBMS_OUTPUT.PUT_LINE('Total después INSERT: ' || v_total);


    /* ===============================
       DELETE
       =============================== */
    DELETE FROM consumo
    WHERE id_consumo = 11473;

    DBMS_OUTPUT.PUT_LINE('DELETE realizado: -monto de ID 11473');


    /* ===============================
       UPDATE
       =============================== */
    UPDATE consumo
    SET monto = 95
    WHERE id_consumo = 10688;

    DBMS_OUTPUT.PUT_LINE('UPDATE realizado: monto ID 10688 ahora = 95');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('===== FIN PRUEBA TRIGGER =====');

END;
/

SELECT * FROM consumo
WHERE id_huesped IN (340003, 340004, 340006, 340008, 340009)
ORDER BY id_huesped, id_consumo;


SELECT * FROM total_consumos
WHERE id_huesped IN (340003, 340004, 340006, 340008, 340009)
ORDER BY id_huesped;


/*=========================================================
                           CASO 2
=========================================================*/

/*=========================================================
 PACKAGE: PKG_TOURS
 Descripción:
 Contiene variable pública y función para calcular
 el total de tours contratados por un huésped en USD.
=========================================================*/
CREATE OR REPLACE PACKAGE pkg_tours IS

    /* Variable pública que almacena el total calculado */
    v_total_tours NUMBER;

    /* Función que retorna el total de tours en USD */
    FUNCTION fn_total_tours_usd (
        p_id_huesped NUMBER
    ) RETURN NUMBER;

END pkg_tours;
/

/*=========================================================
 PACKAGE BODY: PKG_TOURS
=========================================================*/
CREATE OR REPLACE PACKAGE BODY pkg_tours IS

    FUNCTION fn_total_tours_usd (
        p_id_huesped NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER := 0;
    BEGIN

        /* Se suman los tours contratados por el huésped */
        SELECT NVL(SUM(ht.num_personas * t.valor_tour),0)
        INTO v_total
        FROM huesped_tour ht
        JOIN tour t ON ht.id_tour = t.id_tour
        WHERE ht.id_huesped = p_id_huesped;

        /* Se almacena en variable pública */
        v_total_tours := v_total;

        RETURN v_total;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END;

END pkg_tours;
/

/*=========================================================
 FUNCIÓN: fn_nombre_agencia
 Descripción:
 Retorna el nombre de la agencia asociada al huésped.
 Si no tiene agencia, registra error en REG_ERRORES
 y retorna 'NO REGISTRA AGENCIA'.
=========================================================*/
CREATE OR REPLACE FUNCTION fn_nombre_agencia (
    p_id_huesped NUMBER
) RETURN VARCHAR2
IS
    v_nombre VARCHAR2(40);
BEGIN

    SELECT a.nom_agencia
    INTO v_nombre
    FROM huesped h
    JOIN agencia a ON h.id_agencia = a.id_agencia
    WHERE h.id_huesped = p_id_huesped;

    RETURN v_nombre;

EXCEPTION
    WHEN NO_DATA_FOUND THEN

        INSERT INTO reg_errores
        VALUES (
            sq_error.NEXTVAL,
            'fn_nombre_agencia',
            'Huesped sin agencia'
        );

        RETURN 'NO REGISTRA AGENCIA';
END;
/
/*=========================================================
 FUNCIÓN: fn_total_consumos
 Descripción:
 Retorna el total de consumos del huésped desde
 la tabla TOTAL_CONSUMOS.
 Si no existe registro, retorna 0.
=========================================================*/
CREATE OR REPLACE FUNCTION fn_total_consumos (
    p_id_huesped NUMBER
) RETURN NUMBER
IS
    v_total NUMBER;
BEGIN

    SELECT monto_consumos
    INTO v_total
    FROM total_consumos
    WHERE id_huesped = p_id_huesped;

    RETURN v_total;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/
/*=========================================================
 PROCEDIMIENTO: sp_proceso_diario
 Descripción:
 Genera el detalle diario de huéspedes que salen
 en la fecha indicada.
 Parámetros:
   p_fecha_proceso  → Fecha de salida
   p_tipo_cambio    → Valor dólar
=========================================================*/
CREATE OR REPLACE PROCEDURE sp_proceso_diario (
    p_fecha_proceso DATE,
    p_tipo_cambio NUMBER
)
IS

    /* Variables generales */
    v_nombre VARCHAR2(60);
    v_agencia VARCHAR2(40);

    /* Valores en USD */
    v_alojamiento_usd NUMBER;
    v_consumos_usd NUMBER;
    v_tours_usd NUMBER;
    v_subtotal_usd NUMBER;

    /* Valores en pesos */
    v_subtotal_pesos NUMBER;
    v_desc_consumos NUMBER := 0;
    v_desc_agencia NUMBER := 0;
    v_total_final NUMBER;

    v_pct_tramo NUMBER := 0;

BEGIN

    /* Limpieza previa de la tabla */
    EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_diario_huespedes';

    /* Cursor implícito: huéspedes que salen en la fecha */
    FOR rec IN (
        SELECT r.id_reserva,
               h.id_huesped,
               h.appat_huesped || ' ' || h.nom_huesped nombre,
               r.estadia,
               dr.id_habitacion,
               ha.valor_habitacion,
               ha.valor_minibar
        FROM reserva r
        JOIN huesped h ON r.id_huesped = h.id_huesped
        JOIN detalle_reserva dr ON r.id_reserva = dr.id_reserva
        JOIN habitacion ha ON dr.id_habitacion = ha.id_habitacion
        WHERE r.ingreso + r.estadia = p_fecha_proceso
    )
    LOOP

        /* Se guarda nombre */
        v_nombre := rec.nombre;

        /* ==============================
           Cálculo alojamiento (USD)
           ============================== */
        v_alojamiento_usd :=
            (rec.valor_habitacion + rec.valor_minibar) * rec.estadia;

        /* ==============================
           Total consumos (USD)
           ============================== */
        v_consumos_usd :=
            fn_total_consumos(rec.id_huesped);

        /* ==============================
           Total tours (USD)
           ============================== */
        v_tours_usd :=
            pkg_tours.fn_total_tours_usd(rec.id_huesped);

        /* ==============================
           Subtotal en USD
           ============================== */
        v_subtotal_usd :=
            v_alojamiento_usd + v_consumos_usd + v_tours_usd;

        /* ==============================
           Convertir a pesos y sumar
              cargo fijo de $35.000
           ============================== */
        v_subtotal_pesos :=
            ROUND((v_subtotal_usd * p_tipo_cambio) + 35000);

        /* ==============================
           Descuento por tramo consumo
           ============================== */
        BEGIN
            SELECT pct
            INTO v_pct_tramo
            FROM tramos_consumos
            WHERE v_consumos_usd
                  BETWEEN vmin_tramo AND vmax_tramo;

            v_desc_consumos :=
                ROUND(v_subtotal_pesos * (v_pct_tramo/100));

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_desc_consumos := 0;
        END;

        /* ==============================
           Descuento agencia
           Solo si es VIAJES ALBERTI
           ============================== */
        v_agencia :=
            fn_nombre_agencia(rec.id_huesped);

        IF v_agencia = 'VIAJES ALBERTI' THEN
            v_desc_agencia :=
                ROUND(v_subtotal_pesos * 0.12);
        ELSE
            v_desc_agencia := 0;
        END IF;

        /* ==============================
           Total final
           ============================== */
        v_total_final :=
            v_subtotal_pesos - v_desc_consumos - v_desc_agencia;

        /* ==============================
           Insertar resultado
           ============================== */
        INSERT INTO detalle_diario_huespedes
        VALUES (
            rec.id_huesped,
            v_nombre,
            v_agencia,
            ROUND(v_alojamiento_usd * p_tipo_cambio),
            ROUND(v_consumos_usd * p_tipo_cambio),
            ROUND(v_tours_usd * p_tipo_cambio),
            v_subtotal_pesos,
            v_desc_consumos,
            v_desc_agencia,
            v_total_final
        );

    END LOOP;

    COMMIT;

END;
/

SELECT * FROM reserva
WHERE ingreso + estadia = TO_DATE('18/08/2021', 'DD/MM/YYYY')
ORDER BY id_huesped;


