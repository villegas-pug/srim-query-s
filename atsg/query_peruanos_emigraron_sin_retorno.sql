USE SIM
GO

/*

   -- 1. Cantidad de peruanos que emigraron desde el Perú y no han retornado. Considerando entre el 2024 y enero 2025.           */
-- ===================================================================================================================================================

-- 1
DROP TABLE IF EXISTS #tmp_peruanos
SELECT
   pe.uIdPersona,
   [sIdPersona] = REPLACE(
                     CONCAT(
                        SOUNDEX(pe.sNombre), 
                        SOUNDEX(pe.sPaterno), 
                        SOUNDEX(pe.sMaterno), 
                        CAST(pe.dFechaNacimiento AS INT), 
                        pe.sSexo
                     ) , ' ', '')
                     
   INTO #tmp_peruanos
FROM SimPersona pe
WHERE
   pe.bActivo = 1
   AND pe.sIdPaisNacionalidad = 'PER'

CREATE NONCLUSTERED INDEX ix_tmp_peruanos 
   ON #tmp_peruanos(sIdPersona)

CREATE NONCLUSTERED INDEX ix_tmp_peruanos2
   ON #tmp_peruanos(uIdPersona)

-- 3
DROP TABLE IF EXISTS #per_ult_salida
SELECT 
   mm2.*
   INTO #per_ult_salida
FROM (

   SELECT
      mm.uIdPersona,
      mm.dFechaControl,
      mm.sTipo,
      [#] = ROW_NUMBER() OVER (PARTITION BY pe.sIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   JOIN #tmp_peruanos pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2025-01-31 23:59:59.998'

) mm2
WHERE 
   mm2.[#] = 1 -- Ultimo movimiento
   AND mm2.sTipo = 'S' -- Emigraron

-- 2. Final:
SELECT 
   [Fuera(Dias)] = DATEDIFF(DD, mm.dFechaControl, GETDATE()),
   [Personas] = COUNT(1)
FROM #per_ult_salida mm
GROUP BY
   DATEDIFF(DD, mm.dFechaControl, GETDATE())


-- Test
SELECT DATEDIFF(DD, '2025-02-10', GETDATE())

-- ===================================================================================================================================================
