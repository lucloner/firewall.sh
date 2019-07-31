#!/bin/sh
### BEGIN INIT INFO
# Provides:          DASHFW.plugin.openSimSim.sh
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop::    $network $local_fs $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: 阿里巴巴与四十大盗 之 芝麻开门( Open Simsim)
### END INIT INFO
### 关于openssl
# 生成私钥
# openssl genrsa -out privkey.pem 2048
# 生成公钥
# openssl rsa -in privkey.pem -outform PEM -out privkey.pub.pem -pubout
# 生成加密文本
# echo word | openssl pkeyutl -encrypt -pubin -inkey privkey.pub.pem -pubin | base64 > secured.word
# 解密
# cat secured.word | base64 -i -d | openssl pkeyutl -decrypt -inkey privkey.pem
### 额外注解结束

export PATH=/sbin:/usr/sbin:$PATH:/usr/local/sbin:/usr/local/bin

command -v ncat >/dev/null 2>&1 || { echo >&2 "!!require ncat but it's not installed.  Aborting!!"; exit 1; }

NAME=DASHFW.plugin.openSimsim
FILENAME=openSimSim.sh
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

#密钥
rsacert=${curdir}/private.pem
pubkey=${curdir}/public.pem

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
peerlist=${tmpdir}/peer.lst
touch $peerlist

#一些工作文件
workinglist=${tmpdir}/thieves.lst
touch $workinglist
outofdate=${tmpdir}/outofdate.lst
touch $outofdate
#white=${curdir}/white.lst
#touch $white

#声明变量
simlist=${curdir}/sim.lst
touch $simlist
simport=63757

#单例
var10=`cat $PIDFILE`
if [ -s $PIDFILE ]
then
  if [ -d /proc/$var10 ]
  then
    echo $NAME [$FILENAME] IS RUNNING
    exit 2
  fi
fi
echo $NAME [$FILENAME] PID CHECKED OK
echo $$ > $PIDFILE

decrypt(){
  if [ ! -s $var2 ]
  then
    return
  fi

  if [ ! -s $var6 ]
  then
    return
  fi

  secureword=`cat $var2`
  ip=`cat $var6`

  echo --try decrypt words for ip: $ip
  cat /dev/null > $var2
  cat /dev/null > $var4
  cat /dev/null > $var7
  echo $secureword | base64 -i -d | openssl pkeyutl -decrypt -inkey $rsacert > $var2
  echo --decrypt result is:
  cat $var2
  cat $var2 | grep $ip > $var7

  if [ ! -s $var7 ]
  then
    cat $simlist | while read line
    do
      echo --test for line: $line
      #支持混淆
      cat $var2 | grep $line > $var5
      if [ -s $var5 ]
      then
        echo --pass word then open...
        cat $workinglist | grep $line | awk '{print $2}' > $var3
        if [ -s $var3 ]
        then
          echo --remove old word
          cat $var3 >> $outofdate
          sed -e "/$line/d" $workinglist > $workinglist
        fi
        echo --open for ip: $ip
        echo $line $ip >> $workinglist
        echo $ip >> $var4
      fi
    done
  fi

  if [ -s $var4 ]
  then
    echo --update wordlist
    cat $workinglist | awk '{print $2}' | while read line
    do
      echo --reading wordlist for ip: $line
      echo $line >> $peerlist
    done
    sh $curdir/firewall.sh
  fi
  echo --done
}

main_exit(){
  echo  PLUGIN DONE: $NAME [$FILENAME]
  exit 0
}

main_install(){
  echo --check cert: $rsacert
  if [ -s $rsacert ]
  then
    return
  fi
  echo --gen cert: $rsacert
  openssl genrsa -out $rsacert 2048
  echo --gen public cert: $pubkey
  openssl rsa -in $rsacert -outform PEM -out $pubkey -pubout
  echo --you pubkey in PEM is:
  cat $pubkey
  echo --save pubkey to encrypt words
}

case "$1" in
encrypt)  echo "Starting $NAME"
        echo "--under constracution"
        main_exit
        ;;
decrypt)   echo "Stoping $NAME"
        echo "--under constracution"
        main_exit
        ;;
install)
  echo "Installing $NAME ..."
  main_install
  main_exit
;;
install)
  echo "Uninstalling $NAME ..."
  rm $rsacert
  main_exit
;;
*)      echo "Usage: sh $FILENAME {encrypt|decrypt|install|uninstall}"
        echo "Listening on port: $simport"
        ;;
esac

main_install
while [ 0 ]; do
        cat /dev/null > $var0
        /usr/bin/ncat -4vule $0 -o $var0 0.0.0.0 $simport > $var1 2>&1
        echo '--'`date`':--'
        if [ ! -z "$var0" ]
        then
                rec=`cat $var0`
                ip1=`cat $var1 | grep 'Ncat: Connection from' | awk '{print $4}' | awk -F '.' '{print $1}'`
                ip2=`cat $var1 | grep 'Ncat: Connection from' | awk '{print $4}' | awk -F '.' '{print $2}'`
                ip3=`cat $var1 | grep 'Ncat: Connection from' | awk '{print $4}' | awk -F '.' '{print $3}'`
                ip4=`cat $var1 | grep 'Ncat: Connection from' | awk '{print $4}' | awk -F '.' '{print $4}'`
                ip=${ip1}.${ip2}.${ip3}.${ip4}
                echo ----received----
                echo $rec
                echo ----analyze------
                echo form ip: $ip
                echo ----end---------
                echo $rec > $var2
                echo $ip > $var6
                decrypt
        fi
done

exit 0
