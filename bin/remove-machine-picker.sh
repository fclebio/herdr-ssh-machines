#!/usr/bin/env bash
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"

# Cores ANSI
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Verifica se o fzf está disponível
if ! command -v fzf &>/dev/null; then
    echo -e "${YELLOW}Aviso: 'fzf' não está instalado no sistema.${RESET}"
    echo "Instale com: sudo apt install fzf"
    echo ""
    read -r -p "Pressione Enter para fechar..."
    exit 1
fi

# Obtém a lista atual de máquinas salvas no Herdr
MACHINES_JSON=$("$HERDR" machine list --json 2>/dev/null || echo "[]")

# Processa com Python para checar contagem e formatar para o fzf
MACHINE_LIST=$(python3 -c '
import sys, json

try:
    data = json.loads(sys.argv[1])
except Exception:
    data = []

if not isinstance(data, list):
    # Se vier encapsulado em result ou similar
    data = data.get("result", {}).get("machines", []) if isinstance(data, dict) else []

for item in data:
    pid = item.get("profile_id", item.get("id", "unknown"))
    label = item.get("label", pid)
    target = item.get("ssh_target", item.get("host", ""))
    enabled = "ativo" if item.get("enabled", True) else "desabilitado"
    print(f"{pid:<34} │ {label:<20} │ {target:<25} │ {enabled}")
' "$MACHINES_JSON")

if [ -z "$MACHINE_LIST" ]; then
    echo -e "${YELLOW}Nenhuma máquina SSH conectada/salva atualmente no Herdr.${RESET}"
    echo ""
    read -r -p "Pressione Enter para fechar..."
    exit 0
fi

# Abre seleção interativa no fzf
SELECTED=$(echo "$MACHINE_LIST" | fzf \
    --ansi \
    --header "ENTER: Remover Máquina  |  ESC / Ctrl+C: Cancelar" \
    --prompt "Remover Máquina Herdr > " \
    --height "100%" \
    --reverse) || true

if [ -z "$SELECTED" ]; then
    exit 0
fi

# Extrai o profile_id e label
PROFILE_ID=$(echo "$SELECTED" | awk '{print $1}')
LABEL=$(echo "$SELECTED" | awk -F'│' '{print $2}' | xargs)

clear
echo -e "${BOLD}${RED}=== Remover Máquina do Herdr ===${RESET}"
echo -e "Máquina selecionada: ${BOLD}${LABEL}${RESET} (ID: ${CYAN}${PROFILE_ID}${RESET})"
echo ""
echo "Nota: Isso apenas desconecta a máquina do seu Herdr local."
echo "As sessões e agentes continuarão rodando no servidor remoto normalmente."
echo ""

read -r -p "Confirma a remoção da máquina '$LABEL'? [s/N]: " CONFIRM
case "${CONFIRM,,}" in
    s|sim|y|yes)
        echo ""
        if "$HERDR" machine remove "$PROFILE_ID"; then
            echo -e "${GREEN}✓ Máquina '${LABEL}' removida com sucesso do Herdr!${RESET}"
            sleep 1.5
        else
            echo -e "${RED}Erro ao remover a máquina.${RESET}"
            read -r -p "Pressione Enter para fechar..."
        fi
        ;;
    *)
        echo "Operação cancelada."
        sleep 1
        ;;
esac
