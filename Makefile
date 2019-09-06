LOCAL_PRIVATE_REPO=127.0.0.1:5000
VERSION=0.4.1-SNAPSHOT
GO111MODULE=off
ARCH ?= (shell uname -m)
# Image URL to use all building/pushing image targets
IMG ?= seldonio/seldon-core-operator:${VERSION}

all: test manager

# Run tests
test: generate fmt vet manifests
	go test ./pkg/... ./cmd/... -coverprofile cover.out

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager github.com/seldonio/seldon-operator/cmd/manager

# Run against the configured Kubernetes cluster in ~/.kube/config
run: generate fmt vet
	go run ./cmd/manager/main.go

# Install CRDs into a cluster
install: manifests
	kubectl apply -f config/crds

uninstall: manifests
	kubectl delete -f config/crds

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: manifests
	#kubectl apply -f config/crds
	kustomize build config/default | kubectl apply -f -

undeploy: manifests
	kustomize build config/default | kubectl delete -f -
	#kubectl delete -f config/crds

# Generate manifests e.g. CRD, RBAC etc.
manifests:
	go run vendor/sigs.k8s.io/controller-tools/cmd/controller-gen/main.go all

# Run go fmt against code
fmt:
	go fmt ./pkg/... ./cmd/...

# Run go vet against code
vet:
	go vet ./pkg/... ./cmd/...

# Generate code
generate:
ifndef GOPATH
	$(error GOPATH not defined, please define GOPATH. Run "go help gopath" to learn more about GOPATH)
endif
	go generate ./pkg/... ./cmd/...

# Build the docker image
docker-build:
	docker build --build-arg ARCH=${ARCH} . -t ${IMG}
	@echo "updating kustomize image patch file for manager resource"
	sed -i'' -e 's@image: .*@image: '"${IMG}"'@' ./config/default/manager_image_patch.yaml

# Push the docker image
docker-push:
	docker push ${IMG}

docker-push-local-private:
	docker tag $(IMG) $(LOCAL_PRIVATE_REPO)/$(IMG)
	docker push $(LOCAL_PRIVATE_REPO)/$(IMG)
