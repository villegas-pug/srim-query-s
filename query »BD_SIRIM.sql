USE BD_SIRIM
GO

-- Create table `RimMovMigra` ...
DROP TABLE IF EXISTS RimMovMigra
SELECT 
   
   -- Control migratorio
	smm.sIdMovMigratorio,
	smm.dFechaControl,
	smm.sTipo,
	[sIdPaisNacionalidad_ISO3] = sp.sCodigoIso,
	smm.uIdPersona,
	smm.sIdDocumento,
	smm.sNumeroDoc,
	smm.sIdDependencia,
   si.sNumeroNave,
   [sEmpresaTransporte] = setr.sNombreRazon,

   -- Persona
	sper.sNombre,
	[sApellidos] = CONCAT(sper.sPaterno, ' ', sper.sMaterno),
	sper.sSexo,
	sper.dFechaNacimiento
   INTO RimMovMigra
FROM SIM.dbo.SimMovMigra smm
JOIN SIM.dbo.SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SIM.dbo.SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
LEFT JOIN SIM.dbo.SimItinerario si ON smm.sIdItinerario = si.sIdItinerario
LEFT JOIN SIM.dbo.SimEmpTransporte setr ON smm.nIdTransportista = setr.nIdTransportista
WHERE
   smm.bAnulado = 0
	AND smm.bTemporal = 0
   AND smm.sTipo = 'E'
   AND (smm.nIdTransportista != 183 OR smm.nIdTransportista IS NULL) -- VOLARIS: No registran vuelos en 'ATSG' ...
	-- AND smm.sIdPaisMov != 'PER'
   AND smm.dFechaControl BETWEEN '2023-08-08 00:00:00.000' AND '2023-08-09 23:59:59.999'

-- DROP TABLE IF EXISTS tmp_atsg_flight_arrive
EXEC sp_help tmp_atsg_flight_arrive
SELECT TOP 10 * FROM tmp_atsg_flight_arrive

-- Index: `tmp_atsg_flight_arrive`
CREATE NONCLUSTERED INDEX IX_tmp_atsg_flight_arrive_group1 
   ON tmp_atsg_flight_arrive(FirstName, LastName, Gender, DOB, CitizenshipCountry)

-- Index: `tmp_atsg_flight_arrive`
/* CREATE NONCLUSTERED INDEX IX_RimMovMigra_group1 
   ON RimMovMigra(sNombre, sApellidos, sSexo, dFechaNacimiento, sIdPaisNacionalidad) */

-- 2. Remove whitespace's ...
UPDATE tmp_atsg_flight_arrive
   SET LastName = REPLACE(LastName, ' ', '')

UPDATE RimMovMigra
   SET sApellidos = REPLACE(sApellidos, ' ', '')


SELECT TOP 10 * FROM tmp_atsg_flight_arrive
SELECT TOP 10 * FROM RimMovMigra mm

-- 3. Vuelos de `ATSG` no registrados en Control Migratorio ...
-- 3.1

-- Test `SOUNDEX` ...
SELECT DIFFERENCE('CHAMORROALVAREZVDA.DEPANDURO', 'CHAMORROALVAREZ')
SELECT DIFFERENCE('ZAGO', 'ZAGOMARTINEZ')
SELECT DIFFERENCE('ZAGOMARTINEZ', 'ZAGO')
SELECT DIFFERENCE('GENESSI', 'GENESSI YOSELIN')
SELECT DIFFERENCE('MAXIMOMR', 'MAXIMO')
SELECT DIFFERENCE('YAYA', 'YAYAALCALA')

-- 1: Vuelos de `ATSG` no registrados en Control Migratorio ...
SELECT TOP 100 atsg.* FROM tmp_atsg_flight_arrive atsg
WHERE
   EXISTS (
      SELECT 1 FROM RimMovMigra mm 
      WHERE
         DIFFERENCE(mm.sNombre, atsg.FirstName) >= 3
         AND DIFFERENCE(mm.sApellidos, atsg.LastName) >= 2
         -- AND mm.dFechaNacimiento = atsg.DOB
         -- AND mm.sSexo = atsg.Gender
         -- AND mm.sIdPaisNacionalidad_ISO3 = atsg.CitizenshipCountry -- ISO3
         -- AND mm.sNumeroDoc = atsg.NumberDocument
         -- AND mm.sNumeroNave = REPLACE(atsg.FlightNumber, '''', '')
   )

SELECT TRY_CONVERT(INT, REPLACE('''A0005', '''', ''))
SELECT ISNULL(CAST(TRY_CONVERT(INT, REPLACE('''A0005', '''', '')) AS VARCHAR), REPLACE('''A0005', '''', ''))

SELECT * FROM RimMovMigra mm 
WHERE
   mm.sNombre LIKE 'JOSE%'
   AND mm.sApellidos LIKE 'BARBAPAJUELO'


-- 2: Vuelos de Control Migratorio no registrados en `ATSG` ...
SELECT mm.* FROM RimMovMigra mm
WHERE
   NOT EXISTS (
      SELECT 1 FROM tmp_atsg_flight_arrive atsg
      WHERE
         DIFFERENCE(mm.sNombre, atsg.FirstName) = 4
         AND DIFFERENCE(mm.sApellidos, atsg.LastName) >= 2
         AND mm.dFechaNacimiento = atsg.DOB
         AND mm.sSexo = atsg.Gender
         -- AND mm.sIdPaisNacionalidad = atsg.CitizenshipCountry
   )

-- Test ...
-- 1
SELECT COUNT(1) FROM RimMovMigra
SELECT COUNT(1) FROM tmp_atsg_flight_arrive
SELECT TOP 10 mm.* FROM RimMovMigra mm
SELECT TOP 10 atsg.* FROM tmp_atsg_flight_arrive atsg

-- 2
SELECT mm.* FROM RimMovMigra mm
WHERE
   mm.sNombre = 'MAXIMO'

SELECT atsg.* FROM tmp_atsg_flight_arrive atsg
WHERE
   atsg.FirstName = 'MAXIMOMR'