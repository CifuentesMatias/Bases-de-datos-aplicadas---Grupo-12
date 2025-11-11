if db_id('Com2900G12') is null
	create database Com2900G12 collate Latin1_General_CI_AS;
go

use Com2900G12
go

-- Creacion de base
CREATE DATABASE Com2900G12;
go

-- Creacion de usuarios
	-- Administrador general del sistema.
	/* Es el que crea y elimina registros de consorcios, unidades, personas.
	Ejecuta scripts críticos.
	Asigna permisos a otros usuarios. 
	*/
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'admin_expensas')
    CREATE LOGIN admin_expensas WITH PASSWORD = '124Admin!';
GO

CREATE USER admin_expensas FOR LOGIN admin_expensas;
EXEC sp_addrolemember 'db_owner', 'admin_expensas';
GO

	-- Encargado de registrar pagos y generar reportes.
	/* 
	Sin acceso a eliminar registros.
	*/
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'tesorero')
    CREATE LOGIN tesorero WITH PASSWORD = 'Teso!';
GO
CREATE USER tesorero FOR LOGIN tesorero;
GO

	-- Usuario del consorcio (solo consulta).

	/*
	No puede modificar datos.
	*/
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'pConsorcio')
    CREATE LOGIN pConsorcio WITH PASSWORD = 'Consorcio2025!';
GO
CREATE USER pConsorcio FOR LOGIN pConsorcio;
GO


-- SCHEMAS
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Personas')
    EXEC('CREATE SCHEMA Personas AUTHORIZATION dbo;');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'UF')
    EXEC('CREATE SCHEMA UF AUTHORIZATION dbo;');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Consorcio')
    EXEC('CREATE SCHEMA Consorcio AUTHORIZATION dbo;');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Expensa')
    EXEC('CREATE SCHEMA Expensa AUTHORIZATION dbo;');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Gasto')
    EXEC('CREATE SCHEMA Gasto AUTHORIZATION dbo;');

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Pago')
    EXEC('CREATE SCHEMA Pago AUTHORIZATION dbo;');
GO

--Creacion de tablas
CREATE TABLE Prop_Inq -- REVEER
(
	id				TINYINT IDENTITY(1,1),
	Descripcion			NVARCHAR(30),
	CONSTRAINT PROP_INQ_PK PRIMARY KEY (id),
);

CREATE TABLE Personas.Persona
(
	id				INT IDENTITY(1,1),
	dni				INT NOT NULL,
	nombre			NVARCHAR(25) NULL,
	apellido		NVARCHAR(25) NULL,
	email			VARCHAR(255) NULL,	-- segun estandar email es hasta 255
	telefono		char(12) NULL,		-- 123-12345678
	cbu_cvu			char(22) not null,
	-- Prop_Inq		TINYINT,

	CONSTRAINT PERSONA_PK PRIMARY KEY (id, cbu_cvu),


	-- CONSTRAINT PERSONA_FK_PoI FOREIGN KEY (Prop_Inq) REFERENCES Prop_Inq(id),
	CONSTRAINT PERSONA_CHK_CBU CHECK 
	(cbu_cvu LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),

	CONSTRAINT PERSONA_UK UNIQUE (dni),
	CONSTRAINT PERSONA_CHK_TELEFONO CHECK (telefono 
		LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

CREATE TABLE Consorcio.Consorcio
(
	id	INT IDENTITY(1,1),
	razon_social nvarchar(50) not null,
	nombre NVARCHAR(50) NOT NULL,
	m2	NUMERIC(7,2) NOT NULL,

	CONSTRAINT CONSORCIO_PK PRIMARY KEY (id),
	CONSTRAINT CONSORCIO_CHK_M2 CHECK (m2 > 0)
);

CREATE TABLE UF.Unidad_Funcional
(
	id				INT IDENTITY(1,1),
	id_consorcio	INT NOT NULL,
	piso			TINYINT NOT NULL,
	departamento	CHAR(1) NOT NULL,
	m2				NUMERIC(5,2) NOT NULL,
	porcentual_edf	NUMERIC(5,2) NOT NULL,

	CONSTRAINT UF_PK PRIMARY KEY (id, id_consorcio),
	-- CONSTRAINT UF_UK UNIQUE (id_consorcio, piso, departamento),

	--CONSTRAINT UF_UK_INQUILINO UNIQUE (id_inquilino),
	CONSTRAINT UF_FK_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
	CONSTRAINT UF_CHK_DEPARTAMENTO CHECK (departamento LIKE '[A-Z]'),
	CONSTRAINT UF_CHK_M2 CHECK (m2 > 0),
	CONSTRAINT UF_CHK_PORC CHECK (porcentual_edf > 0),
);

CREATE TABLE Personas.Persona_UF
(
	cbu_cvu	INT NOT NULL,
	id_uf	INT NOT NULL,
	id_consorcio int not null,
	fecha date not null,

	CONSTRAINT PERSONA_UF_PK PRIMARY KEY (cbu_cvu, id_uf, id_consorcio),
	CONSTRAINT PERSONA_UF_FK_PERSONA FOREIGN KEY (cbu_cvu) REFERENCES Persona(cbu_cvu),
	CONSTRAINT PERSONA_UF_FK_UF FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id),
);

CREATE TABLE UF.Tipo_Adicional
(
	Tipo				TINYINT IDENTITY(1,1),
	Descripcion			NVARCHAR(30),


	CONSTRAINT TIPO_ADICIONAL_PK PRIMARY KEY (Tipo),
);

CREATE TABLE UF.Adicional
(
	id				TINYINT IDENTITY(1,1),
	id_uf			INT NOT NULL,
	m2				NUMERIC(5,2) NOT NULL,
	Tipo			TINYINT NOT NULL,
	CONSTRAINT ADICIONAL_PK PRIMARY KEY (id),
	CONSTRAINT ADICIONAL_FK_UF FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id),
	CONSTRAINT ADICIONAL_FK_Tipo FOREIGN KEY (Tipo) REFERENCES Tipo_Adicional(Tipo),
	CONSTRAINT ADICIONAL_CHK_M2 CHECK (m2 > 0)
);

CREATE TABLE Expensa.Expensa
(
	id INT IDENTITY(1,1),
	vencimiento1 DATE,
	vencimiento2 DATE,
	importe_total NUMERIC(9,2) NOT NULL,
	mes			int,
	anio		int,
	id_persona	int NOT NULL,
	id_consorcio int NOT NULL,
	CONSTRAINT EXPENSA_CHK_IMPORTE CHECK (importe_total > 0),
	CONSTRAINT EXPENSA_PERSONA FOREIGN KEY (id_persona) REFERENCES Persona(id),
	CONSTRAINT EXPENSA_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
	CONSTRAINT EXPENSA_PK PRIMARY KEY (id)
);

CREATE TABLE Expensa.Detalle_Expensa
(
	id			INT IDENTITY(1,1),
	id_expensa INT NOT NULL,
	fecha		DATE NOT NULL,
	importe		NUMERIC(9,2) NOT NULL,
	Tipo_gasto	varchar(15) NOT NULL,
	CONSTRAINT DETALLE_EXPENSA_PK PRIMARY KEY (id),
	CONSTRAINT DETALLE_EXPENSA_CHK_IMPORTE CHECK (importe > 0),
	CONSTRAINT DETALLE_EXPENSA_FK_EXPENSA FOREIGN KEY (id_expensa) REFERENCES Expensa(id)
);

CREATE TABLE Pago.Pago
(
	id				INT IDENTITY(1,1),
	cbu_cvu			char(22) not null,
	fecha_pago		DATE not null,
	monto			NUMERIC(9,2) NOT NULL,
	-- id_gasto		INT,
	-- CONSTRAINT PAGO_GASTO FOREIGN KEY (id_gasto) REFERENCES Detalle_Expensa(id),
	CONSTRAINT PAGO_PK PRIMARY KEY (id),
	CONSTRAINT PAGO_CBU_CVU FOREIGN KEY (cbu_cvu) REFERENCES Persona(cbu_cvu),
);

CREATE TABLE Proveedor
(
	id				INT IDENTITY(1,1),
	nombre_proveedor varchar(50),
	-- tipo_servicio	varchar(50),
	CONSTRAINT PROVEEDOR_PK PRIMARY KEY (id),
);

CREATE TABLE Gasto.Gasto_Ordinario
(
	id				INT NOT NULL,
	id_proveedor	INT NOT NULL,
	nro_factura		INT,
	CONSTRAINT GASTO_ORDINARIO_PK PRIMARY KEY (id),
	CONSTRAINT GASTO_ORDINARIO_FK_EXPENSA FOREIGN KEY (id) REFERENCES Detalle_Expensa(id),
	CONSTRAINT GASTO_ORDINARIO_FK_PROVEEDOR FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id),
);

CREATE TABLE Gasto.Gasto_Extraordinario
(
	id				INT NOT NULL,
	id_proveedor	INT NOT NULL,
	nro_factura		INT,
	descripcion		varchar(50),
	cuota_paga		TINYINT,
	cant_cuotas		TINYINT,
	CONSTRAINT GASTO_EXTRAORDINARIO_PK PRIMARY KEY (id),
	CONSTRAINT GASTO_EXTRAORDINARIO_CHK_CUOTA_PAGA CHECK (cuota_paga > 0),
	CONSTRAINT GASTO_EXTRAORDINARIO_CHK_CANT_CUOTAS CHECK (cant_cuotas > 0),
	CONSTRAINT GASTO_EXTRAORDINARIO_CHK_CUOTAS CHECK (cuota_paga <= cant_cuotas),
	CONSTRAINT GASTO_EXTRAORDINARIO_FK_EXPENSA FOREIGN KEY (id) REFERENCES Detalle_Expensa(id),
	CONSTRAINT GASTO_EXTRAORDINARIO_FK_PROVEEDOR FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id),
);

CREATE TABLE UF.EstadoCuenta
(
    id_cuenta       INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio    INT NOT NULL,
    id_uf           INT NOT NULL,
    pagos_registrados		DECIMAL(18,2) NOT NULL,
    gasto_ord      DECIMAL(18,2) NOT NULL,
    gasto_ext DECIMAL(18,2) NOT NULL,
	gasto_cochera DECIMAL(18,2) NOT NULL,
	gasto_baulera DECIMAL(18,2) NOT NULL,
    saldo_anterior DECIMAL(18,2) NOT NULL,
    -- saldo_cierre DECIMAL(18,2) NOT NULL,
    anio            INT NOT NULL,
    mes             INT NOT NULL,
    fecha_creacion DATE DEFAULT GETDATE(),


	constraint FK_idConsorcio foreign key(id_consorcio) references Consorcio(id),
	constraint FK_idUnidadFuncional foreign key(id_uf) references Unidad_Funcional(id)
);

CREATE TABLE Consorcio.EstadoFinanciero
(
    id_est_financiero  INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio    INT NOT NULL,
	
	egresos_mes decimal(18,2) not null,
	ingreso_termino decimal(18,2) not null,
	ingreso_adeudado decimal(18,2) not null,
	ingreso_adelantado decimal(18,2) not null,

    saldo_anterior DECIMAL(18,2) NOT NULL,
    -- saldo_cierre DECIMAL(18,2) NOT NULL,
    anio            INT NOT NULL,
    mes             INT NOT NULL,
    fecha_creacion DATE DEFAULT GETDATE(),


	constraint FK_idConsorcio foreign key(id_consorcio) references Consorcio(id),
);