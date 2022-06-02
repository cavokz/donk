# Docker-outside-of-Docker
DooD := docker run --rm -v /var/run/docker.sock:/var/run/docker.sock

all:
	@echo "uhm.. yeah?"

donk: Dockerfile
	-docker rmi -f donk
	docker build -t donk .
	docker image ls donk

sanity: NEST_LEVEL ?= 3
sanity:
ifneq ($(NEST_LEVEL),0)
	$(DooD) donk make sanity NEST_LEVEL=$(shell echo $$(( $(NEST_LEVEL) - 1 )))
else
	$(DooD) donk make
endif

run:
	$(DooD) -d donk tail -f /dev/null
