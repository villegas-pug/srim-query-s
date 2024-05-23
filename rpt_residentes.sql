/*░
--» Nacionalizados ... 
=============================================================================================================================*/

-- Secuencia etapas nacionalización
SELECT
	se.nIdEtapa,
	[nSecuencia] = sett.nSecuencia,
	[sEtapa] = se.sDescripcion
FROM SimEtapaTipoTramite sett 
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
-- NAC → 69, 71, 72, 73, 76, 78, 79
-- CCM → 58
WHERE sett.nIdTipoTramite = 58 
ORDER BY
	sett.nSecuencia

;WITH tmp_nac AS
(
	SELECT
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Impresión] = (
								SELECT TOP 1 setn.dFechaHoraAud FROM SimEtapaTramiteNac setn 
								WHERE 
									setn.sNumeroTramite = st.sNumeroTramite
									AND setn.nIdEtapa = 6 -- 6 | IMPRESION
									-- AND setn.sEstado = 'F'
								ORDER BY
									setn.dFechaHoraAud DESC
							),
		[Fecha Nacionalización] = (
								SELECT TOP 1 YEAR(setn.dFechaHoraAud) FROM SimEtapaTramiteNac setn 
								WHERE 
									setn.sNumeroTramite = st.sNumeroTramite
									AND setn.nIdEtapa = 6 -- 6 | IMPRESION
									-- AND setn.sEstado = 'F'
								ORDER BY
									setn.dFechaHoraAud DESC
							),
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad
	FROM SimTramite st
	JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	LEFT JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	LEFT JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	WHERE
		stn.nIdEtapaActual IN (6, 48, 40, 47, 42, 53, 43, 44)
		AND (
				SELECT TOP 1 YEAR(setn.dFechaHoraAud) FROM SimEtapaTramiteNac setn 
				WHERE 
					setn.sNumeroTramite = st.sNumeroTramite
					AND setn.nIdEtapa = 6 -- 6 | IMPRESION
				ORDER BY
					setn.dFechaHoraAud DESC
			) >= 2016
		AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)
)
SELECT * FROM tmp_nac n
ORDER BY
	n.[Fecha Nacionalización]

-- Test ...
SELECT TOP 10 * FROM SimTramiteNac
--=============================================================================================================================*/

/*░
--» CCM ... 
=============================================================================================================================*/
	
;WITH tmp_ccm_vigentes AS(

	SELECT
		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = sccm.dFechaAprobacion,
		[Fecha Vencimiento] = sccm.dFechaVencimiento,
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		st.nIdTipoTramite = 58 -- CCM
		AND sti.sEstadoActual IN ('A', 'P')
		AND (sccm.dFechaAprobacion IS NOT NULL AND sccm.dFechaAprobacion >= '2016-01-01 00:00:00.000')
		-- AND scm.sTipo = 'R' -- RESIDENTE
		AND DATEDIFF(DD, GETDATE(), sccm.dFechaVencimiento) > 0 -- Vigentes: No excede fecha de vencimiento ...
	
), tmp_ccm_vigentes_distinct AS (

	SELECT * FROM (

		SELECT 
			*,
			[nFila_ccm] = ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY [Fecha Aprobación] DESC)
		FROM tmp_ccm_vigentes

	) ccm
	WHERE ccm.nFila_ccm = 1
)
SELECT * FROM tmp_ccm_vigentes_distinct

-- Test: ``
--=============================================================================================================================*/

/*░
--» CPP | 113 | REGULARIZACION DE EXTRANJEROS ... 
--→ CPP es Aprobado en etapa `75 | CONFORMIDAD JEFATURA ZONAL` Finalizada ...
=============================================================================================================================*/

;WITH tmp_cpp_vigentes AS(

	SELECT
		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = seti.dFechaFin,
		[Fecha Vencimiento] = [Fecha Aprobación],
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimEtapaTramiteInm seti ON seti.sNumeroTramite = st.sNumeroTramite
									AND seti.nIdEtapa = 75 -- 75 | CONFORMIDAD JEFATURA ZONAL
									AND seti.sEstado = 'F'
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		st.nIdTipoTramite = 113 -- CPP
		AND sti.sEstadoActual IN ('A', 'P')
		-- AND scm.sTipo = 'R' -- RESIDENTE
		--AND DATEDIFF(DD, GETDATE(), sccm.dFechaVencimiento) > 0 -- Vigentes: No excede fecha de vencimiento ...
	
), tmp_cpp_vigentes_distinct AS (

	SELECT * FROM (

		SELECT 
			*,
			[nFila_cpp] = ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY [Fecha Aprobación] DESC)
		FROM tmp_cpp_vigentes

	) cpp
	WHERE cpp.nFila_cpp = 1
)
SELECT * FROM tmp_cpp_vigentes_distinct

SELECT COUNT(1) FROM SimTramite st 
WHERE 
	st.nIdTipoTramite = 113 
	AND st.dFechaHoraReg BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

SELECT * FROM SimCambioCalMig sccm WHERE sccm.sNumeroTramite = 'LM180088518'


/*░
--» PRR ... 
=============================================================================================================================*/

-- Etapas por tipo trámite
SELECT 
	TOP 10 
	sti.sEstadoActual,
	scm.sDescripcion,
	se.sDescripcion,
	sccm.*
FROM SimTramite st 
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
JOIN SimEtapa se ON sti.nIdEtapaActual = se.nIdEtapa
JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
WHERE 
	--st.nIdTipoTramite = 113
	--AND st.sIdDependencia = '25'
	--AND dFechaHoraReg BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:49.999'
	st.sNumeroTramite = 'LM220003182'

SELECT 
	se.nIdEtapa, 
	se.sDescripcion, 
	sett.nSecuencia 
FROM SimEtapaTipoTramite sett 
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE
	sett.nIdTipoTramite = 113
ORDER BY sett.nSecuencia

-- 
SELECT 
	se.nIdEtapa, 
	se.sDescripcion,
	seti.*
FROM SimTramite st
JOIN SimEtapaTramiteInm seti ON st.sNumeroTramite = seti.sNumeroTramite
JOIN SimEtapa se ON seti.nIdEtapa = se.nIdEtapa
WHERE
	st.sNumeroTramite = 'LM210734180'
ORDER BY
	seti.nIdEtapaTramite

-- Etapas
SELECT 
	TOP 10 
	sti.sEstadoActual,
	[sEtapaActual] = se.sDescripcion,
	sccm.*
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
JOIN SimEtapa se ON sti.nIdEtapaActual = se.nIdEtapa
WHERE 
	st.nIdTipoTramite = 113
	AND st.sIdDependencia = '25'
	AND sti.sEstadoActual IN ('A', 'P')
	-- AND sccm.dFechaAprobacion IS NOT NULL
	AND sccm.dFechaAprobacion >= '2016-01-01 00:00:00.000'
	AND EXISTS(-- ...
			
			SELECT 
				TOP 1 1
			FROM SimEtapaTramiteInm seti
			WHERE 
				seti.sNumeroTramite = st.sNumeroTramite
				AND seti.nIdEtapa = 6 -- 6 | IMPRESION
				-- AND seti.sEstado = 'F'

		)

SELECT * FROM SimDependencia WHERE sNombre LIKE '%lim%'

SELECT 
	se.nIdEtapa, se.sDescripcion
FROM SimEtapaTramiteInm setti
JOIN SimEtapa se ON setti.nIdEtapa = se.nIdEtapa
WHERE sNumeroTramite = 'LM180088518'

;WITH tmp_prr AS
(
	SELECT
		(spa.sNombre)paisNac,
		(sp.sSexo)sexo,
		YEAR(sti.dFechaHoraAud)añoAprobado,
		COUNT(st.sNumeroTramite)numeroTramite,

		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = sccm.dFechaAprobacion,
		[Fecha Vencimiento] = sccm.dFechaVencimiento,
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad

	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimProrroga spr ON sti.sNumeroTramite = spr.sNumeroTramite
	LEFT JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		spa.sNombre IS NOT NULL
		AND sti.sEstadoActual = 'A'
		AND sti.dFechaHoraAud BETWEEN '20160101' AND '20211231'
		AND spr.sTipo = 'R'
	GROUP BY
		spa.sNombre,
		sp.sSexo,
		YEAR(sti.dFechaHoraAud)
)
SELECT * FROM tmp_prr
--=============================================================================================================================*/

