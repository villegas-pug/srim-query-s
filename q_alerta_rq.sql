USE SIM
GO

-- 1
SELECT
   [nAño] = DATEPART(YYYY, o.dFecha),
   [nMes] = DATEPART(MM, o.dFecha),
   [nDia] = DATEPART(DD, o.dFecha),
   [nTotal] = COUNT(1)
FROM SimOficioRQ o
WHERE
   o.dFecha >= '2024-01-01 00:00:00.000'
GROUP BY
   DATEPART(YYYY, o.dFecha),
   DATEPART(MM, o.dFecha),
   DATEPART(DD, o.dFecha)
ORDER BY
   [nMes], [nDia]

-- 2
SELECT
   TOP 10 
   o.*
FROM SimOficioRQ o
WHERE
   o.dFecha >= '2024-01-01 00:00:00.000'

SELECT TOP 10 * 
FROM SimMovMigra mm
WHERE
   EXISTS (
            SELECT 1
            FROM SimOficioRQ o
            WHERE
               o.dFecha >= '2024-01-01 00:00:00.000'
               AND mm.sIdMovMigratorio = o.sIdMovMigratorio
   )