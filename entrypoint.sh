#!/bin/bash

ACTION="$(echo $1|tr '[A-Z]' '[a-z]')"

#DEFAULTS
CONFDIR=/CONF
GRAPHITEBASE=/var/lib/graphite
DATA=${GRAPHITEBASE}/storage/whisper
SECRET_KEY="${SECRET_KEY:="YouSh0uldChangeMe"}"

#GRAPHITE
EMAIL="${EMAIL:=admin@graphite.local}"

# COLORS
RED='\033[0;31m' # Red
BLUE='\033[0;34m' # Blue
GREEN='\033[0;32m' # Green
CYAN='\033[0;36m' # Cyan
NC='\033[0m' # No Color

ErrorMessage(){
	printf "${RED}ERROR: $* ${NC}\n"
	exit 1
}

InfoMessage(){
	printf "${CYAN}INFO: $* ${NC}\n"
}

Help(){
	printf "${GREEN}HELP:\n"

	printf "${NC}\n"
}

InitialConfiguration(){

  cp ${CONFDIR}/nginx.conf /etc/nginx/nginx.conf

  cp ${CONFDIR}/supervisord.conf /etc/supervisor/supervisord.conf

  cp ${CONFDIR}/local_settings.py ${GRAPHITEBASE}/webapp/graphite/local_settings.py

  cp ${CONFDIR}/carbon.conf ${GRAPHITEBASE}/conf/carbon.conf

  cp ${CONFDIR}/storage-schemas.conf ${GRAPHITEBASE}/conf/storage-schemas.conf

  mkdir -p ${DATA}

  touch ${GRAPHITEBASE}/storage/graphite.db ${GRAPHITEBASE}/storage/index

  chown -R www-data ${GRAPHITEBASE}/storage

  chmod 0775 ${GRAPHITEBASE}/storage ${DATA}

  chmod 0664 ${GRAPHITEBASE}/storage/graphite.db

  cd ${GRAPHITEBASE}/webapp/graphite && python manage.py syncdb --noinput

  cp ${CONFDIR}/initial_data.json ${GRAPHITEBASE}/webapp/graphite/initial_data.json

  login_date="$(date +%Y-%m-%d" "%H:%M:%S)"

  sed -i "s/__DATE__/${login_date}/g" ${GRAPHITEBASE}/webapp/graphite/initial_data.json

  sed -i "s/__EMAIL__/${EMAIL}/g" ${GRAPHITEBASE}/webapp/graphite/initial_data.json

  cd ${GRAPHITEBASE}/webapp/graphite && python manage.py loaddata initial_data.json

  cp -p ${GRAPHITEBASE}/conf/graphite.wsgi.example ${GRAPHITEBASE}/webapp/wsgi.py



  cd ${GRAPHITEBASE}/webapp/graphite && echo "INSTALLED_APPS += ('django_generate_secret_key',)" >>settings.py \
  && python manage.py generate_secret_key /tmp/secretkey.txt && SECRET_KEY=$(cat /tmp/secretkey.txt)

  sed -i "s/SECRET_KEY = 'UNSAFE_DEFAULT'/SECRET_KEY = '${SECRET_KEY}'/" ${GRAPHITEBASE}/webapp/graphite/settings.py

  #python manage.py createsuperuser --noinput --username admin --email admin@local.local

  #webapp django-admin.py migrate --settings=graphite.settings --run-syncdb
}


case ${ACTION} in

  start)

    InitialConfiguration

    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  ;;

	help)
		Help
	;;

	*)
		"$@"
	;;

esac
