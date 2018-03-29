#！/bin/bash

PORT=389

# install openldap server
if [ ! $(whereis openldap) == ""]; then
    yum install -y openldap openldap-servers openldap-clients
    # check ldap install success
    if [ ! $(whereis openldap) == ""]; then
        echo "openldap install fail"
        exit;
    fi
fi

# start ldap service
service slapd start

if [ ! $(netstat -antup | grep :389) == "" ]; then
    echo "slapd start fail"
    exit;
fi

# generate admin password
domain=""
username=""
read -p "Please Input your LDAP domain" domain
read -p "Please Input your admin username" username
echo "Please Input your admin password"
password=$(slappasswd|grep {SSHA})

full_username="cn=${username},dc=${domain},dc=com"

# generate modify.ldif to modify ldap database
config="
# 修改管理员密码
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: ${password}
# 管理员的DN前缀（一般为Base DN）
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=${domain},dc=com
# 管理员的用户名
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: ${full_username}
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth\" read by
dn.base=\"cn=admin,dc=my-domain,dc=com\" read by * none
"

# TDOO 
# 1.如何自动输入用户名和密码？
# 2.如何加载config
ldapadd -Y EXTERNAL -H ldapi:/// -f modify.ldif

# restart ldap service
service slapd restart

echo "Install Finished!"
echo "Visit by port ${PORT}"
echo "Base DN is dc=${domain},dc=com"
echo "Username is ${full_username}"