FROM    ubuntu:16.04

RUN apt-get -y update \
&& apt-get install --no-install-recommends -qq --no-install-recommends --no-install-suggests -qq python-ldap python-cairo \
python-django python-twisted python-django-tagging python-simplejson python-memcache \
python-pysqlite2 python-tz python-pip gunicorn supervisor nginx-light pwgen
#python-support

ENV CONF=/CONF \
APP=/var/lib/graphite \
DATA=${APP}/storage/whisper

RUN pip install --upgrade pip && pip install whisper==0.9.15 \
&& pip install --install-option="--prefix=${APP}" --install-option="--install-lib=${APP}/lib" carbon==0.9.15 \
&& pip install --install-option="--prefix=${APP}" --install-option="--install-lib=${APP}/webapp" graphite-web==0.9.15 \
&& pip install django-generate-secret-key


COPY conf/ /CONF

EXPOSE  2003 2003/udp

EXPOSE  2004

EXPOSE  7002

EXPOSE  80

COPY entrypoint.sh /entrypoint.sh

VOLUME ["${DATA}"]

ENTRYPOINT ["/entrypoint.sh"]

CMD ["help"]
