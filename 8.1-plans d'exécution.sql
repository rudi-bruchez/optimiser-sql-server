-- extraction du plan des requêtes en cours
SELECT er.session_id, er.start_time, er.status, er.command, 
	st.text, qp.query_plan
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) qp
GO

-- un emprunt à http://www.sqlskills.com/blogs/bobb/2006/03/03/MoveOverDevelopersSQLServerXQueryIsActuallyADBATool.aspx.
CREATE PROCEDURE LookForPhysicalOps (@op VARCHAR(30))
AS
SELECT sql.text, qs.EXECUTION_COUNT, qs.*, p.*
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) sql
CROSS APPLY sys.dm_exec_query_plan(plan_handle) p
WHERE query_plan.exist('
declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";
/ShowPlanXML/BatchSequence/Batch/Statements//RelOp/@PhysicalOp[. = sql:variable("@op")]
') = 1
GO

EXECUTE LookForPhysicalOps 'Clustered Index Scan'
EXECUTE LookForPhysicalOps 'Hash Match'
EXECUTE LookForPhysicalOps 'Table Scan'
GO

SELECT TOP 0 * FROM Person.Address;
SELECT * FROM Person.Address WHERE 1 = 0;
GO
