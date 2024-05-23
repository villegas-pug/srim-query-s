USE [NEPTUNO]
GO

/*» ELABORAR 4 EJERCICIOS QUE CONTENGAN:
=======================================================================================================================================================*/
-- 1. EJERCICIO QUE TENGA TRIGGERS UPDATE, DELETE, INSERT.

-- 1.1: Crear tabla, para guardar LOG'S ...
DROP TABLE IF EXISTS LogPedidos
SELECT TOP 0 * INTO LogPedidos FROM [dbo].[Detalles de pedidos]

-- 1.2: Trigger para guardar el detalle del pedido eliminado ...
CREATE TRIGGER trg_GuardarAlEliminarEnLogPedidos 
ON [dbo].[Pedidos] 
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON

	DECLARE @idPedido INT = (SELECT v.IdPedido FROM DELETED v)

	INSERT INTO LogPedidos
		SELECT * FROM [Detalles de pedidos] dp
		WHERE dp.IdPedido = @idPedido

END

-- Test: ...
DELETE FROM Pedidos WHERE IdPedido = 10248
SELECT * FROM LogPedidos

-- 2. EJERCICIO QUE TENGA CURSORES: Calcular el total de la ventas ...
DECLARE @totalVentas MONEY = 0.0,
		@precioUnidad MONEY = 0.0,
	    @cantidad TINYINT = 0
DECLARE TotalVentas CURSOR 
FOR SELECT 
		dp.Cantidad, 
		dp.PrecioUnidad
	FROM [Detalles de pedidos] dp
OPEN TotalVentas

FETCH NEXT FROM TotalVentas INTO @cantidad, @precioUnidad

WHILE @@fetch_status = 0
BEGIN
    SET @totalVentas = @totalVentas + (@cantidad * @precioUnidad)

    FETCH NEXT FROM TotalVentas INTO @cantidad, @precioUnidad
END
CLOSE TotalVentas
DEALLOCATE TotalVentas

SELECT @totalVentas AS TotalVentas

-- 3. EJERCICIO QUE TENGA FUNCIONES: Función para capitalizar textos.
CREATE OR ALTER FUNCTION uf_Capitalizar
(
    @texto VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

	DECLARE @restoTexto VARCHAR(MAX) = CONCAT(@texto, ' '),
			@textoCapitalizado VARCHAR(MAX) = '',
			@palabra VARCHAR(MAX) = '',
			@palabraCapitalizada VARCHAR(MAX) = ''

	WHILE PATINDEX('% %', @restoTexto) > 0
	BEGIN
		SET @palabra = SUBSTRING(@restoTexto, 1, CHARINDEX(' ', @restoTexto) - 1)
		SET @palabraCapitalizada = UPPER(LEFT(@palabra, 1)) + SUBSTRING(@palabra, 2, LEN(@palabra))
		SET @textoCapitalizado = CONCAT(@textoCapitalizado, ' ', @palabraCapitalizada)
		SET @restoTexto = LTRIM(REPLACE(@restoTexto, @palabra, ''))
	END

    RETURN @textoCapitalizado

END

-- Test ...
SELECT dbo.uf_Capitalizar('hola como estas')

-- 4. EJERCICIO QUE TENGA BEGIN TRY BEGIN CATCH | BEGIN TRANSACTION COMMIT TRANSACTION ROLLBACK.
-- 4.1: Eliminar clientes que no han realizado pedidos ...

BEGIN TRY

	BEGIN TRAN

	DELETE c
	FROM Clientes c
	LEFT JOIN Pedidos p ON c.IdCliente = p.IdCliente
	WHERE
		p.IdPedido IS NULL

	COMMIT TRAN

END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH

-- Clientes que no realizaron pedidos ...
SELECT * FROM Clientes c
WHERE
	NOT EXISTS (
		SELECT 1 FROM Pedidos p WHERE p.IdCliente = c.IdCliente
	)
--=======================================================================================================================================================*/