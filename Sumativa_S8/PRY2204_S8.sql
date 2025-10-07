/* =========================================================
   CASO 1: IMPLEMENTACIÓN DEL MODELO
   ========================================================= */
/* =========================================================
   LIMPIEZA DE TABLAS 
   ========================================================= */
DROP TABLE DETALLE_VENTA CASCADE CONSTRAINTS;
DROP TABLE VENTA CASCADE CONSTRAINTS;
DROP TABLE PRODUCTO CASCADE CONSTRAINTS;
DROP TABLE VENDEDOR CASCADE CONSTRAINTS;
DROP TABLE ADMINISTRATIVO CASCADE CONSTRAINTS;
DROP TABLE EMPLEADO CASCADE CONSTRAINTS;
DROP TABLE PROVEEDOR CASCADE CONSTRAINTS;
DROP TABLE MARCA CASCADE CONSTRAINTS;
DROP TABLE CATEGORIA CASCADE CONSTRAINTS;
DROP TABLE MEDIO_PAGO CASCADE CONSTRAINTS;
DROP TABLE SALUD CASCADE CONSTRAINTS;
DROP TABLE AFP CASCADE CONSTRAINTS;
DROP TABLE COMUNA CASCADE CONSTRAINTS;
DROP TABLE REGION CASCADE CONSTRAINTS;
/* =========================================================
   TABLAS FUERTES
   ========================================================= */

--En cada tabla, las PK no se escribieron como NOT NULL, ya que al ser PK, es automático la obligatoriedad.

CREATE TABLE REGION (
    id_region NUMBER(4),
    nom_region VARCHAR2(255) NOT NULL,
    CONSTRAINT REGION_PK PRIMARY KEY (id_region) 
);


CREATE TABLE COMUNA (
    id_comuna NUMBER(4),
    nom_comuna VARCHAR2(100) NOT NULL,
    cod_region NUMBER(4) NOT NULL,
    CONSTRAINT COMUNA_PK PRIMARY KEY (id_comuna, cod_region), 
    CONSTRAINT FK_COMUNA_REGION FOREIGN KEY (cod_region) REFERENCES REGION(id_region)
);


CREATE TABLE AFP (
    id_afp NUMBER(5) GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 6),
    nom_afp VARCHAR2(255) NOT NULL,
    CONSTRAINT AFP_PK PRIMARY KEY (id_afp) 
);


CREATE TABLE SALUD (
    id_salud NUMBER(5),
    nom_salud VARCHAR2(40) NOT NULL,
    CONSTRAINT SALUD_PK PRIMARY KEY (id_salud) 
);


CREATE TABLE MEDIO_PAGO (
    id_mpago NUMBER(3),
    nombre_mpago VARCHAR2(50) NOT NULL,
    CONSTRAINT MEDIO_PAGO_PK PRIMARY KEY (id_mpago) 
);


CREATE TABLE CATEGORIA (
    id_categoria NUMBER(3),
    nombre_categoria VARCHAR2(255) NOT NULL,
    CONSTRAINT CATEGORIA_PK PRIMARY KEY (id_categoria) 
);


CREATE TABLE MARCA (
    id_marca NUMBER(3),
    nombre_marca VARCHAR2(25) NOT NULL,
    CONSTRAINT MARCA_PK PRIMARY KEY (id_marca) 
);


CREATE TABLE PROVEEDOR (
    id_proveedor NUMBER(5),
    nombre_proveedor VARCHAR2(150) NOT NULL,
    rut_proveedor VARCHAR2(10) NOT NULL,
    telefono VARCHAR2(10) NOT NULL,
    email VARCHAR2(200) NOT NULL,
    direccion VARCHAR2(200) NOT NULL,
    cod_comuna NUMBER(4) NOT NULL,
    CONSTRAINT PROVEEDOR_PK PRIMARY KEY (id_proveedor), 
    CONSTRAINT FK_PROVEEDOR_COMUNA FOREIGN KEY (cod_comuna) REFERENCES COMUNA(id_comuna)
);


CREATE TABLE EMPLEADO (
    id_empleado NUMBER(4),
    rut_empleado VARCHAR2(10) NOT NULL,
    nombre_empleado VARCHAR2(25) NOT NULL,
    apellido_paterno VARCHAR2(25) NOT NULL,
    apellido_materno VARCHAR2(25) NOT NULL,
    fecha_contratacion DATE NOT NULL,
    sueldo_base NUMBER(10) NOT NULL,
    bono_jefatura NUMBER(10),
    activo CHAR(1),
    tipo_empleado VARCHAR2(25) NOT NULL,
    cod_empleado NUMBER(4), 
    cod_salud NUMBER(4) NOT NULL,
    cod_afp NUMBER(5) NOT NULL,
    CONSTRAINT EMPLEADO_PK PRIMARY KEY (id_empleado), 
    CONSTRAINT FK_EMPLEADO_SALUD FOREIGN KEY (cod_salud) REFERENCES SALUD(id_salud),
    CONSTRAINT FK_EMPLEADO_AFP FOREIGN KEY (cod_afp) REFERENCES AFP(id_afp),
    CONSTRAINT FK_EMPLEADO_JEFE FOREIGN KEY (cod_empleado) REFERENCES EMPLEADO(id_empleado)
);

/* =========================================================
   TABLAS DÉBILES
   ========================================================= */
CREATE TABLE ADMINISTRATIVO (
    id_empleado NUMBER(4),
    CONSTRAINT ADMNISTRATIVO_PK PRIMARY KEY (id_empleado), 
    CONSTRAINT FK_ADMINISTRATIVO_EMPLEADO FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado)
);


CREATE TABLE VENDEDOR (
    id_empleado NUMBER(4),
    comision_venta NUMBER(5,2) NOT NULL,
    CONSTRAINT VENDEDOR_PK PRIMARY KEY (id_empleado), 
    CONSTRAINT FK_VENDEDOR_EMPLEADO FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado)
);


CREATE TABLE PRODUCTO (
    id_producto NUMBER(4),
    nombre_producto VARCHAR2(100) NOT NULL,
    precio_unitario NUMBER NOT NULL,
    origen_nacional CHAR(1) CHECK (origen_nacional IN ('S','N')),
    stock_minimo NUMBER(3),
    activo CHAR(1) CHECK (activo IN ('S','N')),
    cod_marca NUMBER(3) NOT NULL,
    cod_categoria NUMBER(3) NOT NULL,
    cod_proveedor NUMBER(5) NOT NULL,
    CONSTRAINT PRODUCTO_PK PRIMARY KEY (id_producto), 
    CONSTRAINT FK_PRODUCTO_MARCA FOREIGN KEY (cod_marca) REFERENCES MARCA(id_marca),
    CONSTRAINT FK_PRODUCTO_CATEGORIA FOREIGN KEY (cod_categoria) REFERENCES CATEGORIA(id_categoria),
    CONSTRAINT FK_PRODUCTO_PROVEEDOR FOREIGN KEY (cod_proveedor) REFERENCES PROVEEDOR(id_proveedor)
);


CREATE TABLE VENTA (
    id_venta NUMBER(4) GENERATED ALWAYS AS IDENTITY (START WITH 5050 INCREMENT BY 3),
    fecha_venta DATE NOT NULL,
    total_venta NUMBER(10) NOT NULL,
    cod_mpago NUMBER(3) NOT NULL,
    cod_empleado NUMBER(4) NOT NULL,
    CONSTRAINT VENTA_PK PRIMARY KEY (id_venta), 
    CONSTRAINT FK_VENTA_MEDIO FOREIGN KEY (cod_mpago) REFERENCES MEDIO_PAGO(id_mpago),
    CONSTRAINT FK_VENTA_EMPLEADO FOREIGN KEY (cod_empleado) REFERENCES EMPLEADO(id_empleado)
);


CREATE TABLE DETALLE_VENTA (
    cod_venta NUMBER(4),
    cod_producto NUMBER(4),
    cantidad NUMBER(6) NOT NULL,
    CONSTRAINT DETALLE_VENTA_PK PRIMARY KEY (cod_venta, cod_producto),
    CONSTRAINT FK_DET_VENTA FOREIGN KEY (cod_venta) REFERENCES VENTA(id_venta),
    CONSTRAINT FK_DET_PRODUCTO FOREIGN KEY (cod_producto) REFERENCES PRODUCTO(id_producto)
);

/* =========================================================
   CASO 2: MODIFICACIÓN DEL MODELO
   ========================================================= */

ALTER TABLE EMPLEADO
ADD CONSTRAINT CK_EMPLEADO_SUELDO_BASE CHECK (sueldo_base >= 400000);


ALTER TABLE VENDEDOR
ADD CONSTRAINT CK_VENDEDOR_COMISION CHECK (comision_venta BETWEEN 0 AND 0.25);


ALTER TABLE PRODUCTO
ADD CONSTRAINT CK_PRODUCTO_STOCK_MIN CHECK (stock_minimo >= 3);


ALTER TABLE PROVEEDOR
ADD CONSTRAINT UN_PROVEEDOR_EMAIL UNIQUE (email);


ALTER TABLE MARCA
ADD CONSTRAINT UN_MARCA_NOMBRE UNIQUE (nombre_marca);


ALTER TABLE DETALLE_VENTA
ADD CONSTRAINT CK_DETALLE_VENTA_CANTIDAD CHECK (cantidad > 0);

/* =========================================================
   CASO 3: POBLAMIENTO DEL MODELO
   ========================================================= */

/* ===== TABLA REGION ===== */
INSERT INTO REGION (id_region, nom_region) VALUES (1,'Región Metropolitana');
INSERT INTO REGION (id_region, nom_region) VALUES (2, 'Valparaíso');
INSERT INTO REGION (id_region, nom_region) VALUES (3, 'Biobío');
INSERT INTO REGION (id_region, nom_region) VALUES (4, 'Los Lagos');


/* ===== TABLA AFP ===== */
INSERT INTO AFP (nom_afp) VALUES ('AFP Habitat');
INSERT INTO AFP (nom_afp) VALUES ('AFP Cumprum');
INSERT INTO AFP (nom_afp) VALUES ('AFP Provida');
INSERT INTO AFP (nom_afp) VALUES ('AFP PlanVital');


-- Secuencia para SALUD
DROP SEQUENCE SEQ_SALUD;
CREATE SEQUENCE SEQ_SALUD START WITH 2050 INCREMENT BY 10;

/* ===== TABLA SALUD ===== */
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Fonasa');
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Isapre Colmena');
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Isapre Banmédica');
INSERT INTO SALUD (id_salud, nom_salud) VALUES (SEQ_SALUD.NEXTVAL, 'Isapre Cruz Blanca');


/* ===== TABLA MEDIO_PAGO ===== */
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (11, 'Efectivo');
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (12, 'Tarjeta Débito');
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (13, 'Tarjeta Crédito');
INSERT INTO MEDIO_PAGO (id_mpago, nombre_mpago) VALUES (14, 'Cheque');


-- Secuencia para EMPLEADO
DROP SEQUENCE SEQ_EMPLEADO;
CREATE SEQUENCE SEQ_EMPLEADO START WITH 750 INCREMENT BY 3;

/* ===== TABLA EMPLEADO ===== */
INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '11111111-1', 'Marcela', 'González', 'Pérez',
 TO_DATE('15-03-2022','DD-MM-YYYY'), 950000, 80000, 'S', 'Administrativo',
 NULL, 2050, 210);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '22222222-2', 'José', 'Muñoz', 'Ramírez',
 TO_DATE('10-07-2021','DD-MM-YYYY'), 900000, 75000, 'S', 'Administrativo',
 NULL, 2060, 216);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '33333333-3', 'Verónica', 'Soto', 'Alarcón',
 TO_DATE('05-01-2020','DD-MM-YYYY'), 880000, 70000, 'S', 'Vendedor',
 750, 2060, 228);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '44444444-4', 'Luis', 'Reyes', 'Fuentes',
 TO_DATE('01-04-2023','DD-MM-YYYY'), 560000, NULL, 'S', 'Vendedor',
 750, 2070, 228);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '55555555-5', 'Claudia', 'Fernández', 'Lagos',
 TO_DATE('15-04-2023','DD-MM-YYYY'), 600000, NULL, 'S', 'Vendedor',
 753, 2070, 216);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '66666666-6', 'Carlos', 'Navarro', 'Vega',
 TO_DATE('01-05-2023','DD-MM-YYYY'), 610000, NULL, 'S', 'Administrativo',
 753, 2060, 210);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '77777777-7', 'Javiera', 'Pino', 'Rojas',
 TO_DATE('10-05-2023','DD-MM-YYYY'), 650000, NULL, 'S', 'Administrativo',
 750, 2050, 210);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '88888888-8', 'Diego', 'Mella', 'Contreras',
 TO_DATE('12-05-2023','DD-MM-YYYY'), 620000, NULL, 'S', 'Vendedor',
 750, 2060, 216);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '99999999-9', 'Fernanda', 'Salas', 'Herrera',
 TO_DATE('18-05-2023','DD-MM-YYYY'), 570000, NULL, 'S', 'Vendedor',
 753, 2070, 228);

INSERT INTO EMPLEADO 
(id_empleado, rut_empleado, nombre_empleado, apellido_paterno, apellido_materno, 
 fecha_contratacion, sueldo_base, bono_jefatura, activo, tipo_empleado, 
 cod_empleado, cod_salud, cod_afp)
VALUES 
(SEQ_EMPLEADO.NEXTVAL, '10101010-0', 'Tomás', 'Vidal', 'Espinoza',
 TO_DATE('01-06-2023','DD-MM-YYYY'), 530000, NULL, 'S', 'Vendedor',
 NULL, 2050, 222);


/* ===== TABLA VENTA ===== */
INSERT INTO VENTA (fecha_venta, total_venta, cod_mpago, cod_empleado)
VALUES (TO_DATE('12-05-2023','DD-MM-YYYY'), 225990, 12, 771);

INSERT INTO VENTA (fecha_venta, total_venta, cod_mpago, cod_empleado)
VALUES (TO_DATE('23-10-2023','DD-MM-YYYY'), 524990, 13, 777);

INSERT INTO VENTA (fecha_venta, total_venta, cod_mpago, cod_empleado)
VALUES (TO_DATE('17-02-2023','DD-MM-YYYY'), 466990, 11, 759);


/* =========================================================
   CASO 4: RECUPERACIÓN DE DATOS
   ========================================================= */

/* ===== INFORME 1 ===== */
SELECT 
    e.id_empleado AS "IDENTIFICADOR",
    e.nombre_empleado || ' ' || e.apellido_paterno || ' ' || e.apellido_materno AS "NOMBRE COMPLETO",
    e.sueldo_base AS "SALARIO",
    e.bono_jefatura AS "BONIFICACION",
    (e.sueldo_base + e.bono_jefatura) AS "SALARIO SIMULADO"
FROM EMPLEADO e
WHERE e.activo = 'S'
  AND e.bono_jefatura IS NOT NULL
ORDER BY 
    "SALARIO SIMULADO" DESC,
    e.apellido_paterno DESC;


/* ===== INFORME 2 ===== */
SELECT
    e.nombre_empleado || ' ' || e.apellido_paterno || ' ' || e.apellido_materno AS "EMPLEADO",
    e.sueldo_base AS "SUELDO",
    (e.sueldo_base * 0.08) AS "POSIBLE AUMENTO",
    (e.sueldo_base * 1.08) AS "SALARIO SIMULADO"
FROM EMPLEADO e
WHERE e.sueldo_base BETWEEN 550000 AND 800000
ORDER BY e.sueldo_base ASC;

