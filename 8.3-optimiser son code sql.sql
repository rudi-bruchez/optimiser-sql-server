-- une requête toute bête
SELECT FirstName, LastName
FROM Person.Contact
WHERE Title = 'Mr.'
ORDER BY LastName, FirstName;
GO

-- liberté de parole
SELECT c.FirstName, c.LastName
FROM Person.Contact c
CROSS JOIN HumanResources.Employee e
WHERE c.ContactId = e.ContactId
GO
SELECT c.FirstName, c.LastName
FROM Person.Contact c
JOIN HumanResources.Employee e ON c.ContactId = e.ContactId
GO
SELECT c.FirstName, c.LastName
FROM Person.Contact c
WHERE EXISTS (SELECT *
FROM HumanResources.Employee e WHERE c.ContactId = e.ContactId)
GO
SELECT c.FirstName, c.LastName
FROM Person.Contact c
WHERE c.ContactId IN (SELECT e.ContactId
FROM HumanResources.Employee e)
GO

-- exécution procédurale d'une syntaxe ensembliste
DECLARE @i int;
SET @i = 0;
SELECT @i = @i + 1 FROM Person.Contact;
SELECT @i;
GO

-- sous-requête vs fonction de fenêtrage
-- SELECT avec sous-requête
SELECT
    t.FirstName, 
    t.LastName,
    (SELECT COUNT(*) 
     FROM Person.Contact 
     WHERE LastName = t.LastName) cnt
FROM Person.Contact t
GO
-- SELECT avec fonction de fenêtrage
SELECT
    t.FirstName, 
    t.LastName,
    COUNT(*) OVER (PARTITION BY LastName) as cnt 
FROM Person.Contact t
GO

-- comparaisons et filtres
SELECT LastName, FirstName
FROM Person.Contact
WHERE LastName LIKE 'Al%';
GO

--indexez vos clés étrangères !
SELECT c.LastName, c.FirstName, a.AddressLine1, a.PostalCode, a.City
FROM Person.Contact c
JOIN HumanResources.Employee e ON c.ContactId = e.ContactId
JOIN HumanResources.EmployeeAddress ea ON e.EmployeeId = ea.EmployeeId
JOIN Person.Address a ON ea.AddressId = a.AddressId;
GO

-- ne dites pas :
SELECT FirstName, LastName 
FROM Person.Contact
WHERE LastName COLLATE Latin1_General_CI_AI = 'Jimenez';

SELECT FirstName, LastName 
FROM Person.Contact
WHERE LEFT(LastName, 2) = 'AG';

SELECT FirstName, LastName 
FROM Person.Contact
WHERE LastName + FirstName = 'AlamedaLili';
GO

-- dites plutôt :
SELECT FirstName, LastName 
FROM Person.Contact
WHERE LastName LIKE 'Jim[eé]nez';

SELECT FirstName, LastName 
FROM Person.Contact
WHERE LastName LIKE 'AG%';

SELECT FirstName, LastName 
FROM Person.Contact
WHERE LastName = 'Alameda' AND FirstName = 'Lili';
GO

-- constant folding ?
SELECT *
FROM Person.Contact
WHERE ContactId + 3 = 34;

SELECT *
FROM Person.Contact
WHERE ContactId = 37;
GO

---------------------------
-- fonctions utilisateur --
---------------------------
CREATE FUNCTION Person.GetCountContacts (@LastName nvarchar(50))
RETURNS int
AS BEGIN
   RETURN (SELECT COUNT(*) 
           FROM Person.contact 
           WHERE LastName LIKE @LastName)
END;
GO

SELECT Person.GetCountContacts('%');
SELECT Person.GetCountContacts('A%');
SELECT Person.GetCountContacts('Ackerman');
GO

--Pratique, non ? 

-- SELECT avec utilisation de la fonction
SELECT 
    t.FirstName,
    t.LastName,
    Person.GetCountContacts(t.LastName) as cnt
FROM Person.Contact t
GO
-- SELECT avec sous-requête
SELECT
    t.FirstName, 
    t.LastName,
    (SELECT COUNT(*) 
     FROM Person.Contact 
     WHERE LastName = t.LastName) cnt
FROM Person.Contact t
GO

-- compter les lignes d'une table
SELECT COUNT(*)
FROM Person.Contact;
GO

SELECT SUM(row_count) as row_count
FROM sys.dm_db_partition_stats
WHERE 
    object_id=OBJECT_ID('Person.Contact') AND
    (index_id=0 or index_id=1);
GO

-- variable de type table
SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES
GO

DECLARE @t TABLE (id int)

SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES
GO

DECLARE @t TABLE (Name SYSNAME)
INSERT @t SELECT name FROM sys.system_objects

SELECT * FROM @
GO

-- tables temporaires
USE tempdb
GO

CREATE TABLE #t (Name SYSNAME)

BEGIN TRAN
INSERT #t SELECT name FROM [master].[dbo].[sysobjects]

ROLLBACK

SELECT * FROM #t
GO

DECLARE @t TABLE (Name SYSNAME)

BEGIN TRAN
INSERT @t SELECT name FROM [master].[dbo].[sysobjects]
ROLLBACK

SELECT * FROM @t
GO

-- SQL dynamique
DECLARE @sql varchar(8000)
SET @sql = 'SELECT * FROM Person.Contact'
EXEC (@sql)
GO

SELECT FirstName, MiddleName, LastName, Suffix, EmailAddress
FROM Person.Contact
WHERE 
   (LastName = @LastName OR @LastName IS NULL) AND
   (FirstName = @FirstName OR @FirstName IS NULL) AND
   (MiddleName = @MiddleName OR @MiddleName IS NULL) AND
   (Suffix = @Suffix OR @Suffix IS NULL) AND
   (EmailAddress = @EmailAddress OR @EmailAddress IS NULL)
ORDER BY LastName, FirstName
GO

DECLARE @sql varchar(8000)

SET @sql = '
   SELECT FirstName, MiddleName, LastName, Suffix, EmailAddress
   FROM Person.Contact
   WHERE '
IF @FirstName IS NOT NULL
   SET @sql = @sql + ' FirstName = ''' + @FirstName + ''' AND '
IF @MiddleName IS NOT NULL
   SET @sql = @sql + ' MiddleName = ''' + @MiddleName + ''' AND '
IF @LastName IS NOT NULL
   SET @sql = @sql + ' LastName = ''' + @LastName + ''' AND '
IF @Suffix IS NOT NULL
   SET @sql = @sql + ' Suffix = ''' + @Suffix + ''' AND '
IF @EmailAddress IS NOT NULL
   SET @sql = @sql + ' EmailAddress = ''' + @EmailAddress + ''' AND '

SET @sql = LEFT(@sql, LEN(@sql)-3)
EXEC (@sql)
GO
