--if we have a table with wrong identity like id column started 1..100 then you tried to insert a row but you had a vaiolation of some constraints
--and then you tried again you will may got a high value of the id columns let same 1013
--if you run DBCC on this table he will tell you the current identity is 1013
dbcc checkident ('dbo.employees')
--and if you need to fix that you can type the correct value 
--option 1
--update the value of the wrong id with 101 value then run
dbcc checkident ('dbo.employees',RESEED,101)
--option 1
--or delete the record with the wrong id then
dbcc checkident ('dbo.employees',RESEED,100)
--then insert it again regualarly then you will found out it takes 101 id
