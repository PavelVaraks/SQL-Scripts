-----���-�� ������� ��������� ���������� ������--------------
select  State '������ ��������', label '����� ��������', COUNT(*) as '���-�� ���������', '�-��������, �-���������'
 from dbo.TaskQueue
where IDParent='0' and Label='AIS3.MPSMGT'
group by State,label

-----���-�� ������� ��������� ������ ����-������--------------
select  State '������ ��������', label '����� ��������', COUNT(*) as '���-�� ���������', '�-��������, �-���������'
 from dbo.TaskQueue
where IDParent='0' and Label='AIS3.MPSPOSTPACK'
group by State,label
