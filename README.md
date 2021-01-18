# kick-start-odoo
Kick-start Odoo with SSL certificate from Let's Encrypt and odoochat (Long Polling)

Preparation
 - install Docker
 - install Docker-compose
 - Define a server name using a subdomain or domain you own, for example odoo.example.com or example.com.
 - Make sure the domain DNS records point to your VPS's IP address.


Create docker-network

    docker network create nginx-proxy

Сlone this repository

    git clone https://github.com/kukharev/kick-start-odoo.git

Let's make the script executable

    chmod +x kick-start-odoo.sh

Run the script and enter the email (messages from Let's Encrypt will be sent to it) and the domain

    ./kick-start-odoo.sh

Run docker-compose

    docker-compose up -d

We are waiting for the download of docker images and go to our domain. Create a base and log in.

Attention! after creating the database, we deny access to the database manager in the config/odoo.conf file, set the value:

    list_db = False


links:

 - https://github.com/nginx-proxy/nginx-proxy
