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


-------- IMPORTACION DE PERSONAS (inquilino-propietarios-datos.csv) --------
create or alter procedure Personas.sp_ImportarInquilinos
	@RutaArchivo NVARCHAR(500)
as
begin
	begin try
		set nocount on;

		CREATE TABLE #tmpPersona (
			nombre varchar(50) not null,
			apellido varchar(50) not null,
			dni varchar(8) not null check(dni not like '%[^0-9]%'),
			email varchar(200) not null,
			telefono varchar(10) not null check(telefono like '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
			cvu_cbu varchar(30) not null check(cvu_cbu not like '%[^0-9]%'), 
			rol bit not null
		);


		-- Cargar archivo CSV usando BULK INSERT dinámico
		DECLARE @SQL NVARCHAR(MAX);

		SET @SQL = 
		N'BULK INSERT #tmpPersona
		FROM '''+@RutaArchivo+'''
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = '';'',
			ROWTERMINATOR = ''\n'',
			TABLOCK
		);';

		EXEC sp_executesql @SQL;


		insert into Personas.Persona(nombre, apellido, dni, email, telefono, cvu_cbu, rol)
		select LOWER(TRIM(nombre)) as nombre, LOWER(TRIM(apellido)) as apellido, dni, LOWER(TRIM(email)) as email, telefono, cvu_cbu, rol from #tmpPersona

		print 'Importación completada';

        -- Limpiar tablas temporales
        DROP TABLE #tmpPersona;
	end try
	begin catch
		print 'Error en la imporacion';
		PRINT ERROR_MESSAGE();
	end catch
end
go

exec Personas.sp_ImportarInquilinos @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\Inquilino-propietarios-datos.csv';