

SELECT TOP 10 * FROM Passenger

-- F77127320
SELECT TOP 10 * FROM PNR
SELECT TOP 10 * FROM Passenger
SELECT COUNT(1) FROM Email
SELECT COUNT(1) FROM Phone

-- 2.1. `tmp` registro de vuelos de `LIM` como origen o destino ...
SELECT

   [Nombres] = CONCAT(p.FirstName, ' ',p.MiddleName),
   [Apellidos] = p.LastName,
   [Sexo] = p.Gender,
   [Fecha Nacimiento] = p.DOB,
   [Ciudadanía País] = p.CitizenshipCountry,
   [Fecha Vuelo] = f.FlightDate,
   [Número Vuelo] = f.FlightNumber,
   [Tiempo Partida] = f.ETD,
   [Tiempo Llegada] = f.ETA,
   [País Origen] = f.OriginCountry,
   [Ciudad Origen] = f.Origin,
   [País Destino] = f.DestinationCountry,
   [Destino] = f.Destination,

   [Routa Ciudad] = j.RouteIata,
   [Routa Pais] = j.RouteCountryCodes,

   [Movimiento] = IIF(p.ApiOutbound = 1, 'S', 'E'), -- 1 ↔ Salida | 0 ↔ Entraga
   /* [Movimiento] = (
                     CASE
                        WHEN (f.OriginCountry != 'PE' AND f.DestinationCountry = 'PE') THEN 'E'
                        WHEN (f.OriginCountry = 'PE' AND f.DestinationCountry != 'PE') THEN 'S'
                     END      
   ), */
   [Email] = e.EmailAddress,
   [Ciudad Telefono] = ph.City,
   [Telefono] = ph.Number

FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
JOIN PassengerJourney j ON p.Id = j.PassengerId
JOIN Document d ON p.Id = d.PassengerId
JOIN PnrPassenger pnp ON p.Id = pnp.PaxId
JOIN Pnr pn ON pnp.PnrId = pn.Id
JOIN Email e ON pn.Id = e.PnrId
JOIN Phone ph ON pn.Id = ph.PnrId
WHERE
   -- f.Deleted = 0
   -- AND f.ETA BETWEEN '2024-01-01 00:00:00.000' AND '2024-08-07 23:59:59.999'
   -- AND p.ApiOutbound IN (0, 1) -- Entradas y Salidas
   -- AND p.CitizenshipCountry != 'PE' -- Extranjero
   -- AND p.PassengerType = 'PAX'
   -- d.Number = 'F61251114'
   d.Number = 'F77127320'
   AND d.DocumentType = 'P'
   -- AND (f.Destination = 'LIM' OR f.Origin = 'LIM') -- AIJCH


-- 2
-- 2.1. `tmp` registro de vuelos de `LIM` como origen o destino ...
SELECT * 
FROM (

   SELECT

      [Nombres] = CONCAT(p.FirstName, ' ',p.MiddleName),
      [Apellidos] = p.LastName,
      [Sexo] = p.Gender,
      [Fecha Nacimiento] = p.DOB,
      [Ciudadanía País] = p.CitizenshipCountry,
      [Fecha Vuelo] = f.FlightDate,
      [Número Vuelo] = f.FlightNumber,
      [Tiempo Partida] = f.ETD,
      [Tiempo Llegada] = f.ETA,
      [País Origen] = f.OriginCountry,
      [Ciudad Origen] = f.Origin,
      [País Destino] = f.DestinationCountry,
      [Destino] = f.Destination,
      [Routa Ciudad] = j.RouteIata,
      [Routa Pais] = j.RouteCountryCodes,
      [Movimiento] = IIF(p.ApiOutbound = 1, 'S', 'E'), -- 1 ↔ Salida | 0 ↔ Entraga
      [Email] = e.EmailAddress,
      [Ciudad Telefono] = ph.City,
      [Telefono] = ph.Number,

      [#] = ROW_NUMBER() OVER (PARTITION BY f.FlightNumber ORDER BY f.FlightDate DESC)

   FROM Passenger p
   JOIN PassengerFlight pf ON p.Id = pf.PassengerId
   LEFT JOIN Flight f ON pf.FlightId = f.Id
   LEFT JOIN PassengerJourney j ON p.Id = j.PassengerId
   LEFT JOIN Document d ON p.Id = d.PassengerId
   LEFT JOIN PnrPassenger pnp ON p.Id = pnp.PaxId
   LEFT JOIN Pnr pn ON pnp.PnrId = pn.Id
   LEFT JOIN Email e ON pn.Id = e.PnrId
   LEFT JOIN Phone ph ON pn.Id = ph.PnrId
   WHERE
      d.Number = 'F77127320'
      AND d.DocumentType = 'P'

) f
WHERE f.[#] = 1


-- 3.1. `tmp` registro de vuelos de `LIM` como origen o destino ...
-- ETD → Estimated time of Departure | Tiempo estimado de partida
-- ETA → Estimated Time of Arrival | Tiempo Estimado de Llegada
SELECT

   CONCAT(p.FirstName, ' ',p.MiddleName),
   p.LastName,
   p.Gender,
   p.DOB,
   p.CitizenshipCountry,
   f.FlightDate,
   f.FlightNumber,
   f.ETD,
   f.ETA,
   f.OriginCountry,
   f.Origin,
   f.DestinationCountry,
   f.Destination,
   j.RouteIata,
   j.RouteCountryCodes
   -- IIF(p.ApiOutbound = 1, 'S', 'E') -- 1 ↔ Salida | 0 ↔ Entraga

FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
JOIN PassengerJourney j ON p.Id = j.PassengerId
WHERE
   f.Destination = 'LIM' -- AIJCH
   AND f.ETA BETWEEN '2024-11-01 00:00:00.000' AND '2025-01-31 23:59:59.998'
   -- AND p.CitizenshipCountry = 'VE' -- Extranjero
   AND p.CitizenshipCountry = 'IR' -- Extranjero
   AND EXISTS ( -- Usó asiento
               SELECT 1 FROM Seat s 
               WHERE 
                  s.FlightId = pf.FlightId
                  AND s.PaxId = pf.PassengerId
         )



-- Test
-- 3
SELECT TOP 10 * FROM PnrPassenger
SELECT TOP 10 * FROM PassengerJourney
SELECT TOP 10 * FROM Phone
SELECT TOP 10 * FROM Passenger
SELECT TOP 10 * FROM PassengerJourney
SELECT TOP 10 * FROM COuntry c
WHERE c.Name LIKE '%iran%'


