
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
EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@twoweek

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


