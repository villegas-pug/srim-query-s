-- RC00008
-- 3. Ciudadanos extranjeros con pasaporte peruano y sin trámites de nacionalidad ...
-- ==================================================================================================================================================================

-- 3.1. Identificar extranjeros.
DROP TABLE IF EXISTS #tmp_ext_dupl
SELECT 
   p3.*
   INTO #tmp_ext_dupl
FROM (

   SELECT
      p2.*,
      [nDupl(sId)] = COUNT(1) OVER (PARTITION BY p2.sIdPersona),
      [nDupl(sId, sNacionalidad)] = COUNT(1) OVER (PARTITION BY p2.sIdPersona, p2.sIdPaisNacionalidad)
   FROM (

      SELECT
         [sIdPersona] = CONCAT(
                                 REPLACE(p.sNombre, ' ', ''),
                                 REPLACE(p.sPaterno, ' ', ''),
                                 REPLACE(p.sMaterno, ' ', ''),
                                 LTRIM(RTRIM(p.sSexo)),
                                 CAST(p.dFechaNacimiento AS FLOAT),
                                 p.sIdPaisNacimiento
                        ),
         p.*
      FROM SimPersona p
      WHERE
         p.bActivo = 1
         AND p.uIdPersona != '00000000-0000-0000-0000-000000000000'
         AND (p.sIdPaisNacionalidad != 'NNN' AND p.sIdPaisNacionalidad IS NOT NULL )
         AND (p.sIdPaisNacimiento NOT IN ('PER', 'NNN') AND p.sIdPaisNacimiento IS NOT NULL )
         AND p.dFechaNacimiento != '1900-01-01 00:00:00.000'

   ) p2

) p3
WHERE
   p3.[nDupl(sId)] >= 2
   AND p3.[nDupl(sId, sNacionalidad)] = 1


-- 3.2 Identificar inconsistenica.
BEGIN

   -- Dep's 
   DROP TABLE IF EXISTS #tmp_ext_dupl_bak
   SELECT * INTO #tmp_ext_dupl_bak FROM #tmp_ext_dupl

   CREATE NONCLUSTERED INDEX IX_#tmp_ext_dupl_bak_sIdPersona 
      ON #tmp_ext_dupl_bak(sIdPersona)

   DROP TABLE IF EXISTS #tmp_ext_con_pas_noreg_nac_final
   SELECT 
      TOP 0
      [sIdPersona] = REPLICATE('|', 255),
      p.uIdPersona,
      p.sNombre,
      p.sPaterno,
      p.sMaterno,
      p.sSexo,
      p.dFechaNacimiento,
      p.sIdPaisNacimiento,
      p.sIdPaisResidencia,
      p.sIdPaisNacionalidad,
      p.sIdDocIdentidad,
      p.sNumDocIdentidad
      INTO #tmp_ext_con_pas_noreg_nac_final
   FROM SimPersona p

   WHILE (SELECT COUNT(1) FROM #tmp_ext_dupl_bak) > 0
   BEGIN

      -- Dep's
      DECLARE @sId VARCHAR(255) = (SELECT TOP 1 e.sIdPersona FROM #tmp_ext_dupl_bak e ORDER BY e.sIdPersona ASC),
              @nPeso TINYINT = 0

      -- 1. Si tiene nacionalidad `PER` y tiene `DNI` = 1
      IF EXISTS (
                  SELECT 1
                  FROM #tmp_ext_dupl_bak e
                  WHERE
                     e.sIdPersona = @sId
                     AND e.sIdPaisNacionalidad = 'PER'
                     AND e.sIdDocIdentidad = 'DNI'

      )
      BEGIN
         SET @nPeso = @nPeso + 1
      END

      -- 2. Si tiene PAS peruano vigente = 1
      IF EXISTS (
                  SELECT 1
                  FROM SimTramitePas tp
                  JOIN SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
                  WHERE
                     t.bCancelado = 0
                     AND t.uIdPersona IN (
                                             SELECT 
                                                e.uIdPersona
                                             FROM #tmp_ext_dupl_bak e
                                             WHERE
                                                e.sIdPersona = @sId
                                                AND e.sIdPaisNacionalidad = 'PER'
                                       )
                     AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico
                     
      )
      BEGIN
         SET @nPeso = @nPeso + 1
      END

      -- 3. Si no tiene trámites de `NAC` = 1
      IF NOT EXISTS (
                  SELECT 1
                  FROM SimTramite t
                  JOIN SimTramiteNac tn ON t.sNumeroTramite = tn.sNumeroTramite
                  WHERE
                     t.bCancelado = 0
                     AND t.uIdPersona IN (
                                             SELECT 
                                                e.uIdPersona
                                             FROM #tmp_ext_dupl_bak e
                                             WHERE
                                                e.sIdPersona = @sId
                                                -- AND e.sIdPaisNacionalidad = 'PER'
                                    )
                     AND t.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79) -- Trámites para obtener la nacionalidad ...
                     
      )
      BEGIN
         SET @nPeso = @nPeso + 1
      END

      IF @nPeso = 3
      BEGIN
         INSERT INTO #tmp_ext_con_pas_noreg_nac_final
            SELECT 
               @sId,
               e.uIdPersona,
               e.sNombre,
               e.sPaterno,
               e.sMaterno,
               e.sSexo,
               e.dFechaNacimiento,
               e.sIdPaisNacimiento,
               e.sIdPaisResidencia,
               e.sIdPaisNacionalidad,
               e.sIdDocIdentidad,
               e.sNumDocIdentidad
            FROM #tmp_ext_dupl_bak e
            WHERE 
               e.sIdPersona = @sId
      END

      -- Cleanup ...
      DELETE FROM #tmp_ext_dupl_bak
      WHERE sIdPersona = @sId

   END

END

-- Resultado ...
SELECT 

   -- 1
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Pasaporte] = (
                              SELECT
                                 TOP 1
                                 tp.sPasNumero
                              FROM SimTramitePas tp
                              JOIN SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
                              JOIN SimPasaporte pas ON tp.sPasNumero = pas.sPasNumero
                              WHERE
                                 t.bCancelado = 0
                                 AND t.uIdPersona = e.uIdPersona
                                 AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico
                                 AND pas.sEstadoActual = 'E'
                              ORDER BY pas.dFechaEmision DESC
   ),
   [Fecha Emisión Pasaporte] = (
                                    SELECT
                                       TOP 1
                                       pas.dFechaEmision
                                    FROM SimTramitePas tp
                                    JOIN SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
                                    JOIN SimPasaporte pas ON tp.sPasNumero = pas.sPasNumero
                                    WHERE
                                       t.bCancelado = 0
                                       AND t.uIdPersona = e.uIdPersona
                                       AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico
                                       AND pas.sEstadoActual = 'E'
                                    ORDER BY pas.dFechaEmision DESC
   )

FROM #tmp_ext_con_pas_noreg_nac_final e
JOIN SimPersona p ON e.uIdPersona = p.uIdPersona
ORDER BY e.sIdPersona ASC