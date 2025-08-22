-- ALGUNAS MEDIDAS

USE ProyectoV2
/* 1- MAS PARTIDOS OFICIALES GANADOS 
Voy a hacer una lista de los equipos que más partidos ganaron en la historia.
Sólo considero PARTIDOS OFICIALES.
*/

--Armo una VIEW con los ganadores de partidos oficiales; NULL es un empate
CREATE VIEW Ganadores_oficiales AS
SELECT DISTINCT
t1.ID_partido,
t1.fecha,
t2.Selección AS Ganador,
t3.torneo
FROM Partidos t1
LEFT JOIN Selecciones t2
	ON t1.ganador = t2.ID_pais
LEFT JOIN Torneos t3
	ON t1.torneo = t3.ID_torneo
WHERE t3.tipo LIKE '%Official%'

--Cuento los partidos ganados por cada equipo:
SELECT
*
FROM Ganadores_oficiales
WHERE Ganador IS NOT NULL

SELECT
Ganador,
count(Ganador) as Oficiales_ganados
FROM Ganadores_oficiales
WHERE Ganador IS NOT NULL
GROUP BY Ganador
ORDER BY Oficiales_ganados DESC;



/* 2- MAS PARTIDOS GANADOS A TOP 10
Voy a hacer una lista de los equipos que les ganaron a más equipos que estaban en 
el Top 10 del Ranking FIFA en ese momento.
El Ranking FIFA sale cada cierta cantidad de meses, desde el año 1992*/

CREATE VIEW prueba AS 
SELECT
	t1.ranking,
	t2.Selección,
	t1.fecha,
	abs(datediff(day, t1.fecha, '1993-08-20')) AS diferencia
FROM Ranking_FIFA t1
LEFT JOIN Selecciones t2
	ON t1.pais = t2.ID_pais
WHERE fecha IS NOT NULL
	  AND
	  ranking <=10

SELECT
fecha,
Selección,
ranking
FROM prueba
WHERE diferencia IN ( SELECT min(diferencia) FROM prueba)

SELECT
t1.fecha,
t2.Selección,
t1.ranking
FROM Ranking_FIFA t1
LEFT JOIN Selecciones t2
	ON t1.pais = t2.ID_pais
WHERE abs(datediff(day, t1.fecha, '1993-08-20')) IN ( SELECT min(diferencia) FROM prueba)

SELECT
	t1.fecha,
	abs(datediff(day, t1.fecha, '1993-08-20')) AS diferencia
FROM Ranking_FIFA t1
LEFT JOIN Selecciones t2
	ON t1.pais = t2.ID_pais
WHERE fecha IS NOT NULL
	  AND
	  ranking <=10
GROUP BY t1.fecha

SELECT
min(diferencia)
FROM (SELECT
	t1.fecha,
	abs(datediff(day, t1.fecha, '1993-08-20')) AS diferencia
FROM Ranking_FIFA t1
LEFT JOIN Selecciones t2
	ON t1.pais = t2.ID_pais
WHERE fecha IS NOT NULL
	  AND
	  ranking <=10
GROUP BY t1.fecha)

/*Bueno, es muy dificil hacerlo bien. Voy a mirar el ranking por meses*/
CREATE VIEW Ranking AS
SELECT
ranking,
pais,
fecha,
year(fecha) AS Año_rank,
month(fecha) AS Mes_rank
FROM Ranking_FIFA
WHERE ranking <= 10;

CREATE VIEW Oficiales AS
SELECT 
P.ID_partido,
P.fecha,
P.equipo AS Perdedor,
P.ganador,
year(P.fecha) AS Año,
month(P.fecha) AS Mes
FROM PARTIDOS P
LEFT JOIN Torneos T
	ON P.torneo = T.ID_torneo
WHERE T.tipo = 'Official'
	  AND
	  P.ganador <> P.equipo
	  AND
	  year(P.fecha) >= 1992

/* Un quilombooo!! Voy a considerar un ranking por año calendario, donde el mejor de cada año
se decide por el ranking FIFA a diciembre del año anterior. Por ejemplo: si en 12/2020 se decide
que Alemania es el mejor equipo del mundo, lo será por todo el año 2021*/

/*Armo la lista con el ranking anual construido de esa manera:*/
CREATE VIEW Ranking AS
SELECT
ranking,
pais,
fecha,
year(fecha)+1 AS Validez
FROM Ranking_FIFA
WHERE month(fecha) = 12
	  AND
	  ranking <= 10
--ORDER BY Validez, ranking

/*Ahora sí puedo comparar quiénes les ganaron a los top 10 de cada año.
Armo la VIEW con los perdedores y ganadores de partidos oficiales:*/
CREATE VIEW Oficiales AS
SELECT 
P.ID_partido,
P.fecha,
P.equipo AS Perdedor,
P.ganador,
year(P.fecha) AS Año,
month(P.fecha) AS Mes
FROM PARTIDOS P
LEFT JOIN Torneos T
	ON P.torneo = T.ID_torneo
WHERE T.tipo = 'Official'
	  AND
	  P.ganador <> P.equipo
	  AND
	  year(P.fecha) >= 1992

/*La voy a unir con el ranking para comparar con la columna de Perdedores:*/
SELECT
*
FROM Oficiales O
LEFT JOIN Ranking R
	ON O.Año = R.Validez
WHERE O.Perdedor = R.pais  --quiero ver si en ese partido perdió un TOP 10
ORDER BY O.fecha, R.pais

/*Voy a contar cuántas veces ganó cada equipo a un TOP 10: */
SELECT
S.Selección,
count(O.ganador) AS [Partidos ganados a top 10]
FROM Oficiales O
LEFT JOIN Ranking R
	ON O.Año = R.Validez
LEFT JOIN Selecciones S
	ON O.ganador = S.ID_pais
WHERE O.Perdedor = R.pais
GROUP BY S.Selección
ORDER BY [Partidos ganados a top 10] DESC


/* 3- MAS GOLES CONVERTIDOS
Voy a armar una lista de los equipos más goleadores de la historia, separando el total de goles,
goles en partidos oficiales y goles en mundiales*/

/*TABLA: TOTAL DE GOLES*/
CREATE VIEW Goles_total AS
SELECT 
equipo,
sum(goles) as [Total de goles]
FROM Partidos
GROUP BY equipo
ORDER BY [Total de goles] DESC

/*TABLA: GOLES OFICIALES*/
CREATE VIEW Goles_oficial AS
SELECT 
P.equipo,
sum(P.goles) as [Goles oficiales]
FROM Partidos P
LEFT JOIN Torneos T
	ON P.torneo = T.ID_torneo
WHERE T.tipo = 'Official'
GROUP BY equipo
--ORDER BY [Goles oficiales] DESC

/*TABLA: GOLES EN MUNDIALES*/
CREATE VIEW Goles_mundial AS
SELECT 
P.equipo,
sum(P.goles) as [Goles en Mundiales]
FROM Partidos P
LEFT JOIN Torneos T
	ON P.torneo = T.ID_torneo
WHERE T.torneo = 'FIFA World Cup' 
GROUP BY equipo
--ORDER BY [Goles en Mundiales] DESC

/*Falta juntar todas las tablas*/
SELECT
S.Selección,
T.[Total de goles],
O.[Goles oficiales],
M.[Goles en Mundiales]
FROM Goles_total T
LEFT JOIN Goles_oficial O
	ON T.equipo = O.equipo
LEFT JOIN Goles_mundial M
	ON T.equipo = M.equipo
LEFT JOIN Selecciones S
	ON T.equipo = S.ID_pais
ORDER BY M.[Goles en Mundiales] DESC


/* 4- MAS NOMINADOS AL BALON DE ORO
Voy a hacer una lista de los equipos con más nominaciones a Ballon D'Or
desde que se da el premio*/

SELECT
	S.Selección AS País,
	count(B.nacionalidad) AS Nominaciones
FROM Ballon_DOr B
LEFT JOIN Selecciones S
	ON B.nacionalidad = S.ID_pais
GROUP BY S.Selección
ORDER BY Nominaciones DESC


/* 5- MAS JUGADORES EN EL TOP 3 DE BALON DE ORO
Voy a hacer una lista de los equipos con más jugadores del top 3 de 
Ballon D'Or*/

SELECT
	S.Selección AS País,
	count(B.nacionalidad) AS Nominaciones
FROM Ballon_DOr B
LEFT JOIN Selecciones S
	ON B.nacionalidad = S.ID_pais
WHERE ranking <=3
GROUP BY S.Selección
ORDER BY Nominaciones DESC

/*Y ya que estamos, una lista con los países que ganaron más
Balones de Oro*/
SELECT
	S.Selección AS País,
	count(B.nacionalidad) AS Ganados
FROM Ballon_DOr B
LEFT JOIN Selecciones S
	ON B.nacionalidad = S.ID_pais
WHERE ranking =1
GROUP BY S.Selección
ORDER BY Ganados DESC