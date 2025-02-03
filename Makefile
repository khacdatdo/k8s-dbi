build-mysql:
	docker buildx build --platform linux/amd64,linux/arm64 -t khacdatdo/k8s-dbi:mysql -f mysql/Dockerfile mysql

build:
	docker buildx build --platform linux/amd64,linux/arm64 -t khacdatdo/k8s-dbi:mysql -f mysql/Dockerfile mysql
