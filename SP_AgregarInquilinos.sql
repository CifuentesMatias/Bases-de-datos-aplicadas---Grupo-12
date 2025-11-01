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

create or alter procedure sp_ImportarInquilinos
as
begin
	begin try
		set nocount on;

		create table #tmpPersona(
			id int identity(1,1) primary key,
			nombre varchar(50) not null,
			apellido varchar(50) not null,
			dni int check(dni like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
			email varchar(255) not null,
			telefono varchar(12) check(telefono like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
			cvu_cbu varchar(22) CHECK (LEN(cvu_cbu) = 22 AND cvu_cbu NOT LIKE '%[^0-9]%'),
			rol tinyint check(rol in (0,1)),
		);

		bulk insert #tmpPersona
		from 'C:\\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\Inquilino-propietarios-datos.csv'
		with (
			FIELDTERMINATOR = ';', 
			ROWTERMINATOR = '\r', 
			FIRSTROW = 2,
			CODEPAGE = '65001'  -- UTF-8, útil si hay acentos
		);


		-- insert into Persons.Persona(id, nombre, apellido, dni, email, telefono, cvu_cbu, rol)
		select id, nombre, apellido, dni, email, telefono, cvu_cbu, rol from #tmpPersona

		print 'Importación completada';
	end try
	begin catch
		print 'Error en la imporacion: ' + ERROR_MESSAGE();
	end catch
end
go

exec sp_ImportarInquilinos;
EXEC xp_fileexist 'C:\\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\Inquilino-propietarios-datos.csv';
SELECT @@VERSION;