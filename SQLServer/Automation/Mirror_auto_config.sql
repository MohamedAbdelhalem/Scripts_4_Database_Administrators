--Mirror auto set partnet
--#######################
declare 
@db_name	varchar(max),
@partner	varchar(150),
@port		varchar(10),
@sql		varchar(max)

set @partner = 'SPDBCLUST'
set @port = '5022'

declare set_partner_cursor cursor fast_forward
for
select db_name(database_id), *
from sys.database_mirroring
where database_id > 4
and mirroring_partner_name is null

open set_partner_cursor
fetch next from set_partner_cursor into @db_name
while @@fetch_status = 0
begin

set @sql = 'Alter Database ['+@db_name+'] set Partner = ''TCP://'+@partner+':'+@port+''''
exec(@sql)

fetch next from set_partner_cursor into @db_name
end
close set_partner_cursor
deallocate set_partner_cursor

--Principle auto set partnet
--#######################
declare 
@db_name	varchar(max),
@partner	varchar(150),
@port		varchar(10),
@sql		varchar(max)

set @partner = 'SPDBCLUSTDR'
set @port = '5022'

declare set_partner_cursor cursor fast_forward
for
select db_name(database_id)
from sys.database_mirroring
where database_id > 4
and mirroring_partner_name is null
and db_name(database_id) in (
select db.name
from [SPDBCLUSTDR].master.sys.database_mirroring dbm inner join [SPDBCLUSTDR].master.sys.databases db
on dbm.database_id = db.database_id
where dbm.database_id > 4
and dbm.mirroring_partner_name is null)

open set_partner_cursor
fetch next from set_partner_cursor into @db_name
while @@fetch_status = 0
begin

set @sql = 'Alter Database ['+@db_name+'] set Partner = ''TCP://'+@partner+':'+@port+''''
exec(@sql)

fetch next from set_partner_cursor into @db_name
end
close set_partner_cursor
deallocate set_partner_cursor
