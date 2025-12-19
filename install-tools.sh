#!/bin/bash
#
# Comando para instalar todas las herramientas y aplicaciones que has utilizado,
# basado en el análisis de tus paquetes instalados y tu historial de comandos.
# La bandera "--needed" evita reinstalar paquetes ya presentes y actualizados.
#

yay -S --needed \
  aichat atuin autofirma \
  bat bc blueman broot btop \
  clipmenu copyq deepin-screen-recorder docker docker-compose dosfstools dunst dust \
  exfatprogs eza \
  fastfetch feh fzf \
  gemini-cli htop lazydocker lazygit lf lsd lxappearance \
  mirage ml4w-hyprland \
  ncdu neovim ouch \
  papirus-folders pasystray pavucontrol superfile tldr tlp tlpui trippy \
  visidata wezterm xh zip zsh ripgrep impala wiremix bluetui fd sd
