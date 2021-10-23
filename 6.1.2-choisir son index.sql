SELECT *
FROM dbo.indexdemo
WHERE id > 10 AND id < 50;
GO

DROP INDEX cix$dbo_indexdemo$id
ON dbo.indexdemo;

CREATE CLUSTERED INDEX cix$dbo_indexdemo$texte
ON dbo.indexdemo (texte ASC);
GO
DBCC SHOW_STATISTICS ('dbo.indexdemo', 'nix$dbo_indexdemo$petittexte');
GO

SELECT DISTINCT LastName
FROM Person.Contact
WHERE LastName LIKE 'A%'
ORDER BY LastName;
GO

SELECT LastName, FirstName
FROM Person.Contact
WHERE LastName LIKE 'A%'
ORDER BY LastName, FirstName;
GO

CREATE INDEX nix$Person_Contact$LastName
ON Person.Contact (LastName) INCLUDE (FirstName)
WITH DROP_EXISTING;
GO

-- index filtré
SELECT *
FROM Person.Contact
WHERE Title = 'Mr.'
GO

CREATE UNIQUE INDEX uqf$Person_Contact$EmailAddress
ON Person.Contact (EmailAddress)
WHERE EmailAddress IS NOT NULL; 
GO

CREATE TABLE dbo.testfiltered (
    id int NOT NULL PRIMARY KEY, 
    Active bit NOT NULL,
    fluff char(896) NOT NULL DEFAULT ('b'));

INSERT INTO dbo.testfiltered (id, Active)
SELECT ContactId, 0 FROM AdventureWorks.Person.Contact

UPDATE t1 SET Active = 1
FROM dbo.testfiltered t1
JOIN (SELECT TOP (10) id FROM dbo.testfiltered ORDER BY NEWID()) t2 
    ON t1.id = t2.id

CREATE INDEX nix$dbo_testfiltered$active
ON dbo.testfiltered (Active)
WHERE Active = 1;

CREATE INDEX nix$dbo_testfiltered$activeNotFiltered
ON dbo.testfiltered (Active);

DBCC SHOW_STATISTICS ('dbo.testfiltered', 'nix$dbo_testfiltered$active')
DBCC SHOW_STATISTICS ('dbo.testfiltered', 
    'nix$dbo_testfiltered$activeNotFiltered')

SELECT * 
FROM dbo.testfiltered
WHERE Active = 1;
GO
