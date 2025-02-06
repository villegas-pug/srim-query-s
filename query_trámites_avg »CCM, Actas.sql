USE SIM
GO

-- 1
-- 58 ↔ CCM
-- 111 ↔ ACTUALIZACIÓN CON EMISIÓN DE DOCUMENTO
-- 117 ↔ RENOVACION DE CARNÉ DE EXTRANJERÍA
-- 64 ↔	DUPLICADO DE CE
SELECT stt.* FROM SimTipoTramite stt 
WHERE stt.sDescripcion LIKE '%dupli%'

/*SELECT * FROM SimEtapaTipoTramite sett 
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE sett.nIdTipoTramite = 58
ORDER BY sett.nSecuencia */

-- 2
-- Trámites `P` ...
SELECT p.* FROM (
   SELECT 
      st.sNumeroTramite,
      [nMesTramite] = DATEPART(MM, st.dFechaHora)
   FROM SimTramite st
   JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND st.nIdTipoTramite = 64 -- CCM
      AND st.dFechaHora BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
) t
PIVOT( 
   COUNT(t.sNumeroTramite) FOR t.nMesTramite IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) p

-- Trámites `A` ...
SELECT p.* FROM (
   SELECT 
      st.sNumeroTramite,
      [nMesFin] = DATEPART(MM, st.dFechaHora)
   FROM SimTramite st
   JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND sti.sEstadoActual = 'A'
      AND st.nIdTipoTramite = 58 -- CCM
      AND sti.dFechaFin BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
) t
PIVOT( 
   COUNT(t.sNumeroTramite) FOR t.nMesFin IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) p

SELECT 
   e.Departamento,
   COUNT(1)
FROM xTotalExtranjerosPeru e
GROUP BY
   e.Departamento
ORDER BY 2 DESC