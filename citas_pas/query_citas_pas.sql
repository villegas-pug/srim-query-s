USE CITASPAS
GO

-- Caso 2: Citas ...

-- 2.1: Igual fecha y hora cita ...
SELECT
   [Nombres] = c1.sNomBeneficiario,
   [Apellido 1] = c1.sPriApeBeneficiario,
   [Apellido 2] = c1.sSegApeBeneficiario,
   [Sexo] = '-',
   [Fecha Nacimiento] = c1.dFecNacBeneficiario,

   -- Aux
   [Id Cita Web] = c1.nIdCitaWebNacional,
   [Digito Verificación Banco] = c1.sDigVerRecBanco,
   [Fecha Cita] = c1.dFechaCita,
   [Hora Cita] = c1.sDescFilaHoraria,
   [Cita Postergada] = IIF(c1.bPostergado = 1, 'Si', 'No'),
   [Cita Anulada] = IIF(c1.bAnulado = 1, 'Si', 'No'),
   [Cita Activa] = IIF(c1.bActivo = 1, 'Si', 'No'),

   -- Aux 2
   c1.sNumDocBeneficiario,
   c1.dFecNacBeneficiario

FROM (

   SELECT
      scn.*,
      [nDupl] = COUNT(1) OVER (PARTITION BY CAST(scn.dFechaCita AS DATE), scn.sDescFilaHoraria, scn.sNumDocBeneficiario)
   FROM SimCitaWebNacional scn
   WHERE
      scn.bPostergado = 0
      AND scn.bAnulado = 0
      AND scn.bActivo = 1
      AND scn.dFecAnulacion = '1900-01-01 00:00:00.000'

) c1
WHERE
   c1.nDupl >= 2
ORDER BY
   c1.sNumDocBeneficiario

-- Test ...
SELECT TOP 1 * FROM SimCitaWebNacional scn

-- 2.2: Igual fecha y diferente hora cita ...
SELECT 

   [Nombres] = c2.sNomBeneficiario,
   [Apellido 1] = c2.sPriApeBeneficiario,
   [Apellido 2] = c2.sSegApeBeneficiario,
   [Sexo] = '-',
   [Fecha Nacimiento] = c2.dFecNacBeneficiario,

   -- Aux
   [Id Cita Web] = c2.nIdCitaWebNacional,
   [Digito Verificación Banco] = c2.sDigVerRecBanco,
   [Fecha Cita] = c2.dFechaCita,
   [Hora Cita] = c2.sDescFilaHoraria,
   [Cita Postergada] = IIF(c2.bPostergado = 1, 'Si', 'No'),
   [Cita Anulada] = IIF(c2.bAnulado = 1, 'Si', 'No'),
   [Cita Activa] = IIF(c2.bActivo = 1, 'Si', 'No')
   
FROM (

   SELECT
      c1.*,
      [nDupl_DiffDiaCita] = COUNT(1) OVER (PARTITION BY c1.sDescFilaHoraria, c1.sNumDocBeneficiario)
   FROM (

      SELECT
         scn.*,
         [nDupl] = COUNT(1) OVER (PARTITION BY CAST(scn.dFechaCita AS DATE), scn.sNumDocBeneficiario)
      FROM SimCitaWebNacional scn
      WHERE
         scn.bPostergado = 0
         AND scn.bAnulado = 0
         AND scn.bActivo = 1
         AND scn.dFecAnulacion = '1900-01-01 00:00:00.000'

   ) c1
   WHERE
      c1.nDupl >= 2

) c2
WHERE
   c2.nDupl_DiffDiaCita = 1
ORDER BY
   c2.sNumDocBeneficiario


-- 2.3: Test ...
SELECT
   c1.sNumDocBeneficiario,
   [sDocIdentidad_per] = (
 
                           SELECT
                              sper.sNumDocIdentidad
                           FROM SimRecibo sr
                           JOIN SimPagos sp ON sr.sCodRecibo = sp.sCodRecibo
                           JOIN SIM.dbo.SimTramite st ON sp.sNumeroTramite = st.sNumeroTramite
                           JOIN SIM.dbo.SimPersona sper ON st.uIdPersona = sper.uIdPersona
                           WHERE
                              sr.sNumeroDoc = c1.sNumDocBeneficiario
                              AND sr.sDigitoVerifica = c1.sDigVerRecBanco

                        )
FROM (

   SELECT
      scn.*,
      [nDupl] = COUNT(1) OVER (PARTITION BY DATEPART(yyyy, scn.dFechaCita), scn.sNumDocBeneficiario)
   FROM SimCitaWebNacional scn
   WHERE
      scn.bPostergado = 0
      AND scn.bAnulado = 0
      AND scn.bActivo = 1
      AND scn.dFechaCita >= '2023-01-01 00:00:00.000'
      AND scn.dFecAnulacion = '1900-01-01 00:00:00.000'

) c1
WHERE
   c1.nDupl >= 2

