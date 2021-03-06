--索引视图
/*
原理：对视图创建唯一聚集索引后，结果集将存储在数据库中，就像带有聚集索引的表一样。

适用范围：
（1）大量行进行复杂处理（如聚合大量数据或联接许多行）的视图。
（2）在查询中频繁地引用这类视图。

不适用情景：
（1）具有大量写操作的 OLTP 系统。
（2）具有大量更新的数据库（维护索引视图的成本可能高于维护表索引的成本）。
（3）数据频繁变化（维护索引视图数据的成本可能超过使用索引视图所带来的性能收益）。
（4）不涉及聚合或联接的查询。
（5）GROUP BY 键具有高基数度的数据聚合。高基数度表示键包含许多不同的值。唯一键具有可能的最高基数度，因为每个键具有不同的值。

维护：
*如果很少更新基础数据，则索引视图的效果最佳。
基础数据定期更新前删除所有索引视图，然后再重新生成（这样做可以提高更新的性能）。*/
if(object_id('dbo.testa') is not null) drop table testa;
 GO
create table testa (id bigint not null primary key identity(1,1),tname varchar(20) NULL,tname2 varchar(20) NULL);

insert into testa (tname,tname2) values(N'XXXXXXX',N'XXXXXXX'),(N'YYYYYYYYYY',N'YYYYYYYYYY'),(N'ZZZZZZZZZZ',N'ZZZZZZZZZZ'); 

select * from testa;

create view vtesta
with schemabinding
as select id,tname from dbo.testa;

--视图索引
CREATE UNIQUE CLUSTERED INDEX idx_vtesta ON vtesta(tname);

create view vw_testa
with schemabinding
as select id,tname from dbo.vtesta;

CREATE UNIQUE CLUSTERED INDEX idx_vw_testa ON vw_testa(tname);

/*实现条件:
1.create view with schemabinding (select columnName<具体列> from schema.objectName<两部分命名>)
2.只能创建CREATE UNIQUE CLUSTERED INDEX, 在添加了唯一聚集索引之后，才可以添加非聚集索引
3.from的对象只能实体表，且不能跨库。
4.多表连接只支持inner join（left/right 不支持），而且不能自连接（只能from一次）

视图不能包含UNION子句、TOP子句、ORDERBY子句、Having子句、Rollup子句、Cube子句、compute子句、ComputeBy子句或Distinct关键字；
G． 视图不允许使用某些集合函数，如：Count（*）可以使用count_big（*）代替、avg()、max()、min()、stdev()、stdevp()、var()或varp()等；
H． 视图不能使用Select *这样的语句，也就是说视图的所有字段都必须显示指定；
I． 视图不能包含Text、ntext、image类型的列；
J． 如果视图包含一个GroupBy子句，那么他必须在Select列中包含count_big(*)；
K． 视图中的所有标和用户自定义的函数都必须使用两段式名来引用，即所有者.表或函数名称；
L． 所有的基本表和视图都必须使用 Set Ansi_Nulls On创建；
M． 在创建索引时或创建索引后执行IUD时，必须显示或隐式地执行：
       Set ANSI_NULLS ON
       SET ANSI_PADDING ON
       SET ANSI_WARNINGS ON
       SET ARITHABORT ON
       SET CONCAT_NULL_YIELDS_NULL ON
       SET QUOTED_IDENTIFIER ON
       SET NUMERIC_ROUNDABORT OFF
*/