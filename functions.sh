#!/bin/bash

# =============================================
# KALI QUICK FUNCTIONS + CTF MODE ON
# Autor: Mortymerio
# GitHub: https://github.com/Mortymerio/kali-quick-setup
# =============================================

[[ -n "$KALI_FUNCTIONS_LOADED" ]] && return
export KALI_FUNCTIONS_LOADED=1

# --- COLORES ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# =============================================
# CTF MODE ON
# =============================================
ctfmode() {
    local action="${1:-full}"
    local base_dir="$HOME/CTF"
    local tools_dir="$base_dir/tools"
    local wordlists_dir="$base_dir/wordlists"
    local scripts_dir="$base_dir/scripts"
    local logs_dir="$base_dir/logs"
    local log_file="$logs_dir/ctfmode_$(date +%Y%m%d_%H%M%S).log"

    mkdir -p "$tools_dir" "$wordlists_dir" "$scripts_dir" "$logs_dir" "$base_dir/exploits" "$base_dir/screenshots" "$base_dir/loot" "$base_dir/notes"

    {
        echo "CTF MODE ON - $(date)"
        echo "Usuario: $USER | Acción: $action"
        echo "Directorio: $base_dir"
    } >> "$log_file"

    log "CTF MODE ON activado"
    info "Log: $log_file"

    case "$action" in
        full|"")
            log "Estructura de carpetas..."
            for d in exploits loot notes screenshots; do
                mkdir -p "$base_dir/$d"
            done

            log "Wordlists..."
            local wlists=(
                "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt:raft-medium-directories.txt"
                "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-files.txt:raft-medium-files.txt"
                "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Leaked-Databases/rockyou.txt:rockyou.txt"
                "https://raw.githubusercontent.com/berzerk0/Probable-Wordlists/master/Real-Passwords/Top12Thousand-probable-v2.txt:top12k.txt"
            )
            for item in "${wlists[@]}"; do
                local url=$(echo "$item" | cut -d: -f1)
                local file="$wordlists_dir/$(echo "$item" | cut -d: -f2)"
                [ ! -f "$file" ] && curl -sSL "$url" -o "$file" && log "   $(basename "$file")"
            done

            log "Scripts de enumeración..."
            local scripts=(
                "https://raw.githubusercontent.com/carlospolop/PEASS-ng/master/linpeas.sh:linpeas.sh"
                "https://raw.githubusercontent.com/carlospolop/PEASS-ng/master/winpeas.ps1:winpeas.ps1"
                "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh:LinEnum.sh"
            )
            for item in "${scripts[@]}"; do
                local url=$(echo "$item" | cut -d: -f1)
                local file="$scripts_dir/$(echo "$item" | cut -d: -f2)"
                [ ! -f "$file" ] && curl -sSL "$url" -o "$file" && chmod +x "$file" && log "   $(basename "$file")"
            done

            log "Herramientas Kali..."
            local tools=(gobuster ffuf sqlmap nikto nmap metasploit-framework seclists)
            for tool in "${tools[@]}"; do
                command -v "$tool" >/dev/null || sudo apt install -y "$tool" >> "$log_file" 2>&1 && log "   $tool"
            done

            log "Alias CTF..."
            {
                echo "export CTF='$base_dir'"
                echo "export WORDLISTS='$wordlists_dir'"
                echo "alias ctf='cd \$CTF'"
                echo "alias loot='cd \$CTF/loot'"
                echo "alias exp='cd \$CTF/exploits'"
                echo "alias note='nano \$CTF/notes/\$(date +%Y%m%d_%H%M%S).txt'"
                echo "alias wl='ls -la \$WORDLISTS'"
            } >> "$HOME/.bashrc"
            [ -f "$HOME/.zshrc" ] && grep -q "alias ctf" "$HOME/.zshrc" || cat >> "$HOME/.zshrc"

            log "CTF MODE COMPLETADO"
            info "Usa: ctf, note, loot, wl"
            ;;

        update)
            log "Actualizando wordlists y scripts..."
            ctfmode full >/dev/null 2>&1
            log "Actualizado"
            ;;

        clean)
            warn "BORRANDO ~/CTF..."
            read -p "¿Seguro? (s/N): " -r r
            [[ $r =~ ^[Ss]$ ]] && rm -rf "$base_dir" && sed -i '/CTF/d' "$HOME/.bashrc" "$HOME/.zshrc" && log "Eliminado"
            ;;

        *) err "Uso: ctfmode [full|update|clean]" ;;
    esac
}

# =============================================
# ATAJOS DE PENTESTING
# =============================================

addhost() {
    [[ $# -ne 2 ]] && { echo "Uso: addhost IP HOST"; return 1; }
    local ip="$1" host="$2"
    grep -q "^$ip.*$host" /etc/hosts && { warn "Ya existe"; return; }
    echo "$ip $host" | sudo tee -a /etc/hosts > /dev/null
    log "Agregado: $ip $host"
}

nmapquick() { [[ $# -eq 0 ]] && { echo "Uso: nmapquick IP"; return; }; nmap -sV -sC -T4 "$1"; }
nmapfull() { [[ $# -eq 0 ]] && { echo "Uso: nmapfull IP"; return; }; sudo nmap -p- -sV -sC -O "$1"; }
gobuster_dir() { [[ $# -lt 2 ]] && { echo "Uso: gobuster_dir URL WORDLIST"; return; }; gobuster dir -u "$1" -w "$2" -q -t 50; }
ffuf_web() { [[ $# -lt 2 ]] && { echo "Uso: ffuf_web URL WORDLIST"; return; }; ffuf -u "$1/FUZZ" -w "$2" -mc 200,301; }
sqlmap_quick() { [[ $# -eq 0 ]] && { echo "Uso: sqlmap_quick URL"; return; }; sqlmap -u "$1" --batch; }
nikto_scan() { [[ $# -eq 0 ]] && { echo "Uso: nikto_scan URL"; return; }; nikto -h "$1"; }

updatekali() { sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y; }
fuck() { sudo $(history -p !!); }
psg() { [[ $# -eq 0 ]] && return; ps aux | grep -v grep | grep -i "$1"; }
ka() { [[ $# -eq 0 ]] && return; pkill -f "$1"; }

ll() { ls -lah --color=auto "$@"; }
la() { ls -lahA --color=auto "$@"; }
q() { exit; }

remoteip() { curl -s ifconfig.me; }
localip() { ip -4 a | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1; }

gac() { [[ $# -eq 0 ]] && return; git add . && git commit -m "$1" && git push; }

# Final
echo -e "${GREEN}KALI QUICK + CTF MODE ON → Usa: ctfmode${NC}"
