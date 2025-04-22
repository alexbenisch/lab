FROM ubuntu:latest
ENV HOME=/root/

# System-Updates und Installation der notwendigen Pakete
RUN apt update && apt install -y \
    gpg sudo wget curl unzip git ripgrep fzf fd-find \
    neovim lua5.4 make gcc zsh tmux \
    && rm -rf /var/lib/apt/lists/*

# Mise installieren
RUN sudo install -dm 755 /etc/apt/keyrings && \
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list && \
    apt update && \
    apt install -y mise

# Setze Zsh als Standard-Shell für root
RUN chsh -s /usr/bin/zsh root

# Setze pure als zsh prompt
RUN git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"

# LazyVim-Setup
RUN git clone --depth 1 https://github.com/LazyVim/starter /root/.config/nvim

# Kopiere die .zshrc Datei ins Home-Verzeichnis
COPY .zshrc /root/.zshrc

# Standardbefehl: Zsh starten
CMD ["zsh"]

