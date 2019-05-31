# Compile
## TODO
- Scripting
## Requirements for building NGINX from source
Mandatory requirements:

- OpenSSL library version between 1.0.2 - 1.1.0
- zlib library version between 1.1.3 - 1.2.11
- PCRE library version between 4.4 - 8.40
- GCC Compiler
- Optional requirements:

PERL:

- libatomic_ops
- LibGD
- MaxMind GeoIP
- libxml2
- libxslt

## Install Nginx
REF: [https://www.vultr.com/docs/how-to-compile-nginx-from-source-on-centos-7](https://www.vultr.com/docs/how-to-compile-nginx-from-source-on-centos-7)

### Install necessary package
```
yum groupinstall -y 'Development Tools'
yum install -y perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel GeoIP GeoIP-devel
yum install -y wget
yum install -y vim
```

### 1. Download source (Just get stable version)
Download nginx and extract

```
wget https://nginx.org/download/nginx-1.16.0.tar.gz
tar zxvf nginx-1.16.0.tar.gz
```

Download openssl and extract
```
wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
tar zxvf openssl-1.1.1b.tar.gz
```

Download pcre and extract
```
wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
tar zxvf pcre-8.43.tar.gz
```

Downloaod zlin and extract
```
wget https://www.zlib.net/zlib-1.2.11.tar.gz
tar zxvf zlib-1.2.11.tar.gz
```

### 2. Create the NGINX system user and group
```
useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" --user-group nginx
```

### 3. Create cache folder
```
mkdir -p /var/cache/nginx && sudo nginx -t
```

### 4. Configure
Go to NGINX source directory
```
cd ~/nginx-1.16.0
```

```
./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib64/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=CentOS \
            --builddir=nginx-1.16.0 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.43 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1b \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug
```

```
make
make install
```

Symlink /usr/lib64/nginx/modules to /etc/nginx/modules directory,
so that you can load dynamic modules in nginx configuration like this 
load_module modules/ngx_foo_module.so;
`ln -s /usr/lib64/nginx/modules /etc/nginx/modules`

Copy NGINX manual page to /usr/share/man/man8:
`sudo cp ~/nginx-1.13.2/man/nginx.8 /usr/share/man/man8`
`sudo gzip /usr/share/man/man8/nginx.8`

Check that Man page for NGINX is working
`man nginx`

Print the NGINX version, compiler version, and configure script parameters:
`nginx -V`

```
nginx version: nginx/1.13.2 (CentOS)
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-11) (GCC)
built with OpenSSL 1.1.0f  25 May 2017
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx . . .
. . .
. . .
```


### Check syntax and potential errors:
```
nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Create a systemd unit file for nginx:
```
vim /usr/lib/systemd/system/nginx.service
```

```


[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
```
### Start NGINX service
Run and check status of NGINX service
```
systemctl start nginx.service
systemctl status nginx.service
ps aux | grep nginx
ss -nao | grep :80
curl -I 127.0.0.1
```
###  Enable NGINX service
Enable and check  to ensure NGINX service is enabled

```
systemctl enable nginx.service
systemctl is-enabled nginx.service
```
### Reboot your VPS to verify that NGINX starts up automatically:
```
sudo shutdown -r now
```

### Remove archaic files from the /etc/nginx directory:
```
sudo rm /etc/nginx/koi-utf /etc/nginx/koi-win /etc/nginx/win-utf
```

### Configure vim for highlighting of NGINX configuration
Place syntax highlighting of NGINX configuration for vim into ~/.vim/.
You will get nice syntax highlighting when editing NGINX configuration file:
```
mkdir ~/.vim/
cp -r ~/nginx-1.16.0/contrib/vim/* ~/.vim/
```

### Remove all .default backup files from /etc/nginx/:
```
sudo rm /etc/nginx/*.default
```