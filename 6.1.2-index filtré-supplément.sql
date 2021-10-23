USE sandbox;

CREATE TABLE dbo.testfiltered (
	id int NOT NULL PRIMARY KEY, 
	Active bit NOT NULL,
	fluff char(896) NOT NULL DEFAULT ('b'));

INSERT INTO dbo.testfiltered (id, Active)
SELECT ContactId, 0
FROM AdventureWorks.Person.Contact

UPDATE t1
SET Active = 1
FROM dbo.testfiltered t1
JOIN (SELECT TOP (10) id 
FROM dbo.testfiltered
ORDER BY NEWID()) t2 ON t1.id = t2.id

CREATE INDEX nix$dbo_testfiltered$active
ON dbo.testfiltered (Active)
WHERE Active = 1;

CREATE INDEX nix$dbo_testfiltered$activeNotFiltered
ON dbo.testfiltered (Active);


DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active')
DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$activeNotFiltered')

SET STATISTICS IO ON

SELECT * 
FROM dbo.testfiltered
WHERE Active = 1;

SELECT * 
FROM dbo.testfiltered WITH(index = nix$dbo_testfiltered$activeNotFiltered)
WHERE Active = 1;

CREATE INDEX nix$dbo_testfiltered$active_big
ON dbo.testfiltered (Active, fluff)
WHERE Active = 1;

CREATE INDEX nix$dbo_testfiltered$activeNotFiltered_big
ON dbo.testfiltered (Active, fluff);

DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active_big')
DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$activeNotFiltered_big')

SELECT * 
FROM dbo.testfiltered
WHERE Active = 1;

SELECT * 
FROM dbo.testfiltered WITH(index = nix$dbo_testfiltered$activeNotFiltered_big)
WHERE Active = 1;

CREATE INDEX nix$dbo_testfiltered$active_big_include
ON dbo.testfiltered (Active) INCLUDE (fluff)
WHERE Active = 1;

CREATE INDEX nix$dbo_testfiltered$activeNotFiltered_big_include
ON dbo.testfiltered (Active) INCLUDE (fluff);

DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active_big_include')
DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$activeNotFiltered_big_include')

SELECT * 
FROM dbo.testfiltered
WHERE Active = 1;

SELECT * 
FROM dbo.testfiltered WITH(index = nix$dbo_testfiltered$activeNotFiltered_big_include)
WHERE Active = 1;

UPDATE t1
SET fluff = 'a'
FROM dbo.testfiltered t1
JOIN (SELECT TOP (20) id 
FROM dbo.testfiltered
ORDER BY NEWID()) t2 ON t1.id = t2.id

CREATE INDEX nix$dbo_testfiltered$active_big_include_FilterOnInclude
ON dbo.testfiltered (Active) INCLUDE (fluff)
WHERE fluff = 'a'
WITH DROP_EXISTING;

DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active_big_include_FilterOnInclude')

UPDATE t1
SET fluff = 'a'
FROM dbo.testfiltered t1
JOIN (SELECT TOP (10) id 
FROM dbo.testfiltered
WHERE fluff = 'b'
ORDER BY NEWID()) t2 ON t1.id = t2.id

DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active_big_include_FilterOnInclude')

CREATE INDEX nix$dbo_testfiltered$active_big_include_FilterOnInclude
ON dbo.testfiltered (Active) INCLUDE (fluff)
WHERE fluff = 'a'
WITH DROP_EXISTING;

DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active_big_include_FilterOnInclude')