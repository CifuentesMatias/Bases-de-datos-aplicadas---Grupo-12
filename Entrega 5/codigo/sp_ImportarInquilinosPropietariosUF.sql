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

create or alter procedure sp_ImportarInquilinosPropietariosUF
    @RutaArchivo NVARCHAR(500)
as
begin
    begin try
        set nocount on;

        CREATE TABLE #tmpInquilinoUF (
            cvu_cbu VARCHAR(30) NOT NULL,
            nombre_consorcio VARCHAR(100) NOT NULL,
            nroUnidadFuncional varchar(10) NOT NULL,
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

        INSERT INTO Persona_UF (cvu_cbu, id_consorcio, id_uf)
        SELECT 
            TRIM(t.cvu_cbu),
            c.id,
            u.id
        FROM #tmpInquilinoUF t
        JOIN Consorcio c ON TRIM(t.nombre_consorcio) = c.razon_social
        JOIN UF u ON TRIM(t.nroUnidadFuncional) = CAST(u.id AS VARCHAR(10)) 
                    AND c.id = u.id_consorcio
                    AND (CASE WHEN TRIM(t.piso) = 'PB' THEN 0 ELSE CAST(TRIM(t.piso) AS INT) END) = u.piso
                    AND TRIM(t.departamento) = u.depto
        WHERE NOT EXISTS (
            SELECT 1 FROM Persona_UF pu
            WHERE pu.cvu_cbu = TRIM(t.cvu_cbu) AND pu.id_consorcio = c.id AND pu.id_uf = u.id
        )

        DROP TABLE #tmpInquilinoUF;
    end try
    begin catch
        PRINT 'Error en la importación';
        PRINT ERROR_MESSAGE();

        IF OBJECT_ID('tempdb..#tmpInquilinoUF') IS NOT NULL
            DROP TABLE #tmpInquilinoUF;
    end catch
end
go

EXEC sp_ImportarInquilinosPropietariosUF 
    @RutaArchivo = 'C:\Users\botta\Documents\GitHub\BaseDatosAplicadaGrupo12\Bases-de-datos-aplicadas---Grupo-12\Entrega 5\Archivos_para_importar\Inquilino-propietarios-UF.csv';
go


Select * from Persona_UF