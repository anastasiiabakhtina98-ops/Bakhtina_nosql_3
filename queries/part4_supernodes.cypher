// ВИЯВЛЕННЯ СУПЕРВУЗЛІВ

// Запит 1: Пошук вузлів з аномально великою кількістю ребер
// COUNT { (n)--() } є оптимізованим способом дізнатися ступінь вузла (degree) 
// без фактичного завантаження всіх ребер у пам'ять (специфіка Neo4j 5+).

MATCH (n)
WITH n, COUNT { (n)--() } AS degree
ORDER BY degree DESC
LIMIT 20
RETURN labels(n) AS NodeLabels, 
       coalesce(n.title, n.name, n.userId) AS Identifier, 
       degree AS TotalConnections;

// Запит 2: Аналіз супервузлів саме серед Жанрів
// Оскільки кожен фільм може мати кілька жанрів, жанри стають "хабами" графа.

MATCH (g:Genre)
WITH g, COUNT { (g)<--() } AS incomingConnections
ORDER BY incomingConnections DESC
LIMIT 5
RETURN g.name AS GenreName, incomingConnections;