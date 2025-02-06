USE SIM
GO

/*░
   En atención a lo coordinado se solicita información sobre el total de personas extranjeras de nacionalidades: 

   -  Siria, Irak, Líbano, Irán, Palestina, Israel, Jordania, Kuwait, Baréin, Arabia Saudita, Qatar, Emiratos Árabes Unidos, 
      Omán, Yemen, Egipto, Sudán, Libia, Chipre y Turquía, Cuba y Rusia.
   
   Que hubieran ingresado a territorio peruano entre los años 2022 y 2023, y si dichas personas aún se encuentran en el país, 
   así como si cuentan o no con calidad migratoria vigente.

 ========================================================================================================================================================================*/

-- 1:
-- 1.1: Todos movimientos migratorios(E, S) ...
DROP TABLE IF EXISTS #tmp_mm_pnp_1
SELECT 
   mm.*
   INTO #tmp_mm_pnp_1
FROM (

   SELECT
      smm.*,
      [sIdPersona] = CONCAT(smm.sIdPaisNacionalidad, smm.sIdDocumento, smm.sNumeroDoc),
      [nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC),
      -- [nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.sIdPaisNacionalidad, smm.sIdDocumento, smm.sNumeroDoc ORDER BY smm.dFechaControl DESC)
      [nTotal_mm2] = COUNT(smm.uIdPersona) OVER (PARTITION BY smm.sIdPaisNacionalidad, smm.sIdDocumento, smm.sNumeroDoc)
   FROM SimMovMigra smm
   WHERE
      smm.bAnulado = 0
      AND smm.bTemporal = 0
      AND smm.dFechaControl >= '2022-01-01 00:00:00.000'
      AND smm.sIdPaisNacionalidad IN (

         SELECT sp.sIdPais FROM SimPais sp
         RIGHT JOIN (

            SELECT tmp_paises.* FROM (
            VALUES 
               ('Iraq'), ('Libano'), ('Iran'), ('Palestina'), ('Israel'), ('Jordania'), ('Kuwait'), ('BAHREIN'), ('Arabia Saudita'), 
               ('Qatar'), ('EMIRATOS ARABES UNID'), ('Oman'), ('Yemen'), ('Egipto'), ('Sudan'), ('Libia'), ('Chipre'), ('Turquia'), ('Cuba'), ('Rusia')
            ) AS tmp_paises([sNombre])

         ) p on sp.sNombre = p.sNombre
         WHERE
            sp.sNombre IS NOT NULL

      )

) mm
WHERE
   mm.nFila_mm = 1

-- Update: Elimina espacion en blanco de `#tmp_mm_pnp_1.sIdPersona` ...
-- SELECT REPLACE('abc def', ' ', '')
UPDATE #tmp_mm_pnp_1
   SET sIdPersona = REPLACE(sIdPersona, ' ', '')

-- Test ...
-- RAFI	VAKYIN
SELECT * FROM #tmp_mm_pnp_1 mm

-- 1.2: Ultimo MovMigra agrupados por sIdPaisNacionalidad, sIdDocumento, sNumeroDoc ...
DROP TABLE IF EXISTS #tmp_mm_pnp_1_2
SELECT 
   mm.*
   INTO #tmp_mm_pnp_1_2
FROM (

   SELECT
      smm.*,
      [nFila_mm2] = ROW_NUMBER() OVER (PARTITION BY smm.sIdPersona ORDER BY smm.dFechaControl DESC)
   FROM #tmp_mm_pnp_1 smm

) mm
WHERE
   mm.nFila_mm2 = 1

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_mm_pnp_1
   ON #tmp_mm_pnp_1(uIdPersona)

CREATE NONCLUSTERED INDEX IX_tmp_mm_pnp_1_2
   ON #tmp_mm_pnp_1_2(uIdPersona)

-- Test ...
SELECT TOP 10 * FROM #tmp_mm_pnp_1_2 mm 
WHERE
   mm.nTotal_mm2 > 1

-- 2: Trámites de Cambio de Calidad para `#tmp_mm_pnp_1` ...
-- CAMBIO DE CALIDAD MIGRATORIA, REGULARIZACION DE EXTRANJEROS, PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS #tmp_mm_pnp_1_ccm
SELECT 
   mm3.*
   INTO #tmp_mm_pnp_1_ccm 
FROM (

   SELECT 
      mm2.*,
      [nFila_ccm] = ROW_NUMBER() OVER (PARTITION BY mm2.sIdPersona ORDER BY mm2.dFechaAprobacion DESC)
   FROM (

      SELECT 
         st.uIdPersona,
         mm.sIdPersona,
         st.sNumeroTramite,
         st.nIdTipoTramite,
         [dFechaAprobacion] = (
                                 SELECT 
                                    TOP 1 
                                    seti.dFechaHoraFin
                                 FROM dbo.SimEtapaTramiteInm seti
                                 WHERE 
                                    seti.sNumeroTramite = st.sNumeroTramite 
                                    AND seti.nIdEtapa = (
                                                            CASE st.nIdTipoTramite 
                                                               WHEN 126 THEN 75 
                                                               WHEN 58 THEN 46 
                                                               WHEN 113 THEN 75 
                                                            END
                                                      )  
                                    AND seti.sEstado = 'F' 
                                    AND seti.bActivo = 1
                                 ORDER BY
                                    seti.dFechaHoraFin DESC
         ),
         [dFechaVencimiento] = (
                                 CASE st.nIdTipoTramite
                                    WHEN  58 THEN ( -- CCM
                                       SELECT sccm.dFechaVencimiento FROM SimCambioCalMig sccm 
                                       WHERE
                                          sccm.sNumeroTramite = st.sNumeroTramite
                                    )
                                    ELSE ( -- Otros trámites de regularización ...

                                       SELECT sptp.dFechaCaducidad FROM SimCarnetPTP sptp
                                       WHERE
                                          sptp.sNumeroTramite = st.sNumeroTramite

                                    )
                                 END
         )
      FROM #tmp_mm_pnp_1 mm
      JOIN SimTramite st ON mm.uIdPersona = st.uIdPersona
      JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
      WHERE
         st.bCancelado = 0
         AND sti.sEstadoActual IN ('P', 'A')
         AND st.nIdTipoTramite IN (58, 113, 126)

   ) mm2
   
) mm3
WHERE
   mm3.nFila_ccm = 1

-- 3: Final ...
DROP TABLE IF EXISTS #tmp_mm_pnp_3
SELECT
   [Nombre] = sper.sNombre,
   [Paterno] = sper.sPaterno,
   [Materno] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sper.dFechaNacimiento,
   [Nacionalidad] = spn.sNacionalidad,
   [Fecha Ultimo MovMigra] = mm.dFechaControl,
   [Tipo Ultimo MovMigra] = mm.sTipo,
   [Dependencia] = sd.sNombre,
   [Calidad Control Migra] = scmm.sDescripcion,
   [Documento] = mm.sIdDocumento,
   [Numero Documento] = CONCAT('''', mm.sNumeroDoc),
   
   -- ¿Esta dentro del Perú? ...
   [Dentro del Perú] = IIF(mm.sTipo = 'E', 'SI', 'NO'),

   -- Cuenta o no con CCM vigente ...
   [Estado Calidad Migratoria] = (

                                    CASE 
                                       WHEN (SELECT 1 FROM #tmp_mm_pnp_1_ccm ccm WHERE ccm.sIdPersona = mm.sIdPersona) IS NULL THEN 'Sin trámites CCM'
                                       ELSE (
                                          CASE
                                             WHEN (
                                                      SELECT DATEDIFF(DD, GETDATE(), ccm.dFechaVencimiento) 
                                                      FROM #tmp_mm_pnp_1_ccm ccm
                                                      WHERE ccm.sIdPersona = mm.sIdPersona
                                                   ) IS NULL THEN 'Vencido'
                                             WHEN (
                                                      SELECT DATEDIFF(DD, GETDATE(), ccm.dFechaVencimiento) 
                                                      FROM #tmp_mm_pnp_1_ccm ccm
                                                      WHERE ccm.sIdPersona = mm.sIdPersona
                                                   ) <= 0 THEN 'Vencido'
                                             ELSE 'Vigente'
                                          END
                                       )
                                    END               

   ),
   [Calidad Migratoria] = (
                              COALESCE(
                                 (
                                    SELECT stt.sDescripcion FROM #tmp_mm_pnp_1_ccm ccm
                                    JOIN SimTipoTramite stt ON ccm.nIdTipoTramite = stt.nIdTipoTramite
                                    WHERE
                                       ccm.sIdPersona = mm.sIdPersona
                                 ),
                                 'Sin trámites CCM'
                              )
                              
   ),
   [Total MovMigra] = mm.nTotal_mm2
   INTO #tmp_mm_pnp_3
FROM #tmp_mm_pnp_1_2 mm
JOIN SimPersona sper ON mm.uIdPersona = sper.uIdPersona
JOIN SimPais spn ON sper.sIdPaisNacionalidad = spn.sIdPais
JOIN SimDependencia sd ON mm.sIdDependencia = sd.sIdDependencia
JOIN SimCalidadMigratoria scmm ON mm.nIdCalidad = scmm.nIdCalidad

-- Test ...
SELECT DATEDIFF(DD, GETDATE(), '2023-11-15')
SELECT COUNT(1) FROM #tmp_mm_pnp_1

SELECT ccm.* FROM #tmp_mm_pnp_1_ccm ccm
JOIN SimPersona sper ON ccm.uIdPersona = sper.uIdPersona
WHERE
   sper.sNombre = 'ANTON'
   AND sper.sPaterno = 'ZONOV'

-- ...
SELECT COUNT(1) FROM #tmp_mm_pnp_3

SELECT * FROM #tmp_mm_pnp_3 mm
ORDER BY [Total MovMigra] DESC
-- ========================================================================================================================================================================*/


SELECT COUNT(1) FROM SimRQAudit

SELECT TOP 10 * FROM SimRQAudit srq
ORDER BY
   srq.dInicio DESC