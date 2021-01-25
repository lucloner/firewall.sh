export PATH=/sbin:/usr/sbin:$PATH:/usr/local/sbin:/usr/local/bin
route add -host 192.168.0.251 gw 192.168.2.129
route add -net 192.168.1.0/24 gw 192.168.177.2
