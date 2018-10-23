DECLARE @StatusBackup nvarchar(100)
SELECT
  user_name,
  (SELECT
    CONVERT(varchar(10), backup_start_date, 104))
  AS StartDate,
  (SELECT
    CONVERT(varchar(8), backup_start_date, 114))
  AS TimeStart,
  (SELECT
    CONVERT(varchar(8), backup_finish_date, 114))
  AS TimeEnd,
  'TimeRun' =
             CASE
               --минуты
               WHEN DATEDIFF(SECOND, backup_start_date, backup_finish_date) >= 3600 THEN CAST(DATEDIFF(SECOND, backup_start_date, backup_finish_date) / 3600 % 24 AS varchar(4)) + ' ' + 'h' + ' ' + CAST(DATEDIFF(SECOND, backup_start_date, backup_finish_date) / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(DATEDIFF(SECOND, backup_start_date, backup_finish_date) % 60 AS varchar(4)) + ' ' + 'sec'
               --Минуты 
               WHEN DATEDIFF(SECOND, backup_start_date, backup_finish_date) > 60 THEN CAST(DATEDIFF(SECOND, backup_start_date, backup_finish_date) / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(DATEDIFF(SECOND, backup_start_date, backup_finish_date) % 60 AS varchar(4)) + ' ' + 'sec'
               --секунды 
               WHEN DATEDIFF(SECOND, backup_start_date, backup_finish_date) BETWEEN 1 AND 60 THEN CAST(DATEDIFF(SECOND, backup_start_date, backup_finish_date) % 60 AS varchar(4)) + ' ' + 'sec'
               WHEN DATEDIFF(SECOND, backup_start_date, backup_finish_date) = 0 THEN '<1 sec'
               ELSE 'can''n show'
             END,
  'BackupSize' =
                CASE
                  --Гигабайты
                  WHEN (compressed_backup_size / 1073741824) > 1 THEN CAST(CAST(compressed_backup_size / 1073741824 AS decimal(6, 1)) AS varchar(14)) + ' ' + 'GB'
                  --Мегабайты
                  WHEN (compressed_backup_size / 1048576) > 1 THEN CAST(CAST(compressed_backup_size / 1048576 AS decimal(6, 1)) AS varchar(14)) + ' ' + 'MB'
                  --Килобайты
                  WHEN (compressed_backup_size / 1024) > 1 THEN CAST(CAST(compressed_backup_size / 1024 AS decimal(4, 0)) AS varchar(14)) + ' ' + 'KB'
                  ELSE 'Backup=0 Warning!'
                END,
  'AVG Speed' =
               CASE
                 WHEN compressed_backup_size <= 0 OR
                   DATEDIFF(SECOND, backup_start_date, backup_finish_date) < 0 THEN '<1'
                 WHEN (compressed_backup_size / 13421772) > 1 AND
                   DATEDIFF(SECOND, backup_start_date, backup_finish_date) > 0 THEN CAST(CAST((compressed_backup_size / DATEDIFF(SECOND, backup_start_date, backup_finish_date)) / 134217728 AS decimal(6, 1)) AS varchar(14)) + ' Gbit'
                 --Мегабайты
                 WHEN (compressed_backup_size / 1048576) > 1 THEN CAST(CAST(compressed_backup_size / 1048576 AS decimal(6, 1)) AS varchar(14)) + ' ' + 'MB'
                 --Килобайты
                 WHEN (compressed_backup_size / 1024) > 1 AND
                   DATEDIFF(SECOND, backup_start_date, backup_finish_date) > 0 THEN CAST(CAST(compressed_backup_size / 1024 AS decimal(4, 0)) AS varchar(14)) + ' ' + 'KB'
                 ELSE ''
               END,
  CASE type
    WHEN 'L' THEN 'Logs'
    WHEN 'D' THEN 'Full'
    WHEN 'I' THEN 'Differential'
  END AS BackUpType,
  mf.physical_device_name,
  database_name,
  server_name
FROM msdb.dbo.backupset AS bs
LEFT JOIN msdb.dbo.backupmediafamily AS MF
  ON mf.media_set_id = bs.media_set_id

ORDER BY backup_start_date DESC