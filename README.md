# herdr-ssh-machines

Plugin para o [Herdr](https://herdr.dev) para adicionar e remover máquinas SSH diretamente da interface, integrando com o `~/.ssh/config`, suporte a grupos/clientes e busca interativa com `fzf`.

## Funcionalidades

- **Adicionar Máquina SSH (`prefix + m` / `Ctrl+B m`):**
  - Abre um popup no Herdr listando todos os servidores do `~/.ssh/config`.
  - Busca instantânea com `fzf` por **Host**, **Cliente/Grupo** ou **IP**.
  - Janela de preview mostrando `HostName`, `User`, `Port` e cliente correspondente.
  - Opção no topo para **digitar qualquer Host ou IP avulso** manualmente sem precisar ter no `~/.ssh/config`.
  - Ao pressionar `Enter`, executa `herdr machine add <host> --label <host>`, conectando a máquina ao Herdr e listando-a na barra lateral.
- **Remover Máquina Conectada (`prefix + M` / `Ctrl+B Shift+M`):**
  - Abre um popup listando as máquinas atualmente ativas no Herdr.
  - Seleção com `fzf` e confirmação rápida apertando **`Enter`** novamente.
  - Fecha o túnel SSH em segundo plano e retorna automaticamente ao workspace Local.

---

## Atalhos Recomendados no Herdr (`~/.config/herdr/config.toml`)

No seu arquivo de configuração `~/.config/herdr/config.toml`:

```toml
[keys]
prefix = "ctrl+b"

# Navegar entre as máquinas (Workspaces):
# Ctrl+B depois Alt+1 = Máquina Local (Workspace 1)
# Ctrl+B depois Alt+2 = Máquina Remota 2
# Ctrl+B depois Alt+3 = Máquina Remota 3 (até Alt+9)
switch_workspace = "prefix+alt+1..9"

# Navegar entre máquinas com setas (anterior / próxima):
previous_workspace = "prefix+left"
next_workspace = "prefix+right"

# Atalho dedicado para ir DIRETO para a Máquina Local:
# Pressione Ctrl+B e depois a barra de Espaço:
[[keys.command]]
key = "prefix+space"
type = "shell"
command = "herdr workspace focus 1"
description = "Ir para Máquina Local"

# Atalhos do plugin herdr-ssh-machines:
[[keys.command]]
key = "prefix+m"
type = "plugin_action"
command = "herdr-ssh-machines.add-machine"
description = "Adicionar máquina SSH ao Herdr"

[[keys.command]]
key = "prefix+shift+m"
type = "plugin_action"
command = "herdr-ssh-machines.remove-machine"
description = "Remover máquina SSH do Herdr"
```

---

## Como Navegar e Usar no Dia a Dia

### 1. Alternando entre Máquinas
* **Ir direto para a Máquina Local:** Pressione **`Ctrl+B`** e em seguida a **barra de espaço** (`prefix+space`).
* **Ir para uma máquina pelo número:**
  - `Ctrl+B` depois `Alt+1` -> Máquina Local (Workspace 1)
  - `Ctrl+B` depois `Alt+2` -> Máquina Remota 2
  - `Ctrl+B` depois `Alt+3` -> Máquina Remota 3
* **Navegar para a próxima/anterior:** `Ctrl+B` depois `Seta Direita` / `Seta Esquerda`.
* **Workspace Picker visual (funciona em qualquer máquina):** Pressione **`Ctrl+B w`** e escolha a máquina com as setas.

### 2. Adicionar uma nova máquina SSH
1. Certifique-se de estar no workspace Local (se estiver em um servidor remoto, basta dar `Ctrl+B Espaço`).
2. Pressione **`Ctrl+B`** e depois **`m`**.
3. Escolha o servidor com `fzf` e dê **`Enter`**. A máquina será conectada e adicionada à barra lateral!

### 3. Remover uma máquina conectada
1. Pressione **`Ctrl+B`** e depois **`Shift+M`** (M maiúsculo).
2. Selecione a máquina no `fzf` e pressione **`Enter`**.
3. Pressione **`Enter`** novamente para confirmar. A máquina será desconectada e a tela voltará automaticamente para o Local!

---

## Pré-requisitos

1. **Herdr** >= 0.8.0 instalado.
2. **fzf** instalado no sistema:
   - Ubuntu / Debian: `sudo apt install fzf`
   - Fedora: `sudo dnf install fzf`
   - Arch Linux: `sudo pacman -S fzf`
   - macOS: `brew install fzf`
3. **Python 3** (vem por padrão na maioria das distribuições Linux e macOS).

---

## Como Instalar em Outra Máquina (Passo a Passo)

### Método 1: Instalação Direta via GitHub (Recomendado)

```bash
herdr plugin install fclebio/herdr-ssh-machines
```

### Método 2: Instalação Manual via Git Clone

```bash
git clone https://github.com/fclebio/herdr-ssh-machines.git ~/herdr-ssh-machines
cd ~/herdr-ssh-machines
herdr plugin link .
```

---

## Organizando Servidores por Clientes/Grupos no `~/.ssh/config`

Basta adicionar um comentário `# Cliente: Nome` ou simplesmente `# Nome` antes ou na mesma linha do `Host`:

```ssh
# Cliente: Banco Alfa
Host alfa-api
    HostName 10.0.1.10
    User deploy

Host alfa-db # Cliente: Banco Alfa
    HostName 10.0.1.20
    User postgres

# Loja Virtual
Host loja-web loja-worker
    HostName 192.168.1.50
    User ubuntu
```

No `fzf`, ao digitar `Alfa` ou `Loja`, o filtro trará apenas os servidores daquele cliente!
