#download packages from repository web pages with filter using Python
#python3 download_packages.py
#>>download
#>>selinux
#>>https://download.docker.com/linux/centos/7/source/stable/Packages/

import os

if __name__=="__main__":
    action=str(input())
    search=str(input())
    url=str(input())
    rpm=str()
    cmd="curl "+url
    page=os.popen(cmd)
    for i in page:
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
