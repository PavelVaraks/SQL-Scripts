
SELECT (cpu_count / hyperthread_ratio) AS PhysicalCPUs
,cpu_count AS logicalCPUs
,physical_memory_in_bytes/1024/1024/1024 as GB
FROM sys.dm_os_sys_info  