#!/bin/bash
# Zero-Trust SRE Workspace Launcher
echo "Initiating Secure SRE Workspace..."
docker run -it --rm \
  -e HOME=/home/sre \
  -e KUBECONFIG=/workspace/.kube-config \
  --mount type=bind,source="$HOME/.azure",target=/home/sre/.azure \
  --mount type=bind,source="$(pwd)",target=/workspace \
  -p 8080:8080 \
  --user $(id -u):$(id -g) \
  --workdir /workspace \
  sre-workspace:latest
