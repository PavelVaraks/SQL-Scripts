--ВключаемАгента
IF NOT EXISTS (
select 1 from master.dbo.sysprocesses
where program_name = 'SQLAgent - Generic Refresher')
BEGIN
EXEC xp_servicecontrol N'START',N'SQLServerAGENT' 
END
Print 'Агент Запущен'
go
--ВключаемМодульMailService
sp_CONFIGURE 'show advance', 1
GO
RECONFIGURE 
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE 
GO

declare @twoweek nvarchar(25)
set @twoweek = (select getdate()-14)
EXEC msdb.dbo.sp_purge_jobhistory @oldest_date=@twoweek
--ДляБэкапов
DECLARE @profile_name sysname,
@account_name sysname,
@email_address NVARCHAR(128),
@display_name NVARCHAR(128),
@replyto_address nvarchar(128);
SET @profile_name = 'ForBackup';
SET @account_name = 'gridcontrol';
declare @SMTP_serverName nvarchar(255)
declare @SMTP_serverFullName nvarchar(255)
DECLARE @Domain NVARCHAR(100)
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\services\Tcpip\Parameters', N'Domain',@Domain OUTPUT
declare @servername nvarchar(255)
set @servername = Replace(convert(nvarchar(200), SERVERPROPERTY('ServerName'),2),RIGHT(convert(nvarchar(200), SERVERPROPERTY('ServerName'),2),6),'')
IF @servername in ('n5001-','n5201-')
BEGIN
Set @SMTP_serverName=@servername+'mail.'
SET @SMTP_serverFullName = @SMTP_serverName+@Domain
END
Else
set @SMTP_serverFullName = 'm9965-sys055'
SET @email_address = 'gridcontrol@fcod.nalog.ru';
SET @display_name = 'gridcontrol';
SET @replyto_address = 'dbashift@fcod.nalog.ru';
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
--RAISERROR('The specified Database Mail profile (<profile_name,sysname,SampleProfile>) already exists.', 16, 1);
print @profile_name + 'профайл уже добавлен'
GOTO done;
END;
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
BEGIN
RAISERROR('The specified Database Mail account (<account_name,sysname,SampleAccount>) already exists.', 16, 1) ;
GOTO done;
END;

BEGIN TRANSACTION ;
DECLARE @rv INT;
EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
@account_name = @account_name,
@use_default_credentials = 1,
@replyto_address= @replyto_address,
@email_address = @email_address,
@display_name = @display_name,
@mailserver_name = @SMTP_serverFullName;

IF @rv<>0
BEGIN
RAISERROR('Failed to create the specified Database Mail account (<account_name,sysname,SampleAccount>).', 16, 1) ;
GOTO done;
END
EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
@profile_name = @profile_name ;
IF @rv<>0
BEGIN
RAISERROR('Failed to create the specified Database Mail profile (<profile_name,sysname,SampleProfile>).', 16, 1);
ROLLBACK TRANSACTION;
GOTO done;
END;
EXECUTE @rv=msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = @profile_name,
@account_name = @account_name,
@sequence_number = 1 ;
IF @rv<>0
BEGIN
RAISERROR('Failed to associate the speficied profile with the specified account (<account_name,sysname,SampleAccount>).', 16, 1) ;
ROLLBACK TRANSACTION;
GOTO done;
END;
COMMIT TRANSACTION;
done:
GO
--Пользователь для Алертов
DECLARE @profile_name sysname,
@account_name sysname,
@SMTP_servername sysname,
@email_address NVARCHAR(128),
@display_name NVARCHAR(128),
@replyto_address nvarchar(128);
SET @profile_name = 'AlertSystem';
SET @account_name = 'AlertSql';


declare @SMTP_serverFullName nvarchar(255)
DECLARE @Domain NVARCHAR(100)
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\services\Tcpip\Parameters', N'Domain',@Domain OUTPUT
declare @servername nvarchar(255)
set @servername = Replace(convert(nvarchar(200), SERVERPROPERTY('ServerName'),2),RIGHT(convert(nvarchar(200), SERVERPROPERTY('ServerName'),2),6),'')
IF @servername in ('n5001-','n5201-')
BEGIN
Set @SMTP_serverName=@servername+'mail.'
SET @SMTP_serverFullName = @SMTP_serverName+@Domain
END
Else
set @SMTP_serverFullName = 'm9965-sys055'
SET @email_address = 'AlertSql@fcod.nalog.ru';
SET @display_name = 'AlertSql';
SET @replyto_address = 'dbashift@fcod.nalog.ru';

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
--RAISERROR('The specified Database Mail profile (<profile_name,sysname,SampleProfile>) already exists.', 16, 1);
print @profile_name + 'профайл уже добавлен'
GOTO done;
END;
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
BEGIN
RAISERROR('The specified Database Mail account (<account_name,sysname,SampleAccount>) already exists.', 16, 1) ;
GOTO done;
END;

BEGIN TRANSACTION ;
DECLARE @rv INT;

EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
@account_name = @account_name,
@use_default_credentials = 1,
@replyto_address= @replyto_address,
@email_address = @email_address,
@display_name = @display_name,
@mailserver_name = @SMTP_serverFullName;

IF @rv<>0
BEGIN
RAISERROR('Failed to create the specified Database Mail account (<account_name,sysname,SampleAccount>).', 16, 1) ;
GOTO done;
END
-- Add the profile
EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
@profile_name = @profile_name ;
IF @rv<>0
BEGIN
RAISERROR('Failed to create the specified Database Mail profile (<profile_name,sysname,SampleProfile>).', 16, 1);
ROLLBACK TRANSACTION;
GOTO done;
END;
-- Associate the account with the profile.
EXECUTE @rv=msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = @profile_name,
@account_name = @account_name,
@sequence_number = 1 ;
IF @rv<>0
BEGIN
RAISERROR('Failed to associate the speficied profile with the specified account (<account_name,sysname,SampleAccount>).', 16, 1) ;
ROLLBACK TRANSACTION;
GOTO done;
END;
COMMIT TRANSACTION;
done:
GO
USE [msdb]
GO
IF (NOT EXISTS (SELECT *
FROM msdb.dbo.sysoperators
WHERE (name = 'AlertSql'))) 
EXEC msdb.dbo.sp_add_operator @name=N'AlertSql', 
@enabled=1, 
@pager_days=0, 
@email_address=N'dbashift@fcod.nalog.ru'
GO
USE [msdb]
GO
IF (NOT EXISTS (SELECT *
FROM msdb.dbo.sysoperators
WHERE (name = 'gridcontrol')))
EXEC msdb.dbo.sp_add_operator @name=N'gridcontrol', 
@enabled=1, 
@pager_days=0, 
@email_address=N'dbashift@fcod.nalog.ru'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, 
@databasemail_profile=N'AlertSystem', 
@use_databasemail=1
GO

--Все ошибки с важностью 16-25
USE [msdb]
GO
declare @operatorString nvarchar(150)
set @operatorString = 'AlertSql'
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=@operatorString, @notification_method = 1;

--Запустить запрос на нужном сервере
--В SQL agent создается job - "backup missing"
USE [msdb]
GO
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[monitoring]' AND category_class=1)
EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[monitoring]'
if exists(select * from msdb.dbo.sysjobs where name = 'backup missing')
exec msdb.dbo.sp_delete_job @job_name = 'backup missing'
EXEC msdb.dbo.sp_add_job @job_name=N'backup missing', 
@enabled=1, 
@notify_level_eventlog=0, 
@notify_level_email=0, 
@notify_level_netsend=0, 
@notify_level_page=0, 
@delete_level=0, 
@description=N'No description available.', 
@category_name=N'[monitoring]', 
@owner_login_name=N'sa'
declare @servername nvarchar(200)
set @servername = CONVERT(nvarchar, SERVERPROPERTY('servername'),2)
EXEC msdb.dbo.sp_add_jobserver @job_name=N'backup missing', @server_name = @servername
GO
EXEC msdb.dbo.sp_add_jobstep
@job_name='backup missing',
@step_name=N'check backup', 
@step_id=1, 
@cmdexec_success_code=0, 
@on_success_action=1, 
@on_success_step_id=0, 
@on_fail_action=2, 
@on_fail_step_id=0, 
@retry_attempts=0, 
@retry_interval=0, 
@os_run_priority=0, @subsystem=N'TSQL', 
@command=N'declare @do int = 0
-- 0 пассивная нода - не высылаем
-- 1 активная нода - высылаем
-- 2 сервер не в олвизоне - высылаем
-- 3 сервер не поддерживает олвизон - высылаем
begin try
declare @t table (name sysname)
insert @t exec sp_executesql N''
select c.replica_server_name
from sys.dm_hadr_availability_replica_cluster_states c
join sys.dm_hadr_availability_replica_states r
on r.replica_id = c.replica_id
and r.group_id = c.group_id
and r.is_local = 1'' -- здесь должен быть catch если нет поддержки олвизон
-- ниже опредилили что сервер поддерживает олвизон
if @@rowcount > 0 -- в олвизоне сервер
begin
insert @t
exec sp_executesql N''
select c.replica_server_name
from sys.dm_hadr_availability_replica_cluster_states c
join sys.dm_hadr_availability_replica_states r
on r.replica_id = c.replica_id
and r.group_id = c.group_id
and r.is_local = 1
and r.connected_state = 1
and r.role = 1
and c.replica_server_name = @@servername''
if @@rowcount>0 set @do = 1 -- нода активная
else set @do = 0 -- нода пассивная
end
else set @do = 2 -- сервер не в олвизоне
end try
begin catch
set @do = 3 -- 3 сервер не поддерживает олвизон - высылаем
end catch
/*
бэкапы лога если нет более 4х часов - оповещаем
фул/диф бэкапы если нет более 24 часов - оповещаем
фул бэкапы если нет более 7 дней - оповещаем
*/
if @do = 0 return;
declare
@bl int = 240
,@bd int = 1440
,@bf int = 10080
,@r1 int,@r2 int,@r3 int
if object_id(''tempdb..#t'') is not null drop table #t;
if object_id(''tempdb..#t1'') is not null drop table #t1;
if object_id(''tempdb..#t2'') is not null drop table #t2;
if object_id(''tempdb..#t3'') is not null drop table #t3;
select
s.server_name,
s.database_name,
s.backup_start_date,
datediff(minute,backup_start_date,getdate()) dif_min,
s.type,
s.type as tt,
d.recovery_model_desc,
d.recovery_model,
s.is_copy_only
into #t
from msdb.dbo.backupset s
right join sys.databases d
on d.name = s.database_name
and d.recovery_model != 3
and d.database_id>4
and s.is_copy_only = 0
where 1=1
and s.type in (''D'',''I'',''L'')
--create clustered index ix1 on #t (tt, database_name, type, backup_start_date desc)
select database_name,backup_start_date,dif_min
into #t1
from
(
select
server_name,
database_name,
backup_start_date,
dif_min,
type,
recovery_model_desc,
recovery_model,
is_copy_only,
row_number() over (partition by database_name, type order by backup_start_date desc) as rn
from #t
where tt = ''L''
) t
where rn=1 and dif_min > @bl
set @r1 = @@rowcount
select database_name,backup_start_date,dif_min
into #t2
from
(
select
server_name,
database_name,
backup_start_date,
dif_min,
type,
recovery_model_desc,
recovery_model,
is_copy_only,
row_number() over (partition by database_name order by backup_start_date desc) as rn
from #t
where tt in (''D'',''I'')
) t
where rn=1 and dif_min > @bd
set @r2 = @@rowcount
select database_name,backup_start_date,dif_min
into #t3
from
(
select
server_name,
database_name,
backup_start_date,
dif_min,
type,
recovery_model_desc,
recovery_model,
is_copy_only,
row_number() over (partition by database_name order by backup_start_date desc) as rn
from #t
where tt in (''D'')
) t
where rn=1 and dif_min > @bf
set @r3 = @@rowcount
print @r1
print @r2
print @r3
if @r1+@r2+@r3 = 0 return
-----ГенерацияТемы
declare @Subject nvarchar(255) = ''backup_report: mssql_''+@@servername+'' Backup Missing!''
DECLARE @tableHTML NVARCHAR(MAX) ;
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
</style>
''+@@version
+N''
<H3><font color="Red">бэкапы лога если нет более 4х часов:</H3>'' +
N''<table id="box-table" >'' +
N''
<th>БД</th>
<th>Дата последнего бэкапа</th>
<th>Сколько прошло времени</th>
''+cast ( (
SELECT
td=database_name, ''''
,td=backup_start_date, ''''
,td=dif_min, ''''
FROM #t1
ORDER BY 1,2 desc,3
FOR XML PATH(''tr''), TYPE 
) AS NVARCHAR(MAX) ) +
N''</table>''
+N''<H3><font color="Red">фул/диф бэкапы если нет более 24 часов:</H3>'' +
N''<table id="box-table" >'' +
N''
<th>БД</th>
<th>Дата последнего бэкапа</th>
<th>Сколько прошло времени</th>
''+cast ( (
SELECT
td=database_name, ''''
,td=backup_start_date, ''''
,td=dif_min, ''''
FROM #t2
ORDER BY 1,2 desc,3
FOR XML PATH(''tr''), TYPE 
) AS NVARCHAR(MAX) ) +
N''</table>''
+N''<H3><font color="Red">фул бэкапы если нет более 7 дней:</H3>'' +
N''<table id="box-table" >'' +
N''
<th>БД</th>
<th>Дата последнего бэкапа</th>
<th>Сколько прошло времени</th>
''+cast ( (
SELECT
td=database_name, ''''
,td=backup_start_date, ''''
,td=dif_min, ''''
FROM #t3
ORDER BY 1,2 desc,3
FOR XML PATH(''tr''), TYPE 
) AS NVARCHAR(MAX) ) +
N''</table>''
print @tableHTML
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''ForBackup'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @tableHTML,
@body_format = ''HTML''
', 
@database_name=N'msdb', 
@flags=0
EXEC msdb.dbo.sp_add_jobschedule
@job_name='backup missing',
@name=N'every 1 hours', 
@enabled=1, 
@freq_type=4, 
@freq_interval=1, 
@freq_subday_type=8, 
@freq_subday_interval=1, 
@freq_relative_interval=0, 
@freq_recurrence_factor=0, 
@active_start_date=20180130, 
@active_end_date=99991231, 
@active_start_time=50000, 
@active_end_time=220000
--Success MailSend backup
--1) Создаем новое поле MailSend(Бит(1 или 0))
IF NOT EXISTS (select 1 from msdb.INFORMATION_SCHEMA.COLUMNS
where 1=1
and TABLE_NAME = 'backupset'
and COLUMN_NAME = 'Mailsend')
BEGIN
ALTER TABLE msdb.dbo.backupset ADD
MailSend bit NULL
ALTER TABLE msdb.dbo.backupset ADD CONSTRAINT
DF_backupset_MailSend DEFAULT 0 FOR MailSend
END
--2) Заполняем это поле Единицой(1)(отправленно)
go
update msdb.dbo.backupset
set mailsend = 1
where mailsend is null
go
--3) С N переодичностью определяем есть ли записи с значением 0
--if
--(select top 1 mailsend from msdb.dbo.backupset where mailsend = 0 order by backup_finish_date desc ) = 0
--4) Если есть
--Print 'ЕстьНеОтправленныеСообщенияНужноИхНайти'
--5) Если нет
--Else 
--print 'Ничего не делаем'
--6) ГОТОВЫЙ СКРИПТ
declare @jobID nvarchar(255)
set @jobID = (
select top 1 job_id from msdb.dbo.sysjobs
where name='BackupSuccessMailSend'
)
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[monitoring]' AND category_class=1)
EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[monitoring]'
EXEC msdb.dbo.sp_delete_job @job_id=@jobID, @delete_unused_schedule=1
GO
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job @job_name=N'BackupSuccessMailSend', 
@enabled=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@category_name=N'[monitoring]', 
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
from msdb.dbo.backupset as bs
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
from msdb.dbo.backupset as bs
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
DECLARE @tableHTML NVARCHAR(MAX) ;
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
SELECT td=server_name, ''''
,td=database_name, ''''
,td=CASE type
WHEN ''L''
THEN ''Logs''
WHEN ''D''
THEN ''Full''
WHEN ''I''
THEN ''Differential''
ELSE ''UNKNOWN''
END, ''''
,td=(
SELECT convert(VARCHAR(10), bs.backup_start_date, 104)
), ''''
,td=(
SELECT convert(VARCHAR(8), bs.backup_start_date, 114)
), ''''
,td=(
SELECT convert(VARCHAR(8), bs.backup_finish_date, 114)
), ''''
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
END, ''''
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
END, ''''
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
END, ''''
,td = mf.physical_device_name, '''' 
,td = 
Case 
WHEN bs.backup_size < 0 Then ''Errors occurred during this backup''
When bs.backup_size > 0 Then ''has finished without errors''
END, ''''
,td= user_name, ''''
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
@category_name=N'[monitoring]', 
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
select @jobID
declare @scheduleID nvarchar(255)
set @scheduleID = (
select top 1 schedule_id from msdb.dbo.sysjobschedules
where job_id = @jobID)
select @scheduleID
EXEC msdb.dbo.sp_attach_schedule @job_id=@jobid,@schedule_id=@scheduleID
GO

USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job @job_name=N'ErrorBackupMailSend', 
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
set @servername = convert(nvarchar(200), SERVERPROPERTY('ServerName'),2)
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
@command=N'declare @time1 nvarchar(255),@time2 nvarchar(255),@time3 nvarchar(255)
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
set @Subject1 = '' backup_report: mssql_''
set @subject2 = (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))
set @subject5 =
''_''+(select top 1 CASE 
WHEN TEXT LIKE ''%DIFFERENTIAL%''
THEN ''DIFFERENTIAL''
WHEN TEXT LIKE ''%BACKUP DATABASE%''
THEN ''Full''
WHEN TEXT LIKE ''%BACKUP LOG%''
THEN ''Log''
END
from #BackupError)

set @subject3 = ''Time of Backup=0 sec''
set @subject4 = '':Errors occurred during this backup''
set @subject6='' has finished:''
set @Subject = @Subject1+@subject2+@subject5+@subject6+@subject3+@subject4
select @Subject
-----ГенерацияТемыКонец
--ГенерацияПисьма
DECLARE @tableHTML NVARCHAR(MAX) ;
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
td=Time, ''''
,td=ProcessInfo, ''''
,td=TEXT, ''''
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
drop table #BackupError', 
@database_name=N'msdb', 
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
@notify_email_operator_name=N'', 
@notify_page_operator_name=N''
GO
USE [msdb]
GO
declare @jobID nvarchar(255)
set @jobID=(select job_id from msdb.dbo.sysjobs where name='ErrorBackupMailSend')
EXEC msdb.dbo.sp_update_alert @name=N'Severity 016', 
@message_id=0, 
@severity=16, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1, 
@database_name=N'', 
@notification_message=N'', 
@event_description_keyword=N'', 
@performance_condition=N'', 
@wmi_namespace=N'', 
@wmi_query=N'', 
@job_id=@jobID
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'Severity 016', @operator_name=N'AlertSql', @notification_method = 1

USE [msdb]
GO
declare @operatorString nvarchar(150)
set @operatorString = 'AlertSql'
EXEC msdb.dbo.sp_add_alert @name=N'823 - Read/Write Failure',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
EXEC msdb.dbo.sp_add_notification @alert_name=N'823 - Read/Write Failure', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'824 - Page Error',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
EXEC msdb.dbo.sp_add_notification @alert_name=N'824 - Page Error', @operator_name=@operatorString, @notification_method = 1;
EXEC msdb.dbo.sp_add_alert @name=N'825 - Read-Retry Required',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
EXEC msdb.dbo.sp_add_notification @alert_name=N'825 - Read-Retry Required', @operator_name=@operatorString, @notification_method = 1;

USE [msdb]
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[monitoring]' AND category_class=1)
EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[monitoring]'
if exists(select * from msdb.dbo.sysjobs where name = 'CheckAvailabilitySpace')
exec msdb.dbo.sp_delete_job @job_name = 'CheckAvailabilitySpace'
GO
DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job @job_name=N'CheckAvailabilitySpace', 
@enabled=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@category_name=N'[monitoring]', 
@owner_login_name=N'sa', 
@notify_email_operator_name=N'AlertSql', @job_id = @jobId OUTPUT
select @jobId
GO
declare @srvName nvarchar(200)
set @srvName = convert(nvarchar,SERVERPROPERTY('servername'),2)
EXEC msdb.dbo.sp_add_jobserver @job_name=N'CheckAvailabilitySpace', @server_name = @srvName
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'CheckAvailabilitySpace', @step_name=N'CheckAvailabilitySpace', 
@step_id=1, 
@cmdexec_success_code=0, 
@on_success_action=3, 
@on_fail_action=2, 
@retry_attempts=0, 
@retry_interval=0, 
@os_run_priority=0, @subsystem=N'TSQL', 
@command=N'declare @subject nvarchar(100)
declare @msg nvarchar(100)
declare @DiskName nvarchar(5)
declare @totalSpace nvarchar(255)
declare @FreeSpace nvarchar(255)
declare @AvailableInPercent nvarchar(255)
create table #SpaceFree
(Drive nvarchar(255),
TotalSpace nvarchar(255),
AvailableSpace nvarchar(255),
AvailableInPercent nvarchar(255)
)
insert into #SpaceFree
SELECT distinct s.volume_mount_point [Drive]
,
''TotalSpace'' =case 
WHEN (s.total_bytes / 1099511627776) > 1
THEN CAST(CAST(s.total_bytes / 1099511627776 as decimal(6,2)) AS Varchar(14)) + '' TB''
WHEN (s.total_bytes / 1073741824) > 1
THEN CAST(CAST(s.total_bytes / 1073741824 as decimal(6,1)) AS Varchar(14)) + '' GB'' 
Else ''''
END
,
''FreeSpace'' =case 
WHEN (s.available_bytes / 1099511627776) > 1
THEN CAST(CAST(s.available_bytes / 1099511627776 as decimal(6,2)) AS Varchar(14)) + '' TB''
WHEN (s.available_bytes / 1073741824) > 1
THEN CAST(CAST(s.available_bytes / 1073741824 as decimal(6,1)) AS Varchar(14)) + '' GB'' 
Else ''''
END
,(available_bytes/1024/1024)/((total_bytes/1024/1024)/100) as ''Свободно %''
FROM 
sys.master_files f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) s
CREATE TABLE #SpaceFreeC (
drive char,
[free] int
)
insert into #SpaceFreeC
EXEC master..xp_fixeddrives
IF
(select count(*) from #SpaceFree
where AvailableInPercent between 20 and 15 ) > 0
Begin
set @totalSpace = (select TotalSpace from #SpaceFree where AvailableInPercent between 20 and 15 )
Set @DiskName = (select Drive from #SpaceFree)
Set @AvailableInPercent = (select AvailableInPercent from #SpaceFree)
set @FreeSpace= (select AvailableSpace from #SpaceFree)
Set @subject= ''[WARNING] Free Disk space for drive ''+@DiskName+'' is less < 20% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''TotalSpace= ''+@totalSpace+''. FreeSpace ''+@FreeSpace+ ''in percent ''+ @AvailableInPercent
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
--Алерт, диск меньше 15%
IF
(select count(*) from #SpaceFree
where AvailableInPercent < 15) > 0 
Begin
set @totalSpace = (select TotalSpace from #SpaceFree where AvailableInPercent < 15 )
Set @DiskName = (select Drive from #SpaceFree)
Set @AvailableInPercent = (select AvailableInPercent from #SpaceFree)
set @FreeSpace= (select AvailableSpace from #SpaceFree)
Set @subject= ''[CRITICAL] Free Disk space for drive ''+@DiskName+'' is less < 15% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''TotalSpace= ''+@totalSpace+''. FreeSpace ''+@FreeSpace+ ''in percent ''+ @AvailableInPercent
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
IF
(Select count(*) from #SpaceFreeC
where free < 5 * 1024
and drive =''C'') > 0
Begin
Set @subject= ''[WARNING] Free Disk space for drive "C" is less < 5GB on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''[WARNING] Free Disk space for drive "C" is less < 5GB on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
Else
Print ''Disk Space Is Enough''
drop table #spaceFree 
drop table #SpaceFreeC', 
@database_name=N'master', 
@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'CheckAvailabilitySpace', @step_name=N'Purge_job_history', 
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
,@job_name = ''CheckAvailabilitySpace''', 
@database_name=N'master', 
@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'CheckAvailabilitySpace', 
@enabled=1, 
@start_step_id=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@description=N'', 
@category_name=N'[monitoring]', 
@owner_login_name=N'sa', 
@notify_email_operator_name=N'AlertSql', 
@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'CheckAvailabilitySpace', @name=N'Every10Min', 
@enabled=1, 
@freq_type=4, 
@freq_interval=1, 
@freq_subday_type=4, 
@freq_subday_interval=10, 
@freq_relative_interval=0, 
@freq_recurrence_factor=1, 
@active_start_date=20180101, 
@active_end_date=99991231, 
@active_start_time=0, 
@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

DECLARE @perfcond NVARCHAR(100);
DECLARE @sqlversion TINYINT;
SELECT @sqlversion = ca2.Ver
FROM (SELECT CONVERT(VARCHAR(20), 
SERVERPROPERTY('ProductVersion')) AS Ver) dt1
CROSS APPLY (SELECT CHARINDEX('.', dt1.Ver) AS Pos) ca1
CROSS APPLY (SELECT SUBSTRING(dt1.Ver, 1, ca1.Pos-1) AS Ver) ca2;
SELECT @perfcond = 
CASE WHEN @sqlversion >= 11 THEN ''
ELSE ISNULL(N'MSSQL$' + 
CONVERT(sysname, SERVERPROPERTY('InstanceName')), N'SQLServer') + N':'
END +
N'Locks|Number of Deadlocks/sec|_Total|>|0';
EXEC msdb.dbo.sp_add_alert 
@name=N'Deadlock Alert', 
@message_id=0, 
@severity=0, 
@enabled=1, 
@delay_between_responses=0, 
@include_event_description_in=0, 
@category_name=N'[Uncategorized]', 
@performance_condition=@perfcond, 
@job_id=N'00000000-0000-0000-0000-000000000000'
GO

declare @operatorString nvarchar(150)
set @operatorString = 'AlertSql'
EXEC msdb.dbo.sp_add_notification 
@alert_name = N'Deadlock Alert',
@notification_method = 1, --email
@operator_name = @operatorString
GO

USE [msdb]
GO
declare @operatorString nvarchar(150)
set @operatorString = 'AlertSql'
-- 1480 - AG Role Change (failover)
if exists(select * from msdb.dbo.sysalerts where name = 'AG Role Change')
exec msdb.dbo.sp_delete_alert @name = 'AG Role Change'
EXEC msdb.dbo.sp_add_alert
@name = N'AG Role Change',
@message_id = 1480,
@severity = 0,
@enabled = 1,
@delay_between_responses = 0,
@include_event_description_in = 1;
EXEC msdb.dbo.sp_add_notification 
@alert_name = N'AG Role Change', 
@operator_name = @operatorString, 
@notification_method = 1;
-- 35264 - AG Data Movement - Resumed
if exists(select * from msdb.dbo.sysalerts where name = 'AG Data Movement - Suspended')
exec msdb.dbo.sp_delete_alert @name = 'AG Data Movement - Suspended'
EXEC msdb.dbo.sp_add_alert
@name = N'AG Data Movement - Suspended',
@message_id = 35264,
@severity = 0,
@enabled = 1,
@delay_between_responses = 0,
@include_event_description_in = 1;
EXEC msdb.dbo.sp_add_notification 
@alert_name = N'AG Data Movement - Suspended', 
@operator_name = @operatorString, 
@notification_method = 1;
-- 35265 - AG Data Movement - Resumed
if exists(select * from msdb.dbo.sysalerts where name = 'AG Data Movement - Resumed')
exec msdb.dbo.sp_delete_alert @name = 'AG Data Movement - Resumed'
EXEC msdb.dbo.sp_add_alert
@name = N'AG Data Movement - Resumed',
@message_id = 35265,
@severity = 0,
@enabled = 1,
@delay_between_responses = 0,
@include_event_description_in = 1;
EXEC msdb.dbo.sp_add_notification 
@alert_name = N'AG Data Movement - Resumed', 
@operator_name = @operatorString, 
@notification_method = 1; 
-- 35206 - AG Timeout to Secondary Replica
if exists(select * from msdb.dbo.sysalerts where name = 'AG Timeout to Secondary Replica')
exec msdb.dbo.sp_delete_alert @name = 'AG Timeout to Secondary Replica'
EXEC msdb .dbo . sp_add_alert
@name = N'AG Timeout to Secondary Replica',
@message_id = 35206,
@severity = 0,
@enabled = 1,
@delay_between_responses = 0,
@include_event_description_in = 1;
EXEC msdb .dbo . sp_add_notification
@alert_name = N'AG Timeout to Secondary Replica',
@operator_name = @operatorString, 
@notification_method = 1;
-- 35202 - AG Timeout to Secondary Replica
if exists(select * from msdb.dbo.sysalerts where name = 'AG Connection has been successfully established')
exec msdb.dbo.sp_delete_alert @name = 'AG Connection has been successfully established'
EXEC msdb .dbo . sp_add_alert
@name = N'AG Connection has been successfully established',
@message_id = 35202,
@severity = 0,
@enabled = 1,
@delay_between_responses = 0,
@include_event_description_in = 1;
EXEC msdb .dbo . sp_add_notification
@alert_name = N'AG Connection has been successfully established',
@operator_name = @operatorString, 
@notification_method = 1;