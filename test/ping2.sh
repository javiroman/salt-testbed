TOKEN=$(sh login.sh | jq -r '.return[0].token')
curl -sS http://192.168.121.158:8000 \
    -H 'Accept: application/json' \
    -H "X-Auth-Token: $TOKEN" \
    -d client='local' \
    -d tgt='*' \
    -d fun='test.ping' | \
    jq .

