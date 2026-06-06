// 5.1. PageRank на графі фільмів

// Крок 1: Матеріалізуємо ребра фільм-фільм

MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: Створюємо проєкцію

CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запускаємо алгоритм PageRank 

CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS title, score
ORDER BY score DESC
LIMIT 15;

// Крок 4: Видаляємо проєкцію та тимчасові ребра

CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;

// 5.2. Виявлення спільнот (Louvain)

// Крок 1: Матеріалізуємо ребра користувач-користувач

MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: Створюємо проєкцію

CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск Louvain з записом результату у властивості вузлів 

CALL gds.louvain.write('userSimilarity', {
  relationshipWeightProperty: 'weight',
  writeProperty: 'communityId'
})
YIELD communityCount, modularity;

// Крок 4: Аналіз кластерів (топ-10 за розміром і їхні топ-3 жанри)

MATCH (u:User)
WHERE u.communityId IS NOT NULL
WITH u.communityId AS community, count(u) AS clusterSize
ORDER BY clusterSize DESC
LIMIT 10
MATCH (u:User {communityId: community})-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4
WITH community, clusterSize, g.name AS genre, count(*) AS genreCount
ORDER BY community, genreCount DESC
WITH community, clusterSize, collect(genre)[0..3] AS topGenres
RETURN community, clusterSize, topGenres
ORDER BY clusterSize DESC;

// Крок 5: Видаляємо проєкцію та тимчасові ребра

CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;

// 5.3. Найкоротший шлях між користувачами

// Крок 1: Матеріалізуємо ребра 

MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 5 AND r2.rating >= 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: Створюємо проєкцію 

CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Пошук найкоротшого шляху (Дейкстра)
// Ми ігноруємо вагу, щоб знайти найкоротший шлях саме в кількості "рукостискань" (hops)

MATCH (source:User {userId: '1'}), (target:User {userId: '200'})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target
})
YIELD totalCost, nodeIds
RETURN totalCost AS hops_distance, 
       [id IN nodeIds | gds.util.asNode(id).userId] AS userPath; //no changes, no records 

// Знаходимо двох користувачів, які знаходяться на відстані 3-4 кроків один від одного

MATCH p = (source:User)-[:SIMILAR*3..4]-(target:User)
WHERE source.userId <> target.userId
WITH source, target LIMIT 1

// Запускаємо Дейкстру для цієї знайденої пари

CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target
})
YIELD path
RETURN path;

// Крок 4: Очищення

CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;