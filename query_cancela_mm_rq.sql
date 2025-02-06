USE SIM
GO

-- 1. Cancelación de movimiento migratorio
SELECT 
   mm.sIdMovMigratorio,
   mm.dFechaControl,
   mm.bAnulado,
   mm.sTipo,
   [sMotivoCancelación] = mt.sDescripcion
FROM SimMovMigra mm
JOIN SimCancelacionMov c ON mm.sIdMovMigratorio = c.sIdMovMigratorio
JOIN SimMotivoTramite mt ON c.nIdMotivoTramite = mt.nIdMotivoTramite

SELECT
   TOP 10
   mm.sObservaciones
FROM SimMovMigra mm
WHERE
   mm.bAnulado = 1

-- 2. RQ
SELECT

   -- mm.*,
   [Tipo Movimiento] = mm.sTipo, 
   [Nombres] = r.sNombre, 
   [Primer Apellido] = r.sPaterno, 
   [Segundo Apellido] = r.sMaterno, 
   [Fecha Nacimiento] = r.dFechaNacimiento, 
   [Nacionalidad] = p.sNombre,
   [Tipo Alerta] = 'RQ',
   [Fecha Alerta] = r.dInicio,
   [Observaciones] = r.sMensaje,
   [Usuario] = u.sLogin,
   [Puesto Control] = d.sNombre,
   [Documento] = mm.sIdDocumento,
   [Numero Documento] = mm.sNumeroDoc,
   mm.sEstadoRq
   
   /* [Documento] = dp.sIdDocumento,
   [Numero Documento] = dp.sNumero */

FROM SimRQAudit r
INNER JOIN SimMovMigra mm ON mm.uIdPersona = r.uIdPersona AND mm.sTransaccionRQ = r.sTransaccion
INNER JOIN SimSesion ss ON ss.nIdSesion = r.sIdSesion 
INNER JOIN SimOperador o ON o.nIdOperador = ss.nIdOperador 
INNER JOIN SimUsuario u ON u.nIdOperador = o.nIdOperador 
LEFT JOIN SimPais p ON p.sIdPais = mm.sIdPaisNacionalidad 
LEFT JOIN SimDependencia d ON d.sIdDependencia = mm.sIdDependencia
-- INNER JOIN SimDocPersona dp ON r.uIdPersona = dp.uIdPersona
WHERE
   r.sRespuestaRQAuto  = '1'


 
SELECT TOP 10 * FROM SimRQAudit a
ORDER BY a.dInicio DESC


SELECT
   r.*
FROM SimRQAudit r
INNER JOIN SimMovMigra mm ON mm.uIdPersona = r.uIdPersona AND mm.sTransaccionRQ = r.sTransaccion