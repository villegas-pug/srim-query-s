--SELECT * FROM SimPersona sp
SELECT * FROM SimMovMigra smm
JOIN SimPersona sp ON smm.uIdPersona = sp.uIdPersona
JOIN SimOrdenPago sop ON smm.sIdMovMigratorio = sop.sIdMovMigratorio
WHERE
	sp.sNombre = 'YUXING'
	AND sp.sPaterno = 'HUANG'
ORDER BY smm.dFechaControl DESC


SELECT * FROM SimPConceptoPago scp WHERE scp.Descripcion LIKE '%Nacionalidad%'
SimOrdenPagoExon
SELECT TOP 10 * FROM SimOrdenPagoDocumento
SimPersona
SimMovMigra
SELECT TOP 10 * FROM SimOrdenPagoDetalle
SimPTipoPeriodo
SELECT * FROM SimMotivo
SELECT * FROM SimDocumento
SimMoneda

SELECT TOP 10 sm.*, scp.* FROM SimPConceptoPago scp
JOIN SimMotivo sm ON scp.nIdMotivo = sm.nIdMotivo

SELECT TOP 1 * FROM SimFraDeuParametros
SELECT TOP 1 * FROM SimFraDeuParametroAnio
SELECT TOP 1 * FROM SimFraDeuEvaluacion
SELECT TOP 1 * FROM SimFraDeuUITAnio
SELECT TOP 1 * FROM SimFraDeuRequisito
SELECT TOP 1 * FROM SimDocumentoExoMultaMigra
SELECT TOP 1 * FROM SimAgregadoDocExoMultaMigra
SELECT TOP 1 * FROM SimOrdenPagoCorreo

SELECT
	smm.dFechaControl,
	smm.sTipo,
	smm.sIdPaisNacionalidad,
	sop.nTotal,
	sopd.nImporte,
	sopd.sNumeroTramite,
	scp.Descripcion [sConceptoPago],
	sm.sDescripcion [sMotivo],
	stm.sDescripcion [sTipoMotivo]
FROM SimMovMigra smm
JOIN SimOrdenPago sop ON smm.sIdMovMigratorio = sop.sIdMovMigratorio
JOIN SimOrdenPagoDetalle sopd ON sop.nIdPago = sopd.nIdPago
JOIN SimPConceptoPago scp ON sopd.nIdConcepto = scp.IdConceptoPago
JOIN SimMotivo sm ON scp.nIdMotivo = sm.nIdMotivo
JOIN SimTipoMotivo stm ON sm.nIdTipoMotivo = stm.nIdTipoMotivo
WHERE
	--Perman. Irregular (Ant. DS 007-2017)
	-- 7 | Multa Ext.-Uso de más de una Nacionalidad por ingreso
	--sopd.nIdConcepto = 7

--SELECT * FROM SimPConceptoPago
--SELECT * FROM SimMotivo
--SELECT * FROM SimTipoMotivo

SELECT TOP 1000 * FROM SimOrdenPagoExon sope 
WHERE 
	--sope.sDescripcion LIKE '%nacion%'
	sope.nImporte = 230

