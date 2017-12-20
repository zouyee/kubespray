#!/bin/bash
touch /tmp/etcd_journal.pos
touch /tmp/kubelet_journal.pos
(while true
do
	echo $(journalctl -r -n 1 -o json -u etcd) | awk '{print $4}' |  sed 's/'\"'/''/g'| sed 's/'\,'/''/g' >>/tmp/etcd_journal.pos
	echo $(journalctl -r -n 1 -o json -u kubelet) | awk '{print $4}' |  sed 's/'\"'/''/g'| sed 's/'\,'/''/g' >>/tmp/kubelet_journal.pos
	sleep 5s
done) &
(etcd_last_pos=$(tail -n 1 /tmp/etcd_journal.pos)
 kubelet_last_pos=$(tail -n 1 /tmp/kubelet_journal.pos)
(journalctl -o json -f  -u kubelet --after-cursor=$kubelet_last_pos| ncat 127.0.0.1 5001) &
(journalctl -o json -f  -u etcd --after-cursor=$etcd_last_pos| ncat 127.0.0.1  5000)
)
