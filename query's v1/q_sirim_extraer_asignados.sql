USE SIRIM
GO

SELECT * FROM RimTablaDinamica rt
SELECT * FROM RimAsigGrupoCamposAnalisis

--==========================================================================================================
-- » Listar los asignados
--==========================================================================================================

-- Dep's ...
DECLARE @nombreBase VARCHAR(55) = 'Multiples_DNI_2',
		@minRegAsig INT,
		@maxRegAsig INT,
		@sql NVARCHAR(MAX)

-- STEP-1: Extrae el mínimo y máximo registro asignado ...
SELECT 
	@minRegAsig = MIN(ra.nRegAnalisisIni),
	@maxRegAsig = MAX(ra.nRegAnalisisFin)
FROM RimTablaDinamica rt
JOIN RimGrupoCamposAnalisis rg ON rt.nIdTabla = rg.nIdTabla
JOIN RimAsigGrupoCamposAnalisis ra ON rg.nIdGrupo = ra.nIdGrupo
WHERE
	rt.sNombre = @nombreBase

SET @sql = CONCAT('SELECT * FROM ', @nombreBase)
SET @sql = @sql + CONCAT(' WHERE nId BETWEEN ', @minRegAsig, ' AND ', @maxRegAsig)

-- STEP-FINAL:
EXEC(@sql)
--==========================================================================================================


--==========================================================================================================
-- » Eliminar los pendientes
--==========================================================================================================

-- Dep's ...
BEGIN TRAN
-- COMMIT TRAN
ROLLBACK TRAN

DECLARE @base VARCHAR(55) = 'Multiples_DNI_2',
		@maxRegAsigToDel INT,
		@sqlToDel NVARCHAR(MAX)

-- STEP-1: Extrae el máximo registro asignado ...
SELECT 
	@maxRegAsigToDel = MAX(ra.nRegAnalisisFin)
FROM RimTablaDinamica rt
JOIN RimGrupoCamposAnalisis rg ON rt.nIdTabla = rg.nIdTabla
JOIN RimAsigGrupoCamposAnalisis ra ON rg.nIdGrupo = ra.nIdGrupo
WHERE
	rt.sNombre = @base

SET @sqlToDel = CONCAT('DELETE FROM ', @base)
SET @sqlToDel = @sqlToDel + CONCAT(' WHERE nId > ', @maxRegAsigToDel)

-- STEP-FINAL:
EXEC(@sqlToDel)
SELECT @maxRegAsigToDel

-- Test ...
EXEC('SELECT * FROM Multiples_DNI_2 WHERE nId <= 3235')
EXEC('SELECT * FROM ' + @base + ' WHERE nId <= ' + @maxRegAsigToDel)
--==========================================================================================================
