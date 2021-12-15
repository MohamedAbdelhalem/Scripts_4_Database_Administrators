--in this case we are looking for a bad position in the index that make the engine split the pages with also non-default fill factor (> 0) or (< 100%)
--run this query to get the indexes that have a key columns with the following attributes:
--1. has identity column
--2. the identity column is not the first key column
--3. and finally with fill factor > 0 and < 100

--just alter the result of the indexes and reorder the keys and remove the fill factor = 100%

declare @result table (
[database_name] varchar(400), identity_column_position int, index_column_name varchar(300), is_identity bit, index_id int, index_name varchar(400), object_id int, 
table_name varchar(400), index_type varchar(100), WRONG_FillFactor_Val int, RIGHT_FillFactor_Val int, is_unique bit, is_unique_constraint bit)

insert into @result
exec sp_MSforeachdb 'USE [?]
select db_name(db_id()) database_name, identity_column_position, index_column_name, is_identity, index_id, index_name, object_id, table_name, index_type, 
WRONG_FillFactor_Val, RIGHT_FillFactor_Val, is_unique, is_unique_constraint 
from (
select row_number() over(partition by i.name, i.object_id order by i.object_id, i.name) identity_column_position,
c.name index_column_name,c.is_identity, i.index_id, isnull(i.name,'''') index_name, t.object_id, 
''[''+schema_name(t.schema_id)+''].[''+t.name+'']'' table_name, 
i.type_desc index_type, fill_factor WRONG_FillFactor_Val , 0 RIGHT_FillFactor_Val, is_unique, is_unique_constraint  
from sys.indexes i inner join sys.tables t
on i.object_id = t.object_id
inner join sys.index_columns ic
on i.index_id = ic.index_id
and i.object_id = ic.object_id
inner join sys.columns c
on c.object_id = ic.object_id
and c.column_id = ic.column_id
where ic.is_included_column = 0)a
where is_identity = 1 
and identity_column_position != 1
order by table_name, index_name'

select * 
from @result
where db_id([database_name]) > 4

