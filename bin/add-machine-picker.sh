#!/usr/bin/env bash
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/parse_ssh_config.py"

# Cores ANSI para feedback
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Verifica se o fzf está disponível
if ! command -v fzf &>/dev/null; then
    echo -e "${YELLOW}Aviso: 'fzf' não está instalado no sistema.${RESET}"
    echo "Instale com: sudo apt install fzf"
    echo ""
    read -r -p "Pressione Enter para sair..."
    exit 1
fi

# Abre a busca interativa com fzf
SELECTED=$(python3 "$PARSER" | fzf \
    --ansi \
    --header "ENTER: Conectar e Adicionar  |  ESC / Ctrl+C: Cancelar  |  Busca por Host ou [Grupo]" \
    --prompt "Adicionar Máquina SSH > " \
    --preview "python3 \"$PARSER\" --preview {1}" \
    --preview-window "right:50%:wrap" \
    --height "100%" \
    --reverse) || true

if [ -z "$SELECTED" ]; then
    exit 0
fi

# Extrai o primeiro campo (Host alias)
HOST_ALIAS=$(echo "$SELECTED" | awk '{print $1}')

clear
echo -e "${BOLD}${CYAN}=== Conectar Máquina SSH ao Herdr ===${RESET}"

# Se o usuário escolheu a opção de entrada manual
if [ "$HOST_ALIAS" = "+manual" ]; then
    echo -e "Nenhum host pré-configurado selecionado."
    echo ""
    read -r -p "Digite o endereço SSH (ex: ubuntu@192.168.1.50 ou meu-servidor): " MANUAL_TARGET
    if [ -z "$MANUAL_TARGET" ]; then
        echo "Cancelado."
        sleep 1
        exit 0
    fi
    HOST_ALIAS="$MANUAL_TARGET"
    
    # Extrai um label limpo se for do formato user@host ou user@host:port
    DEFAULT_LABEL=$(echo "$MANUAL_TARGET" | sed -E 's/^.*@//' | sed -E 's/:.*$//')
    read -r -p "Label para a máquina [padrão: $DEFAULT_LABEL]: " USER_LABEL
    LABEL="${USER_LABEL:-$DEFAULT_LABEL}"
else
    LABEL="$HOST_ALIAS"
fi

echo ""
echo -e "Host:  ${GREEN}${HOST_ALIAS}${RESET}"
echo -e "Label: ${BOLD}${LABEL}${RESET}"
echo "---------------------------------------------------"
echo -e "Iniciando conexão e setup..."
echo ""

# Executa o herdr machine add usando o label
if "$HERDR" machine add "$HOST_ALIAS" --label "$LABEL"; then
    echo ""
    echo -e "${GREEN}✓ Máquina '${LABEL}' conectada com sucesso ao Herdr!${RESET}"
    echo "Os workspaces e agentes aparecerão na barra lateral."
    echo ""
    sleep 2
else
    echo ""
    echo -e "${YELLOW}Ocorreu uma falha ao adicionar a máquina.${RESET}"
    echo "Verifique as mensagens acima (SSH, autenticação ou rede)."
    echo ""
    read -r -p "Pressione Enter para fechar..."
fi
