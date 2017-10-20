create procedure [dbo].[pcktable](@tabname varchar(50))
as
set  nocount on
/*
--CREATE　BY  BianZhongMing  20160823
-- 建表规范审查，具体审查内容：
1.字段
（1）字段只包含数字，字母，下划线（无空格==）
（2）字段以字母开头
（3）字段字母大写
（4）固定字段审计（ID，自增，非空，主键；9个固定字段）
（5）以_cn结尾的字段建议使用NCHAR或NVARCHAR数据类型。
（6）以保留字或关键字命名的字段建议修改字段名称
2.约束
（1）存在主键
（2）存在唯一键
*/
 
if ( object_id('tempdb.dbo.#ck') is not null) DROP TABLE #ck;
select t.TabName,t.ColName,t.DataType,t.max_length,t.isnullable,t.is_identity,i.is_primary_key,i.is_unique_constraint
into #ck
from 
(
SELECT t.name           TabName,--表名
       s.name           SchName, --Schema名
       c.name           ColName,--列名
       tp.name          DataType,
	   c.max_length,
       c.is_nullable isnullable,
	   c.is_identity --是否自增
  FROM sys.tables t, sys.columns c, sys.schemas s, sys.types tp
 WHERE t.schema_id = s.schema_id
   and t.object_id = c.object_id
   and c.system_type_id = tp.system_type_id
   and tp.name<>'sysname' --系统中nvarchar等价于sysname类型
) t left join
(
--查询所有系统索引信息（明细） 利用sp_helpindex 逻辑，避免系统表死锁
SELECT a.name  IndexName,
       c.name  TableName,
       d.name  IndexColumn,
       i.is_primary_key,--为主键=1，其他为0
       i.is_unique_constraint --唯一约束=1，其他为0
  FROM sysindexes a
  JOIN sysindexkeys b
    ON a.id = b.id
   AND a.indid = b.indid
  JOIN sysobjects c
    ON b.id = c.id
  JOIN syscolumns d
    ON b.id = d.id
   AND b.colid = d.colid
join sys.indexes i
on i.index_id=a.indid and c.id=i.object_id  --object_id('md_security')
 WHERE a.indid NOT IN (0, 255) --indid = 0 或 255则为表，其他为索引。
      -- and   c.xtype='U'  /*U = 用户表*/ and   c.status>0 --查所有用户表  
      -- and c.type <> 's' --S = 系统表
   and b.keyno<>0
) i on (t.tabname=i.TableName and t.ColName=i.IndexColumn)
where t.tabname=@tabname
 
--Mysql和Sqlserver数据库系统保留字
if ( object_id('tempdb.dbo.#keyw') is not null) DROP TABLE #keyw; 
SELECT keyw into #keyw
FROM   (VALUES ('ADD'), ('ANALYZE'), ('ASC'), ('BETWEEN'), ('BLOB'), ('CALL'), ('CHANGE'),
               ('CHECK'), ('CONDITION'), ('CONTINUE'), ('CROSS'), ('CURRENT_TIMESTAMP'), ('DATABASE'), ('DAY_MICROSECOND'),
               ('DEC'), ('DEFAULT'), ('DESC'), ('DISTINCT'), ('DOUBLE'), ('EACH'), ('ENCLOSED'),
               ('EXIT'), ('FETCH'), ('FLOAT8'), ('FOREIGN'), ('GOTO'), ('HAVING'), ('HOUR_MINUTE'),
               ('IGNORE'), ('INFILE'), ('INSENSITIVE'), ('INT1'), ('INT4'), ('INTERVAL'), ('ITERATE'),
               ('KEYS'), ('LEADING'), ('LIKE'), ('LINES'), ('LOCALTIMESTAMP'), ('LONGBLOB'), ('LOW_PRIORITY'),
               ('MEDIUMINT'), ('MINUTE_MICROSECOND'), ('MODIFIES'), ('NO_WRITE_TO_BINLOG'), ('ON'), ('OPTIONALLY'), ('OUT'),
               ('PRECISION'), ('PURGE'), ('READ'), ('REFERENCES'), ('RENAME'), ('REQUIRE'), ('REVOKE'),
               ('SCHEMA'), ('SELECT'), ('SET'), ('SPATIAL'), ('SQLEXCEPTION'), ('SQL_BIG_RESULT'), ('SSL'),
               ('TABLE'), ('TINYBLOB'), ('TO'), ('TRUE'), ('UNIQUE'), ('UPDATE'), ('USING'),
               ('UTC_TIMESTAMP'), ('VARCHAR'), ('WHEN'), ('WITH'), ('XOR'), ('ALL'), ('AND'),
               ('ASENSITIVE'), ('BIGINT'), ('BOTH'), ('CASCADE'), ('CHAR'), ('COLLATE'), ('CONNECTION'),
               ('CONVERT'), ('CURRENT_DATE'), ('CURRENT_USER'), ('DATABASES'), ('DAY_MINUTE'), ('DECIMAL'), ('DELAYED'),
               ('DESCRIBE'), ('DISTINCTROW'), ('DROP'), ('ELSE'), ('ESCAPED'), ('EXPLAIN'), ('FLOAT'),
               ('FOR'), ('FROM'), ('GRANT'), ('HIGH_PRIORITY'), ('HOUR_SECOND'), ('IN'), ('INNER'),
               ('INSERT'), ('INT2'), ('INT8'), ('INTO'), ('JOIN'), ('KILL'), ('LEAVE'),
               ('LIMIT'), ('LOAD'), ('LOCK'), ('LONGTEXT'), ('MATCH'), ('MEDIUMTEXT'), ('MINUTE_SECOND'),
               ('NATURAL'), ('NULL'), ('OPTIMIZE'), ('OR'), ('OUTER'), ('PRIMARY'), ('RAID0'),
               ('READS'), ('REGEXP'), ('REPEAT'), ('RESTRICT'), ('RIGHT'), ('SCHEMAS'), ('SENSITIVE'),
               ('SHOW'), ('SPECIFIC'), ('SQLSTATE'), ('SQL_CALC_FOUND_ROWS'), ('STARTING'), ('TERMINATED'), ('TINYINT'),
               ('TRAILING'), ('UNDO'), ('UNLOCK'), ('USAGE'), ('UTC_DATE'), ('VALUES'), ('VARCHARACTER'),
               ('WHERE'), ('WRITE'), ('YEAR_MONTH'), ('ALTER'), ('AS'), ('BEFORE'), ('BINARY'),
               ('BY'), ('CASE'), ('CHARACTER'), ('COLUMN'), ('CONSTRAINT'), ('CREATE'), ('CURRENT_TIME'),
               ('CURSOR'), ('DAY_HOUR'), ('DAY_SECOND'), ('DECLARE'), ('DELETE'), ('DETERMINISTIC'), ('DIV'),
               ('DUAL'), ('ELSEIF'), ('EXISTS'), ('FALSE'), ('FLOAT4'), ('FORCE'), ('FULLTEXT'),
               ('GROUP'), ('HOUR_MICROSECOND'), ('IF'), ('INDEX'), ('INOUT'), ('INT'), ('INT3'),
               ('INTEGER'), ('IS'), ('KEY'), ('LABEL'), ('LEFT'), ('LINEAR'), ('LOCALTIME'),
               ('LONG'), ('LOOP'), ('MEDIUMBLOB'), ('MIDDLEINT'), ('MOD'), ('NOT'), ('NUMERIC'),
               ('OPTION'), ('ORDER'), ('OUTFILE'), ('PROCEDURE'), ('RANGE'), ('REAL'), ('RELEASE'),
               ('REPLACE'), ('RETURN'), ('RLIKE'), ('SECOND_MICROSECOND'), ('SEPARATOR'), ('SMALLINT'), ('SQL'),
               ('SQLWARNING'), ('SQL_SMALL_RESULT'), ('STRAIGHT_JOIN'), ('THEN'), ('TINYTEXT'), ('TRIGGER'), ('UNION'),
               ('UNSIGNED'), ('USE'), ('UTC_TIME'), ('VARBINARY'), ('VARYING'), ('WHILE'), ('X509'),
               ('ZEROFILL'), ('ANY'), ('AUTHORIZATION'), ('BACKUP'), ('BEGIN'), ('BREAK'), ('BROWSE'),
               ('BULK'), ('CHECKPOINT'), ('CLOSE'), ('CLUSTERED'), ('COALESCE'), ('COMMIT'), ('COMPUTE'),
               ('CONTAINS'), ('CONTAINSTABLE'), ('CURRENT'), ('DBCC'), ('DEALLOCATE'), ('DENY'), ('DISK'),
               ('DISTRIBUTED'), ('DUMP'), ('END'), ('ERRLVL'), ('ESCAPE'), ('EXCEPT'), ('EXEC'),
               ('EXECUTE'), ('EXTERNAL'), ('FILE'), ('FILLFACTOR'), ('FREETEXT'), ('FREETEXTTABLE'), ('FULL'),
               ('FUNCTION'), ('INTERSECT'), ('HOLDLOCK'), ('IDENTITY'), ('IDENTITY_INSERT'), ('IDENTITYCOL'), ('LINENO'),
               ('MERGE'), ('NATIONAL'), ('NOCHECK'), ('NONCLUSTERED'), ('NULLIF'), ('OF'), ('OFF'),
               ('OFFSETS'), ('OPEN'), ('PRINT'), ('PROC'), ('PUBLIC'), ('OPENDATASOURCE'), ('OPENQUERY'),
               ('OPENROWSET'), ('OPENXML'), ('OVER'), ('PERCENT'), ('PIVOT'), ('PLAN'), ('RAISERROR'),
               ('READTEXT'), ('RECONFIGURE'), ('REPLICATION'), ('RESTORE'), ('REVERT'), ('ROLLBACK'), ('ROWCOUNT'),
               ('ROWGUIDCOL'), ('RULE'), ('SAVE'), ('SECURITYAUDIT'), ('SESSION_USER'), ('SETUSER'), ('SHUTDOWN'),
               ('SOME'), ('STATISTICS'), ('SYSTEM_USER'), ('TABLESAMPLE'), ('TEXTSIZE'), ('TOP'), ('TRAN'),
               ('TRANSACTION'), ('TRUNCATE'), ('TSEQUAL'), ('UNPIVOT'), ('UPDATETEXT'), ('USER'), ('VIEW'),
               ('WAITFOR'), ('WRITETEXT'), ('ABSOLUTE'), ('ACTION'), ('ADA'), ('ALLOCATE'), ('ARE'),
               ('ASSERTION'), ('AT'), ('AVG'), ('BIT'), ('BIT_LENGTH'), ('CASCADED'), ('CAST'),
               ('CATALOG'), ('CHAR_LENGTH'), ('CHARACTER_LENGTH'), ('COLLATION'), ('CONNECT'), ('CONSTRAINTS'), ('CORRESPONDING'),
               ('COUNT'), ('DATE'), ('DAY'), ('DEFERRABLE'), ('DEFERRED'), ('DESCRIPTOR'), ('DIAGNOSTICS'),
               ('DISCONNECT'), ('DOMAIN'), ('END-EXEC'), ('EXCEPTION'), ('EXTRACT'), ('FIRST'), ('FORTRAN'),
               ('FOUND'), ('GET'), ('GLOBAL'), ('GO'), ('HOUR'), ('IMMEDIATE'), ('INCLUDE'),
               ('INDICATOR'), ('INITIALLY'), ('INPUT'), ('ISOLATION'), ('LANGUAGE'), ('LAST'), ('LEVEL'),
               ('LOCAL'), ('LOWER'), ('MAX'), ('MIN'), ('MINUTE'), ('MODULE'), ('MONTH'),
               ('NAMES'), ('NCHAR'), ('NEXT'), ('NO'), ('NONE'), ('OCTET_LENGTH'), ('ONLY'),
               ('OUTPUT'), ('OVERLAPS'), ('PAD'), ('PARTIAL'), ('PASCAL'), ('POSITION'), ('PREPARE'),
               ('PRESERVE'), ('PRIOR'), ('PRIVILEGES'), ('RELATIVE'), ('ROWS'), ('SCROLL'), ('SECOND'),
               ('SECTION'), ('SESSION'), ('SIZE'), ('SPACE'), ('SQLCA'), ('SQLCODE'), ('SQLERROR'),
               ('SUBSTRING'), ('SUM'), ('TEMPORARY'), ('TIME'), ('TIMESTAMP'), ('TIMEZONE_HOUR'), ('TIMEZONE_MINUTE'),
               ('TRANSLATE'), ('TRANSLATION'), ('TRIM'), ('UNKNOWN'), ('UPPER'), ('VALUE'), ('WHENEVER'),
               ('WORK'), ('YEAR'), ('ZONE')) AS keyw(keyw);
 
--（1）字段只包含数字，字母，下划线（无空格==）
--（2）字段以字母开头
select '【Error】表“'+t.tabname+'”的字段 “'+t.ColName+'” 存在非法字符！' results from #ck t 
where t.ColName like '%[^0-9A-Z_]%' or t.ColName like '[^A-Z]%'
UNION ALL
--表名是小写，字段名要大写
select distinct '【Error】按照规范，表“'+t.tabname+'”名称的字母部分需为小写字母！' results from #ck t 
where t.tabname <>lower(t.tabname) collate Chinese_PRC_CS_AI 
UNION ALL
select '【Error】按照规范，字段“'+t.tabname+'.'+t.ColName+'” 名称的字母部分需为大写字母！' results from #ck t 
where t.ColName <>upper(t.ColName) collate Chinese_PRC_CS_AI   
UNION　ALL
 --ID，自增，非空，主键
select case when (
 select count(1) from #ck t where t.ColName='ID' and t.DataType='bigint' and t.isnullable=0 and 
 t.is_identity=1 and t.is_primary_key=1 and t.is_unique_constraint=0 )=1 
 then '● NOTE：自增非空主键ID存在且符合要求' else '【Error】自增非空主键ID不存在或不符合要求' end results
UNION ALL
--9个固定字段
select case when (
select count(1) from #ck t where colname+'~'+datatype+'~'+cast(max_length as varchar(10))+'~'+cast(isnullable as varchar(10))
 in(
'QA_RULE_CHK_FLG~tinyint~1~1',
'CREATE_TIME~datetime~8~0',
'UPDATE_TIME~datetime~8~0',
'QA_MANUAL_FLG~bit~1~1',
'QA_ACTIVE_FLG~bit~1~0',
'ETL_CRC~bigint~8~1',
'CREATE_BY~varchar~50~1',
'UPDATE_BY~varchar~50~1',
'TMSTAMP~timestamp~8~0' )
)=9 then '● NOTE：9个固定字段存在且符合要求' else '【Error】9个固定字段不全或格式有误！' end results
UNION ALL
--约束检验
select case when p.ct=0 or u.ct=0 then '【Error】没有主键或没有唯一约束（业务主键）！'
else '● NOTE：主键字段数：'+cast(p.ct as varchar(10))+', 唯一约束字段数：'+cast(u.ct as varchar(10)) end results
 from( 
select count(1) ct from #ck t where t.is_primary_key=1 ) p,
(select count(1) ct from #ck t where t.is_unique_constraint=1) u
union all
select '----------------------------------------------------------------' results 
union all
--对(n)varchar/(n)char 和 decimal字段长度进行审计 
 /*判断是否存在长度过短字段*/
select case when count(*)>0 then '● 【Warning】：下面字段的长度过短，可能需要后续调整，请确认字段长度是否合适：' 
else '● NOTE：无长度过短字段。' end results  from #ck
where colname not in /*9个固定字段*/('QA_RULE_CHK_FLG','CREATE_TIME','UPDATE_TIME',
'QA_MANUAL_FLG','QA_ACTIVE_FLG','ETL_CRC','CREATE_BY','UPDATE_BY','TMSTAMP')
and DataType in ('varchar','nvarchar','char','nchar','decimal')
and max_length<5
union all
/*长度过短字段明细*/
select '字段名：'+colname+',	类型：'+DataType+',	最大长度:'+cast(max_length as varchar(10)) results from #ck 
where colname not in /*9个固定字段*/('QA_RULE_CHK_FLG','CREATE_TIME','UPDATE_TIME',
'QA_MANUAL_FLG','QA_ACTIVE_FLG','ETL_CRC','CREATE_BY','UPDATE_BY','TMSTAMP')
and DataType in ('varchar','nvarchar','char','nchar','decimal')
and max_length<5
union all
select '----------------------------------------------------------------' results 
union all
-----------------------------------------------------
--对以_CN结尾的字段的数据类型进行审计
/*判断是否存在以_cn结尾，且数据类型不为nchar或nvarchar的字段*/
select case when count(*)>0 then  '● 【Suggestion】：下面字段以_CN结尾，建议数据类型改为NCHAR或NVARCHAR：' 
else '● NOTE：无以_CN结尾的字段。' end results from #ck
where colname not in /*9个固定字段*/('QA_RULE_CHK_FLG','CREATE_TIME','UPDATE_TIME',
'QA_MANUAL_FLG','QA_ACTIVE_FLG','ETL_CRC','CREATE_BY','UPDATE_BY','TMSTAMP') 
and (colname like '%_cn' or colname like '%_CN')
and DataType  in ('char','varchar')
/*以_cn结尾，且数据类型为char或varchar的字段明细*/
union all
select '字段名: '+colname+',     类型: ' +DataType as results from #ck
where  colname not in /*9个固定字段*/('QA_RULE_CHK_FLG','CREATE_TIME','UPDATE_TIME',
'QA_MANUAL_FLG','QA_ACTIVE_FLG','ETL_CRC','CREATE_BY','UPDATE_BY','TMSTAMP') 
and colname like '%_cn' 
and DataType  in ('char','varchar')
-------------------------------------------------------------------------------------------
union all
select '----------------------------------------------------------------' results 
union all
--对字段名为保留字的字段进行审计
/*判断字段名是否为保留字*/
select case when count(*) >0 then '● 【Warning】：下面字段的名称为保留字，建议修改：'
else '● NOTE：无以保留字命名的字段。' end results from #ck
where colname in (select keyw from #keyw )
/*字段名称为保留字的字段明细*/
union all
select '字段名: '+colname+',     类型: '  +DataType as results from #ck
where colname in (select keyw from #keyw )
union all
select '----------------------------------------------------------------' results 
 
GO