USE Com2900G12;
GO

------------------------------------------------------------ ☻ PROCEDIMIENTO: p_ImportarPersonas

CREATE OR ALTER PROCEDURE dbo.p_ImportarPersonas 
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Crear tabla temporal de errores
        IF OBJECT_ID('tempdb..#Log_Errores_Importacion') IS NOT NULL
            DROP TABLE #Log_Errores_Importacion;
            
        CREATE TABLE #Log_Errores_Importacion (
            id INT IDENTITY(1,1) PRIMARY KEY,
            numero_fila INT,
            datos_fila NVARCHAR(MAX),
            mensaje_error NVARCHAR(MAX)
        );

        -- Verificar existencia del archivo
        DECLARE @FileExists INT;
        CREATE TABLE #FileCheck (FileExists INT, FileIsDir INT, ParentDirExists INT);
        INSERT INTO #FileCheck EXEC xp_fileexist @RutaArchivo;
        SELECT @FileExists = FileExists FROM #FileCheck;
        DROP TABLE #FileCheck;
        
        IF @FileExists = 0
        BEGIN
            INSERT INTO #Log_Errores_Importacion (numero_fila, datos_fila, mensaje_error)
            VALUES (0, @RutaArchivo, 'El archivo especificado no existe o no es accesible.');
            
            SELECT * FROM #Log_Errores_Importacion;
            RETURN;
        END;

        -- Crear tabla temporal
        IF OBJECT_ID('tempdb..#TempPersonas') IS NOT NULL
            DROP TABLE #TempPersonas;
            
        CREATE TABLE #TempPersonas (
            fila INT IDENTITY(1,1),
            nombre NVARCHAR(25),
            apellido NVARCHAR(25),
            dni INT,
            email VARCHAR(255),
            telefono CHAR(12)
        );

        -- Importar desde CSV 
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

        -- Procesar fila por fila
        DECLARE @fila INT, @nombre NVARCHAR(25), @apellido NVARCHAR(25), @dni INT, @email VARCHAR(255), @telefono CHAR(12);
        DECLARE @DatosFila NVARCHAR(MAX);

        DECLARE cursor_personas CURSOR FOR
        SELECT fila, nombre, apellido, dni, email, telefono
        FROM #TempPersonas;

        OPEN cursor_personas;
        FETCH NEXT FROM cursor_personas INTO @fila, @nombre, @apellido, @dni, @email, @telefono;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                SET @DatosFila = CONCAT('DNI:', @dni, ' | Nombre:', @nombre, ' | Apellido:', @apellido, ' | Email:', @email, ' | Tel:', @telefono);

                -- Solo agregar si NO existe
                IF NOT EXISTS (SELECT 1 FROM Persona WHERE dni = @dni)
                BEGIN
                    INSERT INTO Persona (dni, nombre, apellido, email, telefono)
                    VALUES (@dni, @nombre, @apellido, @email, @telefono);
                END
            END TRY
            BEGIN CATCH
                INSERT INTO #Log_Errores_Importacion (numero_fila, datos_fila, mensaje_error)
                VALUES (@fila + 1, @DatosFila, ERROR_MESSAGE());
            END CATCH

            FETCH NEXT FROM cursor_personas INTO @fila, @nombre, @apellido, @dni, @email, @telefono;
        END

        CLOSE cursor_personas;
        DEALLOCATE cursor_personas;

        DROP TABLE #TempPersonas;

        SELECT * FROM #Log_Errores_Importacion;
        
        DROP TABLE #Log_Errores_Importacion;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#Log_Errores_Importacion') IS NOT NULL
        BEGIN
            SELECT * FROM #Log_Errores_Importacion;
            DROP TABLE #Log_Errores_Importacion;
        END
    END CATCH
END;
GO

EXEC dbo.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietario-datos.csv';
GO


------------------------------------------------------------ ☻  PROCEDIMIENTO: p_ImportarUnidadesFuncionales

CREATE OR ALTER PROCEDURE dbo.p_ImportarUnidadesFuncionales
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Crear tabla temporal de errores
        IF OBJECT_ID('tempdb..#Log_Errores_Importacion') IS NOT NULL
            DROP TABLE #Log_Errores_Importacion;
            
        CREATE TABLE #Log_Errores_Importacion (
            id INT IDENTITY(1,1) PRIMARY KEY,
            numero_fila INT,
            datos_fila NVARCHAR(MAX),
            mensaje_error NVARCHAR(MAX)
        );

        -- Verificar existencia del archivo
        DECLARE @FileExists INT;
        CREATE TABLE #FileCheck (FileExists INT, FileIsDir INT, ParentDirExists INT);
        INSERT INTO #FileCheck EXEC xp_fileexist @RutaArchivo;
        SELECT @FileExists = FileExists FROM #FileCheck;
        DROP TABLE #FileCheck;
        
        IF @FileExists = 0
        BEGIN
            INSERT INTO #Log_Errores_Importacion (numero_fila, datos_fila, mensaje_error)
            VALUES (0, @RutaArchivo, 'El archivo especificado no existe o no es accesible.');
            
            SELECT * FROM #Log_Errores_Importacion;
            RETURN;
        END;
        
        -- Crear tabla temporal
        IF OBJECT_ID('tempdb..#TempUnidadesFuncionales') IS NOT NULL
            DROP TABLE #TempUnidadesFuncionales;
        
        CREATE TABLE #TempUnidadesFuncionales (
            fila INT IDENTITY(1,1),
            cbu_cvu NVARCHAR(50),
            nombre_consorcio NVARCHAR(50),
            nro_uf INT,
            piso_texto NVARCHAR(10),
            departamento CHAR(1)
        );

        -- Importar desde CSV 
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

        -- Procesar fila por fila
        DECLARE @fila INT, @cbu_cvu NVARCHAR(50), @nombre_consorcio NVARCHAR(50), @nro_uf INT, 
                @piso_texto NVARCHAR(10), @departamento CHAR(1);
        DECLARE @DatosFila NVARCHAR(MAX);
        DECLARE @id_consorcio INT, @piso TINYINT;

        DECLARE cursor_uf CURSOR FOR
        SELECT fila, cbu_cvu, nombre_consorcio, nro_uf, piso_texto, departamento
        FROM #TempUnidadesFuncionales;

        OPEN cursor_uf;
        FETCH NEXT FROM cursor_uf INTO @fila, @cbu_cvu, @nombre_consorcio, @nro_uf, @piso_texto, @departamento;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                SET @DatosFila = CONCAT('Consorcio:', @nombre_consorcio, ' | UF:', @nro_uf, ' | Piso:', @piso_texto, ' | Depto:', @departamento);

                SELECT @id_consorcio = id FROM Consorcio WHERE nombre = @nombre_consorcio;
                SET @piso = TRY_CONVERT(TINYINT, @piso_texto);
                
                -- Solo agregar si NO existe
                IF NOT EXISTS (
                    SELECT 1 FROM Unidad_Funcional 
                    WHERE id_consorcio = @id_consorcio 
                      AND piso = @piso 
                      AND departamento = @departamento
                )
                BEGIN
                    INSERT INTO Unidad_Funcional (id_consorcio, piso, departamento, m2, id_baulera, id_cochera, id_propietario, id_inquilino)
                    VALUES (@id_consorcio, @piso, @departamento, 50.00, NULL, NULL, NULL, NULL);
                END
            END TRY
            BEGIN CATCH
                INSERT INTO #Log_Errores_Importacion (numero_fila, datos_fila, mensaje_error)
                VALUES (@fila + 1, @DatosFila, ERROR_MESSAGE());
            END CATCH

            FETCH NEXT FROM cursor_uf INTO @fila, @cbu_cvu, @nombre_consorcio, @nro_uf, @piso_texto, @departamento;
        END

        CLOSE cursor_uf;
        DEALLOCATE cursor_uf;

        DROP TABLE #TempUnidadesFuncionales;

        SELECT * FROM #Log_Errores_Importacion;
        
        DROP TABLE #Log_Errores_Importacion;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#Log_Errores_Importacion') IS NOT NULL
        BEGIN
            SELECT * FROM #Log_Errores_Importacion;
            DROP TABLE #Log_Errores_Importacion;
        END
    END CATCH
END;
GO

EXEC dbo.p_ImportarUnidadesFuncionales @RutaArchivo = 'C:\consorcios\Inquilino-propietarios-UF.csv';
GO


------------------------------------------------------------ ☻ PROCEDIMIENTO: p_ImportarPagos

CREATE OR ALTER PROCEDURE dbo.p_ImportarPagos
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Crear tabla temporal de errores
        IF OBJECT_ID('tempdb..#Log_Errores_Importacion') IS NOT NULL
            DROP TABLE #Log_Errores_Importacion;
            
        CREATE TABLE #Log_Errores_Importacion (
            id INT IDENTITY(1,1) PRIMARY KEY,
            numero_fila INT,
            datos_fila NVARCHAR(MAX),
            mensaje_error NVARCHAR(MAX)
        );

        -- Verificar existencia del archivo
        DECLARE @FileExists INT;
        CREATE TABLE #FileCheck (FileExists INT, FileIsDir INT, ParentDirExists INT);
        INSERT INTO #FileCheck EXEC xp_fileexist @RutaArchivo;
        SELECT @FileExists = FileExists FROM #FileCheck;
        DROP TABLE #FileCheck;
        
        IF @FileExists = 0
        BEGIN
            INSERT INTO #Log_Errores_Importacion (numero_fila, datos_fila, mensaje_error)
            VALUES (0, @RutaArchivo, 'El archivo especificado no existe o no es accesible.');
            
            SELECT * FROM #Log_Errores_Importacion;
            RETURN;
        END;
        
        -- Crear tabla temporal
        IF OBJECT_ID('tempdb..#TempPagos') IS NOT NULL
            DROP TABLE #TempPagos;
        
        CREATE TABLE #TempPagos (
            fila INT IDENTITY(1,1),
            id_pago INT,
            fecha_texto NVARCHAR(20),
            cbu_cvu NVARCHAR(50),
            monto_texto NVARCHAR(50)
        );

        -- Importar desde CSV 
        DECLARE @SQL NVARCHAR(MAX);
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

        -- Procesar fila por fila
        DECLARE @fila INT, @id_pago INT, @fecha_texto NVARCHAR(20), @cbu_cvu NVARCHAR(50), @monto_texto NVARCHAR(50);
        DECLARE @DatosFila NVARCHAR(MAX);
        DECLARE @fecha_pago DATETIME, @monto NUMERIC(9,2), @cbu_cvu_limpio NVARCHAR(50);

        DECLARE cursor_pagos CURSOR FOR
        SELECT fila, id_pago, fecha_texto, cbu_cvu, monto_texto
        FROM #TempPagos;

        OPEN cursor_pagos;
        FETCH NEXT FROM cursor_pagos INTO @fila, @id_pago, @fecha_texto, @cbu_cvu, @monto_texto;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                SET @DatosFila = CONCAT('ID:', @id_pago, ' | Fecha:', @fecha_texto, ' | CBU/CVU:', @cbu_cvu, ' | Monto:', @monto_texto);

                SET @fecha_pago = TRY_CONVERT(DATETIME, @fecha_texto, 103);
                SET @monto = TRY_CONVERT(NUMERIC(9,2), REPLACE(REPLACE(REPLACE(@monto_texto, '$', ''), ' ', ''), ',', ''));
                SET @cbu_cvu_limpio = REPLACE(REPLACE(@cbu_cvu, ' ', ''), '-', '');

                -- Solo agregar si NO existe
                IF NOT EXISTS (SELECT 1 FROM Pago WHERE id_pago = @id_pago)
                BEGIN
                    INSERT INTO Pago (id_pago, fecha_pago, monto, cbu_cvu)
                    VALUES (@id_pago, @fecha_pago, @monto, @cbu_cvu_limpio);
                END
            END TRY
            BEGIN CATCH
                INSERT INTO #Log_Errores_Importacion (numero_fila, datos_fila, mensaje_error)
                VALUES (@fila + 1, @DatosFila, ERROR_MESSAGE());
            END CATCH

            FETCH NEXT FROM cursor_pagos INTO @fila, @id_pago, @fecha_texto, @cbu_cvu, @monto_texto;
        END

        CLOSE cursor_pagos;
        DEALLOCATE cursor_pagos;

        DROP TABLE #TempPagos;

        SELECT * FROM #Log_Errores_Importacion;
        
        DROP TABLE #Log_Errores_Importacion;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#Log_Errores_Importacion') IS NOT NULL
        BEGIN
            SELECT * FROM #Log_Errores_Importacion;
            DROP TABLE #Log_Errores_Importacion;
        END
    END CATCH
END;
GO

EXEC dbo.p_ImportarPagos @RutaArchivo = 'C:\consorcios\pagos_consorcios.csv';
