USE SIM
GO


/*
   -- bActivo
	-- 0 → Habilitada
	-- 1 → Inhabilitada
=========================================================================================================================================================== */

-- 1: ...
   SELECT 

      -- [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
      [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
      [Nombre] = pna.sNombre,
      [Paterno] = pna.sPaterno,
      [Materno] = pna.sMaterno,
      [Sexo] = pna.sSexo,
      [Documento] = pna.sIdDocumento,
      [Num Doc Identidad] = CONCAT('''', pna.sNumDocIdentidad),
      [Fecha Nacimiento] = pna.dFechaNacimiento,
      [Pais Nacionalidad] = pna.sIdPaisNacionalidad,
      [Fecha Inicio Medida] = pna.dFechaInicioMedida,
      [Fecha Emisión] = di.dFechaEmision,
      [Fecha Recepción] = di.dFechaRecepcion,
      [Fecha Cancelación DNV] = pna.dFechaCancelacion,
      [Motivo] = mi.sDescripcion,
      [Tipo Alerta] = COALESCE(tt.sDescripcion, 'NO REGISTRA TIPO'),
      [Observaciones] = pna.sObservaciones,
      [Estado] = IIF(pna.bActivo = 1, 'Inhabilitado', 'Habilitado')

   FROM SimPersonaNoAutorizada pna
   RIGHT JOIN SimDocInvalidacion di ON pna.nIdDocInvalidacion = di.nIdDocInvalidacion
   LEFT JOIN SimMotivoInvalidacion mi ON pna.sIdMotivoInv = mi.sIdMotivoInv
   LEFT JOIN SimTablaTipo tt ON pna.sIdAlertaInv = tt.strequivalente
   WHERE
      pna.bActivo = 1 -- Inhabilitada


--========================================================================================================================================== */