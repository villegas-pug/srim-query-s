USE SIM
GO

-- Interpol
select 
   r.ID id,
   [sTipoMovimiento] = m.sTipo, 
   [sNombres] = r.sNombre, 
   [sPrimerApellido] = r.sPaterno, 
   [sSegundoApellido] = r.sMaterno, 
   [sFechaNacimiento] = r.dFechaNacimiento, 
   [sNacionalidad] = m.sIdPaisNacionalidad,
   [sTipoAlerta] = 'INTERPOL',  
   [sMotivoAlerta] = '', 
   [sFechaAlerta] = dInicio, 
   [sObservaciones] = r.sMensaje
   
from [dbo].[SimRQAudit] r
inner join SimMovMigra m  on m.uIdPersona  = r.uIdPersona 
                          and m.sTransaccionRQ = r.sTransaccion
where
   r.sRespuestaRQAuto  = '1' and r.uTranInterPer is not null
   AND m.uIdPersona = 'ea0d03ca-d0f8-4d4f-84c6-cd41381cc503'


-- Alerta RQ

select
   r.ID id,
   m.sTipo sTipoMovimiento, 
   r.sNombre sNombres, 
   r.sPaterno sPrimerApellido, 
   r.sMaterno sSegundoApellido, 
   r.dFechaNacimiento sFechaNacimiento, 
   -- p.sNombre sNacionalidad,
   'RQ' sTipoAlerta,  
   '' sMotivoAlerta, 
   dInicio sFechaAlerta,
   r.sMensaje sObservaciones
   /* u.sLogin  sUsuaruo,
   d.sNombre sPuestoControl,
   doc.sIdDocumento,
   doc.sNumero */
from [dbo].[SimRQAudit] r
inner join SimMovMigra m  on m.uIdPersona  = r.uIdPersona and m.sTransaccionRQ = r.sTransaccion
/* inner join SimSesion ss  on ss.nIdSesion  = r.sIdSesion 
inner join SimOperador  o on o.nIdOperador  = ss.nIdOperador 
inner join SimUsuario u on u.nIdOperador  = o.nIdOperador 
left join SimPais  p on p.sIdPais = m.sIdPaisNacionalidad 
left join SimDependencia d on d.sIdDependencia  = m.sIdDependencia
inner join SimDocPersona doc on r.uIdPersona = doc.uIdPersona */
where
   r.sRespuestaRQAuto  = '1'
   AND m.uIdPersona = 'ea0d03ca-d0f8-4d4f-84c6-cd41381cc503' -- AMBROSIO FLORES MONTUFAR, DAVID DANIEL

		

SELECT TOP 10 * 
FROM SimSistPersonaDatosAdicionalPDA sp
WHERE
   sp.sNomBeneficiario LIKE '%nei%'
   AND sp.sPriApeBeneficiario LIKE 'TOVAR'
   AND sp.sSegApeBeneficiario LIKE 'ROSILLO'
ORDER BY sp.dFechaRegistro DESC


SELECT * 
FROM SimTipoTramite tt WHERE tt.nIdTipoTramite IN (99, 109)