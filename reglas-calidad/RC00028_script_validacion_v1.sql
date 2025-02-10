-- RC00028
--> ░ 3. Se define como regla, que el uso del documento de viaje PAS de ciudadanos peruanos en el control migratorio, debe ser exclusivamente personal.
-- ========================================================================================================================================================================

--3.1
DROP TABLE IF EXISTS #tmp_pas
SELECT
   p.*,
   t.uIdPersona
	INTO #tmp_pas
FROM SIM.dbo.SimPasaporte p
JOIN SIM.dbo.SimTramite t ON t.sNumeroTramite = p.sNumeroTramite
WHERE
   t.bCancelado = 0
	AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
	AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
	AND ISNUMERIC(p.sPasNumero) = 1
	AND p.sPasNumero LIKE '1[1-2]%'

CREATE NONCLUSTERED INDEX ix_tmp_pas_sPasNumero_uIdPersona ON #tmp_pas(uIdPersona, sPasNumero)

-- 3.2 Pasaportes como documentos de viaje
DROP TABLE IF EXISTS #tmp_mm_pase
SELECT
   mm.*,
   [sNombre(SimPersona)] = pe.sNombre,
   [sPaterno(SimPersona)] = pe.sPaterno,
   [sMaterno(SimPersona)] = pe.sMaterno,
   [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento

   INTO #tmp_mm_pase
FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'PAS'
   AND ( -- PAS electrónico
         ISNUMERIC(mm.sNumeroDoc) = 1
         AND LEN(mm.sNumeroDoc) = 9
         AND mm.sNumeroDoc LIKE '1[1-2]%'
   )
   AND EXISTS ( -- Pasaporte válido
               SELECT 1 FROM #tmp_pas p
               WHERE p.sPasNumero = mm.sNumeroDoc
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

CREATE NONCLUSTERED INDEX ix_tmp_mm_pase
   ON #tmp_mm_pase(uIdPersona, sNumeroDoc, dFechaControl)

-- 3.3
DROP TABLE IF EXISTS #tmp_mm_pase_f
SELECT f2.* INTO #tmp_mm_pase_f
FROM (

   SELECT
      f.*,
      [nTotalPase] = COUNT(1) OVER (PARTITION BY f.sNumeroDoc)
   FROM (

      SELECT
         mm.*,
         -- Aux
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona, mm.sNumeroDoc ORDER BY mm.dFechaControl)

      FROM #tmp_mm_pase mm

   ) f
   WHERE
      f.[#] = 1 -- Personas

) f2
WHERE
   f2.nTotalPase > 1 -- Total pase usados

-- 3 Final:
-- 3.1
SELECT
   f1.sIdMovMigratorio,
   f1.uIdPersona,
   f1.sNumeroDoc,
   f1.nIdOperadorDigita
FROM #tmp_mm_pase_f f1
WHERE
   EXISTS ( -- Valida personas distintas
            SELECT TOP 1 1
            FROM #tmp_mm_pase_f f2
            WHERE
               f1.uIdPersona != f2.uIdPersona -- Personas distintas ...
               AND f1.sNumeroDoc = f2.sNumeroDoc -- `PAS` iguales ...
               AND (
                     DIFFERENCE(f1.[sNombre(SimPersona)], f2.[sNombre(SimPersona)]) <= 3
                     AND DIFFERENCE(f1.[sPaterno(SimPersona)], f2.[sPaterno(SimPersona)]) <= 2
                     AND DIFFERENCE(f1.[sMaterno(SimPersona)], f2.[sMaterno(SimPersona)]) <= 2
               )
   )