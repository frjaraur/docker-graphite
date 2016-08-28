FROM    ubuntu:16.04

RUN apt-get -y update \
&& apt-get install --no-install-recommends -qq --no-install-recommends --no-install-suggests -qq python-ldap python-cairo \
python-django python-twisted python-django-tagging python-simplejson python-memcache \
python-pysqlite2 python-tz python-pip gunicorn supervisor nginx-light
#python-support
RUN pip install --upgrade pip && pip install whisper==0.9.15 \
&& pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon==0.9.15 \
&& pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web==0.9.15 \
&& pip install django-generate-secret-key

ENV CONF=/CONF DATA=/var/lib/graphite/storage/whisper

COPY conf/ /CONF

EXPOSE  2003 2003/udp

EXPOSE  2004

EXPOSE  7002

EXPOSE  80

COPY entrypoint.sh /entrypoint.sh

VOLUME ["${DATA}"]

ENTRYPOINT ["/entrypoint.sh"]

CMD ["help"]
