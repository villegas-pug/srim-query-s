USE SIM
GO

-- jose jesus mavares rojano | CI 18793768 | VEN

-- 1. SimDocPersona
SELECT sdp.* FROM SimDocPersona sdp
WHERE
   -- sdp.sIdDocumento = 'CI'
   sdp.sNumero = '18793768'


-- 2. SimPersona
SELECT sper.sIdPaisNacionalidad, sper.* FROM SimPersona sper
WHERE 
   -- 1
   -- sper.sNombre LIKE '%jose%'
   /* sper.sPaterno LIKE '%mava%'
   AND sper.sMaterno LIKE '%rojan%' */

   -- 2
   -- sper.sNombre LIKE 'jose jesus'
   sper.sMaterno LIKE '%mava%'
   AND sper.sPaterno LIKE '%roj%'

   -- 2
   /* DIFFERENCE(sper.sNombre, 'jose jesus') = 4
   AND DIFFERENCE(sper.sPaterno, 'mavares') = 4
   -- AND DIFFERENCE(sper.sMaterno, 'rojano') >= 3 */


SELECT 
   sapda.uIdPersona,
   sapda.sNomBeneficiario,
   sapda.sPriApeBeneficiario,
   sapda.sSegApeBeneficiario,
   sapda.dFecNacBeneficiario,
   sapda.sIdPaisDocBeneficiario,
   sdpda.sIdUbigeoBeneficiario,
   sdpda.sDireccionBeneficiario,
   sapda.dFechaHoraAud
FROM [dbo].[SimSistPersonaDatosAdicionalPDA] sapda
JOIN [dbo].[SimDireccionPDA] sdpda ON sapda.nIdCitaVerifica = sdpda.nIdCitaVerifica
                                      AND sapda.nIdTipoTramite = sdpda.nIdTipoTramite
WHERE
   -- sapda.sNomBeneficiario LIKE '%jose%'
   /* sapda.sPriApeBeneficiario LIKE 'mav%'
   AND sapda.sSegApeBeneficiario LIKE 'roj%' */

   sapda.sPriApeBeneficiario LIKE 'roj%'
   AND sapda.sSegApeBeneficiario LIKE 'mav%'