-- RC00053

-- 2. Se define como regla, que cada persona debe registrar únicamente una nacionalidad en sus movimientos migratorios.
-- =====================================================================================================================================================================
-- 2.1
;WITH cte_mm_dif_nac
AS  (
   SELECT f.*
   FROM (
      SELECT

         mm.uIdPersona,
         mm.sIdDocumento,
         mm.sNumeroDoc,
         mm.sNombres,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC),
         [nContarMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona),
         [nContarNacionalidadMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, mm.sIdPaisNacionalidad)

      FROM SimMovMigra mm
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         -- AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
         AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
   ) f
   WHERE
      f.[#] = 1
      AND f.[nContarNacionalidadMM] < f.[nContarMM]

) 
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Cantidad Nacionalidades] = (
                                 SELECT COUNT(DISTINCT(mm.sIdPaisNacionalidad))
                                 FROM SimMovMigra mm
                                 WHERE mm.uIdPersona = d.uIdPersona
   ),
   [Nacionalidades] = (
                        SELECT DISTINCT mm.sIdPaisNacionalidad
                        FROM SimMovMigra mm
                        WHERE mm.uIdPersona = d.uIdPersona
                        FOR XML PATH('')
   )
FROM cte_mm_dif_nac d
JOIN SimPersona pe ON d.uIdPersona = pe.uIdPersona


-- =====================================================================================================================================================================