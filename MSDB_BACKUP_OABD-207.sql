SELECT
	--backup_start_date
	--,backup_finish_date
	--,type
	user_name
	,(
		SELECT convert(VARCHAR(10), backup_start_date, 104)
		) AS ДатаСтарта
	,(
		SELECT convert(VARCHAR(8), backup_start_date, 114)
		) AS ВремяСтарта
--	,(
--		SELECT convert(VARCHAR(10), backup_finish_date, 104)
--		) AS ДатаОкончания
	,(
		SELECT convert(VARCHAR(8), backup_finish_date, 114)
		) AS ВремяОкончания
	,CASE type
		WHEN 'L'
			THEN 'BackUp Logs'
		WHEN 'D'
			THEN 'Full Backup'
		WHEN 'I'
			THEN 'Differential  Logs'
		END AS ТипБэкапа
	/*
DECLARE @startdate datetime2 = '2007-05-05 12:10:09.3312722';
DECLARE @enddate datetime2 = '2007-06-04 12:10:09.3312722'; 
SELECT DATEDIFF(day, @startdate, @enddate); */
	,DATEDIFF(SECOND, (
			SELECT convert(VARCHAR(80), backup_start_date, 114)
			), (
			SELECT convert(VARCHAR(80), backup_finish_date, 114)
			)) AS ВремяВыполненияВСекундах
	,Round(backup_size / 1083263051, 4)
	,(
		SELECT ROUND(CAST(backup_size / 1083263051 AS DECIMAL(6, 2)), 4)
		) AS ОбъемРезервнойКопииГБ
	,database_name
	,server_name
FROM msdb.dbo.backupset
WHERE database_name = 'mps' -- and type !='L'
ORDER BY backup_start_date DESC