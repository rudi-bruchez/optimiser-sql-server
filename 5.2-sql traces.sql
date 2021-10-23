-- événement personnalisé
DECLARE @userdata varbinary(8000)
SET @userdata = CAST('c''est moi' as varbinary(8000))

EXEC sys.sp_trace_generateevent
      @event_class = 82, 
      @userinfo = N'J''existe !!',
      @userdata = @userdata
GO

-- importation de trace
SELECT * INTO dbo.matrace
FROM sys.fn_trace_gettable('c:\temp\matrace.trc', default);
GO

SELECT 
    CAST(TextData as varchar(8000)) as TextData,
    COUNT(*) as Executions,
    AVG(reads) as MoyenneReads,
    AVG(CPU) as MoyenneCPU,
    AVG(Duration) / 1000 as MoyenneDurationMillisecondes
FROM dbo.matrace
WHERE EventClass IN (
    SELECT trace_event_id
    FROM sys.trace_events
    WHERE name LIKE 'S%Completed')
GROUP BY CAST(TextData as varchar(8000))
ORDER BY MoyenneReads DESC, MoyenneCPU DESC;
GO

-- trace_events
SELECT tc.name as categorie, te.name as evenement, trace_event_id
FROM sys.trace_categories tc
JOIN sys.trace_events te ON tc.category_id = te.category_id
ORDER BY categorie, evenement;  
GO

-- traces systèmes
SELECT * FROM fn_trace_getinfo(1);
GO

-- trace par défaut
EXEC sp_configure 'show advanced options' , 1;
RECONFIGURE;
EXEC sp_configure 'default trace enabled', 0;
EXEC sp_configure 'show advanced options' , 0;
RECONFIGURE;
GO

DECLARE @traceId int
EXEC sys.sp_trace_create @traceId OUTPUT, @Options = 8;
EXEC sys.sp_trace_setstatus @traceId, 1;
SELECT @traceId;
GO

-- prcédure startup
EXEC sys.sp_procoption 'ma_procedure', 'STARTUP', 'ON';
