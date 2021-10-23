-- fill factor
SELECT SCHEMA_NAME(o.schema_id) + '.' + o.name as table_name, 
    i.name as index_name, 
    i.fill_factor
FROM sys.indexes i
JOIN sys.objects o ON i.object_id = o.object_id
WHERE fill_factor <> 0
ORDER BY table_name;
GO

-- défragmentation
ALTER INDEX ALL ON Person.Contact REBUILD;
GO

ALTER INDEX nix$Person_Contact$LastName
ON Person.Contact
REBUILD WITH (FILLFACTOR = 50);
GO

CREATE INDEX nix$Person_Contact$FirstName
ON Person.Contact (FirstName)

SELECT index_id, *
FROM sys.indexes 
WHERE name = 'nix$Person_Contact$FirstName'
AND object_id = OBJECT_ID('Person.Contact')

SELECT * FROM sys.dm_db_index_physical_stats
    (DB_ID(N'AdventureWorks'), 
     OBJECT_ID(N'Person.Contact'), 22, NULL , 'DETAILED')
ORDER BY index_level DESC;

ALTER INDEX nix$Person_Contact$FirstName
ON Person.Contact
REBUILD WITH (FILLFACTOR = 20)
-- ou :
CREATE INDEX nix$Person_Contact$FirstName
ON Person.Contact (FirstName)
WITH FILLFACTOR = 20,
     DROP_EXISTING;

SELECT * 
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'AdventureWorks'), 
    OBJECT_ID(N'Person.Contact'), 22, NULL , 'DETAILED')
ORDER BY index_level DESC;
GO
