select * 
from (
select table_name, index_id, index_name, index_column_id, column_id, column_name, key_ordinal, is_included_column, 
case when row_number() over(partition by index_name, is_included_column order by is_included_column, index_id desc, key_ordinal) = 1 
and index_id != 1 then 1 else 0 end index_keys,
row_number() over(partition by column_id order by is_included_column, index_id desc, key_ordinal) part
from (
select object_name(c.object_id) table_name,i.index_id,i.name index_name, index_column_id, ic.column_id, c.name column_name, key_ordinal, is_included_column
  from sys.index_columns ic inner join sys.columns c 
    on ic.column_id = c.column_id 
   and ic.object_id = c.object_id
 inner join sys.indexes i
    on i.index_id = ic.index_id
   and i.object_id = ic.object_id
 where i.index_id in (2)
   and c.object_id = object_id('wse_ibt_user_tracking_details') 
union all
select object_name(c.object_id),i.index_id,i.name, index_column_id,ic.column_id,c.name,key_ordinal,is_included_column
  from sys.index_columns ic inner join sys.columns c 
    on ic.column_id = c.column_id 
   and ic.object_id = c.object_id
 inner join sys.indexes i
    on i.index_id = ic.index_id
   and i.object_id = ic.object_id
 where i.index_id in (0,1)
   and c.object_id = object_id('wse_ibt_user_tracking_details') 
 )a)b
 where part = 1
 order by is_included_column, index_id desc, key_ordinal
