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

FILENAME=$0
NAME=DASHFW.plugin.$(basename $FILENAME)
MAINPID=$$
PIDFILE=/var/run/$NAME.pid
USER="root"
GROUP="root"
touch $PIDFILE

#声明临时文件
tmpdir=$(mount | grep fwfs | grep tmpfs | awk '{print $3}')
if [ -z "$tmpdir" ]; then
	tmpdir='/tmp'
fi

#工作目录
curdir=$(cd $tmpdir/.. && pwd)
plugin=${curdir}/firewall.d
fullpath=${curdir}/$FILENAME
savelast=$tmpdir/$NAME

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

echo ===DOORKEEPER===
route -n | grep eth0 | awk '{print $1}' >$savelast
cat $tmpdir/ns*_from_*.log >$var1
echo ===DOORCHECKED===

main_start() {
	echo $NAME [$FILENAME] START TEMPLY NOT AVALIBLE
}

main_stop() {
	echo $NAME [$FILENAME] STOP TEMPLY NOT AVALIBLE
}

main_setup() {
	echo $NAME [$FILENAME] SETUP TEMPLY NOT AVALIBLE
}

main_install() {
	echo $NAME [$FILENAME] INSTALL TEMPLY NOT AVALIBLE
}

main_uninstall() {
	echo $NAME [$FILENAME] UNINSTALL TEMPLY NOT AVALIBLE
}

main_init() {
	echo $NAME [$FILENAME] INIT TEMPLY NOT AVALIBLE
}

main() {
	echo $NAME [$FILENAME] MAIN WOEKING
	echo 0.0.0.0 >>$var1
	cat $tmpdir/../dnsserver.lst >>$var1
	cat $tmpdir/../white.lst >>$var1
	cat $tmpdir/outofdate.lst >>$savelast
	#sed -i '1,2d' $savelast
	sed -i '/0.0.0.0/d' $savelast
	cat $savelast | while read line; do
		echo DOOR CHECK $line
		if [ ! $(cat $var1 | grep $line) ]; then
			if [ 9 -lt $(cat $var2 | grep $line | wc -l) ]; then
				route del -host $line
				sed -i "/$line/d" $var2
				echo ==DOOR CLOSED $line
			else
				echo $line >>$var2
				echo ==DOOR SIGNED $line
			fi
		else
			sed -i "/$line/d" $var2
			echo ==DOOR OPENED $line
		fi
	done

	echo DOOR CHECK IPTABLES OUTPUT
	iptables -L OUTPUT -n --line-numbers | grep ACCEPT | grep '0\.0\.0\.0' | awk '{print $1,$6}' | grep '0\.0\.0\.0' | awk '{print $1}' >$var3
	while [ 1 -lt $(cat $var3 | wc -l) ]; do
		line=$(cat $var3 | head -n 1)
		[ ! $line ] && break
		echo =DOOR DELETE OUTPUT LINE $line
		iptables -D OUTPUT $(cat $var3 | head -n 1)
		iptables -L OUTPUT -n --line-numbers | grep ACCEPT | grep '0\.0\.0\.0' | awk '{print $1,$6}' | grep '0\.0\.0\.0' | awk '{print $1}' >$var3
	done

	echo DOOR CHECKED DONE
}

case "$1" in
start)
	echo "Starting $NAME"
	main_start
	;;
stop)
	echo "Stoping $NAME"
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
*)
	echo "Usage: sh $FILENAME {start|stop|init|install|uninstall|setup}"
	echo "Refreshing"
	main
	;;
esac
echo PLUGIN DONE: $NAME [$FILENAME]
exit 0
