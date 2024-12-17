#!/bin/bash
# Inicia o Xvfb (X Virtual Framebuffer)
Xvfb :1 -screen 0 1280x1024x24 &
export DISPLAY=:1

# Inicia o Fluxbox (gerenciador de janelas)
fluxbox &

# Inicia o servidor VNC
tigervncserver :1 -geometry 1280x1024 -depth 24 -passwordfile ~/.vnc/passwd

# Espera o VNC server iniciar
sleep 5

# Inicia o Jupyter Notebook
jupyter notebook --ip=0.0.0.0 --port=8888 --NotebookApp.token=''

