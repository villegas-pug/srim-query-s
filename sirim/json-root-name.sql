-- RN00196 | json-root-name: Documento Vinculado(DNI)
/*

[Id Mov Migratorio] = v.sIdMovMigratorio,
v.[Id Persona],
v.[Nombres],
v.[Apellido 1],
v.[Apellido 2],
v.[Sexo],
[Fecha Nacimiento] = CAST(v.[Fecha de Nacimiento] AS DATE),
v.[Nacionalidad],
[Documento] = v.sIdDocumento,
[Numero Doc] = v.sNumeroDoc,
[Login Operador Digita] = COALESCE(u.sLogin, '-'),
[Operador Digita] = COALESCE(u.sNombre, '-')

*/

-- RN00193 | json-root-name: Documento Vinculado(PAS)
/*

[Id Mov Migratorio] = v.sIdMovMigratorio,
v.[Id Persona],
v.[Nombres],
v.[Apellido 1],
v.[Apellido 2],
v.[Sexo],
[Fecha Nacimiento] = CAST(v.[Fecha de Nacimiento] AS DATE),
v.[Nacionalidad],
[Documento] = v.sIdDocumento,
[Numero Doc] = v.sNumeroDoc,
[Login Operador Digita] = COALESCE(u.sLogin, '-'),
[Operador Digita] = COALESCE(u.sNombre, '-')

*/

-- RN00189 | json-root-name: Persona Duplicada
/*
   [Id Persona] = d.uIdPersona,
   [Nombre] = d.sNombre,
   [Primer Ape] = d.sPaterno,
   [Segundo Ape] = d.sMaterno,
   [Sexo] = d.sSexo,
   [Fecha Nacimiento] = d.dFechaNacimiento,
   [Pais Nacionalidad] = d.sIdPaisNacionalidad,
   [Doc Identidad] = d.sIdDocIdentidad,
   [Num Doc Identidad] = d.sNumDocIdentidad,
   [Calidad] = d.sCalidad,
   [Login Operador Digita] = COALESCE(u.sLogin, '-'),
   [Operador Digita] = COALESCE(u.sNombre, '-')
*/

-- RN00154 | json-root-name: Movimiento Duplicado
/*

[Id Persona] = d.uIdPersona,
[Id Mov Migratorio] = d.sIdMovMigratorio,
[Fecha Control] = d.dFechaControl,
[Tipo Movimiento] = d.sTipo,
[Pais Nacionalidad] = d.sIdPaisNacionalidad,
[Documento] = d.sIdDocumento,
[Numero Doc] = d.sNumeroDoc,
[Pais Mov] = d.sIdPaisMov,
[Nombre] = pe.sNombre,
[Paterno] = pe.sPaterno,
[Materno] = pe.sMaterno,
[Sexo] = pe.sSexo,
[Fecha Nacimiento] = pe.dFechaNacimiento,
[Login Operador Digita] = u.sLogin,
[Operador Digita] = u.sNombre


*/



-- Script
DECLARE @json NVARCHAR(MAX) = N'
   {
      "SimPersona": [
         { "name": "Cristopher1" },
         { "name": "Cristopher2" },
         { "name": "Cristopher3" }
      ]
   }
'
DECLARE @json2 NVARCHAR(MAX) = N'
   {
      "SimPersona": [
         { "name": "Cristopher1" },
         { "name": "Cristopher2" },
         { "name": "Cristopher3" }
      ]
   }
'

SELECT JSON_MODIFY(@json, '$.SimMovMigra', @json2)




-- Script

SELECT * 
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.dFechaControl > GETDATE()






-- Script
DROP TABLE IF EXISTS #tmp_mm_dni_vinculado_1
SELECT p2.* INTO #tmp_mm_dni_vinculado_1
FROM (
   SELECT
      [Id Persona] = pe.uIdPersona,
      [Nombres] = pe.sNombre,
      [Apellido 1] = pe.sPaterno,
      [Apellido 2] = pe.sMaterno,
      [Sexo] = pe.sSexo,
      [Fecha de Nacimiento] = pe.dFechaNacimiento,
      [Nacionalidad] = pe.sIdPaisNacionalidad,
      -- Aux
      mm.sIdMovMigratorio, 
      mm.sIdDocumento,
      mm.sNumeroDoc,
      mm.nIdOperadorDigita,
      [#(uId, NumDoc)] = ROW_NUMBER() OVER (
                                             PARTITION BY
                                                   mm.uIdPersona,
                                                   mm.sNumeroDoc
                                             ORDER BY mm.dFechaControl DESC
                                          )
   FROM SIM.dbo.SimMovMigra mm
   JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
      AND pe.sIdPaisNacionalidad = 'PER'
      AND mm.sIdDocumento = 'DNI'
      AND ISNUMERIC(mm.sNumeroDoc) = 1
      AND LEN(mm.sNumeroDoc) = 8

) p2
WHERE
   p2.[#(uId, NumDoc)] = 1

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_mm_dni_vinculado_1 ON #tmp_mm_dni_vinculado_1(sNumeroDoc)

-- `tmp` Conteo por dni.
DROP TABLE IF EXISTS #tmp_mm_dni_vinculado_2
SELECT * INTO #tmp_mm_dni_vinculado_2
FROM (
   SELECT 
      v.*,
      [nCant(NumDoc)(2)] = COUNT(1) OVER (PARTITION BY v.sNumeroDoc)
   FROM #tmp_mm_dni_vinculado_1 v
) f
WHERE f.[nCant(NumDoc)(2)] >= 2

-- Documentos de viaje vinculados recientes únicos 
SELECT f.* INTO #tmp_mm_dni_vinculado_uniq
FROM (
   SELECT
      *,
      [#] = ROW_NUMBER() OVER (PARTITION BY v.sNumeroDoc ORDER BY v.sIdMovMigratorio DESC)
   FROM #tmp_mm_dni_vinculado_2 v
) f
WHERE f.[#] = 1

-- Final
SELECT 
   vu.sIdMovMigratorio,
   [jDatosDuplicados] = (
      SELECT 
         TOP 5
         [Id Mov Migratorio] = v.sIdMovMigratorio,
         v.[Id Persona],
         v.[Nombres],
         v.[Apellido 1],
         v.[Apellido 2],
         v.[Sexo],
         [Fecha Nacimiento] = CAST(v.[Fecha de Nacimiento] AS DATE),
         v.[Nacionalidad],
         [Documento] = v.sIdDocumento,
         [Numero Doc] = v.sNumeroDoc,
         [Login Operador Digita] = COALESCE(u.sLogin, '-'),
         [Operador Digita] = COALESCE(u.sNombre, '-')
      FROM #tmp_mm_dni_vinculado_2 v
      LEFT JOIN SIM.dbo.SimUsuario u ON v.nIdOperadorDigita = u.nIdOperador
      WHERE
         v.[Id Persona] != vu.[Id Persona]
         AND v.sNumeroDoc = vu.sNumeroDoc
      FOR JSON PATH, ROOT('Documento Vinculado(DNI)')
   )
FROM #tmp_mm_dni_vinculado_uniq vu

SELECT * 
FROM RimRNRegistroEjecucionScript ;

EXEC sp_help RimRNTipoScript
EXEC sp_help RimRNDimension
EXEC sp_help RimReglaNegocio
EXEC sp_help RimRNControlCambios
EXEC sp_help RimRNRegistroEjecucionScript

ALTER INDEX ALL ON RimRNAuditoriaControlMigratorio REBUILD

SELECT * FROM SidUsuario


SELECT TOP 10 mm.* 
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDepDigita = (
                           SELECT d.sIdDependencia
                           FROM SIM.dbo.SimDependencia d
                           WHERE d.sNombre LIKE '%daka%'
   )
ORDER BY mm.dFechaControl DESC

-- EXEC sp_help RimRNControlCambios
SELECT 
   c.nIdRNControlCambio,
   c.nRuntime
FROM RimRNControlCambios c
WHERE 
   c.nIdTipoScript = 1
   AND c.nRuntime IS NOT NULL
ORDER BY c.nRuntime DESC

SELECT * FROM RimRNRegistroEjecucionScript e
ORDER BY e.dFechaEjecucion DESC

EXEC sp_help RimRNControlCambios


SELECT * FROM RimRNRegistroEjecucionScript e
ORDER BY e.dFechaEjecucion DESC
