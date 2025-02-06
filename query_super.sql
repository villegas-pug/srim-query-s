USE SIM
GO

/*
SELECT 
	se.*
FROM SimPersona sper
JOIN SimExtranjero se ON sper.uIdPersona = se.uIdPersona
WHERE
	sper.sNombre = 'Sergio' 
	AND sper.sPaterno = 'Tarache'
	AND sper.sMaterno = 'Parra'
*/

-- Filtro: 
-- 140101 | CALLE ACOMAYO - MZ. G - LT. 5 - URBANIZACIÓN RESIDENCIAL
SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad,
	[Distrito Domicilio] = su.sNombre,
	[Dirección Domiciliaria] = se.sDomicilio,
	se.sTelefono,
	[Calidad Migratoria] = scm.sDescripcion,
	[Ultimo MovMigra] = (
							COALESCE(
							
								(SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
								WHERE
									smm.uIdPersona = se.uIdPersona
								ORDER BY
									smm.dFechaControl DESC),
								'Sin Control Migratorio'

							)
								
						)
FROM SimExtranjero se
JOIN SimPersona sper ON se.uIdPersona = sper.uIdPersona
LEFT JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
-- JOIN
WHERE
	-- 140135 | SAN MARTIN DE PORRES
	se.sIdUbigeoDomicilio IN ('140135')
	-- CALS/N MZ B LT 10 URB MANZALES
	-- se.sDomicilio LIKE '%CALS%'
	AND se.sDomicilio LIKE '%MZ%B%LT%10%'
	-- AND se.sDomicilio LIKE '%LT%10%'
	AND se.sDomicilio LIKE '%MAN%'


/*
	SELECT * FROM SimUbigeo su
	WHERE
		su.sNombre LIKE 'LIM%'

*/