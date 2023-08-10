# VIRTUAL_HOST=www.hai-techwares.com
# hostname: www

#listen 80;
listen 443 default ssl;
#server_name www.hai-techwares.com;
server_name ...;
return 301 https://$host$request_uri;

include ./ssl/www/ssl.conf;

location / {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    proxy_pass http://$host/index.html;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Scheme $scheme;
    proxy_connect_timeout 1;
    proxy_send_timeout 30;
    proxy_read_timeout 30;
}

location /oauth {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    # route it to internal-developers
    #proxy_pass http://internal-developers:4180/oauth;
    proxy_pass http://internal-developers/oauth;
}
location /oauth2/callback {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    # route it to internal-developers
    #proxy_pass http://internal-developers:4180/oauth2-callback;
    proxy_pass http://internal-developers/oauth2-callback;
}

location /status {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    proxy_pass http://$host/status;
}

location /manga-furigana/oauth2/callback {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    proxy_pass http://$host/manga-furigana-ouath2-callback;
}

location /manga-furigana/ {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    proxy_pass http://$host/manga-furigana-default;
}
