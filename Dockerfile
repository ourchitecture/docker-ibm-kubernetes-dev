# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.148.1/containers/ubuntu/.devcontainer/base.Dockerfile

ARG VARIANT="focal"

FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

ARG USER_NAME="vscode"

# https://github.com/git-town/git-town/releases
ARG GIT_TOWN_VERSION="v7.4.0"
ARG GIT_TOWN_FILE="git-town_7.4.0_linux_intel_64.deb"

# https://github.com/IBM-Cloud/terraform-provider-ibm/releases/
ARG IBM_TERRAFORM_VERSION="v1.14.0"
ARG IBM_TERRAFORM_FILE="linux_amd64.zip"

WORKDIR /tmp

# update and install general packages
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-transport-https \
        gnupg2 \
        curl \
        wget \
        unzip \
    # clean up layer: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
    && rm -rf /var/lib/apt/lists/*

# install git-town
# https://www.git-town.com/install.html
RUN wget -q -O git-town.deb https://github.com/git-town/git-town/releases/download/${GIT_TOWN_VERSION}/${GIT_TOWN_FILE} \
    && dpkg -i git-town.deb \
    && rm -f git-town.deb \
    # bug: installing does not set it to executable
    && chmod +x /usr/local/bin/git-town \
    && git-town version \
    && git-town alias true

# install kubernetes
# https://kubernetes.io/docs/tasks/tools/install-kubectl/
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn apt-key add - \
    && export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE= \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
        kubectl \
    && kubectl version --client \
    # clean up layer: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
    && rm -rf /var/lib/apt/lists/*

# install helm
# https://helm.sh/docs/intro/install/
RUN curl -fsSL https://baltocdn.com/helm/signing.asc | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn apt-key add - \
    && export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE= \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
        helm \
    # clean up layer: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
    && rm -rf /var/lib/apt/lists/*

# install terraform
# https://learn.hashicorp.com/tutorials/terraform/install-cli
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn apt-key add - \
    && export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE= \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
        terraform \
    # check version
    && terraform -version \
    # enable tab completion
    && terraform -install-autocomplete \
    # clean up layer: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
    && rm -rf /var/lib/apt/lists/*

# install IBM Cloud CLI
# https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh \
    && ibmcloud plugin install container-registry \
    && ibmcloud plugin install container-service \
    && ibmcloud -v \
    # clean up layer: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
    && rm -rf /var/lib/apt/lists/*

# install IBM Cloud terraform provider
# https://cloud.ibm.com/docs/terraform?topic=terraform-getting-started#install
RUN wget -q -O terraform-provider-ibm.zip https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/${IBM_TERRAFORM_VERSION}/${IBM_TERRAFORM_FILE} \
    && unzip ./terraform-provider-ibm.zip -d ./terraform-provider-ibm \
    && rm -f ./terraform-provider-ibm.zip \
    && mkdir -p /home/${USER_NAME}/.terraform.d/plugins \
    && mv ./terraform-provider-ibm/terraform-provider-ibm* /home/${USER_NAME}/.terraform.d/plugins/

# configure git
# always sign git commits (https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/signing-commits)
RUN git config --global commit.gpgsign true \
    # even simpler alias for `git new-pull-request`
    && git config --global alias.new-pr town new-pull-request

# return to previous working directory
WORKDIR /
