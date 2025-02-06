USE SIM
GO

-- 1. USA Por pais de nacionalidad del Control Migratorio
-- 1.1
DROP TABLE IF EXISTS #tmp_usa_tur
SELECT
   -- TOP 100
   mm2.uIdPersona,
   mm2.dFechaControl,
   mm2.sTipo,
   [nAñosPermanencia] = DATEDIFF(YYYY, mm2.dFechaControl, GETDATE())
   
   INTO #tmp_usa_tur
FROM (

   SELECT

      mm.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sIdPaisNacionalidad = 'USA'

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.sTipo = 'E'
   AND mm2.nIdCalidad IN (41, 227)  -- 41; 227 | TURISTA


-- 2
SELECT 

   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,

   -- Aux
   [Años Permanencia] = f.[nAñosPermanencia]

FROM #tmp_usa_tur f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
/* WHERE
   f.[nAñosPermanencia] BETWEEN 5 AND 10 */


-- 2. ECU Por pais de nacionalidad del Control Migratorio
-- 1.1. Dentro del territorio nacional
DROP TABLE IF EXISTS #tmp_ecu_dentro_terr_nac
SELECT
   -- TOP 100
   mm2.uIdPersona,
   mm2.dFechaControl,
   [sTipoMovimiento] = mm2.sTipo,
   mm2.sIdDocumento,
   mm2.sNumDocumento,
   mm2.nIdCalidad,
   [nAñosPermanencia] = DATEDIFF(YYYY, mm2.dFechaControl, GETDATE())
   
   INTO #tmp_ecu_dentro_terr_nac
FROM (

   SELECT

      mm.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sIdPaisNacionalidad = 'ECU'

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.sTipo = 'E'
   -- AND mm2.nIdCalidad IN (41, 227)  -- 41; 227 | TURISTA


-- 2.2
SELECT 

   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   [Fecha Ultimo Ingreso] = f.dFechaControl,
   [Tipo Documento Viaje] = f.sIdDocumento,
   [Documento Viaje] = f.sNumeroDoc,
   -- [Tipo Movimiento] = f.sTipoMovimiento,
   [Calidad Persona] = cmp.sDescripcion,
   [Calidad Ultimo Ingreso] = cmm.sDescripcion,
   [sDireccion] = CONCAT(u.sNombre, '; ', e.sDomicilio),

   -- Aux
   [Años Permanencia] = f.[nAñosPermanencia]

FROM #tmp_ecu_dentro_terr_nac f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
LEFT JOIN SimExtranjero e ON pe.uIdPersona = e.uIdPersona
LEFT JOIN SimUbigeo u ON e.sIdUbigeoDomicilio = u.sIdUbigeo
JOIN SimCalidadMigratoria cmm ON f.nIdCalidad = cmm.nIdCalidad
JOIN SimCalidadMigratoria cmp ON pe.nIdCalidad = cmp.nIdCalidad


-- 3. ECU Por pais de persona
-- 1.1. Dentro del territorio nacional
DROP TABLE IF EXISTS #tmp_ecu_dentro_terr_nac
SELECT
   -- TOP 100
   mm2.*,
   [nAñosPermanencia] = DATEDIFF(YYYY, mm2.dFechaControl, GETDATE())

   INTO #tmp_ecu_dentro_terr_nac
FROM (

   SELECT

      mm.uIdPersona,
      mm.dFechaControl,
      [sTipoMovimiento] = mm.sTipo,
      mm.sIdDocumento,
      mm.sNumeroDoc,
      [nIdCalidadMM] = mm.nIdCalidad,

      -- Persona
      pe.sNombre,
      pe.sPaterno,
      pe.sMaterno,
      pe.sSexo,
      pe.dFechaNacimiento,
      pe.sIdPaisNacionalidad,
      [nIdCalidadPer] = pe.nIdcalidad,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND pe.sIdPaisNacionalidad = 'ECU'

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.sTipoMovimiento = 'E'
   -- AND mm2.nIdCalidad IN (41, 227)  -- 41; 227 | TURISTA


-- 2.2
SELECT 

   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   [Fecha Ultimo Ingreso] = f.dFechaControl,
   [Tipo Documento Viaje] = f.sIdDocumento,
   [Documento Viaje] = f.sNumeroDoc,
   -- [Tipo Movimiento] = f.sTipoMovimiento,
   [Calidad Persona] = cmp.sDescripcion,
   [Calidad Ultimo Ingreso] = cmm.sDescripcion,
   [sDireccion] = CONCAT(u.sNombre, '; ', e.sDomicilio),

   -- Aux
   [Años Permanencia] = f.[nAñosPermanencia]

FROM #tmp_ecu_dentro_terr_nac f
LEFT JOIN SimExtranjero e ON pe.uIdPersona = e.uIdPersona
LEFT JOIN SimUbigeo u ON e.sIdUbigeoDomicilio = u.sIdUbigeo
JOIN SimCalidadMigratoria cmm ON f.nIdCalidad = cmm.nIdCalidad
JOIN SimCalidadMigratoria cmp ON pe.nIdCalidad = cmp.nIdCalidad


-- Test
SELECT COUNT(1) FROM #tmp_usa_tur
SELECT DATEDIFF(DD, '2024-01-01', GETDATE())
SELECT TOP 10 * FROM SimPersona
SELECT TOP 10 * FROM SimPais
SELECT TOP 10 * FROM SimDependencia


SELECT * 
FROM BD_SIRIM.dbo.RimRNJefaturaZonal

EXEC sp_help RimRNJefaturaZonal

-- Scala
-- 1
SELECT

   mm2.uIdPersona,
   mm2.dFechaControl,
   mm2.sTipo,
   [nAñosPermanencia] = DATEDIFF(YYYY, mm2.dFechaControl, GETDATE())
   
FROM (

   SELECT

      mm.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sIdPaisNacionalidad = 'USA'

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.sTipo = 'E'
   AND mm2.nIdCalidad IN (41, 227)  -- 41; 227 | TURISTA



   -- 2. ECU
-- 1.1. Dentro del territorio nacional
DROP TABLE IF EXISTS #tmp_ecu_dentro_terr_nac
SELECT
   -- TOP 100
   mm2.uIdPersona,
   mm2.dFechaControl,
   [sTipoMovimiento] = mm2.sTipo,
   mm2.sIdDocumento,
   mm2.sNumeroDoc,
   mm2.nIdCalidad,
   [nAñosPermanencia] = DATEDIFF(YYYY, mm2.dFechaControl, GETDATE())
   
   INTO #tmp_ecu_dentro_terr_nac
FROM (

   SELECT

      mm.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.sIdPaisNacionalidad = 'ECU'

) mm2
WHERE
   mm2.[#] = 1
   AND mm2.sTipo = 'E'
   -- AND mm2.nIdCalidad IN (41, 227)  -- 41; 227 | TURISTA


-- 1.2
SELECT 

   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   [Fecha Ultimo Ingreso] = f.dFechaControl,
   [Tipo Documento Viaje] = mm.
   [Documento Viaje]
   [Calidad Persona] = cmp.sDescripcion,
   [Calidad Ultimo Ingreso] = cmm.sDescripcion,
   [sDireccion] = CONCAT(u.sNombre, '; ', e.sDomicilio),

   -- Aux
   [Años Permanencia] = f.[nAñosPermanencia]

FROM #tmp_ecu_dentro_terr_nac f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
LEFT JOIN SimExtranjero e ON pe.uIdPersona = e.uIdPersona
LEFT JOIN SimUbigeo u ON e.sIdUbigeoDomicilio = u.sIdUbigeo
JOIN SimCalidadMigratoria cmm ON f.nIdCalidad = cmm.nIdCalidad
JOIN SimCalidadMigratoria cmp ON pe.nIdCalidad = cmp.nIdCalidad