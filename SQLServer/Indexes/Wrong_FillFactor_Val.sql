--Wrong Fill Factor configuration
--in this case we are looking for indexes that are configured with non-default fill factor value (> 0) or (< 100%) but in identity columns 
--either clustered or non-clustered indexes, because in this case there is no page split so we need to fill the index pages till the end.

select index_id, index_name, object_id, table_name, index_type, Wrong_FillFactor_Val , Right_FillFactor_Val, is_unique, is_unique_constraint  
from (
select count(*) c, 
c.name,c.is_identity, i.index_id, isnull(i.name,'') index_name, t.object_id, 
'['+schema_name(t.schema_id)+'].['+t.name+']' table_name, 
i.type_desc index_type, fill_factor Wrong_FillFactor_Val , 0 Right_FillFactor_Val, is_unique, is_unique_constraint  
from sys.indexes i inner join sys.tables t
on i.object_id = t.object_id
inner join sys.index_columns ic
on i.index_id = ic.index_id
and i.object_id = ic.object_id
inner join sys.columns c
on c.object_id = ic.object_id
and c.column_id = ic.column_id
where fill_factor between 1 and 99
and (is_unique = 1 or is_unique_constraint = 1)
and c.is_identity = 1
group by c.name,c.is_identity, i.index_id, i.name, t.object_id, t.schema_id, t.name, i.type_desc, fill_factor, is_unique, is_unique_constraint  
having count(*) = 1) as tab
order by Wrong_FillFactor_Val

