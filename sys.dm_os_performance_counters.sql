	select	getdate() as Collect_time, 
			Counter = CASE	WHEN counter_name = 'Granted Workspace Memory (KB)' then 'Granted Workspace Memory (MB)'
							ELSE rtrim(counter_name) END, 
			Value =	CASE	WHEN counter_name like '%/sec%'
										then cntr_value/DATEDIFF(SS, (select create_date from sys.databases where name = 'tempdb'), getdate())
							WHEN counter_name like 'Granted Workspace Memory (KB)%' then cntr_value/1024
							ELSE cntr_value
							END
	from sys.dm_os_performance_counters where 
	counter_name = N'Checkpoint Pages/sec' or
	counter_name = N'Processes Blocked' or
	(counter_name = N'Lock Waits/sec' and instance_name = '_Total') or
	counter_name = N'User Connections' or
	counter_name = N'SQL Re-Compilations/sec' or
	counter_name = N'SQL Compilations/sec' or
	counter_name = 'Batch Requests/sec' or
	counter_name = 'Percent Log Used' or
	(counter_name = 'Page life expectancy' and object_name like '%Buffer Manager%') or
	counter_name = 'Granted Workspace Memory (KB)'