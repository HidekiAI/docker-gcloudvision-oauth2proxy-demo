#VIRTUAL_HOST=internal-developers.hai-techwares.com
# hostname: internal-developers

# Most of the configuration is from https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/ "Nginx auth_request" section

# nginx-proxy will port-forward to ports defined in "proxy_pass"
# assumes that the hostname is "oauth2-proxy"
#listen 80;
listen 443 ssl;
#server_name internal-developers.hai-techwares.com;
server_name ...;

include ./ssl/internal-developers/ssl.conf;

#resolver    

location /oauth2/ {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    proxy_pass       http://$host:4180;
    proxy_set_header Host                    $host;
    proxy_set_header X-Real-IP               $remote_addr;
    proxy_set_header X-Scheme                $scheme;
    proxy_set_header X-Auth-Request-Redirect $request_uri;
    # or, if you are handling multiple domains:
    # proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
}
location = /oauth2/auth {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    proxy_pass       http://$host:4180;
    proxy_set_header Host             $host;
    proxy_set_header X-Real-IP        $remote_addr;
    proxy_set_header X-Scheme         $scheme;
    # nginx auth_request includes headers but not body
    proxy_set_header Content-Length   "";
    proxy_pass_request_body           off;
}

# redirect callback
location /oauth2/callback {
    # Google cloud oauth2 client should now have packaged up
    # the access token in the response body, in which it is then
    # stored in the X-Auth-Request-Access-Token header by 
    # the oauth2-proxy, which is then passed to the backend
    # application by nginx using the proxy_set_header directive.
    # the backend application can then use the access Token 
    # to make requests to the Google Cloud Vision API 
    proxy_pass       http://my-rust-app:6666/;
}

location / {
    #internal;   # only allow internal redirects
    #allow 10.86.86.0/24;    # allow only this subnet
    #deny all;   # deny everyone else

    auth_request /oauth2/auth;
    error_page 401 = /oauth2/sign_in;

    # pass information via X-User and X-Email headers to backend,
    # requires running with --set-xauthrequest flag
    auth_request_set $user   $upstream_http_x_auth_request_user;
    auth_request_set $email  $upstream_http_x_auth_request_email;
    proxy_set_header X-User  $user;
    proxy_set_header X-Email $email;

    # if you enabled --pass-access-token, this will pass the token to the backend
    auth_request_set $token  $upstream_http_x_auth_request_access_token;
    proxy_set_header X-Access-Token $token;

    # if you enabled --cookie-refresh, this is needed for it to work with auth_request
    auth_request_set $auth_cookie $upstream_http_set_cookie;
    add_header Set-Cookie $auth_cookie;

    # When using the --set-authorization-header flag, some provider's cookies can exceed the 4kb
    # limit and so the OAuth2 Proxy splits these into multiple parts.
    # Nginx normally only copies the first `Set-Cookie` header from the auth_request to the response,
    # so if your cookies are larger than 4kb, you will need to extract additional cookies manually.
    auth_request_set $auth_cookie_name_upstream_1 $upstream_cookie_auth_cookie_name_1;

    # Extract the Cookie attributes from the first Set-Cookie header and append them
    # to the second part ($upstream_cookie_* variables only contain the raw cookie content)
    if ($auth_cookie ~* "(; .*)") {
        set $auth_cookie_name_0 $auth_cookie;
        set $auth_cookie_name_1 "auth_cookie_name_1=$auth_cookie_name_upstream_1$1";
    }

    # Send both Set-Cookie headers now if there was a second part
    if ($auth_cookie_name_upstream_1) {
        add_header Set-Cookie $auth_cookie_name_0;
        add_header Set-Cookie $auth_cookie_name_1;
    }

    proxy_pass http://backend/;
    # or "root /path/to/site;" or "fastcgi_pass ..." etc
}

## http://internal-developers.hai-techwares.com/ and https://internal-developers.hai-techwares.com/ should just port forward from port 80/443 to 4180
## note that "proxy_pass" with "http://" will forward both http and https
#location /oauth {
#    proxy_pass http://oauth2-proxy:4180/oauth;
#}

#location /manga-furigana/oauth2/callback {
#    proxy_pass http://oauth2-proxy:4180/manga-furigana-ouath2-callback;
#}
#location /manga-furigana/ {
#    proxy_pass http://oauth2-proxy:4180/manga-furigana-default;
#}

#location /oauth2/callback {
#    proxy_pass http://oauth2-proxy:4180/oauth2-callback;
#}

#location / {
#    proxy_pass http://oauth2-proxy:4180/internal-developers-default;
#}