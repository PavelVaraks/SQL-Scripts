-----Кол-во текущих процессов Управления печати--------------
select  State 'Статус процесса', label 'Метка процесса', COUNT(*) as 'кол-во процессов', 'А-активный, Е-ошибочный'
 from dbo.TaskQueue
where IDParent='0' and Label='AIS3.MPSMGT'
group by State,label

-----Кол-во текущих процессов Печать пост-пакета--------------
select  State 'Статус процесса', label 'Метка процесса', COUNT(*) as 'кол-во процессов', 'А-активный, Е-ошибочный'
 from dbo.TaskQueue
where IDParent='0' and Label='AIS3.MPSPOSTPACK'
group by State,label
