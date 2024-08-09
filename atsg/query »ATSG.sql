USE ATSG
GO

-- 1. ETD → Estimated time of Departure | Tiempo estimado de partida
-- 2. ETA → Estimated Time of Arrival | Tiempo Estimado de Llegada

-- Vuelo
EXEC sp_help Flight
SELECT TOP 10 * FROM Flight

-- Pasajero
EXEC sp_help Passenger
SELECT TOP 10 * FROM Passenger

-- Documento
SELECT TOP 10 * FROM Document -- FK_Document_Passenger
SELECT TOP 10 * FROM DocumentType

/* 
   → ATSG.dbo.PNR: Datos como nombre del viajero, línea aérea, número de vuelo, ruta, fecha, horarios, 
                   clase de servicio, teléfono de contacto ...
   → PNR ↔ Passenger Name Record */
EXEC sp_help PnrPassenger
SELECT TOP 10 * FROM PNR
SELECT TOP 10 * FROM PnrPassenger -- FK_PnrPassenger_PNR
SELECT TOP 10 * FROM PnrFlight -- FK_PnrFlight_Flight
SELECT TOP 10 * FROM PnrAgency -- FK_PnrAgency_PNR

SELECT * FROM Passenger p WHERE p.Id = 32133827

-- Interpol
EXEC sp_help ListRuleHit
SELECT TOP 10 * FROM [Case] -- FK_Cases_Passenger
SELECT TOP 10 * FROM CaseListRuleHit -- FK_Cases_Passenger
SELECT TOP 10 * FROM ListRuleHit -- FK_ListRuleHit_Passenger
SELECT TOP 10 * FROM InterpolHit -- FK_InterpolHit_Passenger
SELECT TOP 10 * FROM RuleHit -- FK_RuleHit_Passenger

-- Asiento
SELECT TOP 10 * FROM Seat -- FK_Seat_Passenger

-- Viaje de pasajeros
SELECT TOP 10 * FROM PassengerJourney

-- Vuelo de pasajeros
SELECT TOP 10 * FROM PassengerFlight -- FK_TravelerFlights_Flights

-- Tiempo de permanencia
SELECT TOP 10 * FROM DwellTime -- FK_DwellTime_PNR

-- Datos adicionales de Pasajero
SELECT TOP 10 * FROM [Address]
SELECT TOP 10 * FROM Email -- FK_Email_PNR
SELECT TOP 10 * FROM Names -- FK_Names_PNR
SELECT TOP 10 * FROM Phone -- FK_TravelerPhone

-- Aerolinea
SELECT TOP 10 * FROM CarrierCode c
SELECT * FROM CarrierCode c
-- WHERE
   -- c.Active = 1
   -- AND c.Name = 'BLUE AIR'
   -- c.Name = '%L%'
ORDER BY c.Name

EXEC sp_help CarrierCode

-- Historial de Viajes
EXEC sp_help TravelHistory
SELECT TOP 10 * FROM TravelHistory th WHERE th.Id = '13302426'

-- Pais
EXEC sp_help Country
SELECT TOP 10 * FROM Country c WHERE c.Name = 'Peru'

-- Acompañantes
SELECT TOP 10 p.* FROM RecordLocator rl
JOIN Passenger p ON rl.PaxId = p.Id
WHERE rl.[Value] = 'RSF7TB'

-- Agencia
SELECT TOP 10 * FROM PnrAgency a
SELECT TOP 10 * FROM TravelAgency ta 
WHERE ta.SoundexValue = '00000337'

-- Test ...
-- 1
SELECT
   TOP 10
   f.ETA, f.ETD,
   p.*
FROM Flight f
JOIN PassengerFlight pf ON f.Id = pf.FlightId
JOIN Passenger p ON pf.PassengerId = p.Id
WHERE
   f.ETA >= '2024-01-01 00:00:00.0000000'
   AND p.ApiOutbound IS NOT NULL
ORDER BY
   -- f.ETA DESC
   -- f.Id DESC
   p.Id DESC

-- 1
SELECT
   p.ApiOutbound,
   -- f.*,
   p.*
FROM Flight f
JOIN PassengerFlight pf ON f.Id = pf.FlightId
JOIN Passenger p ON pf.PassengerId = p.Id
JOIN Document d ON p.Id = d.PassengerId
WHERE
   -- f.Id = 1
   -- 1
   p.FirstName = 'FREDERIC'
   AND p.LastName LIKE '%GUSTAVE%'
   AND p.DOB = '1964-03-22'
   -- 1186660

   -- 2
   -- p.ApiOutbound IS NULL
   /* p.FirstName = 'MARCELA'
   AND p.LastName LIKE 'QUINTO'
   AND p.DOB = '1982-01-21' */
   -- d.Number = '18FA26768'
   
   /* p.FirstName = 'SANTOS'
   AND p.LastName = 'VILLEGAS MONTOYA' */
   -- AND p.DOB = '1993-08-13'
ORDER BY
   f.ETA DESC

-- PNR
SELECT TOP 10 pnr.* FROM PNR pnr
LEFT JOIN PnrPassenger pp ON pnr.Id = pp.PnrId
LEFT JOIN Passenger p ON pp.PaxId = p.Id
LEFT JOIN Document d ON p.Id = d.PassengerId
WHERE
   d.Number = '18FA26768'

-- 3. Buscar Duplicados en Passage ...
SELECT TOP 10 p2.* FROM (

   SELECT 
      p.*,
      [nCount_pax] = COUNT(1) OVER (PARTITION BY p.FirstName, p.MiddleName, p.LastName, p.DOB)
   FROM Passenger p
   WHERE p.FirstName IS NOT NULL AND p.LastName IS NOT NULL

) p2
WHERE
   p2.nCount_pax > 1

/*
   → 1. Registro de llegadas al `LIM-PE` en el ATSG ...
-- ============================================================================================================ */
-- DROP TABLE #tmp_flight_arrive

-- 1: ...
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES t WHERE t.TABLE_NAME = 'tmp_atsg_flight_arrive')
   DROP TABLE tmp_atsg_flight_arrive

-- 2. Create `tmp` into SIM ↔ 172.27.0.124 ...
-- EXEC sp_help Country
CREATE TABLE  tmp_atsg_flight_arrive (
   PassId BIGINT,
   ETA DATETIME2,
   ETD DATETIME2,
   FlightDate DATE,
   FlightNumber NVARCHAR(16),

   -- New field's
   DocumentType NVARCHAR(4),
   [NumberDocument] NVARCHAR(200),
   [CountryDocument] NCHAR(6),

   FirstName NVARCHAR(100),
   MiddleName NVARCHAR(100),
   LastName NVARCHAR(100),
   Gender NVARCHAR(4),
   DOB DATE,
   CitizenshipCountry NVARCHAR(6),
   Origin NVARCHAR(8),
   OriginCountry NVARCHAR(6),
   Destination	NVARCHAR(8),
   DestinationCountry NVARCHAR(6),
   ApiOutbound BIT
)

-- 3: ...
DECLARE @dateArrived VARCHAR(10) = '2023-12-31'
SELECT
   TOP 100
   [IdPass] = p.Id,
   f.ETA,
   f.ETD,
   f.FlightDate,
   -- [FlightNumber] = CONCAT('''', f.FlightNumber),
   [FlightNumber] = f.FlightNumber,

   -- New field's
   d.DocumentType,
   [NumberDocument] = d.Number,
   [CountryDocument] = c.ISO_3,

   p.FirstName,
   p.MiddleName,

   p.LastName,
   p.Gender,
   p.DOB,
   [CitizenshipCountry] = cp.ISO_3,

   f.Origin,
   f.OriginCountry,
   f.Destination,
   f.DestinationCountry,
   p.ApiOutbound -- 1 ↔ Salida | 0 ↔ Entraga

FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
JOIN Document d ON p.Id = d.PassengerId
                AND d.IsCurrent = 1 -- Actual
-- JOIN CarrierCode cc ON f.Carrier = cc.Code
LEFT JOIN Country cp ON p.CitizenshipCountry = cp.ISO_2
LEFT JOIN Country c ON d.IssuanceCountry = c.ISO_2
WHERE 
   -- p.Id = 58879084
   f.Destination = 'LIM' -- Destino `AIJCH`
   AND f.OriginCountry != 'PE' -- Origen distinto `PE`: Excluye vuelos locales
   AND EXISTS ( -- Usó asiento
                  SELECT 1 FROM Seat s 
                  WHERE 
                     s.FlightId = f.Id
                     AND s.PaxId = p.Id
               )
   /* AND EXISTS ( -- Registró llegada ...
                  SELECT 1
                  FROM EmbarkDebarkHistory edh
                  WHERE
                     edh.PassengerId = p.Id
                     AND edh.Embarkation = f.Origin
                     AND edh.Debarkation = f.Destination
                     AND edh.Debarkation = 'LIM'
               ) */

   AND f.ETA BETWEEN @dateArrived + ' 00:00:00.0000000' AND @dateArrived + ' 23:59:59.9999999'

-- Test ...
EXEC sp_help Document
EXEC sp_help Country
EXEC sp_help Country

-- Pasajero con más de 1 vuelo ...
-- 16189202; 16864848
SELECT TOP 5 p.Id FROM Passenger p
WHERE (
   SELECT
      COUNT(1)
   FROM PassengerFlight pf
   WHERE pf.PassengerId = p.Id
) = 5
ORDER BY NEWID()

-- 19374933; 20099649; 20446957; 20494929
DECLARE @IdPass BIGINT = 20494929

-- Pasajero
SELECT [PassId] = p.Id, p.CreateDateTime, p.EmbarkCountry, p.DebarkCountry FROM Passenger p WHERE p.Id =  @IdPass

-- Historial vuelos
SELECT TOP 10 * FROM EmbarkDebarkHistory h
WHERE h.PassengerId = @IdPass 

-- Vuelos
SELECT
   [PassId] = p.Id,
   f.FlightDate,
   f.ETD,
   f.ETA,
   f.OriginCountry,
   f.DestinationCountry,
   [usoAsiento] = (
      IIF(
         EXISTS (
            SELECT 1 FROM Seat s 
            WHERE 
               s.FlightId = f.Id
               AND s.PaxId = p.Id
         ),
         1,
         0
      )
   )
   -- pf.*
FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
WHERE p.Id = @IdPass 
AND EXISTS ( -- Usó asiento
                  SELECT 1 FROM Seat s 
                  WHERE 
                     s.FlightId = f.Id
                     AND s.PaxId = p.Id
               )
ORDER BY f.ETA


-- 53,268,037
-- 53,268,037
SELECT 
   -- COUNT(DISTINCT d.PassengerId) 
   d.*
FROM Document d 
WHERE 
   d.PassengerId = '47940083'
   -- d.IsCurrent = 1

SELECT h.* FROM EmbarkDebarkHistory h
WHERE h.PassengerId IN (

   SELECT 
      p.Id 
   FROM Passenger p
   WHERE 
      p.FirstName = 'SANTOS'
      AND p.LastName = 'VILLEGAS MONTOYA'

)

SELECT
   [PassId] = p.Id,
   f.*
   -- pf.*S
FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
WHERE 
   p.FirstName = 'SANTOS'
   AND p.LastName = 'VILLEGAS MONTOYA'

-- 57223660
-- 57401540
SELECT pnr.* FROM PNR pnr
JOIN PnrPassenger pp ON pnr.Id = pp.PnrId
WHERE pp.PaxId = 57223660

-- ============================================================================================================