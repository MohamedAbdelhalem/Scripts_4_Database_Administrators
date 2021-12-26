
CREATE TABLE OrigenalData  (ID number,Character nvarchar2(4));
/
INSERT INTO OrigenalData VALUES (1, 'a');
INSERT INTO OrigenalData VALUES (2, 'b');
INSERT INTO OrigenalData VALUES (3, 'c');
INSERT INTO OrigenalData VALUES (4, 'd');
INSERT INTO OrigenalData VALUES (5, 'e');
INSERT INTO OrigenalData VALUES (6, 'f');
INSERT INTO OrigenalData VALUES (7, 'g');
INSERT INTO OrigenalData VALUES (8, 'h');
INSERT INTO OrigenalData VALUES (9, 'i');
INSERT INTO OrigenalData VALUES (10, 'j');
INSERT INTO OrigenalData VALUES (11, 'k');
INSERT INTO OrigenalData VALUES (12, 'l');
INSERT INTO OrigenalData VALUES (13, 'm');
INSERT INTO OrigenalData VALUES (14, 'n');
INSERT INTO OrigenalData VALUES (15, 'o');
INSERT INTO OrigenalData VALUES (16, 'p');
INSERT INTO OrigenalData VALUES (17, 'q');
INSERT INTO OrigenalData VALUES (18, 'r');
INSERT INTO OrigenalData VALUES (19, 's');
INSERT INTO OrigenalData VALUES (20, 't');
INSERT INTO OrigenalData VALUES (21, 'u');
INSERT INTO OrigenalData VALUES (22, 'v');
INSERT INTO OrigenalData VALUES (23, 'w');
INSERT INTO OrigenalData VALUES (24, 'x');
INSERT INTO OrigenalData VALUES (25, 'y');
INSERT INTO OrigenalData VALUES (26, 'z');
INSERT INTO OrigenalData VALUES (27, '1');
INSERT INTO OrigenalData VALUES (28, '2');
INSERT INTO OrigenalData VALUES (29, '3');
INSERT INTO OrigenalData VALUES (30, '4');
INSERT INTO OrigenalData VALUES (31, '5');
INSERT INTO OrigenalData VALUES (32, '6');
INSERT INTO OrigenalData VALUES (33, '7');
INSERT INTO OrigenalData VALUES (34, '8');
INSERT INTO OrigenalData VALUES (35, '9');
INSERT INTO OrigenalData VALUES (36, '0');
INSERT INTO OrigenalData VALUES (37, '@');
commit;

CREATE TABLE EncryptedData (ID number,Character_Name nvarchar2(5));
/
INSERT INTO EncryptedData VALUES (1,'~');
INSERT INTO EncryptedData VALUES (2,'ë');
INSERT INTO EncryptedData VALUES (3,'ε');
INSERT INTO EncryptedData VALUES (4,'Ç');
INSERT INTO EncryptedData VALUES (5,'é');
INSERT INTO EncryptedData VALUES (6,'á');
INSERT INTO EncryptedData VALUES (7,'α');
INSERT INTO EncryptedData VALUES (8,'╧');
INSERT INTO EncryptedData VALUES (9,'╩');
INSERT INTO EncryptedData VALUES (10,'╤');
INSERT INTO EncryptedData VALUES (11,'╪');
INSERT INTO EncryptedData VALUES (12,'¥');
INSERT INTO EncryptedData VALUES (13,'╔');
INSERT INTO EncryptedData VALUES (14,'¼');
INSERT INTO EncryptedData VALUES (15,'┌');
INSERT INTO EncryptedData VALUES (16,'║');
INSERT INTO EncryptedData VALUES (17,'◄');
INSERT INTO EncryptedData VALUES (18,'§');
INSERT INTO EncryptedData VALUES (19,'╚');
INSERT INTO EncryptedData VALUES (20,'░');
INSERT INTO EncryptedData VALUES (21,'┼');
INSERT INTO EncryptedData VALUES (22,'¿');
INSERT INTO EncryptedData VALUES (23,'µ');
INSERT INTO EncryptedData VALUES (24,'■');
INSERT INTO EncryptedData VALUES (25,'ê');
INSERT INTO EncryptedData VALUES (26,'¶');
INSERT INTO EncryptedData VALUES (27,'ƒ');
INSERT INTO EncryptedData VALUES (28,'♀');
INSERT INTO EncryptedData VALUES (29,'▒');
INSERT INTO EncryptedData VALUES (30,'☼');
INSERT INTO EncryptedData VALUES (31,'¡');
INSERT INTO EncryptedData VALUES (32,'┬');
INSERT INTO EncryptedData VALUES (33,'▼');
INSERT INTO EncryptedData VALUES (34,'ç');
INSERT INTO EncryptedData VALUES (35,'⌐');
INSERT INTO EncryptedData VALUES (36,'ÿ');
INSERT INTO EncryptedData VALUES (37,'♣');

commit;

Create or replace Type TType as object (Origenal varchar2(5), encrypted varchar2(5));
/

Create or replace Type Table_Type as Table Of TType;
/

Create or replace Function Fn_RandomEncryption
(Random_ number)
return Table_Type
as
v table_type;
begin

v := table_type();

select cast(multiset(select Character, Character_Name from (
select org.Character, Character_Name
from (
select case when id  > (select count(*) from encrypteddata)
then id - (select count(*) from encrypteddata)
else id end id, character_Name
from (
select id, character_Name
from (
select id + Random_ id, character_Name
from encrypteddata)a)b)e, OrigenalData org
where org.id = e.id)) as table_type)
into v
from dual;

return v;
end Fn_RandomEncryption;
/

CREATE or replace VIEW Random_Number
AS
select ID 
from (
Select ID
From OrigenalData 
order by dbms_random.value)
where rownum = 1
/

CREATE OR REPLACE FUNCTION Encrypt_this
(stg_ varchar2)
return varchar2
as
Origenal_     varchar2(100);
Encrypt_      varchar2(100);
Random_       varchar2(10);
string        varchar(4000);
i             sys_refcursor;
cursor R
is
select Origenal, encrypted from table(fn_RandomEncryption(19));

begin
select ID into random_
from random_number;

string := stg_;

open i
for
'select origenal, encrypted from table(fn_randomencryption('||random_||'))';

loop
fetch i into origenal_, encrypt_;
exit when i%notfound;

string := replace (string, origenal_ , Encrypt_);

end loop;
close i;

open R;
loop
fetch R into Origenal_ , Encrypt_;
exit when R%notfound;

random_ := replace (random_ , origenal_ , Encrypt_);

end loop;
close R;

Return random_||' '||string;
End Encrypt_this;
/


CREATE OR REPLACE FUNCTION Decrypt_this
(stg_ varchar2)
return varchar2
as
Origenal_     varchar2(100);
Encrypt_      varchar2(100);
Random_       varchar2(10);
string        varchar(4000);
i             sys_refcursor;
cursor R
is
select Origenal, encrypted
from table(fn_RandomEncryption(19));
begin
select ID into random_
from random_number;

random_ := substr(stg_,1,instr(stg_,' ',1,1)-1);
string  := substr(stg_,instr(stg_,' ',1,1)+1,length(stg_));

open R;
loop
fetch R into Origenal_ , Encrypt_;
exit when R%notfound;

random_ := replace (random_ ,Encrypt_, origenal_);

end loop;
close R;

open i
for
'select origenal, encrypted from table(fn_randomencryption('||random_||'))';
loop
fetch i into origenal_, encrypt_;
exit when i%notfound;

string := replace (string,Encrypt_, origenal_);

end loop;
close i;

Return string;
End Decrypt_this;
/


select Encrypt_This('my name is mohamed fawzy ismail and my number is 058 251 5565') from dual;

select Encrypt_This('my name is mohamed fawzy ismail and my number is 058 251 5565') from dual;

select Encrypt_This('my name is mohamed fawzy ismail and my number is 058 251 5565') from dual;

select Encrypt_This('my name is mohamed fawzy ismail and my number is 058 251 5565') from dual;

select Encrypt_This('my name is mohamed fawzy ismail and my number is 058 251 5565') from dual;




select Decrypt_This('╤¥ ┌ƒ ║ε┌α ╪┼ ┌◄╤ε┌αá ╧εê♀ƒ ╪┼┌ε╪¼ ε║á ┌ƒ ║µ┌Çα░ ╪┼ ~▼ÿ ☼▼▒ ▼▼ç▼') from dual;
