USE SIM
GO

-- 1. Etapas por trámite ...
-- 57, 58, 113, 126
-- 57	14	ACTUALIZAR DATOS BENEFICIARIO
-- 58	4	TOMA DE IMAGENES

DECLARE @nId TINYINT = 113,
        @nAño SMALLINT = 2022
SELECT 
   t.sNumeroTramite,
   t.dFechaHora,
   t.nIdTipoTramite,
   e.nIdEtapa,
   [sEtapa] = e.sDescripcion
FROM SimTramite t
LEFT JOIN SimEtapaTramiteInm eti ON t.sNumeroTramite = eti.sNumeroTramite
LEFT JOIN SimEtapa e ON eti.nIdEtapa = e.nIdEtapa
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.sNumeroTramite = (
            SELECT TOP 1 t2.sNumeroTramite 
            FROM SimTramite t2
            JOIN SimTramiteInm ti ON t2.sNumeroTramite = ti.sNumeroTramite
            WHERE 
               t2.bCancelado = 0
               AND t2.bCulminado = 1
               AND ti.sEstadoActual = 'A'
               AND t2.nIdTipoTramite = @nId
               AND YEAR(t2.dFechaHora) >= @nAño
            ORDER BY NEWID()
   )
ORDER BY eti.nIdEtapaTramite

-- Test
SELECT * 
FROM SimEtapa

SELECT * 
FROM SimEtapaTramiteInm ti WHERE ti.sNumeroTramite = 'LM220417913'


