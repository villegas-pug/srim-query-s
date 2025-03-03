USE [BD_DQA]
GO

/* USE [BDSidtefim-Test]
GO */

-- » CREATE-USER'S: 
-- -----------------------------------------------------------------------------------------------------------------------------

SELECT * FROM SidUsuario
SELECT * FROM SgcdUsuarios

/* DELETE FROM SgcdUsuarios
WHERE uIdUsuario NOT IN ('3d2220e5-a2f9-4117-b6d0-67eb04984c24') */

/* DELETE FROM SgcdUsuarioProcedimientos
WHERE uIdUsuario NOT IN ('3d2220e5-a2f9-4117-b6d0-67eb04984c24') */
-- -----------------------------------------------------------------------------------------------------------------------------


-- » CREATE-CREDENTIALS:
-- -----------------------------------------------------------------------------------------------------------------------------
UPDATE SgcdUsuarios
	SET sLogin = LOWER(d.sNombre),
		 sNombres = LOWER(d.sNombre)
FROM SgcdUsuarios u
JOIN SIM.dbo.SimDependencia d ON u.sDependencia = d.sIdDependencia
WHERE u.uIdUsuario NOT IN ('e02d28b5-944a-4da6-a601-f61e9b4446b4', '3d2220e5-a2f9-4117-b6d0-67eb04984c24')

UPDATE SgcdUsuarios
	SET sIdJefatura = UPPER(sLogin)

-- ► Create User ...
-- SELECT * FROM SgcdUsuarios
INSERT INTO SgcdUsuarios(uIdUsuario, bActivo, sArea, sCargo, sDni, sLogin, sNombres, xPassword, sRegimenLaboral, sIdJefatura)
VALUES
	(NEWID(), 1, 'SRIM', 'ANALISTA PROGRAMADOR', '46392613', 'srim', 'srim', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'LOCADOR', 'srim'),
	(NEWID(), 1, 'JZAREQ', 'JZAREQ', '27041243', 'jzareq', 'JZAREQ', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZCALL', 'JZCALL', '27041243', 'jzcall', 'JZCALL', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZCHIC', 'JZCHIC', '27041243', 'jzchic', 'JZCHIC', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZCHIM', 'JZCHIM', '27041243', 'jzchim', 'JZCHIM', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZCUSC', 'JZCUSC', '27041243', 'jzcusc', 'JZCUSC', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZHCYO', 'JZHCYO', '27041243', 'jzhcyo', 'JZHCYO', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZILO', 'JZILO', '27041243', 'jzilo', 'JZILO', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZIQUI', 'JZIQUI', '27041243', 'jziqui', 'JZIQUI', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZLIMA', 'JZLIMA', '27041243', 'jzlima', 'JZLIMA', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZPIUR', 'JZPIUR', '27041243', 'jzpiur', 'JZPIUR', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZPTOM', 'JZPTOM', '27041243', 'jzptom', 'JZPTOM', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZPUCA', 'JZPUCA', '27041243', 'jzpuca', 'JZPUCA', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZPUNO', 'JZPUNO', '27041243', 'jzpuno', 'JZPUNO', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZTACN', 'JZTACN', '27041243', 'jztacn', 'JZTACN', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZTPTO', 'JZTPTO', '27041243', 'jztpto', 'JZTPTO', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZTRUJ', 'JZTRUJ', '27041243', 'jztruj', 'JZTRUJ', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL'),
	(NEWID(), 1, 'JZTUMB', 'JZTUMB', '27041243', 'jztumb', 'JZTUMB', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'CAS', 'JEFE ZONAL')
	
-- 8; 9
INSERT 
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES 
		(1, GETDATE(), 8, '043e0710-9252-465e-8c39-26e584509b79'),
		(1, GETDATE(), 8, '8db1b00f-1cff-4f73-a0df-27e2bceadfab'),
		(1, GETDATE(), 8, '175012f8-e53b-48f5-8129-49c358ef08d9'),
		(1, GETDATE(), 8, '768d349a-a39c-4cbb-b57a-5f8cb5766586'),
		(1, GETDATE(), 8, '578cf45b-35ec-4aad-88c5-67c150d5f3f2'),
		(1, GETDATE(), 8, 'e3e7c90d-cfe5-4ad7-90a3-83f87360967f'),
		(1, GETDATE(), 8, 'ddf6eacb-c244-4177-88b8-8928c6b59e45'),
		(1, GETDATE(), 8, 'daa8071e-77d6-4321-ba04-8953217a91d7'),
		(1, GETDATE(), 8, '228aedf3-59db-444a-91cb-8f876a07801f'),
		(1, GETDATE(), 8, '75ea4531-7464-4650-911f-975f02559133'),
		(1, GETDATE(), 8, '530276cb-b17e-4d24-adf0-a8a4e42407fd'),
		(1, GETDATE(), 8, 'e949f4f3-d55c-4380-9ac9-ac331654c7a8'),
		(1, GETDATE(), 8, 'f6724b2a-3ebf-444d-9ab4-c1dfdf0960f6'),
		(1, GETDATE(), 8, 'cb6ce43a-7a9d-4d2e-9420-cae02597f085'),
		(1, GETDATE(), 8, '8e1149c6-10ac-4a29-85aa-cf77812ad2e3'),
		(1, GETDATE(), 8, '33236f51-c427-4aba-807c-cfef899fedf6'),
		(1, GETDATE(), 8, 'd0aafd7f-fd18-4ebb-b3f3-e79b91477f0c')

/* ► 
	Create: Perfil ... 
	--► MOD: 69, 70, 73, 74
	--► SUBMOD: 84(BUSCAR INTERPOL), 98(EXTRACCIÓN DE DATOS), 99(DEPURAR EXTRACCIÓN), 100(ASIGNAR EXTRACCIÓN), 101(BUSCAR DNV), 102(ANALIZAR EXTRACCIÓN)
*/
SELECT * FROM SgcdUsuarios
SELECT * FROM SgcdProcedimientos
UPDATE SgcdUsuarios
	SET sGrupo = 'ANALISIS'-- 'DEPURACION' --ANALISIS
WHERE sLogin = 'MRODRIGUEZC'

--► Admin:
-- SELECT * FROM SgcdUsuarios
-- SELECT * FROM SgcdUsuarioProcedimientos
-- SELECT * FROM SgcdProcedimientos
UPDATE SgcdUsuarios
	-- SET sDependencia = '27'
	SET sDependencia = '27'
WHERE uIdUsuario = '3d2220e5-a2f9-4117-b6d0-67eb04984c24'

SELECT * 
FROM SgcdUsuarios u WHERE u.uIdUsuario = 'e02d28b5-944a-4da6-a601-f61e9b4446b4'

INSERT 
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 1, 'a56814ce-4fd7-40e5-82a7-a34d613d736f')



/*► 
	→ Cordinador | Analista ... 
	--► MOD: 69, 70, 73, 74
	--► SUBMOD: 84(BUSCAR INTERPOL), 98(EXTRACCIÓN DE DATOS), 99(DEPURAR EXTRACCIÓN), 100(ASIGNAR EXTRACCIÓN), 101(BUSCAR DNV), 102(ANALIZAR EXTRACCIÓN)
	--► 5ED651A0-9040-4F3B-80A9-1E8B94FCF612 | 354FAEA3-5585-4BB4-93F3-D409926F94BA
	--► 4E385A8B-4C1E-4F76-8851-668A63FCA0CE
*/
-- SELECT * FROM SgcdUsuarios
-- SELECT * FROM SgcdProcedimientos WHERE nIdProcedimiento IN (69, 70, 73, 74, 84, 98, 99, 100, 101, 102)
-- DELETE FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = '38DDCE48-0760-4C82-8501-34CB0BF888C2' 
-- Dep's 
SELECT [value] INTO #tmp_idProc 
FROM 
	STRING_SPLIT('69, 70, 73, 74, 75, 84, 98, 99, 100, 101, 102, 103, 104, 107, 109, 110, 111', ',') -- Cordinador
	-- STRING_SPLIT('69, 70, 73, 74, 84, 101, 102, 108', ',') -- Analista

WHILE((SELECT COUNT(1) FROM #tmp_idProc) > 0)
BEGIN
	DECLARE @idProc INT = (SELECT TOP 1 [value] FROM #tmp_idProc ORDER BY [value])

	INSERT 
		INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
		VALUES (1, GETDATE(), @idProc, '38DDCE48-0760-4C82-8501-34CB0BF888C2')

	-- Clean-up ...
	DELETE FROM #tmp_idProc WHERE [value] = @idProc
END

-- Clean-up
DROP TABLE IF EXISTS #tmp_idProc
/*-----------------------------------------------------------------------------------------------------------------------------*/
	
-- » MOD'S:
EXEC sp_help SgcdProcedimientos

INSERT INTO SgcdProcedimientos
	(
		bActivo, sNombre, sDescripcion, sInformacion, sIcono, sRutaPag, sRutaSubpag, sTipo, nSecuencia
	)
	VALUES
	   -- (1, 'Inicio', 'Página principal', '', 'Home', '/', '', 'PAG', 1),
	   (1, 'Gestionar escenarios', 'Administración para listar, crear, editar y eliminar escenarios.', 'Gestión de escenarios.', 'apartment', 'gestion-escenarios', '', 'PAG', 1),
	   (1, 'Gestionar requerimientos', 'Administración para listar, crear, editar y eliminar requerimientos.', 'Gestión de requerimientos.', 'appstore-add', 'gestion-requerimientos', '', 'PAG', 2),
	   (1, 'Gestionar reglas', 'Administración para listar, crear, editar y eliminar reglas.', 'Gestión de reglas.', 'branches', 'gestion-reglas', '', 'PAG', 3),
	   (1, 'Gestionar Plan Mejora', 'Administración para listar, crear, editar y eliminar reglas.', 'Gestión de plan de mejora.', 'fund-view', 'gestion-plan-mejora', '', 'PAG', 4),
	   (1, 'Reportes', 'Reportes del sistema integral de calidad datos.', 'Reportes.', 'project', 'reportes', '', 'PAG', 5),
	   (1, 'Estadísticas', 'Estadísticas del sistema integral de calidad datos.', 'Estadísticas.', 'area-chart', 'estadisticas', '', 'PAG', 6)
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
	   -- (1, 'Seguimiento Calidad de Datos', 'Seguimiento de cálidad de los datos migratorios.', '', 'MdNearbyError', '/seguimiento-calidad', '', 'PAG', 1)
		
-- Test
SELECT * FROM SgcdProcedimientos
/* DELETE FROM SgcdProcedimientos
WHERE nIdProcedimiento = 7 */

-- » SUB-MOD'S:
INSERT INTO SgcdProcedimientos
	(
		bActivo, sNombre, sDescripcion, sInformacion, sIcono, sRutaPag, sRutaSubpag, sTipo, nSecuencia
	)
	VALUES
		(1, 'Control Migratorio', 'Registros migratorios de ciudadanos nacionales y extranjeros.', '', 'PiAirplaneLandingFill', '/reglas-consistencia', '/control-migratorio', 'SUB_PAG', 1)
	   -- (1, 'Trámites de Inmigración', 'Registros trámites de ciudadanos extranjeros.', 'FaPersonMilitaryToPerson', '', '/reglas-consistencia', '/tramites-inmigracion', 'SUB_PAG', 2),
	   -- (1, 'Alertas', 'Registro de alertas de personas nacionales y extranjeras.', 'AiFillAlert', '', '/reglas-consistencia', '/alertas', 'SUB_PAG', 3)
	   -- (1, 'Seguimiento Control Migratorio', 'Seguimiento de calidad de datos del control migratorio de personas nacionales y extranjeras.', '', 'PiAirplaneLandingFill', '/seguimiento-calidad', '/control-migratorio', 'SUB_PAG', 1)
	   -- (1, 'Emisión de Doc. Viaje', 'Emisión de Documento de viaje de personas nacionales y extranjeras.', '', 'GrDocumentTransfer', '/reglas-consistencia', '/documento-viaje', 'SUB_PAG', 1),
	   -- (1, 'Nacionalización', 'Procedimientos de Nacionalización de personas extranjeras.', '', 'GiTargetPrize', '/reglas-consistencia', '/nacionalizacion', 'SUB_PAG', 1)
		

-- ► Update: SUBMOD secuencia ...
-- SELECT * FROM SgcdProcedimientos WHERE nIdProcedimiento = 51
SELECT * FROM SgcdUsuarios
SELECT * FROM SgcdProcedimientos
UPDATE SgcdProcedimientos
	SET sRutaSubpag = '/nacionalizacion'
WHERE nIdProcedimiento = 11

SELECT * FROM SgcdProcedimientos p
WHERE p.sTipo = 'SUB_MODULO'

DELETE FROM SgcdUsuarioProcedimientos
WHERE
	uIdUsuario = 'A12E06BB-4BC7-4E92-A4B5-79F0967B1A58'
	AND nIdProcedimiento = 98


UPDATE SgcdProcedimientos
SET sNombre = 'REPORTE DIARIO DE PRODUCCIÓN'
WHERE nIdProcedimiento = 104
		
SELECT * FROM SgcdProcedimientos
SELECT TOP 10 * FROM BD_SIRIM.dbo.SidProcedimiento

/*» ITEM'S */
INSERT INTO SgcdProcedimientos
	(
		bActivo, sNombre, sInformacion, sDescripcion, sIcono, sRutaPag, sRutaSubpag, sTipo
	)
	VALUES
		(1, 'INCONSISTENCIAS', 'Procedimientos inconsistentes', 'Procedimiento no registrados en SIM-NAC', 'Person', '/reportes', '/nacionalizacion', 'Inconsistencias', 'ITEM'),
		(1, 'PENDIENTES', 'Procedimientos pendientes', 'Reporte de procedimientos pendientes 2016 al 2021', 'Person', '/reportes', '/nacionalizacion', 'Pendientes', 'ITEM'),
		(1, 'NACIONALIZADOS', 'Procedimientos pendientes', 'Reporte de procedimientos pendientes 2016 al 2021', 'Person', '/reportes', '/nacionalizacion', 'Nacionalizados', 'ITEM'),
		(1, 'ATENDIDOS', 'Procedimientos pendientes', 'Reporte de procedimientos pendientes 2016 al 2021', 'Person', '/reportes', '/nacionalizacion', 'Atendidos', 'ITEM')

-- » SUB-ITEM'S
INSERT INTO SgcdProcedimientos
	(
		bActivo, sNombre, sIcono, sRutaPag, sRutaSubpag, sTipo
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
-- SELECT * FROM SgcdUsuarios
-- SELECT * FROM SgcdUsuarioProcedimientos
-- SELECT * FROM SgcdProcedimientos
DECLARE @uId UNIQUEIDENTIFIER = 'a56814ce-4fd7-40e5-82a7-a34d613d736f'
INSERT INTO SgcdUsuarioProcedimientos(bDenegado, nIdProcedimiento, dFechaRegistro, uIdUsuario)
	SELECT 1, p.nIdProcedimiento, GETDATE(), @uId  FROM SgcdProcedimientos p
	WHERE p.nIdProcedimiento != 1

SELECT * FROM SgcdProcedimientos

/*» RESET ROLES */
--DELETE FROM SgcdUsuarioProcedimientos
--DELETE FROM SgcdProcedimientos
--DBCC CHECKIDENT ('[SgcdProcedimientos]', RESEED,0)
--TRUNCATE TABLE SgcdProcedimientos
/*
ALTER TABLE SgcdProcedimientos
	ALTER COLUMN sIcono VARCHAR(25) NULL */

/*» Test ...*/
SELECT * FROM SgcdUsuarios
	--WHERE uIdUsuario = '6B234CBC-FBC8-4EBC-85AA-E4B3A3807828'
	WHERE sLogin = 'rguevarav'

SELECT * FROM SgcdUsuarioProcedimientos 
	WHERE uIdUsuario = 'A12E06BB-4BC7-4E92-A4B5-79F0967B1A58'

SELECT * FROM SgcdProcedimientos p
WHERE p.sTipo = 'SUB_MODULO'
-- 5 | Procedimiento 
-- 51 | Depuración de datos → CleaningServicesRounded
-- 53 | ASIGNAR EXTRACCIÓN → GroupsRounded

SELECT * FROM SgcdUsuarios
UPDATE SgcdProcedimientos SET nSecuencia = 0

/*
DELETE FROM SgcdUsuarioProcedimientos 
WHERE 
	uIdUsuario = '74260A42-F392-4564-9B9F-A744A32D219A'
	AND nIdProcedimiento = 52
*/
--WHERE uIdUsuario = '5ED651A0-9040-4F3B-80A9-1E8B94FCF612' -- NPASTOR: 5ED651A0-9040-4F3B-80A9-1E8B94FCF612
--WHERE uIdUsuario = '354FAEA3-5585-4BB4-93F3-D409926F94BA' -- EGOLIVERA: 354FAEA3-5585-4BB4-93F3-D409926F94BA
-- SELECT * FROM SgcdUsuarios
-- SELECT * FROM SgcdProcedimientos
-- 104 | REPORTE DE PRODUCCIÓN DIARIO
-- 110 | REPORTE PASAPORTES
-- 112 | CONVENIOS
INSERT
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 72, '23013539-706D-4EF7-9AE2-66839583E7C8')

/*» ROL: ADMIN */
/*--------------------------------------------------------------------------------------------*/
SELECT nIdProcedimiento INTO #tmp FROM SgcdProcedimientos
DECLARE @count_tmp INT = (SELECT COUNT(1) FROM #tmp),
		  @idProc INT
WHILE (@count_tmp > 0)
BEGIN
	SET @idProc = (SELECT TOP 1 nIdProcedimiento FROM #tmp ORDER BY nIdProcedimiento ASC)
	INSERT 
		INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
		VALUES (1, GETDATE(), @idProc, '6B234CBC-FBC8-4EBC-85AA-E4B3A3807828')
	
	DELETE FROM #tmp WHERE nIdProcedimiento = @idProc
	SET @count_tmp = (SELECT COUNT(1) FROM #tmp)
END
--DELETE FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = '4B0383AD-D59C-9F40-83FA-76E1FB5E5F93'
/*--------------------------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------------------------------------------------------------
» ROL		: USER-SFM
» MOD		: 1 | 2 | 3
» SUBMOD	: 8
---------------------------------------------------------------------------------------------------------------------------------*/
DECLARE @uId UNIQUEIDENTIFIER = '6B6E1B18-12BC-4D38-B5ED-F8C6CE058C79'
INSERT 
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES 
		(1, GETDATE(), 1, @uId),
		(1, GETDATE(), 2, @uId),
		(1, GETDATE(), 3, @uId),
		(1, GETDATE(), 8, @uId)
/*» 25 ...*/
SELECT * FROM SgcdUsuarios WHERE sArea = 'SFM'
/*---------------------------------------------------------------------------------------------------------------------------------*/


/*---------------------------------------------------------------------------------------------------------------------------------*/
/*
» ROL		: ADMIN-SFM 
» MOD		: 1 | 2 | 3 | 5 | 7
» SUBMOD	: 8 | 9 | 16
*/
/*--------------------------------------------------------------------------------------------*/
INSERT 
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 16, '2DE78A3B-7C8C-4E30-917B-A676FE57911A')

	SELECT * FROM SgcdUsuarios WHERE sNombres LIKE '%mirian%'
	SELECT * FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = '2DE78A3B-7C8C-4E30-917B-A676FE57911A'
/*--------------------------------------------------------------------------------------------*/

/*
» ROL		: CORDINADOR-SGTM
» MOD		: 1 | 2 | 6 | 7
» SUBMOD	: 12 | 14 | 17
» ITEM		: 18 | 19 | 20 | 21
*/
/*--------------------------------------------------------------------------------------------*/
INSERT 
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 21, 'F5ADDF9A-31C9-471A-8885-0E82E2657790')

	SELECT * FROM SgcdUsuarios WHERE sNombres LIKE '%palma%'
	SELECT * FROM SgcdProcedimientos WHERE sTipo = 'ITEM'
	SELECT * FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = 'F5ADDF9A-31C9-471A-8885-0E82E2657790'
/*--------------------------------------------------------------------------------------------*/

/*
» ROL		: EVALUADOR
» MOD		: 1 | 6
» SUBMOD	: 12 | 13
*/
INSERT 
	INTO SgcdUsuarioProcedimientos(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
	VALUES (1, GETDATE(), 41, '4B0383AD-D59C-9F40-83FA-76E1FB5E5F93')

SELECT * FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = '4BCCEE09-BFF8-6742-B5E4-0771A87BADCB'

/*» Test...*/
DELETE FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = 'A1F2C292-61F8-9141-BAB5-43D77D44681F'
UPDATE SgcdUsuarioProcedimientos 
	SET nIdProcedimiento = 6 
	WHERE 
		uIdUsuario = 'A1F2C292-61F8-9141-BAB5-43D77D44681F'
		AND nIdProcedimiento = 5

SELECT * FROM SgcdProcedimientos
SELECT * FROM SgcdUsuarioProcedimientos

INSERT SgcdUsuarioProcedimientos

SELECT TOP 10 * FROM RimRNAuditoriaControlMigratorio a

SELECT * FROM SgcdProcedimientos
SELECT * FROM SgcdUsuarioProcedimientos WHERE uIdUsuario = '2DE78A3B-7C8C-4E30-917B-A676FE57911A'
SELECT * FROM SgcdUsuarios WHERE uIdUsuario = '2DE78A3B-7C8C-4E30-917B-A676FE57911A'
/*---------------------------------------------------------------------------------------------------------------------------------*/

/* ░ Actualizar sGrupo en SgcdUsuarios
	» 
*/
/*---------------------------------------------------------------------------------*/
-- SELECT * FROM SgcdUsuarios
-- SELECT * FROM SgcdProcedimientos
-- UPDATE SgcdProcedimientos SET nSecuencia = 5 WHERE nIdProcedimiento = 60

UPDATE SgcdUsuarios
SET sGrupo = 'ANALISIS'
WHERE uIdUsuario = 'BF1ED352-D6A1-4255-ADD3-9F592F33477A'

-- DEPURACION
-- ANALISIS
/*---------------------------------------------------------------------------------*/


SELECT * 
FROM SIM.dbo.SimDependencia d
WHERE d.sNombre LIKE '%Cajamarca%'

SELECT * FROM RimRNJefaturaZonal
EXEC sp_help RimRNJefaturaZonal

-- INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES()

SELECT TOP 10 * 
FROM SIM.dbo.SimPasaporte p
WHERE p.sPasNumero LIKE '1[1-2]%'
ORDER BY p.dFechaEmision DESC

-- RinRNProceso
SELECT * FROM RimRNProceso
SELECT [nTotal] = COUNT(1) INTO #tmp_total_ctrl_migra 
FROM SIM.dbo.SimMovMigra mm
WHERE mm.bAnulado = 0 AND mm.bTemporal = 0

SELECT [nTotal] = COUNT(1) INTO #tmp_total_incorr_ctrl_migra 
FROM RimRNAuditoriaControlMigratorio

UPDATE RimRNProceso
	SET nTotalRegCorrectos = (SELECT t.nTotal FROM #tmp_total_ctrl_migra t) - (SELECT t.nTotal FROM #tmp_total_incorr_ctrl_migra t),
		 nTotalRegIncorrectos = (SELECT t.nTotal FROM #tmp_total_incorr_ctrl_migra t),
		 nTotalRegistros = (SELECT t.nTotal FROM #tmp_total_ctrl_migra t),
		 nTotalReglas = (SELECT COUNT(1) FROM RimReglaNegocio)
WHERE nIdProceso = 1

SELECT TOP 10 * 
FROM SIM.dbo.SimMovMigra ;

WITH CTE_SimMovMigra AS (
    SELECT 
        smm.sIdMovMigratorio, 
        smm.bTemporal, 
        smm.bAnulado,
        smm.sIdModuloDigita, 
        smm.nIdEstacionDigita,
        smm.sTipo,
        smm.dFechaControl, 
        smm.sIdPaisMov,
        smm.sIdViaTransporte,
        smm.uIdPersona,
        smm.sIdItinerario,
        smm.nIdTransportista,
       smm.nIdSesion
    FROM SIM.dbo.SimMovMigra smm WITH(INDEX (IX_SimMovMigra_21))
    WHERE smm.sIdViaTransporte = 'A' 
      AND smm.dFechaControl BETWEEN DATEADD(MINUTE, -10, GETDATE()) AND GETDATE()
      AND smm.sIdDependencia = '27'
)
SELECT 
       smm.sIdMovMigratorio, 
       smm.bTemporal, 
       smm.bAnulado,
       smm.sIdModuloDigita, 
       smm.nIdEstacionDigita,
       smm.nIdSesion,
       se.sNombre AS nombreEstacionDigita,
       smm.sTipo,
       smm.dFechaControl, 
       smm.sIdPaisMov,
       si.sIdCiudad as sIdCiudadMov, 
       smm.sIdViaTransporte, 
       set2.sSigla,
       set2.sNombreRazon, 
       si.sNumeroNave,
       si.nCantidadMov,
       si.dFechaProgramada, 
       smm.uIdPersona,
       sp.sNombre,
       sp.sPaterno,
       sp.sMaterno,
       sp.sSexo, 
       sp.dFechaNacimiento,
       sp.sIdPaisNacionalidad, 
       smm.sIdItinerario,
       sei.sIdEstadoItinerario, 
       sei.sNombre as sNombreEstadoItinerario
FROM CTE_SimMovMigra smm
LEFT JOIN SIM.dbo.SimEmpTransporte set2 ON smm.nIdTransportista = set2.nIdTransportista
LEFT JOIN SIM.dbo.SimItinerario si ON smm.sIdItinerario = si.sIdItinerario  
LEFT JOIN SIM.dbo.SimEstadoItinerario sei ON sei.sIdEstadoItinerario = si.sEstado 
LEFT JOIN SIM.dbo.SimPersona sp ON smm.uIdPersona = sp.uIdPersona
LEFT JOIN SIM.dbo.SimEstacion se ON smm.nIdEstacionDigita = se.nIdEstacion;
