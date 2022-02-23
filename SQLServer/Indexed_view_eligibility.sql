select case when sum(isnull(COLUMNPROPERTY(object_id(table_name), column_name, 'IsDeterministic'),0)) > 0 then 'does not eligable to create indexed view' else 'okay' end [status]
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'JV_FBNK_BAB_H_CHQ_DISHONOUR_impr01'
