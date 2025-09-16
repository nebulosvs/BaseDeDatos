-- Generado por Oracle SQL Developer Data Modeler 24.3.1.351.0831
--   en:        2025-09-15 22:44:35 CLST
--   sitio:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE AFP 
    ( 
     id_afp     NUMBER (10)  NOT NULL , 
     nombre_afp VARCHAR2 (25)  NOT NULL 
    ) 
;

ALTER TABLE AFP 
    ADD CONSTRAINT AFP_PK PRIMARY KEY ( id_afp ) ;

CREATE TABLE ATENCION_GENERAL 
    ( 
     id_atencion         NUMBER (1000)  NOT NULL , 
     id_atencion_general NUMBER (20)  NOT NULL , 
     id_comuna           NUMBER  NOT NULL , 
     id_region           NUMBER  NOT NULL 
    ) 
;

ALTER TABLE ATENCION_GENERAL 
    ADD CONSTRAINT ATENCION_GENERAL_PK PRIMARY KEY ( id_atencion, id_comuna, id_region ) ;

ALTER TABLE ATENCION_GENERAL 
    ADD CONSTRAINT ATENCION_GENERAL_PKv1 UNIQUE ( id_atencion_general ) ;

CREATE TABLE ATENCION_MEDICA 
    ( 
     id_atencion          NUMBER (1000)  NOT NULL , 
     fecha_atencion       DATE  NOT NULL , 
     monto_pagado         NUMBER (1000)  NOT NULL , 
     PACIENTE_id_paciente NUMBER (1000)  NOT NULL , 
     MEDICO_id_medico     NUMBER (3)  NOT NULL , 
     id_comuna            NUMBER  NOT NULL , 
     id_region            NUMBER  NOT NULL , 
     hora_atencion        DATE  NOT NULL 
    ) 
;

ALTER TABLE ATENCION_MEDICA 
    ADD CONSTRAINT ATENCION_MEDICA_PK PRIMARY KEY ( id_atencion, id_comuna, id_region ) ;

CREATE TABLE ATENCION_PREVENTIVA 
    ( 
     id_atencion      NUMBER (1000)  NOT NULL , 
     id_atencion_prev NUMBER (20)  NOT NULL , 
     id_comuna        NUMBER  NOT NULL , 
     id_region        NUMBER  NOT NULL 
    ) 
;

ALTER TABLE ATENCION_PREVENTIVA 
    ADD CONSTRAINT ATENCION_PREVENTIVA_PK PRIMARY KEY ( id_atencion, id_comuna, id_region ) ;

ALTER TABLE ATENCION_PREVENTIVA 
    ADD CONSTRAINT ATENCION_PREVENTIVA_PKv1 UNIQUE ( id_atencion_prev ) ;

CREATE TABLE ATENCION_URGENCIA 
    ( 
     id_atencion     NUMBER (1000)  NOT NULL , 
     id_atencion_urg NUMBER (20)  NOT NULL , 
     diagnostico     VARCHAR2 (200)  NOT NULL , 
     id_comuna       NUMBER  NOT NULL , 
     id_region       NUMBER  NOT NULL 
    ) 
;

ALTER TABLE ATENCION_URGENCIA 
    ADD CONSTRAINT ATENCION_URGENCIA_PK PRIMARY KEY ( id_atencion, id_comuna, id_region ) ;

ALTER TABLE ATENCION_URGENCIA 
    ADD CONSTRAINT ATENCION_URGENCIA_PKv1 UNIQUE ( id_atencion_urg ) ;

CREATE TABLE COMUNA 
    ( 
     id_comuna        NUMBER (100)  NOT NULL , 
     nombre_comuna    VARCHAR2 (100)  NOT NULL , 
     REGION_id_region NUMBER (100)  NOT NULL 
    ) 
;

ALTER TABLE COMUNA 
    ADD CONSTRAINT COMUNA_PK PRIMARY KEY ( id_comuna, REGION_id_region ) ;

CREATE TABLE DIRECCION 
    ( 
     COMUNA_id_comuna        NUMBER (100)  NOT NULL , 
     COMUNA_REGION_id_region NUMBER (100)  NOT NULL , 
     id_direccion            NUMBER (100)  NOT NULL , 
     calle                   VARCHAR2 (200)  NOT NULL , 
     num_calle               NUMBER (10)  NOT NULL , 
     num_depto               NUMBER (10) 
    ) 
;

ALTER TABLE DIRECCION 
    ADD CONSTRAINT DIRECCION_PK PRIMARY KEY ( id_direccion, COMUNA_id_comuna, COMUNA_REGION_id_region ) ;

CREATE TABLE ESPECIALIDAD 
    ( 
     id_especialidad     NUMBER (100)  NOT NULL , 
     nombre_especialidad VARCHAR2 (255)  NOT NULL 
    ) 
;

ALTER TABLE ESPECIALIDAD 
    ADD CONSTRAINT ESPECIALIDAD_PK PRIMARY KEY ( id_especialidad ) ;

CREATE TABLE ESTUDIANTE 
    ( 
     id_paciente   NUMBER (1000)  NOT NULL , 
     id_estudiante NUMBER (20)  NOT NULL , 
     id_carrera    NUMBER (20) 
    ) 
;

ALTER TABLE ESTUDIANTE 
    ADD CONSTRAINT ESTUDIANTE_PK PRIMARY KEY ( id_paciente ) ;

ALTER TABLE ESTUDIANTE 
    ADD CONSTRAINT ESTUDIANTE_PKv1 UNIQUE ( id_estudiante ) ;

CREATE TABLE EXAMEN_LABORATORIO 
    ( 
     id_examen                   NUMBER (20)  NOT NULL , 
     nombre_examen               VARCHAR2 (50)  NOT NULL , 
     tipo_muestra                VARCHAR2 (20)  NOT NULL , 
     cond_preparacion            VARCHAR2 (100)  NOT NULL , 
     ATENCION_MEDICA_id_atencion NUMBER (1000)  NOT NULL , 
     ATENCION_MEDICA_id_comuna   NUMBER  NOT NULL , 
     ATENCION_MEDICA_id_region   NUMBER  NOT NULL 
    ) 
;

ALTER TABLE EXAMEN_LABORATORIO 
    ADD CONSTRAINT EXAMEN_LABORATORIO_PK PRIMARY KEY ( id_examen ) ;

CREATE TABLE EXTERNOS 
    ( 
     id_paciente NUMBER (1000)  NOT NULL , 
     id_externo  NUMBER (20)  NOT NULL 
    ) 
;

ALTER TABLE EXTERNOS 
    ADD CONSTRAINT EXTERNOS_PK PRIMARY KEY ( id_paciente ) ;

ALTER TABLE EXTERNOS 
    ADD CONSTRAINT EXTERNOS_PKv1 UNIQUE ( id_externo ) ;

CREATE TABLE FUNCIONARIOS 
    ( 
     id_paciente    NUMBER (1000)  NOT NULL , 
     id_funcionario NUMBER (20)  NOT NULL 
    ) 
;

ALTER TABLE FUNCIONARIOS 
    ADD CONSTRAINT FUNCIONARIOS_PK PRIMARY KEY ( id_paciente ) ;

ALTER TABLE FUNCIONARIOS 
    ADD CONSTRAINT FUNCIONARIOS_PKv1 UNIQUE ( id_funcionario ) ;

CREATE TABLE MEDICO 
    ( 
     id_medico                    NUMBER (3)  NOT NULL , 
     rut_medico                   VARCHAR2 (10)  NOT NULL , 
     nombre_medico                VARCHAR2 (15)  NOT NULL , 
     primer_apellido              VARCHAR2 (15)  NOT NULL , 
     segundo_apellido             VARCHAR2 (15)  NOT NULL , 
     fecha_ingreso                DATE  NOT NULL , 
     ESPECIALIDAD_id_especialidad NUMBER (100) , 
     AFP_id_afp                   NUMBER (10)  NOT NULL , 
     PREVISION_SALUD_id_prevision VARCHAR2 (25)  NOT NULL , 
     MEDICO_id_medico             NUMBER (3) 
    ) 
;
CREATE UNIQUE INDEX MEDICO__IDX ON MEDICO 
    ( 
     MEDICO_id_medico ASC 
    ) 
;

ALTER TABLE MEDICO 
    ADD CONSTRAINT MEDICO_PK PRIMARY KEY ( id_medico ) ;

ALTER TABLE MEDICO 
    ADD CONSTRAINT MEDICO_rut_medico_UN UNIQUE ( rut_medico ) ;

CREATE TABLE MEDIO_PAGO 
    ( 
     id_medio_pago               NUMBER (1000)  NOT NULL , 
     tipo_medio_pago             VARCHAR2 (255)  NOT NULL , 
     descripcion                 VARCHAR2 (255) , 
     ATENCION_MEDICA_id_atencion NUMBER (1000)  NOT NULL , 
     ATENCION_MEDICA_id_comuna   NUMBER  NOT NULL , 
     ATENCION_MEDICA_id_region   NUMBER  NOT NULL 
    ) 
;
CREATE UNIQUE INDEX MEDIO_PAGO__IDX ON MEDIO_PAGO 
    ( 
     ATENCION_MEDICA_id_atencion ASC 
    ) 
;
CREATE UNIQUE INDEX MEDIO_PAGO__IDX ON MEDIO_PAGO 
    ( 
     ATENCION_MEDICA_id_atencion ASC , 
     ATENCION_MEDICA_id_comuna ASC , 
     ATENCION_MEDICA_id_region ASC 
    ) 
;

ALTER TABLE MEDIO_PAGO 
    ADD CONSTRAINT MEDIO_PAGO_PK PRIMARY KEY ( id_medio_pago ) ;

CREATE TABLE PACIENTE 
    ( 
     id_paciente                       NUMBER (1000)  NOT NULL , 
     rut_paciente                      VARCHAR2 (10)  NOT NULL , 
     nombre_paciente                   VARCHAR2 (15)  NOT NULL , 
     primer_apellido                   VARCHAR2 (15)  NOT NULL , 
     segundo_apellido                  VARCHAR2 
--  ERROR: VARCHAR2 size not specified 
                     NOT NULL , 
     fecha_nac                         DATE  NOT NULL , 
     direccion                         VARCHAR2 (200)  NOT NULL , 
     id_comuna                         NUMBER  NOT NULL , 
     id_region                         NUMBER  NOT NULL , 
     DIRECCION_id_direccion            NUMBER (100)  NOT NULL , 
     DIRECCION_COMUNA_id_comuna        NUMBER (100)  NOT NULL , 
--  ERROR: Column name length exceeds maximum allowed length(30) 
     DIRECCION_COMUNA_REGION_id_region NUMBER (100)  NOT NULL , 
     SEXO_id_sexo                      NUMBER (20)  NOT NULL , 
     fono                              NUMBER (20)  NOT NULL , 
     ficha_medica                      VARCHAR2 (200) 
    ) 
;

ALTER TABLE PACIENTE 
    ADD CONSTRAINT PACIENTE_PK PRIMARY KEY ( id_paciente ) ;

ALTER TABLE PACIENTE 
    ADD CONSTRAINT PACIENTE_rut_paciente_UN UNIQUE ( rut_paciente ) ;

CREATE TABLE PAGO_CONVENIO 
    ( 
     id_medio_pago             NUMBER (1000)  NOT NULL , 
     id_medio_pago_convenio    NUMBER (1000)  NOT NULL , 
     cod_autorizacion_convenio VARCHAR2 (255)  NOT NULL , 
     id_caja_emisora           NUMBER (20)  NOT NULL 
    ) 
;

ALTER TABLE PAGO_CONVENIO 
    ADD CONSTRAINT PAGO_CONVENIO_PK PRIMARY KEY ( id_medio_pago ) ;

ALTER TABLE PAGO_CONVENIO 
    ADD CONSTRAINT PAGO_CONVENIO_PKv1 UNIQUE ( id_medio_pago_convenio ) ;


--  ERROR: UK name length exceeds maximum allowed length(30) 
ALTER TABLE PAGO_CONVENIO 
    ADD CONSTRAINT PAGO_CONVENIO_cod_autorizacion_convenio_UN UNIQUE ( cod_autorizacion_convenio ) ;

CREATE TABLE PAGO_EFECTIVO 
    ( 
     id_medio_pago          NUMBER (1000)  NOT NULL , 
     id_medio_pago_efectivo NUMBER (1000)  NOT NULL , 
     vuelto                 NUMBER (100,2)  NOT NULL 
    ) 
;

ALTER TABLE PAGO_EFECTIVO 
    ADD CONSTRAINT PAGO_EFECTIVO_PK PRIMARY KEY ( id_medio_pago ) ;

ALTER TABLE PAGO_EFECTIVO 
    ADD CONSTRAINT PAGO_EFECTIVO_PKv1 UNIQUE ( id_medio_pago_efectivo ) ;

CREATE TABLE PAGO_TARJETA 
    ( 
     id_medio_pago_tarjeta    NUMBER (1000)  NOT NULL , 
     cod_autorizacion_tarjeta VARCHAR2 (255)  NOT NULL , 
     id_banco_emisor          VARCHAR2 (255)  NOT NULL , 
     tipo_tarjeta             VARCHAR2 (255)  NOT NULL , 
     id_medio_pago1           NUMBER (1000)  NOT NULL 
    ) 
;

ALTER TABLE PAGO_TARJETA 
    ADD CONSTRAINT PAGO_TARJETA_PKv1 PRIMARY KEY ( id_medio_pago1 ) ;

ALTER TABLE PAGO_TARJETA 
    ADD CONSTRAINT PAGO_TARJETA_PK UNIQUE ( id_medio_pago_tarjeta ) ;


--  ERROR: UK name length exceeds maximum allowed length(30) 
ALTER TABLE PAGO_TARJETA 
    ADD CONSTRAINT PAGO_TARJETA_cod_autorizacion_UN UNIQUE ( cod_autorizacion_tarjeta ) ;

CREATE TABLE PREVISION_SALUD 
    ( 
     id_prevision     VARCHAR2 (25)  NOT NULL , 
     nombre_prevision VARCHAR2 (100)  NOT NULL 
    ) 
;

ALTER TABLE PREVISION_SALUD 
    ADD CONSTRAINT PREVISION_SALUD_PK PRIMARY KEY ( id_prevision ) ;

CREATE TABLE REGION 
    ( 
     id_region     NUMBER (100)  NOT NULL , 
     nombre_region VARCHAR2 (100)  NOT NULL 
    ) 
;

ALTER TABLE REGION 
    ADD CONSTRAINT REGION_PK PRIMARY KEY ( id_region ) ;

CREATE TABLE SEXO 
    ( 
     id_sexo NUMBER (20)  NOT NULL , 
     sexo    VARCHAR2 (50)  NOT NULL 
    ) 
;

ALTER TABLE SEXO 
    ADD CONSTRAINT SEXO_PK PRIMARY KEY ( id_sexo ) ;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE ATENCION_GENERAL 
    ADD CONSTRAINT ATENCION_GENERAL_ATENCION_MEDICA_FK FOREIGN KEY 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
    REFERENCES ATENCION_MEDICA 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
;

ALTER TABLE ATENCION_MEDICA 
    ADD CONSTRAINT ATENCION_MEDICA_MEDICO_FK FOREIGN KEY 
    ( 
     MEDICO_id_medico
    ) 
    REFERENCES MEDICO 
    ( 
     id_medico
    ) 
;

ALTER TABLE ATENCION_MEDICA 
    ADD CONSTRAINT ATENCION_MEDICA_PACIENTE_FK FOREIGN KEY 
    ( 
     PACIENTE_id_paciente
    ) 
    REFERENCES PACIENTE 
    ( 
     id_paciente
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE ATENCION_PREVENTIVA 
    ADD CONSTRAINT ATENCION_PREVENTIVA_ATENCION_MEDICA_FK FOREIGN KEY 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
    REFERENCES ATENCION_MEDICA 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE ATENCION_URGENCIA 
    ADD CONSTRAINT ATENCION_URGENCIA_ATENCION_MEDICA_FK FOREIGN KEY 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
    REFERENCES ATENCION_MEDICA 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
;

ALTER TABLE COMUNA 
    ADD CONSTRAINT COMUNA_REGION_FK FOREIGN KEY 
    ( 
     REGION_id_region
    ) 
    REFERENCES REGION 
    ( 
     id_region
    ) 
;

ALTER TABLE DIRECCION 
    ADD CONSTRAINT DIRECCION_COMUNA_FK FOREIGN KEY 
    ( 
     COMUNA_id_comuna,
     COMUNA_REGION_id_region
    ) 
    REFERENCES COMUNA 
    ( 
     id_comuna,
     REGION_id_region
    ) 
;

ALTER TABLE ESTUDIANTE 
    ADD CONSTRAINT ESTUDIANTE_PACIENTE_FK FOREIGN KEY 
    ( 
     id_paciente
    ) 
    REFERENCES PACIENTE 
    ( 
     id_paciente
    ) 
;

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE EXAMEN_LABORATORIO 
    ADD CONSTRAINT EXAMEN_LABORATORIO_ATENCION_MEDICA_FK FOREIGN KEY 
    ( 
     ATENCION_MEDICA_id_atencion,
     ATENCION_MEDICA_id_comuna,
     ATENCION_MEDICA_id_region
    ) 
    REFERENCES ATENCION_MEDICA 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
;

ALTER TABLE EXTERNOS 
    ADD CONSTRAINT EXTERNOS_PACIENTE_FK FOREIGN KEY 
    ( 
     id_paciente
    ) 
    REFERENCES PACIENTE 
    ( 
     id_paciente
    ) 
;

ALTER TABLE FUNCIONARIOS 
    ADD CONSTRAINT FUNCIONARIOS_PACIENTE_FK FOREIGN KEY 
    ( 
     id_paciente
    ) 
    REFERENCES PACIENTE 
    ( 
     id_paciente
    ) 
;

ALTER TABLE MEDICO 
    ADD CONSTRAINT MEDICO_AFP_FK FOREIGN KEY 
    ( 
     AFP_id_afp
    ) 
    REFERENCES AFP 
    ( 
     id_afp
    ) 
;

ALTER TABLE MEDICO 
    ADD CONSTRAINT MEDICO_ESPECIALIDAD_FK FOREIGN KEY 
    ( 
     ESPECIALIDAD_id_especialidad
    ) 
    REFERENCES ESPECIALIDAD 
    ( 
     id_especialidad
    ) 
;

ALTER TABLE MEDICO 
    ADD CONSTRAINT MEDICO_MEDICO_FK FOREIGN KEY 
    ( 
     MEDICO_id_medico
    ) 
    REFERENCES MEDICO 
    ( 
     id_medico
    ) 
;

ALTER TABLE MEDICO 
    ADD CONSTRAINT MEDICO_PREVISION_SALUD_FK FOREIGN KEY 
    ( 
     PREVISION_SALUD_id_prevision
    ) 
    REFERENCES PREVISION_SALUD 
    ( 
     id_prevision
    ) 
;

ALTER TABLE MEDIO_PAGO 
    ADD CONSTRAINT MEDIO_PAGO_ATENCION_MEDICA_FK FOREIGN KEY 
    ( 
     ATENCION_MEDICA_id_atencion,
     ATENCION_MEDICA_id_comuna,
     ATENCION_MEDICA_id_region
    ) 
    REFERENCES ATENCION_MEDICA 
    ( 
     id_atencion,
     id_comuna,
     id_region
    ) 
;

ALTER TABLE PACIENTE 
    ADD CONSTRAINT PACIENTE_DIRECCION_FK FOREIGN KEY 
    ( 
     DIRECCION_id_direccion,
     DIRECCION_COMUNA_id_comuna,
     DIRECCION_COMUNA_REGION_id_region
    ) 
    REFERENCES DIRECCION 
    ( 
     id_direccion,
     COMUNA_id_comuna,
     COMUNA_REGION_id_region
    ) 
;

ALTER TABLE PACIENTE 
    ADD CONSTRAINT PACIENTE_SEXO_FK FOREIGN KEY 
    ( 
     SEXO_id_sexo
    ) 
    REFERENCES SEXO 
    ( 
     id_sexo
    ) 
;

ALTER TABLE PAGO_CONVENIO 
    ADD CONSTRAINT PAGO_CONVENIO_MEDIO_PAGO_FK FOREIGN KEY 
    ( 
     id_medio_pago
    ) 
    REFERENCES MEDIO_PAGO 
    ( 
     id_medio_pago
    ) 
;

ALTER TABLE PAGO_EFECTIVO 
    ADD CONSTRAINT PAGO_EFECTIVO_MEDIO_PAGO_FK FOREIGN KEY 
    ( 
     id_medio_pago
    ) 
    REFERENCES MEDIO_PAGO 
    ( 
     id_medio_pago
    ) 
;

ALTER TABLE PAGO_TARJETA 
    ADD CONSTRAINT PAGO_TARJETA_MEDIO_PAGO_FK FOREIGN KEY 
    ( 
     id_medio_pago1
    ) 
    REFERENCES MEDIO_PAGO 
    ( 
     id_medio_pago
    ) 
;

--  ERROR: No Discriminator Column found in Arc FKArc_1 - constraint trigger for Arc cannot be generated 

--  ERROR: No Discriminator Column found in Arc FKArc_1 - constraint trigger for Arc cannot be generated 

--  ERROR: No Discriminator Column found in Arc FKArc_1 - constraint trigger for Arc cannot be generated

--  ERROR: No Discriminator Column found in Arc FKArc_2 - constraint trigger for Arc cannot be generated 

--  ERROR: No Discriminator Column found in Arc FKArc_2 - constraint trigger for Arc cannot be generated 

--  ERROR: No Discriminator Column found in Arc FKArc_2 - constraint trigger for Arc cannot be generated

--  ERROR: No Discriminator Column found in Arc FKArc_3 - constraint trigger for Arc cannot be generated 

--  ERROR: No Discriminator Column found in Arc FKArc_3 - constraint trigger for Arc cannot be generated 

--  ERROR: No Discriminator Column found in Arc FKArc_3 - constraint trigger for Arc cannot be generated



-- Informe de Resumen de Oracle SQL Developer Data Modeler: 
-- 
-- CREATE TABLE                            21
-- CREATE INDEX                             3
-- ALTER TABLE                             55
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           0
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                  17
-- WARNINGS                                 0
