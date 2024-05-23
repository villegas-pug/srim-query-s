USE SIM
GO

/*»
   → ...
======================================================================================================================================================*/

-- 1: ...

-- 1.1: `tmp` ...
DROP TABLE IF EXISTS #tmp_condenados
SELECT 
   TOP 0
   [nId] = 0,
   sper.sIdDocIdentidad,
   sper.sNumDocIdentidad
   INTO #tmp_condenados
FROM SimPersona sper

-- 1.2: ...
-- INSERT INTO #tmp_condenados VALUES(;
-- SELECT COUNT(1) FROM #tmp_condenados


-- 1.3: Remove blank spacing ...
UPDATE #tmp_condenados
   SET 
      sIdDocIdentidad = REPLACE(sIdDocIdentidad, ' ', ''),
      sNumDocIdentidad = REPLACE(sNumDocIdentidad, ' ', '')

-- 2: Add column `uIdPersona` ...
DROP TABLE IF EXISTS #tmp_condenados_uIdPersona
SELECT 
   c.*,
   [uIdPersona] = (

                     SELECT 
                        TOP 1
                        sdp.uIdPersona
                     FROM SimDocPersona sdp
                     JOIN SimPersona sper ON sdp.uIdPersona = sper.uIdPersona
                     WHERE
                        (sdp.uIdPersona != '00000000-0000-0000-0000-000000000000' AND sdp.uIdPersona IS NOT NULL)
                        AND sdp.sIdDocumento = c.sIdDocIdentidad
                        AND sdp.sNumero = c.sNumDocIdentidad
                        AND sper.sIdPaisNacionalidad != 'PER'

                  )
   INTO #tmp_condenados_uIdPersona
FROM #tmp_condenados c

-- Test ...
SELECT 
   -- c.*,
   sper.sIdPaisNacionalidad,
   [nTotal] = COUNT(1)
   -- sper.*
FROM #tmp_condenados_uIdPersona c 
JOIN SimPersona sper ON c.uIdPersona = sper.uIdPersona
/*WHERE
   sper.sIdPaisNacionalidad = 'PER'*/
GROUP BY
   sper.sIdPaisNacionalidad
ORDER BY [nTotal] DESC

-- 3: Add column's ...
DROP TABLE IF EXISTS #tmp_condenados_uIdPersona_adicional
SELECT 
   c.*,

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
                        AND st.uIdPersona = c.uIdPersona
                        AND st.nIdTipoTramite IN (113, 126) -- PERMISO TEMPORAL DE PERMANENCIA - RS109 | 113 - CPP
                     FOR XML PATH('')

                  ),

   -- Ultimo MovMigra ...
   [Fecha Ultimo MovMigra] = (
                                 SELECT TOP 1 smm.dFechaControl FROM SimMovMigra smm
                                 WHERE
                                    smm.uIdPersona = c.uIdPersona
                                    AND smm.bAnulado = 0
                                    AND smm.bTemporal = 0
                                 ORDER BY
                                    smm.dFechaControl DESC
							 			),
	[Tipo Ultimo MovMigra] = COALESCE(
										(
											SELECT TOP 1 smm.sTipo FROM SimMovMigra smm
											WHERE
												smm.uIdPersona = c.uIdPersona
												AND smm.bAnulado = 0
												AND smm.bTemporal = 0
											ORDER BY
												smm.dFechaControl DESC
										),
										'Sin Control Migratorio'
									),
   [Provincia / Distrito] = su.sNombre,
   [Direccion Domiciliaria] = se.sDomicilio,
   [Teléfono] = se.sTelefono,
   [Correo] = se.sEmail,

   -- 124 | ACOGIMIENTO DE AMNISTIA
   [¿Acogimiento de amnistia?] = (
                                    IIF(
                                       EXISTS (
                                          SELECT TOP 1 1 FROM SimTramite st
                                          WHERE
                                             st.bCancelado = 0
                                             AND st.nIdTipoTramite = 124
                                             AND st.uIdPersona = c.uIdPersona
                                          ORDER BY
                                             st.dFechaHora DESC
                                       ),
                                       'Si',
                                       'No'
                                    )

                                 ),
   [Fecha Acogimiento de amnistia] = (
                                       SELECT TOP 1 st.dFechaHora FROM SimTramite st
                                       WHERE
                                          st.bCancelado = 0
                                          AND st.nIdTipoTramite = 124
                                          AND st.uIdPersona = c.uIdPersona
                                       ORDER BY
                                          st.dFechaHora DESC
                                    ),

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
                                 sfe.uIdPersona = c.uIdPersona
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
                                    AND spda.uIdPersona = c.uIdPersona

                              ) df
                              WHERE
                                 df.nFila_uId = 1
                              FOR XML PATH('')

                           )

                        )
   INTO #tmp_condenados_uIdPersona_adicional
FROM #tmp_condenados_uIdPersona c
LEFT JOIN SimExtranjero se ON c.uIdPersona = se.uIdPersona
LEFT JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo


-- Test ...
SELECT * FROM #tmp_condenados_uIdPersona_adicional c
SELECT COUNT(1) FROM #tmp_condenados_uIdPersona_adicional c
WHERE
   c.[Tipo Ultimo MovMigra] IN ('E', 'S')

-- Tipo Trámite ...
-- 124 | ACOGIMIENTO DE AMNISTIA
SELECT
   stt.* 
FROM SimTipoTramite stt
WHERE
   stt.sDescripcion LIKE '%amn%'

-- 2
SELECT
   sti.*
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
WHERE
   st.nIdTipoTramite = 124
-- ======================================================================================================================================================*/

-- Test ...
SELECT 
   TOP 10
   snf.uIdPersona,
   [nContar] = COUNT(1)
FROM SimNucleoFamiliarPDA snf
WHERE
   snf.uIdPersona != '00000000-0000-0000-0000-000000000000' AND snf.uIdPersona IS NOT NULL
GROUP BY
   snf.uIdPersona

-- d437a7d9-3ed6-4a9f-b8c7-64e87781a114   
SELECT 
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   snf.* 
FROM SimNucleoFamiliarPDA snf
JOIN SimPersona sper ON snf.uIdPersona = sper.uIdPersona
WHERE
   snf.uIdPersona = '92a0fc21-a95e-4275-b3dc-a8a7ee130965'

-- Buscar datos familiares por `uId` ...
-- 1
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
   sfe.uIdPersona = '92a0fc21-a95e-4275-b3dc-a8a7ee130965'

-- 2
SELECT 
   [sParentesco] = stp.sDescripcion,
   spda.sNomBeneficiario,
   spda.sPriApeBeneficiario,
   spda.sSegApeBeneficiario,
   snf.*
FROM [dbo].[SimSistPersonaDatosAdicionalPDA] spda
JOIN SimNucleoFamiliarPDA snf ON spda.nIdCitaVerifica = snf.nIdCitaVerifica
JOIN SimTipoParentesco stp ON snf.sIdParentesco = stp.nIdParentesco
WHERE
   snf.bActivo = 1
   -- AND spda.uIdPersona = '38ccd3cf-43cd-4ebd-8611-8936f5abf366'
   AND spda.uIdPersona = '92a0fc21-a95e-4275-b3dc-a8a7ee130965'
   

-- 2
EXEC sp_help SimNucleoFamiliarPDA

-- 92a0fc21-a95e-4275-b3dc-a8a7ee130965
SELECT * FROM SimPersona sper
WHERE
   sper.sIdPaisNacionalidad = 'ECU'
   AND sper.sSexo = 'M'
   -- AND sper.sNombre LIKE '%Valeria%'
   AND sper.sPaterno = 'VELEZ'
   AND sper.sMaterno = 'VELEZ'
   -- AND sper.sSexo = 'M'
   -- AND sper.sNombre LIKE '%Valeria%'

   -- Kenny
   /*sper.sNombre LIKE '%'
   AND sper.sMaterno LIKE 'JARAMILLO%'
   AND sper.sPaterno LIKE 'CONDOR%'*/



-- Trámites
SELECT 
   [sEmpresa] = so.sNombre, 
   sti.* 
FROM SimTramite st
JOIN SimTramiteInm  sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimOrganizacion so ON sti.nIdOrganizacion = so.nIdOrganizacion
WHERE
   st.uIdPersona = '92a0fc21-a95e-4275-b3dc-a8a7ee130965'

-- MovMigra ...
SELECT * FROM SimMovMigra smm
WHERE
   smm.uIdPersona = '92a0fc21-a95e-4275-b3dc-a8a7ee130965'


---