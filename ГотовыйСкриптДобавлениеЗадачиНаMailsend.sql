
declare @jobID nvarchar(255)
set @jobID = ( 


select top 1job_id from msdb.dbo.sysjobs
where name='BackupSuccessMailSend'
)
EXEC msdb.dbo.sp_delete_job @job_id=@jobID, @delete_unused_schedule=1
GO

  USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'BackupSuccessMailSend', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
declare @servername nvarchar(255)
set @servername = CONVERT(NVARCHAR(255),SERVERPROPERTY('ServerName'),2)

EXEC msdb.dbo.sp_add_jobserver @job_name=N'BackupSuccessMailSend', @server_name = @servername
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'BackupSuccessMailSend', @step_name=N'BackupSuccess', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @BackupID int
if
(select top 1 mailsend from msdb.dbo.backupset as bs where mailsend = 0 order by bs.backup_finish_date desc ) = 0
begin
DECLARE db_cursor CURSOR FOR 
SELECT backup_set_id 
FROM msdb.dbo.backupset as bs where mailsend = 0
OPEN db_cursor 
FETCH NEXT FROM db_cursor INTO @BackupID 
WHILE @@FETCH_STATUS = 0 
BEGIN 
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
set @Subject1 = '' backup_report: mssql_''
set @subject2 = (select @@SERVERNAME)
set @subject5=''_''+(select CASE type
		WHEN ''L''
			THEN ''Logs''
		WHEN ''D''
			THEN ''Full''
		WHEN ''I''
			THEN ''Differential''
		END
		from  msdb.dbo.backupset	 as bs
		where backup_set_id=@BackupID
)
 
set @subject3 = ''Time of Backup=''
set @timeBackup = (select ''ВремяВыполнения''=
	CASE
--минуты
WHEN DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)/3600%24 AS VARCHAR(4)) + '' '' + ''h''+'' ''+CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''  
--Минуты 
WHEN DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) >60
THEN CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
--секунды 
WHEN DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) < 60
THEN CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
		Else ''can''''n show''
		END
		from  msdb.dbo.backupset	 as bs
		where backup_set_id=@BackupID
)
If
(select bs.backup_size from msdb.dbo.backupset as bs where backup_set_id= @BackupID ) <0
set @subject4 = ''Errors occurred during this backup''
Else
set @subject4=''''
set @subject6='' has finished:''
set @Subject = @Subject1+@subject2+@subject5+@subject6+@subject3+@timebackup+@subject4

-----ГенерацияТемыКонец
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
<th>ServerName</th>
<th>DatabaseName</th>
<th>BackupType</th>
<th>DateStart</th>
<th>TimeStart</th>
<th>TimeFinish</th>
<th>TimeRun</th>
<th>Backup_size</th>
<th>AVG/s</th>
<th>PhysicalDeviceName</th>
<th>BackupState</th>
<th>WhoRun</th>''
 +
    CAST ( (
SELECT td=server_name,       ''''
,td=database_name,       ''''
 ,td=CASE type
		WHEN ''L''
			THEN ''Logs''
		WHEN ''D''
			THEN ''Full''
		WHEN ''I''
			THEN ''Differential''
			ELSE ''UNKNOWN''
		END,       ''''
	,td=(
		SELECT convert(VARCHAR(10), bs.backup_start_date, 104)
		),       ''''
	,td=(
		SELECT convert(VARCHAR(8), bs.backup_start_date, 114)
		),       ''''
	,td=(
		SELECT convert(VARCHAR(8), bs.backup_finish_date, 114)
		),       ''''
	,td=
	CASE
--минуты
WHEN DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)/3600%24 AS VARCHAR(4)) + '' '' + ''h''+'' ''+CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''  
--Минуты 
WHEN DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) >60
THEN CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
--секунды 
WHEN DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) < 60
THEN CAST(DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
		Else ''can''''n show''
		END,       ''''

,td=
CASE
--Гигабайты
WHEN (bs.backup_size / 1099511627776) > 1
THEN
CAST(Cast(bs.backup_size / 1099511627776 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' TB''
WHEN (bs.backup_size / 1073741824) > 1
THEN
CAST(CAST(bs.backup_size / 1073741824 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' GB''
--Мегабайты
WHEN (bs.backup_size / 1048576) > 1
THEN
CAST(CAST(bs.backup_size / 1048576 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' MB''
--Килобайты
WHEN (bs.backup_size / 1024) > 1
THEN
CAST(CAST(bs.backup_size / 1024 AS DECIMAL(4, 0)) AS VARCHAR(14)) + '' KB''
Else ''Backup=0 Warning!''
END,       ''''
,td = 
Case
WHEN bs.backup_size <= 0 or DATEDIFF(second, bs.backup_start_date, bs.backup_finish_date) <0
THEN ''0''
--Терабайты в Гигабиты
WHEN (backup_size / 13421772) > 1 and DATEDIFF(second, backup_start_date, backup_finish_date) >0
THEN
CAST(CAST((backup_size/DATEDIFF(second, backup_start_date, backup_finish_date))/134217728 as decimal(6,1)) as varchar(14))+ '' Gbit''
--Мегабайты
WHEN (bs.backup_size / 1048576) > 1 
THEN							 
CAST(CAST(bs.backup_size / 1048576 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' MB''
--Килобайты
WHEN (bs.backup_size / 1024) > 1
THEN
CAST(CAST(bs.backup_size / 1024 AS DECIMAL(4, 0)) AS VARCHAR(14)) + '' KB''
Else ''HyperSpeed''
END,       ''''
,td = mf.physical_device_name,       '''' 
,td = 
	Case 
	WHEN bs.backup_size < 0 Then ''Errors occurred during this backup''
	When bs.backup_size > 0 Then ''has finished without errors''
	END,       ''''
,td=	user_name,       ''''

FROM msdb.dbo.backupset as bs
left join msdb.dbo.backupmediafamily as MF on mf.media_set_id=bs.media_set_id
where backup_set_id=@BackupID
ORDER BY bs.backup_finish_date DESC
              FOR XML PATH(''tr''), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N''</table>'' ;

EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = ''ForBackup'',
	@recipients = ''dbashift@fcod.nalog.ru'',
    @subject = @Subject,
    @body = @tableHTML,
    @body_format = ''HTML''

 --Если Все удачно ставим 1
update msdb.dbo.backupset
set mailsend =1
where backup_set_id=@BackupID
FETCH NEXT FROM db_cursor INTO @BackupID 
END

CLOSE db_cursor 
DEALLOCATE db_cursor
end
else
print ''НетНовыхСообщений''

', 
		@database_name=N'msdb', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'BackupSuccessMailSend', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'BackupSuccessMailSend', @name=N'Every1Min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20171018, 
		@active_end_date=99991231, 
		@active_start_time=1, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
		USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'BackupSuccessMailSend', @step_name=N'Purge_job_history', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @twosec nvarchar(25)
set @twosec = (select GETDATE()-0.001)
EXEC msdb.dbo.sp_purge_jobhistory  
@oldest_date=@twosec
,@job_name = ''BackupSuccessMailSend''

', 
		@database_name=N'msdb', 
		@flags=0
GO

USE [msdb]
GO

declare @jobID nvarchar(255)
set @jobID = (
select top 1 job_id from msdb.dbo.sysjobs
where name ='BackupSuccessMailSend')

EXEC msdb.dbo.sp_update_job @job_id=@jobID,
		@notify_level_email=2, 
		@notify_level_page=2, 
		@notify_email_operator_name=N'p_varaks_test'
GO

declare @jobID nvarchar(255)
set @jobID = (
select top 1 job_id from msdb.dbo.sysjobs
where name ='BackupSuccessMailSend')
  select @jobID

declare @scheduleID nvarchar(255)
set @scheduleID = (
select top 1 schedule_id from msdb.dbo.sysjobschedules
where job_id = @jobID)

select @scheduleID
EXEC msdb.dbo.sp_attach_schedule @job_id=@jobid,@schedule_id=@scheduleID
GO


