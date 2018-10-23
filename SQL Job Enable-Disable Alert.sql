USE [msdb]
GO
if (select OBJECT_ID('dbo.tr_SysJobs_enabled')) is not null
drop TRIGGER [dbo].[tr_SysJobs_enabled]
GO
CREATE TRIGGER [dbo].[tr_SysJobs_enabled]  
ON [dbo].[sysjobs]  
FOR UPDATE AS  

SET NOCOUNT ON  

DECLARE @UserName VARCHAR(50),  
@HostName VARCHAR(50),  
@JobName VARCHAR(100),  
@DeletedJobName VARCHAR(100),  
@New_Enabled INT,  
@Old_Enabled INT,  
@Bodytext VARCHAR(200),  
@SubjectText VARCHAR(200), 
@Servername VARCHAR(50) 

SELECT @UserName = SYSTEM_USER, @HostName = HOST_NAME()  
SELECT @New_Enabled = Enabled FROM Inserted  
SELECT @Old_Enabled = Enabled FROM Deleted  
SELECT @JobName = Name FROM Inserted  
SELECT @Servername = @@servername 


IF @New_Enabled <> @Old_Enabled  
BEGIN  
if object_id('msdb.dbo.MSSqlAgent','U') is null
	begin
		create table msdb.dbo.MSSqlAgent
		(
			id bigint identity constraint pk_MSSqlAgent primary key,
			dt$ datetime constraint df_MSSqlAgent_dt$ default getdate(),
			susername sysname constraint df_MSSqlAgent_susername default original_login(),
			hostname sysname constraint df_MSSqlAgent_hostname default host_name(),
			EvntData nvarchar(1000) not null
		)
	end
  IF @New_Enabled = 1  
  BEGIN  
    SET @bodytext = 'User: '+@username+' from '+@hostname+
        ' ENABLED SQL Job ['+@jobname+'] at Date:'+CONVERT(VARCHAR(10),GETDATE(),104) +' Time:'+CONVERT(VARCHAR(8),GETDATE(),14) 
    SET @subjecttext = @Servername+' : ['+@jobname+
        '] has been ENABLED at Date:'+CONVERT(VARCHAR(10),GETDATE(),104) +' Time:'+CONVERT(VARCHAR(8),GETDATE(),14)
	   insert MSSqlAgent (EvntData)
		select @bodytext

		END  

  IF @New_Enabled = 0  
  BEGIN  
    SET @bodytext = 'User: '+@username+' from '+@hostname+
        ' DISABLED SQL Job ['+@jobname+'] at Date:'+CONVERT(VARCHAR(10),GETDATE(),104) +' Time:'+CONVERT(VARCHAR(8),GETDATE(),14) 
    SET @subjecttext = @Servername+' : ['+@jobname+
        '] has been DISABLED at Date:'+CONVERT(VARCHAR(10),GETDATE(),104) +' Time:'+CONVERT(VARCHAR(8),GETDATE(),14)
	    insert MSSqlAgent (EvntData)
		select @bodytext 
  END  

  SET @subjecttext = 'SQL Job on ' + @subjecttext  

  
  EXEC msdb.dbo.sp_send_dbmail  
  @profile_name = 'AlertSystem', 
  @recipients = 'p.varaks@fcod.nalog.ru',
  @body = @bodytext,  
  @subject = @subjecttext  

END
GO
ALTER TABLE [dbo].[sysjobs] ENABLE TRIGGER [tr_SysJobs_enabled]
GO
