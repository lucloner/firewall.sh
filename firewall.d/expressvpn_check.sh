#!/bin/sh
### BEGIN INIT INFO
# Provides:          DASHFW.plugin.expressvpn_check
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop::    $network $local_fs $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: zhao's firewall
### END INIT INFO

export PATH=/sbin:/usr/sbin:$PATH:/usr/local/sbin:/usr/local/bin

FILENAME=expressvpn_check.sh
NAME=DASHFW.plugin.$FILENAME
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
savelast=$tmpdir/$FILENAME

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

rei_connect(){
	expressvpn disconnect
	if [ -s $savelast ]
	then
		express connect
		rm $savelast
	else
		expressvpn connect smart
	fi
	rm /var/run/DASHFW.plugin.expressvpn.pid
	sh %0
}

echo ===EXPRESSVPN CHECK===
expressvpn_status=`expressvpn status 2>&1`
expressvpn_check=`echo $expressvpn_status | grep "Unable to Connect"`
if [ "$expressvpn_check" != "" ]
then
	  echo 1 Unable to connect!
	  echo $(date) $expressvpn_check >> /root/disconnect.log
	  rei_connect
fi

expressvpn_check=`echo $expressvpn_status | grep "Unable to connect"`
if [ "$expressvpn_check" != "" ]
then
	  echo 2 Unable to connect!
	  echo $(date) $expressvpn_check >> /root/disconnect.log
	  rei_connect
fi
expressvpn_check=`echo $expressvpn_status | grep "Not connected"`
if [ "$expressvpn_check" != ""  ]
then
	  echo 3 Unable to connect!
          echo = $(date) $expressvpn_check >> /root/disconnect.log
	  rei_connect
fi

expressvpn_check=`echo $expressvpn_status | grep "Connected to"`
if [ "$expressvpn_check" != ""  ]
then
	 echo ok! $expressvpn_status > $savelast
	 cat $savelast
fi

echo ===EXPRESSVPN CHECKED===
main_start(){
	  echo $NAME [$FILENAME] START TEMPLY NOT AVALIBLE
  }

main_stop(){
	  echo $NAME [$FILENAME] STOP TEMPLY NOT AVALIBLE
  }

main_setup(){
	  echo $NAME [$FILENAME] SETUP TEMPLY NOT AVALIBLE
  }

main_install(){
	  echo $NAME [$FILENAME] INSTALL TEMPLY NOT AVALIBLE
  }

main_uninstall(){
	  echo $NAME [$FILENAME] UNINSTALL TEMPLY NOT AVALIBLE
  }

main_init(){
	  echo $NAME [$FILENAME] INIT TEMPLY NOT AVALIBLE
  }

main(){
	  echo $NAME [$FILENAME] MAIN TEMPLY NOT AVALIBLE
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
	*)      echo "Usage: sh $FILENAME {start|stop|init|install|uninstall|setup}"
		echo "Refreshing"
		main
		;;
esac
echo  PLUGIN DONE: $NAME [$FILENAME]
exit 0
