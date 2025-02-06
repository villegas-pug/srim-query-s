USE BD_SIRIM
GO

CREATE OR ALTER PROCEDURE usp_Rim_RN_ListaHallazgosPorPaginacion
(
   @idJefatura CHAR(15),
   @currentPage INT,
   @recordsByPages INT,
   @fecIni DATE,
   @fecFin DATE
)
AS
BEGIN

      -- Dep's
      DECLARE @skypPages INT = (@currentPage - 1) * @recordsByPages,
              @totalRows BIGINT = 0
      -- 1
      DROP TABLE IF EXISTS #tmp_by_jjzz
      SELECT 
         [uIdPersona] = a.uIdPersona,
         [sIdMovMigratorio] = a.sIdMovMigratorio,
         [dFechaControl] = CONVERT(VARCHAR(19), a.dFechaControl, 120),
         [sNombres] = a.sNombres,
         [sTipo] = a.sTipo,
         [nIdCalidad] = a.nIdCalidad,
         [sCalidad] = a.sCalidad,
         [sIdPaisNacionalidad] = a.sIdPaisNacionalidad,
         [sIdDocumento] = a.sIdDocumento,
         [sNumeroDoc] = a.sNumeroDoc,
         [sIdPaisMov] = a.sIdPaisMov,
         [nPermanencia] = a.nPermanencia,
         [sIdModuloDigita] = a.sIdModuloDigita,
         [sIdViaTransporte] = a.sIdViaTransporte,
         [nIdTransportista] = a.nIdTransportista,
         [sIdProfesion] = a.sIdProfesion,
         [sNombre] = a.sNombre,
         [sPaterno] = a.sPaterno,
         [sMaterno] = a.sMaterno,
         [sSexo] = a.sSexo,
         [dFechaNacimiento] = CONVERT(DATE, a.dFechaNacimiento),
         [sIdItinerario] = a.sIdItinerario,
         [dFechaProgramada] = CONVERT(VARCHAR(19), a.dFechaProgramada, 120),
         [sTipoMovimiento] = a.sTipoMovimiento,
         [nCantidadMov] = a.nCantidadMov,
         [sNumeroNave] = a.sNumeroNave,
         [nIdTransportistaItinerario] = a.nIdTransportista,
         [sIdPaisMovItinerario] = a.sIdPaisMov,
         [sLoginOpeDigita] = a.sLoginOpeDigita,
         [sNombreOpeDigita] = a.sNombreOpeDigita,
         [sIdDependencia] = a.sIdDependencia,
         [sIdJefatura] = a.sIdJefatura,
         [sDimension] = a.sDimension,
         [sCamposErrCsv] = a.sCamposErrCsv,
         [sTabla] = a.sTabla,
         [nIdProceso] = a.nIdProceso,
         [jDatosDuplicados] = a.jDatosDuplicados
         INTO #tmp_by_jjzz
      FROM RimRNAuditoriaControlMigratorio a
      WHERE 
         a.sIdDependencia IN (
                                 SELECT j.sIdDependencia 
                                 FROM RimRNJefaturaZonal j 
                                 WHERE j.sIdJefatura = @idJefatura
                              )
         AND a.dFechaControl BETWEEN CONCAT(@fecIni, ' 00:00:00.000') AND CONCAT(@fecFin, ' 23:59:59.999')
         
         -- Borrar
         -- AND a.sCamposErrCsv LIKE '%RN00196%RN00189%'

      CREATE NONCLUSTERED INDEX ix_tmp_by_jjzz 
         ON #tmp_by_jjzz(dFechaControl)

      -- Total pag's
      SET @totalRows = (SELECT COUNT(1) FROM #tmp_by_jjzz)

      -- 2
      SELECT 
         f.*,
         [nTotalRows] = @totalRows
      FROM #tmp_by_jjzz f
      ORDER BY
         f.dFechaControl DESC
      OFFSET @skypPages ROWS 
      FETCH FIRST @recordsByPages ROWS ONLY

      -- cleanup
      DROP TABLE IF EXISTS #tmp_by_jjzz

END

-- Test:
-- Consistencia, Unicidad
EXEC usp_Rim_RN_ListaHallazgosPorPaginacion 'JZCALL', 1, 20, '2024-09-12', '2024-09-12'

SELECT * 
FROM RimRNAuditoriaControlMigratorio a
WHERE a.sIdMovMigratorio = '2024AI06031049'

EXEC sp_help RimRNAuditoriaControlMigratorio