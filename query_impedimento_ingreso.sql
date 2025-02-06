USE SIM
GO

-- MAR ↔ MARRUECOS ↔ MARROQUI

-- 1. DNV
/*
   ╔ bActivo
   -- 0 → Habilitada
   -- 1 → Inhabilitada */
SELECT

   [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
   [Nombre] = dnv.sNombre,
   [Paterno] = dnv.sPaterno,
   [Materno] = dnv.sMaterno,
   [Sexo] = dnv.sSexo,
   [Documento] = dnv.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', dnv.sNumDocIdentidad),
   [Fecha Nacimiento] = dnv.dFechaNacimiento,
   [Pais Nacionalidad] = dnv.sIdPaisNacionalidad,
   [Fecha Emisión] = di.dFechaEmision,
   [Motivo] = mi.sDescripcion,
   [Tipo Alerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
   [Observaciones] = dnv.sObservaciones,
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado')

FROM SimPersonaNoAutorizada dnv
JOIN SimDocInvalidacion di ON dnv.nIdDocInvalidacion = di.nIdDocInvalidacion
JOIN SimMotivoInvalidacion mi ON dnv.sIdMotivoInv = mi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
WHERE
   dnv.bActivo = 1 -- Inhabilitada
   -- AND stt.sDescripcion = 'ALERTA ES RESTRICTIVA'
   AND dnv.sIdPaisNacionalidad = 'MAR'
   AND dnv.sObservaciones LIKE '%impedimento%ingreso%'



-- 2. Impedimiento
SELECT 
   p.uIdPersona,   
   [Nombre] = p.sNombre,
   [Paterno] = p.sPaterno,
   [Materno] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Pais Nacionalidad] = i.sIdPaisNacionalidad,
   [Documento] = i.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', i.sNumeroDoc),
   [Fecha Emisión] = i.dFecha_InadE_ImpedS,
   [Motivo] = mie.sMotivoInadmisionEntradaExt,
   [Observaciones] = i.sObservaciones,
   [Estado] = ri.sEstado

FROM SimInadmiEntraImpediSali i
JOIN SimPersona p ON i.uIdPersona = p.uIdPersona
JOIN SimRegMotivosImpediEntraSali ri ON i.nId_InadE_ImpedS = ri.nId_InadE_ImpedS
JOIN SimMotivoInadmiEntExtMovMig mie ON ri.nIdMotivoInadmisionEntradaExt = mie.nIdMotivoInadmisionEntradaExt
WHERE
   i.bAnulado = 0
   AND i.sIdPaisNacionalidad = 'MAR'


--3. RQ
SELECT 
   r2.sEstadoRq,
   COUNT(1)
FROM (

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

) r2
GROUP BY r2.sEstadoRq

   r2.sEstadoRq


   AND r.sIdPaisNacionalidad = 'MAR'


/*
116481802
1164M1M02
221036071
40714627
5668449
6688858*/

/*
0cb2ac7e-9770-4083-89d3-f1ae9c8dc98a
399adde3-e90b-4ac6-9d8c-d86de0a8c105
b0aaa0dd-eddf-4ddb-8777-ad085c9938ea*/

SELECT
   mm.*
FROM SimMovMigra mm
WHERE
   mm.uIdPersona = '0cb2ac7e-9770-4083-89d3-f1ae9c8dc98a'


