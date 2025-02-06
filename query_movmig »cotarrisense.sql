USE SIM
GO

/* 
   Personas extranjeras de nacionalidad salvadoreña ( EL salvador), 
   que hayan entrado al país en el año 2022 y 2023, y que no hayan salido del país. 
 ========================================================================================================================================== */

-- SAL | EL SALVADOR
SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%salva%'

-- 1:
DROP TABLE IF EXISTS #tmp_mm_sal
SELECT

   [Documento Viaje] = smm.sIdDocumento,
   [Num Doc Viaje] = CONCAT('''', smm.sNumeroDoc),
   [Nombre] = sper.sNombre,
   [Paterno] = sper.sPaterno,
   [Materno] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sper.dFechaNacimiento,
   [Pais Nacimiento] = sper.sIdPaisNacimiento,
   [Pais Residencia] = sper.sIdPaisResidencia,
   [Pais Nacionalidad] = sper.sIdPaisNacionalidad,
   [Ultimo Movimiento] = smm.sTipo,
   [Ultimo Año Movimiento] = DATEPART(YYYY, smm.dFechaControl),
   [Ultimo Fecha Movimiento] = smm.dFechaControl,
   [Calidad Migratoria] = scm.sDescripcion,

   [sNombre_dx] = SOUNDEX(sper.sNombre),
   [sPaterno_dx] = SOUNDEX(sper.sPaterno),
   [sMaterno_dx] = SOUNDEX(sper.sMaterno),

   smm.*

   INTO #tmp_mm_sal
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.dFechaControl >= '2022-01-01 00:00:00.00'
   AND smm.sIdPaisNacionalidad = 'SAL'


-- 2
SELECT mm2.* FROM (

   SELECT 

      mm.*,

      -- Aux ...
      [nMovMigraByDesc] = ROW_NUMBER() OVER (
                                                PARTITION BY 
                                                   -- opt 1 ...
                                                   mm.sNombre_dx,
                                                   mm.sPaterno_dx,
                                                   mm.sMaterno_dx,
                                                   mm.Sexo,
                                                   mm.[Fecha Nacimiento],
                                                   mm.[Pais Nacionalidad]

                                                ORDER BY 
                                                   mm.dFechaControl DESC
                                             )
   FROM #tmp_mm_sal mm

) mm2
WHERE
   mm2.nMovMigraByDesc = 1
   AND mm2.[Ultimo Movimiento] = 'E'

-- Test ...
SELECT SOUNDEX('kisolpe'), SOUNDEX('kaselpi')
SELECT SOUNDEX('Carlos'), SOUNDEX('kaselpi')



 -- ========================================================================================================================================== */







 /* 
   → Dobles registros con movimientos migratorios ...
 ========================================================================================================================================== */

EXEC sp_help SimPersona

-- 1: SimPersona con movimientos migratorios ...

DROP TABLE IF EXISTS #tmp_per_con_movmig
SELECT

   sper.uIdPersona,
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sper.sSexo,
   sper.dFechaNacimiento,
   sper.sIdPaisNacionalidad,
   smm.sIdDocumento,
   smm.sNumeroDoc

   INTO #tmp_per_con_movmig
FROM SimPersona sper
JOIN SimMovMigra smm ON sper.uIdPersona = smm.uIdPersona
WHERE 
   smm.bAnulado = 0
   AND smm.bTemporal = 0

-- Index ...
CREATE NONCLUSTERED INDEX ix_tmp_per_con_movmig_uIdPersona
   ON #tmp_per_con_movmig(uIdPersona)

CREATE NONCLUSTERED INDEX ix_tmp_per_con_movmig_datos
   ON #tmp_per_con_movmig(sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento, sIdPaisNacionalidad, sIdDocumento, sNumeroDoc)

-- 2: Identificar multiplicidad ...
DROP TABLE IF EXISTS #tmp_per_con_movmig_2
SELECT 
   p2.*
   INTO #tmp_per_con_movmig_2
FROM (

   SELECT
      p.*,
      [nDupl] = ROW_NUMBER() OVER (
                                    PARTITION BY
                                       p.uIdPersona,
                                       p.sIdDocumento,
                                       p.sNumeroDoc
                                    ORDER BY
                                       p.uIdPersona
                                 )
      
   FROM #tmp_per_con_movmig p

) p2
WHERE
   p2.nDupl = 1

-- Index ...
CREATE NONCLUSTERED INDEX ix_tmp_per_con_movmig_2_uIdPersona
   ON #tmp_per_con_movmig_2(uIdPersona)

CREATE NONCLUSTERED INDEX tmp_per_con_movmig_2_datos
   ON #tmp_per_con_movmig_2(sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento, sIdPaisNacionalidad, sIdDocumento, sNumeroDoc)

-- 3: Final ...
DROP TABLE IF EXISTS #tmp_per_con_movmig_3
SELECT p2.* INTO #tmp_per_con_movmig_3 FROM (

   SELECT 
      p.*,
      [nDupl_mm] = COUNT(1) OVER (
                                    PARTITION BY
                                       p.sNombre,
                                       p.sPaterno,
                                       p.sMaterno,
                                       p.sSexo,
                                       p.dFechaNacimiento,
                                       p.sIdPaisNacionalidad,
                                       p.sIdDocumento,
                                       p.sNumeroDoc
                                 )
   
   FROM #tmp_per_con_movmig_2 p

) p2
WHERE
   p2.nDupl_mm >= 2

-- Test ...
SELECT p.* FROM #tmp_per_con_movmig_3 p
SELECT 
   -- TOP 100 
   p.* 
FROM #tmp_per_con_movmig_3 p
ORDER BY
   p.sNombre,
   p.sPaterno,
   p.sMaterno,
   p.sIdPaisNacionalidad

-- 3: Final: Registros únicos ...
-- ...

-- ========================================================================================================================================== */
z