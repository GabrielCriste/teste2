# Use a imagem base
FROM almondsh/almond:latest

# Trocar para o usuário root para instalar dependências do sistema
USER root

# Atualizar sistema e instalar dependências
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
    apt-get -y remove xfce4-screensaver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configurar permissões e criar diretórios necessários
RUN mkdir -p /opt/install && \
    chown -R $NB_UID:$NB_GID /home/jovyan /opt/install

# Trocar para o usuário padrão
USER $NB_UID

# Atualizar pip, instalar e configurar extensões do JupyterLab
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --upgrade jupyterlab && \
    jupyter labextension install @jupyterlab/plotly-extension && \
    jupyter lab clean && \
    jupyter lab build

# Copiar arquivos e scripts adicionais para o container
COPY --chown=$NB_UID:$NB_GID binder/ /home/jovyan/binder/

# Garantir permissões de execução para o script postBuild
RUN chmod +x /home/jovyan/binder/postBuild

# Executar o script postBuild com tratamento de erros
RUN ./home/jovyan/binder/postBuild || (cat /tmp/jupyterlab-debug-*.log && exit 1)

# Definir comando padrão
USER $NB_USER
CMD ["start.sh"]

