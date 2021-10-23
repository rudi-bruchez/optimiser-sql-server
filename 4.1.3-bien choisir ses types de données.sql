-- ok
SELECT CAST('TRUE' as bit), CAST('FALSE' as bit)

SET LANGUAGE 'french'
-- erreur
SELECT CAST('VRAI' as bit), CAST('FALSE' as bit)

-- ok
DECLARE @bool bit
SET @bool = 'TRUE'
SELECT @bool
GO

USE tempdb
GO

CREATE TABLE dbo.PartiPolitique (
	code char(5) NOT NULL PRIMARY KEY CLUSTERED,
	nom varchar(100) NOT NULL UNIQUE, 
	type int NOT NULL DEFAULT(0)
)
GO

INSERT INTO dbo.PartiPolitique (code, nom)
SELECT 'PCF', 'Parti Communiste Français' UNION ALL
SELECT 'MRC', 'Mouvement Républicain et Citoyen' UNION ALL
SELECT 'PS', 'Parti Socialiste' UNION ALL
SELECT 'PRG', 'Parti Radical de Gauche' UNION ALL
SELECT 'VERTS', 'Les Verts' UNION ALL
SELECT 'MODEM', 'Mouvement Démocrate' UNION ALL
SELECT 'UDF', 'Union pour la Démocratie Française' UNION ALL
SELECT 'PSLE', 'Nouveau Centre' UNION ALL
SELECT 'UMP', 'Union pour un Mouvement Populaire' UNION ALL
SELECT 'RPF', 'Rassemblement pour la France' UNION ALL
SELECT 'DLR', 'Debout la République' UNION ALL
SELECT 'FN', 'Front National' UNION ALL
SELECT 'LO', 'Lutte Ouvrière' UNION ALL
SELECT 'LCR', 'Ligue Communiste Révolutionnaire'
GO

CREATE INDEX nix$dbo_PartiPolitique$type 
ON dbo.PartiPolitique ([type])
GO

-- à droite 
UPDATE dbo.PartiPolitique
SET type = type | POWER(2, 0)
WHERE code in ('MODEM', 'UDF', 'PSLE', 'UMP', 'RPF', 'DLR', 'FN', 'CPNT')

-- à gauche
UPDATE dbo.PartiPolitique
SET type = type | POWER(2, 1)
WHERE code in ('MODEM', 'UDF', 'PS', 'PCF', 'PRG', 'VERTS', 'LO', 'LCR')

-- antilibéral
UPDATE dbo.PartiPolitique
SET type = type | POWER(2, 2)
WHERE code in ('PCF', 'LO', 'LCR')

-- au gouvernement
UPDATE dbo.PartiPolitique
SET type = type | POWER(2, 3)
WHERE code in ('UMP', 'PSLE')

-- qui est au centre ?

-- scan
SELECT code
FROM dbo.PartiPolitique
WHERE type & (1 | 2) = (1 | 2)

-- seek... mais incorrect
SELECT code
FROM dbo.PartiPolitique
WHERE type = 3

-----------------------------------------------------
-- autoincrément

CREATE TABLE dbo.autoincrement (id int IDENTITY(-2147483648, 1))

-- chaînes de caractères
DECLARE @ch char(20)
DECLARE @vch varchar(10)
SET @ch = '1234'
SET @vch = '1234  ' -- on ajoute deux espaces
SELECT ASCII(SUBSTRING(@ch, 5, 1)) – 32 = espace

SELECT LEN (@ch), LEN(@vch) -– les deux donnent 4
IF @ch = @vch
    PRINT 'c''est la même chose' -– eh oui, c'est la même chose

SELECT DATALENGTH (@ch), DATALENGTH(@vch)  -- @vch = 6, les espaces sont présents.

SET @vch = @ch
SELECT DATALENGTH(@vch) –- 20 !

-- UNICODE
DECLARE @vch varchar(50)
DECLARE @nvch nvarchar(100)

SET @vch = 'salut!'
SET @nvch = 'salut!  '

IF @vch = @nvch PRINT 'ok'; -- ça marche...

IF @vch LIKE @nvch PRINT 'ok' – ça ne marche pas...

-- varchar
SELECT 
    AVG(DATALENGTH(EmailAddress)) as AvgDatalength, 
    AVG(LEN(EmailAddress)) as AvgLen,
    SUM(DATALENGTH(EmailAddress)) - SUM(LEN(EmailAddress)) as Spaces,
    COLUMNPROPERTY(OBJECT_ID('Person.Contact'), 
        'EmailAddress', 'precision') as ColumnLength
FROM Person.Contact;


SELECT 
    QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) as tbl,
    QUOTENAME(COLUMN_NAME) as col,
    DATA_TYPE + ' (' +
        CASE CHARACTER_MAXIMUM_LENGTH
            WHEN -1 THEN 'MAX'
            ELSE CAST(CHARACTER_MAXIMUM_LENGTH as VARCHAR(20))
        END + ')' as type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE LIKE 'var%' OR DATA_TYPE LIKE 'nvar%'
ORDER BY tbl, ORDINAL_POSITION;


---------------------------------------------
-- datetime

DECLARE @date1 datetime
DECLARE @date2 datetime

SET @date1 = '20071231 23:59:59:999'
SET @date2 = '20080101 00:00:00:001'

IF @date1 = @date2
    PRINT 'pas de différence'


-- LOB
SELECT SCHEMA_NAME(schema_id) + '.' + Name as tbl,
    text_in_row_limit,
    large_value_types_out_of_row
FROM sys.tables
ORDER BY tbl;


-- dépassement de ligne
USE tempdb
GO

CREATE TABLE dbo.longcontact (
    longcontactId int NOT NULL PRIMARY KEY,
    nom varchar(5000), 
    prenom varchar(5000)
)
GO

INSERT INTO dbo.longcontact (longcontactId, nom, prenom)
SELECT 1, REPLICATE('N', 5000), REPLICATE('P', 5000)
GO

SELECT p.index_id, au.type_desc, au.used_pages
FROM sys.partitions p
JOIN sys.allocation_units au ON p.partition_id = au.container_id
WHERE p.object_id = OBJECT_ID('dbo.longcontact');
GO

DBCC IND ('tempdb', 'longcontact', 1);
GO

UPDATE dbo.longcontact
SET prenom = 'Albert'
WHERE longcontactId = 1;
GO

TRUNCATE TABLE dbo.longcontact
GO
INSERT INTO dbo.longcontact (longcontactId, nom, prenom)
SELECT 2, REPLICATE('N', 5000), REPLICATE('P', 3100)
INSERT INTO dbo.longcontact (longcontactId, nom, prenom)
SELECT 3, REPLICATE('N', 5000), REPLICATE('P', 3100)
GO

CREATE TABLE dbo.troplongcontact (
    troplongcontactId int NOT NULL PRIMARY KEY,
    nom char(8000), 
    prenom varchar(5000)
)
GO

INSERT INTO dbo.troplongcontact (troplongcontactId, nom, prenom)
SELECT 2, REPLICATE('N', 8000), REPLICATE('P', 1000)
INSERT INTO dbo.troplongcontact (troplongcontactId, nom, prenom)
SELECT 3, REPLICATE('N', 8000), REPLICATE('P', 1000)
GO

DBCC TRACEON (3604)
DBCC PAGE (tempdb, 1, 127, 3)
GO


-------------------------------------------------
-- FILESTREAM

EXEC sp_configure 'filestream_access_level', '[niveau d'activation]'
RECONFIGURE
GO

ALTER DATABASE AdventureWorks
ADD FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM

ALTER DATABASE AdventureWorks
ADD FILE
  ( NAME = N'AdventureWorks_media',
    FILENAME = N'E:\sqldata\AdventureWorks_media')
TO FILEGROUP [FileStreamGroup1]
GO

CREATE TABLE dbo.document (
    documentId uniqueidentifier NOT NULL ROWGUIDCOL 
        DEFAULT (NEWID()) PRIMARY KEY NONCLUSTERED ,
    nom varchar(1000) NOT NULL,
    document varbinary(max) FILESTREAM);
GO

SELECT 'babaluga', CAST('plein de choses à dire' as varbinary(max))

SELECT 
    nom,
    CAST(document as varchar(max)) as document,
    document.PathName()
FROM dbo.document
GO


