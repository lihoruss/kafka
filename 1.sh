sudo apt-get update
sudo apt-get install -y curl gnupg lsb-release

curl -fsSL https://openresty.org/package/pubkey.gpg | sudo tee /etc/apt/trusted.gpg.d/openresty.asc

echo "deb http://openresty.org/package/debian $(lsb_release -c | awk '{print $2}') main" | sudo tee /etc/apt/sources.list.d/openresty.list
sudo apt-get install nginx-module-lua

root@37fac9c17c7b:/opt/nginx-1.22.1# ldconfig -p | grep luajit
	libluajit-5.1.so.2 (libc6,x86-64) => /usr/local/lib/libluajit-5.1.so.2
	libluajit-5.1.so (libc6,x86-64) => /usr/local/lib/libluajit-5.1.so
root@37fac9c17c7b:/opt/nginx-1.22.1# export LUAJIT_LIB=/usr/local/lib

sudo ldconfig




worker_processes 1;
events { worker_connections 1024; }

http {
    lua_package_path "/usr/local/lib/lua/?.lua;;";
    server {
        listen 8080;

        # Используем Lua для подмены доменов
        set $redirect_uri "";

        location / {
            proxy_pass https://console-openshift-console.apps.okd4bank.rtk.okdp.app.bcs;
            proxy_ssl_verify off;
            proxy_set_header Host console-openshift-console.apps.okd4bank.rtk.okdp.app.bcs;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;

            # Подмена доменов и параметров через Lua
            header_filter_by_lua_block {
                local res = ngx.arg[1]
                -- Подменяем все упоминания домена на локальный
                res = ngx.re.sub(res, "https://console-openshift-console.apps.okd4bank.rtk.okdp.app.bcs", "http://127.0.0.1:8080", "jo")
                res = ngx.re.sub(res, "https://oauth-openshift.apps.okd4bank.rtk.okdp.app.bcs", "http://127.0.0.1:8080/oauth", "jo")
                res = ngx.re.sub(res, "redirect_uri=https%3A%2F%2Fconsole-openshift-console.apps.okd4bank.rtk.okdp.app.bcs%2Fauth%2Fcallback", "redirect_uri=http%3A%2F%2F127.0.0.1%2Fauth%2Fcallback", "jo")
                ngx.arg[1] = res
            }

            # Перехватываем все запросы
            body_filter_by_lua_block {
                local res = ngx.arg[1]
                -- Подменяем все упоминания доменов в теле ответа
                res = ngx.re.sub(res, "https://console-openshift-console.apps.okd4bank.rtk.okdp.app.bcs", "http://127.0.0.1:8080", "jo")
                res = ngx.re.sub(res, "https://oauth-openshift.apps.okd4bank.rtk.okdp.app.bcs", "http://127.0.0.1:8080/oauth", "jo")
                res = ngx.re.sub(res, "redirect_uri=https%3A%2F%2Fconsole-openshift-console.apps.okd4bank.rtk.okdp.app.bcs%2Fauth%2Fcallback", "redirect_uri=http%3A%2F%2F127.0.0.1%2Fauth%2Fcallback", "jo")
                ngx.arg[1] = res
            }
        }

        # Для /oauth маршрута
        location /oauth/ {
            proxy_pass https://oauth-openshift.apps.okd4bank.rtk.okdp.app.bcs;
            proxy_ssl_verify off;
            proxy_set_header Host oauth-openshift.apps.okd4bank.rtk.okdp.app.bcs;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;
        }
    }
}
