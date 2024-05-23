USE SIM
GO

-- 1. Registros de ciudadanos iguales en el Control Migratorio con una diferencia en minutos en la fecha de control, distinta identificador de persona
--    respectivamente e igual nacionalidad.
-- ==================================================================================================================================================================

-- 1.1. Encontrar multiplicidad registros.
DROP TABLE IF EXISTS #tmp_per_dupl
SELECT 
   p3.*
   INTO #tmp_per_dupl
FROM (

   SELECT
      p2.*,
      [nDupl] = COUNT(1) OVER (PARTITION BY p2.sIdPersona)
   FROM (

      SELECT
         [sIdPersona] = CONCAT(
                                 REPLACE(p.sNombre, ' ', ''),
                                 REPLACE(p.sPaterno, ' ', ''),
                                 REPLACE(p.sMaterno, ' ', ''),
                                 LTRIM(RTRIM(p.sSexo)),
                                 CAST(p.dFechaNacimiento AS FLOAT),
                                 p.sIdPaisNacionalidad
                        ),
         p.*
      FROM SimPersona p
      WHERE
         p.bActivo = 1
         AND p.uIdPersona != '00000000-0000-0000-0000-000000000000'
         AND (p.sIdPaisNacionalidad != 'NNN' AND p.sIdPaisNacionalidad IS NOT NULL )
         AND p.dFechaNacimiento != '1900-01-01 00:00:00.000'

   ) p2

) p3
WHERE
   p3.nDupl >= 2


-- 1.2. Registros con movimientos migratorios
DROP TABLE IF EXISTS #tmp_per_dupl_mm
SELECT
   pd3.*
   INTO #tmp_per_dupl_mm
FROM (

   SELECT
      pd2.*,
      [nContar(sId)] = COUNT(1) OVER (PARTITION BY pd2.sIdPersona),
      [nContar(bMovMig)] = SUM(pd2.bMovMig) OVER (PARTITION BY pd2.sIdPersona)
   FROM (

      SELECT
         pd.*,
         [bMovMig] = IIF(
                           EXISTS(
                              SELECT 1
                              FROM SimMovMigra mm 
                              WHERE
                                 mm.bAnulado = 0
                                 AND mm.bTemporal = 0
                                 AND mm.uIdPersona = pd.uIdPersona
                           ),
                           1,
                           0
                        )
      FROM #tmp_per_dupl pd

   ) pd2
   WHERE
      pd2.bMovMig = 1


) pd3
WHERE
   pd3.[nContar(sId)] >= 2
   AND pd3.[nContar(bMovMig)] >= 2

-- 1.3. Identifica registros inconsistentes ...
BEGIN

   -- Dep's 
   DROP TABLE IF EXISTS #tmp_per_dupl_mm_bak
   SELECT * INTO #tmp_per_dupl_mm_bak FROM #tmp_per_dupl_mm

   CREATE NONCLUSTERED INDEX IX_tmp_per_dupl_mm_bak_sIdPersona 
      ON #tmp_per_dupl_mm_bak(sIdPersona);

   DROP TABLE IF EXISTS #tmp_per_dupl_mm_final
   SELECT 
      TOP 0
      [sIdPersona] = REPLICATE('|', 255),
      mm.uIdPersona, mm.sIdMovMigratorio, mm.dFechaControl, mm.sObservaciones, 
      mm.sTipo, mm.sIdPaisNacionalidad, mm.sIdDocumento, 
      mm.sNumeroDoc, mm.sIdDependencia, mm.sIdPaisMov, mm.sNombres,
      [LoginOperador] = REPLICATE('|', 55),
      [Operador] = REPLICATE('|', 200)
      INTO #tmp_per_dupl_mm_final
   FROM SimMovMigra mm

   WHILE (SELECT COUNT(1) FROM #tmp_per_dupl_mm_bak) > 0
   BEGIN

      -- Dep's
      DECLARE @sId VARCHAR(255) = (SELECT TOP 1 p.sIdPersona FROM #tmp_per_dupl_mm_bak p ORDER BY p.sIdPersona ASC)


      -- ...
      INSERT INTO #tmp_per_dupl_mm_final
         SELECT 
            [sIdPersona] = @sId,
            mm2.uIdPersona,
            mm2.sIdMovMigratorio,
            mm2.dFechaControl,
            mm2.sObservaciones,
            mm2.sTipo,
            mm2.sIdPaisNacionalidad,
            mm2.sIdDocumento,
            mm2.sNumeroDoc,
            mm2.sIdDependencia,
            mm2.sIdPaisMov,
            mm2.sNombres,
            mm2.sLoginOperador,
            mm2.sOperador
         FROM (

            SELECT 
               mm.*,
               [sLoginOperador] = u.sLogin,
               [sOperador] = u.sNombre,
               [nDupl(sTipo, Fec, hh)] = COUNT(1) OVER (PARTITION BY
                                                            mm.sTipo, -- TipoMov
                                                            CAST(mm.dFechaControl AS DATE) -- Fecha
                                                            -- DATEPART(HH, mm.dFechaControl) -- Hora
                                                      ),
               [nDupl(uId, Fec, hh, mm)] = COUNT(1) OVER (PARTITION BY
                                                            mm.uIdPersona,
                                                            CAST(mm.dFechaControl AS DATE), -- Fecha
                                                            DATEPART(HH, mm.dFechaControl), -- Hora
                                                            DATEPART(mi, mm.dFechaControl) -- Minutos
                                                      )
            
            FROM SimMovMigra mm
            JOIN SimUsuario u ON mm.nIdOperadorDigita = u.nIdOperador
            WHERE
               mm.bAnulado = 0
               AND mm.bTemporal = 0
               AND mm.uIdPersona IN (
                                       SELECT p.uIdPersona
                                       FROM #tmp_per_dupl_mm_bak p
                                       WHERE p.sIdPersona = @sId
                                    )

         ) mm2
         WHERE
            mm2.[nDupl(sTipo, Fec, hh)] >= 2 -- [yyyy-MM-dd] y [HH:] iguales
            AND mm2.[nDupl(uId, Fec, hh, mm)] = 1 -- uIdPersona distinto


      -- Cleanup ...
      DELETE FROM #tmp_per_dupl_mm_bak
      WHERE sIdPersona = @sId

   END

END

-- Resultado:
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
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Pais Nacionalidad] = f.sIdPaisNacionalidad,
   [Documento] = f.sIdDocumento,
   [NumeroDoc] = f.sNumeroDoc,
   [Pais Mov] = f.sIdPaisMov,
   [Login Operador] = f.LoginOperador,
   [Operador] = f.Operador

FROM #tmp_per_dupl_mm_final f
JOIN SimPersona p ON f.uIdPersona = p.uIdPersona
ORDER BY f.dFechaControl DESC


-- Dashboard para entregable ...
SELECT * 
FROM #tmp_per_dupl_mm_dash_final
DROP TABLE IF EXISTS #tmp_per_dupl_mm_dash_final
SELECT TOP 0 f.*, [nOrden] = 0 INTO #tmp_per_dupl_mm_dash_final FROM #tmp_per_dupl_mm_final f

INSERT INTO #tmp_per_dupl_mm_dash_final
   SELECT * 
   FROM (
      SELECT
         f.*,
         [nOrden] = ROW_NUMBER() OVER (ORDER BY f.dFechaControl ASC)
      FROM #tmp_per_dupl_mm_final f
   ) f2
   ORDER BY f2.nOrden ASC

SELECT f.*
FROM #tmp_per_dupl_mm_dash_final f
ORDER BY f.sIdPersona ASC, f.dFechaControl ASC

SELECT

   d2.sIdPersona,
   d2.dFechaControl,
   d2.sTipo,
   d2.dFecha,
   d2.dHora,
   [FIRST_VALUE] = FIRST_VALUE(d2.dHora) OVER (PARTITION BY d2.sIdPersona, d2.sTipo, d2.dFecha ORDER BY d2.sIdPersona),
   [LAST_VALUE] = LAST_VALUE(d2.dHora) OVER (PARTITION BY d2.sIdPersona, d2.sTipo, d2.dFecha ORDER BY d2.sIdPersona)
   /* [nRango(Horas)] = (
                        CASE
                           WHEN (
                              DATEDIFF(
                                 Mi,
                                 (
                                    SELECT TOP 1 CAST(t.dFechaControl AS TIME) FROM #tmp_per_dupl_mm_final t 
                                    WHERE 
                                       t.sIdPersona = d2.sIdPersona
                                       AND t.sTipo = d2.sTipo
                                       AND CAST(t.dFechaControl AS DATE) = CAST(d2.dFechaControl AS DATE)
                                    ORDER BY t.dFechaControl ASC
                                 ), (
                                    SELECT TOP 1 CAST(t.dFechaControl AS TIME) FROM #tmp_per_dupl_mm_final t 
                                    WHERE 
                                       t.sIdPersona = d2.sIdPersona
                                       AND t.sTipo = d2.sTipo
                                       AND CAST(t.dFechaControl AS DATE)= CAST(d2.dFechaControl AS DATE)
                                    ORDER BY t.dFechaControl DESC
                                 )
                              )
                           ) <= 60 THEN 1
                           WHEN (
                              DATEDIFF(
                                 Mi,
                                 (
                                    SELECT TOP 1 CAST(t.dFechaControl AS TIME) FROM #tmp_per_dupl_mm_final t 
                                    WHERE 
                                       t.sIdPersona = d2.sIdPersona
                                       AND t.sTipo = d2.sTipo
                                       AND CAST(t.dFechaControl AS DATE) = CAST(d2.dFechaControl AS DATE)
                                    ORDER BY t.dFechaControl ASC
                                 ), (
                                    SELECT TOP 1 CAST(t.dFechaControl AS TIME) FROM #tmp_per_dupl_mm_final t 
                                    WHERE 
                                       t.sIdPersona = d2.sIdPersona
                                       AND t.sTipo = d2.sTipo
                                       AND CAST(t.dFechaControl AS DATE)= CAST(d2.dFechaControl AS DATE)
                                    ORDER BY t.dFechaControl DESC
                                 )
                              )
                           ) BETWEEN 61 AND 120 THEN 2
                           WHEN (
                              DATEDIFF(
                                 Mi,
                                 (
                                    SELECT TOP 1 CAST(t.dFechaControl AS TIME) FROM #tmp_per_dupl_mm_final t 
                                    WHERE 
                                       t.sIdPersona = d2.sIdPersona
                                       AND t.sTipo = d2.sTipo
                                       AND CAST(t.dFechaControl AS DATE) = CAST(d2.dFechaControl AS DATE)
                                    ORDER BY t.dFechaControl ASC
                                 ), (
                                    SELECT TOP 1 CAST(t.dFechaControl AS TIME) FROM #tmp_per_dupl_mm_final t 
                                    WHERE 
                                       t.sIdPersona = d2.sIdPersona
                                       AND t.sTipo = d2.sTipo
                                       AND CAST(t.dFechaControl AS DATE)= CAST(d2.dFechaControl AS DATE)
                                    ORDER BY t.dFechaControl DESC
                                 )
                              )
                           ) BETWEEN 121 AND 180 THEN 3
                           ELSE 0 -- '+3 hrs.'
                        END

                     ) */
FROM (

   SELECT 
      -- d.*,
      d.sIdPersona,
      d.dFechaControl,
      d.sTipo,
      [dFecha] = CAST(d.dFechaControl AS DATE),
      [dHora] = CAST(d.dFechaControl AS TIME)

   FROM #tmp_per_dupl_mm_final d

) d2
ORDER BY 
   d2.sIdPersona,
   d2.dFechaControl ASC


-- ==================================================================================================================================================================


-- 2. Registros de ciudadanos iguales en el Control Migratorio con una diferencia en minutos en la fecha de control, distinta identificador de persona 
--    respectivamente, distinto documento y distinta nacionalidad.
-- ==================================================================================================================================================================

-- 2.1. Encontrar multiplicidad registros identicos
DROP TABLE IF EXISTS #tmp_per_dupl
SELECT 
   p3.*
   INTO #tmp_per_dupl
FROM (

   SELECT
      p2.*,
      [nDupl] = COUNT(1) OVER (PARTITION BY p2.sIdPersona)
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
         AND (p.sIdPaisNacimiento != 'NNN' AND p.sIdPaisNacimiento IS NOT NULL )
         AND p.dFechaNacimiento != '1900-01-01 00:00:00.000'

   ) p2

) p3
WHERE
   p3.nDupl >= 2


-- 2.2. Registros con movimientos migratorios
DROP TABLE IF EXISTS #tmp_per_dupl_mm
SELECT
   pd3.*
   INTO #tmp_per_dupl_mm
FROM (

   SELECT
      pd2.*,
      [nContar(sId)] = COUNT(1) OVER (PARTITION BY pd2.sIdPersona),
      [nContar(bMovMig)] = SUM(pd2.bMovMig) OVER (PARTITION BY pd2.sIdPersona, pd2.sIdPaisNacionalidad)
   FROM (

      SELECT
         pd.*,
         [bMovMig] = IIF(
                           EXISTS(
                              SELECT 1
                              FROM SimMovMigra mm 
                              WHERE
                                 mm.bAnulado = 0
                                 AND mm.bTemporal = 0
                                 AND mm.uIdPersona = pd.uIdPersona
                           ),
                           1,
                           0
                        )
      FROM #tmp_per_dupl pd

   ) pd2
   WHERE
      pd2.bMovMig = 1


) pd3
WHERE
   pd3.[nContar(sId)] >= 2
   AND pd3.[nContar(bMovMig)] = 1

-- 2.3. Identifica inconsistencia.
BEGIN

   -- Dep's 
   DROP TABLE IF EXISTS #tmp_per_dupl_mm_bak
   SELECT * INTO #tmp_per_dupl_mm_bak FROM #tmp_per_dupl_mm

   CREATE NONCLUSTERED INDEX IX_tmp_per_dupl_mm_bak_sIdPersona 
      ON #tmp_per_dupl_mm_bak(sIdPersona);

   DROP TABLE IF EXISTS #tmp_per_dupl_mm_final
   SELECT 
      TOP 0
      [sIdPersona] = REPLICATE('|', 255),
      mm.uIdPersona, mm.sIdMovMigratorio, mm.dFechaControl, mm.sObservaciones, 
      mm.sTipo, mm.sIdPaisNacionalidad, mm.sIdDocumento, 
      mm.sNumeroDoc, mm.sIdDependencia, mm.sIdPaisMov, mm.sNombres,
      [LoginOperador] = REPLICATE('|', 55),
      [Operador] = REPLICATE('|', 200)
      INTO #tmp_per_dupl_mm_final
   FROM SimMovMigra mm

   WHILE (SELECT COUNT(1) FROM #tmp_per_dupl_mm_bak) > 0
   BEGIN

      -- Dep's
      DECLARE @sId VARCHAR(255) = (SELECT TOP 1 p.sIdPersona FROM #tmp_per_dupl_mm_bak p ORDER BY p.sIdPersona ASC)

      -- ...
      INSERT INTO #tmp_per_dupl_mm_final
         SELECT 
            [sIdPersona] = @sId,
            mm2.uIdPersona,
            mm2.sIdMovMigratorio,
            mm2.dFechaControl,
            mm2.sObservaciones,
            mm2.sTipo,
            mm2.sIdPaisNacionalidad,
            mm2.sIdDocumento,
            mm2.sNumeroDoc,
            mm2.sIdDependencia,
            mm2.sIdPaisMov,
            mm2.sNombres,
            mm2.sLoginOperador,
            mm2.sOperador
         FROM (

            SELECT 
               mm.*,
               [sLoginOperador] = u.sLogin,
               [sOperador] = u.sNombre,
               [nDupl(tipomov, Fec, hh)] = COUNT(1) OVER (PARTITION BY 
                                                      mm.sTipo, -- Tipo movimiento
                                                      CAST(mm.dFechaControl AS DATE) -- Fecha
                                                      -- DATEPART(HH, mm.dFechaControl) -- Hora
                                                ),
               [nDupl(uId, Fec, hh, mi)] = COUNT(1) OVER (PARTITION BY
                                                            mm.uIdPersona,
                                                            CAST(mm.dFechaControl AS DATE), -- Fecha
                                                            DATEPART(HH, mm.dFechaControl), -- Hora
                                                            DATEPART(mi, mm.dFechaControl) -- Minutos
                                                      )
            FROM SimMovMigra mm
            JOIN SimUsuario u ON mm.nIdOperadorDigita = u.nIdOperador
            WHERE
               mm.bAnulado = 0
               AND mm.bTemporal = 0
               AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
               AND mm.uIdPersona IN (
                                       SELECT p.uIdPersona
                                       FROM #tmp_per_dupl_mm_bak p
                                       WHERE p.sIdPersona = @sId
                                    )

         ) mm2
         WHERE
            mm2.[nDupl(tipomov, Fec, hh)] >= 2 -- [yyyy-MM-dd] y [HH:] iguales
            AND mm2.[nDupl(uId, Fec, hh, mi)] = 1 -- uIdPersona distinto


      -- Cleanup ...
      DELETE FROM #tmp_per_dupl_mm_bak
      WHERE sIdPersona = @sId

   END

END

-- Resutaldo ...
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
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Pais Nacionalidad] = f.sIdPaisNacionalidad,
   [Documento] = f.sIdDocumento,
   [NumeroDoc] = f.sNumeroDoc,
   [Pais Mov] = f.sIdPaisMov,
   [Login Operador] = f.LoginOperador,
   [Operador] = f.Operador
FROM #tmp_per_dupl_mm_final f
JOIN SimPersona p ON f.uIdPersona = p.uIdPersona
ORDER BY f.dFechaControl

-- ==================================================================================================================================================================


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


-- Dashboard

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
      [nPeso] = 0,
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

      INSERT INTO #tmp_ext_con_pas_noreg_nac_final
         SELECT 
            @sId,
            @nPeso,
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

      -- Cleanup ...
      DELETE FROM #tmp_ext_dupl_bak
      WHERE sIdPersona = @sId

   END

END

-- Resultado: Dashboard ...
-- 1. Si tiene nacionalidad `PER` y tiene `DNI` = 1
-- 2. Si tiene PAS peruano vigente = 1
-- 3. Si no tiene trámites de `NAC` = 1
SELECT * 
FROM (

   SELECT 
      f.sIdPersona, 
      f.sIdPaisNacionalidad, 
      [sPeso] = (
                  CASE
                     WHEN f.nPeso = 1 THEN 'DNI'
                     WHEN f.nPeso = 2 THEN 'DNI|PAS'
                     WHEN f.nPeso = 3 THEN 'DNI|PAS|NAC'
                     ELSE 'NNN'
                  END
      )
   FROM #tmp_ext_con_pas_noreg_nac_final f

) f2
WHERE f2.sPeso != 'NNN'


-- ==================================================================================================================================================================


-- 4. Se registran Calidad anterior y solicitada iguales ...
-- ==================================================================================================================================================================

-- Identificar inconsitencia.
DROP TABLE IF EXISTS #tmp_Calant_igual_calsol
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
   [sTipoTramite] = tt.sDescripcion,
   t.sNumeroTramite,
   ti.sEstadoActual,
   ccm.nIdCalAnterior,
   [sCalidadAnterion] = cma.sDescripcion,
   ccm.nIdCalSolicitada,
   [sCalidadSolicitada] = cms.sDescripcion
   INTO #tmp_Calant_igual_calsol
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cma ON ccm.nIdCalAnterior = cma.nIdCalidad
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   -- 314 ↔ ACUERDOS INTERNACIONALES - MERCOSUR; 332 ↔ MERCOSUR PERMANENTE
   AND (ccm.nIdCalAnterior NOT IN (314, 332) AND ccm.nIdCalSolicitada NOT IN (314, 332))
   AND ccm.nIdCalAnterior = ccm.nIdCalSolicitada
ORDER BY
   t.dFechaHora DESC


-- Resultado: Dashboard ...
SELECT 
   ccm2.sTipoTramite,
   ccm2.[bIgualCalidad(A|S)],
   [nTotal] = COUNT(1)
FROM (

   SELECT 
      -- Aux
      [sTipoTramite] = tt.sDescripcion,
      [bIgualCalidad(A|S)] = (
                                 CASE
                                    WHEN ccm.nIdCalAnterior = ccm.nIdCalSolicitada THEN 1
                                    ELSE 0
                                 END
                              )
      
   FROM SimCambioCalMig ccm
   JOIN SimCalidadMigratoria cma ON ccm.nIdCalAnterior = cma.nIdCalidad
   JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
   JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   WHERE
      t.bCancelado = 0
      AND ti.sEstadoActual = 'A'
      AND t.dFechaHora BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
      -- AND t.dFechaHora >= '2024-01-01 00:00:00.000'
      AND (ccm.nIdCalAnterior NOT IN (314, 332) AND ccm.nIdCalSolicitada NOT IN (314, 332))

) ccm2
GROUP BY
   ccm2.sTipoTramite,
   ccm2.[bIgualCalidad(A|S)]
ORDER BY
   3 DESC


-- Test
SELECT 
   -- Aux
   [sCalidadAnterior] = cma.sDescripcion,
   [sCalidadSolicitada] = cms.sDescripcion,
   [nTotal] = COUNT(1)
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cma ON ccm.nIdCalAnterior = cma.nIdCalidad
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND t.dFechaHora BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
   -- AND t.dFechaHora >= '2024-01-01 00:00:00.000'
   AND (ccm.nIdCalAnterior NOT IN (314, 332) AND ccm.nIdCalSolicitada NOT IN (314, 332))
GROUP BY
   cma.sDescripcion,
   cms.sDescripcion
ORDER BY
   3 DESC



-- ==================================================================================================================================================================


-- 5. Trámites de Cambio de Calidad en estado aprobado, sin fecha de aprobación ...
-- ==================================================================================================================================================================

-- EXEC sp_help SimCambioCalMig
SELECT 

   -- 1
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- AUx
   [sTipoTramite] = tt.sDescripcion,
   t.sNumeroTramite,
   ti.sEstadoActual,
   ccm.nIdCalSolicitada,
   [sCalidadSolicitada] = cms.sDescripcion,
   ccm.dFechaAprobacion
FROM SimCambioCalMig ccm
JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (
      58  -- CCM
      -- 113, -- REGULARIZACION DE EXTRANJEROS
      -- 126  -- PERMISO TEMPORAL DE PERMANENCIA - RS109
   )
   AND ccm.dFechaAprobacion IS NULL
   ORDER BY
      t.dFechaHora DESC

-- Resultado: Dashboard ...
SELECT 
   ccm2.sTipoTramite,
   ccm2.[bTieneFecha(A)],
   [nTotal] = COUNT(1)
FROM (

   SELECT 
      -- Aux
      [sTipoTramite] = tt.sDescripcion,
      [bTieneFecha(A)] = (
                              CASE
                                 WHEN ccm.dFechaAprobacion IS NULL THEN 'SIN FECHA'
                                 ELSE 'CON FECHA'
                              END
                           )
      
   FROM SimCambioCalMig ccm
   JOIN SimCalidadMigratoria cma ON ccm.nIdCalAnterior = cma.nIdCalidad
   JOIN SimCalidadMigratoria cms ON ccm.nIdCalAnterior = cms.nIdCalidad
   JOIN SimTramite t ON ccm.sNumeroTramite = t.sNumeroTramite
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   WHERE
      t.bCancelado = 0
      AND ti.sEstadoActual = 'A'
      AND t.dFechaHora BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
      -- AND t.dFechaHora >= '2024-01-01 00:00:00.000'
      AND (ccm.nIdCalAnterior NOT IN (314, 332) AND ccm.nIdCalSolicitada NOT IN (314, 332))

) ccm2
GROUP BY
   ccm2.sTipoTramite,
   ccm2.[bTieneFecha(A)]
ORDER BY
   3 DESC
   

-- ==================================================================================================================================================================

