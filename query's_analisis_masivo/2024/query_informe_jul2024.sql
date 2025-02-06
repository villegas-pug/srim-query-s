USE SIM
GO

--> ░ 1. Se define como regla, que el control migratorio por e-gates solo debe ser utilizado por ciudadanos peruanos que cuenten con documentos de viaje PAS electrónico. ...
-- ========================================================================================================================================================================

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
   [Dependencia] = d.sNombre,
   [Módulo] = mm.sIdModuloDigita */
   -- mm.sIdMovMigratorio
   COUNT(1)

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
-- JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdModuloDigita = 'EGATES' -- EGATES | EGATES
   AND mm.sIdDocumento != 'PAS' -- Documento viaje
   AND mm.sNumeroDoc NOT LIKE '1[1-2]%' -- Documento viaje
   -- AND pe.sIdPaisNacionalidad = 'PER' -- Peruano
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'


-- ========================================================================================================================================================================


--> ░ 2. Se define como regla, que los trámites de `Cambio de Clase de Visa` Aprobados, deben tener sus etapas `Finalizadas` ...
-- ========================================================================================================================================================================

SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Fecha Trámite] = t.dFechaHora,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado] = ti.sEstadoActual

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.nIdTipoTramite = 55 -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
   AND ti.sEstadoActual = 'A'
   AND EXISTS ( -- Registro de etapas únicas y en estado `I` ...

         SELECT 1
         FROM (

            SELECT
               e2.*,
               [nTotalReg(Fin)] = COUNT(1) OVER (PARTITION BY e2.sNumeroTramite) -- Total registros en sub-consulta final
            FROM (

               SELECT 
                  et.*,
                  [nTotalReg(Ini)] = COUNT(1) OVER (PARTITION BY et.sNumeroTramite), -- Total registros en sub-consulta inicial
                  [nTotalEtapas(Ini)] = COUNT(1) OVER (PARTITION BY et.nIdEtapa)
               FROM SimEtapaTramiteInm et
               WHERE
                  et.sNumeroTramite = t.sNumeroTramite 
                  AND et.bActivo = 1

            ) e2
            WHERE
               e2.[nTotalEtapas(Ini)] = 1 -- etapas únicas

         ) e3
         WHERE
            e3.[nTotalReg(Ini)] = e3.[nTotalReg(Fin)]
            AND e3.sEstado = 'I'

   )

-- ========================================================================================================================================================================


--> ░ 3. Se define como regla, que las `Solicitud de Cambio Calidad Migratoria` Aprobadas, deben registrar una fecha de vencimiento ...
-- ========================================================================================================================================================================

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Fecha Trámite] = t.dFechaHora,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado] = ti.sEstadoActual,
   [dFechaAprobacion] = v.dFechaAprobacion,
   [dFechaVencimiento] = v.dFechaVencimiento

FROM SimVisa v
JOIN SimTramite t ON v.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite = 55 -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
   AND (v.dFechaVencimiento IS NULL OR v.dFechaVencimiento = '1900-01-01 00:00:00.000' OR v.dFechaVencimiento = '') -- Fecha nula, fecha invalida o vacia ...
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'


-- ========================================================================================================================================================================


--> ░ 4. Se define como regla, que los Carnet de Extranjería, deben tener una vigencia de 3 años en el caso de menores de edad. ...
-- ========================================================================================================================================================================

SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
	[Número Carnet] = ce.sNumeroCarnet,
	[Fecha Emisión] = ce.dFechaEmision,
	[Fecha Caducidad] = ce.dFechaCaducidad,
	[Edad Emisión Carnet] = DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision)

FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona pe ON ce.uIdPersona = pe.uIdPersona
WHERE 
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND ce.bAnulado = 0
   AND ce.sTipo = 'R'
   AND (ce.dFechaEmision IS NOT NULL OR ce.dFechaEmision != '1900-01-01 00:00:00.000')
   AND (ce.dFechaCaducidad IS NOT NULL OR ce.dFechaCaducidad != '1900-01-01 00:00:00.000')
   AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) < 18 -- Menores de edad
   AND DATEDIFF(YYYY, ce.dFechaEmision, ce.dFechaCaducidad) > 3 -- Vigencia > a 3 años
   
-- ========================================================================================================================================================================


--	5. Se define como regla, que la población extranjera menor de edad, no debe registrar una calidad migratoria de: `ARTISTA, TRIPULANTE, NEGOCIOS y TRABAJADOR`.
-- ============================================================================================================================================================

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Fecha Control] = mm.dFechaControl,
   [Edad Control] = DATEDIFF(YYYY, pe.dFechaNacimiento, mm.dFechaControl),
   [Tipo Control] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
   [Calidad Migratoria Control] = cm.sDescripcion
   
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND DATEDIFF(YYYY, pe.dFechaNacimiento, mm.dFechaControl) < 18 -- Menores
   AND mm.nIdCalidad IN ( -- 'OFICIAL', 'ARTISTA', 'TRIPULANTE', 'NEGOCIOS', 'TRABAJADOR', 'DIPLOMATICA'
         '58', '191', '212', '245', '246', '247', '266', '267', '292', '300', '316'
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- Test
SELECT DATEDIFF(YYYY, '2023-01-01 00:00:00.000', GETDATE())

SELECT * FROM SimCalidadMigratoria cm
WHERE 
   cm.sDescripcion IN (
                        'ARTISTA',
                        'TRIPULANTE',
                        'NEGOCIOS',
                        'TRABAJADOR'
   ) 
AND  cm.bActivo = 1
--============================================================================================================================================================
