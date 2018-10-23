
--ВключаемАгента
EXEC xp_servicecontrol N'START',N'SQLServerAGENT' 
go
--ВключаемАгента

--ВключаемМодульMailService
sp_CONFIGURE 'show advance', 1
GO
RECONFIGURE 
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE 
GO
--ВключаемМодульMailService

declare @twoweek nvarchar(25)
set @twoweek = (select getdate()-14)
EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@twoweek



-------------------------------------------------------------
--  Database Mail Simple Configuration Template.
--
--  This template creates a Database Mail profile, an SMTP account and 
--  associates the account to the profile.
--  The template does not grant access to the new profile for
--  any database principals.  Use msdb.dbo.sysmail_add_principalprofile
--  to grant access to the new profile for users who are not
--  members of sysadmin.
-------------------------------------------------------------
 --ДляБэкапов
DECLARE @profile_name sysname,
        @account_name sysname,
        @SMTP_servername sysname,
        @email_address NVARCHAR(128),
	    @display_name NVARCHAR(128),
		@replyto_address nvarchar(128);

        SET @profile_name = 'ForBackup';

		SET @account_name = 'gridcontrol';
		SET @SMTP_servername = 'n5201-mail.dpc.tax.nalog.ru';
		SET @email_address = 'gridcontrol@fcod.nalog.ru';
        SET @display_name = 'gridcontrol';
		SET @replyto_address = 'dbashift@fcod.nalog.ru';

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
  RAISERROR('The specified Database Mail profile (<profile_name,sysname,SampleProfile>) already exists.', 16, 1);
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
    @mailserver_name = @SMTP_servername;
	
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
-- Profile name. Replace with the name for your profile
        SET @profile_name = 'AlertSystem';

-- Account information. Replace with the information for your account.

		SET @account_name = 'AlertSql';
		SET @SMTP_servername = 'n5201-mail.dpc.tax.nalog.ru';
		SET @email_address = 'AlertSql@fcod.nalog.ru';
        SET @display_name = 'AlertSql';
		SET @replyto_address = 'dbashift@fcod.nalog.ru';


-- Verify the specified account and profile do not already exist.
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
  RAISERROR('The specified Database Mail profile (<profile_name,sysname,SampleProfile>) already exists.', 16, 1);
  GOTO done;
END;

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
BEGIN
 RAISERROR('The specified Database Mail account (<account_name,sysname,SampleAccount>) already exists.', 16, 1) ;
 GOTO done;
END;

-- Start a transaction before adding the account and the profile
BEGIN TRANSACTION ;

DECLARE @rv INT;

-- Add the account
EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
    @account_name = @account_name,
    @use_default_credentials = 1,
	@replyto_address= @replyto_address,
	@email_address = @email_address,
    @display_name = @display_name,
    @mailserver_name = @SMTP_servername;
	
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
--Пользователь для Алертов
 --ОператорДляАлертов
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'AlertSql', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'dbashift@fcod.nalog.ru'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'gridcontrol', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'dbashift@fcod.nalog.ru'
GO

 --ОператорДляАлертовКонец

--Алерты
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

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'823 - Read/Write Failure',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'

EXEC msdb.dbo.sp_add_notification @alert_name=N'823 - Read/Write Failure', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'824 - Page Error',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'

EXEC msdb.dbo.sp_add_notification @alert_name=N'824 - Page Error', @operator_name=@operatorString, @notification_method = 7;

EXEC msdb.dbo.sp_add_alert @name=N'825 - Read-Retry Required',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'

EXEC msdb.dbo.sp_add_notification @alert_name=N'825 - Read-Retry Required', @operator_name=@operatorString, @notification_method = 7;
 --Login Failed for user
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Login failed for user', 
		@message_id=18456, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Login failed for user', @operator_name=N'AlertSql', @notification_method = 1
GO
--Login Failed for user

-- Tested SQL 2005 - 2012.
DECLARE @perfcond NVARCHAR(100);
DECLARE @sqlversion TINYINT;
-- get the major version of sql running
SELECT  @sqlversion = ca2.Ver
FROM    (SELECT CONVERT(VARCHAR(20), 
                        SERVERPROPERTY('ProductVersion')) AS Ver) dt1
        CROSS APPLY (SELECT CHARINDEX('.', dt1.Ver) AS Pos) ca1
        CROSS APPLY (SELECT SUBSTRING(dt1.Ver, 1, ca1.Pos-1) AS Ver) ca2;

-- handle the performance condition depending on the version of sql running
-- and whether this is a named instance or a default instance.
SELECT  @perfcond = 
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
    --@job_name=N'Job to run when a deadlock happens, if applicable'
    -- or 
    @job_id=N'00000000-0000-0000-0000-000000000000'
GO
declare @operatorString nvarchar(150)
set @operatorString = 'AlertSql'
EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Deadlock Alert',
    @notification_method = 1, --email
    @operator_name = @operatorString; -- name of the operator to notify
GO




--Алерты
--АлертыВключениеВАгенте
USE [msdb]
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'AlertSystem'
GO


--АлертыВключениеВАгенте
--Success MailSend backup
 --1) Создаем новое поле MailSend(Бит(1 или 0))
go
ALTER TABLE msdb.dbo.backupset ADD
	MailSend bit NULL
ALTER TABLE msdb.dbo.backupset ADD CONSTRAINT
	DF_backupset_MailSend DEFAULT 0 FOR MailSend
 go
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
--Print  'ЕстьНеОтправленныеСообщенияНужноИхНайти'
  
--5) Если нет
--Else 
--print 'Ничего не делаем'
  
--6) ГОТОВЫЙ СКРИПТ
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
set @servername = convert(nvarchar(200), SERVERPROPERTY('ServerName'),2)

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
(select top 1 mailsend from msdb.dbo.backupset where mailsend = 0 order by backup_finish_date desc ) = 0
begin
DECLARE db_cursor CURSOR FOR 
SELECT backup_set_id 
FROM msdb.dbo.backupset where mailsend = 0
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
set @Subject1 = '' backup_report_mssql_''
set @subject2 = (convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))
set @subject5=''_''+(select CASE type
		WHEN ''L''
			THEN ''Logs''
		WHEN ''D''
			THEN ''Full''
		WHEN ''I''
			THEN ''Differential''
		END
		from  msdb.dbo.backupset
		where backup_set_id=@BackupID
)
 
set @subject3 = ''Time of Backup=''
set @timeBackup = (select ''ВремяВыполнения''=
	CASE
--минуты
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/3600%24 AS VARCHAR(4)) + '' '' + ''h''+'' ''+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''  
--Минуты 
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) >60
THEN CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
--секунды 
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) < 60
THEN CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
		Else ''can''''n show''
		END
		from  msdb.dbo.backupset
		where backup_set_id=@BackupID
)
If
(select backup_size from msdb.dbo.backupset where backup_set_id= @BackupID ) <0
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
<th>Server_Name</th>
<th>Database_Name</th>
<th>Backup_Type</th>
<th>Date_Start</th>
<th>Time_Start</th>
<th>Time_Finish</th>
<th>Time_Run</th>
<th>Backup_Size</th>
<th>AVG/th>
<th>Backup_State</th>
<th>Who_Run</th>''
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
		END,       ''''
	,td=(
		SELECT convert(VARCHAR(10), backup_start_date, 104)
		),       ''''
	,td=(
		SELECT convert(VARCHAR(8), backup_start_date, 114)
		),       ''''
	,td=(
		SELECT convert(VARCHAR(8), backup_finish_date, 114)
		),       ''''
	,td=
	CASE
--минуты
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/3600%24 AS VARCHAR(4)) + '' '' + ''h''+'' ''+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''  
--Минуты 
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) >60
THEN CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/60%60 AS VARCHAR(4)) + '' '' + ''min''+'' ''+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
--секунды 
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) < 60
THEN CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + '' '' + ''sec''
		Else ''can''''n show''
		END,       ''''
,td=
CASE
--Гигабайты
WHEN (backup_size / 1099511627776) > 1
THEN
CAST(Cast(backup_size / 1099511627776 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' TB''
WHEN (backup_size / 1073741824) > 1
THEN
CAST(CAST(backup_size / 1073741824 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' GB''
--Мегабайты
WHEN (backup_size / 1048576) > 1
THEN
CAST(CAST(backup_size / 1048576 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' MB''
--Килобайты
WHEN (backup_size / 1024) > 1
THEN
CAST(CAST(backup_size / 1024 AS DECIMAL(4, 0)) AS VARCHAR(14)) + '' KB''
Else ''Backup=0 Warning!''
END,       ''''
,td = 
Case
WHEN backup_size <= 0 or DATEDIFF(second, backup_start_date, backup_finish_date) <0
THEN ''0''
--Терабайты в Гигабиты
WHEN (backup_size / 1099511627776) > 1
THEN							 
CAST(CAST((backup_size/DATEDIFF(second, backup_start_date, backup_finish_date))/134217728 as decimal(6,1)) as varchar(14))+ '' Гбит''
--Гигабайты в гигабиты
WHEN (backup_size / 1073741824) > 1
THEN
CAST(CAST((backup_size/DATEDIFF(second, backup_start_date, backup_finish_date))/134217728 as decimal(6,1)) as varchar(14))+ '' Гбит''
--Мегабайты
WHEN (backup_size / 1048576) > 1
THEN							 
CAST(CAST(backup_size / 1048576 AS DECIMAL(6, 1)) AS VARCHAR(14)) + '' MB''
--Килобайты
WHEN (backup_size / 1024) > 1
THEN
CAST(CAST(backup_size / 1024 AS DECIMAL(4, 0)) AS VARCHAR(14)) + '' KB''
Else ''HyperSpeed''
END,  
    ''''
,td = 
	Case 
	WHEN backup_size < 0 Then ''Errors occurred during this backup''
	When backup_size > 0 Then ''has finished without errors''
	END,       ''''
,td=	user_name,       ''''

FROM msdb.dbo.backupset
where backup_set_id=@BackupID
ORDER BY backup_finish_date DESC
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
		@command=N'declare @twoweek nvarchar(25)
set @twoweek = (select GETDATE()-0.001)
EXEC msdb.dbo.sp_purge_jobhistory  
@oldest_date=@twoweek
,@job_name = ''BackupSuccessMailSend''

', 
		@database_name=N'msdb', 
		@flags=0
GO

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
set @time1 =convert(VARCHAR(30), getdate()-0.00000578703300, 21)
set @time2 =convert(VARCHAR(30), getdate()+0.00000578703300, 21)
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
		from  #BackupError)
 
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
