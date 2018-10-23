--Расчёт максимальной ОЗУ для MS SQL SERVER
SELECT((total_physical_memory_kb / (1024 * 1024)) - CEILING((CAST((total_physical_memory_kb / (1024 * 1024)) AS NUMERIC(8, 2)) / 16))) * 1024 AS 'Max Memory for SQL Server in MB'
FROM sys.dm_os_sys_memory;
--Общая информация о системе
select * from sys.dm_os_sys_info

--Информация по ОС(уйня)
select * from sys.dm_os_windows_info

--Информация из реестра касающаяся текущего экземпляра MS SQL
select * from sys.dm_server_registry

--Список установленных служб SQL Server
select * from sys.dm_server_services

--Numa конфигурация сервера
select * from sys.dm_os_nodes

--
select * from sys.dm_exec_connections

--Информация о памяти(допилить)
select * from sys.dm_os_sys_memory

--
select * from sys.dm_os_process_memory