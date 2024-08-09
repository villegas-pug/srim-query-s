USE ATSG
GO

/*» 1. ...*/

-- IdPass: 36396142 | lvilchez
-- IdPass: 57401540 | e1
-- IdPass: 57953514 | e2
-- SELECT * FROM Passenger p WHERE p.FirstName = 'Javier' AND p.LastName = 'Aching Acosta'
/* ============================================================================== ::. ATSG ::. ==================================================================================== */
--> 1. Dep's
DECLARE @IdPass BIGINT = 57401540

--> 2. Pasajero
SELECT [PassId] = p.Id, p.CreateDateTime, p.EmbarkCountry, p.DebarkCountry 
FROM Passenger p WHERE p.Id =  @IdPass

--> 3. Historial vuelos
SELECT TOP 10 * FROM EmbarkDebarkHistory h
WHERE h.PassengerId = @IdPass 

-- 4. Vuelos
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

-- 5. Contar pasajeros por vuelo ...
EXEC sp_help PassengerFlight
SELECT 
   -- COUNT(1)
   pf.*
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


-- 6. Pasajeros por vuelo ...
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

-- 7. Vuelos 2023
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


-- =============================================================================================================================================


/* =========================================================================== ::. REPORTES ATSG ::. ================================================================================= */

--> 1. Caso: Vuelos destino `LIM` ...
-- =============================================================================================================================================
-- ETD → Estimated time of Departure | Tiempo estimado de partida
-- ETA → Estimated Time of Arrival | Tiempo Estimado de Llegada

SELECT
   [dFechaVuelo] = f2.[ETD(Date)],
   [nHoraVuelo] = f2.[ETD(Hour)],
   [nTotalVuelo] = COUNT(1),
   [nTotalPas] = SUM(f2.nTotalPas)
FROM (

   SELECT
      f.Id,
      [ETD(Date)] = CAST(f.ETD AS DATE),
      [ETD(Hour)] = DATEPART(HH, f.ETD),
      [nTotalPas] = (
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
                              AND pf.FlightId = f.Id 
      )
   FROM Flight f
   WHERE
      -- f.FlightDate >= '20230101'
      f.ETD >= '2023-01-01 00:00:00.000'
      AND f.Destination = 'LIM' -- Destino `Lima`
      AND f.Deleted = 0

) f2
GROUP BY
   f2.[ETD(Date)],
   f2.[ETD(Hour)]
ORDER BY
   f2.[ETD(Date)], f2.[ETD(Hour)] ASC


-- Test
SELECT 
   f.FlightNumber,
   COUNT(1)
FROM Flight f
GROUP BY f.FlightNumber 
ORDER BY 2 DESC

-- =============================================================================================================================================


--> 2. Caso: Identificar pasajeros de paso por `LIM` ...
-- =============================================================================================================================================
-- ETD → Estimated time of Departure | Tiempo estimado de partida
-- ETA → Estimated Time of Arrival | Tiempo Estimado de Llegada

-- CitizenshipCountry: Nacionalidad

SELECT
   -- TOP 100
   -- f.ETA, f.ETD,
   -- p.*
   pnr.Route,
   f.FlightDate,
   f.FlightNumber,
   f.ETD,
   f.ETA,
   f.OriginCountry,
   f.DestinationCountry,
   p.*
   -- COUNT(1)
FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
JOIN PnrPassenger pp ON p.Id = pp.PaxId
JOIN PNR pnr ON pp.PnrId = pnr.Id
WHERE
   p.ApiOutbound IS NOT NULL
   -- AND f.ETA >= '2024-01-01 00:00:00.0000000'
   AND f.ETA BETWEEN '2023-01-01 00:00:00.000' AND '2023-01-07 23:59:59.999'
   AND p.ApiOutbound = 0 -- Entradas
   AND p.CitizenshipCountry != 'PE' -- Extranjero
   /* AND EXISTS ( -- Usó asiento
      SELECT 1 FROM Seat s 
      WHERE 
         s.FlightId = pf.FlightId
         AND s.PaxId = pf.PassengerId
   ) */
   AND f.Destination = 'LIM' -- Destino `AIJCH`
   --AND f.OriginCountry != 'PE' -- Origen distinto `PE`: Excluye vuelos locales
   /* AND EXISTS ( -- Registró llegada ...
                  SELECT 1
                  FROM EmbarkDebarkHistory edh
                  WHERE
                     edh.PassengerId = p.Id
                     AND edh.Embarkation = f.Origin
                     AND edh.Debarkation = f.Destination
                     AND edh.Debarkation = 'LIM'
               ) */
   AND (pnr.Route LIKE '%LIM%'AND pnr.Route NOT LIKE '%LIM') -- Destino final no es `LIM`


-- 2

-- 2.1. `tmp` registro de vuelos de `LIM` como origen o destino ...
DROP TABLE #tmp_atsg_orgdest_lim
SELECT

   p.FirstName,
   p.LastName,
   p.MiddleName,
   p.Gender,
   p.DOB,
   p.CitizenshipCountry,
   p.ApiOutbound,
   f.FlightDate,
   f.FlightNumber,
   f.ETD,
   f.ETA,
   f.OriginCountry,
   f.Origin,
   f.DestinationCountry,
   f.Destination,
   
   [TipoMovimieno] = (
                        CASE
                           WHEN (f.OriginCountry != 'PE' AND f.DestinationCountry = 'PE') THEN 'E'
                           WHEN (f.OriginCountry = 'PE' AND f.DestinationCountry != 'PE') THEN 'S'
                        END      
   )

   INTO #tmp_atsg_orgdest_lim
FROM Passenger p
JOIN PassengerFlight pf ON p.Id = pf.PassengerId
JOIN Flight f ON pf.FlightId = f.Id
JOIN PassengerJourney j ON p.Id = j.PassengerId
WHERE
   f.Deleted = 0
   AND f.ETA BETWEEN '2024-01-01 00:00:00.000' AND '2024-08-07 23:59:59.999'
   -- AND p.ApiOutbound IN (0, 1) -- Entradas y Salidas
   AND p.CitizenshipCountry != 'PE' -- Extranjero
   AND p.PassengerType = 'PAX'
   AND (f.Destination = 'LIM' OR f.Origin = 'LIM') -- AIJCH

SELECT TOP 10 * FROM Passenger
SELECT TOP 10 * FROM Flight

-- Test: Into tabla físisca:
DROP TABLE IF EXISTS tmp_atsg_orgdest_lim
SELECT * INTO tmp_atsg_orgdest_lim FROM #tmp_atsg_orgdest_lim

-- 2.2. Crea `Id` por datos de pasajero ...
DROP TABLE #tmp_atsg_orgdest_lim_id
SELECT
   a.*,
   [DynamicId] = REPLACE(CONCAT(ISNULL(a.FirstName, ''), ISNULL(a.LastName, ''), ISNULL(a.MiddleName, ''), FORMAT(a.DOB, 'yyyy-MM-dd'), a.CitizenshipCountry), ' ', '')
   INTO #tmp_atsg_orgdest_lim_id
FROM #tmp_atsg_orgdest_lim a

CREATE NONCLUSTERED INDEX ux_tmp_atsg_orgdest_lim_id 
   ON #tmp_atsg_orgdest_lim_id(DynamicId)

-- 2.3. No registran `SALIDA` ...
SELECT 
   f.*

   INTO #tmp_atsg_orgdest_lim_id_ultvuelo_entrada
FROM (

   SELECT 
      *,

      -- Aux
      [OrdenVuelo] = ROW_NUMBER() OVER (PARTITION BY
                                             v.DynamicId
                                             ORDER BY v.ETA DESC
                                          )
   FROM #tmp_atsg_orgdest_lim_id v

) f
WHERE
   f.OrdenVuelo = 1 -- Ultimo vuelo
   AND f.TipoMovimieno = 'E' -- Entrada

-- bak
SELECT * INTO tmp_atsg_orgdest_lim_id_ultvuelo_entrada FROM #tmp_atsg_orgdest_lim_id_ultvuelo_entrada

-- 2.4. Buscar coincidencia con SIM.dbo.SimMovMigra ...

SELECT TOP 10 * FROM SIM.dbo.SimMovMigra smm


-- Test
SELECT TOP 10 * FROM #tmp_atsg_orgdest_lim_id_ultvuelo_entrada
SELECT TOP 10 * FROM tmp_atsg_orgdest_lim_id_ultvuelo_entrada

EXEC sp_help tmp_atsg_orgdest_lim_id_ultvuelo_entrada
EXEC sp_helptext Passenger

-- Test
SELECT TOP 10 * FROM Passenger
SELECT TOP 10 * FROM PassengerJourney
SELECT TOP 10 * FROM PassengerFlight
SELECT TOP 10 * FROM Flight
SELECT TOP 10 * FROM PnrPassenger
SELECT TOP 10 * FROM PNR
SELECT TOP 10 * FROM FlightLeg
SELECT TOP 10 * FROM Doc

-- =============================================================================================================================================


