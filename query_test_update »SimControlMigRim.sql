USE SIRIM
GO

SELECT TOP 10 scm.dFechaControl, SUM(scm.nTotalCtrlMig) FROM SimControlMigRim scm
GROUP BY scm.dFechaControl
ORDER BY scm.dFechaControl DESC


-- DELETE FROM SimControlMigRim WHERE dFechaControl = '2022-07-11'

SELECT * FROM SimControlMigRim scm 
WHERE scm.dFechaControl BETWEEN '2022-06-28' AND '2022-06-29'

BEGIN TRAN
-- COMMIT TRAN
ROLLBACK TRAN
DELETE FROM SimControlMigRim
WHERE dFechaControl >= '2022-07-12'

SELECT TOP 100000 * FROM SimPasaporteRim

