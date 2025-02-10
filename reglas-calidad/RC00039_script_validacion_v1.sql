-- RC00039

-- 4. Se establece como regla que los documentos de viaje Pasaporte Electrónico en el registro de salida del control migratorio no deben estar vencidos ni tener una fecha de vencimiento dentro de los próximos 6 meses.
-- =============================================================================================================================================

-- 4.1
-- 90 | Expedición de Pasaporte Electrónico
DROP TABLE IF EXISTS #tmp_pas_e
SELECT t.uIdPersona, pas.* INTO #tmp_pas_e
FROM SIM.dbo.SimPasaporte pas
JOIN SIM.dbo.SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
	AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
	AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
	AND ISNUMERIC(p.sPasNumero) = 1
	AND p.sPasNumero LIKE '1[1-2]%'

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_pas_e_datos
   ON #tmp_pas_e(uIdPersona, sPasNumero, dFechaExpiracion)

-- 4.2
-- 28,412
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Tipo Movimiento] = mm.sTipo,
   [Fecha Movimiento] = mm.dFechaControl,
   [Documento] = mm.sIdDocumento,
   [Número Documento] = mm.sNumeroDoc,
   [Fecha Emisión Pasaporte] = (
                                 SELECT ei.dFechaEmision 
                                 FROM #tmp_pas_e ei
                                 WHERE
                                    ei.uIdPersona = mm.uIdPersona
                                    AND ei.sPasNumero = mm.sNumeroDoc
   ),
   [Fecha Expiración Pasaporte] = (
                                    SELECT ei.dFechaExpiracion 
                                    FROM #tmp_pas_e ei
                                    WHERE
                                       ei.uIdPersona = mm.uIdPersona
                                       AND ei.sPasNumero = mm.sNumeroDoc
   )

FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'PAS'
   AND (ISNUMERIC(mm.sNumeroDoc) = 1 AND LEN(mm.sNumeroDoc) = 9 AND mm.sNumeroDoc LIKE '1[1-2]%')
   AND mm.sTipo = 'S'
   AND EXISTS ( -- Pas-e vencidos o por vencer(6 meses) realizaron control migratorio
                  SELECT 1
                  FROM #tmp_pas_e e
                  WHERE
                     e.uIdPersona = mm.uIdPersona
                     AND e.sPasNumero = mm.sNumeroDoc
                     AND (
                        -- e.dFechaExpiracion <= mm.dFechaControl -- Venció
                        DATEDIFF(DD, mm.dFechaControl, e.dFechaExpiracion) <= 0 -- Venció
                        -- OR DATEDIFF(MM, mm.dFechaControl, e.dFechaExpiracion) <= 6 -- Por vencer
                     )
   )