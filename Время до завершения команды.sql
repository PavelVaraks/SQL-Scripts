-- Процент исполнения длительного запроса ввода-вывода 
SELECT
  ost.session_id,
  DB_NAME(ISNULL(s.dbid, 1)) AS dbname,
  er.command,
  er.percent_complete,
  DATEADD(ms, er.estimated_completion_time, GETDATE()) AS [Прогноз завершения],
  er.status,
  osth.os_thread_id,
  ost.pending_io_count,
  ost.scheduler_id,
  osth.creation_time,
  ec.last_read,
  ec.last_write,
  s.text,
  owt.exec_context_id,
  owt.wait_duration_ms,
  owt.wait_type
FROM master.sys.dm_os_tasks AS ost
JOIN master.sys.dm_os_threads AS osth
  ON ost.worker_address = osth.worker_address
  AND ost.pending_io_count > 0
  AND ost.session_id IS NOT NULL
JOIN master.sys.dm_exec_connections AS ec
  ON ost.session_id = ec.session_id
CROSS APPLY master.sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS s
JOIN master.sys.dm_os_waiting_tasks AS owt
  ON ost.session_id = owt.session_id
  AND owt.wait_duration_ms > 0
JOIN master.sys.dm_exec_requests AS er
  ON ost.session_id = er.session_id
  AND er.percent_complete > 0
ORDER BY ost.session_id
GO
----------------------------------------------------------------------------------------
SELECT
  session_id,
  start_time,
  status,
  command,
  'Время выполнения' =
                      CASE
                        WHEN total_elapsed_time / 1000 >= 86400 THEN CAST(total_elapsed_time / 1000 / 86400 % 24 AS varchar(4)) + ' ' + 'DAY' + ' ' + CAST(total_elapsed_time / 1000 / 3600 % 24 AS varchar(4)) + ' ' + 'h' + ' ' + CAST(total_elapsed_time / 1000 / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(total_elapsed_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                        WHEN total_elapsed_time / 1000 >= 3600 THEN CAST(total_elapsed_time / 1000 / 3600 % 24 AS varchar(4)) + ' ' + 'h' + ' ' + CAST(total_elapsed_time / 1000 / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(total_elapsed_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                        WHEN total_elapsed_time / 1000 > 60 THEN CAST(total_elapsed_time / 1000 / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(total_elapsed_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                        WHEN total_elapsed_time / 1000 BETWEEN 1 AND 60 THEN CAST(total_elapsed_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                        WHEN total_elapsed_time = 0 THEN '<1 sec'
                        ELSE 'can''n show'
                      END,
  percent_complete,
  'Расчетное время завершение' =
                                CASE
                                  WHEN total_elapsed_time / 1000 >= 86400 THEN CAST(estimated_completion_time / 1000 / 86400 % 24 AS varchar(4)) + ' ' + 'DAY' + ' ' + CAST(estimated_completion_time / 1000 / 3600 % 24 AS varchar(4)) + ' ' + 'h' + ' ' + CAST(estimated_completion_time / 1000 / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(estimated_completion_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                                  WHEN estimated_completion_time / 1000 >= 3600 THEN CAST(estimated_completion_time / 1000 / 3600 % 24 AS varchar(4)) + ' ' + 'h' + ' ' + CAST(estimated_completion_time / 1000 / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(estimated_completion_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                                  WHEN estimated_completion_time / 1000 > 60 THEN CAST(estimated_completion_time / 1000 / 60 % 60 AS varchar(4)) + ' ' + 'min' + ' ' + CAST(estimated_completion_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                                  WHEN estimated_completion_time / 1000 BETWEEN 1 AND 60 THEN CAST(estimated_completion_time / 1000 % 60 AS varchar(4)) + ' ' + 'sec'
                                  WHEN estimated_completion_time = 0 THEN '<1 sec'
                                  ELSE 'can''n show'
                                END

FROM sys.dm_exec_requests
WHERE command LIKE '%backup%'
OR percent_complete > 0