#!/bin/bash
export LC_CTYPE=C
PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
##############
echo "Enter email for Let's Encrypt sertificates"
read EMAIL
#############
echo "Enter domain"
read DOMAIN
#############
mkdir vhost
mkdir config

#Create odoo.conf
echo "[options]
#list_db = False
longpolling_port = 8072" > config/odoo.conf

echo "location ~* /web/static/ {
    proxy_cache_valid 200 60m;
    proxy_buffering on;
    expires 864000;
    proxy_pass http://$DOMAIN;
}

location /longpolling {
    proxy_pass http://odoochat.$DOMAIN;
}" > vhost/$DOMAIN

echo "version: '3'
services:

  odoo:
    image: odoo:14.0
    depends_on:
      - db
    restart: unless-stopped
    command: odoo --workers=2
    expose:
      - 8069
      - 8072
    volumes:
      # ./odoo.conf:/etc/odoo/odoo.conf
      - odoo-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo
      - VIRTUAL_HOST=$DOMAIN
      - VIRTUAL_NETWORK=default
      - VIRTUAL_PORT=8069
      - LETSENCRYPT_HOST=$DOMAIN
      - LETSENCRYPT_EMAIL=$EMAIL

  odoochat:
    image: kukharev59/odoochat:latest
    command: socat TCP-LISTEN:8072,fork TCP:odoo:8072
    environment:
      - VIRTUAL_HOST=odoochat.$DOMAIN
      - VIRTUAL_PORT=8072
    expose:
      - 8072
    networks:
      - default
    depends_on:
      - odoo
    restart: always

  db:
    image: postgres:10
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - db-data:/var/lib/postgresql/data/pgdata

  nginx:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - conf:/etc/nginx/conf.d
      - ./vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - certs:/etc/nginx/certs:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
    restart: always

  docker-gen:
    image: jwilder/docker-gen
    command: -notify-sighup nginx-proxy -watch /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
    container_name: nginx-proxy-gen
    networks:
      - default
    volumes:
      - conf:/etc/nginx/conf.d
      - ./vhost:/etc/nginx/vhost.d
      - certs:/etc/nginx/certs:ro
      - ./nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
    restart: always

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: nginx-proxy-le
    depends_on:
      - docker-gen
    networks:
      - default
    volumes:
      - ./vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - certs:/etc/nginx/certs
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - NGINX_PROXY_CONTAINER=nginx-proxy
      - NGINX_DOCKER_GEN_CONTAINER=nginx-proxy-gen
    restart: always

volumes:
  certs:
  html:
  conf:
  odoo-data:
  db-data:

networks:
  default:
    external:
      name: nginx-proxy

" > docker-compose.yml
echo "Done"
