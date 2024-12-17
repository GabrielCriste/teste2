FROM quay.io/jupyter/base-notebook:2024-12-02

USER root

# Instalar dependências adicionais necessárias
RUN apt-get -y -qq update \
    && apt-get -y -qq install \
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
    && mkdir -p /opt/install \
    && chown -R $NB_UID:$NB_GID $HOME /opt/install \
    && rm -rf /var/lib/apt/lists/*

# Instalar o VNC server (opcional)
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        apt-get -y -qq update; \
        apt-get -y -qq install tigervnc-standalone-server; \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Clonar o repositório desejado
RUN git clone https://github.com/almond-sh/examples.git /opt/repository

# Instalar dependências do repositório (ajuste conforme necessário)
WORKDIR /opt/repository
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file environment.yml || true

# Instalar pacotes adicionais no ambiente
COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    mamba install -y -q "nodejs>=22" && \
    pip install /opt/install

USER $NB_USER
