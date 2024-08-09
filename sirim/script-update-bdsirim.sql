USE [BD_SIRIM]
GO

/* USE [BDSidtefim-Test]
GO */

-- 1. Rename: Field's from SidProcedimiento
-- EXEC sp_rename 'SidProcedimiento.sRutaPa', 'sRutaPag', 'COLUMN'

-- 2. Delete Field: sRefItem, sDisposicion
/* ALTER TABLE SidProcedimiento
   DROP COLUMN sDisposicion */

-- 3. Update: bActivo → SidUsuario
UPDATE SidUsuario
   SET bActivo = 1

-- 4. Update: sTipo
/*
   → MODULO: PAG
   → SUB MODULO: SUB PAG
   → ITEM: DYNAMIC COMPONENT */
BEGIN TRAN
-- COMMIT TRAN
UPDATE SidProcedimiento
   SET sTipo = CASE
                  -- WHEN sTipo = 'MODULO' THEN 'PAG'
                  -- WHEN sTipo = 'SUB_MODULO' THEN 'SUB PAG'
                  WHEN sTipo = 'SUB PAG' THEN 'SUB_PAG'
                  ELSE sTipo
               END

-- 5

-- » CREATE-CREDENTIALS 
-- -----------------------------------------------------------------------------------------------------------------------------

-- ► Create User ...
-- SELECT * FROM SidUsuario
-- DELETE FROM SidUsuario
-- DELETE FROM SidUsuario WHERE uIdUsuario = '14BC83D0-04EF-4F7C-A171-16DD1C2982BB'
-- DELETE FROM SidUsuarioProcedimiento WHERE nIdUsrProcedimiento = 6
INSERT INTO SidUsuario(uIdUsuario, bActivo, sArea, sCargo, sDni, sLogin, sNombres, xPassword, sRegimenLaboral, sDependencia, sGrupo) 
-- VALUES(NEWID(), 1, 'RIM', 'Analista de Registro', '48291881', 'srim', 'Rooy Cristopher, Guevara Villegas', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'TERCERO', 'LIMA', 'ANALISIS')
VALUES(NEWID(), 1, 'DIROP', 'Analista de Registro', '27041243', 'jzlima', 'John Doe', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'TERCERO', 'LIMA', 'ANALISIS')

/* ► 
	Create: Perfil ... 
	--► MOD: 69, 70, 73, 74
	--► SUBMOD: 84(BUSCAR INTERPOL), 98(EXTRACCIÓN DE DATOS), 99(DEPURAR EXTRACCIÓN), 100(ASIGNAR EXTRACCIÓN), 101(BUSCAR DNV), 102(ANALIZAR EXTRACCIÓN)
*/
SELECT * FROM SidUsuario
UPDATE SidUsuario
	SET sGrupo = 'ANALISIS'-- 'DEPURACION' --ANALISIS
WHERE sLogin = 'MRODRIGUEZC'

--► Admin:
-- SELECT * FROM SidUsuario
-- SELECT * FROM SidUsuarioProcedimiento
-- SELECT * FROM SidProcedimiento
INSERT 
	INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 7, 'e02d28b5-944a-4da6-a601-f61e9b4446b4')



/*► 
	→ Cordinador | Analista ... 
	--► MOD: 69, 70, 73, 74
	--► SUBMOD: 84(BUSCAR INTERPOL), 98(EXTRACCIÓN DE DATOS), 99(DEPURAR EXTRACCIÓN), 100(ASIGNAR EXTRACCIÓN), 101(BUSCAR DNV), 102(ANALIZAR EXTRACCIÓN)
	--► 5ED651A0-9040-4F3B-80A9-1E8B94FCF612 | 354FAEA3-5585-4BB4-93F3-D409926F94BA
	--► 4E385A8B-4C1E-4F76-8851-668A63FCA0CE
*/
-- SELECT * FROM SidUsuario
-- SELECT * FROM SidProcedimiento WHERE nIdProcedimiento IN (69, 70, 73, 74, 84, 98, 99, 100, 101, 102)
-- DELETE FROM SidUsuarioProcedimiento WHERE uIdUsuario = '38DDCE48-0760-4C82-8501-34CB0BF888C2' 
-- Dep's 
SELECT [value] INTO #tmp_idProc 
FROM 
	STRING_SPLIT('69, 70, 73, 74, 75, 84, 98, 99, 100, 101, 102, 103, 104, 107, 109, 110, 111', ',') -- Cordinador
	-- STRING_SPLIT('69, 70, 73, 74, 84, 101, 102, 108', ',') -- Analista

WHILE((SELECT COUNT(1) FROM #tmp_idProc) > 0)
BEGIN
	DECLARE @idProc INT = (SELECT TOP 1 [value] FROM #tmp_idProc ORDER BY [value])

	INSERT 
		INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
		VALUES (1, GETDATE(), @idProc, '38DDCE48-0760-4C82-8501-34CB0BF888C2')

	-- Clean-up ...
	DELETE FROM #tmp_idProc WHERE [value] = @idProc
END

-- Clean-up
DROP TABLE IF EXISTS #tmp_idProc
/*-----------------------------------------------------------------------------------------------------------------------------*/
	
-- » MOD'S:
EXEC sp_help SidProcedimiento

INSERT INTO SidProcedimiento
	(
		bActivo, sNombre, sDescripcion, sInformacion, sIcono, sRutaPag, sRutaSubpag, sTipo, nSecuencia
	)
	VALUES
	   /* (1, 'HOME', 'Home', '', 'Home', '/', 'MODULO', 'appbar'),
	   (1, 'PERFIL', 'Mis credenciales', 'Puede actulizar sus credenciales', 'Person', '/perfil', 'MODULO', 'appbar'),
	   (1, 'ACTIVIDADES', 'Registro de actividades', '', 'SupervisorAccount', '/actividades', 'MODULO', 'appbar'),
	   (1, 'LINEAMIENTOS', 'Lineamientos Generales', '', 'AddBox', '/lineamientos', 'MODULO', 'sidebar'),
	   (1, 'PROCESOS', 'Procesos', '', 'Settings', '/procesos', 'MODULO', 'sidebar'),
	   (1, 'UTILIDADES', 'Utilidades', '', 'LiveHelp', '/utilidades', 'MODULO', 'sidebar'),
	   (1, 'REPORTES', 'Reportes', '', 'BarChartRounded', '/reportes', 'MODULO', 'sidebar'),
	   (1, 'GESTIÓN TRÁMITES', 'Gestión de Trámites', '', 'AccountTree', '/gestion-tramites', 'MODULO', 'sidebar'),
	   (1, 'MANTENIMIENTO', 'Mantenimiento', '', 'EngineeringRounded', '/mantenimiento', 'MODULO', 'sidebar'), */
	   -- (1, 'Reglas de Consistencia', 'Reglas de consistencia de los procesos de migraciones.', '', '', '/reglas-consistencia', '', 'PAG', 1)
	   (1, 'Control Registros Inconsistentes', 'Control de registros inconsistentes.', '', '', '/control-registros', '', 'PAG', 1)

-- Test
SELECT * FROM SidProcedimiento

-- » SUB-MOD'S:
SELECT * FROM SidProcedimiento
UPDATE SidProcedimiento SET sRutaSubmod = '' WHERE nIdProcedimiento = 105

INSERT INTO SidProcedimiento
	(
		bActivo, sNombre, sInformacion, sDescripcion, sIcono, sRutaMod, sRutaSubmod, sTipo
	)
	VALUES
		/* (1, 'NUEVO INTERPOL', 'Nuevo interpol emitidos', 'Registro de fichas de interpol emitida.', 'Create', '/procesos', '/nuevo-interpol', 'SUB_MODULO'),
		(1, 'BUSCAR INTERPOL', 'Interpol Emitidos', 'Fichas de interpol registradas y emitida.', 'FindInPage', '/utilidades', '/buscar-interpol', 'SUB_MODULO'),
		(1, 'EXTRACCIÓN DE DATOS', 'Extracción de Datos', 'Extracción de datos de los módulos de datos de Migraciones.', 'StorageRounded', '/procesos', '/extraccion-datos', 'SUB_MODULO'),
		(1, 'DEPURAR EXTRACCIÓN', 'Depuración de datos', 'Nueva extracción de datos para analizar.', 'CleaningServicesRounded', '/procesos', '/nueva-depuracion', 'SUB_MODULO'),
		(1, 'ASIGNAR EXTRACCIÓN', 'Asignar Extracción', 'Asignar extracción de datos para analizar.', 'GroupsRounded', '/procesos', '/asignar-extraccion', 'SUB_MODULO'),
		(1, 'BUSCAR DNV', 'Documento no Válidos', 'Invalidación de documentos de cudadanos Extranjeros.', 'FindInPage', '/utilidades', '/buscar-dnv', 'SUB_MODULO'),
		(1, 'ANALIZAR EXTRACCIÓN', 'analizar Extracción', 'Analizar extracción de datos.', 'QueryStatsRounded', '/procesos', '/analizar-extraccion', 'SUB_MODULO'),
		(1, 'CONTROL DE CALIDAD', 'Control de calidad', 'Control de calidad, para el analisis de datos extraidos.', 'GradingRounded', '/procesos', '/control-calidad', 'SUB_MODULO'),
		(1, 'REPORTE DIARIO DE PRODUCCIÓN', 'Reporte diario de analisis de datos', 'Reporte diario de producción de analisis y depuración de datos.', 'TrendingUp', '/reportes', '/produccion-diario', 'SUB_MODULO'),
		(1, 'CREAR TIPO LÓGICO', 'Crear, actualizar y eliminar tipo de dato lógico.', 'Crear, actualizar y eliminar tipo de dato lógico.', 'DataObjectRounded', '/mantenimiento', '/tipo-logico', 'SUB_MODULO'),
		(1, 'EVENTO', 'Crear, actualizar y eliminar eventos.', 'Crear, actualizar y eliminar eventos.', 'EventNoteRounded', '/utilidades', '/evento', 'SUB_MODULO'),
		(1, 'REPORTE DE HORAS TRABAJADAS', 'Reporte de registros analizados por horas.', 'Reporte de registros analizados por horas.', 'QueryBuilderRounded', '/reportes', '/produccion-horas', 'SUB_MODULO'),
		(1, 'REPORTE CONTROL MIGRATORIO', 'Reporte de Control Migratorio.', 'Reporte de Control Migratorio.', 'StackedLineChartRounded', '/reportes', '/control-migratorio', 'SUB_MODULO'),
		(1, 'REPORTE PASAPORTES', 'Reporte de Pasaportes.', 'Reporte de Pasaportes.', 'StyleRounded', '/reportes', '/pasaportes', 'SUB_MODULO'),
		(1, 'REPORTE REGISTROS ANALIZADOS', 'Reporte de Registros Analizados.', 'Reporte de Registros Analizados.', 'KeyboardDoubleArrowDownRounded', '/reportes', '/analizados', 'SUB_MODULO'),
		(1, 'CONVENIOS', 'Convenios de la DRCM', 'Convenios de la Dirección de Registro y Control Migratoria.', 'DescriptionRounded', '/lineamientos', '/convenios', 'SUB_MODULO') */
		(1, 'Control Migratorio', 'Registros migratorios de ciudadanos nacionales y extranjeros.', '', '', '/reglas-consistencia', '/control-migratorio', 'SUB_PAG', 1),
	   (1, 'Trámites de Inmigración', 'Registros trámites de ciudadanos extranjeros.', '', '', '/reglas-consistencia', '/tramites-inmigracion', 'SUB_PAG', 2),
	   (1, 'Alertas', 'Registro de alertas de personas nacionales y extranjeras.', '', '', '/reglas-consistencia', '/alertas', 'SUB_PAG', 3)
		

-- ► Update: SUBMOD secuencia ...
-- SELECT * FROM SidProcedimiento WHERE nIdProcedimiento = 51
SELECT * FROM SidUsuario
SELECT * FROM SidProcedimiento
UPDATE SidProcedimiento
	SET sIcono = 'MdNearbyError'
WHERE nIdProcedimiento = 7

SELECT * FROM SidProcedimiento p
WHERE p.sTipo = 'SUB_MODULO'

DELETE FROM SidUsuarioProcedimiento
WHERE
	uIdUsuario = 'A12E06BB-4BC7-4E92-A4B5-79F0967B1A58'
	AND nIdProcedimiento = 98


UPDATE SidProcedimiento
SET sNombre = 'REPORTE DIARIO DE PRODUCCIÓN'
WHERE nIdProcedimiento = 104
		
/*» ITEM'S */
INSERT INTO SidProcedimiento
	(
		bActivo, sNombre, sInformacion, sDescripcion, sIcono, sRutaMod, sRutaSubmod, sRefItem, sTipo
	)
	VALUES
		(1, 'INCONSISTENCIAS', 'Procedimientos inconsistentes', 'Procedimiento no registrados en SIM-NAC', 'Person', '/reportes', '/nacionalizacion', 'Inconsistencias', 'ITEM'),
		(1, 'PENDIENTES', 'Procedimientos pendientes', 'Reporte de procedimientos pendientes 2016 al 2021', 'Person', '/reportes', '/nacionalizacion', 'Pendientes', 'ITEM'),
		(1, 'NACIONALIZADOS', 'Procedimientos pendientes', 'Reporte de procedimientos pendientes 2016 al 2021', 'Person', '/reportes', '/nacionalizacion', 'Nacionalizados', 'ITEM'),
		(1, 'ATENDIDOS', 'Procedimientos pendientes', 'Reporte de procedimientos pendientes 2016 al 2021', 'Person', '/reportes', '/nacionalizacion', 'Atendidos', 'ITEM')

-- » SUB-ITEM'S
INSERT INTO SidProcedimiento
	(
		bActivo, sNombre, sIcono, sRutaMod, sRutaSubmod, sRefItem, sTipo
	)
	VALUES
		(1, 'PIURA', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'ILO', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'BREÑA', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'LIMA', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'AREQUIPA', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'LIM', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'CHIMBOTE', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'TARAPOTO', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'TACNA', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'IQUITOS', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'PTO', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'TRUJILLO', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'PUCALLPA', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'TUMBES', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'CHICLAYO', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM'),
		(1, 'CUSCO', 'LocationCity', '/reportes', '/nacionalizacion', 'Pendientes', 'SUB_ITEM')


-- » Inserta todos los procedimientos a `root` ...
-- SELECT * FROM SidUsuario
-- SELECT * FROM SidUsuarioProcedimiento
DECLARE @uId UNIQUEIDENTIFIER = '3d2220e5-a2f9-4117-b6d0-67eb04984c24'
INSERT INTO SidUsuarioProcedimiento(bDenegado, nIdProcedimiento, dFechaRegistro, uIdUsuario)
	SELECT 1, p.nIdProcedimiento, GETDATE(), @uId  FROM SidProcedimiento p

/*» RESET ROLES */
--DELETE FROM SidUsuarioProcedimiento
--DELETE FROM SidProcedimiento
--DBCC CHECKIDENT ('[SidProcedimiento]', RESEED,0)
--TRUNCATE TABLE SidProcedimiento
/*
ALTER TABLE SidProcedimiento
	ALTER COLUMN sIcono VARCHAR(25) NULL */

/*» Test ...*/
SELECT * FROM SidUsuario
	--WHERE uIdUsuario = '6B234CBC-FBC8-4EBC-85AA-E4B3A3807828'
	WHERE sLogin = 'rguevarav'

SELECT * FROM SidUsuarioProcedimiento 
	WHERE uIdUsuario = 'A12E06BB-4BC7-4E92-A4B5-79F0967B1A58'

SELECT * FROM SidProcedimiento p
WHERE p.sTipo = 'SUB_MODULO'
-- 5 | Procedimiento 
-- 51 | Depuración de datos → CleaningServicesRounded
-- 53 | ASIGNAR EXTRACCIÓN → GroupsRounded

SELECT * FROM SidUsuario
UPDATE SidProcedimiento SET nSecuencia = 0

/*
DELETE FROM SidUsuarioProcedimiento 
WHERE 
	uIdUsuario = '74260A42-F392-4564-9B9F-A744A32D219A'
	AND nIdProcedimiento = 52
*/
--WHERE uIdUsuario = '5ED651A0-9040-4F3B-80A9-1E8B94FCF612' -- NPASTOR: 5ED651A0-9040-4F3B-80A9-1E8B94FCF612
--WHERE uIdUsuario = '354FAEA3-5585-4BB4-93F3-D409926F94BA' -- EGOLIVERA: 354FAEA3-5585-4BB4-93F3-D409926F94BA
-- SELECT * FROM SidUsuario
-- SELECT * FROM SidProcedimiento
-- 104 | REPORTE DE PRODUCCIÓN DIARIO
-- 110 | REPORTE PASAPORTES
-- 112 | CONVENIOS
INSERT
	INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 72, '23013539-706D-4EF7-9AE2-66839583E7C8')

/*» ROL: ADMIN */
/*--------------------------------------------------------------------------------------------*/
SELECT nIdProcedimiento INTO #tmp FROM SidProcedimiento
DECLARE @count_tmp INT = (SELECT COUNT(1) FROM #tmp),
		@idProc INT
WHILE (@count_tmp > 0)
BEGIN
	SET @idProc = (SELECT TOP 1 nIdProcedimiento FROM #tmp ORDER BY nIdProcedimiento ASC)
	INSERT 
		INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
		VALUES (1, GETDATE(), @idProc, '6B234CBC-FBC8-4EBC-85AA-E4B3A3807828')
	
	DELETE FROM #tmp WHERE nIdProcedimiento = @idProc
	SET @count_tmp = (SELECT COUNT(1) FROM #tmp)
END
--DELETE FROM SidUsuarioProcedimiento WHERE uIdUsuario = '4B0383AD-D59C-9F40-83FA-76E1FB5E5F93'
/*--------------------------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------------------------------------------------------------
» ROL		: USER-SFM
» MOD		: 1 | 2 | 3
» SUBMOD	: 8
---------------------------------------------------------------------------------------------------------------------------------*/
DECLARE @uId UNIQUEIDENTIFIER = '6B6E1B18-12BC-4D38-B5ED-F8C6CE058C79'
INSERT 
	INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES 
		(1, GETDATE(), 1, @uId),
		(1, GETDATE(), 2, @uId),
		(1, GETDATE(), 3, @uId),
		(1, GETDATE(), 8, @uId)
/*» 25 ...*/
SELECT * FROM SidUsuario WHERE sArea = 'SFM'
/*---------------------------------------------------------------------------------------------------------------------------------*/


/*---------------------------------------------------------------------------------------------------------------------------------*/
/*
» ROL		: ADMIN-SFM 
» MOD		: 1 | 2 | 3 | 5 | 7
» SUBMOD	: 8 | 9 | 16
*/
/*--------------------------------------------------------------------------------------------*/
INSERT 
	INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 16, '2DE78A3B-7C8C-4E30-917B-A676FE57911A')

	SELECT * FROM SidUsuario WHERE sNombres LIKE '%mirian%'
	SELECT * FROM SidUsuarioProcedimiento WHERE uIdUsuario = '2DE78A3B-7C8C-4E30-917B-A676FE57911A'
/*--------------------------------------------------------------------------------------------*/

/*
» ROL		: CORDINADOR-SGTM
» MOD		: 1 | 2 | 6 | 7
» SUBMOD	: 12 | 14 | 17
» ITEM		: 18 | 19 | 20 | 21
*/
/*--------------------------------------------------------------------------------------------*/
INSERT 
	INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 21, 'F5ADDF9A-31C9-471A-8885-0E82E2657790')

	SELECT * FROM SidUsuario WHERE sNombres LIKE '%palma%'
	SELECT * FROM SidProcedimiento WHERE sTipo = 'ITEM'
	SELECT * FROM SidUsuarioProcedimiento WHERE uIdUsuario = 'F5ADDF9A-31C9-471A-8885-0E82E2657790'
/*--------------------------------------------------------------------------------------------*/

/*
» ROL		: EVALUADOR
» MOD		: 1 | 6
» SUBMOD	: 12 | 13
*/
INSERT 
	INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 41, '4B0383AD-D59C-9F40-83FA-76E1FB5E5F93')

SELECT * FROM SidUsuarioProcedimiento WHERE uIdUsuario = '4BCCEE09-BFF8-6742-B5E4-0771A87BADCB'

/*» Test...*/
DELETE FROM SidUsuarioProcedimiento WHERE uIdUsuario = 'A1F2C292-61F8-9141-BAB5-43D77D44681F'
UPDATE SidUsuarioProcedimiento 
	SET nIdProcedimiento = 6 
	WHERE 
		uIdUsuario = 'A1F2C292-61F8-9141-BAB5-43D77D44681F'
		AND nIdProcedimiento = 5

SELECT * FROM SidProcedimiento sp
	WHERE sp.sTipo = 'MODULO'
SELECT * FROM SidProcedimiento sp
	WHERE 
		sp.sTipo = 'SUB_MODULO'
		AND sp.sRutaMod = (SELECT sRutaMod FROM SidProcedimiento WHERE sTipo = 'MODULO' AND sNombre = 'ACTIVIDADES')


SELECT * FROM SidProcedimiento
SELECT * FROM SidUsuarioProcedimiento

INSERT SidUsuarioProcedimiento



SELECT * FROM SidProcedimiento
SELECT * FROM SidUsuarioProcedimiento WHERE uIdUsuario = '2DE78A3B-7C8C-4E30-917B-A676FE57911A'
SELECT * FROM SidUsuario WHERE uIdUsuario = '2DE78A3B-7C8C-4E30-917B-A676FE57911A'
/*---------------------------------------------------------------------------------------------------------------------------------*/

/* ░ Actualizar sGrupo en SidUsuario
	» 
*/
/*---------------------------------------------------------------------------------*/
-- SELECT * FROM SidUsuario
-- SELECT * FROM SidProcedimiento
-- UPDATE SidProcedimiento SET nSecuencia = 5 WHERE nIdProcedimiento = 60

UPDATE SidUsuario
SET sGrupo = 'ANALISIS'
WHERE uIdUsuario = 'BF1ED352-D6A1-4255-ADD3-9F592F33477A'

-- DEPURACION
-- ANALISIS
/*---------------------------------------------------------------------------------*/

ALTER TABLE RimProduccionAnalisis
ALTER COLUMN dFechaFin DATETIME NOT NULL

UPDATE RimProduccionAnalisis
SET dFechaFin = CONVERT(DATETIME, dFechaFin)


SELECT * FROM RimProduccionAnalisis rp
WHERE
	rp.dFechaFin >= '2022-08-31 00:00:00.000'

SELECT * FROM SidUsuario
SELECT * FROM RimGrupoCamposAnalisis rg WHERE rg.nIdGrupo = 5
SELECT TOP 1000 * FROM Rim_Test_2022 WHERE nId >= 51


DROP TABLE IF EXISTS #tmp_cols_a
DECLARE @table VARCHAR(MAX) = 'RUMANIA_ABRIL_AGOSTO'

DECLARE @csv VARCHAR(MAX) = (
	SELECT 
		[field] = STRING_AGG(s.COLUMN_NAME, '|')
	FROM INFORMATION_SCHEMA.COLUMNS s
	WHERE 
		s.TABLE_NAME = @table
		AND s.COLUMN_NAME LIKE '%_a'
)

SELECT [field] = value INTO #tmp_cols_a FROM STRING_SPLIT(@csv, '|')

WHILE EXISTS(SELECT 1 FROM #tmp_cols_a)
BEGIN
	DECLARE @field VARCHAR(MAX) = (SELECT TOP 1 field FROM #tmp_cols_a ORDER BY field)

	DECLARE @sql NVARCHAR(MAX) = N'ALTER TABLE ' + @table + ' ALTER COLUMN ' + @field + ' VARCHAR(MAX) NULL'
	EXEC sp_executesql @sql

	DELETE FROM #tmp_cols_a WHERE field = @field
END



/* ► Test ... */
SELECT 
	t.*,
	g.sMetaFieldsCsv
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
WHERE
	t.nIdTabla = 3

SELECT * FROM RimCtrlCalCamposAnalisis

nCampo_Analisis_01_a, 
sCampo_Analisis_02_a, 
bCampo_Analisis_03_a, 
bCampo_Analisis_04_a, 
dCampo_Analisis_05_a, 
bCampo_Analisis_06_a, 
bCampo_Analisis_08_a

SELECT * FROM INPE_AGO_22
SELECT * FROM Pas_DNI_vinculado
SELECT * FROM RUMANIA_ABRIL_AGOSTO

-- USER: ; PWD
-- PWD: 123 | $2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO
-- USER: EGOLIVERA; PWD: $2a$10$zRXvNF6TBeus./Thq9h3AOQsNmTMCD5YtEWqu0E49VBRhNWLfAbHG
SELECT * FROM SidUsuario
SELECT * FROM RimTablaDinamica
SELECT * FROM RimEvento
SELECT * FROM RimProduccionAnalisis

ALTER TABLE Rim_Extraccion_2022
	DROP COLUMN bAnalisado


SELECT TOP 1000 * FROM Multiples_DNIs_2_19ene_a

SELECT * FROM SidUsuario

SELECT * FROM RimTablaDinamica td
WHERE td.sNombre = 'EMISION_PASAPORTE_NACIONAL2'

BEGIN TRAN
-- COMMIT TRAN

UPDATE RimTablaDinamica
	SET uIdUsrCreador = '630AE24D-32B1-4FE7-808D-9E8FCF0B87AD'
WHERE sNombre = 'rpt_nacSinres_cancelada'

ROLLBACK TRAN

-- EGOLIVERA   | 354FAEA3-5585-4BB4-93F3-D409926F94BA
-- RCARHUAPOMA | 38DDCE48-0760-4C82-8501-34CB0BF888C2
-- NPASTOR | 5ED651A0-9040-4F3B-80A9-1E8B94FCF612
-- MRODRIGUEZC | D411BA23-E4A6-401F-9FC9-C7FCD0F58071

-- SELECT * FROM SidUsuario

-- Reas
UPDATE RimTablaDinamica
	SET uIdUsrCreador = 'D411BA23-E4A6-401F-9FC9-C7FCD0F58071'
FROM RimTablaDinamica td
JOIN SidUsuario u ON td.uIdUsrCreador = u.uIdUsuario
WHERE
	u.sLogin = 'NPASTOR'

UPDATE SidUsuario
	-- SET sGrupo = 'DEPURACION'
	SET sGrupo = 'ANALISIS'
WHERE 
	-- uIdUsuario IN ('354FAEA3-5585-4BB4-93F3-D409926F94BA')
	uIdUsuario IN ('D562090E-AD36-4C9D-A773-7D5B368112D9')



SELECT * 
FROM SimDependencia ;

SELECT 
	-- TOP 10 * 
	p.sEstado,
	COUNT(1)
FROM RimPasaporte p
GROUP BY
	p.sEstado
ORDER BY
	2 DESC


EXEC sp_help SidUsuario
EXEC sp_help SidProcedimiento

SELECT TOP 10 * FROM SidUsuarioProcedimiento
SELECT TOP 10 * FROM SidProcedimiento

/*
3  | Reglas de Consistencia
4	| Control Migratorio
5	| Trámites de Inmigración
6	| Alertas

	BsDatabaseX
	PiAirplaneLandingFill
	AiFillAlert
	FaPersonMilitaryToPerson
*/

/* UPDATE SidProcedimiento
	SET sIcono = 'FaPersonMilitaryToPerson'
WHERE nIdProcedimiento = 5 */

-- Bulk: Regla
-- EXEC sp_help RimRNProceso
-- INSERT INTO RimRNProceso(sNombre, sDescripcion, nTotalRegCorrectos, nTotalRegIncorrectos, nTotalRegistros, nTotalReglas, bActivo, dFechaCreacion) VALUES()
INSERT INTO RimRNProceso(sNombre, sDescripcion, nTotalRegCorrectos, nTotalRegIncorrectos, nTotalRegistros, nTotalReglas, bActivo, dFechaCreacion) VALUES('Control Migratorio','Registros de control migratorio.',217734027,55552809,273286836,146, 1, GETDATE())
INSERT INTO RimRNProceso(sNombre, sDescripcion, nTotalRegCorrectos, nTotalRegIncorrectos, nTotalRegistros, nTotalReglas, bActivo, dFechaCreacion) VALUES('Trámites de Inmigración','Registros de trámites de inmigración.',4840810,1115474,5956284,50, 1, GETDATE())
INSERT INTO RimRNProceso(sNombre, sDescripcion, nTotalRegCorrectos, nTotalRegIncorrectos, nTotalRegistros, nTotalReglas, bActivo, dFechaCreacion) VALUES('Alertas','Registro de personas no autorizadas.',64933,29000,93933,0, 1, GETDATE())

SELECT * FROM RimRNProceso

-- Bulk 2
-- SELECT * FROM RimRNDimension
INSERT INTO RimRNDimension(sNombre, bActivo) VALUES('Unicidad', 1)
INSERT INTO RimRNDimension(sNombre, bActivo) VALUES('Completitud', 1)
INSERT INTO RimRNDimension(sNombre, bActivo) VALUES('Exactitud', 1)
INSERT INTO RimRNDimension(sNombre, bActivo) VALUES('Consistencia', 1)
INSERT INTO RimRNDimension(sNombre, bActivo) VALUES('Obligatoriedad', 1)
INSERT INTO RimRNDimension(sNombre, bActivo) VALUES('Frescura', 1)

-- Bulk 3
-- SELECT * FROM RimRNStatus
INSERT INTO RimRNStatus(sNombre, bActivo) VALUES('APROBADO', 1)
INSERT INTO RimRNStatus(sNombre, bActivo) VALUES('OBSERVADO', 1)

-- Bulk 4
-- SELECT * FROM RimRNTipoScript
INSERT INTO RimRNTipoScript(sDescripcion, bActivo) VALUES('DETECCION', 1)
INSERT INTO RimRNTipoScript(sDescripcion, bActivo) VALUES('VALIDACION', 1)
INSERT INTO RimRNTipoScript(sDescripcion, bActivo) VALUES('CORECCION', 1)

-- Bulk 5
-- SELECT * FROM RimReglaNegocio
EXEC sp_help RimReglaNegocio
INSERT INTO RimReglaNegocio VALUES ('RC0001', 1, GETDATE(), 1, 1, 2, '[dFechaControl], [sTipo]', '[SimMovMigra]')
INSERT INTO RimReglaNegocio VALUES ('RC0002', 1, GETDATE(), 2, 1, 1, '[dFechaControl], [sTipo]', '[SimMovMigra]')


-- Bulk 6
/*
	→ RN			: RC0001, RC0002
	→ Operador	: 3d2220e5-a2f9-4117-b6d0-67eb04984c24
	→ SELECT * FROM RimRNControlCambios
*/
-- SELECT * FROM RimRNTipoScript
SELECT * FROM RimReglaNegocio

INSERT INTO RimRNControlCambios(
	bActivo, dFechaCreacion, dFechaModificacion, nIdTipoScript, sObservaciones, sScript, sIdRN, uIdUsuarioCreador
) VALUES 
	-- (1, GETDATE(), GETDATE(), 1, '', 'SELECT TOP 10 mm.sIdMovMigratorio, mm.sIdDocumento, mm.sNumeroDoc FROM SIM.dbo.SimMovMigra mm WHERE mm.bAnulado = 0 AND mm.bTemporal = 0 AND mm.sIdPaisNacionalidad = ''PER'' AND mm.sIdDocumento = ''PAS'' AND LEN(mm.sNumeroDoc) = 9 AND mm.sNumeroDoc LIKE ''1[1-2]%[a-zA-Z]%''', 'RN0003', '3d2220e5-a2f9-4117-b6d0-67eb04984c24')
	(1, GETDATE(), GETDATE(), 1, '', '
		SELECT

			TOP 10 
			mm.sIdMovMigratorio,
			dmm.sTipo

		FROM SIM.dbo.SimMovMigra dmm
		JOIN SIM.dbo.SimPersona dpe ON dmm.uIdPersona = dpe.uIdPersona
		JOIN SIM.dbo.SimCalidadMigratoria dcm ON dmm.nIdCalidad = dcm.nIdCalidad
		LEFT JOIN SIM.dbo.SimSesion ds ON dmm.nIdSesion = ds.nIdSesion
		LEFT JOIN SIM.dbo.SimUsuario du ON ds.nIdOperador = du.nIdOperador
		WHERE
			dmm.bAnulado = 0
			AND dmm.bTemporal = 0
			AND dmm.sIdPaisMov = (''NNN'')

	', 
	'RN0005', '3d2220e5-a2f9-4117-b6d0-67eb04984c24')

-- Bulk 7
/*
	→ CC			: 1, 2
	→ Operador	: 3d2220e5-a2f9-4117-b6d0-67eb04984c24
	→ SELECT * FROM RimRNControlCambios
	→ SELECT * FROM RimRNRegistroEjecucionScript
*/
EXEC sp_help RimRNRegistroEjecucionScript
SELECT * FROM RimRNRegistroEjecucionScript

-- RimRNControlCambios.nId: 1
INSERT INTO RimRNRegistroEjecucionScript(
	bActivo, dFechaEjecucion, nResultado, nIdRNControlCambio
) VALUES 
	(1, GETDATE(), 1056, 1),
	(1, GETDATE(), 1000, 1),
	(1, GETDATE(), 5359, 2),
	(1, GETDATE(), 9566, 2),
	(1, GETDATE(), 5359, 3),
	(1, GETDATE(), 9566, 3),
	(1, GETDATE(), 5359, 4),
	(1, GETDATE(), 9566, 4)



--
SELECT * FROM RimReglaNegocio
INSERT INTO RimReglaNegocio
VALUES
	-- ('RN0003', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sNumeroDoc]', 'Se define como regla, que los números de pasaportes electrónicos deben ser dígitos y una longitud de 8.'),
	-- ('RN0004', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sTipo]', 'Se define como regla, que el tipo de movimiento migratorio deben ser ENTRADA(E) y SALIDA(S).'),
	-- ('RN0005', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sIdPaisMov]', 'Se define como regla, que el pais de movimieno debe ser distinto a vacio, nulo o NNN.')
	-- ('RN0006', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sIdPaisMov]', 'Se define como regla, que todos los registros del elemento de datos [sNombres] de la tabla [SimMovMigra] debe presentar un valor diferente al nulo o vacío.')
	-- ('RN0007', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sIdPaisMov]', 'Se define como regla, que para un registro de la tabla [SimMovMigra] los elementos de datos [sIdPaisNacionalidad]<>” PER” y “NNN”, entonces el elemento de datos [nIdCalidad] debe tener un valor diferente a 21(Peruano).')
	-- ('RN0008', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sIdPaisMov]', 'Se define como regla, que si el elemento de datos [sTipo] presenta el valor "S", entonces el elemento de datos [nPermanencia] debe presentar un valor igual a 0.')
	('RN0010', 1, GETDATE(), 1, 1, 2, '[SIM].[dbo].[SimMovMigra]', '[sIdPaisNacionalidad], [nIdCalidad]', 'Se define como regla, que si para un registro de la tabla [SimMovMigra] los elementos de datos [sIdPaisNacionalidad]=”PER”, entonces el elemento de datos [nIdCalidad] debe tener registrado el valor <> 41(Turista).')

-- Se define como regla, que los números de pasaportes electrónicos deben ser dígitos y una longitud de 8.
-- Se define como regla, que el tipo de movimiento migratorio deben ser ENTRADA(E) y SALIDA(S).
-- Se define como regla, que el pais de movimieno debe ser distinto a vacio, nulo o NNN.


-- Inserta control de cambios:
-- SELECT * FROM RimReglaNegocio
-- SELECT * FROM RimRNControlCambios
EXEC sp_help RimRNControlCambios -- 12
INSERT INTO RimRNControlCambios(bActivo, dFechaCreacion, dFechaModificacion, sObservaciones, nIdTipoScript, sScript, sIdRN, uIdUsuarioCreador)
	SELECT 
		1, GETDATE(), GETDATE(), '', 2, f.sScript, f.sIdRN, f.uIdUsuarioCreador

	FROM (

		SELECT 
			*,
			[#] = ROW_NUMBER() OVER (PARTITION BY c.sIdRN ORDER BY c.dFechaCreacion DESC)
		FROM dbo.RimRNControlCambios c

	) f
	WHERE
		f.# = 1

UPDATE RimRNControlCambios
	SET sScript = REPLACE(sScript, 'TOP 10', '')
WHERE nIdRNControlCambio = 4

INSERT INTO RimRNControlCambios(
	bActivo, dFechaCreacion, dFechaModificacion, nIdTipoScript, sObservaciones, sScript, sIdRN, uIdUsuarioCreador
) VALUES 
	(1, GETDATE(), GETDATE(), 1, '', '
		
		SELECT 
			mm.sIdMovMigratorio, 
			mm.sNumeroDoc
		FROM SIM.dbo.SimMovMigra mm 
		WHERE 
			mm.bAnulado = 0 
			AND mm.bTemporal = 0 
			AND mm.sIdPaisNacionalidad = ''PER''
			AND mm.sIdDocumento = ''PAS''
			AND LEN(mm.sNumeroDoc) = 9 
			AND mm.sNumeroDoc LIKE ''1[1-2]%[a-z]''
			AND mm.dFechaControl >= ''2019-01-01 00:00:00.000''

	',
	'RC0002', '3d2220e5-a2f9-4117-b6d0-67eb04984c24')

-- Update
-- SELECT * FROM RimRNControlCambios
UPDATE RimRNControlCambios
	SET sScript = '
		
		SELECT
			dmm.sIdMovMigratorio
		FROM SIM.dbo.SimMovMigra dmm
		WHERE
			dmm.bAnulado = 0
			AND dmm.bTemporal = 0
			AND dmm.sIdPaisMov = ''NNN''

	'
WHERE nIdRNControlCambio = 7


-- Test
-- SELECT * FROM RimReglaNegocio
-- SIM.dbo.
-- AND smm.dFechaControl >= ''2016-01-01 00:00:00.000''
-- Se define como regla, que si para un registro de la tabla [SimMovMigra] los elementos de datos [sIdPaisNacionalidad]=”PER”
-- Entonces el elemento de datos [nIdCalidad] debe tener registrado el valor <> 41(Turista)."

SELECT * FROM RimRNRegistroEjecucionScript
DELETE FROM RimRNRegistroEjecucionScript
WHERE dFechaEjecucion < '2024-08-07 00:00:00.000'



SELECT * FROM RimReglaNegocio
SELECT * FROM RimRNRegistroEjecucionScript

EXEC sp_help RimRNRegistroEjecucionScript
INSERT INTO RimRNRegistroEjecucionScript(bActivo, dFechaEjecucion, nResultado, nIdRNControlCambio)
	SELECT 
		1, GETDATE(), ROUND(273286836 - (273286836 * RAND()), 0), f.nIdRNControlCambio
	FROM (

		SELECT 
			*,
			[#] = ROW_NUMBER() OVER (PARTITION BY c.sIdRN ORDER BY c.dFechaCreacion DESC)
		FROM RimRNControlCambios c
		WHERE c.nIdTipoScript = 2

	) f
	WHERE
		f.# = 1

SELECT ROUND(273286836 - (273286836 * RAND()), 0)

-- Update status
UPDATE RimReglaNegocio
	SET nIdStatusRegla = 2
WHERE sIdRN = 'RC0002'

SELECT * FROM RimRNRegistroEjecucionScript r
WHERE r.nIdRNControlCambio = 15

DELETE FROM RimRNRegistroEjecucionScript
	WHERE 
		nIdRNControlCambio = 15
		AND dFechaEjecucion < '2024-08-09 10:05:00.000'



SELECT 
	smm.sIdMovMigratorio
FROM SIM.dbo.SimMovMigra smm
WHERE
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	AND (smm.sNombres IS NULL OR smm.sNombres = '')



		SELECT
			dmm.sIdMovMigratorio
		FROM SIM.dbo.SimMovMigra dmm
		WHERE
			dmm.bAnulado = 0
			AND dmm.bTemporal = 0
			AND dmm.sIdPaisMov = 'NNN'


SELECT
	TOP 10 
	pe.sNombre,
	pe.sPaterno,
	pe.sMaterno,
	pe.dFechaNacimiento,
	ce.* 
FROM SIM.dbo.SimCarnetExtranjeria ce
JOIN SIM.dbo.SimTramite t ON t.sNumeroTramite = ce.sNumeroTramite
JOIN SIM.dbo.SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
	-- LEN(CAST(ce.sNumeroCarnet AS INT)) = 4
	LEN(TRY_CAST(ce.sNumeroCarnet AS INT)) = 4
	AND ce.bDuplicado = 0
ORDER BY 
	ce.dFechaEmision DESC

SELECT CAST('0000555' AS INT)
	