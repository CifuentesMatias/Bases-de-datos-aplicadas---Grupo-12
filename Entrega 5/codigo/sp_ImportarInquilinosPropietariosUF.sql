use Com2900G12
go

sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO
EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'AllowInProcess', 1;
    
EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'DynamicParameters', 1;
GO

create or alter procedure Consorcios.sp_ImportarInquilinosPropietariosUF
    @RutaArchivo NVARCHAR(500)
as
begin
    begin try
        set nocount on;

        CREATE TABLE #tmpInquilinoUF (
            cvu_cbu VARCHAR(30) NOT NULL,
            nombre_consorcio VARCHAR(100) NOT NULL,
            nroUnidadFuncional INT NOT NULL,
            piso VARCHAR(10) NOT NULL,
            departamento VARCHAR(10) NOT NULL
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 
        N'BULK INSERT #tmpInquilinoUF
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            TABLOCK
        );';
        EXEC sp_executesql @SQL;

        INSERT INTO Consorcios.InquilinoUnidadFuncional (cvu_cbu, nombre_consorcio, nroUnidadFuncional, piso, departamento)
        SELECT 
            TRIM(cvu_cbu) as cvu_cbu,
            TRIM(nombre_consorcio) as nombre_consorcio,
            nroUnidadFuncional,
            TRIM(piso) as piso,
            TRIM(departamento) as departamento
        FROM #tmpInquilinoUF;
        DROP TABLE #tmpInquilinoUF;
        PRINT 'Importación completada exitosamente';
    end try
    begin catch
        PRINT 'Error en la importación';
        PRINT ERROR_MESSAGE();

        IF OBJECT_ID('tempdb..#tmpInquilinoUF') IS NOT NULL
            DROP TABLE #tmpInquilinoUF;
    end catch
end
go

EXEC Consorcios.sp_ImportarInquilinosPropietariosUF 
    @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\Inquilino-propietarios-UF.csv';
go
