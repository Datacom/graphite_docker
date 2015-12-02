FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y install curl &&\
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ trusty universe' >> /etc/apt/sources.list &&\
    curl -sL https://deb.nodesource.com/setup_4.x | bash

ENV GRAPHITE_VERSION 0.9.15
ENV GRAFANA_VERSION 2.1.3

RUN apt-get -y install      \
  python-django-tagging     \
  python-simplejson         \
  python-memcache           \
  python-ldap               \
  python-cairo              \
  python-django             \
  python-twisted            \
  python-pysqlite2          \
  python-support            \
  python-pip                \
  gunicorn                  \
  supervisor                \ 
  nginx-light               \
  nodejs                    \
  git                       \
  wget                      

# Install statsd
RUN	mkdir /src && git clone https://github.com/etsy/statsd.git /src/statsd



# Install required packages
RUN	pip install whisper pytz
RUN	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
RUN	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web==$GRAPHITE_VERSION

# grafana
RUN     cd ~ &&\
	wget https://grafanarel.s3.amazonaws.com/builds/grafana_2.1.3_amd64.deb &&\
        dpkg -i grafana_2.1.3_amd64.deb && rm grafana_2.1.3_amd64.deb

# statsd
ADD	./statsd/config.js /src/statsd/config.js

# ADD graphite config
ADD	./graphite/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
ADD	./graphite/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
ADD	./graphite/carbon.conf /var/lib/graphite/conf/carbon.conf
ADD	./graphite/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
ADD	./graphite/storage-aggregation.conf /var/lib/graphite/conf/storage-aggregation.conf

ADD     ./grafana/config.ini /etc/grafana/config.ini

# ADD system service config
ADD	./nginx/nginx.conf /etc/nginx/nginx.conf
ADD	./supervisord.conf /etc/supervisor/conf.d/supervisord.conf




# Nginx
#
# graphite
EXPOSE	80
# grafana
EXPOSE  3000

# Carbon line receiver port
EXPOSE	2003
# Carbon pickle receiver port
EXPOSE	2004
# Carbon cache query port
EXPOSE	7002

# Statsd UDP port
EXPOSE	8125/udp
# Statsd Management port
EXPOSE	8126

ADD ./bin/init /usr/bin/init

CMD /usr/bin/init

