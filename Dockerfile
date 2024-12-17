FROM quay.io/jupyter/base-notebook:2024-12-02

USER root

# Atualiza os pacotes e instala dependências necessárias para o desktop virtual
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    dbus-x11 \
    xclip \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    fonts-dejavu \
    graphviz \
    openjdk-8-jre-headless \
    xvfb \
    fluxbox \
    tigervnc-standalone-server \
    tigervnc-common \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Instalar Node.js e pacotes do Python (mamba/conda)
USER $NB_USER
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp/
RUN . /opt/conda/bin/activate && mamba env update --quiet --file /tmp/environment.yml
RUN . /opt/conda/bin/activate && mamba install -y -q "nodejs>=22" && pip install --no-cache-dir /opt/install

# Copiar os arquivos do repositório para o diretório de trabalho no contêiner
COPY --chown=$NB_UID:$NB_GID . /opt/install/

# Configurações do VNC
ENV DISPLAY=:1
ENV VNC_PASSWORD=password

# Script de inicialização do VNC e Fluxbox
COPY ./vnc_start.sh /usr/local/bin/vnc_start.sh
RUN chmod +x /usr/local/bin/vnc_start.sh

# Adicionar e dar permissão ao script de entrada do contêiner
COPY /repo2docker-entrypoint /usr/local/bin/repo2docker-entrypoint
RUN chmod +x /usr/local/bin/repo2docker-entrypoint

# Configurar o entrypoint e o comando para rodar o JupyterHub
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0", "--port", "8888", "--NotebookApp.token=''"]


