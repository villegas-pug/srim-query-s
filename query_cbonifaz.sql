USE SIM
GO

-- 1
DROP TABLE IF EXISTS #tmp_dnv
SELECT 
   TOP 0
   [nId] = 0,
   dnv.sNombre,
   dnv.sPaterno,
   dnv.sMaterno,
   dnv.sIdPaisNacionalidad,
   [sNumDocInvalida] = dnv.sDescripcion
   INTO #tmp_dnv
FROM SimPersonaNoAutorizada dnv

-- 1.1
-- INSERT INTO #tmp_dnv VALUES()
SELECT COUNT(1) FROM #tmp_dnv
SELECT TOP 10 * FROM #tmp_dnv

-- Update ...
UPDATE #tmp_dnv
   SET sNombre = REPLACE(sNombre, '''''', ''''),
       sPaterno = REPLACE(sPaterno, '''''', ''''),
       sMaterno = REPLACE(sMaterno, '''''', ''''),
       sNumDocInvalida = REPLACE(sNumDocInvalida, '''''', '''')

-- 2
-- SELECT * FROM SimMotivoInvalidacion
SELECT
   t.*,
   [Motivo Invalidación] = (
                              SELECT
                                 TOP 1
                                 smi.sDescripcion
                              FROM SimPersonaNoAutorizada dnv
                              JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
                              JOIN SimMotivoInvalidacion smi ON smi.sIdMotivoInv = dnv.sIdMotivoInv
                              WHERE
                                 dnv.sNombre = RTRIM(LTRIM(t.sNombre))
                                 AND dnv.sPaterno = t.sPaterno
                                 AND dnv.sMaterno = t.sMaterno
                                 AND dnv.sIdPaisNacionalidad = RTRIM(LTRIM(t.sIdPaisNacionalidad))
                                 AND t.sNumDocInvalida LIKE '%' + RTRIM(LTRIM(sdi.sNumDocInvalida)) + '%'
                           )
FROM #tmp_dnv t



SELECT * FROM SimDocInvalidacion sdi
WHERE 'OFC N° OFICIO N° 01295 -2022-PVM-CARPITAS-JZ1TUM/MIGRACIO' LIKE '%' + sdi.sNumDocInvalida + '%'