	
-- STEP-01: ...
SELECT * FROM SidUsuario

SELECT * FROM RimTablaDinamica
SELECT * FROM RimGrupoCamposAnalisis

TRUNCATE TABLE Multiples_DNI_2
SELECT TOP 0 * INTO Multiples_DNI_2_12_01_2023 FROM Multiples_DNI_2

-- STEP-02: ...
INSERT INTO RimTablaDinamica(
		bActivo,
		dFechaCreacion,
		sNombre,
		uIdUsrCreador,
		sMetaFieldsCsv,
		nPorcentajeQC
	)
	SELECT 
		bActivo,
		dFechaCreacion,
		sNombre,
		uIdUsrCreador,
		sMetaFieldsCsv,
		nPorcentajeQC
	FROM RimTablaDinamica WHERE nIdTabla = 57

-- STEP-03: Actualizar nombre de tabla en `RImTablaDinamica`
SELECT * FROM Multiples_DNI_2_12_01_2023

WHERE sNombre = 'Multiples_DNI_2_12_01_2023'

UPDATE RimTablaDinamica
	SET sNombre = 'Multiples_DNI_2_12_01_2023'
WHERE
	nIdTabla = 59

-- STEP-04: Crear grupo en `RimGrupoCamposAnalisis`	
SELECT * FROM RimTablaDinamica

INSERT INTO RimGrupoCamposAnalisis
(
	bActivo,
	dFechaCreacion,
	sMetaFieldsCsv,
	sNombre,
	nIdTabla,
	bObligatorio
)
SELECT 
	g.bActivo,
	g.dFechaCreacion,
	g.sMetaFieldsCsv,
	g.sNombre,
	g.nIdTabla,
	g.bObligatorio
FROM RimTablaDinamica t
JOIN RimGrupoCamposAnalisis g ON t.nIdTabla = g.nIdTabla
WHERE 
	t.nIdTabla = 57

SELECT * FROM RimGrupoCamposAnalisis
SELECT * FROM RimTablaDinamica

UPDATE RimGrupoCamposAnalisis
	SET nIdTabla = 59
WHERE 
	nIdGrupo = 52

-- Test ...

-- TRUNCATE TABLE Multiples_DNI_5_6_
SELECT * FROM Multiples_DNI_5_6_
TRUNCATE TABLE Multiples_DNI_2_12_01_2023
SELECT * FROM Multiples_DNI_2_12_01_2023

SET IDENTITY_INSERT Multiples_DNI_5_6_ OFF
SET IDENTITY_INSERT Multiples_DNI_5_6_ ON


sID_Persona_e
sNombre_e
sApellido_Paterno_e
sApellido_Materno_e
sSexo_e
sFecha_Nacimiento_e
sTipo_Documento_e
sNumero_e
sPeriodo_e
sNombre_Ultimo_Operador_e
sCantidad_e
sModulo_Origen_e
sDependencia_Origen_e