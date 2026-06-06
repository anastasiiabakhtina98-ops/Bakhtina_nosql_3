// БАЗОВІ ЗАПИТИ

// Запит 1: Фільми жанру «Thriller» із середнім рейтингом вище 4.0

MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (u:User)-[r:RATED]->(m)
WITH m, avg(r.rating) AS avgRating
WHERE avgRating > 4.0
RETURN m.movieId AS movieId, m.title AS title, m.year AS year, avgRating
ORDER BY avgRating DESC;

// Запит 2: Користувачі, які поставили оцінку 5 більш ніж 50 фільмам

MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u, count(m) AS count5s
WHERE count5s > 50
RETURN u.userId AS userId, u.gender AS gender, u.age AS age, count5s
ORDER BY count5s DESC;

// ЗАПИТИ СЕРЕДНЬОГО РІВНЯ

// Запит 3: Фільми, які обидва користувачі (userId="1" і userId="2") оцінили високо (рейтинг >= 4)

MATCH (u1:User {userId: '1'})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: '2'})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.movieId AS movieId, m.title AS title, r1.rating AS user1_rating, r2.rating AS user2_rating;

// Запит 4: Жанри, чиї фільми стабільно отримують високі оцінки (середній рейтинг та кількість оцінок)

MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(u:User)
WITH g, avg(r.rating) AS avgRating, count(r) AS totalRatings
WHERE totalRatings > 5000 // Фільтр стабільності (щоб відсіяти жанри з малою кількістю голосів)
RETURN g.name AS genre, avgRating, totalRatings
ORDER BY avgRating DESC;

// СКЛАДНІ ЗАПИТИ (РЕКОМЕНДАЦІЇ ТА ШЛЯХИ)

// Запит 5: Рекомендація «користувачі зі схожими смаками також дивилися» для userId="1"

MATCH (u1:User {userId: '1'})-[r1:RATED]->(m1:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND u1 <> u2
WITH u1, u2, count(m1) AS similarityScore
ORDER BY similarityScore DESC
LIMIT 15 // Беремо топ-15 найближчих "однодумців"

MATCH (u2)-[r3:RATED]->(m2:Movie)
WHERE r3.rating >= 4 AND NOT (u1)-[:RATED]->(m2)
RETURN m2.title AS recommendation, avg(r3.rating) AS avgRatingOfSimilar, count(u2) AS recommendationStrength
ORDER BY recommendationStrength DESC, avgRatingOfSimilar DESC
LIMIT 10;

// Запит 6: Найкоротший ланцюжок зв’язку між двома користувачами (наприклад, userId="1" і userId="10") через спільні фільми

MATCH (u1:User {userId: '1'}), (u2:User {userId: '10'})
MATCH p = shortestPath((u1)-[:RATED*..10]-(u2))
RETURN p;