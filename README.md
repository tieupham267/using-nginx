# using-nginx
Using nginx

NGINX can be used as an HTTP/HTTPS server, reverse proxy server, mail proxy server, load balancer, TLS terminator, or caching server. It is quite modular by design. It has native modules and third-party modules created by the community. Written in the C programming language, it's a very fast and lightweight piece of software.

NOTE: NGINX has two version streams that run in parallel - stable and mainline. Both versions can be used on a production server. It is recommended to use the mainline version in production.

Installing NGINX from source code is relatively "easy" - download the latest version of the NGINX source code, configure, build and install it.

- Lab 1: Install and using NGINX basically
- Lab 2: Compile NGINX on CentOS 7
	In this tutorial, I will use the mainline version, which is 1.13.2 at the time of writing. Update version numbers accordingly when newer versions become available.