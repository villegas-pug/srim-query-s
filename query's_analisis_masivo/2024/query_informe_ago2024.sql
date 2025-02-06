-- 1. Se define como regla, que los datos personales de peruanos registrados en [SimPersona], deben ser iguales a los datos personales registrados en el pasaporte.
-- =====================================================================================================================================================================

-- 1.1 `tmp` Pasaportes electrónicos:
DROP TABLE IF EXISTS #tmp_pas_e
SELECT 
   t.uIdPersona,
   [dFechaNacimiento] = CAST(pas.dFechaNacimiento AS DATE),
   pas.sPasNumero,
   pas.sIdDependencia

   INTO #tmp_pas_e
FROM SimPasaporte pas
JOIN SimTramite t ON pas.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.nIdTipoTramite = 90 -- 90 | Expedición de Pasaporte Electrónico

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_pas_e
   ON #tmp_pas_e(uIdPersona, dFechaNacimiento)

-- 1.2 `tmp` Peruanos en `SimPersona`:
DROP TABLE IF EXISTS #tmp_pe
SELECT 
   pe.uIdPersona,
   pe.sNombre,
   pe.sPaterno,
   pe.sMaterno,
   pe.sSexo,
   [dFechaNacimiento] = CAST(pe.dFechaNacimiento AS DATE),
   pe.sIdPaisNacionalidad

   INTO #tmp_pe
FROM SimPersona pe
WHERE
   pe.bActivo = 1
   AND pe.sIdPaisNacionalidad = 'PER'

-- Index
CREATE NONCLUSTERED INDEX ux_tmp_pe 
   ON #tmp_pe(uIdPersona, dFechaNacimiento)

-- 1.3 Final
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Persona Pasaporte] = e.uIdPersona,
   [Número Pasaporte] = e.sPasNumero,
   [Fecha Nacimiento Pasaporte] = e.dFechaNacimiento,
   [Id Persona] = pe.uIdPersona,
   [Fecha Nacimiento Persona] = pe.dFechaNacimiento

FROM #tmp_pas_e e
JOIN #tmp_pe pe ON e.uIdPersona = pe.uIdPersona
WHERE
   e.dFechaNacimiento != pe.dFechaNacimiento

-- 1.4 Para analisis:
SELECT
   d.sSigla
FROM #tmp_pas_e e
JOIN #tmp_pe pe ON e.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON e.sIdDependencia = d.sIdDependencia
WHERE
   e.dFechaNacimiento != pe.dFechaNacimiento

-- =========================================================================================================================================================

-- 2. Se define como regla, que la fecha de nacimiento de [SimPersona], debe ser menor a la fecha actual.
-- =========================================================================================================================================================

-- 2.1
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Login Operador Digita] = u.sLogin,
   [Nombre Operador Digita] = u.sNombre,
   [Id Módulo Digita] = m.sIdModulo,
   [Nombre Módulo Digita] = m.sNombre

FROM SimPersona pe
JOIN SimSesion s ON pe.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
JOIN SimModulo m ON s.sIdModulo = m.sIdModulo
WHERE 
   pe.bActivo = 1
   AND pe.dFechaNacimiento >= GETDATE()

-- =========================================================================================================================================================


-- 3. Se define como regla, las calidad solicitada de `TRABAJADOR`, el trámite debe registrar una empresa.
-- =========================================================================================================================================================

-- 3.1
SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Tramite] = tt.sDescripcion,
   [Estado Trámite] = ti.sEstadoActual,
   [Calidad Migratoria] = cm.sDescripcion,
   [Empresa] = ti.nIdOrganizacion

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND (ti.nIdOrganizacion IS NULL OR ti.nIdOrganizacion = '' OR ti.nIdOrganizacion = 0)
   AND ccm.nIdCalSolicitada IN (
      SELECT cm.nIdCalidad
      FROM SimCalidadMigratoria cm
      WHERE 
         cm.bActivo = 1
         AND cm.sDescripcion LIKE '%trab%'
   )

-- 3.2
SELECT
   d.sSigla
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND (ti.nIdOrganizacion IS NULL OR ti.nIdOrganizacion = '' OR ti.nIdOrganizacion = 0)
   AND ccm.nIdCalSolicitada IN (
      SELECT cm.nIdCalidad
      FROM SimCalidadMigratoria cm
      WHERE 
         cm.bActivo = 1
         AND cm.sDescripcion LIKE '%trab%'
   )
-- =============================================================================================================================================

-- 4. Se define como regla, que los documentos de viaje `PAS` en el registro de salida del control migratorio, deben estar vigentes.
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

   /* [Id Persona] = pe.uIdPersona,
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
   ) */
   -- mm.sIdMovMigratorio
   COUNT(1)

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
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'


-- 4.3: Analisis
SELECT
   mm.sIdModuloDigita
FROM SimMovMigra mm
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'PAS'
   AND ISNUMERIC(mm.sNumeroDoc) = 1
   AND LEN(mm.sNumeroDoc) = 9
   AND mm.sNumeroDoc LIKE '1[1-2]%'
   AND mm.sTipo = 'S'
   AND EXISTS ( -- Pas-e vencidos realizaron control migratorio
                  SELECT 1
                  FROM #tmp_pas_e e
                  WHERE
                     e.uIdPersona = mm.uIdPersona
                     AND e.sPasNumero = mm.sNumeroDoc
                     AND e.dFechaExpiracion <= mm.dFechaControl
   )
   
-- =============================================================================================================================================

-- 5. Se define como regla, que únicamente paises que forman parte de comunidad Andina, pueden registrar un documento de viaje `TAM`.
-- =============================================================================================================================================
-- 5.1
SELECT

   /* [Id Persona] = pe.uIdPersona,
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
   [Dependencia] = d.sNombre */
   -- mm.sIdMovMigratorio
   COUNT(1)
FROM SIM.dbo.SimMovMigra mm
/* JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia */
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDocumento = 'TAM' -- TAM | TARJETA ANDINA | 1567
   AND mm.sIdPaisNacionalidad NOT IN ('PER', 'ECU', 'CHL', 'BOL', 'ARN', 'ESP', 'BRA', 'COL')
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
-- =============================================================================================================================================


USE SIM
GO

;WITH cteName
AS  
(  
   SELECT *
   FROM SImPais
)
SELECT * FROM cteName