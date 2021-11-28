import os

if __name__=="__main__":
    action=str(input())
    search=str(input())
    url=str(input())
    rpm=str()
    rpms = list(open('postgreSQL.repo.txt'))
    for i in rpms:
        if '.rpm' in i:
            rpm = i.split('>')[1]
            rpm = rpm[0:-3]
            if search == 'all':
                cmd = "curl -O "+url+rpm
                if action == 'view':
                    print(cmd)
                elif action == "download":
                    os.system(cmd)
            else:
                cmd = "curl -O "+url+rpm
                if action == 'view' and search in rpm:
                    print(cmd)
                elif action == "download" and search in rpm:
                    os.system(cmd)


