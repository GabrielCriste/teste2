# Use a imagem base do Almond
FROM almondsh/almond:latest

# Trocar para o usuário root para instalar dependências do sistema
USER root

# Atualizar e instalar dependências necessárias
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    nodejs \
    npm \
    graphviz \
    dbus-x11 \
    xclip \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    fonts-dejavu && \
    apt-get -y -qq remove xfce4-screensaver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Atualizar o Node.js para uma versão compatível com JupyterLab
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Atualizar pip e instalar JupyterLab
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir jupyterlab && \
    jupyter lab clean && \
    jupyter lab build --dev-build=False --minimize=False || \
    cat /tmp/jupyterlab-debug-*.log

# Copiar scripts adicionais para o diretório de trabalho
COPY --chown=$NB_UID:$NB_GID binder/ /home/jovyan/binder/

# Garantir permissões para o script postBuild
RUN chmod +x /home/jovyan/binder/postBuild

# Executar o script postBuild com tratamento de erros
RUN ./home/jovyan/binder/postBuild || (cat /tmp/jupyterlab-debug-*.log && exit 1)

# Retornar ao usuário padrão do container
USER $NB_UID

# Definir o comando padrão
CMD ["start.sh"]

