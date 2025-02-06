USE SIM
GO

/*
   → Modelo:
   | Orden | Fecha de Nacimiento | Tipo de Movimiento | Nacionalidad | Fecha de Movimiento 
   | Tipo de Documento | Pais de Origen/Destino | Puesto de Control | Aerolína Vuelo | Calidad Migratoria 

   → Paises:
      CNO | COREA DEL NORTE
      CSU | COREA DEL SUR 
      
-- ======================================================================================================================================= */


-- 1
DROP TABLE IF EXISTS #tmp_mm_corea_2024
SELECT 

   mm.uIdPersona,
   [Orden] = ROW_NUMBER() OVER (ORDER BY mm.dFechaControl ASC),
   [Nombre] = pe.sNombre,
   [Paterno] = pe.sPaterno,
   [Materno] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = p.sNacionalidad,
   [Tipo Movimiento] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
   [Fecha Movimiento] = mm.dFechaControl,
   [Tipo Documento] = do.sDescripcion,
   [Pais de Origen/Destino] = pm.sNombre,
   [Dependencia] = d.sNombre,
   [Puesto de Control] = td.sDescripcion,
   [Aerolinea] = et.sNombreRazon,
   [Calidad Migratoria] = cm.sDescripcion
   
   INTO #tmp_mm_corea_2024
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
JOIN SimPais pm ON mm.sIdPaisMov = pm.sIdPais
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SimTipoDependencia td ON d.nIdTipoDependencia = td.nIdTipoDependencia
JOIN SimEmpTransporte et ON mm.nIdTransportista = et.nIdTransportista
JOIN SimDocumento do ON mm.sIdDocumento = do.sIdDocumento
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-06-30 23:59:59.999'
   AND mm.sIdPaisNacionalidad IN ('CNO', 'CSU') -- CNO | COREA DEL NORTE
                                                -- CSU | COREA DEL SUR


SELECT * FROM #tmp_mm_corea_2024

-- 2
-- EXEC sp_help SimMovMigra
SELECT f.*
FROM (

   SELECT 

      mm.uIdPersona,
      [Orden] = ROW_NUMBER() OVER (ORDER BY mm.dFechaControl ASC),
      [Nombre] = pe.sNombre,
      [Paterno] = pe.sPaterno,
      [Materno] = pe.sMaterno,
      [Sexo] = pe.sSexo,
      [Fecha Nacimiento] = pe.dFechaNacimiento,
      [Nacionalidad] = p.sNacionalidad,
      [Tipo Movimiento] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
      [Fecha Movimiento] = mm.dFechaControl,
      [Tipo Documento] = do.sDescripcion,
      [Pais de Origen/Destino] = pm.sNombre,
      [Dependencia] = d.sNombre,
      [Puesto de Control] = td.sDescripcion,
      [Aerolinea] = et.sNombreRazon,
      [Calidad Migratoria] = cm.sDescripcion,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC),
      [nTotalMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona)

   FROM SimMovMigra mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
   JOIN SimDocumento do ON mm.sIdDocumento = do.sIdDocumento
   JOIN SimPais p ON mm.sIdPaisNacionalidad = p.sIdPais
   JOIN SimPais pm ON mm.sIdPaisMov = pm.sIdPais
   JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
   JOIN SimTipoDependencia td ON d.nIdTipoDependencia = td.nIdTipoDependencia
   LEFT JOIN SimEmpTransporte et ON mm.nIdTransportista = et.nIdTransportista
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      /* AND mm.uIdPersona IN (
                              SELECT DISTINCT c.uIdPersona
                              FROM #tmp_mm_corea_2024 c
      ) */
      AND mm.sIdPaisNacionalidad IN ('CNO', 'CSU') -- CNO | COREA DEL NORTE
                                                   -- CSU | COREA DEL SUR

) f
WHERE
   f.[#] = 1
   -- AND f.nTotalMM = 1

-- =======================================================================================================================================



-- 1
DROP TABLE IF EXISTS #tmp_dni
SELECT 
   TOP 0 pe.sNumDocIdentidad
   INTO #tmp_dni 
FROM SimPersona pe

-- 1.1
-- INSERT INTO #tmp_dni VALUES()
-- SELECT COUNT(1) FROM #tmp_dni -- 131

-- 2

-- 2.1 SimDocPersona
DROP TABLE IF EXISTS #tmp_dni_uid
SELECT 
   * INTO #tmp_dni_uid
FROM #tmp_dni dni
LEFT JOIN (

   SELECT
      DISTINCT per.uIdPersona, dp.sNumero
   FROM #tmp_dni d
   JOIN SimDocPersona dp ON d.sNumDocIdentidad = dp.sNumero
                        AND dp.sIdDocumento = 'DNI'
   JOIN SimPersona per ON dp.uIdPersona = per.uIdPersona
   WHERE
      dp.bActivo = 1
      AND per.sIdPaisNacionalidad = 'PER'

) dni_uid ON dni.sNumDocIdentidad = dni_uid.sNumero

-- Test
SELECT COUNT(1) FROM #tmp_dni_uid
SELECT * FROM #tmp_dni_uid

-- 2.2: Final
SELECT f.*
FROM (

   SELECT 
      d.*,
      pas.sPasNumero,
      pas.dFechaEmision,
      pas.dFechaExpiracion,
      [sVigente] = (
                        CASE
                           WHEN pas.sPasNumero IS NULL THEN NULL
                           WHEN DATEDIFF(DD, pas.dFechaExpiracion, GETDATE()) > 0 THEN 'NO'
                           ELSE 'SI'
                        END
      ),
      [Nombre] = per.sNombre,
      [Paterno] = per.sPaterno,
      [Materno] = per.sMaterno,
      [Sexo] = per.sSexo,
      [Fecha Nacimiento] = per.dFechaNacimiento,
      [Pais Nacionalidad] = per.sIdPaisNacionalidad,
      [#] = ROW_NUMBER() OVER (PARTITION BY d.sNumDocIdentidad ORDER BY pas.dFechaEmision DESC)
   FROM #tmp_dni_uid d
   LEFT JOIN SimTramite t ON d.uIdPersona = t.uIdPersona
   LEFT JOIN SimPersona per on t.uIdPersona = per.uIdPersona
   LEFT JOIN SimPasaporte pas ON t.sNumeroTramite = pas.sNumeroTramite
   WHERE
      t.bCancelado = 0 AND t.bCulminado = 1
      OR (t.bCancelado IS NULL AND t.bCulminado IS NULL)

) f
WHERE
   f.[#] = 1

 SELECT * FROM SimProceso