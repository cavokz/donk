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

kind-up:
	kind create cluster
	kind load docker-image donk
	kubectl wait node kind-control-plane --for condition=Ready --timeout=30s
	kubectl get nodes
	kubectl run donk-sleep --image=donk --image-pull-policy=Never -- sleep 5
	kubectl run donk-pause --image=donk --image-pull-policy=Never -- make pause
	kubectl get pods

kind-down:
	kind delete cluster

kind-sanity:
	$(DooD) donk make kind-up kind-down
