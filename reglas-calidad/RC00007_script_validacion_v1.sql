-- RC00007
-- 2. Duplicidad de registros en el control migratorio de ciudadanos que presentan el mismo tipo de movimiento y fecha de control, con una diferencia de minutos, pero asociados a otro registro de identidad con una nacionalidad diferente, perteneciente a la misma persona.
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