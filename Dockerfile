# Use uma imagem base apropriada
FROM jupyter/base-notebook:latest

# Atualizar pacotes e instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    nodejs \
    npm \
    python3-dev \
    libc6-dev \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Certifique-se de usar uma versão compatível do Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Instalar o JupyterLab e suas dependências
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --upgrade jupyterlab

# Garantir limpeza antes do build
RUN jupyter lab clean

# Adicionar o script postBuild com permissões corretas
COPY binder/postBuild ./binder/postBuild
RUN chmod +x /home/jovyan/binder/postBuild

# Rodar o script postBuild e capturar erros, se houver
RUN ./binder/postBuild || (cat /tmp/jupyterlab-debug-*.log && exit 1)

# Construir o JupyterLab com detalhes de erro
RUN jupyter lab build --debug --dev-build=False --minimize=False || \
    (cat /tmp/jupyterlab-debug-*.log && exit 1)

# Configurar o usuário padrão
ARG NB_USER=jovyan
USER ${NB_USER}
