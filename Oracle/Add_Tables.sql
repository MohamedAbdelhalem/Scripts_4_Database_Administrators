CREATE OR REPLACE PACKAGE ADD_TABLES
AS

FUNCTION ROW_FUN
RETURN VARCHAR2;

FUNCTION DATE_FUN
RETURN VARCHAR2;

PROCEDURE DROP_COLUMNS
(COL VARCHAR2);

PROCEDURE ALTER_TABLES;

PROCEDURE ALTER_TABLES_MAN
(TAB VARCHAR2);

PROCEDURE ADD_ROW_NO;

PROCEDURE ADD_ROW_NO_MAN
(TAB VARCHAR2);

PROCEDURE ALTER_SEQ_NO;

PROCEDURE ADD_SEQ_NO;

PROCEDURE ROW_NO_EXECUTE;

PROCEDURE INSERT_DATE_EXECUTE;

PROCEDURE ADD_INSERT_DATE;

PROCEDURE CREATE_UPDATE_TABLES
(TNS varchar2);

PROCEDURE CREATE_DELETE_TABLES
(TNS varchar2);

PROCEDURE ADD_UPDATE_DATE_THINGS;

PROCEDURE ADD_DELETE_DATE_THINGS;

PROCEDURE ADD_DELETE_UPDATE_TABS_COLS
(TNS VARCHAR);

PROCEDURE ALTER_NEW_TABLES;

PROCEDURE ADD_ROW_NO_4_NEW_TABLES;

PROCEDURE ADD_INSERT_DATE_4_NEW_TABLES;

PROCEDURE ADD_TABLE
(TNS VARCHAR2);

PROCEDURE CREATE_UPDATE_TABLES_MAN
(TNS varchar2 , tab varchar2);

PROCEDURE CREATE_DELETE_TABLES_MAN
(TNS varchar2 ,tab varchar2);

PROCEDURE ADD_UPDATE_DATE_THINGS_MAN
(TAB VARCHAR2);

PROCEDURE ADD_DELETE_DATE_THINGS_MAN
(TAB VARCHAR2);

PROCEDURE ADD_DELETE_UPDATE_4_NEW_TABLES
(TNS VARCHAR2);

PROCEDURE INSERT_JOBS_MAN;

PROCEDURE ADD_TRIGS_PROS_4_NEW_TABLES
(P_USER VARCHAR2 , AUD_USER VARCHAR2);

PROCEDURE TRIGS_PROS_4_NEW_TABLES_RMT
(P_USER VARCHAR2 , AUD_USER VARCHAR2);

PROCEDURE ADD_UPDATE_DATE_COLUMN_MAN
(P_USER VARCHAR2);

PROCEDURE INSERT_DEFAULT_TABLES;

FUNCTION PROCEDURES_001_100
(PRO_NAME VARCHAR2)
RETURN VARCHAR2;

FUNCTION PROCEDURES_101_200
(PRO_NAME VARCHAR2)
RETURN VARCHAR2;

FUNCTION PROCEDURES_201_300
(PRO_NAME VARCHAR2)
RETURN VARCHAR2;

FUNCTION PROCEDURES_301_400
(PRO_NAME VARCHAR2)
RETURN VARCHAR2;

PROCEDURE CREATE_PROCEDURES_PACKAGE
(PRO_NAME VARCHAR2);

PROCEDURE DROP_COLUMN_CONSTRAINTS
(COL VARCHAR2);

PROCEDURE STORED_DATA_TO
(P_USER VARCHAR2);

END ADD_TABLES;
/


CREATE OR REPLACE PACKAGE BODY ADD_TABLES
AS

FUNCTION ROW_FUN
RETURN VARCHAR2
IS
CURSOR COLS IS
select SUBSTR(table_name,1,28)
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
TAB      varchar2(50);
SEL_COLS VARCHAR2(2000);
begin
open cols;
loop fetch cols into TAB;
exit when  cols%notfound;
sel_cols := sel_colS||' O$'||TAB||'; ';
end loop;
close cols;
RETURN SEL_COLS;
end ROW_FUN;

FUNCTION DATE_FUN
RETURN VARCHAR2
IS
CURSOR COLS IS
select SUBSTR(table_name,1,28)
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
TAB      varchar2(50);
SEL_COLS VARCHAR2(2000);
begin
open cols;
loop fetch cols into TAB;
exit when  cols%notfound;
sel_cols := sel_colS||' E$'||TAB||'; ';
end loop;
close cols;
RETURN SEL_COLS;
end DATE_FUN;


PROCEDURE DROP_COLUMNS
(COL VARCHAR2)
IS
CURSOR I IS
SELECT DISTINCT T.TABLE_NAME
FROM USER_TAB_COLUMNS T , USER_TABLES TA
WHERE T.TABLE_NAME=TA.TABLE_NAME
AND COLUMN_NAME =COL;
TAB VARCHAR2(50);
BEGIN
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' DROP COLUMN '||COL);
END LOOP;
CLOSE I;
END DROP_COLUMNS;

PROCEDURE ALTER_TABLES
IS
CURSOR I IS
select table_name
from user_tables;
TAB varchar2(50);
BEGIN
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD ROW_NO NUMBER UNIQUE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD INSERT_DATE DATE DEFAULT SYSDATE');
PACKETS.CREATE_VIEWS_MAN(TAB);
END LOOP;
CLOSE I;
END ALTER_TABLES;

PROCEDURE ALTER_TABLES_MAN
(TAB varchar2)
IS
BEGIN
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD ROW_NO NUMBER UNIQUE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD INSERT_DATE DATE DEFAULT SYSDATE');
END ALTER_TABLES_MAN;


PROCEDURE ADD_ROW_NO
IS
CURSOR INO IS
select table_name
from user_tables;
TAB   varchar2(50);
STAT  varchar2(50);
S_CUR VARCHAR2(200) := 'SELECT COUNT(*) FROM ';
CUR SYS_REFCURSOR;
NUM NUMBER;
BEGIN
OPEN INO;
LOOP FETCH INO INTO TAB;
EXIT WHEN  INO%NOTFOUND;
STAT := SUBSTR(TAB, 1 ,28);
OPEN CUR FOR S_CUR||TAB;
FETCH CUR INTO NUM;
IF NUM > 0 THEN
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE O$'||STAT||'
IS
CURSOR I IS
SELECT ROW_ID , ROW_NO
FROM F$'||STAT||';
V F$'||STAT||'%ROWTYPE;
BEGIN
OPEN I;
LOOP FETCH I INTO V.ROW_ID , V.ROW_NO;
EXIT WHEN  I%NOTFOUND;
UPDATE '||TAB||' SET ROW_NO = V.ROW_NO
WHERE ROWID = V.ROW_ID;
COMMIT;
END LOOP;
CLOSE I;
END O$'||STAT||';');
END IF;
END LOOP;
CLOSE INO;
END ADD_ROW_NO;

PROCEDURE ADD_ROW_NO_MAN
(TAB   varchar2)
IS
STAT  varchar2(50);
S_CUR VARCHAR2(200) := 'SELECT COUNT(*) FROM ';
CUR SYS_REFCURSOR;
NUM NUMBER;
BEGIN
STAT := SUBSTR(TAB, 1 ,28);
OPEN CUR FOR S_CUR||TAB;
FETCH CUR INTO NUM;
IF NUM > 0 THEN
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE O$'||STAT||'
IS
CURSOR I IS
SELECT ROW_ID , ROW_NO
FROM F$'||STAT||';
V F$'||STAT||'%ROWTYPE;
BEGIN
OPEN I;
LOOP FETCH I INTO V.ROW_ID , V.ROW_NO;
EXIT WHEN  I%NOTFOUND;
UPDATE '||TAB||' SET ROW_NO = V.ROW_NO
WHERE ROWID = V.ROW_ID;
COMMIT;
END LOOP;
CLOSE I;
END O$'||STAT||';');
END IF;
END ADD_ROW_NO_MAN;

PROCEDURE ALTER_SEQ_NO
IS
CURSOR I IS
select table_name
from user_tables;
TAB varchar2(50);
BEGIN
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD SEQ_NO NUMBER UNIQUE');
PACKETS.CREATE_VIEWS_MAN(TAB);
END LOOP;
CLOSE I;
END ALTER_SEQ_NO;

PROCEDURE ADD_SEQ_NO
IS
CURSOR INO IS
select table_name
from user_tables;
TAB   varchar2(50);
STAT  varchar2(50);
S_CUR VARCHAR2(200) := 'SELECT COUNT(*) FROM ';
CUR SYS_REFCURSOR;
NUM NUMBER;
BEGIN
OPEN INO;
LOOP FETCH INO INTO TAB;
EXIT WHEN  INO%NOTFOUND;
STAT := SUBSTR(TAB, 1 ,28);
OPEN CUR FOR S_CUR||TAB;
FETCH CUR INTO NUM;
IF NUM > 0 THEN
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE O$'||STAT||'
IS
CURSOR I IS
SELECT ROW_ID , ROW_NO
FROM F$'||STAT||';
V F$'||STAT||'%ROWTYPE;
BEGIN
OPEN I;
LOOP FETCH I INTO V.ROW_ID , V.ROW_NO;
EXIT WHEN  I%NOTFOUND;
UPDATE '||TAB||' SET SEQ_NO = V.ROW_NO
WHERE ROWID = V.ROW_ID;
COMMIT;
END LOOP;
CLOSE I;
END O$'||STAT||';');
END IF;
END LOOP;
CLOSE INO;
END ADD_SEQ_NO;

PROCEDURE ADD_INSERT_DATE
IS
CURSOR N IS
select table_name
from user_tables;
TAB  VARCHAR2(50);
STAT VARCHAR2(50);
S_CUR VARCHAR2(200) := 'SELECT COUNT(*) FROM ';
CUR SYS_REFCURSOR;
NUM NUMBER;
BEGIN
OPEN N;
LOOP FETCH N INTO TAB;
EXIT WHEN  N%NOTFOUND;
STAT := SUBSTR(TAB , 1 , 28);
OPEN CUR FOR S_CUR||TAB;
FETCH CUR INTO NUM;
IF NUM > 0 THEN
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE E$'||STAT||'
IS
BEGIN
FOR I IN 1..235661 LOOP
UPDATE '||TAB||' SET
INSERT_DATE= INSERT_DATE -235661+I
WHERE ROW_NO=I;
commit;
END LOOP;
END E$'||STAT||';');
END IF;
END LOOP;
CLOSE N;
END ADD_INSERT_DATE;


PROCEDURE ROW_NO_EXECUTE
IS
CURSOR I IS
SELECT OBJECT_NAME
FROM USER_OBJECTS
WHERE OBJECT_NAME LIKE 'O$_%'
AND OBJECT_TYPE='PROCEDURE';
PRO VARCHAR2(40);
JOBS NUMBER;
BEGIN
OPEN I;
LOOP FETCH I INTO PRO;
EXIT WHEN I%NOTFOUND;
DBMS_JOB.SUBMIT(JOB=>JOBS, WHAT=>'BEGIN
'||PRO||';
END;',
NEXT_DATE=>SYSDATE +1/24/60/60,
INTERVAL=>'SYSDATE +10/24/60',
FORCE=>TRUE);
dbms_job.run(job=>jOBS);
END LOOP;
CLOSE I;
END ROW_NO_EXECUTE;

PROCEDURE INSERT_DATE_EXECUTE
IS
CURSOR I IS
SELECT OBJECT_NAME
FROM USER_OBJECTS
WHERE OBJECT_NAME LIKE 'E$_%'
AND OBJECT_TYPE='PROCEDURE';
PRO VARCHAR2(40);
JOBS NUMBER;
BEGIN
OPEN I;
LOOP FETCH I INTO PRO;
EXIT WHEN I%NOTFOUND;
DBMS_JOB.SUBMIT(JOB=>JOBS, WHAT=>'BEGIN
'||PRO||';
END;',
NEXT_DATE=>SYSDATE +1/24/60/60,
INTERVAL=>'SYSDATE +10/24/60',
FORCE=>TRUE);
dbms_job.run(job=>jOBS);
END LOOP;
CLOSE I;
END INSERT_DATE_EXECUTE;


PROCEDURE CREATE_UPDATE_TABLES
(TNS varchar2)
is
i SYS_REFCURSOR;
STATE  varchar2(300) := 'select table_name from CURRENT_TABLES@';
tab    varchar2(50);
STAT   varchar2(50);
begin
-----------------COMMENT-------------------------------
-------------------------------------------------------
--THIS PROCEDURE FOR AUD SCHEMA TO CREATE UPDATE TABLES
--IN THE FIRST OF THE REPLICATION
-------------------------------------------------------
open i for STATE||tns;
loop fetch i into tab;
exit when  i%notfound;
STAT := SUBSTR(TAB , 1 , 28);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
create table U'||STAT||' as select * from '||TAB||'@'||TNS||' WHERE ROWNUM = 1000');
end loop;
close i;
end CREATE_UPDATE_TABLES;


PROCEDURE CREATE_DELETE_TABLES
(TNS varchar2)
is
i SYS_REFCURSOR;
STATE  varchar2(300) := 'select table_name from CURRENT_TABLES@';
tab    varchar2(50);
STAT   varchar2(50);
begin
-----------------COMMENT-------------------------------
-------------------------------------------------------
--THIS PROCEDURE FOR AUD SCHEMA TO CREATE DELETE TABLES
--IN THE FIRST OF THE REPLICATION
-------------------------------------------------------
open i for STATE||tns;
loop fetch i into tab;
exit when  i%notfound;
STAT := SUBSTR(TAB , 1 , 28);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
create table D'||STAT||' as select * from '||TAB||'@'||TNS||' WHERE ROWNUM = 1000');
end loop;
close i;
end CREATE_DELETE_TABLES;


PROCEDURE ADD_UPDATE_DATE_THINGS
IS
CURSOR I IS
SELECT TABLE_NAME
FROM USER_TABLES
WHERE TABLE_NAME LIKE 'U_%';
TAB  VARCHAR2(50);
STAT VARCHAR2(50);
BEGIN
-----------------COMMENT---------------------------
---------------------------------------------------
--THIS IS FOR ALL TABLES
--ADD UPDATE_DATE, REFERENCE AND UPDATE_ALL COLUMNS
---------------------------------------------------
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
STAT := SUBSTR(TAB , 1 , 29);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD UPDATE_DATE DATE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD REFERENCE VARCHAR2(10)');
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD UPDATE_ALL DATE');
END LOOP;
CLOSE I;
END ADD_UPDATE_DATE_THINGS;


PROCEDURE ADD_DELETE_DATE_THINGS
IS
CURSOR I IS
SELECT TABLE_NAME
FROM USER_TABLES
WHERE TABLE_NAME LIKE 'D_%';
TAB  VARCHAR2(50);
STAT VARCHAR2(50);
BEGIN
-----------------COMMENT--------------------------
--------------------------------------------------
--THIS IS FOR ALL TABLES
--ADD DELETE_DATEE AND REFERENCE COLUMNS
--------------------------------------------------
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
STAT := SUBSTR(TAB , 1 , 29);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD DELETE_DATEE DATE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD REFERENCE VARCHAR2(10)');
END LOOP;
CLOSE I;
END ADD_DELETE_DATE_THINGS;


PROCEDURE ADD_DELETE_UPDATE_TABS_COLS
(TNS VARCHAR)
IS
BEGIN
-----------------COMMENT--------------------------
--------------------------------------------------
--THIS IS FOR ALL TABLES
--AUTO ALTER NEW U_TABLES AND D_TABLES TO ADD
--U_TABLES UPDATE_DATE , REFERENCE AND UPDATE_ALL
--D_TABLES DELETE_DATEE, REFERENCE..
--ADD_UPDATE_DATE_THINGS + ADD_DELETE_DATE_THINGS
--CREATE_UPDATE_TABLES + CREATE_DELETE_TABLES
--------------------------------------------------
CREATE_UPDATE_TABLES(TNS);
CREATE_DELETE_TABLES(TNS);
ADD_DELETE_DATE_THINGS;
ADD_UPDATE_DATE_THINGS;
END ADD_DELETE_UPDATE_TABS_COLS;


PROCEDURE ALTER_NEW_TABLES
IS
CURSOR I IS
select table_name
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
TAB varchar2(50);
BEGIN
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD ROW_NO NUMBER UNIQUE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' ADD INSERT_DATE DATE DEFAULT SYSDATE');
PACKETS.CREATE_VIEWS_MAN(TAB);
END LOOP;
CLOSE I;
END ALTER_NEW_TABLES;

PROCEDURE ADD_ROW_NO_4_NEW_TABLES
IS
CURSOR INO IS
select table_name
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
PROS VARCHAR2(2000);
TAB  varchar2(50);
STAT varchar2(50);
BEGIN
OPEN INO;
LOOP FETCH INO INTO TAB;
EXIT WHEN  INO%NOTFOUND;
STAT := SUBSTR(TAB, 1 ,28);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE O$'||STAT||'
IS
CURSOR I IS
SELECT ROW_ID , ROW_NO
FROM F$'||STAT||';
V F$'||STAT||'%ROWTYPE;
BEGIN
OPEN I;
LOOP FETCH I INTO V.ROW_ID , V.ROW_NO;
EXIT WHEN  I%NOTFOUND;
UPDATE '||TAB||' SET ROW_NO = V.ROW_NO
WHERE ROWID = V.ROW_ID;
COMMIT;
END LOOP;
CLOSE I;
END O$'||STAT||';');
END LOOP;
CLOSE INO;
SELECT ROW_FUN INTO PROS FROM DUAL;
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE ALL_O$
IS
BEGIN
'||PROS||'
END ALL_O$;');
END ADD_ROW_NO_4_NEW_TABLES;



PROCEDURE ADD_INSERT_DATE_4_NEW_TABLES
IS
CURSOR N IS
select table_name
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
PROS VARCHAR2(2000);
TAB  VARCHAR2(50);
STAT VARCHAR2(50);
BEGIN
OPEN N;
LOOP FETCH N INTO TAB;
EXIT WHEN  N%NOTFOUND;
STAT := SUBSTR(TAB , 1 , 28);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE E$'||STAT||'
IS
BEGIN
FOR I IN 1..235661 LOOP
UPDATE '||TAB||' SET
INSERT_DATE= INSERT_DATE -235661+I
WHERE ROW_NO=I;
commit;
END LOOP;
END E$'||STAT||';');
END LOOP;
CLOSE N;
SELECT DATE_FUN INTO PROS FROM DUAL;
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE ALL_E$
IS
BEGIN
'||PROS||'
END ALL_E$;');
END ADD_INSERT_DATE_4_NEW_TABLES;


PROCEDURE ADD_TABLE
(TNS VARCHAR2)
IS
I SYS_REFCURSOR;
STAT1 VARCHAR2(300) := 'select table_name from user_tables@';
STAT2 VARCHAR2(300) := ' where table_name not in (select table_name from CURRENT_TABLES@';
TAB varchar2(50);
BEGIN
OPEN I FOR STAT1||TNS||STAT2||TNS||')';
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE TABLE '||TAB||' AS SELECT * FROM '||TAB||'@'||TNS);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD UPDATE_DATE DATE');
END LOOP;
CLOSE I;
END ADD_TABLE;

PROCEDURE CREATE_UPDATE_TABLES_MAN
(TNS varchar2 , tab varchar2)
IS
STAT   varchar2(50);
begin
-----------------COMMENT-------------------------------
-------------------------------------------------------
--THIS PROCEDURE FOR AUD SCHEMA TO CREATE UPDATE TABLES
--FOR NEW TABLES
-------------------------------------------------------
STAT := SUBSTR(TAB , 1 , 29);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
create table U'||STAT||' as select * from '||TAB||'@'||TNS||' WHERE ROWNUM = 1000');
end CREATE_UPDATE_TABLES_MAN;

PROCEDURE CREATE_DELETE_TABLES_MAN
(TNS varchar2 ,tab varchar2)
IS
STAT   varchar2(50);
begin
-----------------COMMENT-------------------------------
-------------------------------------------------------
--THIS PROCEDURE FOR AUD SCHEMA TO CREATE DELETE TABLES
--FOR NEW TABLES
-------------------------------------------------------
STAT := SUBSTR(TAB , 1 , 29);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
create table D'||STAT||' as select * from '||TAB||'@'||TNS||' WHERE ROWNUM = 1000');
end CREATE_DELETE_TABLES_MAN;


PROCEDURE ADD_UPDATE_DATE_THINGS_MAN
(TAB VARCHAR2)
IS
STAT VARCHAR2(50);
BEGIN
-----------------COMMENT---------------------------
---------------------------------------------------
--THIS IS FOR NEW TABLES
--ADD UPDATE_DATE, REFERENCE AND UPDATE_ALL COLUMNS
---------------------------------------------------
STAT := SUBSTR(TAB , 1 , 29);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE U'||STAT||' ADD UPDATE_DATE DATE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE U'||STAT||' ADD REFERENCE VARCHAR2(10)');
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE U'||STAT||' ADD UPDATE_ALL DATE');
END ADD_UPDATE_DATE_THINGS_MAN;


PROCEDURE ADD_DELETE_DATE_THINGS_MAN
(TAB  VARCHAR2)
IS
-----------------COMMENT--------------------------
--------------------------------------------------
--THIS IS FOR NEW TABLES
--ADD DELETE_DATEE AND REFERENCE COLUMNS
--------------------------------------------------
STAT VARCHAR2(50);
BEGIN
STAT := SUBSTR(TAB , 1 , 29);
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE D'||STAT||' ADD DELETE_DATEE DATE');
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE D'||STAT||' ADD REFERENCE VARCHAR2(10)');
END ADD_DELETE_DATE_THINGS_MAN;


PROCEDURE ADD_DELETE_UPDATE_4_NEW_TABLES
(TNS VARCHAR2)
IS
-----------------COMMENT--------------------------
--------------------------------------------------
--THIS IS FOR NEW TABLES
--AUTO CREATE U_TABLES AND D_TABLES IN AUD SCHEMA
--AND ALTER THOSE TABLES TO ADD COLUMNS IN..
--U_TABLES UPDATE_DATE , REFERENCE AND UPDATE_ALL
--D_TABLES DELETE_DATEE, REFERENCE..
--------------------------------------------------
I SYS_REFCURSOR;
STAT1 VARCHAR2(300) := 'select table_name from user_tables@';
STAT2 VARCHAR2(300) := ' where table_name not in (select table_name from CURRENT_TABLES@';
TAB varchar2(50);
BEGIN
OPEN I FOR STAT1||TNS||STAT2||TNS||')';
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
CREATE_DELETE_TABLES_MAN(TNS, TAB);
CREATE_UPDATE_TABLES_MAN(TNS, TAB);
ADD_DELETE_DATE_THINGS_MAN(TAB);
ADD_UPDATE_DATE_THINGS_MAN(TAB);
END LOOP;
CLOSE I;
END ADD_DELETE_UPDATE_4_NEW_TABLES;


PROCEDURE INSERT_JOBS_MAN
IS
CURSOR I IS
select 'P$'||SUBSTR(table_name,1,28)
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
PRO VARCHAR2(40);
JOBS NUMBER;
BEGIN
OPEN I;
LOOP FETCH I INTO PRO;
EXIT WHEN I%NOTFOUND;
DBMS_JOB.SUBMIT(JOB=>JOBS, WHAT=>'BEGIN
'||PRO||';
END;',
NEXT_DATE=>SYSDATE +1/24/60/60,
INTERVAL=>'SYSDATE +10/24/60',
FORCE=>TRUE);
dbms_job.run(job=>jOBS);
END LOOP;
CLOSE I;
END INSERT_JOBS_MAN;


PROCEDURE ADD_TRIGS_PROS_4_NEW_TABLES
(P_USER VARCHAR2 , AUD_USER VARCHAR2)
IS
CURSOR I IS
select table_name
from user_tables
where table_name not in (select table_name from CURRENT_TABLES);
TAB varchar2(50);
BEGIN
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
---------COMMENT-------------------------------
-----------------------------------------------
--THIS IS FOR NEW TABLES
--THIS PROCEDURE FOR ADDING
--F$, I$, U$, D$, S$, T$, P$
--AND THIS PROCEDURE THE FINAL ONE..
-----------------------------------------------

PACKETS.INSERT_TRIGGERS_MAN(TAB, AUD_USER);
PACKETS.UPDATE_TRIGGERS_MAN(TAB, AUD_USER);
PACKETS.DELETE_TRIGGERS_MAN(TAB, AUD_USER);
PACKETS.UPDATE_ROW_NO_MAN(TAB);
PACKETS.ROW_NO_TRIGGERS_MAN(TAB);
PACKETS.DELETE_UPDATE_INSERT_PRO_MAN(TAB, P_USER, AUD_USER);
INSERT_JOBS_MAN;
INSERT INTO CURRENT_TABLES (TABLE_NAME)
VALUES (TAB);
COMMIT;
END LOOP;
CLOSE I;
END ADD_TRIGS_PROS_4_NEW_TABLES;

PROCEDURE TRIGS_PROS_4_NEW_TABLES_RMT
(P_USER VARCHAR2 , AUD_USER VARCHAR2)
IS
I SYS_REFCURSOR;
STATEMENT_V VARCHAR2(300) :='select table_name from user_tables
where table_name not in (select table_name from CURRENT_TABLES@';
TAB varchar2(50);
BEGIN
OPEN I FOR STATEMENT_V||P_USER||')';
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
---------COMMENT-------------------------------
-----------------------------------------------
--THIS IS FOR NEW TABLES
--THIS PROCEDURE FOR ADDING
--F$, I$, U$, D$, S$, T$, P$
--AND THIS PROCEDURE THE FINAL ONE..
-----------------------------------------------

PACKETS.INSERT_TRIGGERS_MAN(TAB, AUD_USER);
PACKETS.UPDATE_TRIGGERS_MAN(TAB, AUD_USER);
PACKETS.DELETE_TRIGGERS_MAN(TAB, AUD_USER);
PACKETS.UPDATE_ROW_NO_MAN(TAB);
PACKETS.ROW_NO_TRIGGERS_MAN(TAB);
PACKETS.DELETE_UPDATE_INSERT_PRO_MAN(TAB, P_USER, AUD_USER);
INSERT_JOBS_MAN;
INSERT INTO CURRENT_TABLES (TABLE_NAME)
VALUES (TAB);
COMMIT;
END LOOP;
CLOSE I;
END TRIGS_PROS_4_NEW_TABLES_RMT;

PROCEDURE ADD_UPDATE_DATE_COLUMN_MAN
(P_USER VARCHAR2)
IS
I SYS_REFCURSOR;
STATEMENT_V VARCHAR2(300) :='select table_name from user_tables
where table_name not in (select table_name from CURRENT_TABLES@';
TAB varchar2(50);
BEGIN
OPEN I FOR STATEMENT_V||P_USER||')';
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('
ALTER TABLE '||TAB||' ADD UPDATE_DATEE DATE');
END LOOP;
CLOSE I;
END ADD_UPDATE_DATE_COLUMN_MAN;

PROCEDURE INSERT_DEFAULT_TABLES
IS
BEGIN
INSERT INTO CURRENT_TABLES (TABLE_NAME)
VALUES ('CURRENT_TABLES');
COMMIT;
INSERT INTO CURRENT_TABLES (TABLE_NAME)
VALUES ('ALL_TABLES_COLUMNS');
COMMIT;
END INSERT_DEFAULT_TABLES;

FUNCTION PROCEDURES_001_100
(PRO_NAME VARCHAR2)
RETURN VARCHAR2
IS
CURSOR I IS
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND ROWNUM BETWEEN 1 AND 100;
OBJ VARCHAR2(50);
FUL VARCHAR2(4000);
BEGIN
OPEN I;
LOOP FETCH I INTO OBJ;
EXIT WHEN  I%NOTFOUND;
FUL := FUL ||' '||OBJ||'; ';
END LOOP;
CLOSE I;
RETURN FUL;
END PROCEDURES_001_100;

FUNCTION PROCEDURES_101_200
(PRO_NAME VARCHAR2)
RETURN VARCHAR2
IS
CURSOR I IS
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND OBJECT_NAME NOT IN (
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND ROWNUM BETWEEN 1 AND 100)
AND ROWNUM BETWEEN 1 AND 200;
OBJ VARCHAR2(50);
FUL VARCHAR2(4000);
BEGIN
OPEN I;
LOOP FETCH I INTO OBJ;
EXIT WHEN  I%NOTFOUND;
FUL := FUL ||' '||OBJ||'; ';
END LOOP;
CLOSE I;
RETURN FUL;
END PROCEDURES_101_200;

FUNCTION PROCEDURES_201_300
(PRO_NAME VARCHAR2)
RETURN VARCHAR2
IS
CURSOR I IS
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND OBJECT_NAME NOT IN (
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND ROWNUM BETWEEN 1 AND 200)
AND ROWNUM BETWEEN 1 AND 300;
OBJ VARCHAR2(50);
FUL VARCHAR2(4000);
BEGIN
OPEN I;
LOOP FETCH I INTO OBJ;
EXIT WHEN  I%NOTFOUND;
FUL := FUL ||' '||OBJ||'; ';
END LOOP;
CLOSE I;
RETURN FUL;
END PROCEDURES_201_300;

FUNCTION PROCEDURES_301_400
(PRO_NAME VARCHAR2)
RETURN VARCHAR2
IS
CURSOR I IS
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND OBJECT_NAME NOT IN (
SELECT OBJECT_NAME 
FROM USER_OBJECTS 
WHERE OBJECT_NAME LIKE PRO_NAME
AND OBJECT_TYPE ='PROCEDURE' 
AND ROWNUM BETWEEN 1 AND 300)
AND ROWNUM BETWEEN 1 AND 400;
OBJ VARCHAR2(50);
FUL VARCHAR2(4000);
BEGIN
OPEN I;
LOOP FETCH I INTO OBJ;
EXIT WHEN  I%NOTFOUND;
FUL := FUL ||' '||OBJ||'; ';
END LOOP;
CLOSE I;
RETURN FUL;
END PROCEDURES_301_400;

PROCEDURE CREATE_PROCEDURES_PACKAGE
(PRO_NAME VARCHAR2)
IS
PRO_100 VARCHAR2(4000);
PRO_200 VARCHAR2(4000);
PRO_300 VARCHAR2(4000);
PRO_400 VARCHAR2(4000);
BEGIN
SELECT PROCEDURES_001_100(PRO_NAME) INTO PRO_100 FROM DUAL;
SELECT PROCEDURES_101_200(PRO_NAME) INTO PRO_200 FROM DUAL;
SELECT PROCEDURES_201_300(PRO_NAME) INTO PRO_300 FROM DUAL;
SELECT PROCEDURES_301_400(PRO_NAME) INTO PRO_300 FROM DUAL;
DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE FAWZY$PROCEDURES
IS
BEGIN
'||PRO_100||'
'||PRO_200||'
'||PRO_300||'
'||PRO_400||'
END FAWZY$PROCEDURES;');
END CREATE_PROCEDURES_PACKAGE;

PROCEDURE DROP_COLUMN_CONSTRAINTS
(COL VARCHAR2)
IS
CURSOR I IS
SELECT TABLE_NAME ,CONSTRAINT_NAME FROM  user_cons_columns 
WHERE COLUMN_NAME =COL;
TAB VARCHAR2(30);
CONS VARCHAR2(30);
BEGIN
OPEN I;
LOOP FETCH I INTO TAB, CONS;
EXIT WHEN I%NOTFOUND;
DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE '||TAB||' DROP CONSTRAINT '||CONS);
END LOOP;
CLOSE I;
END DROP_COLUMN_CONSTRAINTS;

PROCEDURE STORED_DATA_TO
(P_USER VARCHAR2)
IS
CURSOR I IS
SELECT TABLE_NAME 
FROM USER_TABLES;
TAB  VARCHAR2(50);
COL  VARCHAR2(3000);
STAT VARCHAR2(30);
CONT NUMBER;
BEGIN
OPEN I;
LOOP FETCH I INTO TAB;
EXIT WHEN  I%NOTFOUND;

SELECT COUNT(*) INTO CONT 
FROM USER_TABLES;

IF CONT > 0 THEN

SELECT PACKETS.COLUM(TAB) INTO COL 
FROM DUAL;
STAT := SUBSTR(TAB , 1 , 28);

DBMS_UTILITY.EXEC_DDL_STATEMENT('
CREATE OR REPLACE PROCEDURE Q$'||STAT||'
IS
BEGIN
INSERT INTO '||P_USER||'.'||TAB||' 
SELECT * FROM '||TAB||';
COMMIT;

DBMS_UTILITY.EXEC_DDL_STATEMENT(''TRUNCATE TABLE '||TAB||''');
END Q$'||STAT||';');

END IF;
END LOOP;
CLOSE I;

END STORED_DATA_TO;

END ADD_TABLES;
/
