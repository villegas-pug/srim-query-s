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
/*=======================================================================================================================================*/
SELECT 
	st.sNumeroTramite,
	stt.sDescripcion [sTipoTramite],
	sti.sEstadoActual,
	st.dFechaHoraReg [dFechaRegistro],
	[dFechaCosulta] = GETDATE(),
	[nDiasTranscurridos] = DATEDIFF(DAY, st.dFechaHoraReg, GETDATE()),
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento
FROM SimTramite st
JOIN SimPersona sp ON st.uIdPersona = sp.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPreTramiteinm sprea ON st.sNumeroTramite = sprea.sNumeroTramite
--JOIN SimEvaluarTramiteInm seti ON st.sNumeroTramite = seti.sNumeroTramite 
--JOIN SimEtapaTramiteInm setapti ON sti.sNumeroTramite = setapti.sNumeroTramite
WHERE
	st.nIdTipoTramite = 58
	AND sti.sEstadoActual = 'A'
	--AND sti.nIdEtapaActual IN (10, 11, 12, 4, 46, 13, 22, 23, 24, 15)
ORDER BY st.dFechaHoraReg

SELECT * FROM SimPreTramiteinm WHERE sNumeroTramite = 'LM210189718'
SELECT * FROM SimPreTramiteinm 
WHERE sNumeroTramite = 'LM220144672'

/*=======================================================================================================================================*/


/*► Test ...*/
SELECT 
	spas.sPasNumero,
	sp.sIdPaisNacionalidad, 
	sp.sIdPaisNacimiento,
	sp.sIdPaisResidencia,
	sp.* 
FROM SimMovMigra smm
JOIN  SimPersona sp ON smm.uIdPersona = sp.uIdPersona
JOIN SimPasaporte spas ON smm.sNumeroDoc = spas.sPasNumero
WHERE 
	sp.sNombre LIKE 'ANYELL%'
	AND sp.sPaterno LIKE 'SAN MIGUEL%'