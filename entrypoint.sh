#!/bin/bash

ACTION="$(echo $1|tr '[A-Z]' '[a-z]')"

#DEFAULTS
CONFDIR=/CONF
APP=/var/lib/graphite
DATA=${APP}/storage/whisper
#SECRET_KEY="${SECRET_KEY}" #Left for using defaults if needed

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
  printf "${GREEN}\tVARIABLES:\n"
  printf "\t${RED}APPDIR${GREEN} --> Graphite Base Location (defaults to /var/lib/graphite)\n"
  printf "\t${RED}DATA${GREEN} --> Graphite Whisper Data Location (defaults to /var/lib/graphite/storage/whisper)\n"
  printf "\t${RED}SECRET_KEY${GREEN} --> Secret key used for hashing django applications (defaults to random generated using 'pwgen' application)\n"
  printf "\t${GREEN}This should be a volume for data persistence\n"
  printf "${GREEN}PORTS to Publish:\n"
  printf "\t${RED}80${GREEN} --> Graphite Web Interface using Nginx\n"
  printf "\t${RED}2003 (tcp/udp)${GREEN} --> Carbon Cache\n"
  printf "\t${RED}2004${GREEN} --> Carbon Cache\n"
  printf "\t${RED}7002${GREEN} --> Carbon Cache-Query\n"
  printf "${GREEN}Usage:\n"
  printf "\t${GREEN}Getting Help --> docker run --rm frjaraur/graphite help\n"
  printf "\t${GREEN}Getting Started --> docker run -d --name graphite -p 8000:80 -p 2003:2003 -p 2003:2003/udp -p 2004:2004 -p 7002:7002 frjaraur/graphite start\n"
	printf "${NC}\n"
}

InitialConfiguration(){

  InfoMessage "Setting Initial Configuration using following values:"

  InfoMessage "APPDIR: ${APP}"

  InfoMessage "WEBAPP: ${APP}/webapp"

  InfoMessage "CONFDIR: ${CONFDIR}"

  InfoMessage "WHISPER STORAGE: ${DATA}"

  cp ${CONFDIR}/nginx.conf /etc/nginx/nginx.conf

  #cp ${CONFDIR}/supervisord.conf /etc/supervisor/supervisord.conf

  sed -e "s|__APP__|${APP}|g" ${CONFDIR}/supervisord.conf > /etc/supervisor/supervisord.conf

  cp ${CONFDIR}/local_settings.py ${APP}/webapp/graphite/local_settings.py

  cp ${CONFDIR}/carbon.conf ${APP}/conf/carbon.conf

  cp ${CONFDIR}/storage-schemas.conf ${APP}/conf/storage-schemas.conf

  mkdir -p ${DATA}

  touch ${APP}/storage/graphite.db ${APP}/storage/index

  chown -R www-data ${APP}/storage

  chmod 0775 ${APP}/storage ${DATA}

  chmod 0664 ${APP}/storage/graphite.db

  if [ ! -n "${SECRET_KEY}" ]
  then
    #cd ${APP}/webapp/graphite && echo "INSTALLED_APPS += ('django_generate_secret_key',)" >>settings.py \
    #&& python manage.py generate_secret_key /tmp/secretkey.txt && SECRET_KEY=$(cat /tmp/secretkey.txt)

    SECRET_KEY="$(pwgen 50 1)"

    sed -i "s/^SECRET_KEY = .*/SECRET_KEY = '${SECRET_KEY}'/" ${APP}/webapp/graphite/settings.py

    #awk -v hash="${SECRET_KEY}" '$1~/^SECRET_KEY/{$0="SECRET_KEY=" hash } 1' ${APP}/webapp/graphite/settings.py >  ${APP}/webapp/graphite/settings.py.



    #mv ${APP}/webapp/graphite/settings.py. ${APP}/webapp/graphite/settings.py

    InfoMessage "SECRET_KEY Changed using a auto generated 50 characters key using pwgen (if you wan to use your own SECRET_KEY, use environment variable)."
  fi

  cd ${APP}/webapp/graphite && python manage.py syncdb --noinput

  cp ${CONFDIR}/initial_data.json ${APP}/webapp/graphite/initial_data.json

  login_date="$(date +%Y-%m-%d" "%H:%M:%S)"

  sed -i "s/__DATE__/${login_date}/g" ${APP}/webapp/graphite/initial_data.json

  sed -i "s/__EMAIL__/${EMAIL}/g" ${APP}/webapp/graphite/initial_data.json

  cd ${APP}/webapp/graphite && python manage.py loaddata initial_data.json

  cp -p ${APP}/conf/graphite.wsgi.example ${APP}/webapp/wsgi.py





  #python manage.py createsuperuser --noinput --username admin --email admin@local.local

  #webapp django-admin.py migrate --settings=graphite.settings --run-syncdb
}


case ${ACTION} in

  start)

    InitialConfiguration

    InfoMessage "Starting Daemons using Supervisord"

    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  ;;

	help)
		Help
	;;

	*)
		"$@"
	;;

esac
