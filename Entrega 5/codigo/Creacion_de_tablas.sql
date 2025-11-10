--Creacion de base
CREATE DATABASE Com2900G12;

--Creacion de usuarios
--CREATE LOGIN

-- creacion de esquemas????????????????

--Creacion de tablas
CREATE TABLE Prop_Inq
(
	id				TINYINT IDENTITY(1,1),
	Descripcion			NVARCHAR(30),
	CONSTRAINT PROP_INQ_PK PRIMARY KEY (id),
);

CREATE TABLE Persona
(
	id				INT IDENTITY(1,1),
	dni				INT NOT NULL,
	nombre			NVARCHAR(25) NULL,
	apellido		NVARCHAR(25) NULL,
	email			VARCHAR(255) NULL,	-- segun estandar email es hasta 255
	telefono		char(12) NULL,		-- 123-12345678
	cbu_cvu			char(22) not null UNIQUE,
	Prop_Inq		TINYINT,
	CONSTRAINT PERSONA_FK_PoI FOREIGN KEY (Prop_Inq) REFERENCES Prop_Inq(id),
	CONSTRAINT PERSONA_CHK_CBU CHECK 
	(cbu_cvu LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT PERSONA_PK PRIMARY KEY (id),
	CONSTRAINT PERSONA_UK UNIQUE (dni),
	CONSTRAINT PERSONA_CHK_TELEFONO CHECK (telefono 
		LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

CREATE TABLE Consorcio
(
	id				INT IDENTITY(1,1),
	nombre			NVARCHAR(50) NOT NULL,
	m2				NUMERIC(7,2) NOT NULL,
	CONSTRAINT CONSORCIO_PK PRIMARY KEY (id),
	CONSTRAINT CONSORCIO_CHK_M2 CHECK (m2 > 0)
);

CREATE TABLE Unidad_Funcional
(
	id				INT IDENTITY(1,1),
	id_consorcio	INT NOT NULL,
	piso			TINYINT NOT NULL,
	departamento	CHAR(1) NOT NULL,
	m2				NUMERIC(5,2) NOT NULL,
	porcentual_edf	NUMERIC(5,2) NOT NULL,
	CONSTRAINT UF_PK PRIMARY KEY (id),
	CONSTRAINT UF_UK UNIQUE (id_consorcio, piso, departamento),
	--CONSTRAINT UF_UK_INQUILINO UNIQUE (id_inquilino),
	CONSTRAINT UF_FK_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
	CONSTRAINT UF_CHK_DEPARTAMENTO CHECK (departamento LIKE '[A-Z]'),
	CONSTRAINT UF_CHK_M2 CHECK (m2 > 0),
	CONSTRAINT UF_CHK_PORC CHECK (porcentual_edf > 0),
);

CREATE TABLE Persona_UF
(
	id_persona			INT NOT NULL,
	id_uf				INT NOT NULL,
	CONSTRAINT PERSONA_UF_PK PRIMARY KEY (id_persona, id_uf),
	CONSTRAINT PERSONA_UF_FK_PERSONA FOREIGN KEY (id_persona) REFERENCES Persona(id),
	CONSTRAINT PERSONA_UF_FK_UF FOREIGN KEY (id_uf) REFERENCES Unidad_Funcional(id),
);

CREATE TABLE Tipo_Adicional
(
	Tipo				TINYINT IDENTITY(1,1),
	Descripcion			NVARCHAR(30),
	CONSTRAINT TIPO_ADICIONAL_PK PRIMARY KEY (Tipo),
);

CREATE TABLE Adicional
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

CREATE TABLE Expensa
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

CREATE TABLE Detalle_Expensa
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

CREATE TABLE Pago
(
	id				INT IDENTITY(1,1),
	cbu_cvu			char(22) not null,
	fecha_pago		DATE,
	monto			NUMERIC(9,2) NOT NULL,
	id_gasto		INT,
	CONSTRAINT PAGO_GASTO FOREIGN KEY (id_gasto) REFERENCES Detalle_Expensa(id),
	CONSTRAINT PAGO_PK PRIMARY KEY (id),
	CONSTRAINT PAGO_CBU_CVU FOREIGN KEY (cbu_cvu) REFERENCES Persona(cbu_cvu),
);

CREATE TABLE Proveedor
(
	id				INT IDENTITY(1,1),
	nombre_proveedor varchar(50),
	tipo_servicio	varchar(50),
	CONSTRAINT PROVEEDOR_PK PRIMARY KEY (id),
);

CREATE TABLE Gasto_Ordinario
(
	id				INT NOT NULL,
	id_proveedor	INT NOT NULL,
	nro_factura		INT,
	CONSTRAINT GASTO_ORDINARIO_PK PRIMARY KEY (id),
	CONSTRAINT GASTO_ORDINARIO_FK_EXPENSA FOREIGN KEY (id) REFERENCES Detalle_Expensa(id),
	CONSTRAINT GASTO_ORDINARIO_FK_PROVEEDOR FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id),
);

CREATE TABLE Gasto_Extraordinario
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

CREATE TABLE EstadoCuenta_UF
(
    id_cuenta       INT IDENTITY(1,1) PRIMARY KEY,
    id_consorcio    INT NOT NULL,
    id_uf           INT NOT NULL,
    ingresos		DECIMAL(18,2) NOT NULL,
    ExpensasOrdinarias      DECIMAL(18,2) NOT NULL,
    ExpensasExtraordinarias DECIMAL(18,2) NOT NULL,
    saldo_anterior DECIMAL(18,2) NOT NULL,
    saldo_cierre DECIMAL(18,2) NOT NULL,
    anio            INT NOT NULL,
    mes             INT NOT NULL,
    fecha_creacion DATE DEFAULT GETDATE(),


	constraint FK_idConsorcio foreign key(id_consorcio) references Consorcio(id),
	constraint FK_idUnidadFuncional foreign key(id_uf) references Unidad_Funcional(id)
);