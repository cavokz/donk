# Docker-outside-of-Docker
DooD := docker run --rm -v /var/run/docker.sock:/var/run/docker.sock

uhm:
	@echo "uhm.. yeah?"

pause:
	tail -f /dev/null

donk: Dockerfile
	-docker rmi -f donk
	docker build -t donk .
	docker image ls donk

sanity: NEST_LEVEL ?= 3
sanity:
ifneq ($(NEST_LEVEL),0)
	$(DooD) --name donk-$(NEST_LEVEL) donk make sanity NEST_LEVEL=$(shell echo $$(( $(NEST_LEVEL) - 1 )))
endif

run:
	$(DooD) -d donk make pause
