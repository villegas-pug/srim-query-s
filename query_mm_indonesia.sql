USE SIM
GO

-- 
/*
   IDO | INDONESIA
   KAZ | KAZAJSTAN
 */

-- Movimientos migratorios de ciudadanos IDO
SELECT 
   pv.*
   -- INTO #tmp_mm_per_dest_mex
FROM (

   SELECT

      -- [Id Persona] = mm.uIdPersona,
      -- [Pais Destino] = mm.sIdPaisMov,
      mm.sIdMovMigratorio,
      [Año Control] = DATEPART(YYYY, mm.dFechaControl),
      [Tipo Movimiento] = mm.sTipo,
      [Dependencia] = d.sNombre

   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl BETWEEN '2019-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
      AND pe.sIdPaisNacionalidad = 'KAZ' -- IDO | INDONESIA

) mm2
PIVOT (
   COUNT(mm2.sIdMovMigratorio) FOR mm2.[Año Control] IN ([2019], [2020], [2021], [2022], [2023], [2024])
) pv


-- 2 Cubanos:
-- 2.1
SELECT

   mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Mov] = mm.sTipo,
   [Calidad Migratoria] = cm.sDescripcion,
   [Procedencia] = mm.sIdPaisMov

FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdPaisMov = 'COL'
   AND mm.sTipo = 'E'
   AND pe.sIdPaisNacionalidad = 'CUB'
   AND mm.dFechaControl >= '2019-01-01 00:00:00.000'

-- 2.2 Puesto de control por meses:
SELECT p.* 
FROM (

   SELECT 
      f.sIdMovMigratorio,
      f.nMesControl,
      f.sDependencia
   FROM (
      SELECT
         mm.sIdMovMigratorio,
         [nMesControl] = DATEPART(MM, mm.dFechaControl),
         [sDependencia] = d.sNombre,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

      FROM SimMovMigra mm
      JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
      JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.sTipo = 'E'
         AND pe.sIdPaisNacionalidad = 'CUB'
         AND mm.sIdProfesion = '002' -- 002 | MEDICO
         AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
   ) f
   /* WHERE 
      -f.[#] = 1 -- Personas */
) f2
PIVOT (
   COUNT(f2.sIdMovMigratorio) FOR f2.[nMesControl] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) p

-- 2.2 Flujo migratorio
SELECT p.*
FROM (

   SELECT 
      f.sIdMovMigratorio,
      f.sDependencia,
      f.sTipo,
      [nMesControl] = DATEPART(MM, f.dFechaControl)
   FROM (
      SELECT
         mm.*,
         [sDependencia] = d.sNombre,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
      JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND pe.sIdPaisNacionalidad = 'CUB'
         AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
   ) f

) f2
PIVOT (
   COUNT(f2.sIdMovMigratorio) FOR f2.[nMesControl] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) p

-- 2.3 Tiempo de permanencia entre ultima entrada y ultima salida

;WITH cte_mm_cub_2024 AS (-- Filtramos solo los movimientos del año 2023

   SELECT 
      mm.sIdMovMigratorio,
      mm.uIdPersona,
      mm.sTipo,
      mm.dFechaControl,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uidPersona ORDER BY mm.dFechaControl ASC)
   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dfechacontrol BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.998'
      AND pe.sIdPaisNacionalidad = 'CUB'

), cte_mm_cub_2024_final AS ( -- Asociamos cada "E" con la siguiente "S" para la misma persona

    SELECT
        e.uidPersona,
        [dFechaEntrada] = e.dfechacontrol,
        [dFechaSalida] = s.dfechacontrol,
        [nDiasPermanencia] = DATEDIFF(DAY, e.dfechacontrol, s.dfechacontrol)
    FROM cte_mm_cub_2024 e
    JOIN cte_mm_cub_2024 s ON e.uIdPersona = s.uIdPersona
                           AND e.[#] + 1 = s.[#]
    WHERE 
        e.sTipo = 'E'
        AND s.sTipo = 'S'

) -- Seleccionamos el resultado final
SELECT 
   f.uIdPersona,
   f.dFechaEntrada,
   f.dFechaSalida,
   f.nDiasPermanencia
FROM cte_mm_cub_2024_final f



-- 2.4 Tiempo de permanencia entre ultima entrada y ultima salida
SELECT

   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Adicional
   [Ultimo Movimiento] = IIF(f2.sTipo = 'E', 'ENTRADA', 'SALIDA'),
   [Ultima Fecha Movimiento] = f2.dFechaControl,
   f2.[nRangoDias(Perm)]

FROM (

   SELECT 
      f.*,
      [nRangoDias(Perm)] = 
                           DATEDIFF(
                                       DD,
                                       LAST_VALUE(f.dFechaControl) OVER (
                                                                        PARTITION BY f.uIdPersona 
                                                                        ORDER BY f.dFechaControl DESC
                                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                  ),
                                       FIRST_VALUE(f.dFechaControl) OVER (
                                                                           PARTITION BY f.uIdPersona 
                                                                           ORDER BY f.dFechaControl DESC
                                                                           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                        )
                           )
   FROM (
      SELECT
         mm.*,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC),
         [nCantMov] = COUNT(1) OVER (PARTITION BY mm.uIdPersona),
         [nCantMov] = COUNT(1) OVER (PARTITION BY mm.uIdPersona),
         [bPrimerMov(E)] = (
                              CASE
                                 WHEN (
                                          LAST_VALUE(mm.sTipo) OVER (
                                                                        PARTITION BY mm.uIdPersona
                                                                        ORDER BY mm.dFechaControl DESC
                                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                     )
                                       ) = 'E' 
                                 THEN 1
                                 ELSE 0
                              END
         ),
         [bUltMov(S)] = (
                           CASE
                              WHEN (
                                       FIRST_VALUE(mm.sTipo) OVER (
                                                                     PARTITION BY mm.uIdPersona 
                                                                     ORDER BY mm.dFechaControl DESC
                                                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                  )
                                    ) = 'S' 
                              THEN 1
                              ELSE 0
                           END
         )
      FROM SimMovMigra mm
      JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND pe.sIdPaisNacionalidad = 'CUB'
         AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
   ) f
   WHERE
      f.[nCantMov] >= 2
      AND f.[#] IN (1, 2)
      AND f.[bPrimerMov(E)] = 1 -- Primer movimiento: Entrada
      AND f.[bUltMov(S)] = 1 -- Ultimo movimiento: Salida
) f2
JOIN SimPersona pe ON f2.uIdPersona = pe.uIdPersona
WHERE
   f2.[#] = 1





-- 2.4 No registran salida
SELECT p.*
FROM (
   SELECT 
      f.sIdMovMigratorio,
      f.sDependencia,
      f.sTipo,
      [nMesControl] = DATEPART(MM, f.dFechaControl)
   FROM (
      SELECT
         mm.*,
         [sDependencia] = d.sNombre,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SimMovMigra mm
      JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
      JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND pe.sIdPaisNacionalidad = 'CUB'
         -- AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
         AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
   ) f
   WHERE 
      f.[#] = 1
      AND f.sTipo = 'E'
) f2
PIVOT (
   COUNT(f2.sIdMovMigratorio) FOR f2.[nMesControl] IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) p




-- 3. Chinos de Taiwan, Taipei, Honkon desde 2016.
/*
   → TWN | TAIWAN (CHN)
   → HNK | HONG KONG
*/

-- 3.1 Flujo migratorio
SELECT p.*
FROM (
   SELECT 
      f.sIdMovMigratorio,
      [sTipo] = IIF(f.sTipo = 'E', 'ENTRADAS', 'SALIDAS'),
      [nMesControl] = DATEPART(yyyy, f.dFechaControl)
   FROM (
      SELECT
         mm.*
      FROM SimMovMigra mm
      JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND pe.sIdPaisNacionalidad IN ('TWN', 'HNK')
         AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
   ) f
) f2
PIVOT (
   COUNT(f2.sIdMovMigratorio) FOR f2.[nMesControl] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023], [2024], [2025])
) p

-- Por calidad migratoria por datos generales



SELECT 
   [sCalidadMigratoria] = cm.sDescripcion,
   [nTotal] = COUNT(1)
FROM SimPersona pe
JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
WHERE
   pe.bActivo = 1
   AND pe.sIdPaisNacionalidad IN ('TWN', 'HNK')
   AND pe.uIdPersona IN (
            SELECT DISTINCT mm.uIdPersona
            FROM SimMovMigra mm
            WHERE
               mm.bAnulado = 0
               AND mm.bTemporal = 0
               AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
   )
GROUP BY
   cm.sDescripcion
ORDER BY 2 DESC





-- Test
SELECT * 
FROM SimProfesion p
WHERE p.sDescripcion LIKE '%medi%'










