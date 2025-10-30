#!/bin/bash

# Kali Quick Setup - Instalador seguro
set -e

USER_HOME="$HOME"
BASHRC="$USER_HOME/.bashrc"
ZSHRC="$USER_HOME/.zshrc"
FUNCS_URL="https://raw.githubusercontent.com/Mortymerio/kali-quick-setup/main/functions.sh"
FUNCS_FILE="$USER_HOME/.kali-functions.sh"
BACKUP_DIR="$USER_HOME/.kali-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Kali Quick Setup + CTF Mode"
echo "GitHub: Mortymerio/kali-quick-setup"
echo "================================"

# Detectar shell
if [[ "$SHELL" == */zsh ]]; then
    RC_FILE="$ZSHRC"
else
    RC_FILE="$BASHRC"
fi

# Backup
BACKUP_RC="$BACKUP_DIR/$(basename $RC_FILE).backup.$TIMESTAMP"
cp "$RC_FILE" "$BACKUP_RC" 2>/dev/null || true
echo "Backup: $BACKUP_RC"

# Descargar functions.sh
if [ -f "$FUNCS_FILE" ]; then
    LOCAL_SUM=$(md5sum "$FUNCS_FILE" | cut -d' ' -f1)
    REMOTE_SUM=$(curl -sSL "$FUNCS_URL" | md5sum | cut -d' ' -f1)
    if [ "$LOCAL_SUM" != "$REMOTE_SUM" ]; then
        read -p "¿Actualizar functions.sh? (s/N): " -r REPLY
        [[ $REPLY =~ ^[Ss]$ ]] && curl -sSL "$FUNCS_URL" -o "$FUNCS_FILE"
    fi
else
    curl -sSL "$FUNCS_URL" -o "$FUNCS_FILE"
    echo "Funciones descargadas"
fi

# Agregar carga
LOAD_LINE="[ -f $FUNCS_FILE ] && . $FUNCS_FILE"
if ! grep -q "$LOAD_LINE" "$RC_FILE" 2>/dev/null; then
    echo "" >> "$RC_FILE"
    echo "# === Kali Quick Setup (Mortymerio) ===" >> "$RC_FILE"
    echo "$LOAD_LINE" >> "$RC_FILE"
    echo "======================================" >> "$RC_FILE"
fi

# Cargar ahora
source "$FUNCS_FILE"

echo ""
echo "¡Listo! Prueba:"
echo "   addhost 127.0.0.1 test.local"
echo "   ctfmode"
echo ""
echo "Recarga en nuevas terminales: source ~/.bashrc"
