USE [master]
GO
/****** Object:  StoredProcedure [dbo].[get_db_backups]    Script Date: 2018-03-12 11:59:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[get_db_backups]
(@p_date varchar(10) = '1982-07-12')
as
begin
if @p_date = '1982-07-12' begin set @p_date = convert(varchar(10),getdate(),120) end

declare @sql varchar(max), @from varchar(10), @to varchar(10), @x int = 0, @columns varchar(max) = '', @select_columns varchar(max) = ''
set @from = case when day(@p_date) != 1 then convert(varchar(10),dateadd(day,- day(@p_date) +1 , @p_date),120) else convert(varchar(10),@p_date,120) end
set @to = case when dateadd(day, 1, @p_date) != 1 then convert(varchar(20),dateadd(s, -1, dateadd(month, 1, dateadd(day,- day(@p_date) +1 , @p_date))),120) else convert(varchar(20),@p_date,120) end

while @x < cast(day(convert(datetime,@to,120)) as int)
begin
set @columns = @columns+'['+convert(varchar(10),dateadd(day, @x, Convert(datetime,@from,120)),120)+'],'
set @select_columns = @select_columns+'
Case ['+convert(varchar(10),dateadd(day, @x, Convert(datetime,@from,120)),120)+'] 
WHEN 10 THEN ''Full - A'' 
WHEN 11 THEN ''Full - M'' 
WHEN 20 THEN ''Diff - A'' 
WHEN 21 THEN ''Diff - M'' 
WHEN 30 THEN ''Log - A'' 
WHEN 31 THEN ''Log - M'' 
WHEN 40 THEN ''File/FG - A'' 
WHEN 41 THEN ''File/FG - M'' 
WHEN 50 THEN ''Diff File - A'' 
WHEN 51 THEN ''Diff File - M'' 
WHEN 60 THEN ''Partial - A'' 
WHEN 61 THEN ''Partial - M'' 
WHEN 70 THEN ''Diff Partial - A'' 
WHEN 71 THEN ''Diff Partial - M'' 
WHEN  0 THEN ''None'' END ['+convert(varchar(10),dateadd(day, @x, Convert(datetime,@from,120)),120)+'],'
set @x = @x + 1
end
set @select_columns = substring(@select_columns,1,len(@select_columns)-1)
set @columns = substring(@columns,1,len(@columns)-1)
SET @SQL = '
SELECT DATABASE_NAME, '+
@select_columns+'
FROM (
select database_name,
case 
when type = ''D'' and by_who = ''A'' then 10 
when type = ''D'' and by_who = ''M'' then 11 
when type = ''I'' and by_who = ''A'' then 20 
when type = ''I'' and by_who = ''M'' then 21 
when type = ''L'' and by_who = ''A'' then 30 
when type = ''L'' and by_who = ''M'' then 31 
when type = ''F'' and by_who = ''A'' then 40 
when type = ''F'' and by_who = ''M'' then 41 
when type = ''G'' and by_who = ''A'' then 50 
when type = ''G'' and by_who = ''M'' then 51 
when type = ''P'' and by_who = ''A'' then 60 
when type = ''P'' and by_who = ''M'' then 61 
when type = ''Q'' and by_who = ''A'' then 70 
when type = ''Q'' and by_who = ''M'' then 71 
else 0 end count_flag, 
backup_finish_date
from (
select row_number() over(order by backup_finish_date) id, type, CONVERT(VARCHAR(10),backup_finish_date,120) backup_finish_date, database_name, db_id(database_name) database_id,
case description when ''MSSQL:'' then ''A'' else ''M'' end by_who
from msdb.dbo.backupset
where backup_finish_date between '+''''+@from+''''+' and '+''''+convert(varchar(20),dateadd(s,-1,convert(datetime,@to,120)+1),120)+''''+')a
where id in (select id from (
select max(id) id, backup_finish_date, database_name
from (
select row_number() over(order by backup_finish_date) id, CONVERT(VARCHAR(10),backup_finish_date,120) backup_finish_date, database_name, db_id(database_name) database_id
from msdb.dbo.backupset
where backup_finish_date between '+''''+@from+''''+' and '+''''+convert(varchar(20),dateadd(s,-1,convert(datetime,@to,120)+1),120)+''''+')aa
group by backup_finish_date, database_name)bb)
) tab1
pivot
(sum(count_flag) for backup_finish_date in ('+@columns+')) piv'

exec (@SQL)
print(@SQL)
end

