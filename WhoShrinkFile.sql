DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);
 
-- Get the name of the current default trace

SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1
      AND property = 2;
 
-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.', @filename);
SET @ec = CHARINDEX('_', @filename)+1;
SET @efn = REVERSE(SUBSTRING(@filename, 1, @bc));
SET @bfn = REVERSE(SUBSTRING(@filename, @ec, LEN(@filename)));
 
-- set filename without rollover number
SET @filename = @bfn + @efn;
SELECT EventType = e.name,
       t.DatabaseName,
       t.ApplicationName,
       t.LoginName,
       t.HostName,
       CONVERT(NVARCHAR(30), t.StartTime, 104) AS Date,
       CONVERT(NVARCHAR(30), t.StartTime, 114) AS Time,
       TextData
FROM sys.traces i
     CROSS APPLY sys.fn_trace_gettable(@filename, DEFAULT) t
     JOIN sys.trace_events e ON t.EventClass = e.trace_event_id
WHERE TextData LIKE '%Shrink%'
      AND e.name != 'Audit Server Alter Trace Event';




