# syntax=docker/dockerfile:1

# --- Builder Stage: Install Python dependencies ---
FROM python:3.11-slim AS builder
WORKDIR /build

# Mathematically guarantee the virtual environment directory exists
RUN python -m venv /build/.venv

# Securely install dependencies directly into the isolated path
COPY requirements.txt .
RUN /build/.venv/bin/pip install --upgrade pip && \
    /build/.venv/bin/pip install --no-cache-dir -r requirements.txt

# --- Final Stage: Minimal Runtime with CLIs ---
FROM debian:bookworm-slim AS base

# Install system dependencies for CLIs
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    sudo \
    git && \
    rm -rf /var/lib/apt/lists/*

# --- Install Azure CLI ---
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    az --version

# --- Install Kubernetes Tools (kubectl & kubelogin) ---
# This mathematically bakes the required execution binaries directly into the image
# necessary for OIDC authentication and cluster management.
RUN az aks install-cli --install-location /usr/local/bin/kubectl \
    --kubelogin-install-location /usr/local/bin/kubelogin

# --- Install gcloud CLI ---
ENV GCLOUD_SDK_VERSION=471.0.0
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar -xf google-cloud-cli-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz -C /opt && \
    /opt/google-cloud-sdk/install.sh --quiet && \
    rm google-cloud-cli-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz
ENV PATH="/opt/google-cloud-sdk/bin:${PATH}"

# --- Install Terraform ---
ENV TERRAFORM_VERSION=1.8.5
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip -d /usr/local/bin && \
    rm terraform.zip && \
    terraform --version

# --- Create non-root user ---
ARG USERNAME=sre
ARG USER_UID=1001
ARG USER_GID=1001
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID --create-home $USERNAME && \
    mkdir -p /workspace && \
    chown $USERNAME:$USERNAME /workspace

# --- Copy Python dependencies from builder ---
COPY --from=builder /build/.venv /home/$USERNAME/.venv
ENV PATH="/home/$USERNAME/.venv/bin:${PATH}"
ENV PYTHONPATH="/workspace"

# --- Set permissions and drop privileges ---
USER $USERNAME
WORKDIR /workspace

# --- Metadata and healthcheck ---
LABEL org.opencontainers.image.title="Zero-Trust SRE Workspace"
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD terraform --version || exit 1
ENTRYPOINT ["/bin/bash"]
