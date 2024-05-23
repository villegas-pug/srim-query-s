USE SIM
GO

/*░ Extranjero permanecen en territorio nacional:

→ 3,706,433 
→ 2016-2023: 1,172,901
--=======================================================================================================================*/
SELECT COUNT(1) FROM (

	SELECT 
		smm.sTipo,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	WHERE 
		smm.bAnulado = 0
		AND smm.sIdPaisNacionalidad != 'PER'
		AND smm.sTipo IN ('E', 'S')
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'

) mm
WHERE 
	mm.sTipo = 'E'
	AND mm.nFila_mm = 1


--=======================================================================================================================