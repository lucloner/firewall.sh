#!/bin/sh
### BEGIN INIT INFO
# Provides:          DASHFW
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop::    $network $local_fs $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: zhao's firewall
### END INIT INFO

export PATH=/sbin:/usr/sbin:$PATH:/usr/local/sbin:/usr/local/bin

NAME=DASHFW
FILENAME=`basename $0 .sh`.sh
MAINPID=$$
PIDFILE=/var/run/$NAME.pid
USER="root"
GROUP="root"

#初始化
#工作目录
curdir=`dirname $0`
echo WORK DIRECTORY IS $curdir
tmpdir=${curdir}/tmp
plugin=${curdir}/firewall.d
fullpath=${curdir}/$FILENAME
#定义内存空间
ramsize=500k
#工作文件
tracker=${curdir}/tracker.lst
white=${curdir}/white.lst
black=${curdir}/black.lst
dnsserver=${curdir}/dnsserver.lst
touch $tracker
touch $white
touch $black
touch $dnsserver
#cafile=${curdir}/ca.pem
#secureword=${curdir}/secureword.lst
#临时文件
var0=${tmpdir}/var0
var1=${tmpdir}/var1
var2=${tmpdir}/var2
var3=${tmpdir}/var3
var4=${tmpdir}/var4
var5=${tmpdir}/var5
var6=${tmpdir}/var6
var7=${tmpdir}/var7
var8=${tmpdir}/var8
var9=${tmpdir}/var9
var101=${tmpdir}/var101
touch $var0
touch $var1
touch $var2
touch $var3
touch $var4
touch $var5
touch $var6
touch $var7
touch $var8
touch $var9
touch $var101
starttag=${tmpdir}/start.tag
dnslist=${tmpdir}/dnslist.log
peerlist=${tmpdir}/peer.lst
routetable=${tmpdir}/route.tbl
iptablein=${tmpdir}/iptablein.lst
iptableout=${tmpdir}/iptableout.lst
gatewayip=${tmpdir}/gw.ip
localnet=${tmpdir}/net.ip
outofdate=${tmpdir}/outofdate.lst
#获取黑名单
#blacklst=`cat $black`
#获取白名单
#witelst=`cat $white`
#网络地址 @Deprecated
#localip='127.0.0.1'
#netid='127.0.0.0/24'

#输出变量
main_getvar(){
  if [ ! -z "$1" ]
  then
    eval echo '$'$1 > $var9
    cat $var9
  fi
}

if [ "$1" = "getvar" ]
then
  main_getvar $2
  exit 1
fi

#创建虚拟目录占用10k内存
create_tmp() {
  echo CHECKING RAMFS
  mkdir -p $tmpdir
  var10=`mount | grep $tmpdir | grep fwfs | grep tmpfs`
  if [ -z "$var10" ]
  then
      echo CREATE RAMFS name:fwfs size:$ramsize path:$tmpdir
      mount -t tmpfs -o size=$ramsize fwfs $tmpdir
      rm $starttag
  fi
  echo RAMFS DONE
}

#更新防火墙表
updatetables(){
  #获得路由表
  route -n 2>&1 > $routetable
  #获得ip表
  iptables -t filter -L INPUT -n 2>&1 > $iptablein
  iptables -t filter -L OUTPUT -n 2>&1 > $iptableout
}

#更新网络信息
updatelocalnetwork(){
  #获得网关
  route -n | grep ^0.0.0.0 | awk '{print $2}' 2>&1 > $gatewayip
  #获得本地网络
  ip addr | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}/[0-9]{1,2}" | grep -Ev "^127\." > $localnet
}
#主更新
updateinfo(){
  updatetables
  updatelocalnetwork
}

#删除旧的信息
delfromlist() {
  touch $1
  touch $2
  cat $1 | while read line
  do
    echo -del $line form $1 to $2
    sed -e "/$line/d" $2 > $var101
    cp $var101 $2
  done
  echo ----delete to list done now trace [$2]:
  cat $2
  echo ----delete to list trace done----
}

#添加旧的信息
addtolist() {
  touch $1
  touch $2
  echo -ADD $1 TO $2
  cat $1 | while read line
  do
    echo -add $line to $2
    cat /dev/null > $var6
    cat $2 | grep $line > $var6
    if [ ! -s $var6 ]
    then
      echo -added $line
      echo $line >> $2
    else
      echo -already had, skipped
    fi
  done
  echo ----add to list done now trace [$2]:
  cat $2
  echo ----add to list trace done----
}

#根据dns更新ip
nsip() {
  echo -DOMAIN FOR $1 FROM $2

  new_fname=${tmpdir}/ns_${1}_from_${2}.log
  touch $new_fname

  cat /dev/null > $var0
  nslookup $1 $2 | grep -A 1 $1 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" > $var0

  if [ -s $var0 ]
  then
    echo -UPDATE $1 FROM $2
    cat /dev/null > $var8
    cat $var0 | while read line
    do
      echo -found ip: $line
      cat $black | grep $line >> $var8
    done

    if [ ! -s $var8 ]
    then
      echo -NOT IN BLACKLIST THEN CONTINUE UPDATE
      delfromlist $new_fname $dnslist
      cp $var0 $new_fname
      addtolist $new_fname $dnslist
    fi
  fi

  echo -DOMAIN FOR $1 DONE
}

#将ip添加到iptables和route里
addiptables() {
  if [ ! -z $1 ]
  then
    echo NOW ADD [$1] TO IPTABLES
    cat $iptablein | grep $1 > $var3
    cat $iptableout | grep $1 >$var4

    if [ ! -s $var3 ]
    then
      iptables -t filter -I INPUT -s $1 -j ACCEPT
    fi

    if [ ! -s $var4 ]
    then
      iptables -t filter -I OUTPUT  -d $1 -j ACCEPT
    fi
  fi
}

addroute() {
  cat $gatewayip | while read line
  do
    if [ ! -z $1 ]
    then
      echo NOW ADD [$1] TO GATEWAY [$line]
      cat $routetable | grep $1 > $var2
      if [ ! -s $var2 ]
      then
        route add -host $1 gw $line metric 200
      fi
    fi
  done
}

#将ip删除从iptables和route里
deliptables() {
  cat /dev/null > $var3
  cat /dev/null > $var4
  cat $iptablein | grep $1 > $var3
  cat $iptableout | grep $1 > $var4

  echo NOW DELETE [$1] FROM IPTABLES
  if [ ! -s $var3 ]
  then
    echo -del iptables input table accept ip: $1
    iptables -t filter -D INPUT -s $1 -j ACCEPT
  fi
  if [ ! -s $var4 ]
  then
    echo -del iptables output table accept ip: $1
    iptables -t filter -D OUTPUT -d $1 -j ACCEPT
  fi
}

delroute() {
  cat /dev/null > $var2
  cat $routetable | grep $1 > $var2
  echo NOW DELETE [$1] FROM ROUTE

  cat $gatewayip | while read line
  do
      if [ ! -s $var2 ]
      then
        echo -del route source [$1] to [$line]
        route del $1 gw $line metric 200
      fi
  done
}

#代理映射
applytable() {
  if [ -s $1 ]
  then
    cat $1 | while read line
    do
        $2 $line
    done
  fi
}

#应用列表
applylist() {
  applytable $outofdate deliptables
  applytable $peerlist addiptables
  applytable $outofdate delroute
  applytable $peerlist addroute

  cat /dev/null > $outofdate
}

#建立需要跟踪的列表
buildlist() {
  addtolist $dnslist $peerlist
}

buildbasiclist() {
  addtolist $gatewayip $peerlist
  addtolist $dnsserver $peerlist
  addtolist $white $peerlist
}

#业务:处理dns列表
dodns(){
  cat $tracker | while read line
  do
    cat $dnsserver | while read toupdate
    do
      echo nslookuping $line from $toupdate
      nsip $line $toupdate
    done
  done
}

#业务:处理插件
doplugin(){
  mkdir -p $plugin
  touch $plugin/stub.sh
  for line in $plugin/*.sh
  do
    echo NOW RUN PLUGIN: $line $1
    sh $line $1
    echo -- $line $1 DONE
  done
}

#业务:处理列表
dogate() {
  echo NOW RESOLVE TRACKLIST
  dodns
  echo NOW RUN PLUGIN
  doplugin
  echo NOW BUILD NORMAL PRIMITIVE LIST
  buildlist
  echo NOW APPLY LIST
  applylist
  echo NOW UPDATE TABLES
  updateinfo
  echo NOW CHECK TABLES
  chkinlist
  chkintable
  if [ -s $var5 ]
  then
    echo NOT CLEAR IN LIST TO TABLE
    #main_start
    cat $var5
  else
    echo OK!
  fi
  if [ -s $var7 ]
  then
    echo NOT CLEAR IN TABLE TO LIST
    cat $var7 >> $outofdate
    cat $var7
  else
    echo OK!
  fi
}

#业务: 重置IPTABLE
initgate(){
  iptables -t filter -F
  iptables -t filter -A INPUT -j DROP
  iptables -t filter -I INPUT -p udp --sport 53 -j ACCEPT
  cat $localnet | while read line
  do
      iptables -t filter -A OUTPUT -d $line -j DROP
  done
  iptables -t filter -A OUTPUT -j DROP
  iptables -t filter -I OUTPUT -p udp --dport 53 -j ACCEPT
  cat /dev/null > $peerlist
  echo NOW BUILD BASIC PRIMITIVE LIST
  buildbasiclist
  echo NOW APPLY BASIC LIST
  applylist
  echo NOW UPDATE TABLES
  updateinfo
}

#业务: 验证
#业务: 验证所有peer都在表内
chkinlist(){
  cat /dev/null > $var5
  cat $peerlist | while read line
  do
    cat $iptablein | grep $line > $var0
    cat $iptableout | grep $line > $var1
    cat $routetable | grep $line > $var2
    for var10 in $var0 $var1 $var2
    do
      if [ ! -s $var10 ]
      then
        echo $line | grep -v '^0\.0\.0\.0\/0' >> $var5
      fi
    done
  done
}

#业务: 验证表项目都在peer内
chkintable(){
  cat /dev/null > $var6
  cat /dev/null > $var7
  cat $iptablein | grep ACCEPT | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | awk '{print $4}' >> $var6
  cat $iptableout | grep ACCEPT | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | awk '{print $5}' >> $var6
  cat $routetable | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | awk '{print $1}' | grep -E "\.[^0]$|\.[^\.]{2,3}$" >> $var6
  cat $var6 | while read line
  do
    cat $peerlist | grep $line > $var0
    if [ ! -s $var0 ]
    then
      echo $line | grep -v '^0\.0\.0\.0\/0' >> $var7
    fi
  done
}

main_init(){
  create_tmp
  touch $dnslist
  updateinfo &
  doplugin init
}

#执行一下
main_init

#主程序
main_start(){
  initgate
  echo $PID > $starttag
  doplugin start
  dogate
}

main_stop(){
  umount $tmpdir
  rmdir -Rf $tmpdir
  iptables -F
  doplugin stop
}

main_restart(){
  main_stop
  init
  main_start
}

main_install(){
  crontab -l > $var1
  if [ `grep -c "$FILENAME" $var1` -eq 0 ]
  then
    echo "*/5 * * * * sh $fullpath" >> $var1
  fi
  crontab $var1 && rm -f $var1
  doplugin install
}

main_uninstall(){
  doplugin uninstall
  crontab -l > $var1
  if [ `grep -c "$FILENAME" $var1` -gt 0 ]
  then
    sed -e "'/$fullpath/d'" $var1 > $var1
  fi
  crontab $var1 && rm -f $var1
}

main_setup(){
  echo TEMPLY NOT AVALIBLE
  doplugin setup
}

case "$1" in
start)  echo "Starting $NAME"
        main_start
        ;;
stop)   echo "Stoping $NAME"
        main_stop
        ;;
restart|reload|force-reload)
        echo "Restarting $NAME"
        main_restart
        ;;
status)
        echo "Checking $NAME ..."
        if [ -f $starttag ]
        then
          echo "Started"
        else
          echo "Stopped"
        fi
        ;;
install)
  echo "Installing $NAME ..."
  main_install
;;
uninstall)
  echo "Uninstalling $NAME ..."
  main_uninstall
;;
setup)
  echo "Setting up $NAME ..."
  main_setup
;;
*)      echo "Usage: sh $FILENAME {start|stop|restart|reload|force-reload|status}"
        echo "Refreshing"
        if [ -f $starttag ]
        then
          dogate
          echo "Done"
        else
          main_start
        fi
        ;;
esac
exit 0
