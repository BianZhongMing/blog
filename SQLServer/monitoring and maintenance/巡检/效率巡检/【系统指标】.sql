--【系统指标】
use master 
GO
/*
--开启xp_cmdshell 
exec sp_configure'show advanced options', 1 
reconfigure with override 
exec sp_configure'xp_cmdshell', 1 
reconfigure with override 
exec sp_configure'show advanced options', 0 
reconfigure with override 
go 
*/

if(object_id('tempdb..#sysInfo') is not null)  drop table #sysInfo;
create table #sysInfo(id int not null identity(1,1),info nvarchar(MAX));

insert into #sysInfo(info)
select '--------------------1.基本硬件信息（品牌，型号）--------------------';
/* 系统信息：systeminfo */
insert into #sysInfo(info)
exec master..xp_cmdshell'systeminfo'

insert into #sysInfo(info)
select '--------------------2.网络信息（响应时间，带宽占用，丢包率）--------------------' as info union all
/* OR本地执行ping */
select '网络数据包统计信息：(Timestamp:'+CONVERT(VARCHAR(20),GETDATE(),21)+')'  union all
select '      输入数据包数量：' + cast(@@pack_received as varchar(MAX)) union all
select '      输出数据包数量：' + cast(@@pack_sent as varchar(MAX)) union all
select '      错误包数量：' + cast(@@packet_errors as varchar(MAX)) union all
/*Returns the number of network packet errors that have occurred on SQL Server connections since SQL Server was last started.*/
select '      错包率：' + cast(@@packet_errors*100./@@pack_received as varchar(MAX))+' %' union all
select 'IP和hostname：' union all
SELECT '      SERVERNAME:'+CONVERT(NVARCHAR(128),SERVERPROPERTY('SERVERNAME')) union all
select '      IPOfSQLServer:'+LOCAL_NET_ADDRESS + 
       '  ClientIPAddress:'+CLIENT_NET_ADDRESS 
 FROM SYS.DM_EXEC_CONNECTIONS WHERE SESSION_ID = @@SPID;
 /*
--执行ipconfig
exec master..xp_cmdshell'ipconfig'
*/

--//操作信息信息（异常日志）

--3.CPU（主频，核数，占用比）
--获取数据库服务器的
declare @tb table (n1 varchar(MAX),n2 varchar(MAX))
insert into @tb
EXEC xp_instance_regread 
  'HKEY_LOCAL_MACHINE',
  'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
  'ProcessorNameString';
insert into #sysInfo(info)
select '--------------------3.CPU（主频，核数，占用比）--------------------' as info union all
select 'CPU型号：'+n2 from @tb union all
--获取数据库服务器CPU核数等信息(只适用于SQL 2005以及以上版本数据库)
SELECT '逻辑CPU核数：'+cast(s.cpu_count as varchar) +
/* s.hyperthread_ratio:一个物理处理器包公开的逻辑内核数与物理内核数的比*/  
'    物理CPU核数：' +cast(s.cpu_count/s.hyperthread_ratio as varchar) 
FROM sys.dm_os_sys_info s OPTION (RECOMPILE);


--4.存储设备(类型，大小，占用比)
--//安全<read类型>
/*执行配置：
EXEC sp_configure 'show advanced options', 1
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE WITH OVERRIDE;
*/
DECLARE @Result   INT;
DECLARE @objectInfo   INT;
DECLARE @DriveInfo   CHAR(1);
DECLARE @TotalSize   VARCHAR(20);
DECLARE @OutDrive   INT;
DECLARE @UnitMB   BIGINT;
DECLARE @FreeRat   FLOAT;
SET @UnitMB = 1048576;
--创建临时表保存服务器磁盘容量信息
declare @DiskCapacity TABLE
(
[DiskCD]   CHAR(1) ,
FreeSize   INT   ,
TotalSize   INT  
);
INSERT @DiskCapacity([DiskCD], FreeSize ) 
EXEC master.dbo.xp_fixeddrives;
EXEC @Result = master.sys.sp_OACreate 'Scripting.FileSystemObject',@objectInfo OUT;
DECLARE CR_DiskInfo CURSOR LOCAL FAST_FORWARD
FOR 
SELECT DiskCD FROM @DiskCapacity
ORDER by DiskCD
OPEN CR_DiskInfo;
FETCH NEXT FROM CR_DiskInfo INTO @DriveInfo
WHILE @@FETCH_STATUS=0
BEGIN
EXEC @Result = sp_OAMethod @objectInfo,'GetDrive', @OutDrive OUT, @DriveInfo
EXEC @Result = sp_OAGetProperty @OutDrive,'TotalSize', @TotalSize OUT
UPDATE @DiskCapacity
SET TotalSize=@TotalSize/@UnitMB
WHERE DiskCD=@DriveInfo
FETCH NEXT FROM CR_DiskInfo INTO @DriveInfo
END
CLOSE CR_DiskInfo
DEALLOCATE CR_DiskInfo;
EXEC @Result=sp_OADestroy @objectInfo
/* SELECT DiskCD   AS [Drive CD]   , 
  STR(TotalSize*1.0/1024,6,2)   AS [Total Size(GB)] ,
  STR((TotalSize - FreeSize)*1.0/1024,6,2)   AS [Used Space(GB)] ,
  STR(FreeSize*1.0/1024,6,2)   AS [Free Space(GB)] ,
  STR(( TotalSize - FreeSize)*1.0/(TotalSize)* 100.0,6,2) AS [Used Rate(%)]  ,
  STR(( FreeSize * 1.0/ ( TotalSize ) ) * 100.0,6,2)    AS [Free Rate(%)]
FROM @DiskCapacity; */
insert into #sysInfo(info)
select '--------------------4.存储设备(类型，大小，占用比)--------------------' as info union all
SELECT 'Disk: '+DiskCD +CHAR(9) + 
'Total:'+cast(STR(TotalSize*1.0/1024,6,2) as varchar(MAX))+' GB' +CHAR(9) + 
'Used:'+cast(STR((TotalSize - FreeSize)*1.0/1024,6,2) as varchar(MAX))+' GB' +CHAR(9) + 
'Free:'+cast(STR(FreeSize*1.0/1024,6,2) as varchar(MAX))+' GB' +CHAR(9) + 
'UsedRate:'+cast(STR(( TotalSize - FreeSize)*1.0/(TotalSize)* 100.0,6,2) as varchar(MAX))+' %' +CHAR(9) + 
'FreeRate:'+cast(STR(( FreeSize * 1.0/ ( TotalSize ) ) * 100.0,6,2) as varchar(MAX))+' %' 
FROM @DiskCapacity;


SELECT *
  FROM #sysInfo
 WHERE     info IS NOT NULL
ORDER BY id;

drop table #sysInfo;
/*
--其他获取信息方式（重复）
--操作系统参数（语言，操作系统位数，内存大小）
exec master..xp_msver;

--服务器名
select 'Server Name:'+ltrim(@@servername);

--内存(类型，大小，占用比)
--适用于SQL Server 2008以及以上的版本:查看物理内存大小，已经使用的物理内存以及还剩下的物理内存。
SELECT CEILING(total_physical_memory_kb * 1.0 / 1024 / 1024)  AS [Physical Memory Size] 
    ,CAST(available_physical_memory_kb * 1.0 / 1024 / 1024 
                       AS DECIMAL(8, 4)) AS [Unused Physical Memory]
    ,CAST(( total_physical_memory_kb - available_physical_memory_kb ) * 1.0
    / 1024 / 1024 AS DECIMAL(8, 4))              AS [Used Physical Memory]
    ,CAST(system_cache_kb*1.0 / 1024/1024 AS DECIMAL(8, 4)) AS [System Cache Size]
FROM  sys.dm_os_sys_memory

*/
