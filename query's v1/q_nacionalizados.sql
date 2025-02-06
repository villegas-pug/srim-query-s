USE SIM
GO

-- ░ Nacionalizados 
-- ========================================================================================================================================

DROP TABLE IF EXISTS BD_SIRIM.dbo.RimNacionalizados
SELECT TOP 0 * INTO BD_SIRIM.dbo.RimNacionalizados FROM
(
	SELECT
		st.uIdPersona,

		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Impresión] = (
								SELECT TOP 1 COALESCE(setn.dFechaHoraFin, setn.dFechaHoraAud) FROM SimEtapaTramiteNac setn 
								WHERE 
									setn.sNumeroTramite = st.sNumeroTramite
									AND setn.nIdEtapa = 6 -- 6 | IMPRESION
									AND setn.sEstado = 'F'
									AND setn.bActivo = 1
								ORDER BY
									setn.dFechaHoraAud DESC
							),
		[Tipo Trámite] = stt.sDescripcion,

		-- Aux
		[Estado] = stn.sEstadoActual,

		[Dependencia] = sd.sNombre,
		[Sexo] = sp.sSexo,
		[Fec Nacimiento] = sp.dFechaNacimiento,
		[Id Nacionalidad] = spa.sIdPais,
		[Nacionalidad] = spa.sNacionalidad,
		[Domicilio] = su.sNombre,
		[Dirección Domiciliaria] = se.sDomicilio
	FROM SimTramite st
	JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
	JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	LEFT JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	LEFT JOIN SimExtranjero se ON st.uIdPersona = se.uIdPersona
	LEFT JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
	LEFT JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	WHERE
		-- stn.sEstadoActual IN ('A', 'P')
		stn.sEstadoActual = 'A'
		AND EXISTS (
				SELECT 1 FROM SimEtapaTramiteNac setn 
				WHERE 
					setn.sNumeroTramite = st.sNumeroTramite
					AND setn.nIdEtapa = 6 -- 6 | IMPRESION
					AND setn.sEstado = 'F'
					AND setn.bActivo = 1
			)
		AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)
		AND (
				SELECT TOP 1 DATEPART(YYYY, setn.dFechaHoraFin) FROM SimEtapaTramiteNac setn 
				WHERE 
					setn.sNumeroTramite = st.sNumeroTramite
					AND setn.nIdEtapa = 6 -- 6 | IMPRESION
					AND setn.sEstado = 'F'
					AND setn.bActivo = 1
				ORDER BY setn.dFechaHoraFin DESC
			) >= 2016
) tmp_nac
ORDER BY
	tmp_nac.[Fecha Impresión]

-- Test ...

-- 1
SELECT * FROM BD_SIRIM.dbo.RimNacionalizados n
WHERE
	n.Estado = 'A'
	AND n.[Fecha Impresión] >= '2023-01-01'

-- 2. Residencia cancelada por nacionalización
-- 2.1 ...

;WITH cte_nacionalizados AS (
	SELECT 
		n.uIdPersona,
		[Año Impresión] = DATEPART(YYYY, n.[Fecha Impresión])
	FROM BD_SIRIM.dbo.RimNacionalizados n
	WHERE
		n.Estado = 'A'
) SELECT * FROM cte_nacionalizados PIVOT (
	COUNT(uIdPersona) FOR [Año Impresión] IN ([2009], [2010], [2011], [2012], [2013], [2014], [2015], [2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv

-- 2.2 Nacionalizados con residencia cancelada ...
;WITH cte_nacionalizados AS (
	SELECT 
		n.uIdPersona,
		[Año Impresión] = DATEPART(YYYY, n.[Fecha Impresión])
	FROM BD_SIRIM.dbo.RimNacionalizados n
	WHERE
	n.Estado = 'A'
	AND EXISTS(
		SELECT 1 FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		WHERE
			st.uIdPersona = n.uIdPersona
			AND st.bCancelado = 0
			AND sti.sEstadoActual = 'A'
			AND st.nIdTipoTramite = 45 -- 45 | CANC. PERMANENCIA/RESIDENCIA X OFICIO

	)
) SELECT * FROM cte_nacionalizados PIVOT (
	COUNT(uIdPersona) FOR [Año Impresión] IN ([2009], [2010], [2011], [2012], [2013], [2014], [2015], [2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv

-- 2.3 Nacionalizados sin residencia cancelada ...
;WITH cte_nacionalizados AS (
	SELECT 
		n.uIdPersona,
		[Año Impresión] = DATEPART(YYYY, n.[Fecha Impresión])
	FROM BD_SIRIM.dbo.RimNacionalizados n
	WHERE
		n.Estado = 'A'
		AND NOT EXISTS(
			SELECT 1 FROM SimTramite st
			JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
			WHERE
				st.uIdPersona = n.uIdPersona
				AND st.bCancelado = 0
				AND sti.sEstadoActual = 'A'
				AND st.nIdTipoTramite = 45 -- 45 | CANC. PERMANENCIA/RESIDENCIA X OFICIO

		)
) SELECT * FROM cte_nacionalizados PIVOT (
	COUNT(uIdPersona) FOR [Año Impresión] IN ([2009], [2010], [2011], [2012], [2013], [2014], [2015], [2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv

-- 3
SELECT * FROM SimTipoTramite stt
WHERE stt.sDescripcion LIKE '%canc%'
-- ========================================================================================================================================