USE SIM
GO

/*░
	-- bActivo
	-- 0 → Habilitada
	-- 1 → Inhabilitada
-- ============================================= */

SELECT * FROM #tmp_pas_anulado a WHERE a.nId = 1361

-- INSERT INTO #tmp_pas_anulado VALUES(1361,'FERNANDO ANTONIO','D''''ALESSIO','IPINZA','NNN','D16001687')


-- 1: tmp ...
CREATE TABLE #tmp_pas_anulado
(
   nId INT PRIMARY KEY NOT NULL,
   sNombre VARCHAR(100) NULL,
   sPaterno VARCHAR(55) NULL,
   sMaterno VARCHAR(55) NULL,
   sIdPaisNacionalidad CHAR(3),
   sNumPasaporte VARCHAR(55)
)

-- 1.1: Insert ...
-- INSERT INTO #tmp_pas_anulado()
SELECT COUNT(1) FROM #tmp_pas_anulado

UPDATE #tmp_pas_anulado
   SET 
      sNombre = REPLACE(sNombre, '''''', ''''),
      sPaterno = REPLACE(sPaterno, '''''', ''''),
      sMaterno = REPLACE(sMaterno, '''''', '''')

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_pas_anulado_sNumPasaporte 
   ON #tmp_pas_anulado(sNumPasaporte)

-- 1.2: ...
DROP TABLE IF EXISTS #tmp_pas_anulado_final
SELECT a2.* INTO #tmp_pas_anulado_final FROM (

   -- Por número de pasaporte ...
   SELECT 
      a_pas2.*,
      [nCantDnv] = (
                     SELECT
                        COUNT(1)
                     FROM SimPersonaNoAutorizada dnv
                     WHERE
                        dnv.bActivo = 1
                        AND dnv.sIdMotivoInv = 'PANU'
                        AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
                        AND dnv.sNumDocIdentidad = a_pas2.sNumPasaporte
                  )
   FROM (

      SELECT a_pas.* FROM (

         SELECT
            a.*,
            [nFila_dnv] = ROW_NUMBER() OVER (PARTITION BY a.sNumPasaporte ORDER BY a.nId)
         FROM #tmp_pas_anulado a
         WHERE
            a.sNumPasaporte != 'NR'
            AND EXISTS (
               SELECT
                  TOP 1 1
               FROM SimPersonaNoAutorizada dnv
               WHERE
                  dnv.bActivo = 1
                  AND dnv.sIdMotivoInv = 'PANU'
                  AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
                  AND dnv.sNumDocIdentidad = a.sNumPasaporte
            )

      ) a_pas
      WHERE
         a_pas.nFila_dnv = 1

   ) a_pas2

   UNION ALL

   -- Si número de documento  es: `NR` ...
   SELECT 
      a_pas.*,
      [nCantDnv] = (
                     SELECT
                        COUNT(1)
                     FROM SimPersonaNoAutorizada dnv
                     WHERE
                        dnv.bActivo = 1
                        AND dnv.sIdMotivoInv = 'PANU'
                        AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
                        AND dnv.sNombre = a_pas.sNombre AND dnv.sPaterno = a_pas.sPaterno AND dnv.sMaterno = a_pas.sMaterno
                  )
   FROM (

      SELECT
         a.*,
         [nFila_dnv] = ROW_NUMBER() OVER (PARTITION BY a.sNombre, a.sPaterno, a.sMaterno ORDER BY a.nId)
      FROM #tmp_pas_anulado a
      WHERE
         a.sNumPasaporte = 'NR'

   ) a_pas
   WHERE
      a_pas.nFila_dnv = 1

   UNION ALL

   -- Si no existe por número de documento ...
   SELECT
      a_pas.*,
      [nCantDnv] = (
                     SELECT
                        COUNT(1)
                     FROM SimPersonaNoAutorizada dnv
                     WHERE
                        dnv.bActivo = 1
                        AND dnv.sIdMotivoInv = 'PANU'
                        AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
                        AND dnv.sNombre = a_pas.sNombre AND dnv.sPaterno = a_pas.sPaterno AND dnv.sMaterno = a_pas.sMaterno
                  )
   FROM (

      SELECT
         a.*,
         [nFila_dnv] = ROW_NUMBER() OVER (PARTITION BY a.sNombre, a.sPaterno, a.sMaterno ORDER BY a.nId)
      FROM #tmp_pas_anulado a
      WHERE
         a.sNumPasaporte != 'NR'
         AND NOT EXISTS (
            SELECT
               TOP 1 1
            FROM SimPersonaNoAutorizada dnv
            WHERE
               dnv.bActivo = 1
               AND dnv.sIdMotivoInv = 'PANU'
               AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
               AND dnv.sNumDocIdentidad = a.sNumPasaporte
         )

   ) a_pas
   WHERE
      a_pas.nFila_dnv = 1

) a2

-- 2. Final
DROP TABLE IF EXISTS #tmp_pas_anulado_final
SELECT a2.* INTO #tmp_pas_anulado_final FROM (
   SELECT
      a_pas.*,
      [nCantDnv_f1] = (
                        SELECT
                           COUNT(1)
                        FROM SimPersonaNoAutorizada dnv
                        WHERE
                           dnv.bActivo = 1
                           AND dnv.sIdMotivoInv = 'PANU'
                           AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
                           AND dnv.sNombre = a_pas.sNombre AND dnv.sPaterno = a_pas.sPaterno AND dnv.sMaterno = a_pas.sMaterno
                     )
   FROM (

      SELECT
         a.*,
         [nFiladnv_f1] = ROW_NUMBER() OVER (PARTITION BY a.sNombre, a.sPaterno, a.sMaterno ORDER BY a.nId)
      FROM #tmp_pas_anulado a

   ) a_pas
   WHERE
      a_pas.nFiladnv_f1 = 1

) a2


-- 2.1 Final
SELECT -- Con pasaporte
   f2.*
FROM (

   SELECT
      f.*,
      [nCantDnv_f2] = SUM(f.nCantDnv_f1) OVER (PARTITION BY f.sNumPasaporte),
      [nFilaDnv_f2] = ROW_NUMBER() OVER (PARTITION BY f.sNumPasaporte ORDER BY f.nId)
   FROM #tmp_pas_anulado_final f
   WHERE
      f.sNumPasaporte != 'NR'

) f2
WHERE
   f2.nFilaDnv_f2 = 1

UNION

SELECT  -- Sin pasaporte ...
   f.*,
   [nCantDnv_f2] = f.nCantDnv_f1,
   [nFilaDnv_f2] = 1
FROM #tmp_pas_anulado_final f
WHERE
   f.sNumPasaporte = 'NR'

-- ================================================================================================================================================

-- KK4R64109
SELECT
   dnv.*
FROM SimPersonaNoAutorizada dnv
WHERE
   dnv.bActivo = 1
   AND dnv.sIdMotivoInv = 'PANU'
   AND dnv.sIdAlertaInv = 'A1' -- ALERTA ES INFORMATIVA
   AND (
      dnv.sNumDocIdentidad = 'FP7268049'
      OR dnv.sPaterno IN (
         'AFRA RASHED EID'
      )
   )