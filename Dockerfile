FROM nginx:1.19.8

RUN apt-get update && apt-get install -y git && apt-get install -y fcgiwrap

RUN mkdir /srv/content
RUN mkdir /srv/tmp

RUN git init --bare /srv/content

COPY content /srv/tmp
WORKDIR /srv/tmp

RUN git init

RUN git config user.email "init@acms.com"
RUN git config user.name "docker"

RUN git remote add local file:///srv/content/
RUN git add .
RUN git commit -m "Init content repo with sample data"
RUN git push --set-upstream local master

RUN chown -R www-data:www-data /srv/content

RUN rm /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/nginx.conf

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/git-http-backend.conf /etc/nginx/conf.d/git-http-backend.conf

CMD /etc/init.d/fcgiwrap start && nginx -g daemon\ off\;
