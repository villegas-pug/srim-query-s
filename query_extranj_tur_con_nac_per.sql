USE SIM
GO

/*
   [4:50 p. m., 10/7/2024] Manuel: Relación de extranjeros que ingresaron desde el.2020 al 2024 como turistas
   [4:50 p. m., 10/7/2024] Manuel: O calidad migratoria temporal
   [4:50 p. m., 10/7/2024] Manuel: Que no tienen salida posteriores del.pais

*/

/* Calidad Migratoria:
   41    | TURISTA | T
   227   | TURISTA | T

*/

-- 1. ...

-- 1.1: Registro de ciudadanos `VEN`, que INGRESARON y no registran SALIDAD ...
DROP TABLE IF EXISTS #tmp_ult_mm_ext
SELECT mm2.* INTO #tmp_ult_mm_ext
FROM (

   SELECT 
      mm.uIdPersona,
      [dFechaControl(Ultimo)] = mm.dFechaControl,
      [sTipoMovimiento(Ultimo)] = mm.sTipo,
      [nIdCalidadMovimiento(Ultimo)] = cm.nIdCalidad,
      [sCalidadMigratorioMovimiento(Ultimo)] = cm.sDescripcion,

      -- Aux
      [nIdDocumentoViaje(Ultimo)] = mm.sIdDocumento,
      [sDocumentoViaje(Ultimo)] = mm.sNumeroDoc,
      -- [sExceso(180d)] = IIF(DATEDIFF(DD, mm.dFechaControl, GETDATE()) > 180, 'Si', 'No'),

      -- Aux 2
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2000-01-01 00:00:00.000'
      -- AND mm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero
      AND pe.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero
      /* AND mm.sIdPaisNacionalidad = 'VEN' -- Extranjero
      AND pe.sIdPaisNacionalidad = 'VEN' -- Extranjero */

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.[sTipoMovimiento(Ultimo)] = 'E'
   -- AND mm2.[nIdCalidad(Ultimo)] IN (41, 227)
   AND mm2.[nIdCalidadMovimiento(Ultimo)] IN ( -- Calidades: T → Temporales ...
                                                SELECT cm.nIdCalidad
                                                FROM SimCalidadMigratoria cm
                                                WHERE
                                                   cm.bActivo = 1
                                                   AND cm.sTipo = 'T'
   )

-- 1.2 Datos adicionales a extranjeros y crea `sIdPersona` ...
DROP TABLE IF EXISTS #tmp_ult_mm_ext_dat
SELECT -- Datos extranjero
   e.*,
   [sIdPersona] = REPLACE(CONCAT(pe_e.sNombre, pe_e.sPaterno, pe_e.sMaterno, pe_e.sSexo, CAST(pe_e.dFechaNacimiento AS FLOAT)), ' ', ''),
   pe_e.sNombre,
   pe_e.sPaterno,
   pe_e.sMaterno,
   pe_e.sSexo,
   pe_e.dFechaNacimiento,
   pe_e.sIdPaisNacionalidad,

   -- Aux
   pe_e.sIdDocIdentidad,
   pe_e.sNumDocIdentidad

   INTO #tmp_ult_mm_ext_dat
FROM #tmp_ult_mm_ext e
JOIN SimPersona pe_e ON e.uIdPersona = pe_e.uIdPersona

CREATE NONCLUSTERED INDEX ix_tmp_ult_mm_ext_dat
   ON #tmp_ult_mm_ext_dat(sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento)

-- 2. ...

-- 2.1. Multiplicidad de extranjeros con nacionalidad `PER` ...
DROP TABLE IF EXISTS #tmp_ult_mm_ext_con_nac_per
SELECT 
   [sIdPersona] = REPLACE(CONCAT(pe.sNombre, pe.sPaterno, pe.sMaterno, pe.sSexo, CAST(pe.dFechaNacimiento AS FLOAT)), ' ', ''),
   pe.*
   INTO #tmp_ult_mm_ext_con_nac_per
FROM SimPersona pe
WHERE
   pe.bActivo = 1
   AND EXISTS (
                  SELECT 1
                  FROM #tmp_ult_mm_ext_dat e
                  WHERE
                     e.uIdPersona != pe.uIdPersona
                     AND pe.sIdPaisNacionalidad = 'PER'
                     AND DIFFERENCE(e.sNombre, pe.sNombre) >= 3
                     AND e.sPaterno = pe.sPaterno
                     AND e.sMaterno = pe.sMaterno
                     AND e.sSexo = pe.sSexo
                     AND e.dFechaNacimiento = pe.dFechaNacimiento
                     /* AND EXISTS ( -- Registre `DNI`

                                    SELECT TOP 1 1
                                    FROM SimDocPersona dp
                                    WHERE
                                       dp.bActivo = 1
                                       AND dp.uIdPersona = pe.uIdPersona
                                       AND dp.sIdDocumento = 'DNI'
                                       -- AND ISNUMERIC(dp.sNumero) = 1
                                       -- AND LEN(dp.sNumero) = 8

                     ) */
   )

-- 2.2. Ultimo control migratorio de posibles extranjeros con nacionalidad `PER` ...
DROP TABLE IF EXISTS #tmp_ult_mm_ext_con_nac_per_ult_mm
SELECT 
   p_mm.* ,

   -- Aux
   sIdDocIdentidad = (
                        SELECT TOP 1 dp.sIdDocumento 
                        FROM SimDocPersona dp
                        WHERE
                           dp.bActivo = 1
                           AND dp.uIdPersona = p_mm.uIdPersona
                        ORDER BY dp.dFechaHoraAud DESC
   ),
   sNumDocIdentidad = (
                        SELECT TOP 1 dp.sNumero 
                        FROM SimDocPersona dp
                        WHERE
                           dp.bActivo = 1
                           AND dp.uIdPersona = p_mm.uIdPersona
                        ORDER BY dp.dFechaHoraAud DESC
   )

   INTO #tmp_ult_mm_ext_con_nac_per_ult_mm
FROM (

   SELECT 

      -- Datos control ...
      p.uIdPersona,
      [dFechaControl(Ultimo)] = IIF(mm.bTemporal = 1 OR mm.bAnulado = 1, NULL, mm.dFechaControl),
      [sTipoMovimiento(Ultimo)] = IIF(mm.bTemporal = 1 OR mm.bAnulado = 1, NULL, mm.sTipo),
      [nIdCalidad(Ultimo)] = IIF(mm.bTemporal = 1 OR mm.bAnulado = 1, NULL, cm.nIdCalidad),
      [sCalidadMigratorio(Ultimo)] = IIF(mm.bTemporal = 1 OR mm.bAnulado = 1, NULL, cm.sDescripcion),
      [nIdDocumentoViaje(Ultimo)] = IIF(mm.bTemporal = 1 OR mm.bAnulado = 1, NULL, mm.sIdDocumento),
      [sDocumentoViaje(Ultimo)] = IIF(mm.bTemporal = 1 OR mm.bAnulado = 1, NULL, mm.sNumeroDoc),

      -- [sExceso(180d)] = '',

      [#] = ROW_NUMBER() OVER (PARTITION BY p.uIdPersona ORDER BY mm.dFechaControl DESC),

      -- Datos adicionales
      p.sIdPersona,
      p.sNombre,
      p.sPaterno,
      p.sMaterno,
      p.sSexo,
      p.dFechaNacimiento,
      p.sIdPaisNacionalidad
      
   FROM #tmp_ult_mm_ext_con_nac_per p
   LEFT JOIN SimMovMigra mm ON p.uIdPersona = mm.uIdPersona
   LEFT JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
   /* WHERE 
      (
         CASE
            WHEN mm.sIdMovMigratorio IS NULL THEN 0 -- Sin registro ...
            WHEN mm.sIdMovMigratorio IS NOT NULL AND (mm.bAnulado = 1 OR mm.bTemporal = 1) THEN 0 -- Tiene registros anulados o temporales ...
            ELSE 0
         END
      ) = 0 */

) p_mm
WHERE
   p_mm.[#] = 1

-- Test
-- 1. Revisar compatibilidad de modelo
SELECT TOP 1 * FROM #tmp_ult_mm_ext_dat
SELECT TOP 1 * FROM #tmp_ult_mm_ext_con_nac_per_ult_mm

-- 5. Final
-- 5.1 No registran salidad `EXTRANJ` ...
-- SELECT COUNT(1) FROM #tmp_ult_mm_ext_dat
SELECT
   e.*,
   [sCalidadMigratoria(Ultima)] = cm.sDescripcion,
   [dFechaAprobacionCalidad(Ultima)] = uc.dFechaAprobacionCalidad
FROM #tmp_ult_mm_ext_dat e
LEFT JOIN BD_SIRIM.dbo.RimUltimaCalidadExtranjero uc ON e.uIdPersona = uc.uIdPersona
LEFT JOIN SimCalidadMigratoria cm ON uc.nIdCalidadSolicitada = cm.nIdCalidad

-- 5.2. Unión de `EXTRANJ` y posible nacionalidad `PER` ...
SELECT
   f.*
FROM (

   SELECT 
      u.*,
      [nMult] = COUNT(1) OVER (PARTITION BY u.sIdPersona)
   FROM (

      SELECT * FROM #tmp_ult_mm_ext_dat
      UNION ALL
      SELECT * FROM #tmp_ult_mm_ext_con_nac_per_ult_mm

   ) u

) f
WHERE
   f.[nMult] > 1
ORDER BY
   f.sIdPersona




-- Test:
-- 1
SELECT * 
FROM SimCalidadMigratoria cm
WHERE
   cm.bActivo = 1
   AND cm.sDescripcion LIKE '%turista%' 