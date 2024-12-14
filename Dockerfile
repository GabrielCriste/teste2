# Use uma imagem base apropriada
FROM jupyter/base-notebook:latest

# Atualizar pacotes e instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    nodejs \
    npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Certifique-se de usar uma versão compatível do Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Instalar o JupyterLab e suas dependências
RUN pip install --no-cache-dir --upgrade pip && \
    pip install jupyterlab

# Garantir limpeza antes do build
RUN jupyter lab clean

# Adicionar o script postBuild com permissões corretas
COPY binder/postBuild ./binder/postBuild
RUN chmod +x binder/postBuild

# Rodar o script e capturar erros, se houver
RUN ./binder/postBuild || (cat /tmp/jupyterlab-debug-*.log && exit 1)

# Build simplificado do JupyterLab
RUN jupyter lab build --dev-build=False --minimize=False || \
    (cat /tmp/jupyterlab-debug-*.log && exit 1)

# Configurar o usuário padrão
ARG NB_USER=jovyan
USER ${NB_USER}


