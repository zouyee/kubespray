#!/bin/bash

url="http://127.0.0.1:30499/api/v1/_raw/pod/namespace/kube-system/name/"`curl -s http://127.0.0.1:30499/api/v1/pod/kube-system|grep -A 1 "paas-auth-*"|head -n 1|gawk -F: '{ print $2 }'|gawk -F, '{ print $1 }'|tr -d '"'`
endpoint=`echo $url|sed s/[[:space:]]//g`
curl -X DELETE $endpoint


