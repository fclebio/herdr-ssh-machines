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
    data = data.get("result", {}).get("machines", []) if isinstance(data, dict) else []

for item in data:
    pid = item.get("id", item.get("profile_id", "unknown"))
    label = item.get("label", pid)
    target = item.get("target", item.get("ssh_target", item.get("host", "")))
    enabled = "ativo" if item.get("enabled", True) else "desabilitado"
    print(f"{pid:<34} │ {label:<22} │ {target:<25} │ {enabled}")
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
    --header "ENTER: Selecionar Máquina  |  ESC / Ctrl+C: Cancelar" \
    --prompt "Remover Máquina Herdr > " \
    --height "100%" \
    --reverse) || true

if [ -z "$SELECTED" ]; then
    exit 0
fi

# Extrai o ID, label e target
PROFILE_ID=$(echo "$SELECTED" | awk '{print $1}')
LABEL=$(echo "$SELECTED" | awk -F'│' '{print $2}' | xargs)
TARGET=$(echo "$SELECTED" | awk -F'│' '{print $3}' | xargs)

clear
echo -e "${BOLD}${RED}=== Desconectar e Remover Máquina ===${RESET}"
echo -e "Máquina: ${BOLD}${LABEL}${RESET}"
echo -e "ID:      ${CYAN}${PROFILE_ID}${RESET}"
echo -e "Target:  ${TARGET}"
echo "---------------------------------------------------"
echo "A máquina será desconectada e você retornará ao workspace Local."
echo ""
echo -e "Pressione ${BOLD}${GREEN}[ENTER]${RESET} para confirmar a remoção"
echo -e "Ou digite ${BOLD}'n'${RESET} / ${BOLD}[Ctrl+C]${RESET} para cancelar."
echo ""

read -r -p "Confirmar? [ENTER = Sim, 'n' = Não]: " CONFIRM
case "${CONFIRM,,}" in
    ""|s|sim|y|yes)
        echo ""
        echo "Desconectando e removendo perfil..."
        
        # 1. Desabilita primeiro a máquina
        "$HERDR" machine disable "$PROFILE_ID" 2>/dev/null || true
        
        # 2. Remove o perfil da máquina salva
        if "$HERDR" machine remove "$PROFILE_ID"; then
            # 3. Fecha conexões persistentes OpenSSH ativas (ControlPersist)
            if [ -n "$TARGET" ]; then
                ssh -O exit "$TARGET" 2>/dev/null || true
            fi
            if [ -n "$LABEL" ]; then
                ssh -O exit "$LABEL" 2>/dev/null || true
            fi

            # 4. Retorna o foco para o workspace Local
            "$HERDR" workspace focus 1 2>/dev/null || true

            echo ""
            echo -e "${GREEN}✓ Máquina '${LABEL}' removida e desconectada com sucesso!${RESET}"
            echo "Alternando para o workspace Local..."
            sleep 1.5
        else
            echo ""
            echo -e "${RED}Erro ao remover a máquina do Herdr.${RESET}"
            read -r -p "Pressione Enter para fechar..."
        fi
        ;;
    *)
        echo "Operação cancelada."
        sleep 1
        ;;
esac
