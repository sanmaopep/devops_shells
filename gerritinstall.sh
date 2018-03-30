#！/bin/bash

SOFTWARE=gerrit
VERSION=2.5.2
INSTALL_PATH="/opt/gerrit"
ADMIN_USERNAME="admin"
PORT=30

# check 8080
./util/checkport.sh 8080 && exit;
# install git first
git || yum install -y git
read -p "Choose a path you want to install(/opt/gerrit):" INSTALL_PATH

cd $INSTALL_PATH
wget https://gerrit-releases.storage.googleapis.com/gerrit-full-2.5.2.war
# TODO how to answer automatic
java -jar gerrit-full-2.5.2.war init -d gerrit_site << EOF


http


















EOF

# 安装Nginx
install_nginx(){
    sudo rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
    sudo yum install -y nginx
}

if [ -e /etc/nginx ]; then
    install_nginx
fi

cd /etc/nginx/conf.d
cp default.conf default.conf.bak
rm -f default.conf
cat > gerrit.conf << EOF
server {
     listen *:80;
     allow   all;
     deny    all;

     auth_basic "Welcomme to Gerrit Code Review Site!";
     auth_basic_user_file /etc/nginx/gerrit.password;

     location / {
        proxy_pass  http://127.0.0.1:8080;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $host;
    }
}
EOF


## 安装apache生成管理员认证
install_apache(){
    yum install -y httpd
}
htpasswd || install_apache

read -p "Choose a username for admin user(admin):" ADMIN_USERNAME
echo "Choose a password!"
htpasswd -c /etc/nginx/gerrit.password $ADMIN_USERNAME

# 注意关闭apache服务
service httpd stop
./util/checkport.sh 80 && exit;
service nginx start

echo "Install Finished"
echo "Listen at ${PORT}"
echo "Admin's username is ${ADMIN_USERNAME}"