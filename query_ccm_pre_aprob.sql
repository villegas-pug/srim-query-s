-- =============================================================================================================================================
-- ◄► CCM Pre-Aprobados
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
									setai.sNumeroTramite = st.sNumeroTramite AND setai.nIdEtapa = 46 -- Evaluación 
									AND setai.bActivo = 1
									AND setai.sEstado = 'I'
								ORDER BY setai.dFechaHoraInicio DESC),
	[dFecha_Aprob_Eval] = (SELECT TOP 1 setai.dFechaHoraFin FROM SimEtapaTramiteInm setai 
						   WHERE 
								setai.sNumeroTramite = st.sNumeroTramite AND setai.nIdEtapa = 46 -- Evaluación 
								AND setai.bActivo = 1
								AND setai.sEstado = 'I'
						   ORDER BY setai.dFechaHoraInicio DESC),
	[sEstado_Eval] = (
								SELECT TOP 1
								CASE setai.sEstado 
									WHEN 'F' THEN 'FINALIZADO'
									WHEN 'I' THEN 'INICIADO'
								END
								FROM SimEtapaTramiteInm setai 
								WHERE 
									setai.sNumeroTramite = st.sNumeroTramite 
									AND setai.nIdEtapa = 46 -- Evaluación
									AND setai.bActivo = 1
									AND setai.sEstado = 'I'
								ORDER BY setai.dFechaHoraInicio DESC
							)
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
	st.nIdTipoTramite = 58 --CCM
	AND sti.sEstadoActual = 'P'
	AND sevalti.bActivo = 1
	-- AND sevalti.sEstado = 'A' -- Todos los estados ...
	AND sprea.sEstadoPre = 'A'
	AND sti.nIdEtapaActual = 46 --EVALUACIÓN
	AND EXISTS (SELECT TOP 1 1 FROM SimEtapaTramiteInm setati 
			    WHERE 
					setati.sNumeroTramite = st.sNumeroTramite 
					AND setati.nIdEtapa = 46 -- Evaluación
					AND setati.bActivo = 1
					AND setati.sEstado = 'I' -- Estado `Iniciado`
					AND setati.nIdUsrFinaliza IS NULL -- Indicador viable del estado; Nota: Si el estado de la etapa es `I`, podría estar finalizada ...
				ORDER BY setati.dFechaHoraInicio DESC)


/*► Test:  ... */
SELECT stpa.sEstadoPre, COUNT(1) FROM SimPreTramiteinm stpa GROUP BY stpa.sEstadoPre

SELECT 
	seti.sEstado, 
	COUNT(1) [nTotal] 
FROM SimTramite st
JOIN SimEvaluarTramiteInm seti ON st.sNumeroTramite = seti.sNumeroTramite
WHERE
	st.nIdTipoTramite = 58 -- CM
GROUP BY seti.sEstado

SELECT * FROM SimEtapaTramiteInm seti WHERE seti.sNumeroTramite = 'CM210015090'
SELECT * FROM SimPreTramiteInm spre WHERE spre.sNumeroTramite = 'PC220000552'

/* ► SimPreTramiteInm → (E): Desistido
	CM210015090
	CS210014602
	CS210014602
	CY220009861
*/

/* ► SimPreTramiteInm → (B): Abandono
	PC220000552
	IL210001613
	TM210011359
	TM210011359
	CS220004546
	TU220000207
	TU220003643
	LM210421723
	LM210452777
*/

-- =============================================================================================================================================

	

