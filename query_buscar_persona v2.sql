USE SIM
GO

-- Aux

-- 1: Crear tablas pda `tmp's` ...
DROP TABLE IF EXISTS #tmp_pda
SELECT 
   pda.nIdCitaVerifica,
   pda.nIdTipoTramite,
   [Id Persona] = pda.uIdPersona,
   [Fecha Registro] = pda.dFechaRegistro,
   [Tipo Tramite] = tt.sDescripcion,
   [Nom Beneficiario] = pda.sNomBeneficiario,
   [Pri Ape Beneficiario] = pda.sPriApeBeneficiario,
   [Seg Ape Beneficiario] = pda.sSegApeBeneficiario,
   [Sexo] = pda.sSexo,
   [Fec Nac Beneficiario] = pda.dFecNacBeneficiario,
   [Pais Doc Beneficiario] = pda.sIdPaisDocBeneficiario,
   [Ubigeo Beneficiario] = d.sIdUbigeoBeneficiario,
   [Direccion Beneficiario] = d.sDireccionBeneficiario,

   -- Fisionomia
   [Cabello] = f.sCabello,
   [Ojos] = f.sOjos,
   [Estatura] = f.nEstatura,
   [Embarazada] = IIF(f.bEmbarazada = 1, 'SI', 'NO'),
   [Discapacitado] = IIF(f.bDiscapacitado = 1, 'SI', 'NO'),
   [Enfermedad] = IIF(f.bEnfermedad = 1, 'SI', 'NO'),
   [Descripcion Enfermedad] = f.sDescripcionEnfermedad,
   [Peso] = f.nPeso,
   [Tatuaje] = IIF(f.bTatuaje = 1, 'SI', 'NO'),
   [Cicatriz] = IIF(f.bCicatriz = 1, 'SI', 'NO'),

   -- Complementario
   [Centro Trabajo] = c.sCentroTrabajo,
   [Religion] = r.sDescripcion,
   [Telefono] = c.nTelefono,
   [Estudios] = c.sEstudios,
   [Cargo Trabajo] = c.sCargoTrabajo,
   [Salario Trabajo] = c.nSalarioTrabajo,
   [Profesion Ocupacion] = p.sNombre,
   [Tiene Trabajo Peru] = IIF(c.bTieneTrabajoPeru = 1, 'SI', 'NO'),
   [Conduce Vehiculo] = IIF(c.bConduceVehiculo = 1, 'SI', 'NO')

   INTO #tmp_pda
FROM [dbo].[SimSistPersonaDatosAdicionalPDA] pda
JOIN [dbo].[SimDireccionPDA] d ON pda.nIdCitaVerifica = d.nIdCitaVerifica
                                   AND pda.nIdTipoTramite = d.nIdTipoTramite
JOIN [dbo].[SimFisionomiaPDA] f ON pda.nIdCitaVerifica = f.nIdCitaVerifica
                                AND pda.nIdTipoTramite = f.nIdTipoTramite
JOIN [dbo].[SimComplementarioPDA] c ON pda.nIdCitaVerifica = c.nIdCitaVerifica
                                    AND pda.nIdTipoTramite = c.nIdTipoTramite
JOIN SimTipoTramite tt ON pda.nIdTipoTramite = tt.nIdTipoTramite
LEFT JOIN SimProfesionOcupacion p ON c.sIdProfesionOcupacion = p.sIdProfesion
LEFT JOIN SimReligion r ON c.sReligion = r.sIdReligion
-- JOIN SimCiudadPDA c ON pda.nId
WHERE pda.bActivo = 1

SELECT * 
FROM SimReligion r WHERE r.sIdReligion = '09'

SELECT * 
FROM SimProfesionOcupacion p WHERE p.sIdProfesion = '46701'

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_pda_uIdPersona
   ON #tmp_pda([Id Persona]);

CREATE NONCLUSTERED INDEX IX_tmp_pda_datos2
   ON #tmp_pda([Nom Beneficiario], [Pri Ape Beneficiario], [Seg Ape Beneficiario]);

CREATE NONCLUSTERED INDEX IX_tmp_pda_datos
   ON #tmp_pda(sNomBeneficiario, sPriApeBeneficiario, sSegApeBeneficiario, dFecNacBeneficiario, sIdPaisDocBeneficiario);


/*
   → Buscar persona ...
-- =================================================================================================================================================== */

-- DENUNCIANTE: LIZBETH ANA AÑAZCO DE LA CRUZ; DNI 71578446
-- DENUNCIADO: NELSON FREDDY MIGUEL ROMERO; DNI 71543023; 170131e4-9292-4baf-a483-db5b97123f6b

-- 1. SimDocPersona
SELECT 
   dp.*, 
   p.sNombre, 
   p.sPaterno, 
   p.sMaterno, 
   p.dFechaNacimiento, 
   p.sIdPaisNacionalidad,
   p.sIdDocIdentidad,
   p.sNumDocIdentidad,

   -- Aux
   e.sDomicilio
FROM SimDocPersona dp
LEFT JOIN SimPersona p ON dp.uIdPersona = p.uIdPersona
LEFT JOIN SimExtranjero e ON p.uIdPersona = e.uIdPersona
WHERE
   -- sdp.sIdDocumento = 'PAS'
   -- dp.sNumero = '1869'
   -- 1
   /* p.sNombre LIKE '%alb%'
   AND p.sPaterno LIKE 'montilla%'
   AND p.sMaterno LIKE 'rod%' */

   -- 2
   p.sNombre LIKE '%diana%'
   AND p.sPaterno LIKE 'fuenmayor%'
   AND p.sMaterno LIKE 'iri%'

   -- 2. SimPersona
   -- TARO MAEGUSHIKU SHIMOKADO
   /*
   1. ESTANISLAO JULIO PINTO ZAMBRANO
   2. STANLEY JAMES PINTO ZAMBRANO
   3. STANISLAW JULIO PINTO ZAMBRANO
   4. ESTANIS JULIO PINTO ZAMBRANO */


SELECT p.* FROM SimPersona p
WHERE
   -- sIdDocIdentidad = '71543023'
   -- 1
   p.sNombre LIKE 'TARO%'
   AND p.sPaterno LIKE 'MA%'
   AND p.sMaterno LIKE 'SHIMO%'


-- 3. SimMovMigra
SELECT
   [sCalidad] = scm.sDescripcion,
   smm.*
FROM SimMovMigra smm 
LEFT JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
WHERE 
   smm.uIdPersona IN (

      SELECT 
         p.uIdPersona 
         -- p.*
      FROM SimPersona p
      WHERE
         -- DAVID DANIEL AMBROSLO FLORES MONTUFA
         p.sNombre LIKE '%DAVID%'
         AND p.sPaterno = 'AMBROSIO'
         AND p.sMaterno = 'FLORES MONTUFAR'

   )
ORDER BY smm.dFechaControl DESC

-- 4. PDA
/*
   → (ANABELL) (DE OLIVEIRA) (DA CRUZ) ↔ e518079c-3351-4841-adef-65167078b984
   → (ANABELL) (DE) (OLIVEIRA DA CRUZ) ↔
   → (ANABELL) (DE OLIVEIRA) (DA CRUZ) ↔ e518079c-3351-4841-adef-65167078b984
*/
SELECT TOP 10 pda.* FROM #tmp_pda pda 
WHERE 
   -- 1
   pda.[Nom Beneficiario] LIKE '%albe%'
   AND pda.[Pri Ape Beneficiario] LIKE 'montilla%'
   AND pda.[Seg Ape Beneficiario] LIKE 'rod%'

   -- 2
   /* pda.[Nom Beneficiario] LIKE '%and%'
   AND pda.[Pri Ape Beneficiario] LIKE 'fuen%'
   AND pda.[Seg Ape Beneficiario] LIKE 'iri%' */

   /* OR
   -- 2
   (pda.sNomBeneficiario LIKE 'ANABELL'
   AND pda.sPriApeBeneficiario LIKE 'DE OLIVEIRA'
   AND pda.sSegApeBeneficiario LIKE 'DA CRUZ') */

   /* pda.[Id Persona] IN (
      '51de7f95-f411-4507-85e5-6f185b8c36b5',
      '2072ba3f-3340-4b19-8ad1-cc2df9869e98',
      '83599bf3-e722-4171-a4c5-0d58e1afcb3c'
   ) */


-- 4.1. Nucleo familiar
EXEC sp_help SimNucleoFamiliarPDA
SELECT
   [Parentesco] = p.sDescripcion,
   [Documento] = f.sIdDocumento,
   [Numero Documento] = f.sNumeroDocumento,
   [Nombres] = f.sNombres,
   [Paterno] = f.sPaterno,
   [Materno] = f.sMaterno,
   [Sexo] = f.sSexo,
   [Fecha Nacimiento] = f.dFechaNacimiento,
   [Esta EnPeru] = IIF(f.bEstaEnPeru = 1, 'SI', 'NO'),
   [PlaneaVenir] = IIF(f.bPlaneaVenir = 1, 'SI', 'NO'),
   [FechaLlegada] = f.dFechaLlegada,
   [TienePasaporte] = IIF(f.bTienePasaporte = 1, 'SI', 'NO'),
   [PasaporteVigente] = IIF(f.bPasaporteVigente = 1, 'SI', 'NO'),
   [Pais Documento] = f.sIdPaisDocumento

FROM SimNucleoFamiliarPDA f
JOIN #tmp_pda pda ON pda.nIdCitaVerifica = f.nIdCitaVerifica
                  AND pda.nIdTipoTramite = f.nIdTipoTramite
LEFT JOIN SimTipoParentesco p ON f.sIdParentesco = p.nIdParentesco
WHERE
   pda.[Id Persona] IN (
      '51de7f95-f411-4507-85e5-6f185b8c36b5',
      '2072ba3f-3340-4b19-8ad1-cc2df9869e98',
      '83599bf3-e722-4171-a4c5-0d58e1afcb3c'
   )


-- 5. SimImagenExtranjero: SIM»dbo»SimImagenExtranjero
SELECT i.*
FROM (
   SELECT 
      -- [sPath] = CONCAT('D:\img\', REPLACE(p.sNombre, ' ', ''), RTRIM(CONCAT(p.sPaterno, p.sMaterno)), '\', COALESCE(ie.sIdDedo, ie.sTipo), '.png'),
      [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, p.sMaterno)), '(', COALESCE(d.sNombre, ie.sTipo), ').png'),
      [xImagen] = CAST(ie.xImagen AS VARBINARY(MAX))
   FROM SIM.dbo.[SimImagenExtranjero] ie
   LEFT JOIN SimDedo d ON ie.sIdDedo = d.sIdDedo
   RIGHT JOIN SimPersona p ON ie.uIdPersona = p.uIdPersona
   WHERE
      ie.bUltimo = 1
      AND p.uIdPersona = 'a705a6e3-864b-42ae-a1b2-94d0279d91e6'
) i
ORDER BY
   LEN(i.sPath) DESC



SELECT * 
FROM SimDocPersona dp
WHERE
   dp.bActivo = 1
   AND dp.sIdDocumento = 'PAS'
   AND dp.uIdPersona IN (
      '51de7f95-f411-4507-85e5-6f185b8c36b5',
      '2072ba3f-3340-4b19-8ad1-cc2df9869e98',
      '83599bf3-e722-4171-a4c5-0d58e1afcb3'
   )