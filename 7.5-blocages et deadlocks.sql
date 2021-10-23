-- détection de blocages
SELECT session_id, wait_duration_ms, wait_type,  
    blocking_session_id, resource_description
FROM sys.dm_os_waiting_tasks
WHERE blocking_session_id IS NOT NULL;
GO

SELECT blocked.session_id, st.text as blocked_sql,
    blocker.session_id as blocker_session_id, blocker.last_request_end_time
FROM sys.dm_exec_requests blocked
JOIN sys.dm_exec_sessions blocker
    ON blocked.blocking_session_id = blocker.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) st;
GO

---------------------------------------------
-- détection par notification d'événements --
---------------------------------------------
SELECT 
      es2.session_id as spid_blocking,
      es1.session_id as spid_blocked,
      er1.start_time as blocked_start, 
      er1.row_count, 
      CASE er1.transaction_isolation_level
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'ReadUncommitted'
            WHEN 2 THEN 'Readcommitted'
            WHEN 3 THEN 'RepeatableRead'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot' 
      END as transaction_isolation_level,
      DB_NAME(er1.database_id) as db,
      est1.text as sql_command_blocked,
      er1.wait_type,
      es1.host_name as host_name_blocked,
      es1.program_name as program_name_blocked,
      es1.login_name as login_name_blocked,
      es2.host_name as host_name_blocking,
      es2.program_name as program_name_blocking,
      es2.login_name as login_name_blocking
FROM sys.dm_exec_requests er1
JOIN sys.dm_exec_sessions es1 
      ON er1.session_id = es1.session_id
CROSS APPLY sys.dm_exec_sql_text(er1.sql_handle) est1
JOIN sys.dm_exec_sessions es2 
      ON er1.blocking_session_id = es2.session_id
ORDER BY spid_blocking;
GO

-- configuration du délai
EXEC sp_configure 'show advanced options', 1
RECONFIGURE 
GO
EXEC sp_configure 'blocked process threshold', 30
RECONFIGURE
GO
EXEC sp_configure 'show advanced options', 0
RECONFIGURE 
GO

-- structure Service Broker
CREATE QUEUE NotifyQueue ;
GO

CREATE SERVICE NotifyService
ON QUEUE NotifyQueue
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE ROUTE NotifyRoute
WITH SERVICE_NAME = 'NotifyService',
ADDRESS = 'LOCAL';
GO

CREATE EVENT NOTIFICATION BlockedProcessReport
    ON SERVER
    WITH fan_in
FOR  BLOCKED_PROCESS_REPORT
TO SERVICE 'NotifyService', 'current database';
GO

-- test
USE sandbox
GO

CREATE TABLE dbo.testblocage ( id int )

BEGIN TRAN
INSERT dbo.testblocage ( id ) VALUES( 1 )
GO

--  dans une autre session
SELECT * FROM sandbox.dbo.testblocage
GO

-- voyons la queue
SELECT CAST(message_body as XML) as msg
FROM NotifyQueue;
GO

-- réception de l'événement
CREATE TABLE dbo.BlockedProcesses (
   message_body xml NOT NULL,
   report_time datetime NOT NULL,
   database_id int NOT NULL,
   process xml NOT NULL
)
GO

BEGIN TRY
   BEGIN TRAN
   DECLARE @BlockedProcesses TABLE (
      message_body xml NOT NULL,
      report_time datetime NOT NULL,
      database_id int NOT NULL,
      process xml NOT NULL
   );
   DECLARE @rowcount int;

   RECEIVE cast( message_body as xml ) as message_body,
      cast( message_body as xml ).value( '(/EVENT_INSTANCE/PostTime)[1]', 'datetime' ) as report_time,
      cast( message_body as xml ).value( '(/EVENT_INSTANCE/DatabaseID)[1]', 'int' ) as database_id,
      cast( message_body as xml ).query( '/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process' ) as process
   FROM NotifyQueue
   INTO @BlockedProcesses;
   SET @rowcount = @@ROWCOUNT

   INSERT INTO dbo.BlockedProcesses
   SELECT * FROM @BlockedProcesses;
   IF (@rowcount <> @@ROWCOUNT)
      ROLlBACK
   ELSE
      COMMIT TRAN
END TRY
BEGIN CATCH
   ROLLBACK TRAN
END CATCH
GO

---------------
-- deadlocks --
---------------

-- EXEMPLE
-- dans la session 1
BEGIN TRAN

UPDATE HumanResources.Employee SET MaritalStatus = 'S'
WHERE Gender = 'F'

UPDATE c SET Title = 'Miss'
FROM Person.Contact c
JOIN HumanResources.Employee e WITH (READUNCOMMITTED)
	ON c.ContactID = e.ContactID
WHERE e.Gender = 'F'

COMMIT TRAN

-- dans la session 2
BEGIN TRAN

UPDATE c SET Suffix = 'Mrs'
FROM Person.Contact c
JOIN HumanResources.Employee e WITH (READUNCOMMITTED)
	ON c.ContactID = e.ContactID
WHERE e.Gender = 'F'

UPDATE HumanResources.Employee SET MaritalStatus = 'M'
WHERE Gender = 'F'

COMMIT TRAN
GO

-- détection
DBCC TRACEON(1204, -1)
