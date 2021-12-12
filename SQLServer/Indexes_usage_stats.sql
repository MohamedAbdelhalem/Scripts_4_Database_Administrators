declare 
@object_id     int,
@table_name    varchar(300), 
@index_id      int,
@column_name   varchar(128),
@index_name    varchar(300),
@index_key     varchar(max),
@index_include varchar(max),
@index_type    varchar(25),
@is_disabled   int,
@is_descinding int

declare @table table (
Table_Name varchar(300), Index_Name varchar(300), Index_Type varchar(25), Is_Disabled int,
Key_Columns varchar(max), Include_Columns varchar(max)
--unique CLUSTERED (table_name, index_name)
)

declare @key_columns_cursor		cursor
declare @include_columns_cursor cursor

declare cursor_tables cursor fast_forward
for
select obj.object_id, obj.name, idx.index_id, idx.name, idx.type_desc, idx.is_disabled
from sys.indexes idx inner join sys.objects obj
on obj.object_id = idx.object_id
where obj.type in ('U')
and idx.name is not null

open cursor_tables
fetch next from cursor_tables into @object_id, @table_name, @index_id, @index_name, @index_type, @is_disabled
while @@fetch_status = 0
begin

set @key_columns_cursor = cursor local
for
select col.name, idx_col.is_descending_key
from sys.index_columns idx_col inner join sys.indexes idx
on  idx_col.object_id = idx.object_id
and idx_col.index_id = idx.index_id
inner join sys.objects obj
on obj.object_id = idx.object_id
inner join sys.columns col
on  obj.object_id = col.object_id
and idx_col.column_id = col.column_id
where idx_col.object_id = @object_id
and idx_col.index_id = @index_id
and is_included_column = 0
order by index_column_id

open @key_columns_cursor
fetch next from @key_columns_cursor into @column_name, @is_descinding
while @@fetch_status = 0
begin

set @index_key = isnull(@index_key+',','')+'['+@column_name+'] '+case @is_descinding when 0 then 'ASC' else 'DESC' end

fetch next from @key_columns_cursor into @column_name, @is_descinding
end
close @key_columns_cursor 
deallocate @key_columns_cursor 

--print(@index_key)

set @include_columns_cursor = cursor local
for
select col.name, idx_col.is_descending_key
from sys.index_columns idx_col inner join sys.indexes idx
on  idx_col.object_id = idx.object_id
and idx_col.index_id = idx.index_id
inner join sys.objects obj
on obj.object_id = idx.object_id
inner join sys.columns col
on  obj.object_id = col.object_id
and idx_col.column_id = col.column_id
where idx_col.object_id = @object_id
and idx_col.index_id = @index_id
and is_included_column = 1
order by index_column_id

open @include_columns_cursor
fetch next from @include_columns_cursor into @column_name, @is_descinding
while @@fetch_status = 0
begin

set @index_include = isnull(@index_include+',','')+'['+@column_name+'] '+case @is_descinding when 0 then 'ASC' else 'DESC' end

fetch next from @include_columns_cursor into @column_name, @is_descinding
end
close @include_columns_cursor 
deallocate @include_columns_cursor 

insert into @table values ( 
@table_name, @index_name, @index_type, @is_disabled, @index_key, @index_include)

set @index_include = null
set @index_key = null

fetch next from cursor_tables into @object_id, @table_name, @index_id, @index_name, @index_type, @is_disabled
end
close cursor_tables 
deallocate cursor_tables 

select * from @table order by Table_name, Index_name

select
object_name(ius.object_id) Table_name, idx.name Index_name, idx.type_desc, 
ius.user_scans, ius.user_seeks, ius.user_lookups, ius.user_updates, last_user_scan, last_user_seek, last_user_lookup, last_user_update 
from sys.dm_db_index_usage_stats ius inner join sys.indexes idx
on ius.object_id = idx.object_id
and ius.index_id = idx.index_id
where database_id = db_id()
order by Table_name, Index_name


