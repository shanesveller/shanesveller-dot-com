FROM debian:7

RUN apt-get update -qq && \
    apt-get -y install curl nginx-extras && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/*

RUN curl -sSL -o /tmp/hugo.deb https://github.com/spf13/hugo/releases/download/v0.14/hugo_0.14_amd64.deb && \
    dpkg -i /tmp/hugo.deb && rm /tmp/hugo.deb

RUN mkdir -p /srv/blog
COPY . /srv/blog
RUN hugo -t hugo-redlounge -s /srv/blog -d /var/www/shanesveller.com

EXPOSE 80
CMD ["nginx","-c","/srv/blog/nginx.conf"]
