-- query governor
exec sp_configure 'show advanced options', 1;
reconfigure;
exec sp_configure 'query governor cost limit', 10;
reconfigure;
exec sp_configure 'show advanced options', 0;
reconfigure;
GO

-- par session
SET QUERY_GOVERNOR_COST_LIMIT 10;

-- resource governor
CREATE RESOURCE POOL [intrus] 
WITH( min_cpu_percent=0, 
      max_cpu_percent=20, 
      min_memory_percent=0, 
      max_memory_percent=10);
GO

ALTER RESOURCE GOVERNOR DISABLE;
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

CREATE WORKLOAD GROUP [méchantes requêtes]
WITH( group_max_requests=10, 
      importance=Low, 
      request_max_cpu_time_sec=0, 
      request_max_memory_grant_percent=25, 
      request_memory_grant_timeout_sec=0, 
      max_dop=1) 
USING [intrus]
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

CREATE FUNCTION dbo.rgclassifier_v01() RETURNS SYSNAME 
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @grp_name AS SYSNAME
      IF (SUSER_NAME() = 'Nicolas') or (APP_NAME() LIKE '%Elysee%')
          SET @grp_name = 'méchantes requêtes'
      ELSE
          SET @grp_name = NULL
    RETURN @grp_name
END
GO
-- Register the classifier function with Resource Governor
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION= dbo.rgclassifier_v01)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

SELECT * 
FROM sys.dm_exec_sessions es
JOIN sys.resource_governor_workload_groups rswg ON es.group_id = rswg.group_id;
GO

ALTER WORKLOAD GROUP [méchantes requêtes]
USING [default];
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

