CREATE TABLE idds (
id          int identity(1,1), 
new_id      uniqueidentifier default newid(),
new_seq_id  uniqueidentifier default newsequentialid());

go

Insert into idds (new_id, new_seq_id) values (default,default)
Insert into idds (new_id, new_seq_id) values (default,default)
Insert into idds (new_id, new_seq_id) values (default,default)
Insert into idds (new_id, new_seq_id) values (default,default)
Insert into idds (new_id, new_seq_id) values (default,default)

Select * from idds
