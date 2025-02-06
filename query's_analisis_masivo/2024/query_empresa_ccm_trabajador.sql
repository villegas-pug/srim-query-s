USE SIM
GO

-- Empresa registradas en Calidad solicitada `TRABAJADOR` ...
-- ======================================================================================================================================================================== */

-- 1.1

SELECT TOP 10 * 
FROM SimCarnetExtranjeria

DROP TABLE IF EXISTS #tmp_ccm_trabajador
SELECT

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = pa.sNacionalidad,
   [Ultimo MovMigra] = (
                           SELECT TOP 1 mm.sTipo
                           FROM SimMovMigra mm
                           WHERE 
                              mm.bAnulado = 0
                              AND mm.bTemporal = 0
                              AND mm.uIdPersona = t.uIdPersona
                           ORDER BY mm.dFechaControl DESC
   ),
   [Fecha Ultimo MovMigra] = (
                                 SELECT TOP 1 CAST(mm.dFechaControl AS DATE)
                                 FROM SimMovMigra mm
                                 WHERE 
                                    mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                    AND mm.uIdPersona = t.uIdPersona
                                 ORDER BY mm.dFechaControl DESC
   ),

   -- Aux
   [Carnet Extranjeria] = (
                              COALESCE(
                                    (
                                       SELECT TOP 1 ce.sNumeroCarnet
                                       FROM SimCarnetExtranjeria ce
                                       WHERE
                                          ce.uIdPersona = t.uIdPersona
                                       ORDER BY ce.dFechaEmision DESC
                                    ), (
                                       SELECT TOP 1 ce.sNumeroCarnet
                                       FROM SimCarnetPtp ce
                                       WHERE
                                          ce.uIdPersona = t.uIdPersona
                                       ORDER BY ce.dFechaEmision DESC
                                    )

                              )
   ),
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Año Aprobación] = (
                           SELECT 
                              TOP 1 
                              DATEPART(YYYY, et.dFechaHoraFin)
                           FROM SimEtapaTramiteInm et
                           WHERE
                              et.sNumeroTramite = t.sNumeroTramite 
                              AND et.bActivo = 1
                              AND et.sEstado = 'F'
                           ORDER BY et.nIdEtapaTramite DESC
   ),
   [Estado Trámite] = ti.sEstadoActual,
   [Calidad Migratoria] = cm.sDescripcion,
   [Empresa] = o.sNombre,
   [Empresa DOC] = o.sIdDocumento,
   [Empresa DOC NRO] = o.sNumeroDoc

   INTO #tmp_ccm_trabajador
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimPais pa ON p.sIdPaisNacionalidad = pa.sIdPais
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimOrganizacion o ON ti.nIdOrganizacion = o.nIdOrganizacion
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND ccm.nIdCalSolicitada IN (

                                    SELECT cm.nIdCalidad
                                    FROM SimCalidadMigratoria cm
                                    WHERE 
                                       cm.bActivo = 1
                                       AND cm.sDescripcion LIKE '%trab%'

   )

-- 2
SELECT * 
FROM (
   SELECT 
      t.*,

      -- Aux
      [bFueraPaisMenos183dias] = (
                                    CASE
                                       WHEN (t.[Ultimo MovMigra] IS NULL) THEN 2
                                       WHEN (t.[Ultimo MovMigra] = 'S') THEN (
                                          CASE
                                             WHEN (DATEDIFF(DD, t.[Fecha Ultimo MovMigra], GETDATE())) <= 183 THEN 1
                                             ELSE 0
                                          END
                                       )
                                       ELSE 2
                                    END
                                 )
      
   FROM #tmp_ccm_trabajador t
) f
WHERE f.bFueraPaisMenos183dias >= 1


-- Test
SELECT DATEDIFF(DD, '2024-12-01', GETDATE())
SELECT IIF(-183 > -200, 1, 0)

SELECT TOP 10 * 
FROM SimOrganizacion ;


-- 1.2 Empresas por año

-- 1.1
SELECT 
   pv.* 
FROM (
   SELECT

      -- Aux
      [Número Trámite] = t.sNumeroTramite,
      [Año Trámite] = DATEPART(YYYY, t.dFechaHora),
      [Empresa] = o.sNombre

   FROM SimTramite t
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   -- JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
   -- JOIN SimPais pa ON p.sIdPaisNacionalidad = pa.sIdPais
   JOIN SimOrganizacion o ON ti.nIdOrganizacion = o.nIdOrganizacion
   -- JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND ti.sEstadoActual = 'A'
      /*AND ccm.nIdCalSolicitada IN (

                                    SELECT cm.nIdCalidad
                                    FROM SimCalidadMigratoria cm
                                    WHERE 
                                       cm.bActivo = 1
                                       AND cm.sDescripcion LIKE '%trab%'

      )*/

) f 
PIVOT (
   COUNT(f.[Número Trámite]) FOR f.[Año Trámite] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023], [2024])
) pv




-- ======================================================================================================================================================================== */


SELECT * 
FROM SimCarnetPtp t
WHERE t.uIdPersona = '6abed57c-7d0e-44ce-96d6-4c7a59f19ed5'

SELECT * 
FROM SimCarnetExtranjeria t
WHERE t.uIdPersona = '6abed57c-7d0e-44ce-96d6-4c7a59f19ed5'

SELECT 
   t.sNumeroCarnet,
   COUNT(1)
FROM SimCarnetExtranjeria t
GROUP BY
   t.sNumeroCarnet
ORDER BY 2 DESC

SELECT * 
FROM SimCarnetExtranjeria t
WHERE t.sNumeroCarnet = '000500294'

SELECT *
FROM SimOrganizacion o
WHERE o.sNumeroDoc = 'LM240318523'

SELECT 
   t.dFechaHora,
   t.bCancelado,
   ti.sEstadoActual,
   cm.sDescripcion
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimCambioCalMig ccm ON t.sNumeroTramite = ccm.sNumeroTramite
JOIN SimCalidadMigratoria cm ON ccm.nIdCalSolicitada = cm.nIdCalidad
JOIN SimOrganizacion o ON ti.nIdOrganizacion = o.nIdOrganizacion
WHERE 
   t.uIdPersona = '6abed57c-7d0e-44ce-96d6-4c7a59f19ed5'
   AND t.nIdTipoTramite = 58

SELECT * 
WHERE ti.sNumeroTramite = 'PU220008341'
