USE Com2900G12;
GO


-- Administrativo General

CREATE ROLE Administrativo_General;
GO

-- lectura tablas
GRANT SELECT ON Consorcio TO Administrativo_General;
GRANT SELECT ON Unidad_Funcional TO Administrativo_General;
GRANT SELECT ON Persona TO Administrativo_General;
GRANT SELECT ON Persona_UF TO Administrativo_General;
GRANT SELECT ON Prop_Inq TO Administrativo_General;
GRANT SELECT ON Adicional TO Administrativo_General;
GRANT SELECT ON Tipo_Adicional TO Administrativo_General;
GRANT SELECT ON Expensa TO Administrativo_General;
GRANT SELECT ON Detalle_Expensa TO Administrativo_General;
GRANT SELECT ON Pago TO Administrativo_General;
GRANT SELECT ON Proveedor TO Administrativo_General;
GRANT SELECT ON Gasto_Ordinario TO Administrativo_General;
GRANT SELECT ON Gasto_Extraordinario TO Administrativo_General;

-- actualización datos de UF
GRANT UPDATE ON Unidad_Funcional TO Administrativo_General;
GRANT UPDATE ON Persona TO Administrativo_General;
GRANT UPDATE ON Persona_UF TO Administrativo_General;
GRANT UPDATE ON Adicional TO Administrativo_General;

-- ejecución reportes
GRANT EXECUTE ON SP_Reporte_Flujo_Caja_Semanal TO Administrativo_General;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Mes_Departamento TO Administrativo_General;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Tipo_Gasto TO Administrativo_General;
GRANT EXECUTE ON SP_Reporte_Top_Meses_Gastos_Ingresos TO Administrativo_General;
GRANT EXECUTE ON SP_Reporte_Propietarios_Morosidad TO Administrativo_General;
GRANT EXECUTE ON SP_Reporte_Dias_Entre_Pagos TO Administrativo_General;
GO


--  Administrativo Bancario

CREATE ROLE Administrativo_Bancario;
GO

-- lectura
GRANT SELECT ON Consorcio TO Administrativo_Bancario;
GRANT SELECT ON Unidad_Funcional TO Administrativo_Bancario;
GRANT SELECT ON Persona TO Administrativo_Bancario;
GRANT SELECT ON Persona_UF TO Administrativo_Bancario;
GRANT SELECT ON Expensa TO Administrativo_Bancario;
GRANT SELECT ON Detalle_Expensa TO Administrativo_Bancario;
GRANT SELECT ON Pago TO Administrativo_Bancario;

-- importación de información 
GRANT INSERT ON Pago TO Administrativo_Bancario;
GRANT UPDATE ON Pago TO Administrativo_Bancario;

-- ejecución reportes
GRANT EXECUTE ON SP_Reporte_Flujo_Caja_Semanal TO Administrativo_Bancario;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Mes_Departamento TO Administrativo_Bancario;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Tipo_Gasto TO Administrativo_Bancario;
GRANT EXECUTE ON SP_Reporte_Top_Meses_Gastos_Ingresos TO Administrativo_Bancario;
GRANT EXECUTE ON SP_Reporte_Propietarios_Morosidad TO Administrativo_Bancario;
GRANT EXECUTE ON SP_Reporte_Dias_Entre_Pagos TO Administrativo_Bancario;
GO


-- Administrativo Operativo

CREATE ROLE Administrativo_Operativo;
GO

-- lectura  todas las tablas
GRANT SELECT ON Consorcio TO Administrativo_Operativo;
GRANT SELECT ON Unidad_Funcional TO Administrativo_Operativo;
GRANT SELECT ON Persona TO Administrativo_Operativo;
GRANT SELECT ON Persona_UF TO Administrativo_Operativo;
GRANT SELECT ON Prop_Inq TO Administrativo_Operativo;
GRANT SELECT ON Adicional TO Administrativo_Operativo;
GRANT SELECT ON Tipo_Adicional TO Administrativo_Operativo;
GRANT SELECT ON Expensa TO Administrativo_Operativo;
GRANT SELECT ON Detalle_Expensa TO Administrativo_Operativo;
GRANT SELECT ON Pago TO Administrativo_Operativo;
GRANT SELECT ON Proveedor TO Administrativo_Operativo;
GRANT SELECT ON Gasto_Ordinario TO Administrativo_Operativo;
GRANT SELECT ON Gasto_Extraordinario TO Administrativo_Operativo;

-- actualización datos UF
GRANT UPDATE ON Unidad_Funcional TO Administrativo_Operativo;
GRANT UPDATE ON Persona TO Administrativo_Operativo;
GRANT UPDATE ON Persona_UF TO Administrativo_Operativo;
GRANT UPDATE ON Adicional TO Administrativo_Operativo;

-- ejecución de reportes
GRANT EXECUTE ON SP_Reporte_Flujo_Caja_Semanal TO Administrativo_Operativo;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Mes_Departamento TO Administrativo_Operativo;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Tipo_Gasto TO Administrativo_Operativo;
GRANT EXECUTE ON SP_Reporte_Top_Meses_Gastos_Ingresos TO Administrativo_Operativo;
GRANT EXECUTE ON SP_Reporte_Propietarios_Morosidad TO Administrativo_Operativo;
GRANT EXECUTE ON SP_Reporte_Dias_Entre_Pagos TO Administrativo_Operativo;
GO


-- Sistemas

CREATE ROLE Sistemas;
GO

-- lectura todas las tablas
GRANT SELECT ON Consorcio TO Sistemas;
GRANT SELECT ON Unidad_Funcional TO Sistemas;
GRANT SELECT ON Persona TO Sistemas;
GRANT SELECT ON Persona_UF TO Sistemas;
GRANT SELECT ON Prop_Inq TO Sistemas;
GRANT SELECT ON Adicional TO Sistemas;
GRANT SELECT ON Tipo_Adicional TO Sistemas;
GRANT SELECT ON Expensa TO Sistemas;
GRANT SELECT ON Detalle_Expensa TO Sistemas;
GRANT SELECT ON Pago TO Sistemas;
GRANT SELECT ON Proveedor TO Sistemas;
GRANT SELECT ON Gasto_Ordinario TO Sistemas;
GRANT SELECT ON Gasto_Extraordinario TO Sistemas;

-- ejecución de reportes
GRANT EXECUTE ON SP_Reporte_Flujo_Caja_Semanal TO Sistemas;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Mes_Departamento TO Sistemas;
GRANT EXECUTE ON SP_Reporte_Recaudacion_Tipo_Gasto TO Sistemas;
GRANT EXECUTE ON SP_Reporte_Top_Meses_Gastos_Ingresos TO Sistemas;
GRANT EXECUTE ON SP_Reporte_Propietarios_Morosidad TO Sistemas;
GRANT EXECUTE ON SP_Reporte_Dias_Entre_Pagos TO Sistemas;
GO
