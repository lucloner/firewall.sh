#!/bin/sh
### BEGIN INIT INFO
# Provides:          DASHFW.plugin.advanced.{ACCEPT|DROP}.{INPUT|OUTPORT}.{tcp|udp}.{sport|dport}.sh
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop::    $network $local_fs $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: zhao's firewall
### END INIT INFO

export PATH=/sbin:/usr/sbin:$PATH:/usr/local/sbin:/usr/local/bin

FILENAME=`basename $0 .sh`.sh
NAME=DASHFW.plugin.advanced.$FILENAME
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
param_j=`echo $FILENAME | awk -F '.' '{print $1}'`
param_c=`echo $FILENAME | awk -F '.' '{print $2}'`
param_p=`echo $FILENAME | awk -F '.' '{print $3}'`
param_opt=`echo $FILENAME | awk -F '.' '{print $4}'`
if [ "$param_opt"x = "sh"x ]
then
  param_opt=''
fi
portlist=${param_j}_${param_c}_${param_p}_${param_opt}.lst
touch $portlist

dolist(){
  iptables -L $param_c -n > $var0
  cat $var0 | grep $param_j | grep $param_p | grep $1 > $var1
  if [ ! -s $var1 ]
  then
    var10=''
    if [ ! -z $param_opt ]
    then
      var10='--'"$param_opt $2"
    fi
    iptables -t filter -$1 $param_c -p $param_p $var10 -j $param_j
  fi
}

main_start(){
  main
}

main_stop(){
  main D
}

main_setup(){
  #echo $NAME [$FILENAME] SETUP TEMPLY NOT AVALIBLE
  echo
}

main_install(){
  #echo $NAME [$FILENAME] INSTALL TEMPLY NOT AVALIBLE
  echo
}

main_uninstall(){
  #echo $NAME [$FILENAME] UNINSTALL TEMPLY NOT AVALIBLE
  echo
}

main_init(){
  #echo $NAME [$FILENAME] INIT TEMPLY NOT AVALIBLE
  echo
}

main(){
  var10='I'
  if [ ! -z $1 ]
  then
    var10=$1
  fi
  #echo --READ FILE $portlist
  cat $portlist | while read line
  do
    #echo --APPLY LINE $line
    dolist $var10 $line
  done
}

case "$1" in
start)  #echo "Starting $NAME"
        main_start
        ;;
stop)   #echo "Stoping $NAME"
        main_stop
        ;;
init)
        #echo "Initializing $NAME"
        main_init
        ;;
install)
  #echo "Installing $NAME ..."
  main_install
;;
uninstall)
  #echo "Uninstalling $NAME ..."
  main_uninstall
;;
setup)
  #echo "Setting up $NAME ..."
  main_setup
;;
*)      #echo "Usage: sh $FILENAME {start|stop|init|install|uninstall|setup}"
        #echo "Refreshing"
        main
        ;;
esac
echo  PLUGIN DONE: $NAME [$FILENAME]
exit 0
