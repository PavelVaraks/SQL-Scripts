declare @src table
(
	srv varchar(200) not null,
	name varchar(200) not null,
	unique (srv,name),
	dt varchar(500)
)

declare @dst table
(
	srv varchar(200) not null,
	name varchar(200) not null,
	primary key (srv,name),
	dt varchar(500)
)

insert @dst values
('srv1','Pavel','hello world'),
('srv1','Alexey','hello world2'),
('srv2','Pavel','hello world3'),
('srv2','Alexey','hello world4')

insert @src values
('srv1','Pavel','1'),
('srv2','Alexey','1')

select * from @dst
select * from @src

merge @dst t using
(
	select * from
	( values
		('srv1','Pavel','1'),
		('srv2','Alexey','1')
	) t(srv,name,dt)
) s
	on t.srv=s.srv and t.name=s.name
when not matched by target then
	insert (srv,name,dt) values (s.srv,s.name,s.dt)
when matched then update set
	dt = s.dt
;

select * from @dst
