#!/usr/bin/env bash

# 1. Run as root or with sudo
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# 2. Make script exit if a simple command fails and
#    Make script print commands being executed
set -e -x

# 3. Set URLs to the source directories
source_pcre=https://ftp.pcre.org/pub/pcre/
source_zlib=https://zlib.net/
source_openssl=https://www.openssl.org/source/
source_nginx=https://nginx.org/download/
source_modsec=https://modsecurity.org/download.html
url_download_modsec=https://www.modsecurity.org/tarball/

# 4. Look up latest versions of each package
version_pcre=$(curl -sL ${source_pcre} | grep -Eo 'pcre\-[0-9.]+[0-9]' | sort -V | tail -n 1)
version_zlib=$(curl -sL ${source_zlib} | grep -Eo 'zlib\-[0-9.]+[0-9]' | sort -V | tail -n 1)
version_openssl=$(curl -sL ${source_openssl} | grep -Eo 'openssl\-[0-9.]+[a-z]?' | sort -V | tail -n 1)
version_nginx=$(curl -sL ${source_nginx} | grep -Eo 'nginx\-[0-9.]+[13579]\.[0-9]+' | sort -V | tail -n 1)
version_modsec=$(curl -sL ${source_modsec} | grep -Eo 'modsecurity\-[0-9.]+[0-9]' | sort -V | tail -n 1)
version_modsec_num=$(curl -sL ${source_modsec} | grep -Eo 'modsecurity\-[0-9.]+[0-9]' | sort -V | tail -n 1 | grep -Eo '[0-9.]+[0-9]')

# Set OpenPGP keys used to sign downloads
#opgp_pcre=45F68D54BBE23FB3039B46E59766E084FB0F43D8
#opgp_zlib=5ED46A6721D365587791E2AA783FCD8E58BCAFBA
#opgp_openssl=8657ABB260F056B1E5190839D9C4D26D0E604491
#opgp_nginx=B0F4253373F8F6F510D42178520A9993A1C052F8

# 5. Set where OpenSSL and NGINX will be built
bpath=$(pwd)/nginx-builder

# 6. Make a "today" variable for use in back-up filenames later
today=$(date +"%Y-%m-%d")

# 7. Clean out any files from previous runs of this script
rm -rf \
  "$bpath" \
  /etc/nginx-default
mkdir "$bpath"

# 8. Ensure the required software to compile NGINX is installed
yum -y update
yum -y install \
    epel-release \
    bash-completion \
    vim \
    wget \
    mlocate \
    ShellCheck \
    bind-utils \
    ntpdate \
    telnet
yum groupinstall -y 'Development Tools'
yum install -y \
    perl \
    perl-devel \
    perl-ExtUtils-Embed \
    libxslt \
    libxslt-devel \
    libxml2 \
    libxml2-devel \
    gd \
    gd-devel \
    GeoIP \
    GeoIP-devel \
	curl-devel \
	httpd-devel \
	pcre-devel

# 9. Download the source files
curl -L "${source_pcre}${version_pcre}.tar.gz" -o "${bpath}/pcre.tar.gz"
curl -L "${source_zlib}${version_zlib}.tar.gz" -o "${bpath}/zlib.tar.gz"
curl -L "${source_openssl}${version_openssl}.tar.gz" -o "${bpath}/openssl.tar.gz"
curl -L "${source_nginx}${version_nginx}.tar.gz" -o "${bpath}/nginx.tar.gz"
curl -L "${url_download_modsec}${version_modsec_num}/${version_modsec}.tar.gz" -o "${bpath}/modsecurity.tar.gz"

# 10. Download the signature files
curl -L "${source_pcre}${version_pcre}.tar.gz.sig" -o "${bpath}/pcre.tar.gz.sig"
curl -L "${source_zlib}${version_zlib}.tar.gz.asc" -o "${bpath}/zlib.tar.gz.asc"
curl -L "${source_openssl}${version_openssl}.tar.gz.asc" -o "${bpath}/openssl.tar.gz.asc"
curl -L "${source_nginx}${version_nginx}.tar.gz.asc" -o "${bpath}/nginx.tar.gz.asc"
curl -L "${url_download_modsec}${version_modsec_num}/${version_modsec}.tar.gz" -o "${bpath}/modsecurity.tar.gz.sha256"

# 11. Verify the integrity and authenticity of the source files through their OpenPGP signature
#cd "$bpath"
#GNUPGHOME="$(mktemp -d)"
#export GNUPGHOME
#( gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$opgp_pcre" "$opgp_zlib" "$opgp_openssl" "$opgp_nginx" \
#|| gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$opgp_pcre" "$opgp_zlib" "$opgp_openssl" "$opgp_nginx")
#gpg --batch --verify pcre.tar.gz.sig pcre.tar.gz
#gpg --batch --verify zlib.tar.gz.asc zlib.tar.gz
#gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz
#gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz

# 12. Expand the source files
cd "$bpath"
for archive in ./*.tar.gz; do
  tar xzf "$archive"
done

# 13. Clean up source files
rm -rf \
  "$GNUPGHOME" \
  "$bpath"/*.tar.*

# 14. Rename the existing /etc/nginx directory so it's saved as a back-up
if [ -d "/etc/nginx" ]; then
  mv /etc/nginx "/etc/nginx-${today}"
fi

# 15. Rename the existing /usr/sbin/nginx directory so it's saved as a back-up
if [ -e "/usr/sbin/nginx" ]; then
  mv /usr/sbin/nginx "/usr/sbin/nginx-${today}"
fi

# 16. Create NGINX cache directories if they do not already exist
if [ ! -d "/var/cache/nginx/" ]; then
  mkdir -p \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp
fi

# 17. Add NGINX group and user if they do not already exist
#id -g nginx &>/dev/null || groupadd --system nginx
getent group nginx &>/dev/null || \
groupadd --system nginx
id -u nginx &>/dev/null || \
useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" -g nginx nginx

# 18. Test to see if our version of gcc supports __SIZEOF_INT128__
if gcc -dM -E - </dev/null | grep -q __SIZEOF_INT128__
then
  ecflag="enable-ec_nistp_64_gcc_128"
else
  ecflag=""
fi

# 19. Buil modsecurity
cd "$bpath/$version_modsec"
./autogen.sh
./configure --enable-standalone-module --disable-mlogc
make
  
# 20. Build NGINX, with various modules included/excluded
cd "$bpath/$version_nginx"

./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib64/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --user=nginx \
  --group=nginx \
  --build=CentOS \
  --builddir="$version_nginx" \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_degradation_module \
  --with-http_slice_module \
  --with-http_stub_status_module \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --add-module="../$version_modsec/nginx/modsecurity" \
  --with-pcre="../$version_pcre" \
  --with-pcre-jit \
  --with-zlib="../$version_zlib" \
  --with-openssl="../$version_openssl" \
  --with-openssl-opt="no-weak-ssl-ciphers no-ssl3 no-shared $ecflag -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong" \
  --with-select_module \
  --with-poll_module \
  --with-threads \
  --with-file-aio \
  --with-mail=dynamic \
  --with-mail_ssl_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_geoip_module=dynamic \
  --with-stream_ssl_preread_module \
  --with-compat \
  --with-debug \
  --without-http_empty_gif_module \
  --without-http_geo_module \
  --without-http_split_clients_module \
  --without-http_ssi_module \
  --without-mail_imap_module \
  --without-mail_pop3_module \
  --without-mail_smtp_module

make
make install
make clean
strip -s /usr/sbin/nginx*

# 21. Create NGINX systemd service file if it does not already exist
if [ ! -e "/lib/systemd/system/nginx.service" ]; then
  # Control will enter here if the NGINX service doesn't exist.
  file="/lib/systemd/system/nginx.service"

  /bin/cat >$file <<'EOF'
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
fi

# 22. Symlink /usr/lib64/nginx/modules to /etc/nginx/modules directory,
#     so that you can load dynamic modules in nginx configuration like this
#     load_module modules/ngx_foo_module.so;
ln -s /usr/lib64/nginx/modules /etc/nginx/modules

# 23. Copy NGINX manual page to /usr/share/man/man8:
sudo cp "$bpath"/"$version_nginx"/man/nginx.8 /usr/share/man/man8
sudo gzip -f /usr/share/man/man8/nginx.8

# 24. Remove archaic files from the /etc/nginx directory:
rm /etc/nginx/koi-utf /etc/nginx/koi-win /etc/nginx/win-utf

# 25. Configure vim for highlighting of NGINX configuration
#     Rename the existing /etc/nginx directory so it's saved as a back-up
if [ -d "$HOME/.vim/" ]; then
  echo "$HOME/.vim folder exist!"
  cp -r "$bpath"/"$version_nginx"/contrib/vim/* "$HOME"/.vim/
else
  mkdir ~/.vim/
  cp -r "$bpath"/"$version_nginx"/contrib/vim/* "$HOME"/.vim/
fi

echo "All done.";
echo "Start with sudo systemctl start nginx"
echo "or with sudo nginx"
