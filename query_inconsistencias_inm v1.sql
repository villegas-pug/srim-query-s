USE [SIM]
GO

/*░
   1. ...
==================================================================================================================================================================*/

-- 126 | PERMISO TEMPORAL DE PERMANENCIA - RS109
SELECT  
	st.uIdPersona,
	[sDependencia] = sd.sNombre,
	[dFechaExpendiente] = st.dFechaHora,
	st.sNumeroTramite,
	sti.sEstadoActual,
	st.nIdTipoTramite
FROM SimTramite st
INNER JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
INNER JOIN SimDependencia sd ON st.sIdDependencia = sd.sIdDependencia
WHERE   
		st.bCancelado = 0
		AND st.nIdTipoTramite = 126 -- PERMISO TEMPORAL DE PERMANENCIA - RS109
		-- AND st.nIdTipoTramite = 113 -- CPP
		-- AND st.nIdTipoTramite = 58 -- CCM | 58
		AND sti.sEstadoActual = 'P'
		AND EXISTS (

			SELECT
				TOP 1 1 
			FROM dbo.SimEtapaTramiteInm seti
			WHERE 
				seti.sNumeroTramite= st.sNumeroTramite 
				AND seti.bActivo = 1
				AND seti.nIdEtapa = 80 -- ENTREGA DE CARNÉ C.P.P.	| 80 → RS109
				-- AND seti.nIdEtapa = 63 -- ENTREGA DE CARNÉ P.T.P. | 63
				-- AND seti.nIdEtapa = 17 -- ENTREGA DE CARNET EXTRANJERIA	| 17 → CMM
				AND seti.sEstado = 'F' 

		)


-- Test ...
-- 1
SELECT 
	se.sDescripcion,
	sett.*
FROM SimEtapaTipoTramite sett
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE
	sett.nIdTipoTramite = 126
	-- sett.nIdTipoTramite = 113
	-- sett.nIdTipoTramite = 58
ORDER BY
	sett.nSecuencia

-- 2
-- 126 | PERMISO TEMPORAL DE PERMANENCIA - RS109
-- 113 | REGULARIZACION DE EXTRANJEROS
SELECT * FROM SimTipoTramite stt
WHERE
	stt.sDescripcion LIKE '%rs%'

-- 18,755,434
SELECT COUNT(1) FROM SimTramite ;
-- ==================================================================================================================================================================*/


/*░
   2. ...
==================================================================================================================================================================*/

INSERT INTO SimPersona DEFAULT VALUES


-- ==================================================================================================================================================================*/