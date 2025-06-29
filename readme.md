## Install 
This is a copy of [marzneshin-deploy](https://github.com/marzneshin/marzneshin-deploy) script for [Marzneshin Panel](https://github.com/marzneshin/marzneshin). I use it for my personal use. I use **Podman** instead of **Docker**.

### using script (full)
```sh
bash -c "$(curl -H 'Cache-Control: no-cache' -sL https://raw.githubusercontent.com/mer30hamid/marzneshin-deploy-podman/refs/heads/main/script.sh)" @ install
```
or copy script.sh to server (/root/) and run:
```sh
bash -c "$(curl -sL file://$(pwd)/script.sh)" @ install
```

or

```sh
bash -c "$(curl -sL file:///root/marzneshin/script.sh)" @ restart
```

### Only marznode
1. create this directory:
```sh
mkdir -p /etc/opt/marzneshin
```

2. copy this to /etc/opt/marzneshin/docker-compose.yml :

Note: Don't forget to add your custom certificate pathes

```yaml
services:
  marznode:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    privileged: true
    image: docker.io/dawsh/marznode:latest
    restart: always
    env_file: marznode.env
    environment:
      SERVICE_ADDRESS: "0.0.0.0"
      #INSECURE: "True"
      XRAY_EXECUTABLE_PATH: "/usr/local/bin/xray"
      XRAY_ASSETS_PATH: "/usr/local/lib/xray"
      XRAY_CONFIG_PATH: "/var/lib/marznode/xray_config.json"
      SSL_KEY_FILE: "/etc/letsencrypt/live/exampledomain.com/privkey.pem"
      SSL_CERT_FILE: "/etc/letsencrypt/live/exampledomain.com/fullchain.pem"
      SSL_CLIENT_CERT_FILE: "/var/lib/marznode/ssl_client_cert.pem"
    network_mode: host
    volumes:
      - /var/lib/marznode:/var/lib/marznode
      - /etc/letsencrypt:/etc/letsencrypt:ro
```
3. Make it Up and running:
```sh
podman-compose -f /etc/opt/marzneshin/docker-compose.yml -d up 
```
## update

### using script (full)
```sh
marzneshin update
```


### using podman
  1. pull the image
  2. stop and start the service (container)
  3. see status and history

#### marznode

```sh
podman pull docker.io/dawsh/marznode:latest
podman-compose -f /etc/opt/marzneshin/docker-compose.yml stop marznode
podman-compose -f /etc/opt/marzneshin/docker-compose.yml start marznode
podman ps
podman history docker.io/dawsh/marznode:latest
```

#### marzneshin

```sh
podman pull docker.io/dawsh/marzneshin:latest
podman-compose -f /etc/opt/marzneshin/docker-compose.yml stop marzneshin
podman-compose -f /etc/opt/marzneshin/docker-compose.yml start marzneshin
podman ps
podman history docker.io/dawsh/marzneshin:latest
```

#### db

```sh
podman pull docker.io/mariadb:latest
podman-compose -f /etc/opt/marzneshin/docker-compose.yml stop db
podman-compose -f /etc/opt/marzneshin/docker-compose.yml start db
podman ps
podman history docker.io/mariadb:latest
```

## stop, start, restart
### using script (full)
use  [marzneshin-cli](#marzneshin-cli) commands, it will apply to all services.

### using podman
  `podman-compose -f /etc/opt/marzneshin/docker-compose.yml` `<stop|start|restart>` `<container name>`
#### marznode

* stop
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml stop marznode
   ```

* start
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml start marznode
   ```

* restart
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml restart marznode
   ```

#### marzneshin

* stop
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml stop marzneshin
   ```

* start
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml start marzneshin
   ```

* restart
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml restart marzneshin
   ```

#### db

* stop
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml stop db
   ```

* start
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml start db
   ```

* restart
   ```sh
   podman-compose -f /etc/opt/marzneshin/docker-compose.yml restart db
   ```

## Auto start Services on boot

To start services automatically when your Linux system boots up

1. **Create a systemd service file**:
   Open a terminal and create a new service file in `/etc/systemd/system/`. You can name it something like `marzneshin.service`.

   ```sh
   sudo nano /etc/systemd/system/marzneshin.service
   ```

2. **Add the following content** to the service file:

   ```ini
   [Unit]
   Description=Start Marzneshin Script

   [Service]
   ExecStart=/usr/local/bin/marzneshin restart
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

3. **Save and exit** the editor (in nano, you can do this by pressing `CTRL + X`, then `Y`, and `Enter`).

4. **Enable the service** to start on boot:

   ```sh
   sudo systemctl enable marzneshin.service
   ```

5. **Start the service** immediately (optional):

   ```sh
   sudo systemctl start marzneshin.service
   ```

## Marzneshin CLI

Add user:
```sh
marzneshin cli admin create --sudo
```

See all commands:

```sh
root@myserver:~# marzneshin
Usage: /usr/local/bin/marzneshin [command]

Commands:
  up              Start services
  down            Stop services
  restart         Restart services
  status          Show status
  logs            Show logs
  cli             Marzneshin command-line interface
  install         Install Marzneshin
  update          Update latest version
  uninstall       Uninstall Marzneshin
  install-script  Install Marzneshin script
```

## Inbounds

XRAY (Generator):
 * https://azavaxhuman.github.io/MarzbanInboundGenerator/

XRAY:
 * https://gozargah.github.io/marzban/fa/docs/xray-inbounds
 * https://github.com/XTLS/Xray-examples

Hysteria2:
 * https://v2.hysteria.network/docs/advanced/Full-Server-Config/

sing-box:
 * https://github.com/chika0801/sing-box-examples

## Sub Templates

1. Edit marzneshin .env file (`vi /etc/opt/marzneshin/marzneshin.env`) and uncomment these lines:
   ```sh
   CUSTOM_TEMPLATES_DIRECTORY="/var/lib/marzneshin/templates/"
   SUBSCRIPTION_PAGE_TEMPLATE="subscription/index.html"
   ```
2. Copy your index.html here:
   ```
   /var/lib/marzneshin/templates/subscription/
   ```
3. You can find sub Templates here : 

   https://github.com/MatinDehghanian?tab=repositories

   for example:
   ```sh
   wget -N -P /var/lib/marzneshin/templates/subscription/ https://raw.githubusercontent.com/mer30hamid/marzneshin-deploy-podman/refs/heads/main/templates/MarzneshinTemplate6/index.html
   ```

4. Restart is not needed but:
   ```sh
   marzneshin restart
   ```


## Backups


1. Using this script: https://github.com/mer30hamid/s-ui-backup
   
   in /root/ folder call:
   
   ```sh
   bash <(curl -Ls https://raw.githubusercontent.com/mer30hamid/s-ui-backup/master/install.sh)
   ```
   
   it installs backup script `/usr/local/bin/backup_and_send.sh` and creates .env file in /root

2. Edit .env file:

   ```sh
   vi /root/.env
   ```
   
   use this (ommit telegram variables and use yours):
   
   ```sh
   TELEGRAM_BOT_TOKEN="1111"
   TELEGRAM_CHAT_ID="1111"
   ENABLE_NGINX_BACKUP="y"
   ENABLE_CERTBOT_BACKUP="y"
   BACKUP_LIST=("/var/lib/marzneshin/" "/var/lib/marznode/" "/etc/opt/marzneshin/")
   BACKUP_DIR="/tmp/backups/"
   PANEL_DIR="/etc/opt/marzneshin/"
   NGINX_DIR="/etc/nginx/"
   CERTBOT_DIRS=("/etc/letsencrypt/live/" "/etc/letsencrypt/renewal/" "/etc/letsencrypt/accounts/")
   EXCLUDE_FILES="/var/lib/marzneshin/mysql/*"
   BACKUP_INTERVAL="1"
   ```
   
3. DB backup:

   Copy "db-backup" to /root/ then :
   
   ```sh
   chmod +x /root/db-backup/db-backup.sh
   ```
   
   edit backup_and_send.sh:
   ```sh
   vi /usr/local/bin/backup_and_send.sh
   ```
   
   and add this to its beginning before `source ...`
   
   ```sh 
   /root/db-backup/db-backup.sh
   if [ $? -ne 0 ]; then
       echo "/root/db-backup/db-backup.sh failed"
       exit 1
   fi  
   ```

## Problems


### CGROUPSV1 

some vps using CGROUPSV1

```shell
vi /etc/containers/containers.conf
```
```ini
[engine]
cgroup_manager = "cgroupfs"
```

## Nginx

[To use with nginx](https://docs.marzneshin.org/docs/how-to-guides/behind-nginx/)

```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name  example.com;

    ssl_certificate      /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/example.com/privkey.pem;

    location ~* /(dashboard|static|locales|api|docs|redoc|openapi.json) {
        proxy_pass http://0.0.0.0:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # xray-core ws-path: /
    # client ws-path: /marzneshin/me/2087
    #
    # All traffic is proxed through port 443, and send to the xray port(2087, 2088 etc.).
    # The '/marzneshin' in location regex path can changed any characters by yourself.
    #
    # /${path}/${username}/${xray-port}
    location ~* /marzneshin/.+/(.+)$ {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$1/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

or

```
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name  marzneshin.example.com;

    ssl_certificate      /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        proxy_pass http://0.0.0.0:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Logs

marzneshin
```
podman-compose -f /etc/opt/marzneshin/docker-compose.yml logs -f marzneshin
```

marznode:
```
podman-compose -f /etc/opt/marzneshin/docker-compose.yml logs -f marznode
```

db:
```
podman-compose -f /etc/opt/marzneshin/docker-compose.yml logs -f db
```
## Documents

https://docs.marzneshin.org/

https://github.com/Gozargah/Marzban/blob/master/README-fa.md

https://gozargah.github.io/marzban/fa/docs/configuration

https://gozargah.github.io/marzban/fa/docs/host-settings
