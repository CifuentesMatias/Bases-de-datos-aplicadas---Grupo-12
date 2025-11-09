-- REPORTE 1: Flujo de caja semanal

CREATE OR ALTER PROCEDURE SP_Reporte_Flujo_Caja_Semanal
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH Semanas AS (
        SELECT 
            DATEPART(YEAR, p.fecha_pago) AS Anio,
            DATEPART(WEEK, p.fecha_pago) AS Semana,
            DATEADD(DAY, 1-DATEPART(WEEKDAY, p.fecha_pago), p.fecha_pago) AS Inicio_Semana,
            SUM(CASE WHEN de.Tipo_gasto = 'Ordinario' THEN p.monto ELSE 0 END) AS Recaudacion_Ordinaria,
            SUM(CASE WHEN de.Tipo_gasto = 'Extraordinario' THEN p.monto ELSE 0 END) AS Recaudacion_Extraordinaria,
            SUM(p.monto) AS Recaudacion_Total
        FROM Pago p
        INNER JOIN Detalle_Expensa de ON p.id_gasto = de.id
        INNER JOIN Expensa e ON de.id_expensa = e.id
        WHERE p.fecha_pago BETWEEN @FechaInicio AND @FechaFin
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
        GROUP BY 
            DATEPART(YEAR, p.fecha_pago),
            DATEPART(WEEK, p.fecha_pago),
            DATEADD(DAY, 1-DATEPART(WEEKDAY, p.fecha_pago), p.fecha_pago)
    )
    SELECT 
        Anio,
        Semana,
        Inicio_Semana,
        Recaudacion_Ordinaria,
        Recaudacion_Extraordinaria,
        Recaudacion_Total,
        AVG(Recaudacion_Total) OVER() AS Promedio_Periodo,
        SUM(Recaudacion_Total) OVER(ORDER BY Anio, Semana) AS Acumulado_Progresivo
    FROM Semanas
    ORDER BY Anio, Semana;
END;
GO


-- REPORTE 2:

CREATE OR ALTER PROCEDURE SP_Reporte_Recaudacion_Mes_Departamento
    @Anio INT,
    @IdConsorcio INT,
    @MesInicio INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        uf.piso,
        uf.departamento,
        SUM(CASE WHEN e.mes = 1 THEN p.monto ELSE 0 END) AS Enero,
        SUM(CASE WHEN e.mes = 2 THEN p.monto ELSE 0 END) AS Febrero,
        SUM(CASE WHEN e.mes = 3 THEN p.monto ELSE 0 END) AS Marzo,
        SUM(CASE WHEN e.mes = 4 THEN p.monto ELSE 0 END) AS Abril,
        SUM(CASE WHEN e.mes = 5 THEN p.monto ELSE 0 END) AS Mayo,
        SUM(CASE WHEN e.mes = 6 THEN p.monto ELSE 0 END) AS Junio,
        SUM(CASE WHEN e.mes = 7 THEN p.monto ELSE 0 END) AS Julio,
        SUM(CASE WHEN e.mes = 8 THEN p.monto ELSE 0 END) AS Agosto,
        SUM(CASE WHEN e.mes = 9 THEN p.monto ELSE 0 END) AS Septiembre,
        SUM(CASE WHEN e.mes = 10 THEN p.monto ELSE 0 END) AS Octubre,
        SUM(CASE WHEN e.mes = 11 THEN p.monto ELSE 0 END) AS Noviembre,
        SUM(CASE WHEN e.mes = 12 THEN p.monto ELSE 0 END) AS Diciembre,
        SUM(p.monto) AS Total_Anual
    FROM Pago p
    INNER JOIN Detalle_Expensa de ON p.id_gasto = de.id
    INNER JOIN Expensa e ON de.id_expensa = e.id
    INNER JOIN Persona_UF puf ON e.id_persona = puf.id_persona
    INNER JOIN Unidad_Funcional uf ON puf.id_uf = uf.id
    WHERE e.anio = @Anio
        AND uf.id_consorcio = @IdConsorcio
        AND e.mes >= @MesInicio
    GROUP BY uf.piso, uf.departamento
    ORDER BY uf.piso, uf.departamento;
END;
GO


-- REPORTE 3

CREATE OR ALTER PROCEDURE SP_Reporte_Recaudacion_Tipo_Gasto
    @FechaInicio DATE,
    @FechaFin DATE,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        YEAR(p.fecha_pago) AS Anio,
        MONTH(p.fecha_pago) AS Mes,
        SUM(CASE WHEN de.Tipo_gasto = 'Ordinario' THEN p.monto ELSE 0 END) AS Recaudacion_Ordinaria,
        SUM(CASE WHEN de.Tipo_gasto = 'Extraordinario' THEN p.monto ELSE 0 END) AS Recaudacion_Extraordinaria,
        SUM(p.monto) AS Total
    FROM Pago p
    INNER JOIN Detalle_Expensa de ON p.id_gasto = de.id
    INNER JOIN Expensa e ON de.id_expensa = e.id
    WHERE p.fecha_pago BETWEEN @FechaInicio AND @FechaFin
        AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    GROUP BY YEAR(p.fecha_pago), MONTH(p.fecha_pago)
    ORDER BY Anio, Mes;
END;
GO


-- REPORTE 4

CREATE OR ALTER PROCEDURE SP_Reporte_Top_Meses_Gastos_Ingresos
    @Anio INT,
    @IdConsorcio INT = NULL,
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Mayores gastos
    SELECT TOP (@TopN)
        'GASTOS' AS Tipo,
        e.anio,
        e.mes,
        SUM(de.importe) AS Total
    FROM Detalle_Expensa de
    INNER JOIN Expensa e ON de.id_expensa = e.id
    WHERE e.anio = @Anio
        AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    GROUP BY e.anio, e.mes
    ORDER BY Total DESC;
    
    -- Mayores ingresos
    SELECT TOP (@TopN)
        'INGRESOS' AS Tipo,
        YEAR(p.fecha_pago) AS anio,
        MONTH(p.fecha_pago) AS mes,
        SUM(p.monto) AS Total
    FROM Pago p
    INNER JOIN Detalle_Expensa de ON p.id_gasto = de.id
    INNER JOIN Expensa e ON de.id_expensa = e.id
    WHERE YEAR(p.fecha_pago) = @Anio
        AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    GROUP BY YEAR(p.fecha_pago), MONTH(p.fecha_pago)
    ORDER BY Total DESC;
END;
GO


-- REPORTE 5

CREATE OR ALTER PROCEDURE SP_Reporte_Propietarios_Morosidad
    @FechaCorte DATE,
    @IdConsorcio INT = NULL,
    @TopN INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH Deuda AS (
        SELECT 
            p.id,
            p.dni,
            p.nombre,
            p.apellido,
            p.email,
            p.telefono,
            e.id_consorcio,
            SUM(e.importe_total) AS Total_Expensas,
            ISNULL(SUM(pag.monto), 0) AS Total_Pagado,
            SUM(e.importe_total) - ISNULL(SUM(pag.monto), 0) AS Deuda_Total
        FROM Persona p
        INNER JOIN Expensa e ON p.id = e.id_persona
        LEFT JOIN Detalle_Expensa de ON e.id = de.id_expensa
        LEFT JOIN Pago pag ON de.id = pag.id_gasto
        WHERE e.vencimiento1 < @FechaCorte
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
        GROUP BY p.id, p.dni, p.nombre, p.apellido, p.email, p.telefono, e.id_consorcio
        HAVING SUM(e.importe_total) - ISNULL(SUM(pag.monto), 0) > 0
    )
    SELECT TOP (@TopN)
        dni AS DNI,
        nombre AS Nombre,
        apellido AS Apellido,
        email AS Email,
        telefono AS Telefono,
        Deuda_Total AS Monto_Adeudado
    FROM Deuda
    ORDER BY Deuda_Total DESC;
END;
GO


-- REPORTE 6

CREATE OR ALTER PROCEDURE SP_Reporte_Dias_Entre_Pagos
    @IdUnidadFuncional INT = NULL,
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH Pagos_UF AS (
        SELECT 
            uf.id AS Id_UF,
            uf.piso,
            uf.departamento,
            p.fecha_pago,
            LAG(p.fecha_pago) OVER (PARTITION BY uf.id ORDER BY p.fecha_pago) AS Pago_Anterior
        FROM Pago p
        INNER JOIN Detalle_Expensa de ON p.id_gasto = de.id
        INNER JOIN Expensa e ON de.id_expensa = e.id
        INNER JOIN Persona_UF puf ON e.id_persona = puf.id_persona
        INNER JOIN Unidad_Funcional uf ON puf.id_uf = uf.id
        WHERE de.Tipo_gasto = 'Ordinario'
            AND p.fecha_pago BETWEEN @FechaInicio AND @FechaFin
            AND (@IdUnidadFuncional IS NULL OR uf.id = @IdUnidadFuncional)
    )
    SELECT 
        Id_UF,
        piso,
        departamento,
        fecha_pago AS Fecha_Pago,
        Pago_Anterior AS Pago_Anterior,
        CASE 
            WHEN Pago_Anterior IS NOT NULL 
            THEN DATEDIFF(DAY, Pago_Anterior, fecha_pago)
            ELSE NULL 
        END AS Dias_Entre_Pagos
    FROM Pagos_UF
    ORDER BY Id_UF, fecha_pago;
END;
GO
