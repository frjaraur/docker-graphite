build:
	docker rm -fv graphite || true
	docker build -t frjaraur/graphite .
start:
	 docker run -ti --rm --net=collectd -p 8080:80 \
	 --name graphite \
	 --network-alias=cserver \
	 -v /etc/localtime:/etc/localtime:ro \
	 -v /etc/timezone:/etc/timezone:ro \
	frjaraur/graphite start

push:
	docker push frjaraur/graphite
