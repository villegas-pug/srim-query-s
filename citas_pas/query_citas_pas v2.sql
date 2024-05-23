USE CITASPAS
GO

-- Test ...
-- SELECT TOP 10 * FROM SimCitaWebNacional
-- SELECT TOP 10 * FROM SimRecibo
-- SELECT TOP 10 * FROM SimPagos

DECLARE @sTipoPago VARCHAR(55) = '%pasapor%'

-- SIM
SELECT TOP 10 * FROM SIM.dbo.SimTipoPago stp 
WHERE stp.sDescripcion LIKE @sTipoPago
ORDER BY stp.nIdTipoPago

-- CITASPAS
SELECT TOP 10 * FROM SimTipoPago stp 
WHERE stp.sDescripcion LIKE @sTipoPago
ORDER BY stp.nIdTipoPago

-- SIM
SELECT COUNT(1) FROM SIM.dbo.SimPagos spa
WHERE spa.sIdTipoPago IN (
   '1627', '1628', '5526'
)

-- CITAPAS
SELECT COUNT(1) FROM CITASPAS.dbo.SimPagos spa
WHERE spa.sIdTipoPago IN (
   '1627', '1628', '5526'
)

/*»
   1. 
-- ================================================================================================================================================================== */

-- Citas con pasaportes ...
SELECT

   -- COUNT(1)
   spa.*,
   [¿Tienen PAS-E?] = ( 
                        IIF(
                              EXISTS(
                                       SELECT 1 FROM SIM.dbo.SimPasaporte spas
                                       JOIN SIM.dbo.SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite 
                                       WHERE
                                          st.bCancelado = 0
                                          AND spas.sNumeroTramite = spa.sNumeroTramite
                                          AND st.nIdTipoTramite = 90 -- 90 | Expedición de Pasaporte Electrónico
                                          AND spas.sEstadoActual = 'E'
                                          AND spas.dFechaEmision >= spa.dFechaHora -- Fecha de emisión de pasaporte es posterior a fecha de pago ...
                              ),
                              'SI',
                              'NO'
                        )
   )

FROM CITASPAS.dbo.SimCitaWebNacional scn
JOIN SIM.dbo.SimPagos spa ON scn.sSecRecBanco = spa.sNroRecibo
                             AND scn.sDigVerRecBanco = spa.sCodVerificacion
                             AND CAST(scn.dFecRecBanco AS DATE) = CAST(spa.dFechaHora AS DATE)
WHERE
   scn.bAnulado = 0
   AND spa.dFechaHora >= '2024-01-01 00:00:00.000' -- Fecha pago ...


-- Test ...
SELECT * FROM SIM.dbo.SimTipoTramite stt WHERE stt.sDescripcion LIKE '%pasapo%'

EXEC sp_help SimCitaWebNacional
EXEC sp_help SimPagos

-- ==================================================================================================================================================================