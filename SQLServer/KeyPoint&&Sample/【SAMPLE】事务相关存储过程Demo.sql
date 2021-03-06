--事务相关存储过程Demo

-------------Test Table Create
create table testbzm(
id int primary key,
val varchar(10)
)


--------------Procedure about Transaction
--simple Test
create proc instestbzm  -- create procedure=create proc
( @id1 int,
 @val1 varchar(10),
 @id2 int,
 @val2 varchar(10)
)
as 
BEGIN
insert into testbzm(id ,val) values(@id1,@val1)
insert into testbzm(id ,val) values(@id2,@val2)
END

exec instestbzm 2,'hHEHE',1,'WAWA'
exec instestbzm 3,'hHEHE',1,'WAWA'
exec instestbzm 4,'hHEHE',1,'WAWA'
select * from testbzm
/*
1	WAWA
2	hHEHE
3	hHEHE
4	hHEHE
*/
--整个proc非一个事务，一个INSERT是一个隐式事务
truncate table testbzm
drop proc instestbzm



--需求完整实现
create proc instestbzm  -- create procedure=create proc
( @id1 int,
 @val1 varchar(10),
 @id2 int,
 @val2 varchar(10)
)
as 
BEGIN
BEGIN TRY  
	SET NOCOUNT ON; --Trans 优化
	SET TRANSACTION ISOLATION LEVEL read uncommitted;--允许脏读
BEGIN TRAN  
insert into testbzm(id ,val) values(@id1,@val1)
insert into testbzm(id ,val) values(@id2,@val2)
COMMIT TRAN  
PRINT '事务提交'  
END TRY  
BEGIN CATCH  
ROLLBACK;  
PRINT '事务回滚'; 
END CATCH  
END


exec instestbzm 2,'hHEHE',1,'WAWA'
exec instestbzm 3,'hHEHE',1,'WAWA'
exec instestbzm 4,'hHEHE',1,'WAWA'
select * from testbzm
/*
1	WAWA
2	hHEHE
*/


--Clear
drop table testbzm
drop proc instestbzm



