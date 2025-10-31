USE Com5600_G12
GO

CREATE OR ALTER PROCEDURE dbo.Importar_Consorcios
    @RutaArchivo NVARCHAR(255),
    @NombreHoja NVARCHAR(128)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        CREATE TABLE #TempConsorcios (
            Nombre NVARCHAR(100),
            Direccion NVARCHAR(150),
            Email NVARCHAR(100)
        );

        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
            INSERT INTO #TempConsorcios
            SELECT [Nombre], [Direccion], [Email]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.16.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [' + @NombreHoja + ']'' 
            );';
        EXEC sp_executesql @SQL;

        INSERT INTO dbo.Consorcio (Nombre, Direccion, Email)
        SELECT t.Nombre, t.Direccion, t.Email
        FROM #TempConsorcios t
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Consorcio c 
            WHERE c.Nombre COLLATE Latin1_General_CI_AS = t.Nombre COLLATE Latin1_General_CI_AS
        );

        DECLARE @Inserted INT = @@ROWCOUNT;
        INSERT INTO dbo.BitacoraImportacion (NombreSP, Archivo, RegistrosInsertados)
        VALUES ('Importar_Consorcios', @RutaArchivo, @Inserted);

        DROP TABLE #TempConsorcios;
        PRINT 'Importación de consorcios completada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Payment.Importar_Pagos
    @RutaArchivo NVARCHAR(255),
    @NombreHoja NVARCHAR(128)
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        CREATE TABLE #TempPagos (
            Fecha DATE,
            CBU VARCHAR(30),
            Importe DECIMAL(18,2)
        );

        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
            INSERT INTO #TempPagos
            SELECT TRY_CONVERT(DATE, [Fecha], 103), [Cuenta Origen], [Importe]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.16.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [' + @NombreHoja + ']'' 
            );';
        EXEC sp_executesql @SQL;

        INSERT INTO Payment.Pago (Fecha_Pago, CBU_Origen, Importe)
        SELECT t.Fecha, t.CBU, t.Importe
        FROM #TempPagos t
        WHERE NOT EXISTS (
            SELECT 1 FROM Payment.Pago p
            WHERE p.Fecha_Pago = t.Fecha
              AND p.CBU_Origen = t.CBU
              AND p.Importe = t.Importe
        );

        DROP TABLE #TempPagos;
        PRINT 'Importación de pagos completada.';
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación de pagos: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
