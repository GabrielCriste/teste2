# Use a imagem base principal
FROM quay.io/jupyter/base-notebook:2024-12-02

# Mantenha o usuário root para instalar dependências
USER root

# Atualizar e instalar dependências do primeiro Dockerfile
RUN apt-get -y -qq update && \
    apt-get install -y -qq \
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
    # Remover o screensaver para evitar problemas com bloqueio de tela
    apt-get -y -qq remove xfce4-screensaver && \
    # Limpar cache
    rm -rf /var/lib/apt/lists/* && \
    # Configurar permissões para os diretórios necessários
    mkdir -p /opt/install && \
    chown -R $NB_UID:$NB_GID $HOME /opt/install

# Instalar extensões do Jupyter Lab
USER $NB_UID
RUN jupyter labextension install @jupyterlab/plotly-extension

# Configurar o servidor VNC
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get -y -qq update && \
        apt-get -y -qq install tigervnc-standalone-server && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update && \
        apt-get -y -qq install turbovnc && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Instalar ambiente Conda e pacotes
USER $NB_USER
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

# Copiar arquivos necessários para instalação
COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install

# Configurar o Almond para Scala (mantido do primeiro arquivo)
USER root
RUN curl -fLo cs https://github.com/coursier/coursier/releases/download/v2.0.3/cs-x86_64-pc-linux && \
    chmod +x cs && \
    ./cs launch "almond:0.11.1" --scala 2.13.3 -- --install --id scala213 --display-name "Scala (2.13)" --env "JAVA_OPTS=-XX:MaxRAMPercentage=80.0" && \
    ./cs launch "almond:0.11.1" --scala 2.12.12 -- --install --id scala212 --display-name "Scala (2.12)" --env "JAVA_OPTS=-XX:MaxRAMPercentage=80.0"

# Finalizar com o usuário padrão
USER $NB_USER
