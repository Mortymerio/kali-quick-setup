#!/bin/bash

# Kali Quick Setup + CTF Mode ON
# Autor: Mortymerio
# GitHub: https://github.com/Mortymerio/kali-quick-setup
# Compatible: Kali Linux (Zsh por defecto)

set -e

USER_HOME="$HOME"
FUNCS_URL="https://raw.githubusercontent.com/Mortymerio/kali-quick-setup/main/functions.sh"
FUNCS_FILE="$USER_HOME/.kali-functions.sh"
BACKUP_DIR="$USER_HOME/.kali-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Kali Quick Setup + CTF Mode ON"
echo "GitHub: Mortymerio/kali-quick-setup"
echo "================================"

# === DETECTAR SHELL REAL (Zsh en Kali) ===
if [[ -n "$ZSH_VERSION" ]]; then
    RC_FILE="$USER_HOME/.zshrc"
    SHELL_NAME="zsh"
elif [[ -n "$BASH_VERSION" ]]; then
    RC_FILE="$USER_HOME/.bashrc"
    SHELL_NAME="bash"
else
    RC_FILE="$USER_HOME/.bashrc"
    SHELL_NAME="bash"
fi

echo "Shell detectado: $SHELL_NAME → $RC_FILE"

# === BACKUP ===
BACKUP_RC="$BACKUP_DIR/$(basename $RC_FILE).backup.$TIMESTAMP"
cp "$RC_FILE" "$BACKUP_RC" 2>/dev/null || true
echo "Backup: $BACKUP_RC"

# === REPARAR BASH-COMPLETION (causa del error 'parse error near &') ===
echo "Reparando bash-completion..."
if ! dpkg -l | grep -q bash-completion; then
    sudo apt install -y bash-completion >/dev/null 2>&1
else
    sudo apt install --reinstall -y bash-completion >/dev/null 2>&1
fi

# === DESCARGAR functions.sh ===
if [ -f "$FUNCS_FILE" ]; then
    LOCAL_SUM=$(md5sum "$FUNCS_FILE" 2>/dev/null | cut -d' ' -f1)
    REMOTE_SUM=$(curl -sSL "$FUNCS_URL" | md5sum | cut -d' ' -f1)
    if [ "$LOCAL_SUM" != "$REMOTE_SUM" ]; then
        read -p "¿Actualizar .kali-functions.sh? (s/N): " -r REPLY
        [[ $REPLY =~ ^[Ss]$ ]] && curl -sSL "$FUNCS_URL" -o "$FUNCS_FILE"
    fi
else
    curl -sSL "$FUNCS_URL" -o "$FUNCS_FILE"
    echo "Funciones descargadas: $FUNCS_FILE"
fi

# === LIMPIAR CONFIGURACIÓN ANTERIOR ===
sed -i '/Kali Quick Setup (Mortymerio)/,/======================================"$/d' "$RC_FILE" 2>/dev/null || true

# === AGREGAR CARGA ===
LOAD_LINE="[ -f \"$FUNCS_FILE\" ] && source \"$FUNCS_FILE\""

{
    echo ""
    echo "# === Kali Quick Setup (Mortymerio) ==="
    echo "$LOAD_LINE"
    echo "======================================"
} >> "$RC_FILE"

# === CARGAR AHORA ===
[ -f "$FUNCS_FILE" ] && source "$FUNCS_FILE"

# === RECARGAR SHELL CORRECTO ===
if [[ "$SHELL_NAME" == "zsh" ]]; then
    echo "Recargando Zsh..."
    exec zsh
else
    echo "Recargando Bash..."
    exec bash
fi

echo ""
echo "¡Listo! Prueba:"
echo "   addhost 127.0.0.1 test.local"
echo "   ctfmode"
echo ""
echo "Todo configurado en: $RC_FILE"
