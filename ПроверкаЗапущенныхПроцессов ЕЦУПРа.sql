select  State '������ ��������', label '����� ��������', COUNT(*) as '���-�� ���������', '�-��������, �-���������'
 from dbo.TaskQueue
where IDParent='0' and Label='���.����������������'
group by State,label

---���������� �� �������� ��������� �������� ������-
select  *
 from dbo.TaskQueue
where IDParent='0' and Label='���.����������������' and State='A'

-------��������� �������� �� �������� ��������� �������� ������-------------
select  a1.ID 'ID-��������',a1.TimeStart '����� �������',a1.Label '����� ��������', a1.Notification '��������� �� ������ ��������'
 from dbo.TaskQueue a1
where  a1.IDparent in
(select  a2.ID from dbo.TaskQueue a2
    where IDParent='0' and  Label='���.����������������' and State='A')
