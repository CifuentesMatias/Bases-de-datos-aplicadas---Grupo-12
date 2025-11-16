IF OBJECT_ID('sp_cargar_datos_prueba', 'P') IS NOT NULL
    DROP PROCEDURE sp_cargar_datos_prueba;
GO

CREATE PROCEDURE sp_cargar_datos_prueba
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        DELETE FROM Pago;
        DELETE FROM Gasto_Extraordinario;
        DELETE FROM Gasto_Ordinario;
        DELETE FROM Detalle_Expensa;
        DELETE FROM Expensa;
        DELETE FROM Persona_UF;
        DELETE FROM Adicionales;
        DELETE FROM UF;
        DELETE FROM Consorcio;
        DELETE FROM Persona;
        DELETE FROM Proveedor;
        DELETE FROM Tipo_Servicio;
        DELETE FROM Tipo_Gasto;
        DELETE FROM Tipo_adicional;
        DELETE FROM Tipo_relacion;

        INSERT INTO Tipo_relacion (id, descripcion) VALUES
        (0, 'Propietario'),
        (1, 'Inquilino');
        PRINT '✓ Tipo_relacion cargado';

        SET IDENTITY_INSERT Tipo_adicional ON;
        INSERT INTO Tipo_adicional (id, descripcion) VALUES
        (1, 'Cochera'),
        (2, 'Baulera');
        SET IDENTITY_INSERT Tipo_adicional OFF;

        SET IDENTITY_INSERT Tipo_Gasto ON;
        INSERT INTO Tipo_Gasto (id, descripcion) VALUES
        (1, 'Gastos Generales'),
        (2, 'Servicios Públicos'),
        (3, 'Seguridad'),
        (4, 'Limpieza'),
        (5, 'Reparaciones y Construcción'),
        (6, 'Gastos Bancarios'),
        (7, 'Honorarios Administrativos'),
        (8, 'Seguros');
        SET IDENTITY_INSERT Tipo_Gasto OFF;

        SET IDENTITY_INSERT Tipo_Servicio ON;
        INSERT INTO Tipo_Servicio (id, descripcion, id_tipo_gasto) VALUES
        (1, 'Mantenimiento General', 1),
        (2, 'Servicios Luz/Agua/Internet', 2),
        (3, 'Vigilancia', 3),
        (4, 'Limpieza Común', 4),
        (5, 'Obras y Refacciones', 5),
        (6, 'Mantenimiento Cuenta Bancaria', 6),
        (7, 'Administración', 7),
        (8, 'Seguro Consorcio', 8);
        SET IDENTITY_INSERT Tipo_Servicio OFF;
        
        SET IDENTITY_INSERT Proveedor ON;
        INSERT INTO Proveedor (id, razon_social) VALUES
        (1, 'Limpieza Total S.A.'),
        (2, 'Seguridad 24/7 S.R.L.'),
        (3, 'Administración Altos de Saint Just'),
        (4, 'Seguros La Protectora S.A.'),
        (5, 'EDESUR - Electricidad'),
        (6, 'AYSA - Agua y Saneamiento'),
        (7, 'Telecom Argentina S.A.'),
        (8, 'Fumigaciones Express'),
        (9, 'Jardines y Parques S.A.'),
        (10, 'Constructora San Martín'),
        (11, 'Banco Galicia'),
        (12, 'Pinturería El Maestro'),
        (13, 'Plomería Rápida'),
        (14, 'Extintores y Seguridad'),
        (15, 'Cerrajería 24hs');
        SET IDENTITY_INSERT Proveedor OFF;
        
        SET IDENTITY_INSERT Persona ON;
        INSERT INTO Persona (id, dni, nombre, apellido, email, telefono, cbu_cvu) VALUES
        -- Consorcio 1
        (1, 20345678, 'Juan', 'Pérez', 'jperez@email.com', '011-45678901', '0000003100012345678901'),
        (2, 30456789, 'María', 'González', 'mgonzalez@email.com', '011-45678902', '0000003100012345678902'),
        (3, 25567890, 'Carlos', 'Rodríguez', 'crodriguez@email.com', '011-45678903', '0000003100012345678903'),
        (4, 28678901, 'Ana', 'Martínez', 'amartinez@email.com', '011-45678904', '0000003100012345678904'),
        (5, 32789012, 'Luis', 'López', 'llopez@email.com', '011-45678905', '0000003100012345678905'),
        (6, 27890123, 'Laura', 'Fernández', 'lfernandez@email.com', '011-45678906', '0000003100012345678906'),
        (7, 31901234, 'Diego', 'Sánchez', 'dsanchez@email.com', '011-45678907', '0000003100012345678907'),
        (8, 29012345, 'Sofía', 'Romero', 'sromero@email.com', '011-45678908', '0000003100012345678908'),
        (9, 33123456, 'Pablo', 'Torres', 'ptorres@email.com', '011-45678909', '0000003100012345678909'),
        (10, 26234567, 'Claudia', 'Benítez', 'cbenitez@email.com', '011-45678910', '0000003100012345678910'),
        (11, 34345678, 'Martín', 'Castro', 'mcastro@email.com', '011-45678911', '0000003100012345678911'),
        (12, 28456789, 'Valeria', 'Ruiz', 'vruiz@email.com', '011-45678912', '0000003100012345678912'),
        -- Consorcio 2
        (13, 22567890, 'Roberto', 'Silva', 'rsilva@email.com', '011-45678913', '0000003100012345678913'),
        (14, 35678901, 'Gabriela', 'Moreno', 'gmoreno@email.com', '011-45678914', '0000003100012345678914'),
        (15, 29789012, 'Fernando', 'Ramos', 'framos@email.com', '011-45678915', '0000003100012345678915'),
        (16, 31890123, 'Patricia', 'Álvarez', 'palvarez@email.com', '011-45678916', '0000003100012345678916'),
        (17, 27901234, 'Gustavo', 'Méndez', 'gmendez@email.com', '011-45678917', '0000003100012345678917'),
        (18, 33012345, 'Mónica', 'Ríos', 'mrios@email.com', '011-45678918', '0000003100012345678918'),
        (19, 26123456, 'Alejandro', 'Ortiz', 'aortiz@email.com', '011-45678919', '0000003100012345678919'),
        (20, 34234567, 'Cecilia', 'Navarro', 'cnavarro@email.com', '011-45678920', '0000003100012345678920'),
        (21, 28345678, 'Ricardo', 'Paz', 'rpaz@email.com', '011-45678921', '0000003100012345678921'),
        (22, 32456789, 'Silvia', 'Vega', 'svega@email.com', '011-45678922', '0000003100012345678922'),
        (23, 25567890, 'Marcelo', 'Luna', 'mluna@email.com', '011-45678923', '0000003100012345678923'),
        (24, 30678901, 'Andrea', 'Cruz', 'acruz@email.com', '011-45678924', '0000003100012345678924'),
        -- Consorcio 3
        (25, 29789012, 'Jorge', 'Herrera', 'jherrera@email.com', '011-45678925', '0000003100012345678925'),
        (26, 31890123, 'Liliana', 'Campos', 'lcampos@email.com', '011-45678926', '0000003100012345678926'),
        (27, 27901234, 'Sergio', 'Rojas', 'srojas@email.com', '011-45678927', '0000003100012345678927'),
        (28, 33012345, 'Beatriz', 'Molina', 'bmolina@email.com', '011-45678928', '0000003100012345678928'),
        (29, 26123456, 'Raúl', 'Peralta', 'rperalta@email.com', '011-45678929', '0000003100012345678929'),
        (30, 34234567, 'Marina', 'Cabrera', 'mcabrera@email.com', '011-45678930', '0000003100012345678930'),
        (31, 28345678, 'Eduardo', 'Suárez', 'esuarez@email.com', '011-45678931', '0000003100012345678931'),
        (32, 32456789, 'Daniela', 'Medina', 'dmedina@email.com', '011-45678932', '0000003100012345678932'),
        (33, 25567890, 'Héctor', 'Guzmán', 'hguzman@email.com', '011-45678933', '0000003100012345678933'),
        (34, 30678901, 'Isabel', 'Acosta', 'iacosta@email.com', '011-45678934', '0000003100012345678934'),
        (35, 29789012, 'Nicolás', 'Sosa', 'nsosa@email.com', '011-45678935', '0000003100012345678935'),
        (36, 31890123, 'Verónica', 'Palacios', 'vpalacios@email.com', '011-45678936', '0000003100012345678936'),
        -- Consorcio 4
        (37, 27901234, 'Adrián', 'Arias', 'aarias@email.com', '011-45678937', '0000003100012345678937'),
        (38, 33012345, 'Natalia', 'Miranda', 'nmiranda@email.com', '011-45678938', '0000003100012345678938'),
        (39, 26123456, 'Oscar', 'Vargas', 'ovargas@email.com', '011-45678939', '0000003100012345678939'),
        (40, 34234567, 'Carolina', 'Sandoval', 'csandoval@email.com', '011-45678940', '0000003100012345678940'),
        (41, 28345678, 'Federico', 'Espinoza', 'fespinoza@email.com', '011-45678941', '0000003100012345678941'),
        (42, 32456789, 'Paola', 'Cortés', 'pcortes@email.com', '011-45678942', '0000003100012345678942'),
        (43, 25567890, 'Javier', 'Ibáñez', 'jibanez@email.com', '011-45678943', '0000003100012345678943'),
        (44, 30678901, 'Florencia', 'Paredes', 'fparedes@email.com', '011-45678944', '0000003100012345678944'),
        (45, 29789012, 'Damián', 'Aguilar', 'daguilar@email.com', '011-45678945', '0000003100012345678945'),
        (46, 31890123, 'Lucía', 'Mendoza', 'lmendoza@email.com', '011-45678946', '0000003100012345678946'),
        (47, 27901234, 'Emilio', 'Bravo', 'ebravo@email.com', '011-45678947', '0000003100012345678947'),
        (48, 33012345, 'Romina', 'Duarte', 'rduarte@email.com', '011-45678948', '0000003100012345678948');
        SET IDENTITY_INSERT Persona OFF;
        
        SET IDENTITY_INSERT Consorcio ON;
        INSERT INTO Consorcio (id, razon_social, domicilio, m2, email) VALUES
        (1, 'Consorcio Edificio Las Rosas', 'Av. Rivadavia 1234, San Justo, Buenos Aires', 1200.00, 'admin.lasrosas@consorcio.com'),
        (2, 'Consorcio Torres del Sur', 'Calle Italia 5678, San Justo, Buenos Aires', 980.50, 'admin.torresdelsur@consorcio.com'),
        (3, 'Consorcio Jardines de Abril', 'Av. San Martín 9012, San Justo, Buenos Aires', 1500.75, 'admin.jardinesabril@consorcio.com'),
        (4, 'Consorcio Plaza Mayor', 'Calle España 3456, San Justo, Buenos Aires', 1100.00, 'admin.plazamayor@consorcio.com');
        SET IDENTITY_INSERT Consorcio OFF;
        
        INSERT INTO UF (id_consorcio, id, m2, porcentaje, depto, piso) VALUES
        (1, 1, 85.50, 7.13, 1, 0), (1, 2, 92.00, 7.67, 2, 0), (1, 3, 78.25, 6.52, 3, 0),
        (1, 4, 88.00, 7.33, 1, 1), (1, 5, 88.00, 7.33, 2, 1), (1, 6, 95.50, 7.96, 3, 1),
        (1, 7, 105.00, 8.75, 1, 2), (1, 8, 98.75, 8.23, 2, 2), (1, 9, 110.00, 9.17, 3, 2),
        (1, 10, 125.50, 10.46, 1, 3), (1, 11, 118.00, 9.83, 2, 3), (1, 12, 115.50, 9.63, 3, 3);

        INSERT INTO UF (id_consorcio, id, m2, porcentaje, depto, piso) VALUES
        (2, 1, 65.00, 6.63, 1, 0), (2, 2, 68.50, 6.98, 2, 0), (2, 3, 72.00, 7.34, 1, 1),
        (2, 4, 70.25, 7.16, 2, 1), (2, 5, 75.00, 7.65, 3, 1), (2, 6, 82.50, 8.41, 1, 2),
        (2, 7, 85.00, 8.67, 2, 2), (2, 8, 88.75, 9.05, 3, 2), (2, 9, 95.00, 9.69, 1, 3),
        (2, 10, 92.50, 9.43, 2, 3), (2, 11, 98.00, 9.99, 3, 3), (2, 12, 87.50, 8.92, 4, 3);

        INSERT INTO UF (id_consorcio, id, m2, porcentaje, depto, piso) VALUES
        (3, 1, 120.00, 8.00, 1, 0), (3, 2, 115.50, 7.70, 2, 0), (3, 3, 125.00, 8.33, 3, 0),
        (3, 4, 130.00, 8.67, 1, 1), (3, 5, 128.75, 8.58, 2, 1), (3, 6, 122.50, 8.17, 3, 1),
        (3, 7, 135.00, 9.00, 1, 2), (3, 8, 140.25, 9.35, 2, 2), (3, 9, 132.00, 8.80, 3, 2),
        (3, 10, 145.50, 9.70, 1, 3), (3, 11, 138.00, 9.20, 2, 3), (3, 12, 148.50, 9.90, 3, 3);

        INSERT INTO UF (id_consorcio, id, m2, porcentaje, depto, piso) VALUES
        (4, 1, 75.00, 6.82, 1, 0), (4, 2, 78.50, 7.14, 2, 0), (4, 3, 82.00, 7.45, 3, 0),
        (4, 4, 85.25, 7.75, 1, 1), (4, 5, 88.00, 8.00, 2, 1), (4, 6, 91.50, 8.32, 3, 1),
        (4, 7, 95.00, 8.64, 1, 2), (4, 8, 98.75, 8.98, 2, 2), (4, 9, 102.00, 9.27, 3, 2),
        (4, 10, 105.50, 9.59, 1, 3), (4, 11, 108.00, 9.82, 2, 3), (4, 12, 110.50, 10.05, 3, 3);
        
        INSERT INTO Adicionales (id_consorcio, id_uf, m2, porcentaje, id_tipo_adicional) VALUES
        (1, 1, 12.50, 1.04, 1), (1, 2, 12.50, 1.04, 1), (1, 4, 12.50, 1.04, 1),
        (1, 5, 12.50, 1.04, 1), (1, 7, 15.00, 1.25, 1), (1, 8, 15.00, 1.25, 1), (1, 10, 15.00, 1.25, 1),
        (1, 3, 4.50, 0.38, 2), (1, 6, 4.50, 0.38, 2), (1, 9, 5.00, 0.42, 2),
        (1, 11, 5.00, 0.42, 2), (1, 12, 5.00, 0.42, 2);

        INSERT INTO Adicionales (id_consorcio, id_uf, m2, porcentaje, id_tipo_adicional) VALUES
        (3, 1, 6.00, 0.40, 2), (3, 2, 6.00, 0.40, 2), (3, 4, 6.00, 0.40, 2),
        (3, 5, 6.50, 0.43, 2), (3, 7, 6.50, 0.43, 2), (3, 9, 7.00, 0.47, 2), (3, 10, 7.00, 0.47, 2);

        INSERT INTO Adicionales (id_consorcio, id_uf, m2, porcentaje, id_tipo_adicional) VALUES
        (4, 1, 13.00, 1.18, 1), (4, 2, 13.00, 1.18, 1), (4, 3, 13.00, 1.18, 1),
        (4, 5, 13.50, 1.23, 1), (4, 6, 13.50, 1.23, 1), (4, 8, 14.00, 1.27, 1),
        (4, 10, 14.00, 1.27, 1), (4, 11, 14.00, 1.27, 1);

        INSERT INTO Persona_UF (id_consorcio, id_uf, cbu_cvu, id_tipo_relacion, fecha) VALUES
        (1, 1, '0000003100012345678901', 0, '2024-01-15'), (1, 2, '0000003100012345678902', 0, '2024-01-15'),
        (1, 3, '0000003100012345678903', 1, '2024-02-01'), (1, 4, '0000003100012345678904', 0, '2024-01-15'),
        (1, 5, '0000003100012345678905', 0, '2024-01-15'), (1, 6, '0000003100012345678906', 1, '2024-03-01'),
        (1, 7, '0000003100012345678907', 0, '2024-01-15'), (1, 8, '0000003100012345678908', 0, '2024-01-15'),
        (1, 9, '0000003100012345678909', 0, '2024-01-15'), (1, 10, '0000003100012345678910', 1, '2024-02-15'),
        (1, 11, '0000003100012345678911', 0, '2024-01-15'), (1, 12, '0000003100012345678912', 0, '2024-01-15');

        INSERT INTO Persona_UF (id_consorcio, id_uf, cbu_cvu, id_tipo_relacion, fecha) VALUES
        (2, 1, '0000003100012345678913', 0, '2024-01-10'), (2, 2, '0000003100012345678914', 1, '2024-02-01'),
        (2, 3, '0000003100012345678915', 0, '2024-01-10'), (2, 4, '0000003100012345678916', 0, '2024-01-10'),
        (2, 5, '0000003100012345678917', 0, '2024-01-10'), (2, 6, '0000003100012345678918', 1, '2024-03-01'),
        (2, 7, '0000003100012345678919', 0, '2024-01-10'), (2, 8, '0000003100012345678920', 0, '2024-01-10'),
        (2, 9, '0000003100012345678921', 0, '2024-01-10'), (2, 10, '0000003100012345678922', 1, '2024-02-15'),
        (2, 11, '0000003100012345678923', 0, '2024-01-10'), (2, 12, '0000003100012345678924', 0, '2024-01-10');

        INSERT INTO Persona_UF (id_consorcio, id_uf, cbu_cvu, id_tipo_relacion, fecha) VALUES
        (3, 1, '0000003100012345678925', 0, '2024-01-05'), (3, 2, '0000003100012345678926', 0, '2024-01-05'),
        (3, 3, '0000003100012345678927', 0, '2024-01-05'), (3, 4, '0000003100012345678928', 1, '2024-02-01'),
        (3, 5, '0000003100012345678929', 0, '2024-01-05'), (3, 6, '0000003100012345678930', 0, '2024-01-05'),
        (3, 7, '0000003100012345678931', 0, '2024-01-05'), (3, 8, '0000003100012345678932', 1, '2024-03-01'),
        (3, 9, '0000003100012345678933', 0, '2024-01-05'), (3, 10, '0000003100012345678934', 0, '2024-01-05'),
        (3, 11, '0000003100012345678935', 0, '2024-01-05'), (3, 12, '0000003100012345678936', 1, '2024-02-15');

        INSERT INTO Persona_UF (id_consorcio, id_uf, cbu_cvu, id_tipo_relacion, fecha) VALUES
        (4, 1, '0000003100012345678937', 0, '2024-01-08'), (4, 2, '0000003100012345678938', 0, '2024-01-08'),
        (4, 3, '0000003100012345678939', 0, '2024-01-08'), (4, 4, '0000003100012345678940', 0, '2024-01-08'),
        (4, 5, '0000003100012345678941', 1, '2024-02-01'), (4, 6, '0000003100012345678942', 0, '2024-01-08'),
        (4, 7, '0000003100012345678943', 0, '2024-01-08'), (4, 8, '0000003100012345678944', 1, '2024-03-01'),
        (4, 9, '0000003100012345678945', 0, '2024-01-08'), (4, 10, '0000003100012345678946', 0, '2024-01-08'),
        (4, 11, '0000003100012345678947', 0, '2024-01-08'), (4, 12, '0000003100012345678948', 1, '2024-02-15');
        
        SET IDENTITY_INSERT Expensa ON;
        -- Octubre 2024
        INSERT INTO Expensa (id, id_consorcio, anio, mes, vence1, vence2) VALUES
        (1, 1, 2024, 10, '2024-10-10', '2024-10-20'),
        (2, 2, 2024, 10, '2024-10-10', '2024-10-20'),
        (3, 3, 2024, 10, '2024-10-10', '2024-10-20'),
        (4, 4, 2024, 10, '2024-10-10', '2024-10-20');

        -- Noviembre 2024
        INSERT INTO Expensa (id, id_consorcio, anio, mes, vence1, vence2) VALUES
        (5, 1, 2024, 11, '2024-11-10', '2024-11-20'),
        (6, 2, 2024, 11, '2024-11-10', '2024-11-20'),
        (7, 3, 2024, 11, '2024-11-10', '2024-11-20'),
        (8, 4, 2024, 11, '2024-11-10', '2024-11-20');

        -- Diciembre 2024 (con extraordinarias)
        INSERT INTO Expensa (id, id_consorcio, anio, mes, vence1, vence2) VALUES
        (9, 1, 2024, 12, '2024-12-10', '2024-12-20'),
        (10, 2, 2024, 12, '2024-12-10', '2024-12-20'),
        (11, 3, 2024, 12, '2024-12-10', '2024-12-20'),
        (12, 4, 2024, 12, '2024-12-10', '2024-12-20');
        SET IDENTITY_INSERT Expensa OFF;
        
        SET IDENTITY_INSERT Detalle_Expensa ON;
        
        -- OCTUBRE 2024 TODOS LOS CONSORCIOS
        INSERT INTO Detalle_Expensa (id_det_exp, id_expensa, fecha, importe, id_proveedor, id_tipo_servicio, descripcion) VALUES
        -- Consorcio 1
        (1, 1, '2024-10-01', 2500.00, 11, 6, 'Gastos bancarios mes Octubre'),
        (2, 1, '2024-10-02', 45000.00, 1, 4, 'Servicio de limpieza Octubre'),
        (3, 1, '2024-10-03', 85000.00, 3, 7, 'Honorarios administrativos Octubre'),
        (4, 1, '2024-10-05', 32000.00, 4, 8, 'Seguro consorcio Octubre'),
        (5, 1, '2024-10-08', 28500.00, 5, 2, 'EDESUR - Luz Octubre'),
        (6, 1, '2024-10-10', 15200.00, 6, 2, 'AYSA - Agua Octubre'),
        (7, 1, '2024-10-12', 8900.00, 7, 2, 'Internet Telecom Octubre'),
        (8, 1, '2024-10-15', 6500.00, 8, 1, 'Fumigación edificio'),
        (9, 1, '2024-10-18', 4200.00, 14, 1, 'Recarga extintores'),
        (10, 1, '2024-10-22', 3800.00, 15, 1, 'Duplicado llaves'),
        -- Consorcio 2
        (11, 2, '2024-10-01', 1800.00, 11, 6, 'Gastos bancarios mes Octubre'),
        (12, 2, '2024-10-02', 38000.00, 1, 4, 'Servicio de limpieza Octubre'),
        (13, 2, '2024-10-03', 75000.00, 3, 7, 'Honorarios administrativos Octubre'),
        (14, 2, '2024-10-05', 28000.00, 4, 8, 'Seguro consorcio Octubre'),
        (15, 2, '2024-10-08', 22000.00, 5, 2, 'EDESUR - Luz Octubre'),
        (16, 2, '2024-10-10', 12500.00, 6, 2, 'AYSA - Agua Octubre'),
        (17, 2, '2024-10-20', 5200.00, 9, 1, 'Mantenimiento jardín'),
        -- Consorcio 3
        (18, 3, '2024-10-01', 3200.00, 11, 6, 'Gastos bancarios mes Octubre'),
        (19, 3, '2024-10-02', 52000.00, 1, 4, 'Servicio de limpieza Octubre'),
        (20, 3, '2024-10-03', 95000.00, 3, 7, 'Honorarios administrativos Octubre'),
        (21, 3, '2024-10-05', 38000.00, 4, 8, 'Seguro consorcio Octubre'),
        (22, 3, '2024-10-08', 35000.00, 5, 2, 'EDESUR - Luz Octubre'),
        (23, 3, '2024-10-10', 18500.00, 6, 2, 'AYSA - Agua Octubre'),
        (24, 3, '2024-10-12', 9500.00, 7, 2, 'Internet Telecom Octubre'),
        (25, 3, '2024-10-16', 7800.00, 8, 1, 'Fumigación edificio'),
        -- Consorcio 4
        (26, 4, '2024-10-01', 2800.00, 11, 6, 'Gastos bancarios mes Octubre'),
        (27, 4, '2024-10-02', 48000.00, 1, 4, 'Servicio de limpieza Octubre'),
        (28, 4, '2024-10-03', 88000.00, 3, 7, 'Honorarios administrativos Octubre'),
        (29, 4, '2024-10-05', 35000.00, 4, 8, 'Seguro consorcio Octubre'),
        (30, 4, '2024-10-08', 30000.00, 5, 2, 'EDESUR - Luz Octubre'),
        (31, 4, '2024-10-10', 16000.00, 6, 2, 'AYSA - Agua Octubre'),
        (32, 4, '2024-10-12', 9200.00, 7, 2, 'Internet Telecom Octubre'),
        (33, 4, '2024-10-18', 5500.00, 9, 1, 'Mantenimiento parque');

        -- NOVIEMBRE 2024 TODOS LOS CONSORCIOS
        INSERT INTO Detalle_Expensa (id_det_exp, id_expensa, fecha, importe, id_proveedor, id_tipo_servicio, descripcion) VALUES
        -- Consorcio 1
        (34, 5, '2024-11-01', 2500.00, 11, 6, 'Gastos bancarios mes Noviembre'),
        (35, 5, '2024-11-02', 45000.00, 1, 4, 'Servicio de limpieza Noviembre'),
        (36, 5, '2024-11-03', 85000.00, 3, 7, 'Honorarios administrativos Noviembre'),
        (37, 5, '2024-11-05', 32000.00, 4, 8, 'Seguro consorcio Noviembre'),
        (38, 5, '2024-11-08', 31000.00, 5, 2, 'EDESUR - Luz Noviembre'),
        (39, 5, '2024-11-10', 16500.00, 6, 2, 'AYSA - Agua Noviembre'),
        (40, 5, '2024-11-12', 8900.00, 7, 2, 'Internet Telecom Noviembre'),
        (41, 5, '2024-11-20', 12000.00, 12, 1, 'Pintura pasillos comunes'),
        -- Consorcio 2
        (42, 6, '2024-11-01', 1800.00, 11, 6, 'Gastos bancarios mes Noviembre'),
        (43, 6, '2024-11-02', 38000.00, 1, 4, 'Servicio de limpieza Noviembre'),
        (44, 6, '2024-11-03', 75000.00, 3, 7, 'Honorarios administrativos Noviembre'),
        (45, 6, '2024-11-05', 28000.00, 4, 8, 'Seguro consorcio Noviembre'),
        (46, 6, '2024-11-08', 24000.00, 5, 2, 'EDESUR - Luz Noviembre'),
        (47, 6, '2024-11-10', 13000.00, 6, 2, 'AYSA - Agua Noviembre'),
        (48, 6, '2024-11-18', 8500.00, 13, 1, 'Reparación cañerías'),
        -- Consorcio 3
        (49, 7, '2024-11-01', 3200.00, 11, 6, 'Gastos bancarios mes Noviembre'),
        (50, 7, '2024-11-02', 52000.00, 1, 4, 'Servicio de limpieza Noviembre'),
        (51, 7, '2024-11-03', 95000.00, 3, 7, 'Honorarios administrativos Noviembre'),
        (52, 7, '2024-11-05', 38000.00, 4, 8, 'Seguro consorcio Noviembre'),
        (53, 7, '2024-11-08', 38000.00, 5, 2, 'EDESUR - Luz Noviembre'),
        (54, 7, '2024-11-10', 19500.00, 6, 2, 'AYSA - Agua Noviembre'),
        (55, 7, '2024-11-12', 9500.00, 7, 2, 'Internet Telecom Noviembre'),
        -- Consorcio 4
        (56, 8, '2024-11-01', 2800.00, 11, 6, 'Gastos bancarios mes Noviembre'),
        (57, 8, '2024-11-02', 48000.00, 1, 4, 'Servicio de limpieza Noviembre'),
        (58, 8, '2024-11-03', 88000.00, 3, 7, 'Honorarios administrativos Noviembre'),
        (59, 8, '2024-11-05', 35000.00, 4, 8, 'Seguro consorcio Noviembre'),
        (60, 8, '2024-11-08', 32000.00, 5, 2, 'EDESUR - Luz Noviembre'),
        (61, 8, '2024-11-10', 17000.00, 6, 2, 'AYSA - Agua Noviembre'),
        (62, 8, '2024-11-12', 9200.00, 7, 2, 'Internet Telecom Noviembre');

        -- DICIEMBRE 2024 CON EXTRAORDINARIAS
        INSERT INTO Detalle_Expensa (id_det_exp, id_expensa, fecha, importe, id_proveedor, id_tipo_servicio, descripcion) VALUES
        -- Consorcio 1
        (63, 9, '2024-12-01', 2500.00, 11, 6, 'Gastos bancarios mes Diciembre'),
        (64, 9, '2024-12-02', 45000.00, 1, 4, 'Servicio de limpieza Diciembre'),
        (65, 9, '2024-12-03', 85000.00, 3, 7, 'Honorarios administrativos Diciembre'),
        (66, 9, '2024-12-05', 32000.00, 4, 8, 'Seguro consorcio Diciembre'),
        (67, 9, '2024-12-08', 35000.00, 5, 2, 'EDESUR - Luz Diciembre'),
        (68, 9, '2024-12-10', 18000.00, 6, 2, 'AYSA - Agua Diciembre'),
        (69, 9, '2024-12-12', 8900.00, 7, 2, 'Internet Telecom Diciembre'),
        (70, 9, '2024-12-15', 500000.00, 10, 5, 'Reparación estructura techo - Cuota 1/10'),
        (71, 9, '2024-12-18', 250000.00, 10, 5, 'Impermeabilización azotea - Cuota 1/5'),
        -- Consorcio 2
        (72, 10, '2024-12-01', 1800.00, 11, 6, 'Gastos bancarios mes Diciembre'),
        (73, 10, '2024-12-02', 38000.00, 1, 4, 'Servicio de limpieza Diciembre'),
        (74, 10, '2024-12-03', 75000.00, 3, 7, 'Honorarios administrativos Diciembre'),
        (75, 10, '2024-12-05', 28000.00, 4, 8, 'Seguro consorcio Diciembre'),
        (76, 10, '2024-12-08', 26000.00, 5, 2, 'EDESUR - Luz Diciembre'),
        (77, 10, '2024-12-10', 14000.00, 6, 2, 'AYSA - Agua Diciembre'),
        (78, 10, '2024-12-15', 350000.00, 10, 5, 'Reparación fachada - Cuota 1/8'),
        -- Consorcio 3
        (79, 11, '2024-12-01', 3200.00, 11, 6, 'Gastos bancarios mes Diciembre'),
        (80, 11, '2024-12-02', 52000.00, 1, 4, 'Servicio de limpieza Diciembre'),
        (81, 11, '2024-12-03', 95000.00, 3, 7, 'Honorarios administrativos Diciembre'),
        (82, 11, '2024-12-05', 38000.00, 4, 8, 'Seguro consorcio Diciembre'),
        (83, 11, '2024-12-08', 40000.00, 5, 2, 'EDESUR - Luz Diciembre'),
        (84, 11, '2024-12-10', 20000.00, 6, 2, 'AYSA - Agua Diciembre'),
        (85, 11, '2024-12-12', 9500.00, 7, 2, 'Internet Telecom Diciembre'),
        (86, 11, '2024-12-16', 420000.00, 10, 5, 'Instalación ascensor nuevo - Cuota 1/12'),
        -- Consorcio 4
        (87, 12, '2024-12-01', 2800.00, 11, 6, 'Gastos bancarios mes Diciembre'),
        (88, 12, '2024-12-02', 48000.00, 1, 4, 'Servicio de limpieza Diciembre'),
        (89, 12, '2024-12-03', 88000.00, 3, 7, 'Honorarios administrativos Diciembre'),
        (90, 12, '2024-12-05', 35000.00, 4, 8, 'Seguro consorcio Diciembre'),
        (91, 12, '2024-12-08', 34000.00, 5, 2, 'EDESUR - Luz Diciembre'),
        (92, 12, '2024-12-10', 18000.00, 6, 2, 'AYSA - Agua Diciembre'),
        (93, 12, '2024-12-12', 9200.00, 7, 2, 'Internet Telecom Diciembre'),
        (94, 12, '2024-12-17', 280000.00, 10, 5, 'Refacción hall entrada - Cuota 1/6');
        
        SET IDENTITY_INSERT Detalle_Expensa OFF;
        
        -- GASTOS ORDINARIOS
        INSERT INTO Gasto_Ordinario (id_gasto, nro_factura) VALUES
        (1, 'FC-0001-00012345'), (2, 'FC-0001-00012346'), (3, 'FC-0001-00012347'),
        (4, 'FC-0001-00012348'), (5, 'FC-0001-00012349'), (6, 'FC-0001-00012350'),
        (7, 'FC-0001-00012351'), (8, 'FC-0001-00012352'), (9, 'FC-0001-00012353'),
        (10, 'FC-0001-00012354'), (11, 'FC-0001-00012355'), (12, 'FC-0001-00012356'),
        (13, 'FC-0001-00012357'), (14, 'FC-0001-00012358'), (15, 'FC-0001-00012359'),
        (16, 'FC-0001-00012360'), (17, 'FC-0001-00012361'), (18, 'FC-0001-00012362'),
        (19, 'FC-0001-00012363'), (20, 'FC-0001-00012364'), (21, 'FC-0001-00012365'),
        (22, 'FC-0001-00012366'), (23, 'FC-0001-00012367'), (24, 'FC-0001-00012368'),
        (25, 'FC-0001-00012369'), (26, 'FC-0001-00012370'), (27, 'FC-0001-00012371'),
        (28, 'FC-0001-00012372'), (29, 'FC-0001-00012373'), (30, 'FC-0001-00012374'),
        (31, 'FC-0001-00012375'), (32, 'FC-0001-00012376'), (33, 'FC-0001-00012377'),
        (34, 'FC-0001-00012378'), (35, 'FC-0001-00012379'), (36, 'FC-0001-00012380'),
        (37, 'FC-0001-00012381'), (38, 'FC-0001-00012382'), (39, 'FC-0001-00012383'),
        (40, 'FC-0001-00012384'), (41, 'FC-0001-00012385'), (42, 'FC-0001-00012386'),
        (43, 'FC-0001-00012387'), (44, 'FC-0001-00012388'), (45, 'FC-0001-00012389'),
        (46, 'FC-0001-00012390'), (47, 'FC-0001-00012391'), (48, 'FC-0001-00012392'),
        (49, 'FC-0001-00012393'), (50, 'FC-0001-00012394'), (51, 'FC-0001-00012395'),
        (52, 'FC-0001-00012396'), (53, 'FC-0001-00012397'), (54, 'FC-0001-00012398'),
        (55, 'FC-0001-00012399'), (56, 'FC-0001-00012400'), (57, 'FC-0001-00012401'),
        (58, 'FC-0001-00012402'), (59, 'FC-0001-00012403'), (60, 'FC-0001-00012404'),
        (61, 'FC-0001-00012405'), (62, 'FC-0001-00012406'),
        (63, 'FC-0001-00012407'), (64, 'FC-0001-00012408'), (65, 'FC-0001-00012409'),
        (66, 'FC-0001-00012410'), (67, 'FC-0001-00012411'), (68, 'FC-0001-00012412'),
        (69, 'FC-0001-00012413'), (72, 'FC-0001-00012414'), (73, 'FC-0001-00012415'),
        (74, 'FC-0001-00012416'), (75, 'FC-0001-00012417'), (76, 'FC-0001-00012418'),
        (77, 'FC-0001-00012419'), (79, 'FC-0001-00012420'), (80, 'FC-0001-00012421'),
        (81, 'FC-0001-00012422'), (82, 'FC-0001-00012423'), (83, 'FC-0001-00012424'),
        (84, 'FC-0001-00012425'), (85, 'FC-0001-00012426'), (87, 'FC-0001-00012427'),
        (88, 'FC-0001-00012428'), (89, 'FC-0001-00012429'), (90, 'FC-0001-00012430'),
        (91, 'FC-0001-00012431'), (92, 'FC-0001-00012432'), (93, 'FC-0001-00012433');

        -- GASTOS EXTRAORDINARIOS (solo en diciembre)
        INSERT INTO Gasto_Extraordinario (id_gasto, cant_cuota, cuota_pagada) VALUES
        (70, 10, 1),  -- Reparación techo Consorcio 1 - Cuota 1/10
        (71, 5, 1),   -- Impermeabilización Consorcio 1 - Cuota 1/5
        (78, 8, 1),   -- Reparación fachada Consorcio 2 - Cuota 1/8
        (86, 12, 1),  -- Ascensor Consorcio 3 - Cuota 1/12
        (94, 6, 1);   -- Refacción hall Consorcio 4 - Cuota 1/6
        
        SET IDENTITY_INSERT Pago ON;

        INSERT INTO Pago (id_pago, fecha_pago, cbu_cvu, monto, id_exp) VALUES
        (1, '2024-10-08', '0000003100012345678901', 45000.00, 1),
        (2, '2024-10-08', '0000003100012345678902', 48000.00, 1),
        (3, '2024-10-09', '0000003100012345678903', 42000.00, 1),
        (4, '2024-10-09', '0000003100012345678904', 46000.00, 1),
        (5, '2024-10-09', '0000003100012345678905', 46000.00, 1),
        (6, '2024-10-09', '0000003100012345678906', 50000.00, 1),
        (7, '2024-10-10', '0000003100012345678907', 55000.00, 1),
        (8, '2024-10-10', '0000003100012345678908', 52000.00, 1),
        (9, '2024-10-07', '0000003100012345678913', 35000.00, 2),
        (10, '2024-10-07', '0000003100012345678914', 37000.00, 2),
        (11, '2024-10-08', '0000003100012345678915', 38000.00, 2),
        (12, '2024-10-08', '0000003100012345678916', 36000.00, 2),
        (13, '2024-10-09', '0000003100012345678917', 40000.00, 2),
        (14, '2024-10-09', '0000003100012345678918', 42000.00, 2),
        (15, '2024-10-08', '0000003100012345678925', 65000.00, 3),
        (16, '2024-10-08', '0000003100012345678926', 62000.00, 3),
        (17, '2024-10-09', '0000003100012345678937', 48000.00, 4),
        (18, '2024-10-09', '0000003100012345678938', 50000.00, 4),
        (19, '2024-10-15', '0000003100012345678909', 58000.00, 1),
        (20, '2024-10-16', '0000003100012345678919', 43500.00, 2),
        (21, '2024-10-17', '0000003100012345678927', 68000.00, 3),
        (22, '2024-10-18', '0000003100012345678939', 51000.00, 4),
        (23, '2024-10-25', '0000003100012345678910', 63000.00, 1),
        (24, '2024-10-26', '0000003100012345678920', 54000.00, 2),
        (25, '2024-10-27', '0000003100012345678928', 70000.00, 3),
        (26, '2024-10-28', '0000003100012345678940', 53000.00, 4);

        INSERT INTO Pago (id_pago, fecha_pago, cbu_cvu, monto, id_exp) VALUES
        (27, '2024-11-07', '0000003100012345678901', 46000.00, 5),
        (28, '2024-11-07', '0000003100012345678902', 49000.00, 5),
        (29, '2024-11-08', '0000003100012345678903', 43000.00, 5),
        (30, '2024-11-08', '0000003100012345678904', 47000.00, 5),
        (31, '2024-11-08', '0000003100012345678905', 47000.00, 5),
        (32, '2024-11-08', '0000003100012345678906', 51000.00, 5),
        (33, '2024-11-09', '0000003100012345678907', 56000.00, 5),
        (34, '2024-11-09', '0000003100012345678908', 53000.00, 5),
        (35, '2024-11-09', '0000003100012345678909', 57000.00, 5),
        (36, '2024-11-09', '0000003100012345678910', 60000.00, 5),
        (37, '2024-11-10', '0000003100012345678911', 61000.00, 5),
        (38, '2024-11-10', '0000003100012345678912', 59000.00, 5),
        (39, '2024-11-06', '0000003100012345678913', 36000.00, 6),
        (40, '2024-11-06', '0000003100012345678914', 38000.00, 6),
        (41, '2024-11-07', '0000003100012345678915', 39000.00, 6),
        (42, '2024-11-07', '0000003100012345678916', 37000.00, 6),
        (43, '2024-11-08', '0000003100012345678917', 41000.00, 6),
        (44, '2024-11-08', '0000003100012345678918', 43000.00, 6),
        (45, '2024-11-08', '0000003100012345678919', 44000.00, 6),
        (46, '2024-11-09', '0000003100012345678920', 45000.00, 6),
        (47, '2024-11-07', '0000003100012345678925', 67000.00, 7),
        (48, '2024-11-07', '0000003100012345678926', 64000.00, 7),
        (49, '2024-11-08', '0000003100012345678927', 69000.00, 7),
        (50, '2024-11-08', '0000003100012345678928', 72000.00, 7),
        (51, '2024-11-06', '0000003100012345678937', 49000.00, 8),
        (52, '2024-11-06', '0000003100012345678938', 51000.00, 8),
        (53, '2024-11-07', '0000003100012345678939', 52000.00, 8),
        (54, '2024-11-07', '0000003100012345678940', 54000.00, 8);

        INSERT INTO Pago (id_pago, fecha_pago, cbu_cvu, monto, id_exp) VALUES
        (55, '2024-12-06', '0000003100012345678901', 120000.00, 9),
        (56, '2024-12-06', '0000003100012345678902', 125000.00, 9),
        (57, '2024-12-07', '0000003100012345678903', 115000.00, 9),
        (58, '2024-12-07', '0000003100012345678904', 118000.00, 9),
        (59, '2024-12-08', '0000003100012345678905', 118000.00, 9),
        (60, '2024-12-08', '0000003100012345678906', 130000.00, 9),
        (61, '2024-12-09', '0000003100012345678907', 140000.00, 9),
        (62, '2024-12-09', '0000003100012345678908', 135000.00, 9),
        (63, '2024-12-10', '0000003100012345678909', 145000.00, 9),
        (64, '2024-12-10', '0000003100012345678910', 150000.00, 9),
        (65, '2024-12-05', '0000003100012345678913', 80000.00, 10),
        (66, '2024-12-05', '0000003100012345678914', 82000.00, 10),
        (67, '2024-12-06', '0000003100012345678915', 85000.00, 10),
        (68, '2024-12-06', '0000003100012345678916', 81000.00, 10),
        (69, '2024-12-07', '0000003100012345678917', 88000.00, 10),
        (70, '2024-12-07', '0000003100012345678918', 90000.00, 10),
        (71, '2024-12-06', '0000003100012345678925', 140000.00, 11),
        (72, '2024-12-06', '0000003100012345678926', 135000.00, 11),
        (73, '2024-12-07', '0000003100012345678927', 145000.00, 11),
        (74, '2024-12-07', '0000003100012345678928', 150000.00, 11),
        (75, '2024-12-10', '0000003100099999999999', 75000.00, 9),-- PAGO NO ASOCIADO (CBU que NO existe en Persona)
        (76, '2024-12-05', '0000003100012345678937', 95000.00, 12),
        (77, '2024-12-05', '0000003100012345678938', 98000.00, 12),
        (78, '2024-12-06', '0000003100012345678939', 100000.00, 12),
        (79, '2024-12-06', '0000003100012345678940', 102000.00, 12);
        
        SET IDENTITY_INSERT Pago OFF;

        COMMIT TRANSACTION;
        END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '';
        PRINT 'ERROR AL CARGAR DATOS:';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        
        THROW;
    END CATCH
END;
GO
