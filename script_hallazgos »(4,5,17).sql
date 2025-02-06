USE SIM
GO

--> Servidor   : 172.27.0.124
--> BaseDatos  : SIM; BD_SIRIM

/*░
	→ 1. Pasaportes electrónicos vencidos con estado `E | Emitido` en SimPasaporte ...
================================================================================================================================*/

-- 1.1
DROP TABLE IF EXISTS #tmp_pase_migradosvencidos_estado_E
SELECT 
	p.*
INTO #tmp_pase_migradosvencidos_estado_E
FROM SimPasaporte p
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
WHERE
	t.bCancelado = 0
	-- AND st.bCulminado = 1
	AND t.nIdTipoTramite = 90 -- 90 | Expedición de Pasaporte Electrónico
	AND p.sEstadoActual = 'E' -- Emitido
	AND p.dFechaExpiracion != '1900-01-01 00:00:00.000'
	AND DATEDIFF(DD, GETDATE(), p.dFechaExpiracion) <= 0

-- 1.2 Final: ...
SELECT 
	pe.sNombre,
	pe.sPaterno,
	pe.sMaterno,
	pe.sSexo,
	pe.dFechaNacimiento,
	pe.sNumeroTramite,
	pe.sPasNumero,
	pe.sEstadoActual,
	pe.dFechaEmision,
	pe.dFechaExpiracion
FROM #tmp_pase_migradosvencidos_estado_E pe

--================================================================================================================================*/

/*░
	→ 2. Pasaportes mecanizados vencidos con estado `E | Emitido` en SimPasaporte ...
================================================================================================================================*/

-- Base: 3,954,465
-- 2.1	EXPEDICION DE PASAPORTE
DROP TABLE IF EXISTS #tmp_pasm_migradosvencidos_estado_E
SELECT 
	p.*
	INTO #tmp_pasm_migradosvencidos_estado_E 
FROM SimPasaporte p 
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
WHERE
	t.bCancelado = 0
	-- AND st.bCulminado = 1
	AND t.nIdTipoTramite = 2 -- 2 | EXPEDICION DE PASAPORTE
	AND p.sEstadoActual = 'E' -- Emitido
	AND p.dFechaExpiracion != '1900-01-01 00:00:00.000'
	AND DATEDIFF(DD, GETDATE(), p.dFechaExpiracion) <= 0

-- 2.2 Final: ...
DROP TABLE IF EXISTS tmp_pasm_migradosvencidos_estado_E
SELECT 
	spas.sNombre,
	spas.sPaterno,
	spas.sMaterno,
	spas.sSexo,
	spas.dFechaNacimiento,
	spas.sNumeroTramite,
	spas.sPasNumero,
	spas.sEstadoActual,
	spas.dFechaEmision,
	spas.dFechaExpiracion
	INTO tmp_pasm_migradosvencidos_estado_E
FROM #tmp_pasm_migradosvencidos_estado_E spas
ORDER BY spas.sNumeroTramite
OFFSET 1000002 ROWS
FETCH NEXT 500000 ROWS ONLY

--=================================================================================================================================


/*░
	→ 3. Trámites con uIdPersona `00000000-0000-0000-0000-000000000000` ...
-- ================================================================================================================================*/


SELECT 
	-- 1
   [Nombres] = '',
   [Apellido 1] = '',
   [Apellido 2] = '',
   [Sexo] = '',
   [Fecha Nacimiento] = '',

   -- Aux ...
   [Número Trámite] = f.sNumeroTramite,
   [Id Persona] = tf.uIdPersona,
   [Tipo Trámite] = tt.sDescripcion,
   [Etapa Actual] = e.sDescripcion
   -- [Estado Etapa] = f.sEstado
	
	-- f.* 
FROM (

	SELECT

		ue.*,

		-- Aux
		[#] = ROW_NUMBER() OVER (PARTITION BY ue.sNumeroTramite ORDER BY ue.nIdEtapaTramite ASC),
		[nCantEtapa] = COUNT(1) OVER (PARTITION BY ue.sNumeroTramite),
		[nIdEtapaActual] = FIRST_VALUE(ue.nIdEtapa) OVER (
																				PARTITION BY ue.sNumeroTramite
																				ORDER BY ue.nIdEtapaTramite ASC
																				ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
																			)

	FROM (

		SELECT -- Inm
			ei.nIdEtapaTramite,
			ei.nIdEtapa,
			ei.bActivo,
			ei.sNumeroTramite,
			ei.sEstado
		FROM SimEtapaTramiteInm ei
		UNION ALL
		SELECT -- Nac
			en.nIdEtapaTramite,
			en.nIdEtapa,
			en.bActivo,
			en.sNumeroTramite,
			en.sEstado
		FROM SimEtapaTramiteNac en

	) ue
	WHERE 
		ue.bActivo = 1
		-- AND ue.sEstado = 'F'
		AND ue.sNumeroTramite IN (
											SELECT 
												t.sNumeroTramite
											FROM SimTramite t
											WHERE
												t.bCancelado = 0
												AND t.uIdPersona = '00000000-0000-0000-0000-000000000000'
		)
) f
JOIN SimTramite tf ON tf.sNumeroTramite = f.sNumeroTramite
JOIN SimTipoTramite tt ON tf.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON f.nIdEtapa = e.nIdEtapa
WHERE
	f.[#] = 1 -- Primera etapa
	AND f.nCantEtapa = 1 -- Única etapa

-- ================================================================================================================================*/
