USE SIM
GO


SELECT  COUNT(1) FROM SimSalidaAutorizada

SELECT TOP 10 * FROM SimSalidaAutorizada sa
WHERE
   YEAR(sa.dFechaEmision) <= 2024
ORDER BY sa.dFechaEmision DESC