if db_id('Com2900G12') is null
	create database Com2900G12 collate Modern_Spanish_CI_AS;
go

use Com2900G12
go

--------------------------------------------------------

-- Eliminar SP si existe
IF OBJECT_ID('SP_CrearTablasYSchemas', 'P') IS NOT NULL
    DROP PROCEDURE SP_CrearTablasYSchemas;
GO

CREATE or ALTER PROCEDURE SP_CrearTablasYSchemas
AS
BEGIN
    SET NOCOUNT ON;

    /* IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SCH_Pago')
    BEGIN
        PRINT 'El schema SCH_Pago no existe. Creándolo...';
        EXEC dbo.GenerarSchemas @NombreSchema = 'SCH_Pago';
    END
    
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SCH_Persona')
    BEGIN
        PRINT 'El schema SCH_Persona no existe. Creándolo...';
        EXEC dbo.GenerarSchemas @NombreSchema = 'SCH_Persona';
    END
    
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SCH_Consorcio')
    BEGIN
        PRINT 'El schema SCH_Consorcio no existe. Creándolo...';
        EXEC dbo.GenerarSchemas @NombreSchema = 'SCH_Consorcio';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SCH_UF')
    BEGIN
        PRINT 'El schema SCH_UF no existe. Creándolo...';
        EXEC dbo.GenerarSchemas @NombreSchema = 'SCH_UF';
    END


    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SCH_Expensa')
    BEGIN
        PRINT 'El schema SCH_Expensa no existe. Creándolo...';
        EXEC dbo.GenerarSchemas @NombreSchema = 'SCH_Expensa';
    END


    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SCH_Gasto')
    BEGIN
        PRINT 'El schema SCH_Gasto no existe. Creándolo...';
        EXEC dbo.GenerarSchemas @NombreSchema = 'SCH_Gasto'; 
    END */


    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF OBJECT_ID('Pago', 'U') IS NOT NULL DROP TABLE Pago;
        IF OBJECT_ID('Gasto_Extraordinario', 'U') IS NOT NULL DROP TABLE Gasto_Extraordinario;
        IF OBJECT_ID('Gasto_Ordinario', 'U') IS NOT NULL DROP TABLE Gasto_Ordinario;
        IF OBJECT_ID('Detalle_Expensa', 'U') IS NOT NULL DROP TABLE Detalle_Expensa;
        IF OBJECT_ID('Expensa', 'U') IS NOT NULL DROP TABLE Expensa;
        IF OBJECT_ID('Estado_financiero', 'U') IS NOT NULL DROP TABLE Estado_financiero;
        IF OBJECT_ID('Estado_de_cuenta', 'U') IS NOT NULL DROP TABLE Estado_de_cuenta;
        IF OBJECT_ID('Persona_UF', 'U') IS NOT NULL DROP TABLE Persona_UF;
        IF OBJECT_ID('Adicionales', 'U') IS NOT NULL DROP TABLE Adicionales;
        IF OBJECT_ID('UF', 'U') IS NOT NULL DROP TABLE UF;
        IF OBJECT_ID('Tipo_Servicio', 'U') IS NOT NULL DROP TABLE Tipo_Servicio;
        IF OBJECT_ID('Tipo_Gasto', 'U') IS NOT NULL DROP TABLE Tipo_Gasto;
        IF OBJECT_ID('Proveedor_Consorcio', 'U') IS NOT NULL DROP TABLE Proveedor_Consorcio;
        IF OBJECT_ID('Proveedor', 'U') IS NOT NULL DROP TABLE Proveedor;
        IF OBJECT_ID('Consorcio', 'U') IS NOT NULL DROP TABLE Consorcio;
        IF OBJECT_ID('Persona', 'U') IS NOT NULL DROP TABLE Persona;
        IF OBJECT_ID('Tipo_adicional', 'U') IS NOT NULL DROP TABLE Tipo_adicional;
        IF OBJECT_ID('Tipo_relacion', 'U') IS NOT NULL DROP TABLE Tipo_relacion;

        -- Tabla: Persona
        CREATE TABLE Persona (
            id	INT IDENTITY(1,1),
	        dni varchar(8) not null check(dni not like '%[^0-9]%'),
	        nombre nvarchar(50) not null,
	        apellido nvarchar(50) not null,
	        email varchar(200) not null,
	        cvu_cbu varchar(30) not null,
	        telefono varchar(11) not null,

            CONSTRAINT PERSONA_CHK_CBU CHECK 
            (cvu_cbu LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
            CONSTRAINT PERSONA_PK PRIMARY KEY (id),
            -- CONSTRAINT PERSONA_UK_DNI UNIQUE (dni),
            CONSTRAINT PERSONA_UK_CBU UNIQUE (cvu_cbu)
        );
        CREATE INDEX idx_persona_cbu_cvu ON Persona(cvu_cbu);


        CREATE TABLE Tipo_relacion (
            id BIT PRIMARY KEY,
            descripcion VARCHAR(100) NOT NULL
        );

        CREATE TABLE Tipo_adicional (
            id TINYINT IDENTITY(1,1) PRIMARY KEY,
            descripcion VARCHAR(100) NOT NULL
        );

        CREATE TABLE Consorcio (
            id INT IDENTITY(1,1) PRIMARY KEY,
            razon_social VARCHAR(200) NOT NULL,
            domicilio VARCHAR(200) NULL,
            m2 DECIMAL(10,2) NULL
        );

        CREATE TABLE UF (
            id_consorcio INT NOT NULL,
            id INT NOT NULL,
            m2 DECIMAL(10,2) NULL,
            porcentaje DECIMAL(5,2) NULL,
            depto CHAR NULL,
            piso INT NULL,
            CONSTRAINT PK_UF PRIMARY KEY (id_consorcio, id),
            CONSTRAINT FK_UF_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id)
        );

        CREATE TABLE Adicionales (
            id_consorcio INT NOT NULL,
            id_uf INT NOT NULL,
            m2 DECIMAL(10,2) NULL,
            porcentaje DECIMAL(5,2) NULL,
            id_tipo_adicional TINYINT NULL,
            CONSTRAINT PK_Adicionales PRIMARY KEY (id_consorcio, id_uf),
            CONSTRAINT FK_ADICIONALES_TIPO_ADICIONAL FOREIGN KEY (id_tipo_adicional) REFERENCES Tipo_adicional(id),
            CONSTRAINT FK_ADICIONALES_UF FOREIGN KEY (id_consorcio, id_uf) REFERENCES UF(id_consorcio, id)
        );

        CREATE TABLE Persona_UF (
            id_consorcio INT NOT NULL,
            id_uf INT NOT NULL,
            cvu_cbu varchar(30) not null,
            id_tipo_relacion BIT NULL,
            fecha DATE NULL,
            CONSTRAINT PK_Persona_UF PRIMARY KEY (id_consorcio, id_uf),
            CONSTRAINT UK_Persona_UF_CBU UNIQUE (cvu_cbu),
            CONSTRAINT FK_PERSONA_UF_UF FOREIGN KEY (id_consorcio, id_uf) REFERENCES UF(id_consorcio, id),
            CONSTRAINT FK_PERSONA_UF_CBU FOREIGN KEY (cvu_cbu) REFERENCES Persona(cvu_cbu),
            CONSTRAINT FK_PERSONA_UF_TIPO_RELACION FOREIGN KEY (id_tipo_relacion) REFERENCES Tipo_relacion(id)
        );

        CREATE TABLE Estado_de_cuenta (
            id_cuenta INT IDENTITY(1,1) PRIMARY KEY,
            id_consorcio INT NOT NULL,
            id_uf INT NOT NULL,
            pagos_registrados DECIMAL(12,2) DEFAULT 0,
            gasto_ord DECIMAL(12,2) DEFAULT 0,
            gasto_ext DECIMAL(12,2) DEFAULT 0,
            gasto_cochera DECIMAL(12,2) DEFAULT 0,
            gasto_baulera DECIMAL(12,2) DEFAULT 0,
            saldo_anterior DECIMAL(12,2) DEFAULT 0,
            anio INT NOT NULL,
            mes TINYINT NOT NULL,
            fecha_creacion DATE DEFAULT GETDATE(),
            CONSTRAINT FK_ESTADO_DE_CUENTA_UF FOREIGN KEY (id_consorcio, id_uf) REFERENCES UF(id_consorcio, id),
            CONSTRAINT CHK_ESTADO_CUENTA_MES CHECK (mes BETWEEN 1 AND 12)
        );

        CREATE TABLE Estado_financiero (
            id_est_finan INT IDENTITY(1,1) PRIMARY KEY,
            id_consorcio INT NOT NULL,
            egresos_mes DECIMAL(12,2) DEFAULT 0,
            ingreso_termino DECIMAL(12,2) DEFAULT 0,
            ingreso_adeudado DECIMAL(12,2) DEFAULT 0,
            ingreso_adelantado DECIMAL(12,2) DEFAULT 0,
            saldo_anterior DECIMAL(12,2) DEFAULT 0,
            anio INT NOT NULL,
            mes TINYINT NOT NULL,
            fecha_creacion DATE DEFAULT GETDATE(),
            CONSTRAINT FK_ESTADO_FINANCIERO_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
            CONSTRAINT CHK_ESTADO_FINANCIERO_MES CHECK (mes BETWEEN 1 AND 12)
        );

        CREATE TABLE Expensa (
            id INT IDENTITY(1,1) PRIMARY KEY,
            id_consorcio INT NOT NULL,
            anio INT NOT NULL,
            mes TINYINT NOT NULL,
            vence1 DATE NULL,
            vence2 DATE NULL,
            CONSTRAINT FK_EXPENSA_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
            CONSTRAINT CHK_EXPENSA_MES CHECK (mes BETWEEN 1 AND 12)
        );

        CREATE TABLE Proveedor (
            id INT IDENTITY(1,1) PRIMARY KEY,
            razon_social VARCHAR(200) NOT NULL,
            cuenta varchar(50),
            );

        CREATE TABLE Proveedor_Consorcio(
        id_consorcio int,
        id_proveedor INT,
        CONSTRAINT PK_PROVEEDOR_CONSORCIO PRIMARY KEY (id_consorcio, id_proveedor),
        CONSTRAINT FK_PROV_CONS FOREIGN KEY (id_consorcio) references Consorcio (id),
        CONSTRAINT FK_CONS_PROV FOREIGN KEY (id_proveedor) references Proveedor (id)
        );

        CREATE TABLE Tipo_Gasto (
            id INT IDENTITY(1,1) PRIMARY KEY,
            descripcion VARCHAR(100) NOT NULL
        );

        CREATE TABLE Tipo_Servicio (
            id INT IDENTITY(1,1) PRIMARY KEY,
            descripcion VARCHAR(100) NOT NULL,
            id_tipo_gasto INT NULL,
            CONSTRAINT FK_TIPO_SERVICIO_TIPO_GASTO FOREIGN KEY (id_tipo_gasto) REFERENCES Tipo_Gasto(id)
        );

        CREATE TABLE Detalle_Expensa (
            id_det_exp INT IDENTITY(1,1) PRIMARY KEY,
            id_expensa INT NOT NULL,
            fecha DATE NULL,
            importe DECIMAL(12,2) NULL,
            id_proveedor INT NULL,
            id_tipo_servicio INT NULL,
            descripcion NVARCHAR(100) NULL,
            CONSTRAINT FK_DET_EXP_EXPENSA FOREIGN KEY (id_expensa) REFERENCES Expensa(id),
            CONSTRAINT FK_DET_EXP_PROVEEDOR FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id),
            CONSTRAINT FK_DET_EXP_TIPO_SERVICIO FOREIGN KEY (id_tipo_servicio) REFERENCES Tipo_Servicio(id)
        );

        CREATE TABLE Gasto_Ordinario (
            id_gasto INT PRIMARY KEY,
            nro_factura VARCHAR(50) NULL,
            CONSTRAINT FK_ORDINARIO_DET_EXP FOREIGN KEY (id_gasto) REFERENCES Detalle_Expensa(id_det_exp)
        );

        CREATE TABLE Gasto_Extraordinario (
            id_gasto INT PRIMARY KEY,
            cant_cuota INT NULL,
            cuota_pagada INT DEFAULT 0,
            CONSTRAINT FK_EXTRAORDINARIO_DET_EXP FOREIGN KEY (id_gasto) REFERENCES Detalle_Expensa(id_det_exp)
        );

        CREATE TABLE Pago (
            id_pago INT IDENTITY(1,1) PRIMARY KEY,
            fecha_pago DATE NULL,
            cbu_cvu CHAR(22) NULL,
            monto DECIMAL(12,2) NULL,
            id_exp INT NULL,
            CONSTRAINT FK_PAGO_EXP FOREIGN KEY (id_exp) REFERENCES Expensa(id),
            CONSTRAINT PAGO_CHK_CBU CHECK 
            (cbu_cvu LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')            
        );
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '';
        PRINT 'ERROR AL CREAR ESTRUCTURA:';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        
        THROW;
    END CATCH
END;
GO

exec SP_CrearTablasYSchemas
