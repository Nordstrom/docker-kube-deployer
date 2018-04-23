IMAGE_NAME := kube-deployer
IMAGE_REGISTRY := quay.io/nordstrom
IMAGE_TAG := 3.2

.PHONY: push/image
push/image: tag/image
	docker push $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: tag/image
tag/image: build/image
	docker tag $(IMAGE_NAME) $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: build/image
build/image: Dockerfile | build
	docker build -t $(IMAGE_NAME) $(BUILD_ARGS) .

build:
	mkdir -p $@

.PHONY: clean/built_image
clean/built_image:
	-docker rmi $(IMAGE_NAME)

.PHONY: clean
clean: clean/built_image
	rm -rf build
