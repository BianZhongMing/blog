--Insert Data Demo
--basic table
use tempdb;
GO

if(object_id('dbo.orders','U') is not NULL) drop table dbo.orders;
GO
create table dbo.orders(
orderid int not null /*identity(1,1)*/ constraint PK_orders primary key,
orderdate date not null constraint DFT_orders_order_date default(current_timestamp),
empid int not null,
custid varchar(10) not null
)

select * from dbo.orders;

-------------Way 1 insert values
insert into dbo.orders values(10001,'20170505',1,'A');
--rows
insert into dbo.orders values
(10002,'20170505',1,'B'),
(10003,'20170506',2,'B'),
(10004,'20170506',1,'A');
--define columns name
insert into dbo.orders(orderid,orderdate,empid,custid) values
(10005,'20170505',1,'C'),
(10006,'20170506',2,'C');
--列:未指定值>default值>未指定default值>nullable>NULL
--values create virtual table
select * from 
(values 
(10002,'20170505',1,'B'),
(10003,'20170506',2,'B'),
(10004,'20170506',1,'A')) as D(id,date,eid,cid);

-------------Way 2 insert select
truncate table dbo.orders;
--insert from a (virtual) table 
insert into dbo.orders 
select * from 
(values 
(10002,'20170505',1,'B'),
(10003,'20170506',2,'B'),
(10004,'20170506',1,'A')) as D(id,date,eid,cid) 
--3 rows affected
--define columns name
insert into dbo.orders(orderid,orderdate,empid,custid)
select * from 
(values 
(10001,'20170505',1,'B'),
(10005,'20170506',2,'B'),
(10006,'20170506',1,'A')) as D(id,date,eid,cid) 
--NOTE:if there are "()" between select clause,must define inserted columns name
insert into dbo.orders
select * from (values (10008,'20170505',1,'B')) as D(id,date,eid,cid) ;
--1 rows affected
insert into dbo.orders
(select * from (values (10008,'20170505',1,'B')) as D(id,date,eid,cid) );
--Error
/*Lookup Error - SQL Server Database Error: Incorrect syntax near the keyword 'select'.*/
--Speed:insert select 场景支持以最小日志方式记录日志操作，整个事务提交，效率高

-------------Way 3 insert exec
if(object_id('dbo.getOrder','P') is not null) drop procedure dbo.getOrder;
GO
create proc dbo.getOrder
@orderid as nvarchar(10)
as 
select orderid+100,orderdate,empid,custid from dbo.orders 
where orderid=@orderid
GO
--exec proc
exec dbo.getOrder @orderid=10001
--Insert exec
insert into dbo.orders
exec dbo.getOrder @orderid=10001
--1 rows affected
insert into dbo.orders(orderid,orderdate,empid,custid)
exec dbo.getOrder @orderid=10002;
--1 rows affected

-------------Way 3 select into
/*ANSI SQL is not included select into caluse */
select * into tempA from dbo.orders;
--10 rows affected
--DML SQL
CREATE TABLE [dbo].[tempA] (
[orderid] int NOT NULL,
[orderdate] date NOT NULL,
[empid] int NOT NULL,
[custid] varchar(10) NOT NULL);
--test insert(double primary key)
insert into tempA 
select * from (values (10001,'20170505',1,'B')) as D(id,date,eid,cid)
--1 rows affected
--identity test
create table #t(id int not null identity(1,1) constraint PK_TT primary key,val int);
insert #t(val) select 1;
select * into tempB from #t;
--DML SQL
CREATE TABLE [dbo].[tempB] (
[id] int IDENTITY(1, 1) NOT NULL,
[val] int NULL)
/*select into caluse:
Cope:column name,data type,nullable,identity,data
Not Cope:constraint,index,trigger
*/
--Speed:select into 非完整恢复模式（FULL）下会以最小日志方式记录日志操作，效率高
--多表/多集合 select into:
select a.test into selectIntoTables from tableA A join tableB B on ...
select test into selectIntoTables from tableA A intersect select test tableB ...
--select into 顺序测试
select * into tempC from dbo.orders order by orderdate;
select * from tempC;--not sort
--执行顺序：集合操作>select>into selectIntoTables>order by

-------------Way 4 bulk insert
select * from dbo.orders;
--export D:\CSVFile.csv
truncate table dbo.orders;
--bulk insert
bulk insert dbo.orders --(orderid,orderdate,empid,custid)
from 'D:\CSVFile.csv'
with(
datafiletype='char',
fieldterminator=',',
rowterminator ='\n'
);
--去掉标题行（从第一行导入）
--ANSI编码
--文件必须放在服务器本地
--date不能包含在""内(删除双引号)
--date包含时间会被截断
/*--D:\CSVFile.csv
10001,2017-05-05 00:00:00,1,B
10002,2017-05-05 00:00:00,1,B
10003,2017-05-06 00:00:00,2,B
10004,2017-05-06 00:00:00,1,A
10005,2017-05-06 00:00:00,2,B
10006,2017-05-06 00:00:00,1,A
10007,2017-05-05 00:00:00,1,B
10008,2017-05-05 00:00:00,1,B
10101,2017-05-05 00:00:00,1,B
10102,2017-05-05 00:00:00,1,B
*/
--BULK INSERT 能以最小日志方式记录日志操作，效率高


--speed testing results:
--select into >> insert select >= bulk insert