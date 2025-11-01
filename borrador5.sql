USE Com2900G12;
GO

CREATE OR ALTER PROCEDURE dbo.p_ImportarPersonas 
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ------------------------------------------------- Verificar existencia del archivo
        DECLARE @FileExists INT;
        CREATE TABLE #FileCheck (FileExists INT, FileIsDir INT, ParentDirExists INT);
        INSERT INTO #FileCheck EXEC xp_fileexist @RutaArchivo;
        SELECT @FileExists = FileExists FROM #FileCheck;
        DROP TABLE #FileCheck;
        
        IF @FileExists = 0
        BEGIN
            RAISERROR('El archivo especificado no existe o no es accesible.', 16, 1);
            RETURN;
        END;

        -------------------------------------------------
        -- Crear tabla temporal
        IF OBJECT_ID('tempdb..#TempPersonas') IS NOT NULL
            DROP TABLE #TempPersonas;
            
        CREATE TABLE #TempPersonas (
            nombre NVARCHAR(25),
            apellido NVARCHAR(25),
            dni INT,
            email VARCHAR(255),
            telefono CHAR(12)
        );

        ------------------------------------------------Importar desde CSV 
        DECLARE @SQL NVARCHAR(MAX);

        SET @SQL = N'
        INSERT INTO #TempPersonas (nombre, apellido, dni, email, telefono)
        SELECT nombre, apellido, dni, email, telefono
        FROM OPENROWSET(
            BULK ''' + @RutaArchivo + ''',
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n''
        ) AS CSVFile(nombre NVARCHAR(25), apellido NVARCHAR(25), dni INT, email VARCHAR(255), telefono CHAR(12))';

        EXEC sp_executesql @SQL;

        ------------------------------------------------- Solo agregar las novedades
        INSERT INTO Persona (dni, nombre, apellido, email, telefono)
        SELECT TP.dni, TP.nombre, TP.apellido, TP.email, TP.telefono
        FROM #TempPersonas TP
        WHERE NOT EXISTS (
            SELECT 1 FROM Persona P WHERE P.dni = TP.dni
        );

        ------------------------------------------------- Limpiar tabla temporal
        DROP TABLE #TempPersonas;

    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietario-datos.csv'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Com2900G12;
GO

CREATE OR ALTER PROCEDURE dbo.p_ImportarUnidadesFuncionales
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ------------------------------------------------- Verificar existencia del archivo
        DECLARE @FileExists INT;
        CREATE TABLE #FileCheck (FileExists INT, FileIsDir INT, ParentDirExists INT);
        INSERT INTO #FileCheck EXEC xp_fileexist @RutaArchivo;
        SELECT @FileExists = FileExists FROM #FileCheck;
        DROP TABLE #FileCheck;
        
        IF @FileExists = 0
        BEGIN
            RAISERROR('El archivo especificado no existe o no es accesible.', 16, 1);
            RETURN;
        END;
        
        ------------------------------------------------- Crear tabla temporal
        IF OBJECT_ID('tempdb..#TempUnidadesFuncionales') IS NOT NULL
    DROP TABLE #TempUnidadesFuncionales;
    
CREATE TABLE #TempUnidadesFuncionales (
    cbu_cvu NVARCHAR(50),
    nombre_consorcio NVARCHAR(50),
    nro_uf INT,
    piso_texto NVARCHAR(10),
    departamento CHAR(1)
);

------------------------------------------------- Importar desde CSV 
DECLARE @SQL NVARCHAR(MAX);
SET @SQL = N'
INSERT INTO #TempUnidadesFuncionales (cbu_cvu, nombre_consorcio, nro_uf, piso_texto, departamento)
SELECT cbu_cvu, nombre_consorcio, nro_uf, piso_texto, departamento
FROM OPENROWSET(
    BULK ''' + @RutaArchivo + ''',
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = ''|'',
    ROWTERMINATOR = ''\n''
) AS CSVFile(
    cbu_cvu NVARCHAR(50), 
    nombre_consorcio NVARCHAR(50), 
    nro_uf INT, 
    piso_texto NVARCHAR(10), 
    departamento CHAR(1)
)';
EXEC sp_executesql @SQL;

------------------------------------------------- Solo agregar las novedades
INSERT INTO Unidad_Funcional (
    id_consorcio, 
    piso, 
    departamento, 
    m2,
    id_baulera,
    id_cochera,
    id_propietario,
    id_inquilino
)
SELECT 
    C.id AS id_consorcio,
    TRY_CONVERT(TINYINT, T.piso_texto) AS piso,
    T.departamento,
    50.00 AS m2,
    NULL AS id_baulera,
    NULL AS id_cochera,
    NULL AS id_propietario,
    NULL AS id_inquilino
FROM #TempUnidadesFuncionales T
INNER JOIN Consorcio C ON C.nombre = T.nombre_consorcio
WHERE NOT EXISTS (
    SELECT 1 
    FROM Unidad_Funcional UF
    WHERE UF.id_consorcio = C.id
      AND UF.piso = TRY_CONVERT(TINYINT, T.piso_texto)
      AND UF.departamento = T.departamento
);
        ------------------------------------------------- Limpiar tabla temporal
        DROP TABLE #TempUnidadesFuncionales;

    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietarios-UF.csv'

CREATE OR ALTER PROCEDURE dbo.p_ImportarPagos
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        ------------------------------------------------- Verificar existencia del archivo
        DECLARE @FileExists INT;
        CREATE TABLE #FileCheck (FileExists INT, FileIsDir INT, ParentDirExists INT);
        INSERT INTO #FileCheck EXEC xp_fileexist @RutaArchivo;
        SELECT @FileExists = FileExists FROM #FileCheck;
        DROP TABLE #FileCheck;
        
        IF @FileExists = 0
        BEGIN
            RAISERROR('El archivo especificado no existe o no es accesible.', 16, 1);
            RETURN;
        END;
        
        ------------------------------------------------- Crear tabla temporal
IF OBJECT_ID('tempdb..#TempPagos') IS NOT NULL
    DROP TABLE #TempPagos;
    
CREATE TABLE #TempPagos (
    id_pago INT,
    fecha_texto NVARCHAR(20),
    cbu_cvu NVARCHAR(50),
    monto_texto NVARCHAR(50)
);

------------------------------------------------- Importar desde CSV 
SET @SQL = N'
INSERT INTO #TempPagos (id_pago, fecha_texto, cbu_cvu, monto_texto)
SELECT id_pago, fecha_texto, cbu_cvu, monto_texto
FROM OPENROWSET(
    BULK ''' + @RutaArchivo + ''',
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n''
) AS CSVFile(
    id_pago INT,
    fecha_texto NVARCHAR(20),
    cbu_cvu NVARCHAR(50),
    monto_texto NVARCHAR(50)
)
WHERE id_pago IS NOT NULL';
EXEC sp_executesql @SQL;

------------------------------------------------- Solo agregar las novedades
INSERT INTO Pago (id_pago, fecha_pago, monto, cbu_cvu)
SELECT 
    TP.id_pago,
    TRY_CONVERT(DATETIME, TP.fecha_texto, 103) AS fecha_pago,
    TRY_CONVERT(NUMERIC(9,2), REPLACE(REPLACE(REPLACE(TP.monto_texto, '$', ''), ' ', ''), ',', '')) AS monto,
    REPLACE(REPLACE(TP.cbu_cvu, ' ', ''), '-', '') AS cbu_cvu
FROM #TempPagos TP
WHERE NOT EXISTS (
    SELECT 1 
    FROM Pago P 
    WHERE P.id_pago = TP.id_pago
)
  AND TRY_CONVERT(DATETIME, TP.fecha_texto, 103) IS NOT NULL
  AND TRY_CONVERT(NUMERIC(9,2), REPLACE(REPLACE(REPLACE(TP.monto_texto, '$', ''), ' ', ''), ',', '')) IS NOT NULL;
        
        ------------------------------------------------- Limpiar tabla temporal
        DROP TABLE #TempPagos;
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\pagos_consorcios.csv'
