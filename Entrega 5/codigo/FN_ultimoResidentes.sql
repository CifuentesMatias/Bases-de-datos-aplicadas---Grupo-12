CREATE FUNCTION fn_ultimoResidentes(@id_consorcio INT, @fecha_actual DATE) RETURNS TABLE AS RETURN
(
	/*
	id_uf	id_persona	es_propietario	fecha_alta	fecha_registro
	1		100			1				2023-01-15	2023-01-10
	1		101			1				2024-05-20	2024-05-15
	1		200			0				2023-06-10	2023-06-05
	1		201			0				2024-08-01	2024-07-28
	2		300			1				2023-03-12	2023-03-10
	2		400			0				2023-07-20	2023-07-15
	3		500			1				2024-02-01	2024-01-25


	id_uf	id_persona	es_propietario	fecha_alta	rn
	1		101			1				2024-05-20	1 Propietario más reciente UF1
	1		100			1				2023-01-15	2
	1		201			0				2024-08-01	1 Inquilino más reciente UF1
	1		200			0				2023-06-10	2
	2		300			1				2023-03-12	1 Propietario más reciente UF2
	2		400			0				2023-07-20	1 Inquilino más reciente UF2
	3		500			1				2024-02-01	1 Solo propietario UF3
	*/

    WITH
		ultimo_residentes AS (SELECT
						        id_uf,
						        id_persona,
						        es_propietario,
						        ROW_NUMBER() OVER (PARTITION BY id_uf, es_propietario ORDER BY fecha_alta DESC) AS rn
						      FROM 
						    	persona_uf
						      WHERE 
						    	id_consorcio = @id_consorcio AND
						       	fecha_alta <= @fecha_actual),
		residentes_actuales AS (SELECT
							        id_uf,
							        MAX(CASE WHEN es_propietario = 1 THEN id_persona END) AS id_persona_prop,
							        MAX(CASE WHEN es_propietario = 0 THEN id_persona END) AS id_persona_inq
							    FROM 
							    	ultimo_residentes
							    WHERE 
							    	rn = 1
							    GROUP BY 
							    	id_uf)
	SELECT
	    ra.id_uf,
	    COALESCE(prop.nombre + ' ' + prop.apellido, '-') AS propietario,
	    prop.dni AS prop_dni,
	    COALESCE(prop.telefono, '') AS prop_tel,
	    COALESCE(prop.email, '') AS prop_email,
	    COALESCE(inq.nombre + ' ' + inq.apellido, '-') AS inquilino,
	    inq.dni AS inq_dni,
	    COALESCE(inq.telefono, '') AS inq_tel,
	    COALESCE(inq.email, '') AS inq_email
	FROM
	    residentes_actuales ra
	LEFT JOIN
	    persona prop 
	    ON prop.id_persona = ra.id_persona_prop
	LEFT JOIN
	    persona inq 
	    ON inq.id_persona = ra.id_persona_inq
);
GO
