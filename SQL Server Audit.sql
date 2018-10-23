USE [master]
GO

/****** Object:  Audit [DATABASE_OBJECT_CHANGE_GROUP]    Script Date: 23.07.2018 15:18:20 ******/
CREATE SERVER AUDIT [DATABASE_OBJECT_CHANGE_GROUP]
TO FILE 
(	FILEPATH = N'H:\Distrib\'
	,MAXSIZE = 1024 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = ON
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = 'ad4113d9-f181-4500-9bca-4dbeea74b352'
)
WHERE (NOT [statement] like 'ALTER INDEX%REBUILD%' AND NOT [statement] like 'ALTER INDEX%REORGANIZE%')
ALTER SERVER AUDIT [DATABASE_OBJECT_CHANGE_GROUP] WITH (STATE = ON)
GO


USE [master]
GO

/****** Object:  Audit [AuditJobs]    Script Date: 23.07.2018 15:18:07 ******/
CREATE SERVER AUDIT [AuditJobs]
TO FILE 
(	FILEPATH = N'H:\Distrib\'
	,MAXSIZE = 2048 MB
	,MAX_FILES = 2
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = '7c5b55af-e272-46e9-beef-d37ed4c8edb2'
)
ALTER SERVER AUDIT [AuditJobs] WITH (STATE = ON)
GO

--Аудит Create table/index/schema & etc
USE [master]
GO

CREATE SERVER AUDIT SPECIFICATION [DATABASE_OBJECT_CHANGE_GROUP]
FOR SERVER AUDIT [DATABASE_OBJECT_CHANGE_GROUP]
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = ON)
GO

--Аудит msdb
USE [msdb]
GO

CREATE DATABASE AUDIT SPECIFICATION [AuditJobsAndAlerts]
FOR SERVER AUDIT [AuditJobs]
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_jobstep] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_jobstep] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_jobstep] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_job] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_job] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_job] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_alert] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_alert] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_alert] BY [public])
WITH (STATE = ON)
GO



--Просмотр через T-SQL
select * 
from fn_get_audit_file( 'H:\Distrib\*', null, null ) 
order by event_time desc
        ,sequence_number
