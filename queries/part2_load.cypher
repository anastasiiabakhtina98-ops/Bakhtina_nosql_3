// КРОК 1: Створення індексів та унікальних обмежень (Constraints)

CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.userId IS UNIQUE;

CREATE CONSTRAINT movie_id_unique IF NOT EXISTS
FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;

CREATE CONSTRAINT genre_name_unique IF NOT EXISTS
FOR (g:Genre) REQUIRE g.name IS UNIQUE;

// КРОК 2: Завантаження вузлів Користувачів (User)

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: row.UserID})
ON CREATE SET u.gender = row.Gender,
              u.age = toInteger(row.Age),
              u.occupation = toInteger(row.Occupation);

// КРОК 3: Завантаження вузлів Фільмів (Movie), Жанрів (Genre) та зв'язків між ними

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: row.MovieID})
ON CREATE SET m.title = left(row.Title, size(row.Title) - 7),
              m.year = toInteger(substring(row.Title, size(row.Title) - 5, 4))
WITH row, m
UNWIND split(row.Genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

// КРОК 4: Пакетне завантаження ребер Оцінок ([:RATED]) через APOC

CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: row.UserID})
   MATCH (m:Movie {movieId: row.MovieID})
   MERGE (u)-[r:RATED]->(m)
   ON CREATE SET r.rating = toInteger(row.Rating), 
                 r.timestamp = toInteger(row.Timestamp)",
  {batchSize: 10000, parallel: false}
);