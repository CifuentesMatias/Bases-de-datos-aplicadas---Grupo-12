use Com2900G12
go

create or alter procedure Consorcios.sp_ImportarUnidadesFuncionales
    @RutaArchivo NVARCHAR(500)
as
begin
    begin try
        set nocount on;

        CREATE TABLE #tmpUnidadFuncional (
            nombre_consorcio VARCHAR(100) NOT NULL,
            nroUnidadFuncional INT NOT NULL,
            piso VARCHAR(10) NOT NULL,
            departamento VARCHAR(10) NOT NULL,
            coeficiente DECIMAL(5,2) NOT NULL,
            m2_unidad_funcional INT NOT NULL,
            bauleras VARCHAR(2) NOT NULL,
            cochera VARCHAR(2) NOT NULL,
            m2_baulera INT NOT NULL,
            m2_cochera INT NOT NULL
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 
        N'BULK INSERT #tmpUnidadFuncional
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            TABLOCK
        );';
        EXEC sp_executesql @SQL;

        
        INSERT INTO Consorcios.UnidadFuncional (
            nombre_consorcio, 
            nroUnidadFuncional, 
            piso, 
            departamento, 
            coeficiente, 
            m2_unidad_funcional, 
            bauleras, 
            cochera, 
            m2_baulera, 
            m2_cochera
        )
        SELECT 
            TRIM(nombre_consorcio) as nombre_consorcio,
            nroUnidadFuncional,
            TRIM(piso) as piso,
            TRIM(departamento) as departamento,
            coeficiente,
            m2_unidad_funcional,
            TRIM(bauleras) as bauleras,
            TRIM(cochera) as cochera,
            m2_baulera,
            m2_cochera
        FROM #tmpUnidadFuncional;
        
        DROP TABLE #tmpUnidadFuncional;
        
        PRINT 'Importación de Unidades Funcionales completada exitosamente';
        PRINT 'Registros importados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    end try
    begin catch
        PRINT 'Error en la importación de Unidades Funcionales';
        PRINT ERROR_MESSAGE();

        IF OBJECT_ID('tempdb..#tmpUnidadFuncional') IS NOT NULL
            DROP TABLE #tmpUnidadFuncional;
    end catch
end
go

EXEC Consorcios.sp_ImportarUnidadesFuncionales 
    @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\unidades_funcionales.csv';
go