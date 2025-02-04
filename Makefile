build-mysql:
	docker buildx build --platform linux/amd64,linux/arm64 -t khacdatdo/k8s-dbi:mysql -f mysql/Dockerfile mysql

build-postgres:
	docker buildx build --platform linux/amd64,linux/arm64 -t khacdatdo/k8s-dbi:postgres -f postgres/Dockerfile postgres

build:
	docker buildx build --platform linux/amd64,linux/arm64 -t khacdatdo/k8s-dbi:mysql -f mysql/Dockerfile mysql
	docker buildx build --platform linux/amd64,linux/arm64 -t khacdatdo/k8s-dbi:postgres -f postgres/Dockerfile postgres
