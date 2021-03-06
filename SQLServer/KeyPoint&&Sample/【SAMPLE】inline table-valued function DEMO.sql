--------------inline table-valued function DEMO
IF OBJECT_ID('dbo.fn_usacus') is not null
 drop function dbo.fn_usacus;
go

create function dbo.fn_usacus
(@i varchar(20) ) returns table
as
return
SELECT custid id, companyname name
FROM InsideTSQL.Sales.Customers
where country=@i  --'USA'
;
GO

select * from dbo.fn_usacus('USA');

--数据操作测试
update dbo.fn_usacus('USA') set name='AAAAA' where id=32;
select * from dbo.fn_usacus('USA');

--无参数
alter function dbo.fn_usacus
() returns table
as
return
SELECT custid id, companyname name
FROM InsideTSQL.Sales.Customers
where country='USA';
GO

select * from dbo.fn_usacus();

--schemabinding
alter function dbo.fn_usacus 
() returns table 
with schemabinding
as
return
SELECT custid id, companyname name
FROM Sales.Customers
where country='USA';
GO

alter table Sales.Customers drop column companyname;
--SQL Server Database Error: The object 'fn_usacus' is dependent on column 'companyname'.

--check option 【只能view使用】

drop function dbo.fn_usacus;
