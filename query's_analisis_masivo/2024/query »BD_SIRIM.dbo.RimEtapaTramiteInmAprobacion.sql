USE SIM
GO

/*
   1. 58    | CCM ↔ 46	| EVALUACIÓN
   2. 118   | EXPEDICIÓN DE CARNÉ DE EXTRANJERÍA → 16 | FIRMA SELLO DIR. INMIGRACION
   3. 64    | DUPLICADO DE CE → 22 | CONFORMIDAD SUB-DIREC.INMGRA.
   4. 117   | RENOVACION DE CARNÉ DE EXTRANJERÍA → 22 | CONFORMIDAD SUB-DIREC.INMGRA.
   5. 111   | ACTUALIZACIÓN CON EMISIÓN DE DOCUMENTO	→ 6 | IMPRESION  
   6. 55    | SOLICITUD DE CALIDAD MIGRATORIA | VISA                                               
   2. 57    | 22 | CONFORMIDAD SUB-DIREC.INMGRA. 
   7. 113   | 63 | ENTREGA DE CARNÉ P.T.P.
   8. 126   | 80 | ENTREGA DE CARNÉ C.P.P.
   
   
   
   */

-- Tabla física ...
DROP TABLE IF EXISTS BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion
CREATE TABLE BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion
(
   nIdTipoTramite INT NOT NULL,
   nIdEtapa INT NOT NULL,
   sEtapa VARCHAR(255) NOT NULL,
   bOtorgaCalidad BIT
)

-- Bulk
INSERT INTO BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion
   VALUES
      (58, 46, 'EVALUACIÓN', 1),
      (118, 16, 'FIRMA SELLO DIR. INMIGRACION', 0),
      (64, 22, 'CONFORMIDAD SUB-DIREC.INMGRA.', 0),
      (117, 22, 'CONFORMIDAD SUB-DIREC.INMGRA.', 0),
      (111, 6, 'IMPRESION', 0),
      (55, 22, 'CONFORMIDAD SUB-DIREC.INMGRA.', 1), -- 55 | SOLICITUD DE CALIDAD MIGRATORIA | VISA
      (57, 22, 'CONFORMIDAD SUB-DIREC.INMGRA.', 0),
      (113, 63, 'ENTREGA DE CARNÉ P.T.P.', 1),
      (126, 80, 'ENTREGA DE CARNÉ C.P.P.', 1)


-- Test

-- 1
SELECT tt.nIdTipoTramite, tt.sDescripcion FROM BD_SIRIM.dbo.RimEtapaTramiteInmAprobacion a
JOIN SimTipoTramite tt ON a.nIdTipoTramite = tt.nIdTipoTramite

-- 2
SELECT 
   -- COUNT(1)
   g.*
FROM BD_SIRIM.dbo.ResultadoConsultaGeocoder g
WHERE
   -- g.sEstado != 'P'
   g.nIdResutado IN (17962, 17932)


-- 17962
-- 17932

/*
   c → 43,432
   P → 16,649
   x → 2,835
   e → 1,643
*/

SELECT
   g.*
FROM BD_SIRIM.dbo.ResultadoConsultaGeocoder g
WHERE
   g.sEstado = 'X'
