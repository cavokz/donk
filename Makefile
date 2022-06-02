all:
	@echo "uhm.. yeah?"

donk: Dockerfile
	-docker rmi -f donk
	docker build -t donk .
	docker image ls donk

sanity:
	docker run --rm donk make

run:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -d donk tail -f /dev/null
