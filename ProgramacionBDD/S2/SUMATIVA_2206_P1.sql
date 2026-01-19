/*==============================================================
  SUMATIVA S2 - TRUCK RENTAL
  CASO: USUARIO_CLAVE (generación de usuario y clave por empleado)

  Requerimientos clave:
  - Bloque PL/SQL anónimo
  - Procesar todos los empleados (id_emp 100 a 320), 1 por iteración
  - Usar variable BIND para fecha de proceso (declarar + asignar + usar)
  - Usar al menos 3 variables con %TYPE
  - Cálculos en PL/SQL (NO dentro de SELECT)
  - Redondear a enteros cuando corresponda
  - TRUNCAR USUARIO_CLAVE en tiempo de ejecución (Dynamic SQL)
  - COMMIT solo si termina correctamente y realiza todas las iteraciones
  - Documentación 
==============================================================*/

SET SERVEROUTPUT ON;

DECLARE
  /*==============================================================
    FECHA DE PROCESO PARAMÉTRICA (BIND TEXTO)
    - En SQL Developer te pedirá :b_fecha_txt en el cuadro "Introducir enlaces"
    - Valores válidos:
        * HOY
        * DD-MM-YYYY   (ej: 19-01-2026)
    - Se convierte a DATE en v_fecha_proceso para usarla en cálculos
  ==============================================================*/
  v_fecha_proceso DATE;

  /*------------------------------------------------------------
    Variables %TYPE 
  ------------------------------------------------------------*/
  v_id_emp           EMPLEADO.id_emp%TYPE;
  v_numrun_emp       EMPLEADO.numrun_emp%TYPE;
  v_dvrun_emp        EMPLEADO.dvrun_emp%TYPE;
  v_appaterno        EMPLEADO.appaterno_emp%TYPE;
  v_apmaterno        EMPLEADO.apmaterno_emp%TYPE;
  v_pnombre          EMPLEADO.pnombre_emp%TYPE;
  v_snombre          EMPLEADO.snombre_emp%TYPE;
  v_fecha_nac        EMPLEADO.fecha_nac%TYPE;
  v_fecha_contrato   EMPLEADO.fecha_contrato%TYPE;
  v_sueldo_base      EMPLEADO.sueldo_base%TYPE;
  v_nom_est_civil    ESTADO_CIVIL.nombre_estado_civil%TYPE; 

  /*------------------------------------------------------------
    Variables de salida / auxiliares
  ------------------------------------------------------------*/
  v_nombre_empleado  VARCHAR2(80);
  v_nombre_usuario   VARCHAR2(50);
  v_clave_usuario    VARCHAR2(80);

  -- Usuario: partes
  v_ec_letra         CHAR(1);
  v_3pnombre         VARCHAR2(3);
  v_largo_pnombre    NUMBER;
  v_ult_dig_sueldo   CHAR(1);
  v_anios_trab       NUMBER;

  -- Clave: partes
  v_run_str          VARCHAR2(10);
  v_3er_dig_run      CHAR(1);
  v_anno_nac_mas2    NUMBER;
  v_ult3_sueldo      NUMBER;
  v_ult3_sueldo_m1   NUMBER;
  v_ult3_sueldo_txt  VARCHAR2(3);
  v_letras_ap        VARCHAR2(2);
  v_mmYYYY           VARCHAR2(6);

  /*------------------------------------------------------------
    Control de proceso (commit condicional)
  ------------------------------------------------------------*/
  v_total_emp        NUMBER := 0;
  v_ok               NUMBER := 0;
  v_err              NUMBER := 0;

BEGIN
  /*==============================================================
    PASO 1 (continuación): interpretar la bind texto
  ==============================================================*/
  -- Validación: bind obligatoria
  IF :b_fecha_txt IS NULL OR TRIM(:b_fecha_txt) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'Debe ingresar :b_fecha_txt (HOY o DD-MM-YYYY).');
  END IF;

  -- Conversión: HOY => SYSDATE, si no => TO_DATE(formato fijo)
  IF UPPER(TRIM(:b_fecha_txt)) = 'HOY' THEN
    v_fecha_proceso := SYSDATE;
  ELSE
    v_fecha_proceso := TO_DATE(TRIM(:b_fecha_txt), 'DD-MM-YYYY');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Fecha proceso (paramétrica): ' || TO_CHAR(v_fecha_proceso,'DD-MM-YYYY HH24:MI:SS'));

  /*------------------------------------------------------------
    TRUNCATE dinámico tabla destino (permite re-ejecución)
  ------------------------------------------------------------*/
  EXECUTE IMMEDIATE 'TRUNCATE TABLE USUARIO_CLAVE';

  /*------------------------------------------------------------
    Total empleados a procesar (id 100..320)
  ------------------------------------------------------------*/
  SELECT COUNT(*)
    INTO v_total_emp
    FROM EMPLEADO
   WHERE id_emp BETWEEN 100 AND 320;

  DBMS_OUTPUT.PUT_LINE('Inicio. Total empleados a procesar=' || v_total_emp);

  /*------------------------------------------------------------
    Loop: 1 empleado por iteración (cursor implícito)
  ------------------------------------------------------------*/
  FOR r IN (
    SELECT e.id_emp,
           e.numrun_emp,
           e.dvrun_emp,
           e.appaterno_emp,
           e.apmaterno_emp,
           e.pnombre_emp,
           e.snombre_emp,
           e.fecha_nac,
           e.fecha_contrato,
           e.sueldo_base,
           ec.nombre_estado_civil
      FROM EMPLEADO e
      JOIN ESTADO_CIVIL ec
        ON ec.id_estado_civil = e.id_estado_civil
     WHERE e.id_emp BETWEEN 100 AND 320
     ORDER BY e.id_emp
  ) LOOP

    SAVEPOINT sp_emp;

    BEGIN
      /*--------------------------------------------------------
        Asignación a variables %TYPE
      --------------------------------------------------------*/
      v_id_emp         := r.id_emp;
      v_numrun_emp     := r.numrun_emp;
      v_dvrun_emp      := r.dvrun_emp;
      v_appaterno      := r.appaterno_emp;
      v_apmaterno      := r.apmaterno_emp;
      v_pnombre        := r.pnombre_emp;
      v_snombre        := r.snombre_emp;
      v_fecha_nac      := r.fecha_nac;
      v_fecha_contrato := r.fecha_contrato;
      v_sueldo_base    := r.sueldo_base;
      v_nom_est_civil  := r.nombre_estado_civil;

      /*--------------------------------------------------------
        Nombre empleado (para tabla salida)
      --------------------------------------------------------*/
      v_nombre_empleado :=
        REGEXP_REPLACE(
          TRIM(v_pnombre || ' ' || NVL(v_snombre,'') || ' ' || v_appaterno || ' ' || v_apmaterno),
          '\s+',
          ' '
        );

      /*--------------------------------------------------------
        Años trabajando (entero) usando v_fecha_proceso (DATE real)
      --------------------------------------------------------*/
      v_anios_trab := TRUNC(MONTHS_BETWEEN(v_fecha_proceso, v_fecha_contrato) / 12);

      /*--------------------------------------------------------
        NOMBRE_USUARIO (reglas)
      --------------------------------------------------------*/
      v_ec_letra := LOWER(SUBSTR(v_nom_est_civil, 1, 1));
      v_3pnombre := UPPER(SUBSTR(v_pnombre, 1, 3));
      v_largo_pnombre := LENGTH(v_pnombre);
      v_ult_dig_sueldo := TO_CHAR(MOD(v_sueldo_base, 10));

      v_nombre_usuario :=
          v_ec_letra
        || v_3pnombre
        || TO_CHAR(v_largo_pnombre)
        || '*'
        || v_ult_dig_sueldo
        || v_dvrun_emp
        || TO_CHAR(v_anios_trab);

      IF v_anios_trab < 10 THEN
        v_nombre_usuario := v_nombre_usuario || 'X';
      END IF;

      /*--------------------------------------------------------
        CLAVE_USUARIO (reglas)
      --------------------------------------------------------*/
      v_run_str := LPAD(TO_CHAR(v_numrun_emp), 10, '0');
      v_3er_dig_run := SUBSTR(v_run_str, 3, 1);
      v_anno_nac_mas2 := EXTRACT(YEAR FROM v_fecha_nac) + 2;

      v_ult3_sueldo := MOD(v_sueldo_base, 1000);
      v_ult3_sueldo_m1 := v_ult3_sueldo - 1;
      IF v_ult3_sueldo_m1 < 0 THEN
        v_ult3_sueldo_m1 := 0;
      END IF;
      v_ult3_sueldo_txt := LPAD(TO_CHAR(v_ult3_sueldo_m1), 3, '0');

      IF v_nom_est_civil IN ('CASADO','CASADA','AUC') THEN
        v_letras_ap := LOWER(SUBSTR(v_appaterno, 1, 2));
      ELSIF v_nom_est_civil IN ('DIVORCIADO','DIVORCIADA','SOLTERO','SOLTERA') THEN
        v_letras_ap := LOWER(SUBSTR(v_appaterno, 1, 1) || SUBSTR(v_appaterno, LENGTH(v_appaterno), 1));
      ELSIF v_nom_est_civil IN ('VIUDO','VIUDA') THEN
        v_letras_ap := LOWER(
          SUBSTR(v_appaterno, LENGTH(v_appaterno) - 2, 1) ||
          SUBSTR(v_appaterno, LENGTH(v_appaterno) - 1, 1)
        );
      ELSIF v_nom_est_civil IN ('SEPARADO','SEPARADA') THEN
        v_letras_ap := LOWER(SUBSTR(v_appaterno, LENGTH(v_appaterno) - 1, 2));
      ELSE
        v_letras_ap := LOWER(SUBSTR(v_appaterno, 1, 2));
      END IF;

      v_mmYYYY := TO_CHAR(v_fecha_proceso, 'MMYYYY');

      v_clave_usuario :=
          v_3er_dig_run
        || TO_CHAR(v_anno_nac_mas2)
        || v_ult3_sueldo_txt
        || v_letras_ap
        || TO_CHAR(v_id_emp)
        || v_mmYYYY;

      /*--------------------------------------------------------
        INSERT tabla destino (1 fila por empleado)
      --------------------------------------------------------*/
      INSERT INTO USUARIO_CLAVE
        (id_emp, numrun_emp, dvrun_emp, nombre_empleado, nombre_usuario, clave_usuario)
      VALUES
        (v_id_emp, v_numrun_emp, v_dvrun_emp, v_nombre_empleado, v_nombre_usuario, v_clave_usuario);

      v_ok := v_ok + 1;

    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK TO sp_emp;
        v_err := v_err + 1;
        DBMS_OUTPUT.PUT_LINE('ERROR id_emp=' || r.id_emp || ' -> ' || SQLERRM);
    END;

  END LOOP;

  /*------------------------------------------------------------
    COMMIT condicional
  ------------------------------------------------------------*/
  IF v_ok = v_total_emp AND v_err = 0 THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('FIN OK: Procesados ' || v_ok || '/' || v_total_emp || '. COMMIT aplicado.');
  ELSE
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('FIN ERROR: OK=' || v_ok || ', Total=' || v_total_emp || ', Err=' || v_err || '. ROLLBACK aplicado.');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('FATAL: ' || SQLERRM);
END;
/

/*==============================================================
 CONSULTAS DE PRUEBA / EVIDENCIA (para capturas)
==============================================================*/

-- Evidencia: cantidad de filas generadas:
SELECT COUNT(*) AS total_generado
FROM USUARIO_CLAVE;

-- Evidencia: resultado ordenado por id_emp (orden se ve en el SELECT):
SELECT *
FROM USUARIO_CLAVE
ORDER BY id_emp;

-- Confirmación específica para el usuario 100 de que se está creando bien c/r a las reglas:
SELECT id_emp, fecha_contrato
FROM empleado
WHERE id_emp = 100;

SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_contrato)/12) AS anios
FROM empleado
WHERE id_emp = 100;

-- Revisar algunos id específicos
SELECT * FROM USUARIO_CLAVE WHERE id_emp IN (200,100,120) ORDER BY id_emp;
