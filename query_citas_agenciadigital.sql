USE SIM
GO

SELECT 
   TOP 100
   src.*
FROM SimRegistroCita src

SELECT COUNT(1)
FROM SIM.dbo.SimMovMigra mm
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0