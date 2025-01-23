This is my copy of [Marzneshin script](https://github.com/marzneshin/marzneshin) for personal use.

## Install script
```bash
bash -c "$(curl -H 'Cache-Control: no-cache' -sL https://raw.githubusercontent.com/mer30hamid/marzneshin-deploy-podman/refs/heads/main/script.sh)" @ install
```
or copy script.sh to server (/root/) and run:
```bash
bash -c "$(curl -sL file://$(pwd)/script.sh)" @ install
```

or

```bash
bash -c "$(curl -sL file:///root/marzneshin/script.sh)" @ restart
```

## Install Service

To start a script automatically when your Linux system boots up

1. **Create a systemd service file**:
   Open a terminal and create a new service file in `/etc/systemd/system/`. You can name it something like `marzneshin.service`.

   ```bash
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

   ```bash
   sudo systemctl enable marzneshin.service
   ```

5. **Start the service** immediately (optional):

   ```bash
   sudo systemctl start marzneshin.service
   ```

## Marzneshin CLI

```bash
marzneshin cli admin create --sudo
```

## Inbounds:

Generator:
https://azavaxhuman.github.io/MarzbanInboundGenerator/

Examples:
https://gozargah.github.io/marzban/fa/docs/xray-inbounds


## Sub Templates

1. Edit marzneshin .env file (`vi /etc/opt/marzneshin/marzneshin.env`) and uncomment these lines:
   ```bash
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
   ```bash
   wget -N -P /var/lib/marzneshin/templates/subscription/ https://raw.githubusercontent.com/mer30hamid/marzneshin-deploy-podman/refs/heads/main/templates/MarzneshinTemplate6/index.html
   ```

4. Restart is not needed but:
   ```bash
   marzneshin restart
   ```


## Backups

1. Copy "db-backup" to /root/
2. Using this script: https://github.com/mer30hamid/s-ui-backup
   
   in /root/ folder call:
   
   ```bash
   bash <(curl -Ls https://raw.githubusercontent.com/mer30hamid/s-ui-backup/master/install.sh)
   ```
   
   it installs backup script `/usr/local/bin/backup_and_send.sh` and creates .env file in /root

3. Edit .env file:

   ```bash
   vi /root/.env
   ```
   
   use this (ommit telegram variables and use yours):
   
   ```bash
   TELEGRAM_BOT_TOKEN="1111"
   TELEGRAM_CHAT_ID="1111"
   ENABLE_NGINX_BACKUP="y"
   ENABLE_CERTBOT_BACKUP="y"
   BACKUP_LIST="/var/lib/marzneshin/ /var/lib/marznode/"
   BACKUP_DIR="/tmp/backups/"
   PANEL_DIR="/usr/local/s-ui/"
   NGINX_DIR="/etc/nginx/"
   CERTBOT_DIRS="/etc/letsencrypt/live/ /etc/letsencrypt/renewal/ /etc/letsencrypt/accounts/"
   EXCLUDE_FILES="/var/lib/marzneshin/mysql/*"
   BACKUP_INTERVAL="1"
   ```
   
4. Edit backup script:
   
   ```bash
   vi /usr/local/bin/backup_and_send.sh
   ```
   
   and add this to its beginning before `source ...`
   
   ```bash 
   /root/db-backup/db-backup.sh
   if [ $? -ne 0 ]; then
       echo "/root/db-backup/db-backup.sh failed"
       exit 1
   fi  
   ```

## Problems

### CGROUPSV1 

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

## Documents

https://docs.marzneshin.org/

https://github.com/Gozargah/Marzban/blob/master/README-fa.md

https://gozargah.github.io/marzban/fa/docs/configuration

https://gozargah.github.io/marzban/fa/docs/host-settings
