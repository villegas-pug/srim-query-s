
-- RC00014
-- 4. Ciudadanos con nacionalidad `PERUANA` realizaron control migratorio con mas de 1 documento (DNI) ...
-- ======================================================================================================================================================================== */

SELECT p2.* 
FROM (

   SELECT

      [Id Persona] = p.uIdPersona,
      [Nombres] = p.sNombre,
      [Apellido 1] = p.sPaterno,
      [Apellido 2] = p.sMaterno,
      [Sexo] = p.sSexo,
      [Fecha de Nacimiento] = p.dFechaNacimiento,
      [Nacionalidad ] = p.sIdPaisNacionalidad,

      -- Aux
      dp.sIdDocumento,
      dp.sNumero,
      [nCant(Id, DNI, NumDoc)] = COUNT(1) OVER (
                                       PARTITION BY 
                                          dp.uIdPersona,
                                          dp.sIdDocumento,
                                          dp.sNumero
                                    ),
      [nCant(Id, DNI)] = COUNT(1) OVER (
                                       PARTITION BY 
                                          dp.uIdPersona,
                                          dp.sIdDocumento
                                    )
   FROM SImDocPersona dp
   JOIN SimPersona p ON dp.uIdPersona = p.uIdPersona
   WHERE 
      (dp.bActivo = 1 AND p.bActivo = 1)
      AND p.sIdPaisNacionalidad = 'PER'
      AND dp.sIdDocumento = 'DNI'
      AND EXISTS (
                     SELECT TOP 1 1 
                     FROM SimMovMigra mm
                     WHERE
                        mm.bAnulado = 0
                        AND mm.bTemporal = 0
                        AND (mm.uIdPersona = dp.uIdPersona AND mm.sIdDocumento = dp.sIdDocumento AND mm.sNumeroDoc = dp.sNumero)
      )

) p2
WHERE
   p2.[nCant(Id, DNI, NumDoc)] = 1 AND p2.[nCant(Id, DNI)] >= 2

-- ======================================================================================================================================================================== */