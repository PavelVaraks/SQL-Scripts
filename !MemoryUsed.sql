SELECT COUNT(DISTINCT [status])
--*100.0/Count(*) 
as 'Distinct_[status] (in %)'
FROM [SfoTax3SignExt].[dbo].[task]

		[SfoTax3SignExt]					  0.000024696153


 --����� �������, ����� ���������� ���� ������ ���������� ������� ����� ������ � SQL Server
SELECT DB_NAME(database_id),
COUNT (1) * 8 / 1024 AS MBUsed
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY COUNT (*) * 8 / 1024 DESC
GO
--����� �������, ����� ���������� ���� ������ ���������� ������� ����� ������ � SQL Server
SELECT
[DatabaseName] = CASE [database_id] WHEN 32767
THEN 'Resource DB'
ELSE DB_NAME([database_id]) END,
COUNT_BIG(*) [Pages in Buffer],
COUNT_BIG(*)/128 [Buffer Size in MB]
FROM sys.dm_os_buffer_descriptors
GROUP BY [database_id]
ORDER BY [Pages in Buffer] DESC;
GO
 
 
 
 --���������� ��� �������� � ���, ������� ������ ������ ������ ���������� � ���������� ���� ������.
 use [model]
SELECT obj.name [Object Name], o.type_desc [Object Type],
i.name [Index Name], i.type_desc [Index Type],
COUNT(*) AS [Cached Pages Count],
COUNT(*)/128 AS [Cached Pages In MB]
FROM sys.dm_os_buffer_descriptors AS bd
INNER JOIN
(
SELECT object_name(object_id) AS name, object_id
,index_id ,allocation_unit_id
FROM sys.allocation_units AS au
INNER JOIN sys.partitions AS p
ON au.container_id = p.hobt_id
AND (au.type = 1 OR au.type = 3)
UNION ALL
SELECT object_name(object_id) AS name, object_id
,index_id, allocation_unit_id
FROM sys.allocation_units AS au
INNER JOIN sys.partitions AS p
ON au.container_id = p.partition_id
AND au.type = 2
) AS obj
ON bd.allocation_unit_id = obj.allocation_unit_id
INNER JOIN sys.indexes i ON obj.[object_id] = i.[object_id]
INNER JOIN sys.objects o ON obj.[object_id] = o.[object_id]
WHERE database_id = DB_ID()
GROUP BY obj.name, i.type_desc, o.type_desc,i.name
ORDER BY [Cached Pages In MB] DESC;
GO


--� ��������� ���� �������� ��������� ������� ������ ����� ����� ���� (0).
-- ��� ��������, ��� �� ����� ������� ��� ���������, ������� �������, ��� ������ ����� ��������� ���, ����� �� ��� ������ ������. 
--������� �������, �� ����� SQL Server ���������� ������, ����� ��� �������� �������� ������������, � ������ �� �������� ��� ���.
--��� ������� ��������, ������� �� ����������, ����� ���������� �������� ����� ��������� �������� � ������.
SELECT object_name, counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Memory Manager%'
AND [counter_name] = 'Memory Grants Pending'