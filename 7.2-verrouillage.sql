BEGIN TRAN
BEGIN TRY
	UPDATE Purchasing.PurchaseOrderHeader 
	SET ShipDate = DATEADD(day, 10, ShipDate)

	UPDATE Purchasing.PurchaseOrderDetail
	SET DueDate = DATEADD(day, 10, DueDate)

	COMMIT TRAN
END TRY
BEGIN CATCH
	IF (XACT_STATE()) <> 0
		ROLLBACK TRAN
END CATCH
GO

USE AdventureWorks
GO

BEGIN TRAN

UPDATE TOP (1) Sales.Currency
SET ModifiedDate = current_timestamp
GO
--Examinons les verrous :
SELECT
   tl.resource_type,
   tl.resource_subtype,
   DB_NAME(tl.resource_database_id) as db,
   tl.resource_description,
   CASE tl.resource_type
      WHEN 'OBJECT' THEN OBJECT_NAME(tl.resource_associated_entity_id) 
      ELSE COALESCE(OBJECT_NAME(p.object_id), 
         CAST(tl.resource_associated_entity_id as sysname))
   END as obj,
   tl.request_mode,
   tl.request_status
FROM sys.dm_tran_locks tl
LEFT JOIN sys.partitions p 
   ON tl.resource_associated_entity_id = p.hobt_id
WHERE 
   tl.request_session_id = @@SPID AND
   tl.resource_database_id = DB_ID()
ORDER BY
   CASE resource_type
      WHEN 'KEY' THEN 1
      WHEN 'RID' THEN 1
      WHEN 'PAGE' THEN 2
      WHEN 'EXTENT' THEN 3
      WHEN 'HOBT' THEN 4
      WHEN 'ALLOCATION_UNIT' THEN 5
      WHEN 'OBJECT' THEN 6
      WHEN 'DATABASE' THEN 7
      WHEN 'FILE' THEN 8
      ELSE 9
   END
GO

-- latches
SELECT wait_type,  
       waiting_tasks_count,  
       wait_time_ms 
FROM sys.dm_os_wait_stats   
WHERE wait_type like 'PAGEIOLATCH%'   
ORDER BY wait_type 
GO

-- granularité
SELECT 
    OBJECT_NAME(ios.object_id) as table_name,
    i.name as index_name,
    i.type_desc as index_type,
    row_lock_count,
    row_lock_wait_count,
    row_lock_wait_in_ms,
    page_lock_count,
    page_lock_wait_count,
    page_lock_wait_in_ms,
    index_lock_promotion_attempt_count,
    index_lock_promotion_count
FROM sys.dm_db_index_operational_stats(
    DB_ID('AdventureWorks'), 
    OBJECT_ID('Person.Contact'), NULL, NULL) ios
JOIN sys.indexes i ON ios.object_id = i.object_id AND ios.index_id = i.index_id
ORDER BY ios.index_id;

-- augmenter la granularité
SELECT
    OBJECT_NAME(object_id) as table_name, 
    name as index_name, 
    allow_row_locks, 
    allow_page_locks
FROM sys.indexes
WHERE allow_row_locks & allow_page_locks = 0
ORDER BY table_name, index_name;

ALTER INDEX PK_Contact_ContactID
  ON Person.Contact
  SET (ALLOW_ROW_LOCKS = OFF, ALLOW_PAGE_LOCKS = OFF);

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
SELECT LastName, FirstName, EmailAddress
FROM Person.Contact
WHERE LastName = 'Adams';

SELECT 
    CASE es.transaction_isolation_level
        WHEN 0 THEN 'non spécifié' 
        WHEN 1 THEN 'READ UNCOMMITTED'
        WHEN 2 THEN 'READ COMMITTED' 
        WHEN 3 THEN 'REPEATABLE'
        WHEN 4 THEN 'SERIALIZABLE' 
        WHEN 5 THEN 'SNAPSHOT'
    END as transaction_isolation_level,
    tl.request_session_id as spid, tl.resource_type, tl.request_mode,
    tl.request_type,
    CASE 
        WHEN tl.resource_type = 'object' THEN
            OBJECT_NAME(tl.resource_associated_entity_id)
        WHEN tl.resource_type = 'database' THEN 
            DB_NAME(tl.resource_associated_entity_id)
        WHEN tl.resource_type IN ('key','page') THEN
            (SELECT object_name(i.object_id) + '.' + i.name 
             FROM sys.partitions p
             JOIN sys.indexes i ON p.object_id = i.object_id
             AND p.index_id = i.index_id
             WHERE p.hobt_id = tl.resource_associated_entity_id)
        ELSE CAST(tl.resource_associated_entity_id as varchar(20))
END as objet
FROM sys.dm_tran_locks tl
LEFT JOIN sys.dm_exec_sessions es 
        ON tl.request_session_id = es.session_id
WHERE request_session_id = @@spid
ORDER BY 
    CASE resource_type
        WHEN 'DATABASE' THEN 10
        WHEN 'METADATA' THEN 20
        WHEN 'OBJECT' THEN 30
        WHEN 'PAGE' THEN 40
        WHEN 'KEY' THEN 50
        ELSE 100
    END

ROLLBACK
  
ALTER INDEX PK_Contact_ContactID
   ON Person.Contact
   SET (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

-- diminuer la granularité
BEGIN TRAN
UPDATE Person.Contact
SET LastName = UPPER(LastName);

UPDATE TOP (1000) Person.Contact
SET LastName = UPPER(LastName);
ROLLBACK
GO

DECLARE @incr int, @rowcnt int

SET @incr = 1
SET @rowcnt = 1

WHILE @rowcnt > 0 BEGIN
    UPDATE TOP (1000) Person.Contact
    SET LastName = UPPER(LastName)
    WHERE ContactID >= @incr

    SET @rowcnt = @@ROWCOUNT
    SET @incr = @incr + 1000
END
GO

BEGIN TRAN
SELECT TOP (0) * FROM Person.Contact WITH (UPDLOCK, HOLDLOCK)
GO


