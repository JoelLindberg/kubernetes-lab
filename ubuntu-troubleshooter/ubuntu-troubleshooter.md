`docker build -t ubuntu-troubleshooter .`

`docker run -it --network opensearch-net ubuntu-troubleshooter bash`


Or it's possible quickly without a Dockerfile:

1. `docker run -it --rm ubuntu bash`
2. `apt-get update && apt-get install -y curl iputils-ping wget netcat jq`
