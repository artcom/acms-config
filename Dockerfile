FROM nginx:1.29-trixie

ARG DEFAULT_BRANCH=main

ENV NVM_VERSION=0.40.4
ENV NODE_VERSION=24.14
ENV DEFAULT_BRANCH=${DEFAULT_BRANCH}
ENV TCP_BROKER_URI=null
ENV BASE_TOPIC=root

# Install dependencies
RUN apt update && apt install -y git fcgiwrap

SHELL ["/bin/bash", "--login", "-c"]

# Install nvm and node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
RUN nvm install $NODE_VERSION

# Initialize config repo
RUN mkdir /srv/config
RUN mkdir /srv/tmp

RUN git init --bare /srv/config

COPY config /srv/tmp
WORKDIR /srv/tmp

RUN git init -b ${DEFAULT_BRANCH}

RUN git config user.email "init@acms.com"
RUN git config user.name "docker"

RUN git remote add local file:///srv/config/
RUN git add .
RUN git commit -m "Init config repo with sample data"
RUN git push --set-upstream local ${DEFAULT_BRANCH}
RUN chown -R root:www-data /srv/config

# Install configuration change hook
COPY configuration-change-hook /opt/configuration-change-hook
WORKDIR /opt/configuration-change-hook
RUN npm install
RUN npm install --global

RUN mkdir -p /etc/git/hooks
RUN git config --system core.hooksPath /etc/git/hooks
RUN ln -s /root/.nvm/versions/node/$(nvm current)/bin/node /usr/local/bin/node
RUN ln -s /root/.nvm/versions/node/$(nvm current)/bin/configuration-change-hook /etc/git/hooks/post-receive

# Configure nginx
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/templates /etc/nginx/templates
COPY nginx/docker-entrypoint.d/ /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/*.sh

CMD ["nginx", "-g", "daemon off;"]

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl", "-f", "http://localhost:8080/health" ]
