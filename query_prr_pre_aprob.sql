-- =============================================================================================================================================
-- ◄► PRR Pre-Aprobados
-- =============================================================================================================================================
SELECT
	st.sNumeroTramite,
	sd.sNombre [sDependencia],
	stt.sDescripcion [sTipoTramite],
	scm.sDescripcion [sCalidadMigratoria],
	st.dFechaHoraReg [dFechaRegistro],
	[sEstadoActual] = CASE sti.sEstadoActual WHEN 'P' THEN 'PENDIENTE'
											 WHEN 'A' THEN 'APROBADO'
											 WHEN 'B' THEN 'ABANDONADO'
											 WHEN 'D' THEN 'DENEGADO'
											 WHEN 'E' THEN 'DESISTIDO'
											 WHEN 'N' THEN 'NO PRESENTADO'
											 WHEN 'R' THEN 'ANULADO'
										END,
	se.sDescripcion [sEtapaActual],
	[sEstadoEtapaActual] = (SELECT 
							TOP 1
							[sEstadoEtapa] = CASE setai.sEstado 
												 WHEN 'F' THEN 'FINALIZADO'
												 WHEN 'I' THEN 'INICIADO'
											END
						  FROM SimEtapaTramiteInm setai 
						  WHERE 
							setai.sNumeroTramite = st.sNumeroTramite 
							AND setai.nIdEtapa = sti.nIdEtapaActual 
							AND setai.bActivo = 1
						  ORDER BY setai.dFechaHoraAud DESC),
	dFechaPreAprob = sprea.dFechaPre,
	[sEstadoPreAprob] = CASE sprea.sEstadoPre 
							WHEN 'P' THEN 'PENDIENTE'
							WHEN 'A' THEN 'APROBADO'
							WHEN 'B' THEN 'ABANDONADO'
							WHEN 'D' THEN 'DENEGADO'
							WHEN 'E' THEN 'DESISTIDO'
							WHEN 'N' THEN 'NO PRESENTADO'
							WHEN 'R' THEN 'ANULADO'
					    END,
	[dFechaCosulta] = GETDATE(),
	[nDiasTranscurridos] = DATEDIFF(DAY, st.dFechaHoraReg, GETDATE()),
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,

	[dFecha_Derivación_Eval] = (SELECT TOP 1 setai.dFechaHoraInicio FROM SimEtapaTramiteInm setai 
								WHERE 
									setai.sNumeroTramite = st.sNumeroTramite AND setai.nIdEtapa = 22 -- 22 | EVALUACIÓN CONFORMIDAD SUB-DIREC.INMGRA
									AND setai.bActivo = 1
									AND setai.sEstado = 'I'
								ORDER BY setai.dFechaHoraInicio DESC)
	/*[dFecha_Aprob_Eval] = (SELECT TOP 1 setai.dFechaHoraFin FROM SimEtapaTramiteInm setai 
						   WHERE 
								setai.sNumeroTramite = st.sNumeroTramite AND setai.nIdEtapa = 22 -- 22 | EVALUACIÓN CONFORMIDAD SUB-DIREC.INMGRA
								AND setai.bActivo = 1
								AND setai.sEstado = 'I'
						   ORDER BY setai.dFechaHoraInicio DESC),
	[sEstado_Eval] = (SELECT 
						TOP 1 
						CASE setai.sEstado 
							WHEN 'F' THEN 'FINALIZADO'
							WHEN 'I' THEN 'INICIADO'
						END
						FROM SimEtapaTramiteInm setai 
						WHERE 
							setai.sNumeroTramite = st.sNumeroTramite 
							AND setai.nIdEtapa = 22 -- 22 | EVALUACIÓN CONFORMIDAD SUB-DIREC.INMGRA
							AND setai.bActivo = 1
							AND setai.sEstado = 'I'
						ORDER BY setai.dFechaHoraInicio DESC)*/
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
JOIN SimCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimEvaluarTramiteInm sevalti ON st.sNumeroTramite = sevalti.sNumeroTramite 
JOIN SimEtapa se ON sti.nIdEtapaActual = se.nIdEtapa
JOIN SimPreTramiteinm sprea ON st.sNumeroTramite = sprea.sNumeroTramite
WHERE
	st.nIdTipoTramite = 57 --PRR
	AND sti.sEstadoActual = 'A'
	AND sevalti.bActivo = 1
	-- AND sevalti.sEstado = 'A' -- Todos los estados ...
	AND sprea.sEstadoPre = 'P'
	-- AND sti.nIdEtapaActual = 22 -- 22 | EVALUACIÓN CONFORMIDAD SUB-DIREC.INMGRA
	AND EXISTS (SELECT TOP 1 1 FROM SimEtapaTramiteInm setati 
			    WHERE 
					setati.sNumeroTramite = st.sNumeroTramite 
					AND setati.nIdEtapa = 22 -- 22 | EVALUACIÓN CONFORMIDAD SUB-DIREC.INMGRA
					AND setati.bActivo = 1
					AND setati.sEstado = 'I' -- Estado `Iniciado`
					AND setati.nIdUsrFinaliza IS NULL -- Indicador viable del estado; Nota: Si el estado de la etapa es `I`, podría estar finalizada ...
				ORDER BY setati.dFechaHoraInicio DESC)
	AND DATEDIFF(DAY, st.dFechaHoraReg, GETDATE()) >= 5 -- Plazo de atención días ...


/*► 
	Test: ... 
	AI220085782
	IL220000017
	IL220000031
	IL220000076
	IL220000078
*/
/*► PRR: Aprobados ... */
SELECT 
	TOP 10
	-- COUNT(1) 
	st.sNumeroTramite
FROM SimTramite st 
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
WHERE 
	st.nIdTipoTramite = 57 --PRR
	AND st.sIdDependencia = '25'
	AND sti.sEstadoActual = 'A'
	AND st.dFechaHoraReg >= '2022-10-01 00:00:00.000'

/*► 
	PRR: Pre-Aprobados ... 
	RECEPCIÓN DINM | 11
	ASOCIACION BENEFICIARIO | 12
	ACTUALIZAR DATOS BENEFICIARIO | 14
	CONFORMIDAD SUB-DIREC.INMGRA | 22
	PAGOS, FECHA Y NRO RD | 24
*/

SELECT 
	-- TOP 10
	-- COUNT(1) 
	st.sNumeroTramite
FROM SimTramite st 
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPreTramiteInm spre ON st.sNumeroTramite = spre.sNumeroTramite
WHERE 
	st.nIdTipoTramite = 57 
	AND st.dFechaHoraReg >= '2022-01-01 00:00:00.000'
	AND sti.sEstadoActual = 'A'
	AND sti.nIdEtapaActual = 22


SELECT 
	se.sDescripcion [sEtapa],
	seti.* 
FROM SimEtapaTramiteInm seti
JOIN SimEtapa se ON seti.nIdEtapa = se.nIdEtapa
WHERE 
	seti.sNumeroTramite = 'AQ220000003'
-- =============================================================================================================================================

-- PRR en evaluación ...
SELECT 
	--TOP 10
	st.sNumeroTramite,
	sti.sEstadoActual,
	stt.sDescripcion [sTipoTramite],
	scm.sDescripcion [sCalidadMigratoria],
	se.sDescripcion [sEtapaTramite],
	seti.bCompletado,
	[sEstadoEvaluacion] = CASE seti.sEstado
								WHEN 'A' THEN 'APROBADO'
								WHEN 'R' THEN 'RECEPCIONADO'
								WHEN 'I' THEN 'INICIADO' 
								WHEN 'C' THEN 'CULMINADO'
								WHEN 'E' THEN 'EVALUADO' 
						  END,
	seti.dFechaAprobacion [dFechaAprobaciónEvaluacion],
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
JOIN SimEtapa se ON sti.nIdEtapaActual = se.nIdEtapa
JOIN SimEvaluarTramiteInm seti ON st.sNumeroTramite = seti.sNumeroTramite
WHERE
	st.nIdTipoTramite = 57 -- PRR
	--AND st.sIdDependencia = '25'

	AND st.dFechaHoraReg >= '2022-01-01 00:00:00.000'
	AND sti.sEstadoActual = 'P'
	AND sti.nIdEtapaActual IN ('11', '12', '14', '22')
	AND seti.bActivo = 1
	-- AND seti.bCompletado = 1
	-- AND seti.nIdOperadorDesig IS NOT NULL
	-- AND seti.dFechaDerivacion IS NOT NULL
	AND seti.dFechaAprobacion IS NOT NULL

SELECT TOP 1 * FROM SimEvaluarTramiteInm

SELECT 
	seti.sEstado,
	COUNT(1)
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimEvaluarTramiteInm seti ON st.sNumeroTramite = seti.sNumeroTramite
WHERE
	st.nIdTipoTramite = 57 -- PRR
	AND st.dFechaHoraReg >= '2022-01-01 00:00:00.000'
	--AND sti.sEstadoActual = 'P'
GROUP BY seti.sEstado

-- ...
SELECT TOP 10 seval.* FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimEvaluarTramiteInm seval ON sti.sNumeroTramite = seval.sNumeroTramite
WHERE
	st.nIdTipoTramite = 57 --PRR
	AND st.sIdDependencia = '25'
	AND sti.sEstadoActual = 'A'
	AND sti.dFechaFin BETWEEN '2022-10-01 00:00:00.000' AND '2022-10-31 23:59:59.999'
ORDER BY
	st.dFechaHoraReg DESC

-- PRR Aprobados ...
/*
	LM230289555
	LM230288063
	LM230288037
	LM230287622
	LM230287615
	LM220766898
	LM220766897
	LM220766891
	LM220765485
	LM220765481
	LM220646660
	LM220646339
	LM220646320
	LM220646152
	LM220646081
*/
SELECT 
	[sEtapaActual] = se.sDescripcion,
	* 
FROM SimEtapaTramiteInm seti
JOIN SimEtapa se ON seti.nIdEtapa = se.nIdEtapa
WHERE
	seti.sNumeroTramite = 'LM220646081'
ORDER BY
	seti.dFechaHoraInicio ASC




-- ...
SELECT * FROM SimDependencia sd
WHERE
	sd.sNombre LIKE '%tara%'


-- MARIA ELENA PURIZAGA GUZMAN DE SEMINARIO
SELECT * FROM SimPersona sp
WHERE
	sp.sNombre LIKE '%'
	AND sp.sPaterno LIKE '%PURI%'
	AND sp.sMaterno LIKE '%GUZM%'
