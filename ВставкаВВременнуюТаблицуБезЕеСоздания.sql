Вставка в временную таблицу без ее создания

select * into #t from sys.databases;
go
select * from #t
DROP table #t