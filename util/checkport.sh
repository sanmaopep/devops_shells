# 检查端口是否被占用
# ./checkport.sh 80
# 存放正确返回
PORT=$0

if [ $(netstat -an|grep ":${PORT}") != "" ]; then
    return 0
else
    return -1
fi