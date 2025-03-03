/*░
--» Nacionalizados ... 
=============================================================================================================================*/

DROP TABLE IF EXISTS #tmp_nac
;WITH tmp_nac AS
(
	SELECT

		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = st.dFechaHora,
		[Calidad Migratoria] = scm.sDescripcion,
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = stin.sNombrePerNac,
		[Ape Pat] = stin.sPaternoPerNac,
		[Ape Mat] = stin.sMaternoPerNac,
		[Sexo] = stin.sSexoPerNac,
		[Fec Nac] = stin.dFechaNacPerNac,
		[Nacionalidad] = stin.sIdPaisNacimiento

	FROM SimTramite st
	JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
	JOIN SimTituloNacionalidad stin ON stn.sNumeroTramite = stin.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SImCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
	JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	WHERE
		stn.sEstadoActual = 'A'
		AND sp.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)
		AND st.dFechaHora >= '2016-01-01 00:00:00.000'
		
) SELECT * INTO #tmp_nac FROM tmp_nac


-- Test: ...
SELECT * FROM #tmp_nac

--=============================================================================================================================*/

-- 2. Trámites de nacionalización por estados
--===========================================================================================================================

SELECT

	[Año Trámite] = DATEPART(YYYY, st.dFechaHora),
	[Estado] = (
					CASE tn.sEstadoActual
						WHEN 'P' THEN 'PENDIENTE'
						WHEN 'R' THEN 'ANULADO'
						WHEN 'D' THEN 'DENEGADO'
						WHEN 'A' THEN 'APROBADO'
						WHEN 'E' THEN 'DESISTIDO'
						WHEN 'B' THEN 'ABANDONO'
						WHEN 'N' THEN 'NO PRESENTADA'
					END
	),
	[Tipo Trámite] = stt.sDescripcion,
	[Total] = COUNT(1)

FROM SimTramite st
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimTramiteNac tn ON st.sNumeroTramite = tn.sNumeroTramite
WHERE
	st.bCancelado = 0
	AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79, 86) -- 86 | RENUNCIA A LA NACIONALIDAD PERUANA
GROUP BY
	DATEPART(YYYY, st.dFechaHora),
	CASE tn.sEstadoActual
		WHEN 'P' THEN 'PENDIENTE'
		WHEN 'R' THEN 'ANULADO'
		WHEN 'D' THEN 'DENEGADO'
		WHEN 'A' THEN 'APROBADO'
		WHEN 'E' THEN 'DESISTIDO'
		WHEN 'B' THEN 'ABANDONO'
		WHEN 'N' THEN 'NO PRESENTADA'
	END,
	stt.sDescripcion
		


--===========================================================================================================================

