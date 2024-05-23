/*
	► CCM `P`:
	► Etapas: Antes `IMPRESIÓN`
	10 | MESA DE PARTES
	11 | RECEPCIÓN DINM
	12 | ASOCIACION BENEFICIARIO
	4  | TOMA DE IMAGENES
	46 | EVALUACIÓN
	13 | INTERPOL
	22 | CONFORMIDAD SUB-DIREC.INMGRA.
	23 | CONFORMIDAD DIREC.INMGRACION.
	24 | PAGOS, FECHA Y NRO RD.
	15 | AUTORIZAR IMPRESION
*/
/*=======================================================================================================================================================================================*/



SELECT
	st.sNumeroTramite,
	sd.sNombre [sDependencia],
	stt.sDescripcion [sTipoTramite],
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
	[sEstado_Eval] = (SELECT 
						TOP 1 
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
						ORDER BY setai.dFechaHoraInicio DESC),
	sevalti.sEstado [sEstadoEval 2]
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SImPersona sp ON st.uIdPersona = sp.uIdPersona
JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimEvaluarTramiteInm sevalti ON st.sNumeroTramite = sevalti.sNumeroTramite 
JOIN SimEtapa se ON sti.nIdEtapaActual = se.nIdEtapa
JOIN SimPreTramiteinm sprea ON st.sNumeroTramite = sprea.sNumeroTramite
WHERE
	st.nIdTipoTramite = 58 --CCM
	AND sti.sEstadoActual = 'P'
	AND sevalti.bActivo = 1
	AND sevalti.sEstado = 'A'
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




/*► Test: SimEtapaTramiteInm  ... */
-- CM210014190 | HA210013820 | LM210663457 | PU210020398 | LM220273258 | PC210005461
-- 2021-10-07 09:29:28.967: 0 | 2021-12-17 14:04:11.810: 1
SELECT se.sDescripcion [sEtapa], seti.* FROM SimEtapaTramiteInm seti 
JOIN SimEtapa se ON seti.nIdEtapa = se.nIdEtapa
WHERE 
	seti.nIdEtapa = 46
	AND seti.sNumeroTramite = 'LM220005242'
ORDER BY seti.dFechaHoraInicio

/*► Test: SimPreTramiteinm  ... */
-- CM210014190 | HA210013820 | LM210663457 | PU210020398 | LM220273258 | PC210005461
SELECT * FROM SimPreTramiteInm spti WHERE spti.sNumeroTramite = 'LM220005242'

/*► Test: SimEvaluarTramiteInm  ... */
-- CM210014190 | HA210013820 | LM210663457 | PU210020398 | LM220273258 | PC210005461

--2021-10-07 09:29:29.863:1 | 2021-12-17 14:56:22.877:0
--SELECT * FROM SimEvaluarTramiteInm seti.sNumeroTramite = 'LM220219718'
SELECT 
	seti.*
	--setapai.*
FROM SimEvaluarTramiteInm seti 
JOIN SimEtapaTramiteInm setapai ON seti.sNumeroTramite = setapai.sNumeroTramite
WHERE 
	setapai.nIdEtapa = 46 -- Evaluación
	AND seti.sNumeroTramite = 'LM220027960' -- LM220027229 LM220027960
	--AND setapai.bActivo = 1
	--AND seti.bActivo = 1




SELECT * FROM SimEtapaTramiteInm seti 
WHERE 
	--seti.dFechaHoraInicio >= '2022-01-01 00:00:00'
	--AND seti.sEstado = 'I'
	--AND seti.dFechaHoraFin IS NULL
	seti.sNumeroTramite = 'TU210023288'
	AND EXISTS (SELECT TOP 1 1 FROM SimEtapaTramiteInm setai 
			    WHERE 
					setai.sNumeroTramite = 'TU210023288'
					AND setai.nIdEtapa = 46 -- Evaluación
					AND setai.nIdUsrFinaliza IS NULL -- Indicador, etapa no esta finalizada; Nota: Una etapa en estado `I`, puede estar finalizada ...
				ORDER BY setai.dFechaHoraInicio DESC)







/*► Test-01 ... */
SELECT 
	sett.nSecuencia,
	st.sNumeroTramite
	--se.sDescripcion [sEtapa]
FROM SimTramite st
JOIN SimEtapaTipoTramite sett ON st.nIdTipoTramite = sett.nIdTipoTramite
--JOIN SimEtapaTramiteInm setapti ON st.sNumeroTramite = setapti.sNumeroTramite
--JOIN SimEtapa se ON setapti.nIdEtapa = se.nIdEtapa
WHERE
	st.sNumeroTramite = 'LM220005242'
ORDER BY 
	sett.nSecuencia

SELECT * FROM SimPreTramiteinm WHERE sNumeroTramite = 'LM210189718'
SELECT * FROM SimPreTramiteinm 
WHERE sNumeroTramite = 'LM220144672'

--SELECT LAST_VALUE(setai.sEstado) OVER (ORDER BY setai.dFechaHoraInicio) 
SELECT setai.sEstado
FROM SimEtapaTramiteInm setai WHERE setai.sNumeroTramite = 'LM220144672' AND setai.nIdEtapa = '46'

SELECT 
	seti.*,
	[nContarDupl] = (ROW_NUMBER() OVER () )
FROM SimEtapaTramiteInm seti

/*► Test-02 ...*/
SELECT 
	se.nIdEtapa,
	se.sDescripcion [sEtapa]
FROM SimEtapaTipoTramite sett
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE
	sett.nIdTipoTramite = 58
ORDER BY
	sett.nSecuencia
/*=======================================================================================================================================================================================*/

SELECT * FROM SimDependencia sd WHERE sd.sNombre LIKE '%chic%'