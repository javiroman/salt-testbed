TOKEN=$(sh login.sh | jq -r '.return[0].token')
curl -sS http://192.168.121.158:8000 \
    -H 'Accept: application/json' \
    -H "X-Auth-Token: $TOKEN" \
    -d client=local \
    -d tgt='*' \
    -d fun=file.write \
    -d arg='/tmp/somefile.txt' \
    -d arg='This is some example text

with newlines

A
B
C' | jq .
