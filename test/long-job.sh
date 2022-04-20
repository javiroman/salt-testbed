#!/bin/sh
JSON='[{"arg":["sleep 14; echo testing"],"client":"local","expr_form":"glob","fun":"cmd.run","tgt":"*"}]'

RESPONSE=`curl -ik https://localhost:8000/login -H 'Content-Type: application/json' -d '[{"eauth":"pam","password":"SOMEPASSWORD","username":"SOMEUSERNAME"}]' 2>/dev/null`
TOKEN=`echo $RESPONSE | grep -oP "[[:alnum:]]{40}"  | uniq`

RESPONSE=`curl -ik https://localhost:8000/minions -H 'Accept: application/json' -H "X-Auth-Token: $TOKEN" -H 'Content-Type: application/json' -d "$JSON" 2>/dev/null`
JID=`echo $RESPONSE | grep -oP "[0-9]{20}" | uniq`
#echo GOT $JID

curl -ik https://localhost:8000/jobs/$JID -H "X-Auth-Token: $TOKEN" 2>/dev/null
echo ""
echo ""
sleep 15
curl -ik https://localhost:8000/jobs/$JID -H "X-Auth-Token: $TOKEN" 2>/dev/null