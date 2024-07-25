/* PROYECTO VERSION 2 - Nuevas relaciones entre tablas

Voy a crear 6 tablas:
	SELECCIONES: una lista de los equipos
		PK: ID_team
	PARTIDOS: lista los partidos jugados por cada equipo. Aparece cada partido ocupando dos registros,
	uno por cada equipo que jugó
		PK: ID
		FK: ID_match (para PENALES)
		FK: team (para SELECCIONES)
		FK: tournament (para TORNEOS) 
	PENALES: lista los partidos definidos por penales y el ganador
		PK: ID_match
		FK: winner (para SELECCIONES)
	TORNEOS: lista los torneos y si fueron oficiales o amistosos
		PK: ID_cup
	FIFA_Ranking: lista el ranking mensual de cada equipo
		PK: ID_FIFA
		FK: country (para SELECCIONES)
	BALLON_DOR: lista jugadores nominados a Balón de Oro y su ranking cada año
		PK: ID_BDO
		FK: nationality (para SELECCIONES)
*/

CREATE DATABASE ProyectoV2;
USE ProyectoV2;

/* 1- SELECCIONES: lo armo y lo completo desde un Excel
*/
CREATE TABLE Selecciones (
	ID_pais float PRIMARY KEY,
	Selección nvarchar(255) NOT NULL
);
/*SUCCESS!*/

/* 2- PARTIDOS: lo armo desde la unión de dos tablas, Local y Visitante.
Primero armo esas dos, las completo desde un Excel y después construyo la nueva tabla
*/
/* Tabla Resultados LOCAL*/
CREATE TABLE [Local] (
	ID_partido nvarchar(255) NOT NULL,
	fecha date,
	equipo_local float,
	goles_local float,
	torneo float
);
/* Tabla Resultados VISITANTE*/
CREATE TABLE Visitante (
	ID_partido nvarchar(255) NOT NULL,
	fecha date,
	equipo_visitante float,
	goles_visitante float,
	torneo float
);
/*Importación de datos: SUCCESS! 
Vamos ahora a construir la tabla PARTIDOS. Viene de la unión de LOCAL Y VISITANTE,
pero con dos columnas más: un ID y una columna de GANADOR del partido:
*/
SELECT *
INTO Partidos
FROM (
	SELECT 
	t1.ID_partido,
	t1.fecha,
	t1.equipo_local AS equipo,
	t1.goles_local AS goles,
		CASE
			WHEN t1.goles_local > t2.goles_visitante THEN t1.equipo_local
			WHEN t1.goles_local < t2.goles_visitante THEN t2.equipo_visitante
			ELSE 0 -- 0 significa que fue un Empate
		END AS ganador,
	t1.torneo
	FROM [Local] t1
	FULL JOIN Visitante t2
		ON t1.ID_partido = t2.ID_partido
	UNION
	SELECT 
	t2.ID_partido,
	t2.fecha,
	t2.equipo_visitante AS equipo,
	t2.goles_visitante AS goles,
		CASE
			WHEN t1.goles_local > t2.goles_visitante THEN t1.equipo_local
			WHEN t1.goles_local < t2.goles_visitante THEN t2.equipo_visitante
			ELSE 0 -- 0 significa que fue un Empate
		END AS ganador,
	t2.torneo
	FROM [Local] t1
	FULL JOIN Visitante t2
		ON t1.ID_partido = t2.ID_partido
) AS Partidos;
/*SUCCESS!
Agrego la columna de ID, que va a ser la PK de la nueva tabla*/
ALTER TABLE Partidos
ADD ID int IDENTITY PRIMARY KEY;
/*SUCCESS! Ya tengo mi tabla PARTIDOS.*/

/* 3- PENALES: lo armo y lo completo desde el Excel:*/
CREATE TABLE Penales (
	ID_match nvarchar(255) PRIMARY KEY,
	fecha date,
	equipo1 float,
	equipo2 float,
	ganador_penales float
)
/* SUCCESS! */

/* 4- TORNEOS: armo la tabla y traigo los datos del Excel*/
CREATE TABLE Torneos (
	ID_torneo float PRIMARY KEY,
	torneo nvarchar(255),
	tipo nvarchar(255)
);
/* SUCCESS! */

/* 5- FIFA Ranking: armo la tabla y traigo los datos del Excel*/
CREATE TABLE Ranking_FIFA (
--	ID_FIFA float PRIMARY KEY,
	ranking float,
	pais float,
	cambio_ranking float,
	confederacion nvarchar(255),
	fecha date
);
/* Algo pasó que no le gustó la columna de ID. La armo aparte:
*/
ALTER TABLE Ranking_FIFA
ADD ID_FIFA int IDENTITY PRIMARY KEY
/* Ahora sí, SUCCESS!*/

/* 6- BALLON DOR: armo la tabla y traigo los datos del Excel*/
CREATE TABLE Ballon_DOr (
--	ID_BDO float PRIMARY KEY,
	año float,
	ranking float,
	jugador nvarchar(255),
	nacionalidad float
);
/* Tampoco le gustó la columna de ID. Va aparte.
*/
ALTER TABLE Ballon_DOr
ADD ID_BDO int IDENTITY PRIMARY KEY
/* SUCCESS! 

Ya tengo armadas todas mis tablas :D */


/*ASIGNACION DE FOREIGN KEYS
Voy a intentar relacionar las tablas entre sí, asignando FK
*/
ALTER TABLE Ranking_FIFA
ADD FOREIGN KEY (pais) REFERENCES Selecciones(ID_pais);

ALTER TABLE Ballon_DOr
ADD FOREIGN KEY (nacionalidad) REFERENCES Selecciones(ID_pais);

ALTER TABLE Penales
ADD FOREIGN KEY (ganador_penales) REFERENCES Selecciones(ID_pais);

ALTER TABLE Partidos
ADD FOREIGN KEY (ID_partido) REFERENCES Penales(ID_match); --problema!!

ALTER TABLE Partidos
ADD FOREIGN KEY (equipo) REFERENCES Selecciones(ID_pais);

ALTER TABLE Partidos
ADD FOREIGN KEY (ganador) REFERENCES Selecciones(ID_pais); --no se puede!

ALTER TABLE Partidos
ADD FOREIGN KEY (torneo) REFERENCES Torneos(ID_torneo);

/*Algunas funcionaron, otras no. Pero bueno*/



-- JUGANDO A PROBAR COSAS
/* Un conteo de las selecciones que ganaron mas definiciones por penales en la historia*/
SELECT
	t2.Selección AS Equipo,
	count(t2.Selección) AS [ganadas por penales]
FROM Penales t1
LEFT JOIN Selecciones t2
	ON t1.ganador_penales = t2.ID_pais
GROUP BY t2.Selección
ORDER BY [ganadas por penales] DESC;

/*Voy a armar una VIEW con el detalle de los partidos definidos por penales:
*/
CREATE VIEW Partidos_por_penales AS
SELECT
	t1.ID_partido,
	t1.torneo,
	t2.fecha,
	t2.equipo1,
	t2.equipo2,
	t2.ganador_penales,
	t3.Selección AS [Ganador por penales]
FROM ((Partidos t1
	   INNER JOIN Penales t2
		   ON t1.ID_partido = t2.ID_match)
	 INNER JOIN Selecciones t3
		ON t2.ganador_penales = t3.ID_pais);

CREATE VIEW Penales2 AS
SELECT 
P.ID AS ID_partido,
P.equipo,
	CASE 
		WHEN P.ganador = 0 THEN 'SI'
		ELSE 'NO'
	END AS Empate,
	CASE
		WHEN Pe.ID_match IS NULL THEN 'NO'
		ELSE 'SI'
	END AS [Definido por penales],
	CASE
		WHEN (Pe.ID_match IS NOT NULL) AND (P.equipo = Pe.ganador_penales) THEN 'SI'
		WHEN (Pe.ID_match IS NOT NULL) AND (P.equipo <> Pe.ganador_penales) THEN 'NO'
		ELSE 'No hubo'
	END AS [Ganó por penales]
FROM Partidos P
LEFT JOIN Penales Pe
	ON P.ID_partido = Pe.ID_match

SELECT * INTO PenalesV2 FROM Penales2



/*Y voy a unir esa VIEW con TORNEOS para filtrar sólo los partidos de mundiales*/
SELECT
	t1.ID_partido,
	t2.torneo,
	t1.[Ganador por penales]
FROM Partidos_por_penales t1
LEFT JOIN Torneos t2
	ON t1.torneo = t2.ID_torneo
WHERE t2.torneo = 'FIFA World Cup';

/*Ahora voy a contar la cantidad de partidos ganados por penales por cada equipo*/
SELECT
	t1.[Ganador por penales],
	count(t1.[Ganador por penales]) AS [Veces ganadas por penales]
FROM Partidos_por_penales t1
LEFT JOIN Torneos t2
	ON t1.torneo = t2.ID_torneo
WHERE t2.torneo = 'FIFA World Cup'
GROUP BY t1.[Ganador por penales]
ORDER BY [Veces ganadas por penales] DESC;
/*Argentina es el que más veces ganó por penales en Mundiales!*/

/*Ahora quiero ver los que más veces perdieron por penales. Armo una VIEW:
*/
CREATE VIEW Perdidos_penales AS
SELECT  
	t1.ID_partido,
	CASE 
		WHEN t1.equipo1 <> t1.ganador_penales THEN t1.equipo1
		ELSE t1.equipo2
	END AS Perdedor
FROM Partidos_por_penales t1
WHERE torneo = (SELECT ID_torneo FROM Torneos WHERE torneo = 'FIFA World Cup')

/*Y junto esa VIEW con Selecciones para contar: */
SELECT
	t2.Selección,
	count(t2.Selección) AS [Veces perdidas por penales]
FROM Perdidos_penales t1
LEFT JOIN Selecciones t2
	ON t1.Perdedor = t2.ID_pais
GROUP BY t2.Selección
ORDER BY [Veces perdidas por penales] DESC;


/*Lo puedo hacer también con Copa América, por ejemplo: 
agarro la VIEW de los partidos por penales y filtro Copa América*/
SELECT
	t1.ID_partido,
	t2.torneo,
	t1.[Ganador por penales]
FROM Partidos_por_penales t1
LEFT JOIN Torneos t2
	ON t1.torneo = t2.ID_torneo
WHERE t2.torneo = 'Copa América';

/*Ahora voy a contar la cantidad de partidos ganados por penales por cada equipo*/
SELECT
	t1.[Ganador por penales],
	count(t1.[Ganador por penales]) AS [Veces ganadas por penales]
FROM Partidos_por_penales t1
LEFT JOIN Torneos t2
	ON t1.torneo = t2.ID_torneo
WHERE t2.torneo = 'Copa América'
GROUP BY t1.[Ganador por penales]
ORDER BY [Veces ganadas por penales] DESC;

/*Y puedo contar las veces perdidas también: armo una VIEW */
CREATE VIEW Perdidos_penales_America AS
SELECT  
	t1.ID_partido,
	CASE 
		WHEN t1.equipo1 <> t1.ganador_penales THEN t1.equipo1
		ELSE t1.equipo2
	END AS Perdedor
FROM Partidos_por_penales t1
WHERE torneo = (SELECT ID_torneo FROM Torneos WHERE torneo = 'Copa América');
/*Y junto esa VIEW con Selecciones para contar: */
SELECT
	t2.Selección,
	count(t2.Selección) AS [Veces perdidas por penales]
FROM Perdidos_penales_America t1
LEFT JOIN Selecciones t2
	ON t1.Perdedor = t2.ID_pais
GROUP BY t2.Selección
ORDER BY [Veces perdidas por penales] DESC;

SELECT * FROM Partidos
WHERE year(fecha) = 2022;
