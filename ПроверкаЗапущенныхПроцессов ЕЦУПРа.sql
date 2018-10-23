select  State 'Статус процесса', label 'Метка процесса', COUNT(*) as 'кол-во процессов', 'А-активный, Е-ошибочный'
 from dbo.TaskQueue
where IDParent='0' and Label='ЦПС.ВЗАИМОДЕЙСТВИЕУД'
group by State,label

---Информация по активным процессам загрузки файлов-
select  *
 from dbo.TaskQueue
where IDParent='0' and Label='ЦПС.ВЗАИМОДЕЙСТВИЕУД' and State='A'

-------Сообщения дочерних по активным процессам загрузки файлов-------------
select  a1.ID 'ID-процесса',a1.TimeStart 'Время запуска',a1.Label 'Метка процесса', a1.Notification 'Сообщение по работе процесса'
 from dbo.TaskQueue a1
where  a1.IDparent in
(select  a2.ID from dbo.TaskQueue a2
    where IDParent='0' and  Label='ЦПС.ВЗАИМОДЕЙСТВИЕУД' and State='A')
