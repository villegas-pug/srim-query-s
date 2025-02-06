USE SAM
GO

-- 20240807166631 | 20240807166601 | 20240803164736 | 20240803164734 | 2024080316730

SELECT TOP 10 * FROM SAM.dbo.[SamMpvTramiteWeb] s
WHERE 
	/* s.sNombre = 'ROOY CRISTOPHER'
	AND s.sApellidoPaterno = 'GUEVARA'
	AND s.sApellidoMaterno = 'VILLEGAS' */
   s.nCodTramiteWeb = '20240803164734'


SELECT COUNT(1)
FROM SIM.dbo.SimMovMigra mm
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0