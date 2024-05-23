USE SIM
GO

   /* -- Trámite
   [sNumeroTramite] = t.sNumeroTramite,
   [TipoTramite] = tt.sDescripcion,
   [Estado Actual] = ti.sEstadoActual,
   [Fecha Trámite] = t.dFechaHora,
   [Año Trámite] = DATEPART(YYYY, t.dFechaHora),

   -- Administrado
   [Nombre Administrado] = p.sNombre,
   [Paterno Administrado] = p.sPaterno,
   [Materno Administrado] = p.sMaterno,
   [Sexo Administrado] = p.sSexo,
   [Fec Nac Administrado] = p.dFechaNacimiento */

-- Trámites inmigración:

-- 1.1
DROP TABLE IF EXISTS #tmp_tram_inm
SELECT 
   e.*,
   -- Aux
   [nContar(T)] = COUNT(1) OVER (PARTITION BY e.[Id Persona]),
   [nOrden(T)] = ROW_NUMBER() OVER (PARTITION BY e.[Id Persona] ORDER BY e.[Fecha Trámite] ASC)
   INTO #tmp_tram_inm
FROM (

   SELECT -- INM
      [Id Persona] = t.uIdPersona,
      [Numero Tramite] = t.sNumeroTramite,
      [Estado Actual] = ti.sEstadoActual,
      [Tipo Tramite] = tt.sSigla,
      [Fecha Trámite] = t.dFechaHora

   FROM SimTramite t
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   WHERE
      t.bCancelado = 0
      AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'

   UNION ALL

   SELECT -- NAC
      [Id Persona] = t.uIdPersona,
      [Numero Tramite] = t.sNumeroTramite,
      [Estado Actual] = tn.sEstadoActual,
      [Tipo Tramite] = tt.sSigla,
      [Fecha Trámite] = t.dFechaHora
   FROM SimTramite t
   JOIN SimTramiteNac tn ON t.sNumeroTramite = tn.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   WHERE
      t.bCancelado = 0
      AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'

) e


-- 1.2 Clusterizar:

-- 1.2.1: Registra solo 1 trámite en estado `P` ...
DROP TABLE IF EXISTS #tmp_inm_1_tram_P
SELECT
   i.*,
   [sGrupo] = 'Único trámite (P)'
   INTO #tmp_inm_1_tram_P
FROM #tmp_tram_inm i
WHERE
   i.[nContar(T)] = 1 AND i.[Estado Actual] = 'P'


-- 1.2.2: Registra el 1° trámite `P` y posteriores todos los estado ...
DROP TABLE IF EXISTS #tmp_inm_1tramP_y_2masposttodoestados
SELECT
   i.*,
   [sGrupo] = 'Primer trámite (P), posteriores (Todos)'
   INTO #tmp_inm_1tramP_y_2masposttodoestados
FROM #tmp_tram_inm i
WHERE
   i.[nContar(T)] >= 2 -- 2 más trámites
   AND EXISTS (
                  SELECT 1
                  FROM #tmp_tram_inm i2
                  WHERE
                     i2.[Id Persona] = i.[Id Persona]
                     AND i2.[nOrden(T)] = 1 -- 1° trámite
                     AND i2.[Estado Actual] = 'P'

   )

-- 1.2.2: Registra todos trámite `P` ...
DROP TABLE IF EXISTS #tmp_inm_2mastodospendientes
SELECT
   i.*,
   [sGrupo] = 'Todos trámite (P)'
   INTO #tmp_inm_2mastodospendientes
FROM #tmp_tram_inm i
WHERE
   i.[nContar(T)] >= 2 -- 2 más trámites
   AND i.[nContar(T)] = (
                           SELECT COUNT(1)
                           FROM #tmp_tram_inm i2
                           WHERE
                              i2.[Id Persona] = i.[Id Persona]
                              AND i2.[Estado Actual] = 'P'
   )


-- 2. Únion
DROP TABLE IF EXISTS #tmp_union_tram
SELECT t.* INTO #tmp_union_tram
FROM (

   SELECT * FROM #tmp_inm_1_tram_P
   UNION ALL
   SELECT * FROM #tmp_inm_1tramP_y_2masposttodoestados
   UNION ALL
   SELECT * FROM #tmp_inm_2mastodospendientes

) t

-- 3. `uId` únicos ...
SELECT 
   t2.*,
   [sGrupo(Tipo&Estado)] = (
                              SIM.dbo.uf_CleanFieldXML(
                                 (
                                    SELECT [sTipoTramite] = u2.[Tipo Tramite], [sEstadoActual] = u2.[Estado Actual]
                                    FROM #tmp_union_tram u2
                                    WHERE
                                       u2.[Id Persona] = t2.[Id Persona]
                                    ORDER BY u2.[Fecha Trámite] ASC
                                    FOR XML PATH('')
                                 )
                              )
                           )
FROM (

   SELECT
      u.*,
      [nOrden(Per)] = ROW_NUMBER() OVER (PARTITION BY u.[Id Persona] ORDER BY u.[Fecha Trámite])
   FROM #tmp_union_tram u

) t2
WHERE t2.[nOrden(Per)] = 1


-- Test
SELECT u.[Tipo Tramite], COUNT(1)
FROM #tmp_union_tram u
GROUP BY u.[Tipo Tramite]
ORDER BY 2 DESC


-- <sTipoTramite>PTP</sTipoTramite><sEstadoActual>P</sEstadoActual>
CREATE OR ALTER FUNCTION uf_CleanFieldXML(@g VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
   DECLARE @g_bak VARCHAR(MAX) = ''
   SET @g_bak = REPLACE(REPLACE(@g, '<sTipoTramite>', ', '), '</sTipoTramite>', '')
   SET @g_bak = REPLACE(REPLACE(@g_bak, '<sEstadoActual>', '('), '</sEstadoActual>', ')')

   IF(CHARINDEX(', ', @g_bak) > 0)
      SET @g_bak = SUBSTRING(@g_bak, 3, LEN(@g_bak))

   RETURN @g_bak
END


SELECT SIM.dbo.uf_CleanFieldXML('<sTipoTramite>PTP</sTipoTramite><sEstadoActual>P</sEstadoActual><sTipoTramite>PTP</sTipoTramite><sEstadoActual>P</sEstadoActual>')
-- SELECT CHARINDEX('ab', 'abc')
SELECT SUBSTRING(' ,abc', 2, LEN(' ,abc'))

SELECT 
    SUBSTRING('SQL Server SUBSTRING', 5, 6) result;






-- 2
USE SIM
GO

DROP TABLE IF EXISTS #tmp_tramites
SELECT
	[Número Trámite] = t.sNumerotramite,
	[Dependencia] = D.sNombre,
	[Tipo Trámite] = UPPER(tt.sDescripcion),
	[Fecha Trámite] = CONVERT(CHAR(10), t.dFechaHora, 23),
   [Módulo] = m.sIdModulo
	INTO #tmp_tramites
FROM [dbo].[SimTramite] t
JOIN SimTipoTramite	tt	ON  tt.nIdTipoTramite = t.nIdTipoTramite
LEFT JOIN SimDependencia d on t.sIdDependencia = d.sIdDependencia
LEFT JOIN SimSesion s ON t.nIdSesion = s.nIdSesion
LEFT JOIN SimModulo m ON s.sIdModulo = m.sIdModulo
WHERE 
	t.bCancelado = 0
	AND t.bCulminado = 0 

-- Update
UPDATE #tmp_tramites
   SET [Módulo] = 'S/R' 
WHERE [Módulo] IS NULL


-- 2.2. Etapas
DROP TABLE IF EXISTS #tmp_etapas
SELECT e.* INTO #tmp_etapas
FROM (


   SELECT i.*
   FROM ( -- Inmigración

      SELECT
         [Número Trámite],
         [Etapa Actual] = e.sDescripcion,
         [#] = ROW_NUMBER() OVER (PARTITION BY eti.sNumeroTramite ORDER BY eti.nIdEtapaTramite DESC)
      FROM #tmp_tramites t
      JOIN SimTramiteInm ti ON t.[Número Trámite] = ti.sNumeroTramite
      JOIN SimEtapaTramiteInm eti ON t.[Número Trámite] = eti.sNumeroTramite
      JOIN SimEtapa e ON e.nIdEtapa = eti.nIdEtapa
      WHERE 
         eti.bActivo = 1
         AND ti.sEstadoActual = 'P'

   ) i 
   WHERE i.[#] = 1

   UNION

   SELECT n.* 
   FROM (-- Nacionalización
   SELECT 
      [Número Trámite],
      [Etapa Actual] = e.sDescripcion,
      [#] = ROW_NUMBER() OVER (PARTITION BY etn.sNumeroTramite ORDER BY etn.nIdEtapaTramite DESC)
   FROM #tmp_tramites t
   JOIN SimTramiteNac tn ON t.[Número Trámite] = tn.sNumeroTramite
   JOIN SimEtapaTramiteNac etn ON t.[Número Trámite] = etn.sNumeroTramite
   JOIN SimEtapa e ON e.nIdEtapa = etn.nIdEtapa
   WHERE 
      etn.bActivo = 1
      AND tn.sEstadoActual = 'P'
   ) n
   WHERE n.[#] = 1

) e

-- 2.3 Final
DROP TABLE IF EXISTS #tmp_tramites_final
SELECT
   t.*,
   e.[Etapa Actual]
   INTO #tmp_tramites_final
FROM #tmp_tramites t
LEFT JOIN #tmp_etapas e ON t.[Número Trámite] = e.[Número Trámite]



-- Test
SELECT
   f.*,
   [Beneficiario] = (
                        COALESCE(
                           (
                              SELECT RTRIM(LTRIM(CONCAT(p.sNombre, ' ', p.sPaterno, ' ', p.sMaterno)))
                              FROM SimTramite t
                              JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
                              WHERE
                                 p.uIdPersona != '00000000-0000-0000-0000-000000000000'
                                 AND t.sNumeroTramite = f.[Número Trámite]
                           ),
                           'No registra beneficiario'
                        )
      
   )
FROM #tmp_tramites_final f


SELECT COUNT(1)
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'P'
   AND t.nIdTipoTramite = 58


-- 
-- dd21647a-a55a-46b3-8d65-9d0a4501699d

SELECT * 
FROM SimTramite t 
WHERE t.sNumeroTramite = '00CC01714'

SELECT * 
FROM SimPersona p
WHERE
   p.uIdPersona = 'dd21647a-a55a-46b3-8d65-9d0a4501699d'


SELECT * 
FROM SimTramite t
WHERE t.uIdPersona = 'dd21647a-a55a-46b3-8d65-9d0a4501699d'


SELECT * 
FROM SimPersona p
WHERE p.sPaterno = 'NO DEFINIDO'



/* → Usuario con mayor flujo migratorio:
      - a96e9b4c-76b3-46b6-a97f-0805e3bcaf73
      - 99700bc9-d52b-4c07-95a8-d9121dcc0301
      - e6440fea-5509-498c-aec7-4bd14dc95578
*/


SELECT
   mm.uIdPersona,
   mm.dFechaControl,
   mm.sTipo,
   [dFechaControl(Lag)] = LAG(mm.dFechaControl) OVER (PARTITION BY mm.uIdPersona ORDER BY mm.sIdMovMigratorio),
   [dFechaControl(First)] = FIRST_VALUE(mm.dFechaControl) OVER (PARTITION BY mm.uIdPersona ORDER BY mm.sIdMovMigratorio),
   [dFechaControl(Last)] = LAST_VALUE(mm.dFechaControl) OVER (
                                                                  PARTITION BY mm.uIdPersona 
                                                                  ORDER BY mm.sIdMovMigratorio
                                                                  RANGE BETWEEN 
                                                                  UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                            )
FROM SimMovMigra mm
WHERE
   mm.uIdPersona = 'a96e9b4c-76b3-46b6-a97f-0805e3bcaf73'
ORDER BY mm.sIdMovMigratorio ASC
