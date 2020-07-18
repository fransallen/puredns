FROM nginx:latest

ENV DOH_VERSION 0.2.1
ENV DOH_LISTEN 0.0.0.0:8053
ENV DOH_RESOLVER 127.0.0.1:53

RUN apt update && apt install -y build-essential curl dnsutils git unbound vim
RUN apt -y upgrade

ADD config/workers/root.hints /var/lib/unbound/root.hints
ADD config/workers/unbound /etc/unbound
RUN unbound-control-setup -d /etc/unbound

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust to PATH
ENV PATH $PATH:/root/.cargo/bin

# Install DoH Proxy
RUN cargo install doh-proxy --version $DOH_VERSION --root /usr/local

# Add the config
ADD config /etc/puredns

# Setup nginx config
RUN cd /etc/nginx &&\
		rm nginx.conf && rm -r conf.d &&\
		ln -s /etc/puredns/core/nginx/nginx.conf nginx.conf &&\
		ln -s /etc/puredns/core/nginx/dhparam.pem dhparam.pem &&\
		ln -s /etc/puredns/core/nginx/conf.d conf.d &&\
    ln -s /etc/puredns/core/nginx/streams streams &&\
		ln -s /etc/puredns/core/nginx puredns &&\
    ln -s /etc/puredns/certs certs

# Create data folder
RUN cd / && mkdir /data &&\
		mkdir -p /data/puredns/cache

# Runner
CMD ["bash", "-c", "service nginx start &&\
		 /etc/init.d/unbound start &&\
     /usr/local/bin/doh-proxy --listen-address $DOH_LISTEN --server-address $DOH_RESOLVER"]
