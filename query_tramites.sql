USE SIM
GO

/*
-- P  -> PENDIENTE
-- R  -> ANULADO
-- D  -> DENEGADO
-- A  -> APROBADO
-- E  -> DESISTIDO
-- B  -> ABANDONO
-- N  -> NO PRESENTADA
*/

-- 1. Crea tabla ...
DROP TABLE IF EXISTS #SimRptTramitesInm
CREATE TABLE #SimRptTramitesInm
(
	uIdPersona UNIQUEIDENTIFIER NOT NULL,
	Dependencia VARCHAR(255) NOT NULL,
	Anio INT NOT NULL,
	Mes INT NOT NULL,
	NumeroTramite VARCHAR(255) NOT NULL,
	PaisNacionalidad VARCHAR(255) NOT NULL,
	UltimaEtapa VARCHAR(255) NOT NULL,
	FechaExpendiente DATETIME NOT NULL,
	FechaEtapaAprobacionMasivaFin DATETIME NOT NULL,
	FechaPre DATETIME NOT NULL,
	OperadorPre VARCHAR(255) NOT NULL,
	EstadoPre VARCHAR(55) NOT NULL,
	EstadoTramite VARCHAR(55) NOT NULL,
)

-- 2. Insertar en tabla temporal ...
INSERT INTO #SimRptTramitesInm
	EXECUTE Usp_Sim_Rpt_TramitesInm 126, 2023, 'A'

-- 3. Insertar en tabla temporal ...
DROP TABLE IF EXISTS SimRptTramitesInm
SELECT 
	srti.uIdPersona,
	srti.Dependencia,
	srti.Anio,
	srti.Mes,
	srti.NumeroTramite,
	srti.PaisNacionalidad,
	srti.UltimaEtapa,
	srti.FechaExpendiente,
	srti.FechaEtapaAprobacionMasivaFin,
	srti.FechaPre,
	srti.OperadorPre,
	[EstadoPre] = (
						CASE
							WHEN srti.EstadoPre = 'PENDIENTE' THEN 'P'
							WHEN srti.EstadoPre = 'ANULADO' THEN 'R'
							WHEN srti.EstadoPre = 'DENEGADO' THEN 'D'
							WHEN srti.EstadoPre = 'APROBADO' THEN 'A'
							WHEN srti.EstadoPre = 'DESISTIDO' THEN 'D'
							WHEN srti.EstadoPre = 'ABANDONO' THEN 'B'
							WHEN srti.EstadoPre = 'NO PRESENTADA' THEN 'N'
						END
					),
	[EstadoTramite] = (
							CASE
								WHEN srti.EstadoTramite = 'PENDIENTE' THEN 'P'
								WHEN srti.EstadoTramite = 'ANULADO' THEN 'R'
								WHEN srti.EstadoTramite = 'DENEGADO' THEN 'D'
								WHEN srti.EstadoTramite = 'APROBADO' THEN 'A'
								WHEN srti.EstadoTramite = 'DESISTIDO' THEN 'D'
								WHEN srti.EstadoTramite = 'ABANDONO' THEN 'B'
								WHEN srti.EstadoTramite = 'NO PRESENTADA' THEN 'N'
							END
						)
	INTO SimRptTramitesInm
FROM #SimRptTramitesInm srti

-- Test ...
SELECT TOP 100 * FROM SimRptTramitesInm;

-- 1
SELECT 
	sdnv.sNombre,
	sdnv.sPaterno,
	sdnv.sMaterno,
	sdnv.sObservaciones,
	sdi.sObservaciones
FROM SimPersonaNoAutorizada sdnv
JOIN SimDocInvalidacion sdi ON sdnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
WHERE
	sdnv.sObservaciones LIKE '%wildre%'
	OR
	sdi.sObservaciones LIKE '%wildre%'

-- 2
SELECT
	sdnv.sNombre,
	sdnv.sPaterno,
	sdnv.sMaterno,
	sdnv.sObservaciones,
	sdi.sObservaciones
FROM SimPersonaNoAutorizada sdnv
JOIN SimDocInvalidacion sdi ON sdnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
WHERE
	sdnv.sNombre = 'WILDRE JESUS'
	AND sdnv.sPaterno = 'ALVAREZ'
	AND sdnv.sMaterno = 'PERALTA'

/* 1
El comandante PNP Luis Felipe Guevara Elias, Jefe de Ficha de Canje Internacional de la OCN Interpol Lima, hace de conocimiento que el 
ciudadano de nacionalidad venezolana Wildre Jesus Alvarez Peralta, con CIP N° V19915570, posee registro policial en su país por el delito de Violación, 
en consecuencia se registra la presente alerta informativa, en caso se advierta que dicho ciudadano pretenda salir del país, se realice el control secundario, de 
conformidad con lo dispesto en el Art.N°115 del Reglamento del D.LEG. N°1350. REG.POR SGMM
*/

/* 2
El Cmte. PNP Luis Felipe Guevara Elias, Jefe de Ficha Canje Internacional de la OCN INTERPOL LIMA, hace de conocimiento de Mil doscientos sesenta y siete (1267)  
ciudadanos de nacionalidad venezolana que posee antecedentes policiales en su país. Impedir el ingreso al país por inc.b del art. 48.1 del 
Dleg. 1350. REG.POR SGMM.
*/