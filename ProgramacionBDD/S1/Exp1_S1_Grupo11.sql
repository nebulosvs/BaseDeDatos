
/*==============================================================
               CASO 1: PROGRAMA TODO SUMA
==============================================================*/

-- 1. Limpiar y configurar sesión
ROLLBACK;
ALTER SESSION DISABLE PARALLEL DML;

-- 2. Variables BIND
VARIABLE b_run NUMBER
VARIABLE b_monto_tramo1 NUMBER
VARIABLE b_monto_tramo2 NUMBER
VARIABLE b_pesos_normal NUMBER
VARIABLE b_pesos_extra1 NUMBER
VARIABLE b_pesos_extra2 NUMBER
VARIABLE b_pesos_extra3 NUMBER

-- 3. Asignar valores (MODIFICAR AQUÍ EL RUN PARA CADA CLIENTE)
BEGIN
    -- Aquí se cambiaría para que cliente se quiere ejecutar el bloque (Solo b_run que simboliza el rut sin puntos ni guión)
    -- :b_run := 21242003;          -- RUN de Karen Sofía Pradenas
    -- :b_run := 22176845;          -- RUN de Silvana Martina Valenzuela
    -- :b_run := 18858542;          -- RUN de Denisse Alicia Díaz
    -- :b_run := 21300628;          -- RUN de Luis Claudio Luna
    -- :b_run := 22558061;          -- RUN de Amanda Romina Lizana
    :b_monto_tramo1 := 1000000;
    :b_monto_tramo2 := 3000000;
    :b_pesos_normal := 1200;
    :b_pesos_extra1 := 100;
    :b_pesos_extra2 := 300;
    :b_pesos_extra3 := 550;
END;
/

-- 4. Bloque PL/SQL Principal
DECLARE
    -- Variables para datos del cliente
    v_nro_cliente       CLIENTE.nro_cliente%TYPE;
    v_run_cliente       CLIENTE.numrun%TYPE;
    v_dv_cliente        CLIENTE.dvrun%TYPE;
    v_nombre_completo   VARCHAR2(50);
    v_tipo_cliente      TIPO_CLIENTE.nombre_tipo_cliente%TYPE;
    
    -- Variables para cálculos
    v_monto_total_solic NUMBER(12) := 0;
    v_total_pesos       NUMBER(12) := 0;
    v_pesos_base        NUMBER(12) := 0;
    v_pesos_extra       NUMBER(12) := 0;
    
    c_factor_monto      CONSTANT NUMBER := 100000;

BEGIN
    -- 1. Obtener datos personales (Incluyendo NRO_CLIENTE)
    SELECT c.nro_cliente,
           c.numrun, 
           c.dvrun, 
           SUBSTR(UPPER(c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno), 1, 50),
           tc.nombre_tipo_cliente
    INTO v_nro_cliente, v_run_cliente, v_dv_cliente, v_nombre_completo, v_tipo_cliente
    FROM cliente c
    JOIN tipo_cliente tc ON c.cod_tipo_cliente = tc.cod_tipo_cliente 
    WHERE c.numrun = :b_run;

    -- 2. Calcular monto total solicitado año anterior
    SELECT NVL(SUM(monto_solicitado), 0)
    INTO v_monto_total_solic
    FROM credito_cliente
    WHERE nro_cliente = v_nro_cliente
      AND EXTRACT(YEAR FROM fecha_solic_cred) = EXTRACT(YEAR FROM SYSDATE) - 1;

    -- 3. Cálculos de Pesos
    v_pesos_base := TRUNC(v_monto_total_solic / c_factor_monto) * :b_pesos_normal;

    IF v_tipo_cliente = 'Trabajadores independientes' THEN
        IF v_monto_total_solic < :b_monto_tramo1 THEN
            v_pesos_extra := TRUNC(v_monto_total_solic / c_factor_monto) * :b_pesos_extra1;
        ELSIF v_monto_total_solic >= :b_monto_tramo1 AND v_monto_total_solic <= :b_monto_tramo2 THEN
            v_pesos_extra := TRUNC(v_monto_total_solic / c_factor_monto) * :b_pesos_extra2;
        ELSIF v_monto_total_solic > :b_monto_tramo2 THEN
            v_pesos_extra := TRUNC(v_monto_total_solic / c_factor_monto) * :b_pesos_extra3;
        END IF;
    END IF;

    v_total_pesos := v_pesos_base + v_pesos_extra;

    -- 4. INSERTAR DATOS (Ahora incluyendo NRO_CLIENTE)
    
    -- Borrar registro previo si existe
    DELETE FROM cliente_todosuma WHERE nro_cliente = v_nro_cliente;
    
    INSERT INTO cliente_todosuma (
        nro_cliente,
        run_cliente, 
        nombre_cliente, 
        tipo_cliente, 
        monto_solic_creditos, 
        monto_pesos_todosuma
    ) VALUES (
        v_nro_cliente,
        v_run_cliente || '-' || v_dv_cliente,
        v_nombre_completo,
        v_tipo_cliente,
        v_monto_total_solic,
        v_total_pesos
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('EXITO: Proceso finalizado para ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('Monto Solicitado Año Anterior: ' || v_monto_total_solic);
    DBMS_OUTPUT.PUT_LINE('Total Pesos Calculados: ' || v_total_pesos);


EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Error: Cliente no encontrado con RUN ' || :b_run);
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('Error: RUN duplicado. Verifique datos del cliente para RUN ' || :b_run);
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
    ROLLBACK;
END;
/

-- SELECT * FROM CLIENTE_TODOSUMA; (PARA REVISAR LA TABLA CON LOS DATOS)


/*==============================================================
               CASO 2: POSTERGACION DE CUOTAS
==============================================================*/


-- 1. Limpieza de sesión
ROLLBACK;
ALTER SESSION DISABLE PARALLEL DML;

-- 2. Variables BIND
VARIABLE b_nro_cliente NUMBER
VARIABLE b_nro_solic NUMBER
VARIABLE b_cant_postergar NUMBER

-- 3. ASIGNACIÓN DE VALORES (Se descomenta el bloque que se quiera probar)
BEGIN
    -------------------------------------------------------------------------
    -- CASO A: Sebastian Patricio (Solicitud 2001)
    -- :b_nro_cliente := 5; :b_nro_solic := 2001; :b_cant_postergar := 2; 
    -------------------------------------------------------------------------
    -- CASO B: Karen Sofia (Solicitud 3004)
    -- :b_nro_cliente := 67; :b_nro_solic := 3004; :b_cant_postergar := 1;
    -------------------------------------------------------------------------
    -- CASO C: Julian Paul (Solicitud 2004) -> PRUEBA ESTE PRIMERO
    -- :b_nro_cliente := 13; :b_nro_solic := 2004; :b_cant_postergar := 1;
    -------------------------------------------------------------------------
END;
/

-- 4. Bloque PL/SQL
DECLARE
    v_cod_credito       NUMBER(3); 
    v_tasa_interes      NUMBER(4,3); 
    
    v_ult_num_cuota     NUMBER(3);
    v_ult_fecha_venc    DATE;
    v_ult_valor_cuota   NUMBER(12);
    
    v_nuevo_valor_cuota NUMBER(12);
    v_nueva_fecha_venc  DATE;
    
    v_cant_creditos_ant NUMBER; 
    
BEGIN
    -- 1. Obtener datos del crédito
    SELECT cc.cod_credito, 
           MAX(cu.nro_cuota),
           MAX(cu.fecha_venc_cuota)
    INTO v_cod_credito, v_ult_num_cuota, v_ult_fecha_venc
    FROM credito_cliente cc
    JOIN cuota_credito_cliente cu ON cc.nro_solic_credito = cu.nro_solic_credito
    WHERE cc.nro_solic_credito = :b_nro_solic
      AND cc.nro_cliente = :b_nro_cliente
    GROUP BY cc.cod_credito;

    -- Obtener valor de la última cuota
    SELECT valor_cuota 
    INTO v_ult_valor_cuota
    FROM cuota_credito_cliente
    WHERE nro_solic_credito = :b_nro_solic 
      AND nro_cuota = v_ult_num_cuota;

    -- 2. Calcular Tasa de Interés
    -- 1=Hipotecario, 2=Consumo, 3=Automotriz
    IF v_cod_credito = 1 THEN 
        IF :b_cant_postergar = 1 THEN v_tasa_interes := 0;
        ELSE v_tasa_interes := 0.005; END IF;
    ELSIF v_cod_credito = 2 THEN 
        v_tasa_interes := 0.01;
    ELSIF v_cod_credito = 3 THEN 
        v_tasa_interes := 0.02;
    ELSE
        v_tasa_interes := 0;
    END IF;

    v_nuevo_valor_cuota := ROUND(v_ult_valor_cuota * (1 + v_tasa_interes));

    -- 3. Insertar nuevas cuotas
    FOR i IN 1 .. :b_cant_postergar LOOP
        v_nueva_fecha_venc := ADD_MONTHS(v_ult_fecha_venc, i);
        
        INSERT INTO cuota_credito_cliente (
            nro_solic_credito, 
            nro_cuota, 
            fecha_venc_cuota, 
            valor_cuota,
            fecha_pago_cuota, 
            monto_pagado, 
            saldo_por_pagar, 
            cod_forma_pago
        ) VALUES (
            :b_nro_solic,
            v_ult_num_cuota + i,
            v_nueva_fecha_venc,
            v_nuevo_valor_cuota,
            NULL, NULL, NULL, NULL
        );
    END LOOP;

    -- 4. Regla Multiproducto (Condonación)
    SELECT COUNT(*)
    INTO v_cant_creditos_ant
    FROM credito_cliente
    WHERE nro_cliente = :b_nro_cliente
      AND EXTRACT(YEAR FROM fecha_solic_cred) = EXTRACT(YEAR FROM SYSDATE) - 1;

    IF v_cant_creditos_ant > 1 THEN
        -- Se actualizan TODOS los campos de pago
        UPDATE cuota_credito_cliente
        SET fecha_pago_cuota = fecha_venc_cuota,
            monto_pagado = valor_cuota,
            saldo_por_pagar = 0,
            cod_forma_pago = 1  -- 1 = Efectivo (Numérico)
        WHERE nro_solic_credito = :b_nro_solic
          AND nro_cuota = v_ult_num_cuota;
          
        DBMS_OUTPUT.PUT_LINE('INFO: Cuota ' || v_ult_num_cuota || ' condonada por multiproducto.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('EXITO: Solicitud ' || :b_nro_solic || ' actualizada.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Verifica que el Cliente '||:b_nro_cliente||' sea dueño de la Solicitud '||:b_nro_solic);
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: SELECT devolvió más de una fila (revisar filtros).');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
END;
/

/* PARA REVISAR LA SOLICITUD
SELECT 
    nro_solic_credito,
    nro_cuota,
    fecha_venc_cuota,
    valor_cuota,
    fecha_pago_cuota,
    monto_pagado,
    saldo_por_pagar,
    cod_forma_pago
FROM cuota_credito_cliente
WHERE nro_solic_credito = 2004  -- <--- SE CAMBIA EL NÚMERO DE SOLICITUD
ORDER BY nro_cuota ASC; 
*/