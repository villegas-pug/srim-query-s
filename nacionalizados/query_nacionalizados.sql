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