image_registry := quay.io/nordstrom
image_name := kube-deployer
image_release := 0.0.5

ifdef http_proxy
build_args := --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(http_proxy)
endif

.PHONY: tag/image push/image

build/image: build/sigil Makefile Dockerfile
	docker build -t $(image_name) $(build_args) .
	touch $@

tag/image: build/image
	docker tag $(image_name) $(image_registry)/$(image_name):$(image_release)

push/image: tag/image
	docker push $(image_registry)/$(image_name):$(image_release)

export SIGIL_VERSION=0.4.0

build/sigil: | build
	go get github.com/gliderlabs/sigil
	cd $(GOPATH)/src/github.com/gliderlabs/sigil; make deps build
	cp $(GOPATH)/src/github.com/gliderlabs/sigil/build/Linux/sigil $@

build:
	mkdir -p $@
