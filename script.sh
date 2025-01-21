#!/usr/bin/env bash
set -e

APP_NAME="marzneshin"
NODE_NAME="marznode"
CONFIG_DIR="/etc/opt/$APP_NAME"
DATA_DIR="/var/lib/$APP_NAME"
NODE_DATA_DIR="/var/lib/$NODE_NAME"
COMPOSE_FILE="$CONFIG_DIR/docker-compose.yml"
USER_NAME="podman-user"

FETCH_REPO="marzneshin/marzneshin"
#SCRIPT_URL="https://github.com/$FETCH_REPO/raw/master/script.sh"

# SCRIPT_URL="file://$(pwd)/script.sh"
SCRIPT_URL="file:///root/marzneshin/script.sh"

colorized_echo() {
    local color=$1
    local text=$2

    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

check_running_as_root() {
    if [ "$(id -u)" != "0" ]; then
        colorized_echo red "This command must be run as root."
        exit 1
    fi
}

detect_os() {
    # Detect the operating system
    if [ -f /etc/lsb-release ]; then
        OS=$(lsb_release -si)
        elif [ -f /etc/os-release ]; then
        OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
        elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | awk '{print $1}')
        elif [ -f /etc/arch-release ]; then
        OS="Arch"
    else
        colorized_echo red "Unsupported operating system"
        exit 1
    fi
}

detect_and_update_package_manager() {
    colorized_echo blue "Updating package manager"
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        PKG_MANAGER="apt-get"
        $PKG_MANAGER update
        elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]]; then
        PKG_MANAGER="yum"
        $PKG_MANAGER update -y
        $PKG_MANAGER install -y epel-release
        elif [[ "$OS" == "Fedora"* ]] || [[ "$OS" == "Rocky"* ]]; then
        PKG_MANAGER="dnf"
        $PKG_MANAGER update
        elif [ "$OS" == "Arch" ]; then
        PKG_MANAGER="pacman"
        $PKG_MANAGER -Sy
    else
        colorized_echo red "Unsupported operating system"
        exit 1
    fi
}

detect_compose() {
    # Check if podman-compose command exists
    if command -v podman-compose >/dev/null 2>&1; then
        COMPOSE='/usr/local/bin/podman-compose'
        echo "Using $COMPOSE"
    elif command -v podman >/dev/null 2>&1; then
        echo "Checking if 'podman compose' is available..."
        # Run podman compose and capture the output
        output=$(podman compose --help 2>&1)
        if [ $? -eq 0 ]; then
            COMPOSE='podman compose'
            echo "Using podman compose"
        else
            echo "podman compose command is not available"
            echo "Error output: $output"
            exit 1
        fi
    else
        echo "podman or podman-compose not found"
        exit 1
    fi
}





install_package () {
    if [ -z $PKG_MANAGER ]; then
        detect_and_update_package_manager
    fi

    PACKAGE=$1
    colorized_echo blue "Installing $PACKAGE"
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        $PKG_MANAGER -y install "$PACKAGE"
        elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]]; then
        $PKG_MANAGER install -y "$PACKAGE"
        elif [[ "$OS" == "Fedora"* ]] || [[ "$OS" == "Rocky"* ]]; then
        $PKG_MANAGER install -y "$PACKAGE"
        elif [ "$OS" == "Arch" ]; then
        $PKG_MANAGER -S --noconfirm "$PACKAGE"
    else
        colorized_echo red "Unsupported operating system"
        exit 1
    fi
}

install_marzneshin_script() {
    colorized_echo blue "Installing marzneshin script"
    curl -sSL $SCRIPT_URL | install -m 755 /dev/stdin /usr/local/bin/marzneshin
    colorized_echo green "marzneshin script installed successfully"
}

install_marzneshin() {
    # Fetch releases
    MARZNESHIN_FILES_URL_PREFIX="https://raw.githubusercontent.com/marzneshin/marzneshin/master"
    MARZNODE_FILES_URL_PREFIX="https://raw.githubusercontent.com/marzneshin/marznode/master"
	COMPOSE_FILES_URL="https://raw.githubusercontent.com/marzneshin/marzneshin-deploy/master"
 	database=$1
  	nightly=$2
  
    mkdir -p "$DATA_DIR"
    mkdir -p "$CONFIG_DIR"

    colorized_echo blue "Fetching compose file"
    # curl -sL "$COMPOSE_FILES_URL/docker-compose-$database.yml" -o "$CONFIG_DIR/docker-compose.yml"
    
    cat << EOF > $CONFIG_DIR/docker-compose.yml
services:
  marzneshin:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
    privileged: true
    image: dawsh/marzneshin:latest
    restart: always
    env_file: marzneshin.env
    network_mode: host
    environment:
      # SQLALCHEMY_DATABASE_URL: "sqlite:////var/lib/marzneshin/db.sqlite3"
      SQLALCHEMY_DATABASE_URL: "mariadb+pymysql://root:12341234@localhost/marzneshin"
    volumes:
      - /var/lib/marzneshin:/var/lib/marzneshin
    depends_on:
      db:
        condition: service_healthy
        required: true
  marznode:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    privileged: true
    image: dawsh/marznode:latest
    restart: always
    env_file: marznode.env
    network_mode: host
    environment:
      SERVICE_ADDRESS: "127.0.0.1"
      INSECURE: "True"
      XRAY_EXECUTABLE_PATH: "/usr/local/bin/xray"
      XRAY_ASSETS_PATH: "/usr/local/lib/xray"
      XRAY_CONFIG_PATH: "/var/lib/marznode/xray_config.json"
      SSL_KEY_FILE: "./server.key"
      SSL_CERT_FILE: "./server.cert"
    volumes:
      - /var/lib/marznode:/var/lib/marznode
      - /var/lib/marzneshin/certs:/var/lib/marzneshin/certs
  db:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 528M
    privileged: true
    image: mariadb:latest
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: 12341234
      MARIADB_DATABASE: marzneshin
    volumes:
      - /var/lib/marzneshin/mysql:/var/lib/mysql
    ports:
      - "127.0.0.1:3306:3306"
    healthcheck:
      test: healthcheck.sh --connect
      interval: 5s
      retries: 4

EOF
    
    
    colorized_echo green "File saved in $CONFIG_DIR/docker-compose.yml"
	if [ "$nightly" = true ]; then
	    colorized_echo red "setting compose tag to nightly."
	 	sed -ri "s/(dawsh\/marzneshin:)latest/\1nightly/g" $CONFIG_DIR/docker-compose.yml
	fi
 
    colorized_echo blue "Fetching example .env file for marzneshin"
    # curl -sL "$MARZNESHIN_FILES_URL_PREFIX/.env.example" -o "$CONFIG_DIR/.env"
    cat << EOF > $CONFIG_DIR/marzneshin.env
    
UVICORN_HOST = "0.0.0.0"
UVICORN_PORT = 8000

## THE FOLLOWING TWO VARIABLES ARE NOT SUPPORTED ANYMORE, USE merzneshin cli.
# SUDO_USERNAME = "admin"
# SUDO_PASSWORD = "admin"

# DASHBOARD_PATH = "/dashboard/"

# UVICORN_UDS: "/run/marzneshin.socket"
# UVICORN_SSL_CERTFILE = "/var/lib/marzneshin/certs/example.com/fullchain.pem"
# UVICORN_SSL_KEYFILE = "/var/lib/marzneshin/certs/example.com/key.pem"


# SUBSCRIPTION_URL_PREFIX = "https://example.com"


# TELEGRAM_API_TOKEN = 123456789:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
# TELEGRAM_ADMIN_ID = 987654321, 123456789
# TELEGRAM_LOGGER_CHANNEL_ID = -1234567890123
# TELEGRAM_PROXY_URL = "http://localhost:8080"

# DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/xxxxxxx"

# CUSTOM_TEMPLATES_DIRECTORY="/var/lib/marzneshin/templates/"
# CLASH_SUBSCRIPTION_TEMPLATE="/var/lib/marzneshin/templates/clash.yml"
# SINGBOX_SUBSCRIPTION_TEMPLATE="/var/lib/marzneshin/templates/sing-box.json"
# XRAY_SUBSCRIPTION_TEMPLATE="/var/lib/marzneshin/templates/xray.json"
# SUBSCRIPTION_PAGE_TEMPLATE="subscription/index.html"
# HOME_PAGE_TEMPLATE="home/index.html"

# SQLALCHEMY_DATABASE_URL = "sqlite:///db.sqlite3"
# SQLALCHEMY_CONNECTION_POOL_SIZE = 10
# SQLALCHEMY_CONNECTION_MAX_OVERFLOW = -1

### for developers
# DOCS=true
# DEBUG=true
# WEBHOOK_ADDRESS = "http://127.0.0.1:9000/"
# WEBHOOK_SECRET = "something-very-very-secret"
# VITE_BASE_API="https://example.com/api/"
# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440
# AUTH_GENERATION_ALGORITHM=xxh128
    
EOF
    
    colorized_echo green "File saved in $CONFIG_DIR/marzneshin.env"


    colorized_echo blue "Fetching example .env file for marznode"
    # curl -sL "$MARZNODE_FILES_URL_PREFIX/.env.example" -o "$CONFIG_DIR/.env"
    cat << EOF > $CONFIG_DIR/marznode.env
    

#SERVICE_ADDRESS=0.0.0.0
#SERVICE_PORT=53042
#INSECURE=False

#XRAY_ENABLED=True
#XRAY_EXECUTABLE_PATH=/usr/bin/xray
#XRAY_ASSETS_PATH=/usr/share/xray
#XRAY_CONFIG_PATH=/etc/xray/xray_config.json
#XRAY_VLESS_REALITY_FLOW=xtls-rprx-vision
#XRAY_RESTART_ON_FAILURE=False
#XRAY_RESTART_ON_FAILURE_INTERVAL=0


HYSTERIA_ENABLED=True
HYSTERIA_EXECUTABLE_PATH=/usr/local/bin/hysteria
HYSTERIA_CONFIG_PATH=/var/lib/marznode/hysteria_config.yaml


SING_BOX_ENABLED=True
SING_BOX_EXECUTABLE_PATH=/usr/local/bin/sing-box
SING_BOX_CONFIG_PATH=/var/lib/marznode/sing-box_config.json
SING_BOX_RESTART_ON_FAILURE=False
SING_BOX_RESTART_ON_FAILURE_INTERVAL=0


SSL_KEY_FILE=/var/lib/marzneshin/certs/dev.local/dev.local.key
SSL_CERT_FILE=/var/lib/marzneshin/certs/dev.local/dev.local.crt
#SSL_CLIENT_CERT_FILE=./client.cert

#DEBUG=True
#AUTH_GENERATION_ALGORITHM=xxh128

EOF
    
    colorized_echo green "File saved in $CONFIG_DIR/marznode.env"

    colorized_echo green ".env files saved successfully"
}

# install_marznode_xray_config() {
install_marznode_configs() {
    mkdir -p "$NODE_DATA_DIR"
    curl -sL "https://raw.githubusercontent.com/marzneshin/marznode/master/xray_config.json" -o "$NODE_DATA_DIR/xray_config.json"
    colorized_echo green "Sample xray config downloaded for marznode"
    
    cat << EOF > $NODE_DATA_DIR/hysteria_config.yaml

listen: :4443
tls:
    cert: /var/lib/marzneshin/certs/dev.local/dev.local.crt
    key: /var/lib/marzneshin/certs/dev.local/dev.local.key
auth:
    type: command
    command: echo
quic:
    initStreamReceiveWindow: 8388608
    maxStreamReceiveWindow: 8388608
    initConnReceiveWindow: 20971520
    maxConnReceiveWindow: 20971520
    maxIdleTimeout: 30s
    maxIncomingStreams: 1024
    disablePathMTUDiscovery: false
bandwidth:
    up: 25 mbps
    down: 25 mbps
ignoreClientBandwidth: true
speedTest: false
disableUDP: false
udpIdleTimeout: 60s
resolver:
    type: udp
    tcp:
        addr: 8.8.8.8:53
        timeout: 4s
    udp:
        addr: 8.8.4.4:53
        timeout: 4s
    tls:
        addr: 1.1.1.1:853
        timeout: 10s
        sni: cloudflare-dns.com
        insecure: false
    https:
        addr: 1.1.1.1:443
        timeout: 10s
        sni: cloudflare-dns.com
        insecure: false
sniff:
    enable: true
    timeout: 2s
    rewriteDomain: false
    tcpPorts: 80,443,8000-9000
    udpPorts: all
# masquerade:
#     type: file
#     proxy:
#         url: https://www.mozilla.org/en-US/
#         rewriteHost: true
#     file:
#         dir: /var/www/html
#     string:
#         content: hello stupid world
#         headers:
#             content-type: text/plain
#             custom-stuff: ice cream so good
#         statusCode: 200
#     listenHTTPS: :443
#     forceHTTPS: true
outbounds:
    - name: v4_only
      type: direct
      direct:
          mode: 4
    - name: v6_only
      type: direct
      direct:
          mode: 6
    - name: socks_out
      type: socks5
      socks5:
          addr: 127.0.0.1:10140
acl:
    inline:
        - reject(geoip:ir)
        - reject(10.0.0.0/8)
        - reject(172.16.0.0/12)
        - reject(192.168.0.0/16)
        - reject(fc00::/7)
        - v4_only(all)
trafficStats:
    listen: 127.0.0.1:4399
    secret: hst2hamidpass

EOF

    colorized_echo green "Sample Hysteria2 config saved for marznode"
    
    cat << EOF > $NODE_DATA_DIR/sing-box_config.json
    
{
  "log": {
    "level": "warn"
  },
  "dns": {
    "servers": [
      {
        "tag": "dns_proxy",
        "address": "https://dohcfpages.just3tagh.ir/dns-query",
        "address_resolver": "dns_resolver",
        "strategy": "ipv4_only",
        "detour": "direct"
      },
      {
        "tag": "dns_resolver",
        "address": "8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "strategy": "prefer_ipv4"
  },
  "inbounds": [
    {
      "type": "trojan",
      "tag": "trojan",
      "listen": "127.0.0.1",
      "listen_port": 30000,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "password": "UUID"
        }
      ],
      "tls": {
        "enabled": false
      },
      "transport": {
        "path": "/UUID-tr",
        "type": "ws"
      }
    },
    {
      "type": "vless",
      "tag": "vless",
      "listen": "127.0.0.1",
      "listen_port": 20000,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "name": "abbas",
          "uuid": "UUID",
          "flow": ""
        }
      ],
      "tls": {
        "enabled": false
      },
      "transport": {
        "path": "/UUID-vl",
        "type": "ws"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess",
      "listen": "127.0.0.1",
      "listen_port": 10000,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "name": "abbas",
          "uuid": "UUID"
        }
      ],
      "tls": {
        "enabled": false
      },
      "transport": {
        "path": "/UUID-vm",
        "type": "ws"
      }
    },
    {
      "type": "trojan",
      "tag": "trojan-proxy",
      "listen": "127.0.0.1",
      "listen_port": 30002,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "password": "UUID"
        }
      ],
      "tls": {
        "enabled": false
      },
      "transport": {
        "path": "/UUID-tr/proxy",
        "type": "ws"
      }
    },
    {
      "type": "vless",
      "tag": "vless-proxy",
      "listen": "127.0.0.1",
      "listen_port": 20002,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "name": "abbas",
          "uuid": "UUID",
          "flow": ""
        }
      ],
      "tls": {
        "enabled": false
      },
      "transport": {
        "path": "/UUID-vl/proxy",
        "type": "ws"
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-proxy",
      "listen": "127.0.0.1",
      "listen_port": 10002,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "name": "abbas",
          "uuid": "UUID"
        }
      ],
      "tls": {
        "enabled": false
      },
      "transport": {
        "path": "/UUID-vm/proxy",
        "type": "ws"
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "bypass",
      "type": "direct"
    },
    {
      "tag": "block",
      "type": "block"
    },
    {
      "tag": "dns-out",
      "type": "dns"
    }
  ],
  "route": {
    "auto_detect_interface": false,
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": "geoip-ir",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-ir",
        "outbound": "direct"
      },
      {
        "domain_suffix": ".ir",
        "outbound": "direct"
      },
      {
        "inbound": [
          "vmess",
          "vless",
          "trojan"
        ],
        "outbound": "direct"
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-ir",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ir.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-ir",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ir.srs",
        "download_detour": "direct"
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "/tmp/singbox_cache.db"
    }
  }
}

EOF
    
    colorized_echo green "Sample sing-box_config.json saved for marznode"

}

uninstall_marzneshin_script() {
    if [ -f "/usr/local/bin/marzneshin" ]; then
        colorized_echo yellow "Removing marzneshin script"
        rm "/usr/local/bin/marzneshin"
    fi
}

uninstall_marzneshin() {
    if [ -d "$CONFIG_DIR" ]; then
        colorized_echo yellow "Removing directory: $CONFIG_DIR"
        rm -r "$CONFIG_DIR"
    fi
}

uninstall_marzneshin_docker_images() {
    images=$(podman images | grep marzneshin | awk '{print $3}')

    if [ -n "$images" ]; then
        colorized_echo yellow "Removing podman images of Marzneshin"
        for image in $images; do
            if podman rmi "$image" >/dev/null 2>&1; then
                colorized_echo yellow "Image $image removed"
            fi
        done
    fi
}

uninstall_marzneshin_data_files() {
    if [ -d "$DATA_DIR" ]; then
        colorized_echo yellow "Removing directory: $DATA_DIR"
        rm -r "$DATA_DIR"
    fi
}

uninstall_marznode_data_files() {
    if [ -d "$NODE_DATA_DIR" ]; then
        colorized_echo yellow "Removing directory: $NODE_DATA_DIR"
        rm -r "$NODE_DATA_DIR"
    fi
}


correct_rootless_permissions() {
    
    # Step 1: Create a dedicated user for container management
    if id "$USER_NAME" &>/dev/null; then
        echo "User '$USER_NAME' already exists."
    else
        sudo useradd -m "$USER_NAME"
        echo "User '$USER_NAME' created."
    fi
    
    # Step 2: Read the YAML file and set proper permissions for volumes
    if [[ -f "$COMPOSE_FILE" ]]; then
        echo "Reading YAML file: $COMPOSE_FILE"
        
        # Extract volume paths from the YAML file
        VOLUME_PATHS=$(grep '^\s*-\s*' "$COMPOSE_FILE" | sed 's/^\s*-\s*//;s/:.*//')
    
        for VOLUME in $VOLUME_PATHS; do
            if [[ -d "$VOLUME" ]]; then
                # Change ownership to the dedicated user
                sudo chown -R "$USER_NAME:$USER_NAME" "$VOLUME"
                echo "Changed ownership of '$VOLUME' to '$USER_NAME'."
            else
                echo "Warning: Directory '$VOLUME' does not exist."
            fi
        done
    else
        echo "Error: YAML file '$COMPOSE_FILE' does not exist."
        exit 1
    fi
}

up_marzneshin() {
    # sudo -u "$USER_NAME" $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" up -d --remove-orphans
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" up -d --remove-orphans
}

down_marzneshin() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" down
}

show_marzneshin_logs() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" logs
}

follow_marzneshin_logs() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" logs -f
}

marzneshin_cli() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" exec -e CLI_PROG_NAME="marzneshin cli" marzneshin /app/marzneshin-cli.py "$@"
}


update_marzneshin_script() {
    colorized_echo blue "Updating marzneshin script"
    curl -sSL $SCRIPT_URL | install -m 755 /dev/stdin /usr/local/bin/marzneshin
    colorized_echo green "marzneshin script updated successfully"
}

update_marzneshin() {
    $COMPOSE -f $COMPOSE_FILE -p "$APP_NAME" pull
}

is_marzneshin_installed() {
    if [ -d $CONFIG_DIR ]; then
        return 0
    else
        return 1
    fi
}


#is_marzneshin_up() {
#    # Get the container IDs
#    container_ids=$($COMPOSE -f $COMPOSE_FILE ps -q)
#
#    # Check if there are any container IDs
#    if [ -z "$container_ids" ]; then
#        return 1  # No containers found
#    fi
#
#    # Check if all containers are running
#    # for container_id in $container_ids; do
#    #     state=$(podman inspect -f '{{.State.Status}}' "$container_id")
#    #     if [ "$state" != "running" ]; then
#    #         return 1  # At least one container is not running
#    #     fi
#    # done
#
#    return 0
#}


is_marzneshin_up() {
    if [ -z "$($COMPOSE -f $COMPOSE_FILE ps -q)" ]; then
        return 1
    else
        return 0
    fi
}

install_command() {
    check_running_as_root
    # Check if marzneshin is already installed
    if is_marzneshin_installed; then
        colorized_echo red "Marzneshin is already installed at $CONFIG_DIR"
        read -p "Do you want to override the previous installation? (y/n) "
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            colorized_echo red "Aborted installation"
            exit 1
        fi
    fi
    detect_os
    if ! command -v jq >/dev/null 2>&1; then
        install_package jq
    fi
    if ! command -v curl >/dev/null 2>&1; then
        install_package curl
    fi
    # if ! command -v docker >/dev/null 2>&1; then
        #install_docker
    #fi
    if ! command -v podman >/dev/null 2>&1; then
        install_package podman 
    fi
	
    # database="sqlite"
    database="mariadb"
	nightly=false
 
	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	        -d|--database)
		 		database="$2"
				if [[ ! $database =~ ^(sqlite|mariadb|mysql)$ ]]; then
				    echo "database could only be sqlite, mysql and mariadb."
					exit 1
				fi
	            shift
	            ;;
			-n|--nightly)
	            nightly=true
	            ;;
	        *)
	            echo "Unknown option: $1"
	            exit 1
	            ;;
	    esac
	    shift
	done

    detect_compose
    install_marzneshin_script
    install_marzneshin $database $nightly
    install_marznode_configs
    
    # correct_rootless_permissions
    
    up_marzneshin
    follow_marzneshin_logs
}

uninstall_command() {
    check_running_as_root
    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin's not installed!"
        exit 1
    fi

    read -p "Do you really want to uninstall Marzneshin? (y/n) "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        colorized_echo red "Aborted"
        exit 1
    fi

    detect_compose
    if is_marzneshin_up; then
        down_marzneshin
    fi
    uninstall_marzneshin_script
    uninstall_marzneshin
    uninstall_marzneshin_docker_images

    read -p "Do you want to remove marzneshin & marznode data files too ($NODE_DATA_DIR, $DATA_DIR)? (y/n) "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        colorized_echo green "Marzneshin uninstalled successfully"
    else
        uninstall_marzneshin_data_files
	uninstall_marznode_data_files
        colorized_echo green "Marzneshin uninstalled successfully"
    fi
}

up_command() {
    help() {
        colorized_echo red "Usage: $0 up [options]"
        echo ""
        echo "OPTIONS:"
        echo "  -h, --help        display this help message"
        echo "  -n, --no-logs     do not follow logs after starting"
    }

    local no_logs=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -n|--no-logs)
                no_logs=true
            ;;
            -h|--help)
                help
                exit 0
            ;;
            *)
                echo "Error: Invalid option: $1" >&2
                help
                exit 0
            ;;
        esac
        shift
    done

    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin is not installed!"
        exit 1
    fi

    detect_compose

    if is_marzneshin_up; then
        colorized_echo red "Marzneshin is already up"
        exit 1
    fi

    up_marzneshin
    if [ "$no_logs" = false ]; then
        follow_marzneshin_logs
    fi
}

down_command() {

    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin's not installed!"
        exit 1
    fi

    detect_compose

    if ! is_marzneshin_up; then
        colorized_echo red "Marzneshin's already down"
        exit 1
    fi

    down_marzneshin
}

restart_command() {
    help() {
        colorized_echo red "Usage: $0 restart [options]"
        echo
        echo "OPTIONS:"
        echo "  -h, --help        display this help message"
        echo "  -n, --no-logs     do not follow logs after starting"
    }

    local no_logs=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -n|--no-logs)
                no_logs=true
            ;;
            -h|--help)
                help
                exit 0
            ;;
            *)
                echo "Error: Invalid option: $1" >&2
                help
                exit 0
            ;;
        esac
        shift
    done

    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin's not installed!"
        exit 1
    fi

    detect_compose

    down_marzneshin
    up_marzneshin
    if [ "$no_logs" = false ]; then
        follow_marzneshin_logs
    fi
}

status_command() {

    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        echo -n "Status: "
        colorized_echo red "Not Installed"
        exit 1
    fi

    detect_compose

    if ! is_marzneshin_up; then
        echo -n "Status: "
        colorized_echo blue "Down"
        exit 1
    fi

    echo -n "Status: "
    colorized_echo green "Up"

    # json=$($COMPOSE -f $COMPOSE_FILE ps --format=json)
    # services=$(echo "$json" | jq -r 'if type == "array" then .[] else . end | .Service')
    # states=$(echo "$json" | jq -r 'if type == "array" then .[] else . end | .State')
    # # Print out the service names and statuses
    # for i in $(seq 0 $(expr $(echo $services | wc -w) - 1)); do
    #     service=$(echo $services | cut -d' ' -f $(expr $i + 1))
    #     state=$(echo $states | cut -d' ' -f $(expr $i + 1))
    #     echo -n "- $service: "
    #     if [ "$state" == "running" ]; then
    #         colorized_echo green $state
    #     else
    #         colorized_echo red $state
    #     fi
    # done
    
    # podman ps -a --format "- {{.Names}}: {{.State}}"
    
    podman ps -a --format "{{.Names}}: {{.State}}" | grep "^$APP_NAME"

}

logs_command() {
    help() {
        colorized_echo red "Usage: marzneshin logs [options]"
        echo ""
        echo "OPTIONS:"
        echo "  -h, --help        display this help message"
        echo "  -n, --no-follow   do not show follow logs"
    }

    local no_follow=false
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -n|--no-follow)
                no_follow=true
            ;;
            -h|--help)
                help
                exit 0
            ;;
            *)
                echo "Error: Invalid option: $1" >&2
                help
                exit 0
            ;;
        esac
        shift
    done

    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin is not installed!"
        exit 1
    fi

    detect_compose

    if ! is_marzneshin_up; then
        colorized_echo red "Marzneshin is not up."
        exit 1
    fi

    if [ "$no_follow" = true ]; then
        show_marzneshin_logs
    else
        follow_marzneshin_logs
    fi
}

cli_command() {
    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin is not installed!"
        exit 1
    fi

    detect_compose

    if ! is_marzneshin_up; then
        colorized_echo red "Marzneshin is not up."
        exit 1
    fi

    marzneshin_cli "$@"
}

update_command() {
    check_running_as_root
    # Check if marzneshin is installed
    if ! is_marzneshin_installed; then
        colorized_echo red "Marzneshin is not installed!"
        exit 1
    fi

    detect_compose

    update_marzneshin_script
    colorized_echo blue "Pulling latest version"
    update_marzneshin

    colorized_echo blue "Restarting Marzneshin's services"
    down_marzneshin
    up_marzneshin

    colorized_echo blue "Marzneshin updated successfully"
}


usage() {
    colorized_echo red "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  up              Start services"
    echo "  down            Stop services"
    echo "  restart         Restart services"
    echo "  status          Show status"
    echo "  logs            Show logs"
    echo "  cli             Marzneshin command-line interface"
    echo "  install         Install Marzneshin"
    echo "  update          Update latest version"
    echo "  uninstall       Uninstall Marzneshin"
    echo "  install-script  Install Marzneshin script"
    echo
}

case "$1" in
    up)
    shift; up_command "$@";;
    down)
    shift; down_command "$@";;
    restart)
    shift; restart_command "$@";;
    status)
    shift; status_command "$@";;
    logs)
    shift; logs_command "$@";;
    cli)
    shift; cli_command "$@";;
    install)
    shift; install_command "$@";;
    update)
    shift; update_command "$@";;
    uninstall)
    shift; uninstall_command "$@";;
    install-script)
    shift; install_marzneshin_script "$@";;
    *)
    usage;;
esac