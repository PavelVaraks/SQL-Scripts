USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'Error Number 823', @new_name=N'823 - Read/Write Failure'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'823 - Read/Write Failure', 
		@message_id=823, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'', 
		@event_description_keyword=N'', 
		@performance_condition=N'', 
		@wmi_namespace=N'', 
		@wmi_query=N'', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'823 - Read/Write Failure', @operator_name=N'AlertSql', @notification_method = 1
GO



USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'Error Number 824', @new_name=N'824 - Page Error'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'824 - Page Error', 
		@message_id=823, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'', 
		@event_description_keyword=N'', 
		@performance_condition=N'', 
		@wmi_namespace=N'', 
		@wmi_query=N'', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'824 - Page Error', @operator_name=N'AlertSql', @notification_method = 1
GO
EXEC msdb.dbo.sp_delete_notification @alert_name=N'824 - Page Error', @operator_name=N'p_varaks_test'
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'Error Number 825', @new_name=N'825 - Read-Retry Required'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'825 - Read-Retry Required', 
		@message_id=823, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'', 
		@event_description_keyword=N'', 
		@performance_condition=N'', 
		@wmi_namespace=N'', 
		@wmi_query=N'', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_update_notification @alert_name=N'825 - Read-Retry Required', @operator_name=N'AlertSql', @notification_method = 1
GO
EXEC msdb.dbo.sp_delete_notification @alert_name=N'825 - Read-Retry Required', @operator_name=N'p_varaks_test'
GO
