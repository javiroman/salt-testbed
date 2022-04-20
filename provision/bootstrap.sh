kernel_tunning() {
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    echo $(hostname).salt.lan | sudo tee /etc/hostname
    sudo systemctl restart systemd-hostnamed
}

bootstrap_dns() {
    echo "Testbed external DNS bootstrapping."
    echo "installing bind ..."
    sudo yum install bind -y --quiet 2> /dev/null
    echo "setting up bind ..."

    DOMAIN="salt.lan"

    DNS=dns
    MASTER=master
    WORKER01=minion01
    WORKER02=minion02
    WORKER03=minion03
    WORKER04=minion04
    MONITOR=monitor

    HOST_DNS="$DNS.$DOMAIN"
    HOST_MASTER="$MASTER.$DOMAIN"
    HOST_WORKER01="$WORKER01.$DOMAIN"
    HOST_WORKER02="$WORKER02.$DOMAIN"
    HOST_WORKER03="$WORKER03.$DOMAIN"
    HOST_WORKER04="$WORKER04.$DOMAIN"
    HOST_MONITOR="$MONITOR.$DOMAIN"

    # 10.0.0.0/24 10.0.0.255
    IP_DNS="10.0.0.8"
    IP_DNS_INV="8"
    IP_MASTER="10.0.0.9"
    IP_MASTER_INV="9"
    IP_WORKER01="10.0.0.10"
    IP_WORKER01_INV="10"
    IP_WORKER02="10.0.0.11"
    IP_WORKER02_INV="11"
    IP_WORKER03="10.0.0.12"
    IP_WORKER03_INV="12"
    IP_WORKER04="10.0.0.13"
    IP_WORKER04_INV="13"
    IP_MONITOR="10.0.0.14"
    IP_MONITOR_INV="14"

    IP_INV="0.0.10"
    IP_REV="10.0.0"

    sudo mkdir -p /etc/named/zones
    sudo mkdir -p /etc/dhcp

sudo tee /etc/named.conf <<! 
options {
    listen-on port 53 { any; };
    directory   "/var/named";
    dump-file   "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };
    querylog yes;
    recursion yes;
    dnssec-enable yes;
    dnssec-validation yes;

    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";

    managed-keys-directory "/var/named/dynamic";

    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

/* 
 * custom
 */
include "/etc/named/named.conf.local";
!

sudo tee /etc/named/named.conf.local <<! 
zone "${DOMAIN}" IN {
    type master;
    file "/etc/named/zones/db.${DOMAIN}"; 
};

zone "${IP_INV}.in-addr.arpa" IN {
    type master;
    file "/etc/named/zones/db.${IP_REV}"; 
};
!

sudo tee /etc/named/zones/db.${DOMAIN} <<!
\$TTL    604800
@       IN      SOA     ${HOST_DNS}. admin.${DOMAIN}. (
             3          ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL

; name servers - NS records
    IN      NS      ${HOST_MN}.

; name servers - A records
${HOST_DNS}.   IN      A       ${IP_DNS}

; 10.0.0.0/24 - A records
${HOST_MASTER}.  IN A ${IP_MASTER}
${HOST_WORKER01}.  IN A ${IP_WORKER01}
${HOST_WORKER02}.  IN A ${IP_WORKER02}
${HOST_WORKER03}.  IN A ${IP_WORKER03}
${HOST_WORKER04}.  IN A ${IP_WORKER04}
${HOST_MONITOR}.  IN A ${IP_MONITOR}
!

sudo tee /etc/named/zones/db.${IP_REV} <<!
\$TTL 604800 ; 1 week
@ IN SOA ${HOST_DNS}. admin.${DOMAIN}. (
    3         ; Serial
    604800    ; Refresh
    86400     ; Retry
    2419200   ; Expire
    604800 )  ; Negative Cache TTL

; name servers
@    IN      NS     ${HOST_DNS}. 

; PTR Records
${IP_DNS_INV}     IN        PTR     ${HOST_DNS}. 
${IP_MASTER_INV} IN        PTR     ${HOST_MASTER}.     
${IP_WORKER01_INV} IN        PTR   ${HOST_WORKER01}.     
${IP_WORKER02_INV} IN        PTR   ${HOST_WORKER02}.     
${IP_WORKER03_INV} IN        PTR   ${HOST_WORKER03}.     
${IP_WORKER04_INV} IN        PTR   ${HOST_WORKER04}.     
${IP_MONITOR_INV} IN        PTR    ${HOST_MONITOR}.     
!

sudo tee /etc/dhcp/dhclient.conf <<!
# The custom DNS server IP
prepend domain-name-servers ${IP_DNS};
!
    echo "starting bind ..."
    sudo systemctl restart named
    sudo systemctl enable named
    sudo systemctl restart NetworkManager
    echo "done."
}

install_salt_packages() {
    sudo rpm --import \
        https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
    curl -fsSL \
        https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo
    sudo yum clean expire-cache
}

bootstrap_host() {
    echo "Testbed host $1 bootstrapping."
    install_dhclient
    case $1 in
        "master")
            echo "installing SALT MASTER"
            install_salt_packages
            sudo yum install salt-master -y --quiet
            sudo yum install salt-api -y --quiet
            sudo systemctl enable salt-master && sudo systemctl start salt-master
            sleep 10
            sudo systemctl enable salt-api && sudo systemctl start salt-api
            ;;
        "worker")
            echo "installing SALT MINION"
            install_salt_packages
            sudo yum install salt-minion -y --quiet

            sudo tee /etc/salt/minion.d/local.conf <<! 
master: master.salt.lan
id: $(hostname)
!
            sudo systemctl enable salt-minion && sudo systemctl start salt-minion
            ;;
        *)
            echo "wtf!"
            exit 1
            ;;
    esac 
}

install_dhclient() {
    sudo tee /etc/dhcp/dhclient.conf <<!
# The custom DNS server IP
prepend domain-name-servers 10.0.0.8;
!
    sudo systemctl restart NetworkManager
}

install_packages() {
    sudo yum --quiet install \
        vim \
        curl \
        tree -y 2> /dev/null
}

case $(hostname) in
  dns)
    kernel_tunning
    install_packages 
    bootstrap_dns
    ;;
  master)
    kernel_tunning
    install_packages 
    bootstrap_host master
    ;;
  minion*)
    kernel_tunning
    install_packages 
    bootstrap_host worker
    ;;
  monitor)
    kernel_tunning
    install_packages 
    ;;
  *)
    echo "wtf!"
    exit 1
    ;;
esac
