--Creacion de base
CREATE DATABASE Com2900G12; GO
USE Com2900G12; GO

--Creacion de usuarios
--CREATE LOGIN
GO

-- creacion de esquemas????????????????
GO

--Creacion de tablas
CREATE TABLE Persona
(
	id				INT IDENTITY(1,1),
	dni				INT NOT NULL,
	nombre			NVARCHAR(25) NULL,
	apellido		NVARCHAR(25) NULL,
	email			VARCHAR(255) NULL,	-- segun estandar email es hasta 255
	telefono		char(12) NULL,		-- 123-12345678
	CONSTRAINT PERSONA_PK PRIMARY KEY (id),
	CONSTRAINT PERSONA_UK UNIQUE (dni),
	CONSTRAINT PERSONA_CHK_TELEFONO CHECK (telefono 
		LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
); GO
CREATE TABLE Consorcio
(
	id				INT IDENTITY(1,1),
	nombre			NVARCHAR(50) NOT NULL,
	m2				NUMERIC(7,2) NOT NULL,
	CONSTRAINT CONSORCIO_PK PRIMARY KEY (id),
	CONSTRAINT CONSORCIO_CHK_M2 CHECK (m2 > 0)
); GO
CREATE TABLE Baulera
(
	id				TINYINT IDENTITY(1,1),
	id_consorcio	INT NOT NULL,
	m2				NUMERIC(5,2) NOT NULL,
	CONSTRAINT BAULERA_PK PRIMARY KEY (id),
	CONSTRAINT BAULERA_FK_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
	CONSTRAINT BAULERA_CHK_M2 CHECK (m2 > 0)
);GO
CREATE TABLE Cochera
(
	id				TINYINT IDENTITY(1,1),
	id_consorcio	INT NOT NULL,
	m2				NUMERIC(5,2) NOT NULL,
	CONSTRAINT COCHERA_PK PRIMARY KEY (id),
	CONSTRAINT COCHERA_FK_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
	CONSTRAINT COCHERA_CHK_M2 CHECK (m2 > 0)
); GO
CREATE TABLE Unidad_Funcional
(
	id_uf			INT IDENTITY(1,1),
	id_consorcio	INT NOT NULL,
	piso			TINYINT NOT NULL,
	departamento	CHAR(1) NOT NULL,
	m2				NUMERIC(5,2) NOT NULL,
	id_baulera		TINYINT NULL,
	id_cochera		TINYINT NULL,
	id_propietario	INT NULL,
	id_inquilino	INT NULL,
	CONSTRAINT UF_PK PRIMARY KEY (id_uf),
	CONSTRAINT UF_UK UNIQUE (id_consorcio, piso, departamento),
	--CONSTRAINT UF_UK_INQUILINO UNIQUE (id_inquilino),
	CONSTRAINT UF_CHK_PISO CHECK (piso > -1),
	CONSTRAINT UF_CHK_DEPARTAMENTO CHECK (departamento LIKE '[A-Z]'),
	CONSTRAINT UF_CHK_M2 CHECK (m2 > 0),
	CONSTRAINT UF_CHK_INQPROP CHECK (id_inquilino IS NULL OR id_propietario IS NOT NULL),
	CONSTRAINT UF_FK_CONSORCIO FOREIGN KEY (id_consorcio) REFERENCES Consorcio(id),
	CONSTRAINT UF_FK_BAULERA FOREIGN KEY (id_baulera) REFERENCES Baulera(id),
	CONSTRAINT UF_FK_COCHERA FOREIGN KEY (id_cochera) REFERENCES Cochera(id),
	CONSTRAINT UF_FK_PROPIETARIO FOREIGN KEY (id_propietario) REFERENCES Persona(id),
	CONSTRAINT UF_FK_INQUILINO FOREIGN KEY (id_inquilino) REFERENCES Persona(id)
); GO


-- DE ACA PARA ABAJO NOSE
CREATE TABLE Expensa
(
	id INT IDENTITY(1,1),
	fecha_venc DATE DEFAULT GETDATE(),
	importe_total NUMERIC(9,2) NOT NULL,
	CONSTRAINT EXPENSA_PK PRIMARY KEY (id)
); GO
CREATE TABLE Detalle_Expensa
(
	id INT IDENTITY(1,1),
	id_expensa INT NOT NULL,
	CONSTRAINT DE_PK PRIMARY KEY (id),
	CONSTRAINT DE_FK_EXPENSA FOREIGN KEY (id_expensa) REFERENCES Expensa(id)
); GO
CREATE TABLE Pago
(
	id INT IDENTITY(1,1),
	id_expensa INT NOT NULL,
	fecha_pago DATETIME NOT NULL,
	monto NUMERIC(9,2) NOT NULL,
	cbu_cvu CHAR(23) NOT NULL, -- 8 digitos + ' ' + 14 digitos
	CONSTRAINT PAGO_PK PRIMARY KEY (id),
	CONSTRAINT PAGO_FK_EXPENSA FOREIGN KEY (id_expensa) REFERENCES Expensa(id),
	CONSTRAINT PAGO_CHK_MONTO CHECK (monto > 0),
	CONSTRAINT PAGO_CHK_CBUCVU CHECK (cbu_cvu 
		LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
); GO
CREATE TABLE Factura
(
	id INT IDENTITY(1,1),
	CONSTRAINT FACTURA_PK PRIMARY KEY (id)
); GO


--Rellenando la db
/*
El conjunto de pruebas debe estar conformado por al menos.
• 1 consorcio con baulera y cochera ---> testSet_A
• 1 consorcio sin baulera y sin cochera ---> testSet_B
• 1 consorcio con baulera solamente ---> testSet_C
• 1 consorcio con cochera solamente ---> testSet_D
Cada consorcio debe constar de al menos 10 unidades funcionales, no necesariamente todas
las unidades funcionales deben tener asociadas cocheras y bauleras
*/
CREATE OR ALTER PROCEDURE testSet_A AS
BEGIN
	SET IDENTITY_INSERT Persona ON;
	--insertamos personas propietarias
	--1001 tiene todo
	--1002 no tiene celular
	--1003 no tiene email
	--1004 no tiene nada
	INSERT INTO Persona(id, dni, nombre, apellido, email, telefono) VALUES 
	(1001, 112201, N'Carlos', N'Rodriguéz', 'crodriguez@hotmail.com', '011-44225599'),
	(1002, 112202, N'Roberto', N'Gil', 'robertogil@hotmail.com', NULL),
	(1003, 112203, N'Julia', N'Marquéz', NULL, '011-22334455'),
	(1004, 112204, N'Marcos', N'Molina', NULL, NULL),
	(1005, 112205, N'Mariano', N'Lopéz', 'test@yahoo.com.ar', '011-11223344'),
	(1006, 112206, N'Jose', N'Suarez', 'test@yahoo.com.ar', '011-11223344'),
	(1007, 112207, N'Fernanda', N'Sosa', 'test@yahoo.com.ar', '011-11223344'),
	(1008, 112208, N'Maria', N'Gonzalez', 'test@yahoo.com.ar', '011-11223344'),
	(1009, 112209, N'Julieta', N'Rodriguéz', 'test@yahoo.com.ar', '011-11223344');
	--insertamos personas inquilinas
	--1501 tiene todo
	--1502 no tiene celular
	--1503 no tiene email
	--1504 no tiene nada
	INSERT INTO Persona(id, dni, nombre, apellido, email, telefono) VALUES 
	(1501, 112501, N'Federico', N'Grillo', 'fgrillo@hotmail.com', '011-66998855'),
	(1502, 112502, N'Mauricio', N'Macron', 'mmacron@hotmail.com', NULL),
	(1503, 112503, N'Florencia', N'Murcia', NULL, '011-88566977'),
	(1504, 112504, N'Brian', N'Dela Serna', NULL, NULL),
	(1505, 112505, N'Gloria', N'Gimenez', 'test@yahoo.com.ar', '011-11223344'),
	(1506, 112506, N'Camila', N'Gutierrez', 'test@yahoo.com.ar', '011-11223344'),
	(1507, 112507, N'Rosario', N'Gomez', 'test@yahoo.com.ar', '011-11223344'),
	(1508, 112508, N'Jose', N'Gomez', 'test@yahoo.com.ar', '011-11223344'),
	(1509, 112509, N'Flavia', N'Mendoza', 'test@yahoo.com.ar', '011-11223344'),
	(1510, 112510, N'Carolina', N'Gonzalez', 'test@yahoo.com.ar', '011-11223344');
	SET IDENTITY_INSERT Persona OFF;

	SET IDENTITY_INSERT Consorcio ON;
	INSERT INTO Consorcio(id, nombre, m2) VALUES 
	(10, N'Altos del aguila', 1350);
	SET IDENTITY_INSERT Consorcio OFF;

	--tiene 5 bauleras (son 35m2)
	SET IDENTITY_INSERT Baulera ON;
	INSERT INTO Baulera(id, id_consorcio, m2) VALUES 
	(101, 10, 5), (102, 10, 5), (103, 10, 5), (104, 10, 5), (105, 10, 15);
	SET IDENTITY_INSERT Baulera OFF;
	--tiene 5 cocheras (son 65m2)
	SET IDENTITY_INSERT Cochera ON;
	INSERT INTO Cochera(id, id_consorcio, m2) VALUES
	(101, 10, 10), (102, 10, 10), (103, 10, 10), (104, 10, 10), (105, 10, 25);
	SET IDENTITY_INSERT Cochera OFF;

	--PB: 2 propiedades de 125m2 = 250m2 (mas 100 m2 cochera+baulera)
	--piso 1: 6 prop de 75m2 = 450m2
	--piso 2: 4 prop de 100m2 = 400m2
	INSERT INTO Unidad_Funcional(id_consorcio, piso, departamento, m2, id_baulera,
								id_cochera,	id_propietario,	id_inquilino) VALUES
	(10, 0, 'A', 125, 105, NULL, NULL, NULL),(10, 0, 'B', 125,  NULL, 101,  NULL, NULL),
	(10, 1, 'A', 75, 101, 105, 1002, 1501),(10, 1, 'B', 75, 102, 104, 1003, 1502),
	(10, 1, 'C', 75, 103, NULL, 1004, 1503),(10, 1, 'D', 75, NULL, 103, 1005, 1504),
	(10, 1, 'E', 75, 104, NULL, 1006, 1505),(10, 1, 'F', 75, NULL, 102, 1007, 1506),
	(10, 2, 'A', 100, NULL, NULL, 1008, 1507),(10, 2, 'B', 100, NULL, NULL, 1009, 1508),
	(10, 2, 'C', 100, NULL, NULL, 1001, 1509),(10, 2, 'D', 100, NULL, NULL, 1001, 1510);
END; GO
CREATE OR ALTER PROCEDURE testSet_B AS
BEGIN
	INSERT INTO Consorcio VALUES (N'Campos Verdes', 700);
	
	INSERT INTO Persona VALUES (100, N'');

END; GO
CREATE OR ALTER PROCEDURE testSet_C AS
BEGIN
	INSERT INTO Consorcio VALUES (N'Reyes del cielo', 700);
	INSERT INTO Persona VALUES (100, N'');

END; GO
CREATE OR ALTER PROCEDURE testSet_D AS
BEGIN
	INSERT INTO Consorcio VALUES (N'Manantiales', 1200);

	INSERT INTO Persona VALUES (100, N'');

END; GO

CREATE OR ALTER VIEW vUnidadFuncionales AS
	SELECT
		edf.nombre as consorcio,
		(CASE piso WHEN 0 THEN 'PB' ELSE CAST(piso as VARCHAR(2)) END) + '-' + departamento as piso_departamento,
		CAST((uf.m2/edf.m2 * 100) AS NUMERIC(5,2)) as porc_superficie,
		CASE WHEN b.m2 IS NULL THEN 0 ELSE b.m2 END as baulera_m2,
		CASE WHEN c.m2 IS NULL THEN 0 ELSE c.m2 END as cochera_m2,
		(prop.nombre + ' ' + prop.apellido) as propietario,
		(inq.nombre + ' ' + inq.apellido) as inquilino
	FROM 
		Unidad_Funcional uf
	JOIN Consorcio edf ON edf.id = uf.id_consorcio
	LEFT JOIN Baulera b ON b.id = uf.id_baulera
	LEFT JOIN Cochera c ON c.id = uf.id_cochera
	LEFT JOIN Persona inq ON inq.id = uf.id_inquilino
	LEFT JOIN Persona prop ON prop.id = uf.id_propietario; GO

SELECT *
FROM vUnidadFuncionales


/*
Consorcio		Nombre del consorcio	Domicilio		Cant unidades funcionales	m2 totales
------------------------------------------------------------------------------------------------
Consorcio 1		Azcuenaga				Belgrano 3344	30							1281
Consorcio 2		Alzaga					Callao 1122		20							914
Consorcio 3		Alberdi					Santa Fe 910	20							784
Consorcio 4		Unzue					Corrientes 5678	25							1316
Consorcio 5		Pereyra Iraola			Rivadavia 1234	40							1691
*/

SELECT 
	('Consorcio ' + ROW_NUMBER() OVER()) as Consorcio,
	nombre as [Nombre del consorcio],
	domicilio as Domicilio,
	m2 as [m2 totales]
FROM Consorcio edf

CREATE OR ALTER PROCEDURE generarConsorcios_deArchivo(@path NVARCHAR(MAX)) AS
BEGIN
	INSERT INTO Consorcio() FROM BULK INSERT @path;
END; GO


/*
Nombre			apellido	DNI			email personal					teléfono de contacto	CVU/CBU		Inquilino
PATRICIA A 		SANDOVAL	232359550	SANDOVAL_PATRICIA A @email.com	1120639588				3,62255E+21	1
Mariela			NANIN		232475210	NANIN_ Mariela@email.com		1120639590				8,89916E+21	1
OSNAGHI ANDREA	LORENA		232738140	LORENA_OSNAGHI ANDREA@email.com	1120639674				6,79302E+21	1
ALEJANDRA		PAULETTE	232850890	PAULETTE_ ALEJANDRA@email.com	1120639615				4,53257E+21	0
*/
SELECT 
	nombre,
	apellido,
	dni,
	email,
	telefono,
	--cbu_cvu,
	(CASE WHEN uf.id_inquilino IS NULL THEN 0 ELSE 1 END) as Inquilino
FROM Persona p
LEFT JOIN Unidad_Funcional uf ON uf.id_inquilino = p.id
