USE ATSG
GO

--> 1. Peruanos con PAS registrados en ATSG, pero no en SIM.
--> 2. Peruanos con PAS registrados en ATSG, tambienen SIM, pero nombres distitnos.
-- =============================================================================================================================================
-- ETD → Estimated time of Departure | Tiempo estimado de partida
-- ETA → Estimated Time of Arrival | Tiempo Estimado de Llegada

-- CitizenshipCountry: Nacionalidad
-- p.ApiOutbound -> 1: Salida; 0: Entrada

-- 1. Únicos documentos `PAS` por pasajero:

-- DROP TABLE #tmp_uniq_doc_by_pass

SELECT f.* INTO #tmp_uniq_doc_by_pass
FROM (

   SELECT 
      d.*,
      [#] = ROW_NUMBER() OVER (PARTITION BY d.PassengerId ORDER BY d.ExpirationDate DESC)
   FROM Document d
   WHERE 
      d.DocumentType = 'P' -- PAS
      AND d.IsCurrent = 1 -- Actual
      AND d.IssuanceCountry = 'PE' -- Pais emite
) f
WHERE f.[#] = 1

-- Index:
CREATE NONCLUSTERED INDEX ix_tmp_uniq_doc_by_pass 
   ON #tmp_uniq_doc_by_pass(PassengerId)

-- 2. Final:
-- DROP TABLE tmp_pass_pe_origin_pe
-- DROP TABLE tmp_pass_pe_origin_pe_2
EXEC sp_help tmp_pass_pe_origin_pe
SELECT

   f.FlightDate,
   f.FlightNumber,
   f.ETD,
   f.ETA,
   f.OriginCountry,
   f.Origin,
   f.DestinationCountry,
   f.Destination,
   [PassengerId] = p.Id,
   d.DocumentType,
   [Document] = d.Number,
   p.FirstName,
   p.MiddleName,
   p.LastName,
   p.Gender,
   p.DOB,
   p.CitizenshipCountry,
   p.Age,
   [TypeControl] = (
                     CASE
                        WHEN (f.OriginCountry != 'PE' AND f.DestinationCountry = 'PE') THEN 'E'
                        WHEN (f.OriginCountry = 'PE' AND f.DestinationCountry != 'PE') THEN 'S'
                     END      
   )
   INTO tmp_pass_pe_origin_pe_2
FROM #tmp_uniq_doc_by_pass d 
JOIN Passenger p ON p.Id = d.PassengerId
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
-- JOIN PnrPassenger pp ON p.Id = pp.PaxId
-- JOIN PNR pnr ON pp.PnrId = pnr.Id
WHERE
   p.ApiOutbound = 1 -- Salida
   AND p.CitizenshipCountry = 'PE' -- Peruano
   AND p.PassengerType = 'PAX'
   -- AND f.FlightDate BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999' -- Estimado de partida
   AND f.ETA BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999' -- Estimado de partida
   AND f.OriginCountry = 'PE' -- Origen igual `PE`
   AND f.DestinationCountry != 'PE' -- Excluye vuelos locales



-- Test
-- 117124913
SELECT * 
FROM tmp_pass_pe_origin_pe_2 a
WHERE a.Document = '117124913'

SELECT * 
FROM Document d
WHERE d.Number = '117124913'

EXEC sp_help Passenger
SELECT TOP 10 * FROM Passenger
SELECT TOP 10 * FROM PassengerJourney
SELECT TOP 10 * FROM PassengerFlight
SELECT TOP 10 * FROM Flight
SELECT TOP 10 * FROM PnrPassenger
SELECT TOP 10 * FROM PNR
SELECT TOP 10 * FROM FlightLeg
SELECT TOP 10 * FROM Document

-- =============================================================================================================================================