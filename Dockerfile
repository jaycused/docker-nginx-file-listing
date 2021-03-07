FROM nginx:stable AS builder

ENV FANCY_INDEX_VERSION 0.5.1
RUN apt-get update && apt-get install -y wget build-essential libpcre3 libpcre3-dev \
  zlib1g zlib1g-dev libssl-dev && \
  wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
  wget "https://github.com/aperezdc/ngx-fancyindex/archive/v${FANCY_INDEX_VERSION}.tar.gz" -O fancyindex.tar.gz

# Reuse same cli arguments as the nginx:alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  tar -xzf nginx.tar.gz -C /usr/src && \
  tar -xzvf "fancyindex.tar.gz" && \
  FIDXDIR="$(pwd)/ngx-fancyindex-${FANCY_INDEX_VERSION}" && \
  cd /usr/src/nginx-$NGINX_VERSION && \
  ./configure --with-compat $CONFARGS --add-dynamic-module=$FIDXDIR && \
  make && make install

FROM nginx:stable

MAINTAINER Andrey Sizov, andrey.sizov@jetbrains.com
COPY --from=builder /usr/local/nginx/modules/ngx_http_fancyindex_module.so /etc/nginx/modules/ngx_fancyindex_module.so
RUN apt-get update && apt-get install -y \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /theme \
    && git clone https://github.com/lfelipe1501/Nginxy /theme \
    && chown -R 1000:1000 /theme

COPY default.conf.template /etc/nginx/conf.d/

EXPOSE 80

CMD /bin/bash -c "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf \	
			&& nginx -g 'daemon off;'"
