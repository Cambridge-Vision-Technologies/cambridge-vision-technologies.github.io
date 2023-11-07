ARG VARIANT=ubuntu-22.04
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}
RUN sudo apt-get update
RUN sudo apt-get install -y ca-certificates curl gnupg
RUN sudo mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN NODE_MAJOR=18 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
RUN sudo apt-get update
RUN sudo apt-get install nodejs -y
RUN sudo npm install -g npm@latest
ARG NPM_TOKEN
ENV NON_CONTAINER_BUILD=true
RUN git config --global core.editor "code --wait"
RUN type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
RUN sudo apt-get install git-lfs -y
RUN git lfs install
# Requirments for cypress
RUN sudo apt --fix-missing update && sudo apt-get install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb -y
ARG CONTAINER_SOURCE_MOUNT
WORKDIR ${CONTAINER_SOURCE_MOUNT}
RUN git config --global --add safe.directory /workspaces/source
RUN ln -sf /bin/bash /bin/sh
CMD [ ]