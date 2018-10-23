select
 
DB.database_id
,DB.name
,create_date
,DB.collation_name
,recovery_model_desc
,type_desc
,physical_name
,size
,'MAX SIZE'=CASE
WHEN max_size = -1
THEN 'Unlimited'
WHEN max_size > 134217728
THEN CAST((max_size/131072)/1024 as varchar(50))+' TB'
WHEN max_size > 1048576
THEN CAST((max_size/131072) as varchar(50))+' GB'
WHEN max_size >= 128
THEN CAST((max_size/128) as varchar(50))+' MB' 
END
,'AUTO_GROWTH'=CASE
	WHEN growth >= 1048576 and is_percent_growth=0
			THEN CAST((growth/131072) as varchar(50))+' GB' 
		WHEN growth >= 128 and is_percent_growth=0
			THEN CAST((growth/128) as varchar(50))+' MB'
			WHEN growth >= 0 and is_percent_growth=1
			THEN CAST(((growth)) as varchar(50))+'%'
END
--,bak.type AS 'ТипБэкапа'
--,bak.backup_size
--,bak.backup_finish_date
from sys.databases as DB
left join sys.master_files as MF on mf.database_id=DB.database_id
--left join msdb.dbo.backupset as BAK on DB.name=BAk.database_name
where 
DB.database_id not in (1,2,3,4)
