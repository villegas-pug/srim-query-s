USE CITASPAS
GO

-- RC00002
-- Se establece como regla de calidad que cada cita para pasaportes electrónicos sea única y no pueda duplicarse con la misma fecha y hora para un mismo ciudadano.
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