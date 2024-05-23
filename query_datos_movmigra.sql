-- =========================================================================================================
-- sPaisNacimiento → `Marruecos`
-- =========================================================================================================
SELECT
	mm.uIdPersona,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacimiento,
	sp.sIdPaisNacionalidad,
	sprof.sDescripcion [sProfesion_Control_Migra],
	mm.dFechaControl,
	mm.sTipo [sTipoMov],
	mm.sIdPaisMov [sPaisProDest],
	mm.sIdDocumento [sTipoDocViaje],
	smv.sDescripcion [sMotivoViaje],
	[sDocViaje] = CONCAT('''', mm.sNumeroDoc),
	stran.sDescripcion [sTipoTransporte],
	sd.sNombre [sDendencia_Digita],
	su.sNombre [sOperador_Digita],
	mm.sObservaciones
FROM SimMovMigra mm
JOIN SimPersona sp ON mm.uIdPersona = sp.uIdPersona
JOIN SimDependencia sd ON mm.sIdDependencia = sd.sIdDependencia
JOIN SimViaTransporte stran ON mm.sIdViaTransporte = stran.sIdViaTransporte
JOIN SimProfesion sprof ON mm.sIdProfesion = sprof.sIdProfesion
JOIN SimUsuario su ON mm.nIdOperadorDigita = su.nIdOperador
JOIN SimMotivoViaje smv ON mm.nIdMotivoViaje = smv.nIdMotivoViaje
WHERE
	mm.bAnulado = 0
	AND mm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND mm.dFechaControl BETWEEN '2022-05-01 00:00:00.000' AND '2022-05-31 23:59:59.000'
	AND mm.sIdPaisNacimiento = 'MAR' -- Marruecos
ORDER BY 
	-- mm.uIdPersona, 
	mm.dFechaControl
-- =========================================================================================================

-- =========================================================================================================
-- sPaisNacimiento → ``
-- =========================================================================================================
SELECT
	mm.uIdPersona,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacimiento,
	sp.sIdPaisNacionalidad,
	sprof.sDescripcion [sProfesion_Control_Migra],
	mm.dFechaControl,
	mm.sTipo [sTipoMov],
	mm.sIdPaisMov [sPaisProDest],
	mm.sIdDocumento [sTipoDocViaje],
	[sDocViaje] = CONCAT('''', mm.sNumeroDoc),
	stran.sDescripcion [sTipoTransporte],
	sd.sNombre [sDendencia_Digita],
	su.sNombre [sOperador_Digita]
FROM SimMovMigra mm
JOIN SimPersona sp ON mm.uIdPersona = sp.uIdPersona
JOIN SimDependencia sd ON mm.sIdDependencia = sd.sIdDependencia
JOIN SimViaTransporte stran ON mm.sIdViaTransporte = stran.sIdViaTransporte
JOIN SimProfesion sprof ON mm.sIdProfesion = sprof.sIdProfesion
JOIN SimUsuario su ON mm.nIdOperadorDigita = su.nIdOperador
WHERE
	mm.bAnulado = 0
	AND mm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND mm.dFechaControl BETWEEN '2022-05-01 00:00:00.000' AND '2022-05-31 23:59:59.000'
	AND mm.sIdPaisNacimiento = 'MAR' -- Marruecos
ORDER BY 
	mm.uIdPersona, mm.dFechaControl
-- =========================================================================================================