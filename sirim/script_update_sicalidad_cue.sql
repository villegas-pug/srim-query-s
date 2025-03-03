USE [BD_DQA]
GO

/* USE [BDSidtefim-Test]
GO */

-- » CREATE-CREDENTIALS:
-- -----------------------------------------------------------------------------------------------------------------------------

-- ► Create User ...
SELECT * FROM SidUsuario
EXEC sp_help SidUsuario
-- SELECT * FROM SidUsuario
-- Admin:
INSERT INTO SidUsuario(uIdUsuario, bActivo, sArea, sCargo, sGrupo, sDependencia, sDni, sLogin, sNombres, xPassword, sRegimenLaboral, sIdJefatura, nIdOperador)
-- VALUES
	-- (NEWID(), 1, 'SRIM', 'ANALISTA DE DATOS', 'CUE', '25', '46392613', 'rguevarav', 'Rooy Cristopher Guevara Villegas', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'LOCADOR', 'JZLIMA', 1)
	-- (NEWID(), 1, 'SRIM', 'ANALISTA DE DATOS', 'CUE', '25', '46392613', 'locador_srim_02', 'Rooy Cristopher Guevara Villegas', '$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO', 'LOCADOR', 'JZLIMA', 2)
	SELECT
		NEWID(), 
		1, 
		'SRIM', 
		'ANALISTA CUE', 
		'CUE',
		u.sIdDependencia, 
		u.sDni,
		u.sLogin, 
		u.sNombre, 
		'$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO',
		'CAS',
		'JZLIMA',
		u.nIdOperador
	FROM SIM.dbo.SimUsuario u
	WHERE u.nIdOperador IN (
		3056, -- MRODRIGUEZC - Rodriguez Coloma, Manuel Augusto
		3651, -- EORMACHEA - Ormachea Fidel, Erie Flor
		4457, -- ASALDARRIAGAA - Saldarriaga Arenas, Allison Gianella
		7155, -- LCONTRERAS - Contreras Rojas, Liz Elvia
		3605, -- NVASQUEZ - Vasquez Vacalla, Nathaly Megg
		4063  -- CALCANTARA - Alcantara Castañeda, Carmen Carol
	)
	
-- » Inserta MOD'S:
EXEC sp_help SidProcedimiento 
SELECT * FROM SidProcedimiento

INSERT INTO SidProcedimiento
	(
      bActivo, sNombre, sDescripcion, sIcono, sRutaPag, sRutaSubpag, nSecuencia, sTipo
	)
	VALUES 
      (1, 'Módulo de Unificación', 'Gestión de Unificación de Registros', 'TbBrandDatabricks', '/unificacion-registros', '', 1, 'PAG')
		
-- Test
SELECT * FROM SidProcedimiento

-- » SUB-MOD'S:
INSERT INTO SidProcedimiento
	(
      bActivo, sNombre, sDescripcion, sIcono, sRutaPag, sRutaSubpag, nSecuencia, sTipo
	)
	VALUES -- LuWorkflow
		-- (1, 'Control de Asignaciones', 'Seguimiento de Asignaciones', 'LuWorkflow', '/unificacion-registros', '/asignaciones', 2, 'SUB_PAG')
		(1, 'Auditoría de registros', 'Proceso de validacion y modificación', 'OrderedListOutlined', '/unificacion-registros', '/auditoria', 2, 'SUB_PAG')
		


-- » Accesos:

-- rguevarav | 890db36a-9230-4cfe-bd7e-60b7317f18de | 12, 13
-- SELECT * FROM SidProcedimiento
-- SELECT TOP 1 * FROM SidUsuarioProcedimiento
-- EXEC sp_help SidUsuarioProcedimiento

INSERT INTO SidUsuarioProcedimiento(bDenegado, dFechaRegistro, nIdProcedimiento, uIdUsuario)
VALUES
   -- (0, GETDATE(), 12, '85065382-0908-43b1-a6ff-7dd8075f434e'),
   (0, GETDATE(), 13, '85065382-0908-43b1-a6ff-7dd8075f434e')
   -- (0, GETDATE(), 14, '85065382-0908-43b1-a6ff-7dd8075f434e')


	SELECT
		0,
		GETDATE(),
		14,
		u.uIdUsuario
	FROM BD_SIRIM.dbo.SidUsuario u
	WHERE u.nIdOperador IN (
		3056, -- MRODRIGUEZC - Rodriguez Coloma, Manuel Augusto
		3651, -- EORMACHEA - Ormachea Fidel, Erie Flor
		4457, -- ASALDARRIAGAA - Saldarriaga Arenas, Allison Gianella
		7155, -- LCONTRERAS - Contreras Rojas, Liz Elvia
		3605, -- NVASQUEZ - Vasquez Vacalla, Nathaly Megg
		4063  -- CALCANTARA - Alcantara Castañeda, Carmen Carol
	)

SELECT * 
FROM SIM.dbo.SimUsuario u
WHERE u.sNombre LIKE '%Saldarriaga Arenas%'

-- Test
SELECT * FROM SegAsignacion
EXEC sp_help SegAsignacion
--SELECT * FROM SegAsignacion

SELECT a.IdAsignacion AS idAsignacion FROM BD_SIRIM.dbo.SegAsignacion a
 

INSERT INTO SidUsuario(uIdUsuario, bActivo, sArea, sCargo, sDependencia, sDni, sLogin, sNombres, xPassword, sRegimenLaboral, sIdJefatura, nIdOperador)
	SELECT  
		NEWID(), 
		1, 
		'SRIM', 
		'ANALISTA DE DATOS', 
		'25', 
		u.sDNI,
		u.sLogin,
		u.sNombre, 
		'$2a$10$SmgP1tGoOkTJdRfuo71ew.sUO4oCIA1h2Vtji1kJJhiPSYXgyrEZO',
		'CAS', 
		'JZLIMA',
		u.nIdOperador 
	FROM SIM.dbo.SimUsuario u
	WHERE
		u.sLogin IN (
			'JPONCES',
			'MRODRIGUEZ',
			'NPASTOR'
		)



SELECT * FROM SidUsuario u
WHERE u.nIdOPerador = 2

UPDATE SidUsuario
	SET sGrupo = 'CUE'
WHERE sLogin = 'locador_srim_02'

EXEC [dbo].[usp_SRIM_INS_ASIGNACION_V1] 4457, 1, 300

SELECT * FROM [dbo].[SegTipoAsignacion]
SELECT * FROM [dbo].[SegTipoAsignacion]
SELECT * FROM BD_SIRIM.dbo.SegTipoAsignacion
SELECT TOP 10 * FROM BD_SIRIM.[dbo].[SegAsignacion]

-- DELETE FROM SegAsignacion

EXEC sp_help SegTipoAsignacion

SELECT 
	* FROM BD_SIRIM.[dbo].[SegAsignacion] a
GROUP BY a.nIdOperador

EXEC sp_help SegEstados
EXEC sp_help SegAsignacion

TRUNCATE TABLE SegAsignacion

SELECT TOP 100 * FROM [dbo].[SegAsignacion] a WHERE a.bTrabajado = 1
WHERE 
	-- a.IdAsignacion = 301
	a.nIdJustifica IS NOT NULL

SELECT * FROM [dbo].[SegEstados]
SELECT * FROM [dbo].[SegTipoJustificacion]
SELECT * FROM [dbo].[SegTipoAsignacion]

EXEC sp_help SegAsignacion

SELECT 
	a.IdAsignacion,
	a.nIdEstado,
	a.nIdJustifica,
	a.nObservacion
FROM BD_SIRIM.[dbo].[SegAsignacion] a
WHERE a.idAsignacion = 1

SELECT COUNT(1) FROM [dbo].[tmp_dupl_personas_mm]

EXEC [dbo].[usp_SRIM_INS_ASIGNACION_V1] 4457, 1, 300, '2025-02-18'


UPDATE SegAsignacion
	SET nIdEstado = 1,
		 nIdJustifica = 1

EXEC USP_SEG_LISTA_ASIGNACION 2, 1, '2025-02-20'

SELECT * FROM SegEstados
TRUNCATE TABLE SegAsignacion
SELECT * FROM SegAsignacion

usp_SRIM_INS_ASIGNACION_V1

