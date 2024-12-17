FROM quay.io/jupyter/base-notebook:2024-12-02

USER root

# Atualiza os pacotes e instala dependências necessárias
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
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Instalar VNC Server (pode ser TigerVNC ou TurboVNC, depende da sua escolha)
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get install -y tigervnc-standalone-server \
    ; fi

RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get install -y turbovnc \
    ; fi

# Configurações do usuário padrão
USER $NB_USER

# Copiar o arquivo de ambiente (mamba ou conda) e atualizar o ambiente Python
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp/
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

# Copiar o código do repositório para o diretório de trabalho no contêiner
COPY --chown=$NB_UID:$NB_GID . /opt/install/

# Instalar pacotes do Python e Node.js
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install --no-cache-dir /opt/install

# Adiciona o arquivo postBuild, caso necessário, para configurações adicionais após build
RUN chmod +x binder/postBuild
RUN ./binder/postBuild

# Definir a variável de ambiente para não deixar o Python bufferizado
ENV PYTHONUNBUFFERED=1

# Copiar o script de login e o entrypoint (caso sejam necessários para o seu ambiente)
COPY /python3-login /usr/local/bin/python3-login
COPY /repo2docker-entrypoint /usr/local/bin/repo2docker-entrypoint

# Definir o entrypoint e o comando para o JupyterHub
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
