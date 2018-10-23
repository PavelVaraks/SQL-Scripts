--Delete job if exist
use [msdb]
declare @jobID nvarchar(255)
set @jobID = ( 


select job_id from msdb.dbo.sysjobs
where name='ErrorBackupMailSend'
)
EXEC msdb.dbo.sp_delete_job @job_id=@jobID, @delete_unused_schedule=1
GO
--Delete job if exist


--Create Job ErrorBackupMailSend
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'ErrorBackupMailSend', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'AlertSql', @job_id = @jobId OUTPUT
select @jobId
GO
declare @servername nvarchar(255)
set @servername = (convert(nvarchar(255),SERVERPROPERTY('servername'),2))
EXEC msdb.dbo.sp_add_jobserver @job_name=N'ErrorBackupMailSend', @server_name = @servername
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'ErrorBackupMailSend', @step_name=N'ErrorBackupMailSend', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @time1 nvarchar(255)
declare @time2 nvarchar(255)

set @time1 =convert(VARCHAR(30), getdate()-0.00001578703300, 21)
set @time2 =convert(VARCHAR(30), getdate()+0.00001578703300, 21)

create table #BackupError
(Time nvarchar(255),
 ProcessInfo nvarchar(255),
 TEXT nvarchar(255)
)

insert into #BackupError
exec master.sys.xp_readerrorlog 0, 1, N''Backup'',null,@time1,@time2,N''desc''

-----ГенерацияТемы
declare @Subject nvarchar(255)
declare @Subject1 nvarchar(255) 
declare @subject2 nvarchar(255)
declare @subject3 nvarchar(255)
declare @subject4 nvarchar(255)
declare @subject5 nvarchar(255)
declare @subject6 nvarchar(255)
declare @query1 nvarchar(255)
declare @timebackup nvarchar(255)
set @Subject1 = '' backup_report_mssql_''
set @subject2 = (select @@SERVERNAME)
set @subject5 =
''_''+(select top 1 CASE 
		WHEN TEXT LIKE ''%DIFFERENTIAL%''
			THEN ''DIFFERENTIAL''
		WHEN TEXT LIKE ''%BACKUP DATABASE%''
			THEN ''Full''
		WHEN TEXT LIKE ''%BACKUP LOG%''
			THEN ''Log''
		END
		from  #BackupError
		where TEXT like ''%DIFFERENTIAL%'' or
		text like ''%BACKUP DATABASE%'' or TEXT like ''%BACKUP LOG%'')
 
set @subject3 = ''Time of Backup=0 sec''
set @subject4 = '':Errors occurred during this backup''
set @subject6='' has finished:''
set @Subject = @Subject1+@subject2+@subject5+@subject6+@subject3+@subject4
  select @Subject
-----ГенерацияТемыКонец

--ГенерацияПисьма
DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML = 
N''<style type="text/css">
#box-table
{
font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
font-size: 12px;
text-align: center;
border-collapse: collapse;
border-top: 7px solid #9baff1;
border-bottom: 7px solid #9baff1;
}
#box-table th
{
font-size: 13px;
font-weight: normal;
background: #b9c9fe;
border-right: 2px solid #9baff1;
border-left: 2px solid #9baff1;
border-bottom: 2px solid #9baff1;
color: #039;
}
#box-table td
{
border-right: 1px solid #aabcfe;
border-left: 1px solid #aabcfe;
border-bottom: 1px solid #aabcfe;
color: #669;
}
tr:nth-child(odd) { background-color:#eee; }
tr:nth-child(even) { background-color:#fff; } 
</style>''+ 
--N''<H3><font color="Red">Бэкап</H3>'' +
N''<table id="box-table" >'' +
N''
<th>LogDate</th>
<th>ProcessInfo</th>
<th>Text</th>''
 +
    CAST ( (
SELECT 
td=Time,       ''''
,td=ProcessInfo,       ''''
 ,td=TEXT,       ''''
FROM #BackupError
              FOR XML PATH(''tr''), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N''</table>'' ;
 
EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = ''ForBackup'',
	@recipients = ''dbashift@fcod.nalog.ru'',
    @subject = @Subject,
    @body = @tableHTML,
    @body_format = ''HTML''
go
drop table #BackupError


', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'ErrorBackupMailSend', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'AlertSql', 
		@notify_page_operator_name=N''
GO
--Create Job ErrorBackupMailSend