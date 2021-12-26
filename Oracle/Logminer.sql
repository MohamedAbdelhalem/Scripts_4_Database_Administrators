https://docs.oracle.com/cd/B19306_01/server.102/b14237/dynviews_1154.htm#REFRN30132

SQL> select log_mode from v$database;

LOG_MODE
------------
ARCHIVELOG

SQL> select name from v$database;

NAME
---------
WBMTHD


SQL> select name, supplemental_log_data_min from v$database;

NAME      SUPPLEME
--------- --------
WBMTHD    NO

SQL> alter database add supplemental log data;

SQL> select name, supplemental_log_data_min from v$database;

NAME      SUPPLEME
--------- --------
WBMTHD    YES

SQL> alter system switch logfile;

SQL> begin
    	dbms_logmnr.end_logmnr();
    	dbms_logmnr.add_logfile ('+FRA/WBMTHD/ONLINELOG/group_2.358.995885487');
    	dbms_logmnr.add_logfile ('+FRA/WBMTHD/ONLINELOG/group_1.461.995885487');
   	dbms_logmnr.add_logfile ('+FRA/WBMTHD/ONLINELOG/group_3.261.995885637');
    	dbms_logmnr.add_logfile ('+FRA/WBMTHD/ONLINELOG/group_4.418.995885637');
    	dbms_logmnr.start_logmnr(options=>DBMS_LOGMNR.DICT_FROM_ONLINE_CATALOG);
end;
/

select to_char(TIMESTAMP,'yyyy-mm-dd HH24:MI:SS') OPERATION_TIME, SCN, Operation, SEG_OWNER,username, Table_Name, SEG_TYPE_NAME,Username, OS_Username, Machine_Name, SQL_REDO, SQL_UNDO, INFO,SRC_CON_NAME,SESSION_INFO   
from v$logmnr_contents
where seg_owner = 'ECMSAPP'
and OPERATION = 'DELETE'
order by OPERATION_TIME;

select to_char(TIMESTAMP,'yyyy-mm-dd HH:MI:SS') OPERATION_TIME, SCN, Operation, SEG_OWNER,Table_Name, SEG_TYPE_NAME,Username, OS_Username, Machine_Name, SQL_REDO, SQL_UNDO, INFO,SRC_CON_NAME,SESSION_INFO   
from v$logmnr_contents
where seg_owner = 'ECMSAPP'
and OPERATION = 'UPDATE'
order by OPERATION_TIME;

SQL> begin
    	dbms_logmnr.end_logmnr();
     end;
/

SQL> alter database drop supplemental log data;

