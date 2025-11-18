CREATE FUNCTION fn_5TODIAHABIL(@fecha DATE) RETURNS DATE AS
BEGIN
    DECLARE @inicioMes DATE = DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1);
    DECLARE @contador INT = 0;
    DECLARE @diaActual DATE = @inicioMes;


    DECLARE @feriados TABLE (fecha DATE PRIMARY KEY);
	INSERT INTO @feriados (fecha) VALUES
		('2024-01-01'), ('2024-02-12'), ('2024-02-13'),
		('2024-03-24'), ('2024-03-29'), ('2024-04-02'),
		('2024-05-01'), ('2024-05-25'), ('2024-06-20'),
		('2024-07-09'), ('2024-12-08'), ('2024-12-25'),
	    ('2025-01-01'), -- anio nuevo
	    ('2025-03-03'), -- carnaval
	    ('2025-03-04'), -- carnaval
	    ('2025-03-24'), -- dia memoria
	    ('2025-04-02'), -- malvinas
	    ('2025-04-18'), -- viernes santo
	    ('2025-05-01'), -- dia trabajador
	    ('2025-05-25'), -- revolucion
	    ('2025-06-20'), -- dia bandera
	    ('2025-07-09'), -- dia independencia
	    ('2025-12-08'), -- dia de la virgen???
	    ('2025-12-25'), -- navidad
		('2026-01-01'), ('2026-02-16'), ('2026-02-17'),
		('2026-03-24'), ('2026-04-02'), ('2026-04-03'),
		('2026-05-01'), ('2026-05-25'), ('2026-06-20'),
		('2026-07-09'), ('2026-12-08'), ('2026-12-25');


    -- deberia asegurarme que que 1 = domingo, 7 = sábado
    --SET DATEFIRST 7;

    WHILE @contador < 5
    BEGIN
        -- DATENAME(WEEKDAY) no se usa para evitar problemas de idioma
			IF DATEPART(WEEKDAY, @diaActual) NOT IN (1, 7) -- no fin de semana
           	AND NOT EXISTS (SELECT 1 FROM @feriados WHERE fecha = @diaActual) -- no feriado
            SET @contador = @contador + 1;

        IF @contador < 5
            SET @diaActual = DATEADD(DAY, 1, @diaActual);
    END
    
    RETURN @diaActual;
END; 
GO
