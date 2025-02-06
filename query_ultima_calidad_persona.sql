USE SIM
GO


--> ░ 1. Ultima Calidad solicitada de persona extranjera ...
-- ========================================================================================================================================================================

DROP TABLE IF EXISTS BD_SIRIM.dbo.RimUltimaCalidadExtranjero

;WITH cte_tram_otorg_calidad AS
( -- 1
   SELECT

      t.uIdPersona,
      t.sNumeroTramite,
      [dFechaTramite] = t.dFechaHora,
      t.nIdTipoTramite,
      [sTipoTramite] = tt.sDescripcion,
      [nIdCalidadSolicitada] = (
                                    CASE
                                       WHEN t.nIdTipoTramite = 55 THEN (  -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
                                                                        SELECT v.nIdCalSolicitada
                                                                        FROM SimVisa v
                                                                        WHERE
                                                                           v.sNumeroTramite = t.sNumeroTramite
                                                                  )
                                       ELSE ( -- Otros trámites que actualicen la calidad migratorio ...
                                                SELECT ccm.nIdCalSolicitada
                                                FROM SimCambioCalMig ccm
                                                WHERE 
                                                   ccm.sNumeroTramite = t.sNumeroTramite
                                       )
                                    END
                              ),
      [dFechaAprobacionCalidad] = (
                                       SELECT TOP 1 e.dFechaHoraFin
                                       FROM SimEtapaTramiteInm e
                                       WHERE
                                          e.bActivo = 1
                                          AND e.sEstado = 'F'
                                          AND e.sNumeroTramite = t.sNumeroTramite
                                          AND e.nIdEtapa = ( -- Etapa aprueba el trámite ...
                                                               SELECT a.nIdEtapa
                                                               FROM BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion a
                                                               WHERE 
                                                                  a.nIdTipoTramite = t.nIdTipoTramite
                                          )
                                       ORDER BY e.nIdEtapaTramite DESC
      )

   FROM SimTramite t
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   WHERE
      t.bCancelado = 0
      -- AND t.bCulminado = 1
      AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND ti.sEstadoActual IN ('A', 'P')
      AND t.nIdTipoTramite IN ( -- Trámites que otorgan una calidad ...
                                 SELECT a.nIdTipoTramite
                                 FROM BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion a
                                 WHERE 
                                    a.bOtorgaCalidad = 1
                              )
      AND EXISTS ( -- Registra etapa que aprueba el trámite ...

                     SELECT 1
                     FROM SimEtapaTramiteInm eti
                     WHERE
                        eti.bActivo = 1 -- Activo
                        AND eti.sEstado = 'F' -- Finalizado
                        AND eti.sNumeroTramite = t.sNumeroTramite
                        AND eti.nIdEtapa = (
                                             SELECT a.nIdEtapa
                                             FROM BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion a
                                             WHERE 
                                                a.nIdTipoTramite = t.nIdTipoTramite
                        )

      )
), cte_tram_otorg_calidad_ultim AS ( -- 2

   SELECT * 
   FROM (

      SELECT 
         c.*,

         -- Aux
         [#] = ROW_NUMBER() OVER (PARTITION BY c.uIdPersona ORDER BY c.dFechaAprobacionCalidad DESC)
      FROM cte_tram_otorg_calidad c

   ) uc
   WHERE
      uc.[#] = 1

) -- Final:
SELECT uc.* INTO BD_SIRIM.dbo.RimUltimaCalidadExtranjero FROM cte_tram_otorg_calidad_ultim uc


-- Test ...
-- 1
SELECT 
   TOP 10
   [sCalidadMigratoria] = cm.sDescripcion,
   uc.* 
FROM BD_SIRIM.dbo.RimUltimaCalidadExtranjero uc
JOIN SimCalidadMigratoria cm ON uc.nIdCalidadSolicitada = cm.nIdCalidad
WHERE
   uc.nIdTipoTramite = 58

-- ========================================================================================================================================================================
