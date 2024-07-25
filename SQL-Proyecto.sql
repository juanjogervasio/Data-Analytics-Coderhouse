USE Proyecto;
SELECT * FROM Matches;

/*Voy a crear tablas vacias para despues importar los datos
En cada caso especifico las PK y FK
*/
CREATE TABLE Penales (
	ID_match nvarchar(255) PRIMARY KEY,
	[date] date,
	home_team nvarchar(255),
	away_team nvarchar(255),
	winner nvarchar(255))

CREATE TABLE FIFA_Ranking (
	ID_ranking float PRIMARY KEY,
	[rank] float,
	country nvarchar(255),
	confederation nvarchar(255),
	rank_date date
--	FOREIGN KEY (country) REFERENCES Teams(Selecciones)	
	)

CREATE TABLE BallonDOr (
	ID_BallonDOr float PRIMARY KEY,
	[year] float,
	[rank] float,
	player nvarchar(255),
	nationality nvarchar(255)
--	FOREIGN KEY (nationality) REFERENCES Teams(Selecciones)
	)

/*Hasta acá va bien. Las tabla Teams ya la tenía de antes, con su
PK. La tabla Matches también, falta relacionarla con la de Penales*/
ALTER TABLE Matches
ADD FOREIGN KEY (ID_match) REFERENCES Penales(ID_match)
/*Me tira error. No sé por qué.

Ahora agrego los datos desde el Excel, importando desde Tasks
Anduvo bien, pero le tuve que quitar los FOREIGN KEYs
*/

ALTER TABLE FIFA_Ranking
ALTER COLUMN rank_date date;

SELECT * FROM Matches
WHERE goals > 5 AND
	  tournament <> 'Friendly';

/*Voy a volver a armar la tabla Matches, uniendo las dos
de locales y visitantes, especificando el ganador del partido*/

SELECT *
INTO new_matches
FROM (
	SELECT 
	t1.ID_match,
	t1.[date],
	t1.home_team AS team,
	t1.home_score AS goals,
		CASE
			WHEN t1.home_score > t2.away_score THEN t1.home_team
			WHEN t1.home_score < t2.away_score THEN t2.away_team
			ELSE 'Empate'
		END AS 'Winner',
	t1.tournament
	FROM Partidos_Local t1
	FULL JOIN Partidos_Visitante t2
		ON t1.ID_match = t2.ID_match
	UNION
	SELECT 
	t2.ID_match,
	t2.[date],
	t2.away_team AS team,
	t2.away_score AS goals,
		CASE
			WHEN t1.home_score > t2.away_score THEN t1.home_team
			WHEN t1.home_score < t2.away_score THEN t2.away_team
			ELSE 'Empate'
		END AS Winner,
	t2.tournament
	FROM Partidos_Local t1
	FULL JOIN Partidos_Visitante t2
		ON t1.ID_match = t2.ID_match
) AS new_matches;

ALTER TABLE new_matches
ADD ID int IDENTITY PRIMARY KEY;

/*Una lista de los torneos registrados*/
SELECT DISTINCT tournament FROM new_matches;

/*Conteo de partidos ganados por cada selección*/
SELECT 
Winner,
count(Winner) AS contador
FROM new_matches
GROUP BY Winner
ORDER BY contador DESC;

SELECT 
t1.*,
t2.*
FROM new_matches t1
INNER JOIN penales t2
	ON t1.ID_match = t2.ID_match
WHERE t1.Winner = 'Empate'
ORDER BY t1.[date] DESC

SELECT * FROM new_matches
ORDER BY [date];

SELECT DISTINCT 
ID_match,
Winner
FROM new_matches;

SELECT * FROM Matches;

SELECT * FROM Partidos_Local;

SELECT * FROM new_matches
WHERE year([date])=1986
	AND
	tournament LIKE '%World%';

SELECT * FROM Ranking_FIFA
WHERE pais is null