USE Movies
GO

-- ░ a) Ejercicio que involucre crear una view donde consoliden la información de 3 o más tablas con left o inner join (2 puntos).
--=========================================================================================================================================================
CREATE OR ALTER VIEW dbo.view_Peliculas
AS
SELECT 
	m.title,
	m.popularity,
	m.vote_average,
	[runtime] = CONCAT(m.runtime, ' min.'),
	l.language_name,
	pc.company_name,
	ct.country_name
FROM [dbo].[movie] m
JOIN [dbo].[movie_languages] lm ON m.movie_id = lm.movie_id
JOIN [dbo].[language] l ON lm.language_id = l.language_id
JOIN [dbo].[movie_company] mc ON m.movie_id = mc.movie_id
JOIN [dbo].[production_company] pc ON mc.company_id = pc.company_id
JOIN [dbo].[production_country] pct ON m.movie_id = pct.movie_id
JOIN [dbo].[country] ct ON pct.country_id = ct.country_id

-- Test ...
SELECT * FROM dbo.view_Peliculas
--=========================================================================================================================================================


-- ░ b) 2 ejercicios que involucren CREATE OR ALTER PROCEDURE. deben usar en alguno de los problemas: select, insert, update, delete (3.5 puntos).
--=========================================================================================================================================================
-- b.1: Buscar pelicuas por titulo ...
CREATE OR ALTER PROCEDURE usp_BuscarPelicula
(
	@nameMovie VARCHAR(255)
)
AS
BEGIN 
	SELECT p.* FROM dbo.view_Peliculas p
	WHERE
		p.title LIKE '%' + @nameMovie + '%'
END

-- Test ...
EXEC usp_BuscarPelicula 'ramb'

-- b.2: Eliminar pelicula menos popular ...
CREATE OR ALTER PROCEDURE usp_EliminarPeliculaMenosPupular
AS
BEGIN 
	SET NOCOUNT ON

	DECLARE @idMovieToDelete INT = (SELECT TOP 1 m.movie_id FROM [dbo].[movie] m 
							        ORDER BY m.popularity ASC)

	BEGIN TRY
		BEGIN TRAN

		DELETE FROM dbo.movie_languages
		WHERE movie_id = @idMovieToDelete

		DELETE FROM dbo.movie_cast
		WHERE movie_id = @idMovieToDelete

		DELETE FROM dbo.movie_crew
		WHERE movie_id = @idMovieToDelete

		DELETE FROM dbo.movie_genres
		WHERE movie_id = @idMovieToDelete

		DELETE FROM dbo.production_country
		WHERE movie_id = @idMovieToDelete

		DELETE FROM dbo.movie
		WHERE movie_id = @idMovieToDelete

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
		ROLLBACK TRAN
	END CATCH
END

-- Test ...
EXEC usp_EliminarPeliculaMenosPupular
--=========================================================================================================================================================

-- ░ c) 1 ejercicio que tengan TRIGGERS Update, Delete, Insert (3.5 puntos).
--=========================================================================================================================================================

-- c.1: Crear tabla, para insertar las peliculas eliminadas ...
SELECT TOP 0 * INTO DeletedMovies FROM dbo.movie

-- c.2: ...
CREATE OR ALTER TRIGGER dbo.tg_GuardarPeliculasEliminadas
ON [dbo].[movie]
FOR DELETE
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRAN

		INSERT INTO DeletedMovies
			SELECT * FROM Deleted m

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
		ROLLBACK TRAN
	END CATCH
END

-- Test ...
EXEC usp_EliminarPeliculaMenosPupular
SELECT * FROM dbo.DeletedMovies
--=========================================================================================================================================================

-- ░ d)	1 ejercicio que tenga cursores (2 puntos).
--=========================================================================================================================================================
DECLARE @titulo VARCHAR(255) = '',
		@titulos VARCHAR(MAX) = '',
		@nro INT = 0

DECLARE Peliculas CURSOR 
FOR SELECT 
		m.title
	FROM dbo.movie m
OPEN Peliculas

FETCH NEXT FROM Peliculas INTO @Titulo

WHILE @@fetch_status = 0
BEGIN
	SET	@nro = @nro + 1
    SET @titulos = CONCAT(@titulos, @nro, '. ', @titulo, '; ')

    FETCH NEXT FROM Peliculas INTO @titulo
END

CLOSE Peliculas
DEALLOCATE Peliculas

SELECT @titulos AS [Título Películas]
--=========================================================================================================================================================


-- ░ e)	1 ejercicio que tenga funciones (2 puntos).
--=========================================================================================================================================================
CREATE OR ALTER FUNCTION [dbo].ufn_RemplazarMultEspaciosPorEspacio
(
    @texto VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

	DECLARE @nuevoTexto VARCHAR(MAX) = ''

	SET @nuevoTexto = REPLACE(@texto, ' ', '<>')
	SET @nuevoTexto = REPLACE(@nuevoTexto, '><', '')
	SET @nuevoTexto = REPLACE(@nuevoTexto, '<>', ' ')
    
	-- Final ...
	RETURN @nuevoTexto	

END

-- Test ...
SELECT dbo.ufn_RemplazarMultEspaciosPorEspacio('Hola  este es un               texto  de prueba.')

--=========================================================================================================================================================

-- ░ f)	1 ejercicio que tenga begin try begin catch --begin transaction commit transaction rollback (2 puntos).
--=========================================================================================================================================================
BEGIN TRY
	DECLARE @idMovie INT = 100

	BEGIN TRAN

	DELETE FROM dbo.movie_languages
	WHERE movie_id = @idMovie

	DELETE FROM dbo.movie_cast
	WHERE movie_id = @idMovie

	DELETE FROM dbo.movie_crew
	WHERE movie_id = @idMovie

	DELETE FROM dbo.movie_genres
	WHERE movie_id = @idMovie

	DELETE FROM dbo.production_country
	WHERE movie_id = @idMovie

	IF EXISTS(SELECT 1 FROM DeletedMovies)
	BEGIN
		INSERT INTO DeletedMovies
			SELECT * FROM movie m WHERE m.movie_id = @idMovie
	END

	DELETE FROM dbo.movie
	WHERE movie_id = @idMovie

	COMMIT TRAN

END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN
END CATCH
--=========================================================================================================================================================
