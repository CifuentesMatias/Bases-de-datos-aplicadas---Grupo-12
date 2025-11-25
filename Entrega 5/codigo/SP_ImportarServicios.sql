USE Com2900G12;
GO

-- Configuración inicial
SP_CONFIGURE 'show advanced options', 1;
RECONFIGURE;
GO
SP_CONFIGURE 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

IF OBJECT_ID('dbo.NormalizarNumeroInteligente', 'FN') IS NOT NULL
    DROP FUNCTION dbo.NormalizarNumeroInteligente;
GO

CREATE FUNCTION dbo.NormalizarNumeroInteligente(@valor VARCHAR(50))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @valorLimpio VARCHAR(50)
    DECLARE @posicion INT
    DECLARE @digitosDespues INT
    DECLARE @caracter CHAR(1)
    DECLARE @resultado DECIMAL(18,2)
    DECLARE @i INT

    IF @valor IS NULL OR TRIM(@valor) = ''
        RETURN NULL

    SET @valorLimpio = TRIM(@valor)
    SET @i = 1
    
    WHILE @i <= LEN(@valorLimpio)
    BEGIN
        SET @caracter = SUBSTRING(@valorLimpio, @i, 1)

        IF @caracter IN (',', '.')
        BEGIN
            SET @digitosDespues = 0
            SET @posicion = @i + 1
            
            WHILE @posicion <= LEN(@valorLimpio)
            BEGIN
                SET @digitosDespues = @digitosDespues + 1
                SET @posicion = @posicion + 1
            END
            
            IF @digitosDespues = 2
            BEGIN
                SET @valorLimpio = STUFF(@valorLimpio, @i, 1, '.')
            END
            ELSE
            BEGIN
                SET @valorLimpio = STUFF(@valorLimpio, @i, 1, '')
                SET @i = @i - 1
            END
        END
        
        SET @i = @i + 1
    END

    SET @resultado = CAST(@valorLimpio AS DECIMAL(18,2))
    
    RETURN @resultado
END
GO

CREATE OR ALTER PROCEDURE SP_ImportarServicios
    @json NVARCHAR(MAX),               
    @anio INT = 2025
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#TempServicios') IS NOT NULL DROP TABLE #TempServicios;
        IF OBJECT_ID('tempdb..#ProveedoresNecesarios') IS NOT NULL DROP TABLE #ProveedoresNecesarios;

        CREATE TABLE #TempServicios (
            RowNum INT IDENTITY(1,1),
            NombreConsorcio NVARCHAR(100),
            Mes NVARCHAR(20),
            MesNumero INT,
            Anio INT,
            Bancarios DECIMAL(18,2),
            Limpieza DECIMAL(18,2),
            Administracion DECIMAL(18,2),
            Seguros DECIMAL(18,2),
            GastosGenerales DECIMAL(18,2),
            ServiciosAgua DECIMAL(18,2),
            ServiciosLuz DECIMAL(18,2),
            IdConsorcio INT,
            IdExpensa INT
        );

        INSERT INTO #TempServicios (NombreConsorcio, Mes, Anio, Bancarios, Limpieza, Administracion, Seguros, GastosGenerales, ServiciosAgua, ServiciosLuz)
        SELECT 
            JSON_VALUE(value, '$."Nombre del consorcio"') COLLATE Modern_Spanish_CI_AS,
            RTRIM(JSON_VALUE(value, '$.Mes')),
            @anio,
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$.BANCARIOS')),
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$.LIMPIEZA')),
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$.ADMINISTRACION')),
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$.SEGUROS')),
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$."GASTOS GENERALES"')),
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$."SERVICIOS PUBLICOS-Agua"')),
            dbo.NormalizarNumeroInteligente(JSON_VALUE(value, '$."SERVICIOS PUBLICOS-Luz"'))
        FROM OPENJSON(@json)
        WHERE JSON_VALUE(value, '$."Nombre del consorcio"') IS NOT NULL;

        UPDATE #TempServicios
        SET MesNumero = CASE LOWER(RTRIM(Mes))
            WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
            WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
            WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9
            WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
        END;

        UPDATE t
        SET t.IdConsorcio = c.id
        FROM #TempServicios t
        INNER JOIN Consorcio c ON c.razon_social LIKE '%' + t.NombreConsorcio + '%';

        CREATE TABLE #ProveedoresNecesarios (
            IdConsorcio INT,
            TipoProveedor NVARCHAR(50),
            IdProveedor INT
        );

        INSERT INTO #ProveedoresNecesarios (IdConsorcio, TipoProveedor)
        SELECT DISTINCT IdConsorcio, 'GASTOS BANCARIOS' FROM #TempServicios WHERE Bancarios > 0 AND IdConsorcio IS NOT NULL
        UNION
        SELECT DISTINCT IdConsorcio, 'GASTOS DE LIMPIEZA' FROM #TempServicios WHERE Limpieza > 0 AND IdConsorcio IS NOT NULL
        UNION
        SELECT DISTINCT IdConsorcio, 'GASTOS DE ADMINISTRACION' FROM #TempServicios WHERE Administracion > 0 AND IdConsorcio IS NOT NULL
        UNION
        SELECT DISTINCT IdConsorcio, 'SEGUROS' FROM #TempServicios WHERE Seguros > 0 AND IdConsorcio IS NOT NULL
        UNION
        SELECT DISTINCT IdConsorcio, 'SERVICIOS PUBLICOS - Luz' FROM #TempServicios WHERE ServiciosLuz > 0 AND IdConsorcio IS NOT NULL
        UNION
        SELECT DISTINCT IdConsorcio, 'SERVICIOS PUBLICOS - Agua' FROM #TempServicios WHERE ServiciosAgua > 0 AND IdConsorcio IS NOT NULL
        UNION
        SELECT DISTINCT IdConsorcio, 'GASTOS GENERALES' FROM #TempServicios WHERE GastosGenerales > 0 AND IdConsorcio IS NOT NULL;
      
        UPDATE pn
        SET pn.IdProveedor = pc.id_proveedor
        FROM #ProveedoresNecesarios pn
        JOIN Tipo_Servicio s on s.descripcion = pn.TipoProveedor
        JOIN Proveedor p on s.id = p.id_tipo_servicio
        JOIN Proveedor_Consorcio pc ON pc.id_proveedor = p.id and pn.idConsorcio = pc.id_consorcio
        WHERE pn.IdProveedor IS NULL;

        Insert into Expensa (id_consorcio, anio, mes)
        Select t.idConsorcio, t.Anio, t.MesNumero
        From #TempServicios t WHERE t.IdConsorcio IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM Expensa e WHERE e.id_consorcio = t.IdConsorcio AND e.anio = t.Anio AND e.mes = t.MesNumero);

        UPDATE t
        SET t.IdExpensa = e.id
        FROM #TempServicios t
        INNER JOIN Expensa e ON e.id_consorcio = t.IdConsorcio AND e.anio = t.Anio AND e.mes = t.MesNumero
        WHERE t.IdConsorcio IS NOT NULL;


        WITH NuevosDetalles AS (   
            -- 1. BANCARIOS
            SELECT t.IdExpensa, t.Bancarios AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'GASTOS BANCARIOS'
            WHERE t.IdExpensa IS NOT NULL AND t.Bancarios > 0 AND pn.IdProveedor IS NOT NULL
            UNION ALL
            -- 2. LIMPIEZA
            SELECT t.IdExpensa, t.Limpieza AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'GASTOS DE LIMPIEZA'
            WHERE t.IdExpensa IS NOT NULL AND t.Limpieza > 0 AND pn.IdProveedor IS NOT NULL
            UNION ALL
            -- 3. ADMINISTRACION
            SELECT t.IdExpensa, t.Administracion AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'GASTOS DE ADMINISTRACION'
            WHERE t.IdExpensa IS NOT NULL AND t.Administracion > 0 AND pn.IdProveedor IS NOT NULL
            UNION ALL
            -- 4. SEGUROS
            SELECT t.IdExpensa, t.Seguros AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'SEGUROS'
            WHERE t.IdExpensa IS NOT NULL AND t.Seguros > 0 AND pn.IdProveedor IS NOT NULL
            UNION ALL
            -- 5. LUZ
            SELECT t.IdExpensa, t.ServiciosLuz AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'SERVICIOS PUBLICOS - Luz'
            WHERE t.IdExpensa IS NOT NULL AND t.ServiciosLuz > 0 AND pn.IdProveedor IS NOT NULL
            UNION ALL
            -- 6. AGUA
            SELECT t.IdExpensa, t.ServiciosAgua AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'SERVICIOS PUBLICOS - Agua'
            WHERE t.IdExpensa IS NOT NULL AND t.ServiciosAgua > 0 AND pn.IdProveedor IS NOT NULL
            UNION ALL
            -- 7. GASTOS GENERALES
            SELECT t.IdExpensa, t.GastosGenerales AS Importe, pn.IdProveedor,
                DATEADD(day, 
                    FLOOR(RAND(CHECKSUM(NEWID())) * (DAY(EOMONTH(DATEFROMPARTS(t.Anio, t.MesNumero, 1))) - 1)),
                    DATEFROMPARTS(t.Anio, t.MesNumero, 1)
                ) AS FechaFactura FROM #TempServicios t 
            JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'GASTOS GENERALES'
            WHERE t.IdExpensa IS NOT NULL AND t.GastosGenerales > 0 AND pn.IdProveedor IS NOT NULL
        )
        -- Inserción final en Detalle_Expensa
        INSERT INTO Detalle_Expensa (id_expensa, importe, id_proveedor, fecha_factura)
        SELECT 
            nd.IdExpensa, 
            nd.Importe, 
            nd.IdProveedor, 
            nd.FechaFactura
        FROM NuevosDetalles nd
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Detalle_Expensa de
            WHERE de.id_expensa = nd.IdExpensa
              AND de.id_proveedor = nd.IdProveedor
              AND de.importe = nd.Importe
        );
        
        -- 9. Generar Gasto_Ordinario
        INSERT INTO Gasto_Ordinario (id_gasto, nro_factura)
        SELECT de.id_det_exp, 'FC-' + FORMAT(de.id_det_exp, '0000') + '-' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR(10))
        FROM Detalle_Expensa de
        WHERE de.id_expensa IN (SELECT IdExpensa FROM #TempServicios WHERE IdExpensa IS NOT NULL)
          AND NOT EXISTS (SELECT 1 FROM Gasto_Ordinario g WHERE g.id_gasto = de.id_det_exp);


          drop TABLE #ProveedoresNecesarios;
          DROP TABLE #TempServicios;

        COMMIT TRANSACTION;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'ERROR EN LA IMPORTACIÓN: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

DECLARE @jsonData NVARCHAR(MAX);

SELECT @jsonData = BulkColumn

FROM OPENROWSET(BULK 'C:\Users\botta\Documents\GitHub\BaseDatosAplicadaGrupo12\Bases-de-datos-aplicadas---Grupo-12\Entrega 5\Archivos_para_importar\Servicios.Servicios.json', SINGLE_CLOB) AS j;


EXEC SP_ImportarServicios 
    @json = @jsonData,
    @anio = 2025;
GO


SELECT * FROM Detalle_Expensa

SELECT * FROM Gasto_Ordinario
SELECT * FROM Expensa