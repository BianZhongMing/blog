--merge into test
/*
使用Merge关键字的好处：简洁有效，性能更强
Note：在SQL Server 2008之前没有Merge
*/
create table testsou( --源测试表
id int,
name varchar(10),
des varchar(50)
)

create table testtag( --目标表
id int,
name varchar(10),
des varchar(50)
)

insert into testsou values(1,'small','a small dog'),(2,'big','a big cat'),(3,'middle','middle school');
insert into testtag values(1,'small','a small dog'),(2,'big','HEHE'),(4,'HEHE','');

--Note：merge语句必须分号结尾
merge into testtag t
using testsou s
on t.id=s.id and t.name=s.name
when matched --and (t.des<>s.des)/*去掉则无论是否相等都更新，多个字段更新用OR连接*/ 
    then--ON条件成立且需更新时update
 update set t.des=s.des
when not matched then--不成立时插入
 insert (id,name,des)/*(字段信息，不填则为所有字段)*/ values(s.id,s.name,s.des)
--;下面可选
when not matched by source then--目标表存在，源表不存在的情况（删除）
 delete; /*加上delete即数据同步(testsou和testtag数据一致)*/

select * from testsou;
select * from testtag;

--clear
drop table testsou;
drop table testtag;

/*SQLSERVER真更新，Mysql假更新 （自增ID会变）*/