curl -s http://192.168.121.158:8000/login \
    -H "Accept: application/json" \
    -d username=javi \
    -d password=javi \
    -d eauth=pam | jq .
