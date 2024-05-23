USE SIM
GO

-- 1. Etapas por trámite ...
-- 58, 113, 126
SELECT 
   t.sNumeroTramite,
   t.dFechaHora,
   t.nIdTipoTramite,
   e.nIdEtapa,
   [sEtapa] = e.sDescripcion
FROM SimTramite t
JOIN SimEtapaTramiteInm eti ON t.sNumeroTramite = eti.sNumeroTramite
JOIN SimEtapa e ON eti.nIdEtapa = e.nIdEtapa
WHERE
   t.sNumeroTramite = (
      SELECT TOP 1 t2.sNumeroTramite 
      FROM SimTramite t2
      WHERE 
         t2.bCancelado = 0
         AND t2.bCulminado = 1
         AND t2.nIdTipoTramite = 58 -- CCM
         AND YEAR(t2.dFechaHora) = 2021
      ORDER BY NEWID()
   )
ORDER BY eti.nIdEtapaTramite