IF object_id('dbo.Test_Posting') IS NOT NULL 
BEGIN
	DROP TABLE Test_Posting
END
GO
CREATE table Test_Posting (
	id int identity(3453,1), 
	postid int, 
	postdate datetime default getdate(), 
	remittence_number as 
					 cast(id as varchar(10))+'-'+
					 cast(postid as varchar(10))+'-'+
					 case when month(postdate) between 1 and 6 
				 		 	then right(cast(year(postdate) - 1 as varchar(10)),2) + right(cast(year(postdate) as varchar(10)),2)
					 	 when month(postdate) between 7 and 12
				 		 	then right(cast(year(postdate) as varchar(10)),2) + right(cast(year(postdate) + 1 as varchar(10)),2)
				 	 end						
					 )
           
INSERT into Test_Posting (postid,postdate) values (1232,'2021-01-13');
INSERT into Test_Posting (postid,postdate) values (1232,'2021-02-18');
INSERT into Test_Posting (postid,postdate) values (1232,'2021-06-22');
INSERT into Test_Posting (postid,postdate) values (1232,'2021-07-12');
INSERT into Test_Posting (postid,postdate) values (1232,'2021-09-01');
INSERT into Test_Posting (postid,postdate) values (1232,'2021-12-01');
INSERT into Test_Posting (postid,postdate) values (1232,'2021-12-31');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-01-13');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-02-18');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-06-22');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-07-12');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-09-01');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-12-01');
INSERT into Test_Posting (postid,postdate) values (1232,'2022-12-31');
INSERT into Test_Posting (postid,postdate) values (1232,'2023-01-13');

SELECT * FROM Test_Posting;

