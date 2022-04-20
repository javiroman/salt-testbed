curl -s http://192.168.121.158:8000/login \
    -H "Accept: application/json" \
    -d username='javi' \
    -d password='javi' \
    -d eauth='pam' \
    -d tgt='*' \
    -d fun='test.ping' \

curl -vv http://192.168.121.158:8000/run \
    -H 'Accept: application/x-yaml' \
    -H 'Content-type: application/json' \
    -d '[{
        "client": "local",
        "tgt": "*",
        "fun": "cmd.run",
        "kwarg": {
           "cmd": "df -h"
        },
        "username": "javi",
        "password": "javi",
        "eauth": "pam"
     }]'

