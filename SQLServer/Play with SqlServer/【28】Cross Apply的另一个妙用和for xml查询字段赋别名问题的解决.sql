--创建测试表
create table ta (id int ,val varchar(10));
create table tb (id int ,val varchar(10));

insert into ta values(1,'A'),(2,'B');
insert into tb values(1,'AA'),(2,'BB'),(1,'AC'),(2,'BC');

--有一个字符串拼接需求，原来的实现方式如下：
select id,val =stuff((select ','+val from (
select ta.id,tb.val from ta join tb on ta.id=tb.id
) AS b where t.id=b.id for xml path('')),1,1,'')
from (
select ta.id,tb.val from ta join tb on ta.id=tb.id
) AS t group by id

--Cross Apply等价改写
select ta.id,stuff(D.nameO,1,1,'') as val from ta cross apply 
(select ','+tb.val  from tb where ta.id=tb.id for xml path('')) AS D(nameO) ;


--for xml path('') 字段不能用别名
select tb.val+',' as Oname  from tb  for xml path('')
--给别名等价下面的查询：
select tb.val+','   from tb  for xml path('Oname')
--这类需求的解决方式：
--方法1：转成字符串
select cast((
select tb.val+','  from tb order by id  for xml path('')
) as varchar(MAX)) as columnName
--方法2：派生表内联别名
select * from (
select tb.val+','  from tb order by id  for xml path('')
) AS D(columnName)

drop table ta;
drop table tb;