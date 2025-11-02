if db_id('Com2900G12') is null
	create database Com2900G12 collate Latin1_General_CI_AS;
go

use Com2900G12
go

/* CREACION DE SCHEMAS */
create schema Personas
authorization dbo;
go

create schema Pagos
authorization dbo; 
go

/* create schema Expensas;
go

create schema Edificio;
go

create schema Gastos;
go


*/

/* CREACION DE TABLAS */
create table Personas.Persona(
	id int identity(1,1),
	dni varchar(8) not null check(dni not like '%[^0-9]%'),
	nombre nvarchar(50) not null,
	apellido nvarchar(50) not null,
	email varchar(200) not null,
	cvu_cbu varchar(30) not null,
	telefono varchar(10) not null,
	rol bit not null,

	constraint pk_persona primary key(id),
	constraint fk_estado_persona foreign key (rol) references Personas.RolPersona(id_rolPersona),
	-- constraint uq_persona unique(dni),
	constraint chk_telefono_persona check(telefono like '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	constraint chk_cbu_persona check(cvu_cbu not like '%[^0-9]%')
);

select * from Personas.Persona;

alter table Personas.Persona
add constraint chk_rol_persona
check(rol in (0,1));

alter table Personas.Persona
drop constraint uq_persona;

alter table Personas.Persona
drop constraint chk_telefono_persona;

alter table Personas.Persona
add constraint uq_cvuCbuPersona unique(cvu_cbu);

create table Personas.RolPersona(
	id_rolPersona bit check(id_rolPersona in (0,1)),
	descripcion varchar(30) not null,

	constraint pk_idRolPersona primary key(id_rolPersona),
	constraint chk_RolPersona_Descripcion 
		check (descripcion IN ('Inquilino', 'Propietario'))
);

/* ALTER TABLE Persons.RolPersona
DROP CONSTRAINT PK__RolPerso__B3357100D1A49BF9; */

insert into Personas.RolPersona(id_rolPersona, descripcion) values
(0, 'Propietario'),
(1, 'Inquilino');

select * from Personas.RolPersona;

create table Pagos.Pago(
	id_pago int,
	fecha_pago date not null,
	cbu_cvu varchar(30) not null,
	monto decimal(10,3) not null

	constraint pk_idPago primary key(id_pago),
	constraint chk_cbu_persona check(cbu_cvu not like '%[^0-9]%'),
	constraint fk_cvuCbuPersona foreign key(cbu_cvu) references Personas.Persona(cvu_cbu)
);

/* 
create table Edificio.Consorcio(
	id_consorcio int identity(1,1),
	id_administrador int,
	razon_social varchar(100) not null,
	calle varchar(30) not null,
	numero_calle int not null,
	m2_edificio int not null,

	constraint pk_idConsorcio primary key(id_consorcio),
	constraint fk_idAdministrador_persona foreign key(id_administrador) references Personas.Persona(id),
);

create table Expensas.DetalleExpensa(
	id_detalle_expensa int identity(1,1),
	fecha date not null,
	hora time not null,
	nombre_compania varchar(30) not null,
	descripcion varchar(50) not null,
	subtotal decimal(10,2) not null

	constraint pk_idDetalleExpensa primary key(id_detalle_expensa) 
);

create table Expensas.Expensa(
	id_expensa int identity(1,1),
	id_consorcio int,
	id_detalle_expensa int,
	id_pagador int,
	importe_total int,

	constraint pk_idExpensa primary key(id_expensa),
	constraint fk_expensa_consorcio foreign key (id_consorcio) references Edificio.Consorcio(id_consorcio),
	constraint fk_detalle_expensa foreign key (id_detalle_expensa) references Expensas.DetalleExpensa(id_detalle_expensa),
	constraint fk_pagador_persona foreign key (id_pagador) references Personas.Persona(id)
);



create table Edificio.UnidadFuncional(
	id_uf int identity(1,1),
	idConsorcio int,
	idPersona int,
	idAdicionales int,
	departamento varchar(6) not null,
	piso int not null,
	m2 decimal(10,1) not null,

	constraint pk_idUnidadFuncional primary key(id_uf),
	constraint fk_idConsorcio foreign key (idConsorcio) references Edificio.Consorcio(id_consorcio),
	constraint fk_idPersona foreign key (idPersona) references Personas.Persona(id_persona),

	constraint chk_departamento_valido check(
		departamento NOT LIKE '%[0-9]%'
		OR
		departamento LIKE '[A-Z]'
		OR 
		departamento LIKE '[0-9][A-Z]'
		OR 
		departamento LIKE '[A-Z][0-9]'
	)
);

create table Edificio.Adicionales(
	id_adicional int identity(1,1),
	id_uf int,
	id_tipo int,
	m2 decimal(10,1) not null,

	constraint pk_idAdicional primary key(id_adicional),
	constraint fk_idUnidadFuncional foreign key(id_uf) references Edificio.UnidadFuncional(id_uf),
	constraint fk_idTipo foreign key(id_tipo) references Edificio.TipoAdicional(id_tipo_adicional),

);

create table Edificio.TipoAdicional(
	id_tipo_adicional int identity(1,1),
	descripcion varchar(30) not null,

	constraint pk_idTipoAdicional primary key(id_tipo_adicional)
);

/* create table Edificio.EstadoFinanciero(
	id_finanza int identity(1,1),
	id_consorcio int,
	saldo decimal(10,1),
	pagos_realizados, // Tengo dudas con este campo, no sé que tipo de dato es.
	pagos_adeudados, // Tengo dudas con este campo, no sé que tipo de dato es.
	pagos_adelantados, // Tengo dudas con este campo, no sé que tipo de dato es.
); */

create table Expensas.ReciboExpensa(
	id_recibo int identity(1,1),
	id_expensa int,
	id_consorcio int,
	id_uf int,
	concepto varchar(100) not null,
	monto_subtotal decimal(10,1) not null,
	monto_total decimal(10,1) not null,

	constraint pk_idRecibo primary key(id_recibo),
	constraint fk_idExpensa foreign key(id_expensa) references Expensas.Expensa(id_expensa),
	constraint fk_idConsorcio foreign key(id_consorcio) references Edificio.Consorcio(id_consorcio),
	constraint fk_idUnidadFuncional foreign key(id_uf) references Edificio.UnidadFuncional(id_uf),
);

create table Gastos.GastosOrdinarios(
	id_gasto_ord int identity(1,1),
	id_expensa int,
	nombre_prestador varchar(50) not null,
	importe decimal(10,1) not null

	constraint pk_idGastoOrd primary key(id_gasto_ord),
	constraint fk_idExpensa foreign key(id_expensa) references Expensas.Expensa(id_expensa)
);

create table Gastos.GastosExtraordinarios(
	id_gasto_ext int identity(1,1),
	id_expensa int,
	mes_declarado date not null,
	descripcion varchar(50) not null,
	importe decimal(10,1) not null,
	cuota_paga int,
	cant_cuotas int not null,

	constraint pk_idGastoExt primary key(id_gasto_ext),
	constraint fk_idExpensa foreign key(id_expensa) references Expensas.Expensa(id_expensa)
);
*/