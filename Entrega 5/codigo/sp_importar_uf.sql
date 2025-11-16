use database Com2900G12
go

CREATE PROCEDURE Importar_UF_Desde_Archivo
    @RutaArchivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#UF_RAW') IS NOT NULL
        DROP TABLE #UF_RAW;

    CREATE TABLE #UF_RAW (
        razon_social NVARCHAR(200),
        nroUnidadFuncional NVARCHAR(10),
        piso NVARCHAR(10),
        departamento NVARCHAR(10),
        coeficiente NVARCHAR(20),
        m2_unidad_funcional NVARCHAR(20),
        bauleras NVARCHAR(10),
        cochera NVARCHAR(10),
        m2_baulera NVARCHAR(20),
        m2_cochera NVARCHAR(20)
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = '
        BULK INSERT #UF_RAW
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001''
        );
    ';

    EXEC (@sql);
INSERT INTO UF (id_consorcio, id, m2, porcentaje, depto, piso)
SELECT 
    c.id,
    TRY_CAST(r.nroUnidadFuncional AS INT),
    TRY_CAST(REPLACE(r.m2_unidad_funcional, ',', '.') AS DECIMAL(10,2)),
    TRY_CAST(REPLACE(r.coeficiente, ',', '.') AS DECIMAL(10,2)),
    r.departamento,
    CASE 
        WHEN r.piso = 'PB' THEN 0
        ELSE TRY_CAST(r.piso AS INT)
    END
FROM #UF_RAW r
INNER JOIN Consorcio c
    ON c.razon_social = r.razon_social;

END;
GO


--Esto en el main
EXEC Importar_UF_Desde_Archivo
    @RutaArchivo = 'C:\Bases-de-datos-aplicadas---Grupo-12\UFporconsorcio.txt';


--select * from Consorcio;
--select * from UF