USE SIM
GO


/*░
	1. Nombres registrados en el Control Migratorio no corresponden al `uIdPersona` ...
===========================================================================================================================================================*/

-- 1: SimMovMigra ...
DROP TABLE IF EXISTS #tmp_movmig
SELECT
	smm.sIdMovMigratorio,
	[uIdPersona_CM] = smm.uIdPersona,
	[sNombres_CM] = smm.sNombres
	INTO #tmp_movmig
FROM SimMovMigra smm
WHERE
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.sIdPaisNacionalidad = 'PER'
	AND (smm.sNombres != '' AND smm.sNombres IS NOT NULL)

-- Index
CREATE NONCLUSTERED INDEX IX_tmp_movmig_uIdPersona
    ON dbo.#tmp_movmig(uIdPersona_CM)

CREATE NONCLUSTERED INDEX IX_tmp_movmig_sNombres
    ON dbo.#tmp_movmig(sNombres_CM)

-- 2: SimPersona ...
DROP TABLE IF EXISTS #tmp_persona
SELECT
	[uIdPersona_PER] = sper.uIdPersona,
	[sPaterno_PER] = sper.sPaterno, 
	[sMaterno_PER] = sper.sMaterno, 
	[sNombre_PER] = sper.sNombre
	INTO #tmp_persona
FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND sper.sIdPaisNacionalidad = 'PER'
	AND sper.sPaterno != '' AND sper.sMaterno != ''
	AND sper.sPaterno IS NOT NULL AND sper.sMaterno IS NOT NULL

-- Index
CREATE NONCLUSTERED INDEX IX_tmp_persona_uIdPersona
    ON dbo.#tmp_persona(uIdPersona_PER)

-- 3: Final ...
-- 3.1: ...
DROP TABLE IF EXISTS #final
SELECT 
	m.*,
	p.*
	INTO #final
FROM #tmp_movmig m
JOIN #tmp_persona p ON m.uIdPersona_CM = p.uIdPersona_PER
WHERE
	(PATINDEX('%[éáíóúñ''''-]%', p.sPaterno_PER) = 0 AND PATINDEX('%[éáíóúñ''''-]%', p.sMaterno_PER) = 0 AND PATINDEX('%[éáíóúñ''''-]%', m.sNombres_CM) = 0)
	AND (m.sNombres_CM NOT LIKE '%' + LEFT(p.sPaterno_PER, 3) + '%' AND m.sNombres_CM NOT LIKE '%' + LEFT(p.sMaterno_PER, 3) + '%')

-- Test ...
-- 627,912
SELECT 
	u.sLogin,
	u.sNombre,
	[nTotal] = COUNT(1)
FROM #final f
JOIN SimPersona p ON p.uIdPersona = f.uIdPersona_PER
JOIN SimSesion s ON p.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
GROUP BY
	u.sLogin,
	u.sNombre
ORDER BY 3 DESC

DROP TABLE IF EXISTS final_base_1
SELECT * INTO final_base_1 FROM #final
--===========================================================================================================================================================*/

 
/*░
	2. ...
===========================================================================================================================================================*/
-- 57 | PRORROGA DE RESIDENCIA

SELECT * FROM SimTipoTramite stt WHERE stt.sDescripcion LIKE '%ins%'

-- 1,130,834
-- 126 | PERMISO TEMPORAL DE PERMANENCIA - RS109
-- 113 | REGULARIZACION DE EXTRANJEROS
SELECT TOP 10 sccm.* FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
-- JOIN SimProrroga sprr ON st.sNumeroTramite = sprr.sNumeroTramite
-- JOIN SimDocumentoOficial sdo ON st.sNumeroTramite = sdo.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
-- JOIN SimAgregado sa ON st.sNumeroTramite = sa.sNum
WHERE
	st.bCancelado = 0
	AND st.nIdTipoTramite IN (113, 126)
	AND sti.sEstadoActual = 'P'
	AND (sccm.dFechaVencimiento IS NOT NULL AND sccm.dFechaVencimiento != '')

-- CE
SELECT TOP 10 sce.* FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCarnetExtranjeria sce ON st.sNumeroTramite = sce.sNumeroTramite
WHERE
	st.bCancelado = 0
	-- AND st.nIdTipoTramite IN (113, 126)
	AND sti.sEstadoActual = 'P'
	AND (sce.dFechaCaducidad IS NOT NULL AND sce.dFechaCaducidad != '')

*/
--===========================================================================================================================================================*/

/*░
	2. Ciudadanos peruanos menores de 16 años no pueden tener estado civil diferente a soltero ...
===========================================================================================================================================================*/
DROP TABLE IF EXISTS #tmp_per_menor
SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	[nEdad] = DATEDIFF(YYYY, sper.dFechaNacimiento, GETDATE()),
	sper.sIdPaisNacimiento,
	sper.sIdPaisResidencia,
	sper.sIdPaisNacionalidad,
	sper.sIdEstadoCivil,
	sper.sIdDocIdentidad,
	sper.sNumDocIdentidad,
	sper.uIdPersona
	INTO #tmp_per_menor
FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND (sper.dFechaNacimiento IS NOT NULL AND sper.dFechaNacimiento != '1900-01-01 00:00:00.000')
	AND sper.sIdPaisNacionalidad = 'PER'
	AND sper.sIdEstadoCivil IN ('C', 'D', 'O', 'V')
	AND DATEDIFF(YYYY, sper.dFechaNacimiento, GETDATE()) < 16

-- test
SELECT 
	u.sLogin,
	u.sNombre,
	[nTotal] = COUNT(1)
FROM #tmp_per_menor f
JOIN SimPersona p ON p.uIdPersona = f.uIdPersona
JOIN SimSesion s ON p.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
GROUP BY
	u.sLogin,
	u.sNombre
ORDER BY 3 DESC

--===========================================================================================================================================================*/


/*░
	3. Ciudadanos peruanos con documento diferente a DNI ...
===========================================================================================================================================================*/

/*
	CIP	| DOC. IDENTIFICACION PERSONAL
	LIB	| Libreta de Tripulante
	PAS	| PASAPORTE
	SLV	| SALVOCONDUCTO
*/
DROP TABLE IF EXISTS #tmp_per_diff_dni
SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacimiento,
	sper.sIdPaisResidencia,
	sper.sIdPaisNacionalidad,
	sper.sIdEstadoCivil,
	sper.sIdDocIdentidad,
	[sDocumento] = sd.sDescripcion,
	[sNumDocIdentidad] = CONCAT('''', sper.sNumDocIdentidad),
	sper.uIdPersona
	INTO #tmp_per_diff_dni
FROM SimPersona sper
JOIN SimDocumento sd ON sper.sIdDocIdentidad = sd.sIdDocumento
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND (sper.sIdPaisNacionalidad = 'PER' AND sper.sIdPaisNacimiento = 'PER')
	AND sper.sIdDocIdentidad NOT IN ('NNN', 'DNI', 'PAS', 'LE', 'PNA', 'SLV', 'LIB')
	AND (sper.sNumDocIdentidad != '' AND sper.sNumDocIdentidad IS NOT NULL)


-- Test ...
SELECT 
	u.sLogin,
	u.sNombre,
	[nTotal] = COUNT(1)
FROM #tmp_per_diff_dni f
JOIN SimPersona p ON p.uIdPersona = f.uIdPersona
JOIN SimSesion s ON p.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
GROUP BY
	u.sLogin,
	u.sNombre
ORDER BY 3 DESC

--===========================================================================================================================================================*/


/*░
	4. Nacidos peruano y con nacionalidad peruana con calidad diferente de Peruano ...
===========================================================================================================================================================*/

SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacimiento,
	sper.sIdPaisResidencia,
	sper.sIdPaisNacionalidad,
	sper.sIdEstadoCivil,
	sper.sIdDocIdentidad,
	[sNumDocIdentidad] = CONCAT('''', sper.sNumDocIdentidad),
	sper.uIdPersona,
	[sCalidad] = sc.sDescripcion
FROM SimPersona sper
JOIN SimCalidadMigratoria sc ON sper.nIdCalidad = sc.nIdCalidad
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	-- AND (sper.sIdPaisNacionalidad = 'PER' AND sper.sIdPaisNacimiento = 'PER')
	AND sper.sIdPaisNacionalidad = 'PER'
	AND (sper.sIdDocIdentidad = 'DNI' AND LEN(sper.sNumDocIdentidad) = 8)
	AND sper.nIdCalidad != 21 -- 21 | PERUANO


-- Test ...
--===========================================================================================================================================================*/

/*░
	5. Extranjeros con Documento Nacional de Identidad(DNI) ...
===========================================================================================================================================================*/

SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacimiento,
	sper.sIdPaisResidencia,
	sper.sIdPaisNacionalidad,
	sper.sIdEstadoCivil,
	sper.sIdDocIdentidad,
	[sNumDocIdentidad] = CONCAT('''', sper.sNumDocIdentidad),
	sper.uIdPersona
FROM SimPersona sper
JOIN SimCalidadMigratoria sc ON sper.nIdCalidad = sc.nIdCalidad
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	-- AND (sper.sIdPaisNacionalidad NOT IN ('PER', 'ARN', 'NNN') AND sper.sIdPaisNacimiento NOT IN ('PER', 'ARN', 'NNN'))
	-- AND (sper.sIdPaisNacionalidad IS NOT NULL AND sper.sIdPaisNacimiento IS NOT NULL)
	AND sper.sIdPaisNacionalidad NOT IN ('PER', 'ARN', 'NNN')
	AND sper.sIdPaisNacionalidad IS NOT NULL
	AND (sper.sIdDocIdentidad = 'DNI' AND LEN(sper.sNumDocIdentidad) = 8)

-- Test ...
--===========================================================================================================================================================*/


-- Test ...
