USE CITASPAS
GO

-- RC00003
-- 2.2: Igual fecha y diferente hora cita ...
-- Se establece como regla de calidad que cada cita para pasaportes electrónicos sea única y no pueda duplicarse con la misma fecha para un mismo ciudadano.
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