USE SIM
GO

-- BASE CENTRAL PAS
-- 0cc0d693-d090-41c6-bafd-cae3765a9003 ↔ 15
DROP TABLE IF EXISTS #tmp_pasa_15
SELECT
   [nOrden] = ROW_NUMBER() OVER (ORDER BY t.dFechaHora ASC),
   -- pas.*,
   tp.sPasNumero,
   t.uIdPersona
   INTO #tmp_pasa_15
FROM SimTramitePas tp
JOIN SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND t.nIdTipoTramite = 90
   AND t.uIdPersona = '0cc0d693-d090-41c6-bafd-cae3765a9003'
ORDER BY
   t.dFechaHora ASC


-- 1.2
SELECT * FROM (

   SELECT
      [nOrden] = (
                     COALESCE(
                        (
                           SELECT p.nOrden
                           FROM #tmp_pasa_15 p
                           WHERE p.sPasNumero =  mm.sNumeroDoc
                        ),
                        0
                     )
      ),
      mm.dFechaControl,
      mm.sTipo,
      [sDependencia] = d.sNombre,
      mm.sIdDocumento,
      mm.sNumeroDoc,
      mm.sIdPaisMov
   FROM SimMovMigra mm
   JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.uIdPersona = '0cc0d693-d090-41c6-bafd-cae3765a9003'
      -- AND mm.sIdDocumento = 'PAS'
      /* AND mm.sNumeroDoc IN (
                              SELECT p.sNumeroPasaporte
                              FROM #tmp_pasa_15 p
                           ) */

) mm2
ORDER BY mm2.dFechaControl ASC

SELECT p.sPasNumero
FROM #tmp_pasa_15 p
WHERE
   NOT EXISTS (
                  SELECT
                     1
                  FROM SimMovMigra mm
                  WHERE
                     mm.bAnulado = 0
                     AND mm.bTemporal = 0
                     AND mm.uIdPersona = '0cc0d693-d090-41c6-bafd-cae3765a9003'
                     AND mm.sIdDocumento = 'PAS'
                     AND mm.sNumeroDoc = p.sPasNumero
               )

/* SELECT * 
FROM SimPasaporte pas WHERE pas.sPasNumero = '124182173' */

SELECT * 
FROM SimTramitePas pas WHERE pas.sPasNumero = '124182173'

-- 2
SELECT
   i.* 
FROM SimImagen i 
WHERE 
   i.uIdPersona = '0cc0d693-d090-41c6-bafd-cae3765a9003'
   AND i.sTipoImagen = 'F'
   AND i.sNumeroTramite = 'LV240149870'
   
-- 3
SELECT
   p.sNombre,
   p.sPaterno,
   p.sMaterno,
   [nEdad] = DATEDIFF(YYYY, p.dFechaNacimiento, GETDATE()),
   [sDomicilio] = CONCAT(u.sNombre, ', ', pe.sDomicilio),
   [sProfesion] = pf.sDescripcion   
FROM SimPersona p
JOIN SimPeruano pe ON p.uIdPersona = pe.uIdPersona
JOIN SimProfesion pf ON p.sIdProfesion = pf.sIdProfesion
JOIN SimUbigeo u ON pe.sIdUbigeoDomicilio = u.sIdUbigeo
WHERE
   p.uIdPersona = '0cc0d693-d090-41c6-bafd-cae3765a9003'


/*
   Ing. Luis: AVALOS LOAYZA TERESA VICTORIA ↔ DNI: 44215933
   Ing. Luis: NOMBRE: AYRTON ALDAIR ALBUJAR TORRES → DNI: 46040202 */



SELECT * 
FROM BD_SIRIM.dbo.RimPasaporte pas
WHERE 
   pas.sNumeroPasaporte IN (
      SELECT
         -- DISTINCT
         /* p.sNombre,
         p.sPaterno,
         p.sMaterno,
         p.sIdPaisNacionalidad, */
         tp.sPasNumero
      FROM SimTramitePas tp 
      JOIN SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
      JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
      WHERE
         t.bCancelado = 0
         AND t.nIdTipoTramite = 90
         AND t.uIdPersona IN (
                                 SELECT p.uIdPersona
                                 FROM SimPersona p
                                 WHERE
                                    p.sIdDocIdentidad = 'DNI'
                                    AND p.sNumDocIdentidad = '44215933'
                              )

   )

