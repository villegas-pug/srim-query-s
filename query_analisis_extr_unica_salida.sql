USE SIM
GO


-- 1. ...

-- 1.1: Registro de ciudadanos `EXTRANJEROS`, que no registran SALIDAD ...
DROP TABLE IF EXISTS #tmp_ult_mm_ext_irr
SELECT 
   mm2.* INTO #tmp_ult_mm_ext_irr
FROM (

   SELECT 
      mm.*,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      AND pe.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.[sTipo] = 'E'
   AND EXISTS ( -- Consulta irregulares
                  SELECT TOP 1 1 
                  FROM xTotalExtranjerosPeru e
                  WHERE
                     e.uIdPersona = mm2.uIdPersona
                     AND e.CalidadTipo NOT IN ('N', 'R')
   )


-- 1.1: Registro de ciudadanos `EXTRANJEROS`, con único momiviento de `SALIDA` ...
DROP TABLE IF EXISTS #tmp_unico_mm_ult_mm_salida
SELECT 
   mm2.* INTO #tmp_unico_mm_ult_mm_salida
FROM (

   SELECT 
      mm.*,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC),
      [nContarMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona)
   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl <= '2024-07-15 23:59:59.999'
      AND pe.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Extranjero

) mm2
WHERE
   mm2.[#] = 1 -- Último registro
   AND mm2.[nContarMM] = 1 -- Único registro
   AND mm2.[sTipo] = 'S'
   

-- 2. Final

-- 2.1 Bak
SELECT * INTO BD_SIRIM.dbo.tmp_ult_mm_ext_irr FROM #tmp_ult_mm_ext_irr
SELECT * INTO BD_SIRIM.dbo.tmp_unico_mm_ult_mm_salida FROM #tmp_unico_mm_ult_mm_salida

-- 2.2 Cuantos coincidencias por `uId` ...
SELECT -- 0
   COUNT(1) 
FROM #tmp_ult_mm_ext_irr i
WHERE
   EXISTS (
      SELECT 1
      FROM #tmp_unico_mm_ult_mm_salida s
      WHERE
         s.uIdPersona = i.uIdPersona
   )

-- 2.3 Cuantos coincidencias por `uId` ...

-- 2.3.1
DROP TABLE IF EXISTS #tmp_ext
SELECT 
   [sIdPersona] = REPLACE(CONCAT(SOUNDEX(e.sNombre), e.sPaterno, e.sMaterno, e.sIdPaisNacionalidad, CAST(e.dFechaNacimiento AS FLOAT)), ' ', ''),
   e.*
   INTO #tmp_ext
FROM SimPersona e
WHERE
   e.bActivo = 1
   AND e.sIdPaisNacionalidad NOT IN ('PER', 'NNN')
   
-- 2.3.2
SELECT TOP 10 * FROM BD_SIRIM.dbo.tmp_ult_mm_ext_irr


;WITH cte_um AS ( -- Ultimo movimiento migratorio es `ENTRADA` ...

   SELECT
      [sIdMovMigratorio(IrreEnPeru)] = um.sIdMovMigratorio,
      [sTipo(IrreEnPeru)] = um.sTipo,
      [dFechaControl(IrreEnPeru)] = um.dFechaControl,
      [uIdPersona(IrreEnPeru)] = pe.uIdPersona,
      [sNombre(IrreEnPeru)] = pe.sNombre,
      [sPaterno(IrreEnPeru)] = pe.sPaterno,
      [sMaterno(IrreEnPeru)] = pe.sMaterno,
      [sSexo(IrreEnPeru)] = pe.sSexo,
      [dFechaNacimiento(IrreEnPeru)] = pe.dFechaNacimiento,
      [sIdPaisNacionalidad(IrreEnPeru)] = pe.sIdPaisNacionalidad
   FROM BD_SIRIM.dbo.tmp_ult_mm_ext_irr um
   JOIN SimPersona pe ON um.uIdPersona = pe.uIdPersona

), cte_us AS ( -- Registran 1 solo movimiento migratorio de `SALIDA` ...

   SELECT
      [sIdMovMigratorio(1Salida)] = us.sIdMovMigratorio,
      [sTipo(1Salida)] = us.sTipo,
      [dFechaControl(1Salida)] = us.dFechaControl,
      [uIdPersona(1Salida)] = pe.uIdPersona,
      [sNombre(1Salida)] = pe.sNombre,
      [sPaterno(1Salida)] = pe.sPaterno,
      [sMaterno(1Salida)] = pe.sMaterno,
      [sSexo(1Salida)] = pe.sSexo,
      [dFechaNacimiento(1Salida)] = pe.dFechaNacimiento,
      [sIdPaisNacionalidad(1Salida)] = pe.sIdPaisNacionalidad
   FROM BD_SIRIM.dbo.tmp_unico_mm_ult_mm_salida us
   JOIN SimPersona pe ON us.uIdPersona = pe.uIdPersona

), cte_final AS (

   SELECT * 
   FROM cte_us us
   JOIN cte_um ue ON us.[uIdPersona(1Salida)] != ue.[uIdPersona(IrreEnPeru)]
                     AND DIFFERENCE(us.[sNombre(1Salida)], ue.[sNombre(IrreEnPeru)]) <= 3
                     AND us.[sPaterno(1Salida)] = ue.[sPaterno(IrreEnPeru)]
                     AND us.[sMaterno(1Salida)] = ue.[sMaterno(IrreEnPeru)]
                     -- AND us.[sSexo(1Salida)] = ue.[sSexo(IrreEnPeru)]
                     AND us.[dFechaNacimiento(1Salida)] = ue.[dFechaNacimiento(IrreEnPeru)]
                     AND us.[sIdPaisNacionalidad(1Salida)] = ue.[sIdPaisNacionalidad(IrreEnPeru)]
                     /* AND (
                              CAST(us.[dFechaControl(1Salida)] AS DATE) = CAST(ue.[dFechaControl(IrreEnPeru)] AS DATE )
                              AND us.[dFechaControl(1Salida)] > ue.[dFechaControl(IrreEnPeru)] -- Única salida mayor a ultima entrada

                           ) */

)
SELECT * FROM cte_final


