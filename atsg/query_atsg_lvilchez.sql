USE ATSG
GO

/*» 1. ...*/

-- IdPass: 36396142 | lvilchez
-- IdPass: 57401540 | e1
-- IdPass: 57953514 | e2
-- SELECT * FROM Passenger p WHERE p.FirstName = 'Javier' AND p.LastName = 'Aching Acosta'

-- Dep's
DECLARE @IdPass BIGINT = 57401540

-- Pasajero
SELECT [PassId] = p.Id, p.CreateDateTime, p.EmbarkCountry, p.DebarkCountry 
FROM Passenger p WHERE p.Id =  @IdPass

-- Historial vuelos
SELECT TOP 10 * FROM EmbarkDebarkHistory h
WHERE h.PassengerId = @IdPass 

-- Vuelos
SELECT
   [PassId] = p.Id,
   [FlyId] = f.Id,
   f.FlightDate,
   f.FlightNumber,
   [CarrierId] = cc.Code,
   [Carrier] = cc.Name,
   f.ETD,
   f.ETA,
   f.OriginCountry,
   f.DestinationCountry
   -- pf.*
FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
JOIN CarrierCode cc ON f.Carrier = cc.Code
WHERE p.Id = @IdPass 
/* AND EXISTS ( -- Usó asiento
                  SELECT 1 FROM Seat s 
                  WHERE 
                     s.FlightId = f.Id
                     AND s.PaxId = p.Id
               ) */
ORDER BY f.ETA

-- Contar pasajeros por vuelo ...
SELECT 
   COUNT(1)
FROM PassengerFlight pf
WHERE
   EXISTS ( -- Usó asiento
            SELECT 1 FROM Seat s 
            WHERE 
               s.FlightId = pf.FlightId
               AND s.PaxId = pf.PassengerId
         )
   AND 
   -- pf.FlightId = 558104 -- lvilchez | 187
   pf.FlightId = 3086179 -- e1
   -- pf.FlightId = 2869685 -- e2


-- Pasajeros por vuelo ...
SELECT p.*, d.DocumentType, d.Number FROM PassengerFlight pf 
JOIN Passenger p ON pf.PassengerId = p.Id
LEFT JOIN Document d ON p.Id = d.PassengerId
                AND d.IsCurrent = 1 -- Actual
WHERE 
   -- pf.FlightId = 558104 -- lvilchez
   pf.FlightId = 3086179 -- e1
   -- pf.FlightId = 2869685 -- e2
   AND EXISTS ( -- Usó asiento
               SELECT 1 FROM Seat s 
               WHERE 
                  s.FlightId = pf.FlightId
                  AND s.PaxId = pf.PassengerId
            )














-- Vuelos 2023
SELECT TOP 100 * FROM Flight f
WHERE
   YEAR(f.ETA) = 2023
   AND f.Destination = 'LIM'
ORDER BY f.ETA DESC

-- 2023-08-08 01:34:00.0000000
SELECT p.* FROM Passenger p 
WHERE
   p.Id = 57401540
   AND p.LastName = 'ACUNA SILVA'
   AND p.FirstName = 'LILIANA'