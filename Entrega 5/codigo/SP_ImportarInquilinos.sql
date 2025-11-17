if db_id('Com2900G12') is null
	create database Com2900G12 collate Latin1_General_CI_AS;
go

use Com2900G12
go

--------------------------------------------------------

-------- IMPORTACION DE PERSONAS (inquilino-propietarios-datos.csv) --------
create or alter procedure SP_ImportarInquilinos
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

exec SP_ImportarInquilinos @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\Inquilino-propietarios-datos.csv';