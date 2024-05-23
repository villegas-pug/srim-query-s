USE SIM
GO

/*»
   → En relación a los otros casos, se verificó a la ciudadana Sandra Verónica Fernández Chillogalli
    ingreso el 14/01/2024 a las 15:42 horas y salió el 06/02/204 a las 12:32 am por tumbes ambos movimientos
-- =========================================================================================================================== */

-- Apoderada: 484db926-165f-47ee-93d4-68c7c970cf95 | FERNANDEZ CHILLOGALLI SANDRA VERONICA | F | 1993-05-29
-- Menor 1: 21f71884-d42b-42d3-8f68-219b2389bee0 | MACAS	FERNANDEZ ERIKA JESSENIA | F | 2013-03-25
DECLARE @nombre VARCHAR(255) = 'Erika Jessenia',
        @priApe VARCHAR(255) = 'Macas',
        @segApe VARCHAR(255) = 'Fernández'

SELECT sper.* FROM SimPersona sper 
WHERE 
   sper.bActivo = 1
   AND SOUNDEX(sper.sNombre) = SOUNDEX(@nombre)
   AND SOUNDEX(sper.sPaterno) = SOUNDEX(@priApe)
   AND SOUNDEX(sper.sMaterno) = SOUNDEX(@segApe)

-- 1. `tmp` Salida de menores por PCF TUMBES-CEBAFEV1ECU en 14/01/2024 BETWEEN 15:40 AND 16:00 ...
DROP TABLE IF EXISTS #tmp_salida_menores_TUMBESCEBAFEV1ECU
SELECT -- 1,281
   smm.uIdPersona,
   [Fecha Control] = smm.dFechaControl,
   [Fecha] = CAST(smm.dFechaControl AS DATE),
   [Tipo Movimiento] = smm.sTipo,
   [Dependencia] = sd.sNombre,
   [Pais Mov] = smm.sIdPaisMov,
   [Nombre] = sper.sNombre,
   [Paterno] = sper.sPaterno,
   [Materno] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sper.dFechaNacimiento,
   [Documento] = smm.sIdDocumento,
   [Numero Doc] = smm.sNumeroDoc,
   [Login Operador] = su.sLogin,
   [Operador] = su.sNombre,
   [Via Transporte] = svt.sDescripcion,
   [Pais Nacionalidad] = smm.sIdPaisNacionalidad,
   [Observaciones] = smm.sObservaciones
   INTO #tmp_salida_menores_TUMBESCEBAFEV1ECU
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
JOIN SimViaTransporte svt ON smm.sIdViaTransporte = svt.sIdViaTransporte
JOIN SimUsuario su ON smm.nIdOperadorDigita = su.nIdOperador
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.sTipo = 'S'
   -- AND smm.dFechaControl BETWEEN '2024-01-14 16:00:00.000' AND '2024-02-07 23:59:59.999'
   AND smm.dFechaControl >= '2024-01-14 16:00:00.000'
   -- AND smm.sIdDependencia = '81' -- 81 | S | PCF TUMBES-CEBAFEV1ECU
   AND DATEDIFF(YYYY, sper.dFechaNacimiento, GETDATE()) < 18 -- Menor de edad ...
   -- AND smm.uIdPersona = '484db926-165f-47ee-93d4-68c7c970cf95'
ORDER BY smm.dFechaControl

-- 2: ...
SELECT * FROM #tmp_salida_menores_TUMBESCEBAFEV1ECU


-- Test ...
SELECT DATEDIFF(YYYY, '2013-03-25', GETDATE())


EXEC sp_help SimPersona

SELECT
   per.uIdPersona,
   per.sNombre,
   per.sPaterno,
   per.sMaterno,
   per.sSexo,
   per.dFechaNacimiento,
   per.sIdPaisNacimiento,
   per.sIdPaisNacionalidad,
   per.sIdDocIdentidad,
   per.sNumDocIdentidad
FROM SimPersona per
WHERE per.bActivo = 1

