# Use a imagem base
FROM almondsh/almond:latest

# Instalar dependências necessárias
USER root
RUN apt-get update && apt-get install -y \
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
    fonts-dejavu \
 && apt-get -y -qq remove xfce4-screensaver \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Configurar permissões e diretórios
RUN mkdir -p /opt/install && chown -R $NB_UID:$NB_GID /home/jovyan /opt/install

# Instalar extensões do JupyterLab
USER $NB_UID
RUN pip install --upgrade pip && \
    pip install --upgrade jupyterlab && \
    jupyter labextension install @jupyterlab/plotly-extension

# Limpar cache e reconstruir o JupyterLab
RUN jupyter lab clean && jupyter lab build

# Copiar e executar scripts adicionais
COPY --chown=$NB_UID:$NB_GID binder/ /home/jovyan/binder/
RUN chmod +x /home/jovyan/binder/postBuild
RUN ./binder/postBuild || cat /tmp/jupyterlab-debug-uo3zg9fm.log

# Definir comandos padrão
USER $NB_USER
CMD ["start.sh"]

