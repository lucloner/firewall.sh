#!/bin/sh
### BEGIN INIT INFO
# Provides:          DASHFW.plugin.expressvpn
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop::    $network $local_fs $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: zhao's firewall
### END INIT INFO

export PATH=/sbin:/usr/sbin:$PATH:/usr/local/sbin:/usr/local/bin

command -v expressvpn >/dev/null 2>&1 || { echo >&2 "!!require expressvpn but it's not installed.  Aborting!!"; exit 3; }

NAME=DASHFW.plugin.expressvpn
FILENAME=expressvpn.sh
MAINPID=$$
PIDFILE=/var/run/$NAME.pid
USER="root"
GROUP="root"
touch $PIDFILE

#声明临时文件
tmpdir=`mount | grep fwfs | grep tmpfs | awk '{print $3}'`
if [ -z "$tmpdir" ]
then
  tmpdir='/tmp'
fi

#工作目录
curdir=`cd $tmpdir/.. && pwd`
plugin=${curdir}/firewall.d
fullpath=${curdir}/$FILENAME

#临时文件
var0=${tmpdir}/var0.$NAME
var1=${tmpdir}/var1.$NAME
var2=${tmpdir}/var2.$NAME
var3=${tmpdir}/var3.$NAME
var4=${tmpdir}/var4.$NAME
var5=${tmpdir}/var5.$NAME
var6=${tmpdir}/var6.$NAME
var7=${tmpdir}/var7.$NAME
var8=${tmpdir}/var8.$NAME
var9=${tmpdir}/var9.$NAME

#声明变量
nodelist=${curdir}/node.lst
expressvpn ls all | awk '{print $1}' | sed -n '3,$p' >$nodelist
pinglist=${curdir}/ping.lst
if [ ! -s $pinglist ]
then
  echo www.google.com > $pinglist
  echo www.facebook.com >> $pinglist
  echo www.twitter.com >> $pinglist
  echo t66y.com >> $pinglist
  echo 8.8.8.8 >> $pinglist
fi

#继续获取随机数
nodecnt=`awk 'END{print NR}' $0`
rnd=`cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}'`
rnd=`expr $rnd % $nodecnt + 1`

#声明临时文件
tmpdir=`mount | grep fwfs | grep tmpfs | awk '{print $3}'`
if [ -z "$tmpdir" ]
then
  tmpdir='/tmp'
fi

#临时文件2
iptablein=${tmpdir}/iptablein.lst
iptableout=${tmpdir}/iptableout.lst
tasklist=${tmpdir}/task_${MAINPID}.lst

echo '--OPENING IPTABLES'
iptables -t filter -L OUTPUT -n --line-numbers | grep 'ACCEPT' | grep 'owner' | grep 'UID match 0' | awk '{print $1}' | sed -n '1P' > $var0
iptables -t filter -L OUTPUT -n --line-numbers | grep 'DROP' | awk '{print $1}' | sed -n '1P' > $var1
iptables -t filter -L INPUT -n --line-numbers | grep 'ACCEPT' | grep 'all' | grep "0.0.0.0/0.*0.0.0.0/0" | awk '{print $1}' | sed -n '1P' > $var2
iptables -t filter -L INPUT -n --line-numbers | grep 'DROP' | awk '{print $1}' | sed -n '1P' > $var3
if [ ! -s $var0 ] || [ 0`cat $var0` -ge 0`cat $var1` ]
then
  echo '--ADD IPTABLES OUTPUT'
  iptables -t filter -I OUTPUT -m owner --uid-owner 0 -j ACCEPT
fi
if [ ! -s $var2 ] || [ 0`cat $var2` -ge 0`cat $var3` ]
then
  echo '--ADD IPTABLES INPUT'
  iptables -t filter -I INPUT -j ACCEPT
fi

echo '--DONE IPTABLES'

var10=`cat $PIDFILE`
if [ -s $PIDFILE ]
then
  if [ -d /proc/$var10 ]
  then
    echo $NAME [$FILENAME] IS RUNNING
    echo $1 >> $tasklist
    exit 2
  fi
fi
echo $NAME [$FILENAME] PID CHECKED OK
echo $$ > $PIDFILE

echo nameserver 8.8.8.8 > /etc/resolv.conf
echo nameserver 8.8.4.4 >> /etc/resolv.conf

vpnstatus(){
  expressvpn status > $var5 2>&1
  if [ `grep -c 'Connected to ' $var5` -eq '0' ]
  then
    echo "--ALREADY CONNECT"
    exit 4
  fi
}

vpnconnect(){
  cnt=$rnd
  echo CONNECT EXPRESSVPN FROM LINE $cnt [PID:$$]
  while cnt=`expr $cnt % $nodecnt + 1`
  do
    sed -n "${cnt}P" $nodelist > $var0
    var10=`cat $var0`
    echo CONNECT EXPRESSVPN TO $var10
    cat /dev/null > $var1
    expressvpn connect $var10 > $var1 2>&1
    cat $var1 | grep 'Connected to ' > $var2
    if [ -s $var2 ]
    then
      echo EXPRESSVPN CONNECT SUCCEED
      exit 1
    fi
    vpnstatus
    echo RECONNECT EXPRESSVPN FROM LINE $cnt
  done
}

vpnverify(){
  cat /dev/null > $var4
  cat $pinglist | while read line
  do
    echo ----TEST PING $PING
    ping -c 10 $line >> $var4
  done
  var10=`cat $var4 | grep ", 0 received" | wc -l | awk '{print $1}'`
  echo ----PING FAILED: $var10
  if [ $var10 -gt 2 ]
  then
    echo ----PING FAILED TRY RECONNECT
    expressvpn disconnect
    vpnconnect
  fi
  cat /dev/null > $var4
}

main_start(){
  vpnstatus
  expressvpn refresh
  vpnconnect
}

main_stop(){
  var10=`cat $PIDFILE`
  kill $var10
  expressvpn disconnect
}

main_setup(){
  echo $NAME [$FILENAME] SETUP TEMPLY NOT AVALIBLE
}

main_install(){
  expressvpn autoconnect true
}

main_uninstall(){
  expressvpn disconnect
  expressvpn autoconnect false
  iptables -t filter -D OUTPUT -m owner --uid-owner 0 -j ACCEPT
  iptables -t filter -D INPUT -j ACCEPT
}

main_init(){
  echo $NAME  [$FILENAME] INIT TEMPLY NOT AVALIBLE
}

main(){
  vpnverify
  vpnstatus
}

case "$1" in
start)  echo "Starting $NAME"
        main_start
        ;;
stop)   echo "Stoping $NAME"
        main_stop
        ;;
init)
        echo "Initializing $NAME"
        main_init
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
*)      echo "Usage: sh [$FILENAME] {start|stop|init|install|uninstall|setup}"
        echo "Refreshing"
        main
        ;;
esac

rm $PIDFILE
touch $tasklist
cat $tasklist | while read line
do
  if [ ! -z "$line" ]
  then
    echo  --DOING WAITING THREAD: $NAME [$FILENAME] $line
    sh $0 $line
  fi
done
rm $tasklist

echo  PLUGIN DONE: $NAME [$FILENAME]

exit 0
