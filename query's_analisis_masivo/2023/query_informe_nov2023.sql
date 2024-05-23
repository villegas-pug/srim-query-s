USE SIM
GO

-- Caso 1: Campo `sNombres` null o vacio en SIM.dbo.SimMovMigra ...
SELECT
   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux ...
   smm.sIdMovMigratorio,
   smm.uIdPersona,
   [sNombres_MovMigra] = smm.sNombres,
   [sNombres_SimPersona] = LTRIM(RTRIM(CONCAT(sper.sPaterno, ' ', sper.sMaterno, ' ', sper.sNombre)))
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.dFechaControl >= '2011-01-01 00:00:00.000'
   AND (smm.uIdPersona != '00000000-0000-0000-0000-000000000000' AND smm.uIdPersona IS NOT NULL)
   AND (smm.sNombres IS NULL OR smm.sNombres = '')

-- Caso 2: Trámites con uIdPersona `00000000-0000-0000-0000-000000000000` ...
SELECT
   -- 1
   [Nombres] = '',
   [Apellido 1] = '',
   [Apellido 2] = '',
   [Sexo] = '',
   [Fecha Nacimiento] = '',

   -- Aux ...
   st.sNumeroTramite,
   st.uIdPersona,
   [sTipoTramite] = stt.sDescripcion,
   sti.sEstadoActual
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   st.bCancelado = 0
   AND st.dFechaHora >= '2016-01-01 00:00:00.000'
   AND st.uIdPersona = '00000000-0000-0000-0000-000000000000'

-- Test ...

-- Caso 3: Trámites de inmigración en estado `P`, con ultima etapa ENTREGA DE CARNÉ finalizada y sin reconsideracion ...
/*
   ░ Ultima etapa por tipo de trámite ...

      → 58  : 17 ↔ ENTREGA DE CARNET EXTRANJERIA
      → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
      → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P. */

SELECT * FROM SimTipoTramite stt
WHERE 
   stt.nIdTipoTramite IN (58, 113, 126)

SELECT
   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   st.uIdPersona,
   [dFechaExpendiente] = st.dFechaHora,
   st.sNumeroTramite,
   sti.sEstadoActual,
   [sTipoTramite] = stt.sDescripcion
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   st.bCancelado = 0
   -- AND st.dFechaHora >= '2016-01-01 00:00:00.000'
   AND st.dFechaHora >= '2021-08-01 00:00:00.000' -- A partir de esta fecha la ultima etapa de CCM es `ENTREGA DE CARNET EXTRANJERIA` ...
   AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND st.nIdTipoTramite IN (58, 113, 126)
   AND sti.sEstadoActual = 'P'
   AND EXISTS (

      SELECT
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (
                                 -- → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 -- → 58  : 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                 -- → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                 SELECT t.nIdEtapaFinal FROM (
                                    VALUES
                                       (58, 17),
                                       (113, 63),
                                       (126, 63),
                                       (126, 80)
                                 ) AS t([nIdTipoTramite], [nIdEtapaFinal])
                                 WHERE
                                    t.nIdTipoTramite = st.nIdTipoTramite
                           )
         AND seti.sEstado = 'F'
         AND seti.bActivo = 1
   )
   AND NOT EXISTS (

      SELECT 
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
         AND seti.sEstado = 'I'
         AND seti.bActivo = 1
         
   )

-- Caso 4: Trámites de inmigración en estado `A`, sin ultima etapa ...
/*
   ░Ultima etapa por tipo de trámite ...

      → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P.
      → 58  : 17 ↔ ENTREGA DE CARNET EXTRANJERIA
      → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
      → 57  : 24 ↔ PAGOS, FECHA Y NRO RD.
      → 55  : 24 ↔ PAGOS, FECHA Y NRO RD. */

SELECT
   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   st.uIdPersona,
   [dFechaExpendiente] = st.dFechaHora,
   st.sNumeroTramite,
   sti.sEstadoActual,
   [sTipoTramite] = stt.sDescripcion
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   st.bCancelado = 0
   -- AND st.dFechaHora >= '2016-01-01 00:00:00.000'
   AND st.dFechaHora >= '2021-08-01 00:00:00.000' -- A partir de esta fecha la ultima etapa de CCM es `ENTREGA DE CARNET EXTRANJERIA` ...
   AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND st.nIdTipoTramite IN (58, 113, 126)
   AND sti.sEstadoActual = 'A'
   AND NOT EXISTS (

      SELECT
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (
                                 -- → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P.; 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                 -- → 58  : 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                 -- → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                 SELECT t.nIdEtapaFinal FROM (
                                    VALUES
                                       (58, 17),
                                       (113, 63),
                                       (126, 63),
                                       (126, 80)
                                 ) AS t([nIdTipoTramite], [nIdEtapaFinal])
                                 WHERE
                                    t.nIdTipoTramite = st.nIdTipoTramite
                           )
         AND seti.bActivo = 1
   )

-- Caso 5: Trámites de CPP y PTP entregados en estado pendiente(P) ...
SELECT 
   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   [dFechaExpendiente] = st.dFechaHora,
   st.sNumeroTramite,
   sti.sEstadoActual,
   [sTipoTramite] = stt.sDescripcion,
   [sEntregado] = IIF(sptp.bEntregado = 1, 'SI', 'NO')
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimCarnetPTP sptp ON st.sNumeroTramite = sptp.sNumeroTramite
WHERE
   st.bCancelado = 0
   AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND st.nIdTipoTramite IN (113, 126)
   AND sti.sEstadoActual = 'P'
   AND (sptp.bAnulado = 0 AND sptp.bImpreso = 1 AND sptp.bEntregado = 1)
   AND NOT EXISTS (

      SELECT
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (
                                 -- → 126 : 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 -- → 113 : 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                 SELECT t.nIdEtapaFinal FROM (
                                    VALUES
                                       (113, 63),
                                       (126, 63),
                                       (126, 80)
                                 ) AS t([nIdTipoTramite], [nIdEtapaFinal])
                                 WHERE
                                    t.nIdTipoTramite = st.nIdTipoTramite
                           )
         AND seti.sEstado = 'F'
         AND seti.bActivo = 1
   )


--
SELECT 
   /* [Tramite] = stt.sDescripcion,
   [Etapa] = se.sDescripcion  */
   stpa.*
FROM SimTramite st
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimTipoPagoAsociado stpa ON st.sNumeroTramite = stpa.sNumeroTramite
JOIN SimEtapaTipoTramite sett ON st.nIdTipoTramite = sett.nIdTipoTramite
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE
   st.sNumeroTramite = 'LM230092656'
ORDER BY
   sett.nSecuencia ASC



SELECT TOP 100 * FROM SimTipoPagoAsociado
SELECT TOP 100 * FROM SimPagoTramite
SELECT TOP 100 * FROM SimPagoTramitePlantilla

SELECT TOP 100 sdp.*
FROM SimDocPersona sdp



SELECT COUNT(1) FROM SimSistCitaWeb

SELECT TOP 100 sscw.* FROM SimSistCitaWeb sscw
ORDER BY
   sscw.dFechaCita DESC

SELECT 
   -- sccm.*
   st.*
   -- sti.*
FROM SimTramite st 
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
WHERE
   st.sNumeroTramite = 'LM230297500'

-- Visas agrupadas ...
SELECT * FROM SimBeneficiarioTramite st 
WHERE st.sNumeroTramite = 'LM220195457'

-- Tramites de SimBeneficiarioTramite ...
SELECT 
   stt.sDescripcion,
   [nTotal] = COUNT(1)
FROM SimBeneficiarioTramite sbt
JOIN SimTramite st ON st.sNumeroTramite = sbt.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
GROUP BY
   stt.sDescripcion
ORDER BY
   [nTotal] DESC

--
SELECT TOP 10 * FROM SimRegExtBeneficiarioAECID
SELECT TOP 10 * FROM SimBeneficiarioTramite


/* Snippet Generated Select with current selected text */
EXEC sp_help SimEtapaTramiteInm

SELECT 
   t.sDescripcion,
   t.nIdTipoTramite,
   [nTotal] = COUNT(1)
FROM (

   SELECT 
      seti.*,
      se.sDescripcion,
      st.nIdTipoTramite,
      [nFila] = ROW_NUMBER() OVER (PARTITION BY seti.sNumeroTramite ORDER BY seti.dFechaHoraInicio DESC)
   FROM SimEtapaTramiteInm seti
   JOIN SimTramite st ON seti.sNumeroTramite = st.sNumeroTramite
   JOIN SimEtapa se ON seti.nIdEtapa = se.nIdEtapa
   WHERE
      -- seti.sNumeroTramite = 'LM230256514'
      seti.sNumeroTramite IN (

         SELECT
            st.sNumeroTramite
         FROM SimTramite st
         WHERE
            st.bCancelado = 0
            AND st.dFechaHora >= '2016-01-01 00:00:00.000'
            AND st.uIdPersona = '00000000-0000-0000-0000-000000000000'
            
      )

) t
WHERE
   t.nFila = 1
GROUP BY
   t.sDescripcion, t.nIdTipoTramite
ORDER BY
   [nTotal] DESC


--
EXEC sp_help SimTipoTramite
SELECT 
   stt.*,
   [nOrden] = ROW_NUMBER() OVER (ORDER BY NEWID())
FROM SimTipoTramite stt

-- ntile
SELECT COUNT(1) FROM SimTipoTramite stt

SELECT * FROM (

   SELECT 
      stt.*,
      [nTile] = NTILE(4) OVER (ORDER BY NEWID())
   FROM SimTipoTramite stt

) tt
WHERE
   tt.nTile = 4



SELECT  
   TOP 10
   st.sNumeroTramite,
   [sTipoTramite] = stt.sDescripcion,
   [dFechaExpedienite] = st.dFechaHora
FROM SimTramite st
JOIN SImTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
WHERE
   st.bCancelado = 0
   AND sti.sEstadoActual = 'A'
   AND YEAR(st.dFechaHora) = 2023
   AND st.nIdTipoTramite = 58

SELECT  
   TOP 10
   st.sNumeroTramite,
   [sTipoTramite] = stt.sDescripcion,
   [dFechaExpedienite] = st.dFechaHora
FROM SimTramite st
JOIN SImTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
WHERE
   st.bCancelado = 0
   AND sti.sEstadoActual = 'A'
   AND YEAR(st.dFechaHora) = 2023
   AND st.nIdTipoTramite = 57

SELECT * FROM SimTipoTramite stt1
SELECT TOP 100 * FROM SimExpediente se

EXEC sp_help SimExpediente
-- JOIN SimTipoTramite stt2 