USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'7701 Дежурные DBA', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'dbashift@fcod.nalog.ru'
GO
