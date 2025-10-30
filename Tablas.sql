CREATE DATABASE Com2900G12;
go;

USE Com2900G12;
go;

/* CREACION DE TABLAS */
create table Persona(
	id int identity(1,1),
	dni int not null,
	nombre nvarchar(30) not null,
	apellido nvarchar(50) not null,
	email varchar(255) not null,
	telefono char(12) not null,
	rol int not null,

	constraint pk_persona primary key(id),
	constraint fk_estado_persona foreign key (rol) references RolPersona(id_rolPersona),
	constraint uq_persona unique(dni),
	constraint ck_telefono_persona check(telefono like '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

create table RolPersona(
	id_rolPersona int identity(1,1) primary key,
	descripcion varchar(30)
);

create table Consorcio(
	id_consorcio int identity(1,1),
	id_administrador int,
	razon_social varchar(100) not null,
	calle varchar(30) not null,
	numero_calle int not null,
	m2_edificio int not null,

	constraint pk_idConsorcio primary key(id_consorcio),
	constraint fk_idAdministrador_persona foreign key(id_administrador) references Persona(id),
);

create table DetalleExpensa(
	id_detalle_expensa int identity(1,1),
	fecha date not null,
	hora time not null,
	nombre_compania varchar(30) not null,
	descripcion varchar(50) not null,
	subtotal decimal(4,2) not null

	constraint pk_idDetalleExpensa primary key(id_detalle_expensa) 
);

create table Expensa(
	id_expensa int identity(1,1),
	id_consorcio int,
	id_detalle_expensa int,
	id_pagador int,
	importe_total int,

	constraint pk_idExpensa primary key(id_expensa),
	constraint fk_expensa_consorcio foreign key (id_consorcio) references Consorcio(id_consorcio),
	constraint fk_detalle_expensa foreign key (id_detalle_expensa) references DetalleExpensa(id_detalle_expensa),
	constraint fk_pagador_persona foreign key (id_pagador) references Persona(id)
);