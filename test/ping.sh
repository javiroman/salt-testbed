curl -sS http://192.168.121.158:8000 \
    -H 'Accept: application/x-yaml' \
    -d eauth='pam' \
    -d username='javi' \
    -d password='javi' \
    -d client='local' \
    -d tgt='*' \
    -d fun='test.ping'
