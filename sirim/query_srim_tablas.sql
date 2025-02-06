--> 1. RimRNAuditoriaControlMigratorio
-- =================================================================================================================================
EXEC sp_help RimRNAuditoriaControlMigratorio
DROP TABLE IF EXISTS RimRNAuditoriaControlMigratorio
CREATE TABLE RimRNAuditoriaControlMigratorio
(
   -- Control
   uIdPersona UNIQUEIDENTIFIER,
   sIdMovMigratorio CHAR(14),
   dFechaControl DATETIME,
   sNombres VARCHAR(80),
   sTipo CHAR(1),
   nIdCalidad INT,
   sCalidad VARCHAR(50),
   sIdPaisNacionalidad CHAR(3),
   sIdDocumento CHAR(3),
   sNumeroDoc VARCHAR(25),
   sIdPaisMov CHAR(3),
   nPermanencia INT,

   sIdModuloDigita CHAR(7) NULL,
   sIdViaTransporte CHAR(1) NULL,
   nIdTransportista INT NULL,
   sIdProfesion CHAR(3) NULL,

   -- Persona
   sNombre VARCHAR(60),
   sPaterno VARCHAR(40),
   sMaterno VARCHAR(40),
   sSexo CHAR(1),
   dFechaNacimiento DATETIME,

   -- Itinerario
   sIdItinerario CHAR(12),
   dFechaProgramada DATETIME,
   sTipoMovimiento CHAR(1),
   nCantidadMov INT,
   sNumeroNave VARCHAR(20),

   nIdTransportistaItinerario INT,
   sIdPaisMovItinerario CHAR(3),

   -- Operador digita
   sLoginOpeDigita VARCHAR(20),
   sNombreOpeDigita VARCHAR(40),

   -- Dep
   sIdDependencia CHAR(3),
   sIdJefatura VARCHAR(6),

   -- Aux
   sDimension VARCHAR(255),
   sCamposErrCsv VARCHAR(1000),

   sTabla VARCHAR(80),
   nIdProceso INT,

   -- jDatosAux
   jDatosDuplicados VARCHAR(8000)

   CONSTRAINT PK_primaryKeyName PRIMARY KEY CLUSTERED (sIdMovMigratorio) 
)


-- Index
/* CREATE UNIQUE CLUSTERED INDEX uix_RimRNAuditoriaControlMigratorio 
   ON RimRNAuditoriaControlMigratorio(sIdMovMigratorio) */

/* 
   ALTER TABLE RimRNAuditoriaControlMigratorio
      ADD jDatosDuplicados TEXT NULL 

   ALTER TABLE RimRNAuditoriaControlMigratorio
      ALTER COLUMN jDatosDuplicados VARCHAR(8000) NULL 

   ALTER TABLE RimRNAuditoriaControlMigratorio
      ADD 
         sIdPaisMovItinerario CHAR(3)
*/

SELECT TOP 10 * FROM RimRNAuditoriaControlMigratorio
SELECT TOP 10 * FROM SIM.dbo.SimItinerario
EXEC sp_help SimItinerario


-- Test
/* 
SELECT TOP 10 * FROM RimRNAuditoriaControlMigratorio a
WHERE a.jDatosDuplicados IS NOT NULL 
*/


-- =================================================================================================================================