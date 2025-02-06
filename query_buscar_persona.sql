USE SIM
GO

-- jose jesus mavares rojano | CI 18793768 | VEN

-- 1. SimDocPersona
SELECT dp.* FROM SimDocPersona dp
WHERE
   -- dp.uIdPersona = '8fe2f4ee-70b2-4da3-a919-21260f33f0e1'
   dp.sIdDocumento = 'CIP'
   AND dp.sNumero LIKE '%1675698%'


-- 2. SimPersona
-- ARANGOITIA HORNA BELGICA SOLANGE
SELECT
   pe.sIdPaisNacionalidad, 
   pe.* 
FROM SimPersona pe
WHERE 
   -- 1
   pe.sNombre LIKE '%SOL%'
   -- pe.sNombre LIKE '%BELGICA SOLANGE%'
   -- pe.sNombre LIKE '%SOL%'
   AND pe.sPaterno LIKE '%ARAN%'
   -- AND pe.sMaterno LIKE '%HOR%'
   -- AND pe.sIdPaisNacionalidad = 'RDO'
   -- AND pe.uIdPersona = 'b7a1307e-e52f-49a4-aa1c-03dd1df45508'
   AND CAST(pe.dFechaNacimiento AS DATE) = '1986-01-28'


SELECT * 
FROM SimMovMigra mm
WHERE 
   mm.uIdPersona IN (
      'b7a1307e-e52f-49a4-aa1c-03dd1df45508',
      '7920b950-7031-48ad-a791-9602b88ecf3f'
   )
ORDER BY mm.dFechaControl DESC

-- Documentos
SELECT * 
FROM SimDocPersona dp
WHERE 
   -- dp.sIdDocumento = 'PAS'
   dp.sNumero IN (
      '124658395',
      '44846265',
      'D16004684'
   )
   /* dp.uIdPersona IN (
               'b7a1307e-e52f-49a4-aa1c-03dd1df45508',
               '7920b950-7031-48ad-a791-9602b88ecf3f'
   ) */

SELECT * 
FROM SimMovMigra mm
WHERE
   mm.sNumeroDoc IN (
      '124658395',
      '44846265',
      'D16004684'
   )


-- 3 Regularización
SELECT 

   [sTipoTramite] = tt.sDescripcion,
   a.dFechaRegistro,
   a.sNomBeneficiario,
   a.sPriApeBeneficiario,
   a.sSegApeBeneficiario,
   a.dFecNacBeneficiario,
   a.sIdPaisDocBeneficiario,
   d.sIdUbigeoBeneficiario,
   d.sDireccionBeneficiario
   -- a.dFechaHoraAud

FROM [dbo].[SimSistPersonaDatosAdicionalPDA] a
JOIN [dbo].[SimDireccionPDA] d ON a.nIdCitaVerifica = d.nIdCitaVerifica
                                      AND a.nIdTipoTramite = d.nIdTipoTramite
JOIN SimTipoTramite tt ON a.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   -- a.sNomBeneficiario LIKE '%ana maria%'
   -- AND a.sPriApeBeneficiario LIKE 'paredes'
   -- AND a.sSegApeBeneficiario LIKE 'roj%'
   a.uIdPersona IN (
      'e485c840-0540-456b-a726-d362f30c9214',
      'da95744e-980f-4ed3-85f5-052f3567bdbe',
      '34bbcbb3-0b07-4591-a248-7d3c003bc419'
   )
   


--- SimMovMigra
SELECT 

   -- Mov
   [sDocViaje] = mm.sIdDocumento,
   [sNumDocViaje] = mm.sNumeroDoc,
   mm.dFechaControl,
   [sTipoMovimiento] = mm.sTipo,
   mm.sIdPaisMov,
   mm.sObservaciones,

   -- Per
   pe.sNombre,
   pe.sPaterno,
   pe.sMaterno,
   pe.dFechaNacimiento,
   pe.sSexo,
   pe.sIdPaisNacionalidad


FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.uIdPersona = '8fe2f4ee-70b2-4da3-a919-21260f33f0e1'


/*

   » Sr. Fernando, buenos dias, necesitamos informacion respecto al ciudadano CAUCOTT QUIROGA Vladimir Patricio, 
     quien ingreso a territorio peruano el 12ENE25. Se desea saber:

   1. Residencia donde va ha permanecer.
   2. Calidad migratoria.
   3. Cualquier otra informacion que haya consignado en Migraciones..


   ░ 27Ene2025:

      1. NESTOR DANIEL BLANCO FERNANDEZ | CIP N° 15994265 | e485c840-0540-456b-a726-d362f30c9214
      2. MODESTO JOSE CLEMANT RAMOS | CIP N° 20201228 | da95744e-980f-4ed3-85f5-052f3567bdbe
      3. EMILHY ELVIRA CAMACHO MAZZO | CIP V29525185 | 34bbcbb3-0b07-4591-a248-7d3c003bc419
*/

-- 1
SELECT *
FROM SimPersona pe
WHERE
   pe.sNombre LIKE 'EMILHY ELVIRA'
   AND pe.sPaterno LIKE 'CAMACHO'
   AND pe.sMaterno LIKE 'MAZZO'

-- 2
SELECT
   
   [Id Persona] = pe.uIdPersona,
   [Nombre] = pe.sNombre,
   [Paterno] = pe.sPaterno,
   [Materno] = pe.sMaterno,
   [Sexo] = pe.sSexo,

   [Documentos] = (
                     REPLACE(
                        (
                           REPLACE(
                              (
                                 SELECT dp.sIdDocumento, dp.sNumero 
                                 FROM SimDocPersona dp
                                 WHERE
                                    -- dp.uIdPersona = pe.uIdPersona
                                    dp.uIdPersona = pe.uIdPersona
                                 FOR XML PATH('')
                              ),
                              '</sIdDocumento><sNumero>',
                              ': '
                           )
                        ),
                        '</sNumero><sIdDocumento>',
                        '; '
                     )
                     
   ),

   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Pais Nacionalidad] = pe.sIdPaisNacionalidad,
   [Calidad Migratoria] = (
                              SELECT cm.sDescripcion
                              FROM SimCalidadMigratoria cm
                              WHERE 
                                 cm.nIdCalidad = pe.nIdCalidad
   ),
   [Calidad Ult MovMigra] = (
                              SELECT TOP 1 cm.sDescripcion 
                              FROM SimMovMigra mm
                              JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
                              WHERE
                                 mm.uIdPersona = pe.uIdPersona
                                 AND mm.bAnulado = 0
                                 AND mm.bTemporal = 0
                              ORDER BY
                                 mm.dFechaControl DESC
   ),

   -- Tramites CPP ...
   [Trámites] = (

                     SELECT
                        [NumeroTramite] = st.sNumeroTramite,
                        [EstadoActual] = sti.sEstadoActual,
                        [TipoTramite] = stt.sDescripcion
                     FROM SimTramite st
                     JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
                     JOIN SimTipotramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
                     WHERE
                        st.bCancelado = 0
                        AND st.uIdPersona = pe.uIdPersona
                        -- AND st.nIdTipoTramite IN (113, 126) -- PERMISO TEMPORAL DE PERMANENCIA - RS109 | 113 - CPP
                     FOR XML PATH('')

                  ),

   -- Ultimo MovMigra ...
   [Fecha Ultimo MovMigra] = (
                                 SELECT TOP 1 smm.dFechaControl FROM SimMovMigra smm
                                 WHERE
                                    smm.uIdPersona = pe.uIdPersona
                                    AND smm.bAnulado = 0
                                    AND smm.bTemporal = 0
                                 ORDER BY
                                    smm.dFechaControl DESC
							 			),
	[Tipo Ultimo MovMigra] = COALESCE(
										(
											SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
											WHERE
												smm.uIdPersona = pe.uIdPersona
												AND smm.bAnulado = 0
												AND smm.bTemporal = 0
											ORDER BY
												smm.dFechaControl DESC
										),
										'Sin Control Migratorio'
									),
   [Provincia / Distrito] = su.sNombre,
   [Fecha Registro] = COALESCE(pe.dFechaHoraAud , a.dFechaRegistro),
   [Direccion Domiciliaria] = COALESCE(e.sDomicilio, d.sDireccionBeneficiario),
   [Teléfono] = e.sTelefono,
   [Correo] = e.sEmail,

   -- Datos familiares ...
   [Datos Familiares] = COALESCE(
                           (
                              SELECT 
                                 [Parentesco] = stp.sDescripcion,
                                 [Nombre] = sf.sNombre,
                                 [Paterno] = sf.sPaterno,
                                 [Materno] = sf.sMaterno,
                                 [Sexo] = sf.sSexo,
                                 [FechaNacimiento] = sf.dFechaNacimiento,
                                 [PaisNacionalidad] = sf.sIdPaisNacionalidad
                              FROM SimFamiliarExt sfe
                              JOIN SimFamiliar sf ON sfe.nIdFamiliar = sf.nIdFamiliar
                              LEFT JOIN SimTipoParentesco stp ON sfe.nIdParentesco = stp.nIdParentesco
                              WHERE
                                 sfe.uIdPersona = pe.uIdPersona
                              FOR XML PATH('')

                           ), (

                              SELECT 
                                 [Parentesco] = df.sDescripcion,
                                 [Nombre] = df.sNombres,
                                 [Paterno] = df.sPaterno,
                                 [Materno] = df.sMaterno,
                                 [Sexo] = df.sSexo,
                                 [FechaNacimiento] = df.dFechaNacimiento,
                                 [PaisDocumento] = df.sIdPaisDocumento 
                              FROM (

                                 SELECT 
                                    snf.*,
                                    stp.sDescripcion,
                                    [nFila_uId] = ROW_NUMBER() OVER (PARTITION BY snf.sNombres, snf.sPaterno, snf.sMaterno 
                                                                     ORDER BY snf.sNombres)
                                 FROM [dbo].[SimSistPersonaDatosAdicionalPDA] spda
                                 JOIN SimNucleoFamiliarPDA snf ON spda.nIdCitaVerifica = snf.nIdCitaVerifica
                                 JOIN SimTipoParentesco stp ON snf.sIdParentesco = stp.nIdParentesco
                                 WHERE
                                    snf.bActivo = 1
                                    AND spda.uIdPersona = pe.uIdPersona

                              ) df
                              WHERE
                                 df.nFila_uId = 1
                              FOR XML PATH('')

                           )

                        ),
   [Observaciones MovMigra] = (
                                 SELECT TOP 1 mm.sObservaciones 
                                 FROM SimMovMigra mm
                                 WHERE
                                    mm.uIdPersona = pe.uIdPersona
                                    AND mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                 ORDER BY
                                    mm.dFechaControl DESC
   ),
   [Via Transporte] = (
                           SELECT TOP 1 mm.sIdViaTransporte 
                           FROM SimMovMigra mm
                           WHERE
                              mm.uIdPersona = pe.uIdPersona
                              AND mm.bAnulado = 0
                              AND mm.bTemporal = 0
                           ORDER BY
                              mm.dFechaControl DESC
   ),
   [Aerolinea] = (
                           SELECT TOP 1 et.sNombreRazon
                           FROM SimMovMigra mm
                           JOIN SimEmpTransporte et ON mm.nIdTransportista = et.nIdTransportista
                           WHERE
                              mm.uIdPersona = pe.uIdPersona
                              AND mm.bAnulado = 0
                              AND mm.bTemporal = 0
                           ORDER BY
                              mm.dFechaControl DESC
   )

FROM SimPersona pe
LEFT JOIN SimExtranjero e ON pe.uIdPersona = e.uIdPersona
LEFT JOIN SimUbigeo su ON e.sIdUbigeoDomicilio = su.sIdUbigeo
LEFT JOIN [dbo].[SimSistPersonaDatosAdicionalPDA] a ON a.uIdPersona = pe.uIdPersona
LEFT JOIN [dbo].[SimDireccionPDA] d ON a.nIdCitaVerifica = d.nIdCitaVerifica
                                    AND a.nIdTipoTramite = d.nIdTipoTramite
-- JOIN SimTipoTramite tt ON a.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   pe.uIdPersona IN (
      'e485c840-0540-456b-a726-d362f30c9214',
      'da95744e-980f-4ed3-85f5-052f3567bdbe',
      '34bbcbb3-0b07-4591-a248-7d3c003bc419'
   )


EXEC sp_help SImMovMIgra


/*


1. Duplicados de personas creadas en control migratorio.
2. Datos incompletos registros en SimPersona desde el control migratorio.


*/