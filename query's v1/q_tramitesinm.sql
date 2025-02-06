USE SIM
GO

/*=================================================================================================================================================================================

	→ 34  |	PAG	| PAGO TASA ANUAL EXTRANJERÍA
	→ 39  |	PEV | PERMISO DE VIAJE
	→ 55  | SOL | SOLICITUD DE VISA
	→ 56  | PRP | PRORROGA DE PERMANENCIA
	→ 57  | PRR | PRORROGA DE RESIDENCIA
	→ 58  | CCM | CAMBIO DE CALIDAD MIGRATORIA
	→ 61  |	PEF	| PERMISO ESP. FIRMAR CONTRATOS
	→ 62  | INS | INSCR.REG.CENTRAL EXTRANJERÍA
	→ 65  |	EXT	| EXONERACIÓN PAGO TASA ANUAL
	→ 92  | PTV | PERMISO TEMPORAL DE PERMANENCIA - VENEZOLANOS
	→ 105 | ETP | ENTREGA DE CARNÉ DE PTP
	→ 113 | CPP | REGULARIZACION DE EXTRANJEROS
=================================================================================================================================================================================*/

DROP TABLE IF EXISTS BD_SIRIM.dbo.RimTramiteInm
;WITH cte_tramites_inm AS (-- STEP-01: ...

	SELECT st.* FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	WHERE 
		st.nIdTipoTramite IN (34, 39, 55, 56, 57, 58, 61, 62, 65, 92, 105, 113)
		AND st.dFechaHoraReg >= '2016-01-01 00:00:00.000'
		
), cte_solicitudes_inm AS (

	SELECT
		[nAñoSol] = DATEPART(YYYY, st.dFechaHoraReg),
		[nMesSol] = DATEPART(MM, st.dFechaHoraReg),
		sp.sSexo,
		[sRangoEdad] = CASE
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 17 THEN '1 - 17'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 30 THEN '18 - 30'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 40 THEN '31 - 40'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 60 THEN '41 - 60'
							ELSE  '61 a más'
					   END,
		st.nIdTipoTramite,
		[nTotalSolicitudes] = COUNT(1)
	FROM cte_tramites_inm st
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	GROUP BY
		DATEPART(YYYY, st.dFechaHoraReg),
		DATEPART(MM, st.dFechaHoraReg),
		sp.sSexo,
		CASE
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 17 THEN '1 - 17'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 30 THEN '18 - 30'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 40 THEN '31 - 40'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 60 THEN '41 - 60'
			ELSE  '61 a más'
		END,
		st.nIdTipoTramite

), cte_solicitudes_inm_P AS (

	SELECT
		[nAñoTram] = DATEPART(YYYY, st.dFechaHoraReg),
		[nMesTram] = DATEPART(MM, st.dFechaHoraReg),
		sp.sSexo,
		[sRangoEdad] = CASE
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 17 THEN '1 - 17'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 30 THEN '18 - 30'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 40 THEN '31 - 40'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 60 THEN '41 - 60'
							ELSE  '61 a más'
					   END,
		st.nIdTipoTramite,
		[nTotal(P)] = COUNT(1)
	FROM cte_tramites_inm st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	WHERE
		sti.sEstadoActual = 'P'
	GROUP BY
		DATEPART(YYYY, st.dFechaHoraReg),
		DATEPART(MM, st.dFechaHoraReg),
		sp.sSexo,
		CASE
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 17 THEN '1 - 17'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 30 THEN '18 - 30'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 40 THEN '31 - 40'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, st.dFechaHoraReg) <= 60 THEN '41 - 60'
			ELSE  '61 a más'
		END,
		st.nIdTipoTramite

), cte_solicitudes_inm_A AS (

	SELECT
		[nAñoFin] = DATEPART(YYYY, sti.dFechaFin),
		[nMesFin] = DATEPART(MM, sti.dFechaFin),
		sp.sSexo,
		[sRangoEdad] = CASE
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 17 THEN '1 - 17'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 30 THEN '18 - 30'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 40 THEN '31 - 40'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 60 THEN '41 - 60'
							ELSE  '61 a más'
					   END,
		st.nIdTipoTramite,
		[nTotal(A)] = COUNT(1)
	FROM cte_tramites_inm st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	WHERE
		sti.sEstadoActual = 'A'
	GROUP BY
		DATEPART(YYYY, sti.dFechaFin),
		DATEPART(MM, sti.dFechaFin),
		sp.sSexo,
		CASE
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 17 THEN '1 - 17'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 30 THEN '18 - 30'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 40 THEN '31 - 40'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 60 THEN '41 - 60'
			ELSE  '61 a más'
		END,
		st.nIdTipoTramite

), cte_solicitudes_inm_D AS (

	SELECT
		[nAñoFin] = DATEPART(YYYY, sti.dFechaFin),
		[nMesFin] = DATEPART(MM, sti.dFechaFin),
		sp.sSexo,
		[sRangoEdad] = CASE
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 17 THEN '1 - 17'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 30 THEN '18 - 30'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 40 THEN '31 - 40'
							WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 60 THEN '41 - 60'
							ELSE  '61 a más'
					   END,
		st.nIdTipoTramite,
		[nTotal(D)] = COUNT(1)
	FROM cte_tramites_inm st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
	WHERE
		sti.sEstadoActual = 'D'
	GROUP BY
		DATEPART(YYYY, sti.dFechaFin),
		DATEPART(MM, sti.dFechaFin),
		sp.sSexo,
		CASE
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 1 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 17 THEN '1 - 17'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 18 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 30 THEN '18 - 30'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 31 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 40 THEN '31 - 40'
			WHEN DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) >= 41 AND DATEDIFF(YYYY, sp.dFechaNacimiento, sti.dFechaFin) <= 60 THEN '41 - 60'
			ELSE  '61 a más'
		END,
		st.nIdTipoTramite

), cte_joins_inm AS (

	SELECT
		s.nIdTipoTramite,
		[nAño] = s.nAñoSol,
		[nMes] = s.nMesSol,
		s.sSexo,
		s.sRangoEdad,
		s.nTotalSolicitudes,
		p.[nTotal(P)],
		a.[nTotal(A)],
		d.[nTotal(D)]
	FROM cte_solicitudes_inm s
	LEFT JOIN cte_solicitudes_inm_P p ON s.nAñoSol = p.nAñoTram AND s.nMesSol = p.nMesTram AND s.nIdTipoTramite = p.nIdTipoTramite AND s.sSexo = p.sSexo AND s.sRangoEdad = p.sRangoEdad
	LEFT JOIN cte_solicitudes_inm_A a ON s.nAñoSol = a.nAñoFin AND s.nMesSol = a.nMesFin AND s.nIdTipoTramite = a.nIdTipoTramite AND s.sSexo = a.sSexo AND s.sRangoEdad = a.sRangoEdad
	LEFT JOIN cte_solicitudes_inm_D d ON s.nAñoSol = d.nAñoFin AND s.nMesSol = d.nMesFin AND s.nIdTipoTramite = d.nIdTipoTramite AND s.sSexo = d.sSexo AND s.sRangoEdad = d.sRangoEdad

) SELECT 
	[sTipoTramite] = UPPER(stt.sDescripcion),
	inm.*
	INTO BD_SIRIM.dbo.RimTramiteInm
FROM cte_joins_inm inm
JOIN SimTipoTramite stt ON inm.nIdTipoTramite = stt.nIdTipoTramite



-- Test ...
SELECT 
	inm.sTipoTramite,
	inm.nAño,
	[nTotalSolicitudes] = SUM(inm.nTotalSolicitudes),
	[nTotal(P)] = SUM(inm.[nTotal(P)]),
	[nTotal(A)] = SUM(inm.[nTotal(A)]),
	[nTotal(D)] = SUM(inm.[nTotal(D)])
FROM BD_SIRIM.dbo.RimTramiteInm inm
WHERE inm.nAño BETWEEN 2016 AND 2023
GROUP BY
	inm.sTipoTramite,
	inm.nAño
ORDER BY
	inm.nAño
/*==================================================================================================================================================================================================*/
