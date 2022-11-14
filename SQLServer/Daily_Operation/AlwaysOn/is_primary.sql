use master
go
create function dbo.is_primary()
returns int
as
begin
declare @result int
select @result = case when count(*) > 0 then 1 else 0 end
from sys.dm_hadr_availability_group_states
where primary_recovery_health = 1
return @result
end

select master.dbo.is_primary()

if master.dbo.is_primary() = 1
begin

print('do something')

end
