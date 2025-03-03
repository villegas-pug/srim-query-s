USE SIM
GO

-- 1. Crear tabla `tmp`, para insertar N° DNI ...

-- 1.1
DROP TABLE IF EXISTS BD_SIRIM.dbo.tmp_dni_minedu
SELECT 
   TOP 0 
   p.sNumDocIdentidad,
   [sNombre] = REPLICATE('|', 100),
   [sPaterno] = REPLICATE('|', 100),
   [sMaterno] = REPLICATE('|', 100),
   [dFechaNacimiento] = REPLICATE('|', 25),
   [sSexo] = REPLICATE('|', 1),
   [sUltMovMigra] = REPLICATE('|', 1),
   [dFechaUltMovMigra] = REPLICATE('|', 25),
   [dOrigenDestinoUltMovMigra] = REPLICATE('|', 55),
   [dMedioTransporteUltMovMigra] = REPLICATE('|', 1),
   [dFechaCorte] = REPLICATE('|', 25)

   INTO BD_SIRIM.dbo.tmp_dni_minedu
FROM SimPersona p

-- 1.1 Bulk
-- INSERT INTO BD_SIRIM.dbo.tmp_dni_minedu VALUES()
-- INSERT INTO BD_SIRIM.dbo.tmp_dni_minedu VALUES('78202390')

-- 1.3
UPDATE BD_SIRIM.dbo.tmp_dni_minedu
   SET sNumDocIdentidad = RIGHT(CONCAT('00000000', sNumDocIdentidad), 8)

-- 1.4 Insertar campo `uIdPersona` ...
ALTER TABLE BD_SIRIM.dbo.tmp_dni_minedu
   ADD uIdPersona UNIQUEIDENTIFIER NULL

-- 2. Actualiza `uIdPersona` por `DNI`
UPDATE BD_SIRIM.dbo.tmp_dni_minedu
   SET uIdPersona = (
                        SELECT TOP 1 dp.uIdPersona
                        FROM SimDocPersona dp
                        JOIN SimPersona p ON dp.uIdPersona = p.uIdPersona
                        WHERE
                           p.bActivo = 1
                           AND p.sIdPaisNacionalidad = 'PER'
                           AND dp.sIdDocumento = 'DNI'
                           AND dp.sNumero = m.sNumDocIdentidad

   )
FROM BD_SIRIM.dbo.tmp_dni_minedu m

-- 3. Actualiza datos personales
DROP TABLE IF EXISTS #tmp_mm_dni_minedu
SELECT f.* INTO #tmp_mm_dni_minedu
FROM (

   SELECT 
      mm.uIdPersona,
      mm.sTipo,
      mm.dFechaControl,
      [sPaisMov] = p.sNombre,
      mm.sIdViaTransporte,
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM SimMovMigra mm
   JOIN BD_SIRIM.dbo.tmp_dni_minedu m ON mm.uIdPersona = m.uIdPersona
   JOIN SimPais p ON mm.sIdPaisMov = p.sIdPais
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0

) f
WHERE f.[#] = 1

-- 3. Actualiza datos personales
UPDATE BD_SIRIM.dbo.tmp_dni_minedu
   SET 
      sNombre = p.sNombre,
      sPaterno = p.sPaterno,
      sMaterno = p.sMaterno,
      dFechaNacimiento = CAST(p.dFechaNacimiento AS DATE),
      sSexo = p.sSexo,

      sUltMovMigra = mm.sTipo,
      dFechaUltMovMigra = CAST(mm.dFechaControl AS DATE),
      dOrigenDestinoUltMovMigra = mm.sPaisMov,
      dMedioTransporteUltMovMigra = mm.sIdViaTransporte,
      dFechaCorte = CAST(GETDATE() AS DATE)
FROM BD_SIRIM.dbo.tmp_dni_minedu m
JOIN SimPersona p ON m.uIdPersona = p.uIdPersona
JOIN #tmp_mm_dni_minedu mm ON m.uIdPersona = mm.uIdPersona

-- 4. Inserta nuevo campo de `sDocumentos`:
-- 4.1
ALTER TABLE BD_SIRIM.dbo.tmp_dni_minedu
   ADD sDocumentos VARCHAR(MAX) NULL

-- 4.2
UPDATE BD_SIRIM.dbo.tmp_dni_minedu
   SET sDocumentos = (
                        SELECT dp.sIdDocumento, dp.sNumero
                        FROM SimDocPersona dp
                        WHERE
                           dp.uIdPersona = m.uIdPersona
                        FOR XML PATH('')

   )
FROM BD_SIRIM.dbo.tmp_dni_minedu m

-- 5. Final
SELECT 
   * 
FROM BD_SIRIM.dbo.tmp_dni_minedu m
