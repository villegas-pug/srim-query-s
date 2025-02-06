USE SIM
GO


-- IRN | IRAN	IRANI
-- VEN | ...

-- 1. Por registros duplicados:
-- 1.1 Crea identificador axiliar ...
DROP TABLE IF EXISTS #tmp_persona
SELECT

   [sIdPersona] = REPLACE(CONCAT(pe.sPaterno, pe.sMaterno, pe.sNombre, pe.sSexo, TRY_CAST(pe.dFechaNacimiento AS INT), pe.sIdPaisNacimiento), ' ', ''),
   pe.uIdPersona,
   pe.sPaterno,
   pe.sMaterno,
   pe.sNombre,
   pe.sSexo,
   pe.dFechaNacimiento,
   pe.sIdPaisNacimiento,
   pe.sIdPaisResidencia,
   pe.sIdPaisNacionalidad

   INTO #tmp_persona
FROM SimPersona pe
WHERE
   pe.bActivo = 1

CREATE NONCLUSTERED INDEX #tmp_persona_ids 
   ON #tmp_persona(sIdPersona, uIdPersona)

-- 2. Filtro:  ...
DROP TABLE IF EXISTS #tmp_ven_y_irn
SELECT 
   pe.*
   INTO #tmp_ven_y_irn
FROM #tmp_persona pe
WHERE
   pe.sIdPaisNacionalidad IN ('IRN', 'VEN')

CREATE NONCLUSTERED INDEX tmp_ven_y_irn_ids
   ON #tmp_ven_y_irn(sIdPersona, uIdPersona)

-- 3. Final
-- 3.1
SELECT f2.* 
FROM (

   SELECT
      f.*,
      -- [nTotalNacionalidad] = COUNT(1) OVER (PARTITION BY f.[sIdPersona(Principal)]) + 1, -- Más la nacionalidad del titular ...
      [#] = ROW_NUMBER() OVER (PARTITION BY f.[sIdPersona(Principal)] ORDER BY f.[sIdPersona(Principal)])
   FROM (

      SELECT

         [sIdPersona(Principal)] = e.sIdPersona,
         [uIdPersona(Principal)] = e.uIdPersona,
         [sNombre(Principal)] = e.sNombre,
         [sPaterno(Principal)] = e.sPaterno,
         [sMaterno(Principal)] = e.sMaterno,
         [sIdPaisNacionalidad(Principal)] = e.sIdPaisNacionalidad,
         [sIdPaisNacimiento(Principal)] = e.sIdPaisNacimiento,
         [sSexo(Principal)] = e.sSexo,
         [dFechaNacimiento(Principal)] = e.dFechaNacimiento,
         [sUltTipoMov(Principal)] = (
                                       SELECT TOP 1 mm.sTipo 
                                       FROM SimMovMigra mm
                                       WHERE
                                          mm.bAnulado = 0
                                          AND mm.bTemporal = 0
                                          AND mm.uIdPersona = e.uIdPersona
                                       ORDER BY mm.dFechaControl DESC
                                    ),
         [dUltFechaControl(Principal)] = (
                                             SELECT TOP 1 mm.dFechaControl 
                                             FROM SimMovMigra mm
                                             WHERE
                                                mm.bAnulado = 0
                                                AND mm.bTemporal = 0
                                                AND mm.uIdPersona = e.uIdPersona
                                             ORDER BY mm.dFechaControl DESC
         ),

         -- Otra nacionalidad
         [sIdPersona(Secundario)] = p.sIdPersona,
         [uIdPersona(Secundario)] = p.uIdPersona,
         [sNombre(Secundario)] = p.sNombre,
         [sPaterno(Secundario)] = p.sPaterno,
         [sMaterno(Secundario)] = p.sMaterno,
         [sIdPaisNacionalidad(Secundario)] = p.sIdPaisNacionalidad,
         [sIdPaisNacimiento(Secundario)] = p.sIdPaisNacimiento,
         [sSexo(Secundario)] = p.sSexo,
         [dFechaNacimiento(Secundario)] = p.dFechaNacimiento,
         [sUltTipoMov(Secundario)] = (
                                       SELECT TOP 1 mm.sTipo 
                                       FROM SimMovMigra mm
                                       WHERE
                                          mm.bAnulado = 0
                                          AND mm.bTemporal = 0
                                          AND mm.uIdPersona = p.uIdPersona
                                       ORDER BY mm.dFechaControl DESC
                                    ),
         [dUltFechaControl(Secundario)] = (
                                             SELECT TOP 1 mm.dFechaControl 
                                             FROM SimMovMigra mm
                                             WHERE
                                                mm.bAnulado = 0
                                                AND mm.bTemporal = 0
                                                AND mm.uIdPersona = p.uIdPersona
                                             ORDER BY mm.dFechaControl DESC
         ),
         [sTituloNacionalidad(Secundario)] = (
                                                SELECT t.sNumeroTitulo
                                                FROM SimTituloNacionalidad t
                                                WHERE
                                                   t.uIdPersonaNac = p.uIdPersona
         ),
         [sNumeroTramite(Secundario)] = (
                                          SELECT t.sNumeroTramite
                                          FROM SimTituloNacionalidad t
                                          WHERE
                                             t.uIdPersonaNac = p.uIdPersona
         ),
         [sTipoNacionalidad(Secundario)] = (
                                             SELECT tt.sDescripcion
                                             FROM SimTituloNacionalidad t
                                             JOIN SimTramite tr ON tr.sNumeroTramite = t.sNumeroTramite
                                             JOIN SimTipoTramite tt ON tr.nIdTipoTramite = tt.nIdTipoTramite
                                             WHERE
                                                t.uIdPersonaNac = p.uIdPersona
         )


      FROM BD_SIRIM.dbo.tmp_ven_y_irn e
      JOIN BD_SIRIM.dbo.tmp_persona p ON e.sIdPersona = p.sIdPersona -- Duplicado
                                    AND e.uIdPersona != p.uIdPersona -- Registro !=
                                    -- AND e.sIdPaisNacionalidad != p.sIdPaisNacionalidad -- Nacionalidad !=
                                    AND p.sIdPaisNacionalidad = 'PER' -- Nacionalidad `PER`

   ) f
   /* WHERE 
      -- f.[#] = 1
      EXISTS ( -- Otra nacionalidad con título de `PER`
               SELECT TOP 1 1
               FROM SimTituloNacionalidad t
               WHERE
                  t.bEntregado = 1
                  AND t.uIdPersonaNac = f.[uIdPersona(Secundario)]
      ) */

) f2
WHERE
   f2.[#] = 1


-- 2. Por título de nacionalidad

SELECT
   
   [uIdPersona(Principal)] = ex.uIdPersona,
   [sNombre(Principal)] = ex.sNombre,
   [sPaterno(Principal)] = ex.sPaterno,
   [sMaterno(Principal)] = ex.sMaterno,
   [sIdPaisNacionalidad(Principal)] = ex.sIdPaisNacionalidad,
   [sIdPaisNacimiento(Principal)] = ex.sIdPaisNacimiento,
   [sSexo(Principal)] = ex.sSexo,
   [dFechaNacimiento(Principal)] = ex.dFechaNacimiento,
   [sUltTipoMov(Principal)] = (
                                 SELECT TOP 1 mm.sTipo 
                                 FROM SimMovMigra mm
                                 WHERE
                                    mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                    AND mm.uIdPersona = ex.uIdPersona
                                 ORDER BY mm.dFechaControl DESC
                              ),
   [dUltFechaControl(Principal)] = (
                                       SELECT TOP 1 mm.dFechaControl 
                                       FROM SimMovMigra mm
                                       WHERE
                                          mm.bAnulado = 0
                                          AND mm.bTemporal = 0
                                          AND mm.uIdPersona = ex.uIdPersona
                                       ORDER BY mm.dFechaControl DESC
   ),

   -- Peruano
   [uIdPersona(Peruano)] = pe.uIdPersona,
   [sNombre(Peruano)] = pe.sNombre,
   [sPaterno(Peruano)] = pe.sPaterno,
   [sMaterno(Peruano)] = pe.sMaterno,
   [sIdPaisNacionalidad(Peruano)] = pe.sIdPaisNacionalidad,
   [sIdPaisNacimiento(Peruano)] = pe.sIdPaisNacimiento,
   [sSexo(Peruano)] = pe.sSexo,
   [dFechaNacimiento(Peruano)] = pe.dFechaNacimiento,
   [sUltTipoMov(Peruano)] = (
                                 SELECT TOP 1 mm.sTipo 
                                 FROM SimMovMigra mm
                                 WHERE
                                    mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                    AND mm.uIdPersona = pe.uIdPersona
                                 ORDER BY mm.dFechaControl DESC
                              ),
   [dUltFechaControl(Peruano)] = (
                                       SELECT TOP 1 mm.dFechaControl 
                                       FROM SimMovMigra mm
                                       WHERE
                                          mm.bAnulado = 0
                                          AND mm.bTemporal = 0
                                          AND mm.uIdPersona = pe.uIdPersona
                                       ORDER BY mm.dFechaControl DESC
   ),
   [sTituloNacionalidad(Peruano)] = t.sNumeroTitulo,
   [sNumeroTramite(Peruano)] = t.sNumeroTramite,
   [sTipoNacionalidad(Peruano)] = tt.sDescripcion

FROM SimTituloNacionalidad t
JOIN SimPersona ex ON t.uIdPersona = ex.uIdPersona
JOIN SimPersona pe ON t.uIdPersonaNac = pe.uIdPersona
JOIN SimTramite tr ON t.sNumeroTramite = tr.sNumeroTramite
JOIN SimTipoTramite tt ON tr.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   ex.sIdPaisNacionalidad IN ('IRN', 'VEN')
   -- t.sIdPaisNacimiento IN ('IRN', 'VEN')


-- Test
SELECT * INTO BD_SIRIM.dbo.tmp_persona FROM #tmp_persona
SELECT * INTO BD_SIRIM.dbo.tmp_ven_y_irn FROM #tmp_ven_y_irn

SELECT TOP 10 * FROM BD_SIRIM.dbo.tmp_persona

SELECT * FROM SimMotivoViaje

SELECT TOP 100 * 
FROM SimMovMigra mm
WHERE
   mm.nIdMotivoViaje = 11 -- 11 | DEPORTADOS
ORDER BY mm.dFechaControl DESC


SELECT COUNT(1)
FROM SimTramiteNac n
JOIN SimTramite t ON n.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   n.sEstadoActual = 'A'
   AND pe.sIdPaisNacionalidad = 'VEN'


SELECT * 
FROM SimTipoTramite tt
WHERE tt.sDescripcion LIKE '%nacio%'