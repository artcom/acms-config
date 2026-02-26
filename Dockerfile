FROM nginx:1.29-trixie

ENV NVM_VERSION=0.40.4
ENV NODE_VERSION=24.14
ENV TCP_BROKER_URI=tcp://mqtt-broker:1883
ENV BASE_TOPIC=root

RUN apt update && apt install -y git fcgiwrap

SHELL ["/bin/bash", "--login", "-c"]

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
RUN nvm install $NODE_VERSION

RUN mkdir /srv/config
RUN mkdir /srv/tmp

RUN git init --bare /srv/config

COPY config /srv/tmp
WORKDIR /srv/tmp

RUN git init

RUN git config user.email "init@acms.com"
RUN git config user.name "docker"

RUN git remote add local file:///srv/config/
RUN git add .
RUN git commit -m "Init config repo with sample data"
RUN git push --set-upstream local master

COPY configuration-change-hook /opt/configuration-change-hook
WORKDIR /opt/configuration-change-hook
RUN npm install
RUN npm install --global

RUN mkdir -p /etc/git/hooks
RUN ln -s /root/.nvm/versions/node/$(nvm current)/bin/configuration-change-hook /etc/git/hooks/post-receive
RUN chown -R root:www-data /srv/config

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/templates /etc/nginx/templates
COPY nginx/docker-entrypoint.d/40-start-fastcgi-wrap.sh /docker-entrypoint.d/40-start-fastcgi-wrap.sh
RUN chmod +x /docker-entrypoint.d/40-start-fastcgi-wrap.sh

CMD ["nginx", "-g", "daemon off;"]
