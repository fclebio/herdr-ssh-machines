# herdr-ssh-machines

Plugin para o [Herdr](https://herdr.dev) para adicionar e remover máquinas SSH diretamente da interface, integrando com o `~/.ssh/config`, suporte a grupos/clientes e busca interativa com `fzf`.

---

## Tabela Rápida de Atalhos

| Ação | Teclas | Descrição |
| :--- | :--- | :--- |
| **Pular para a Máquina Local** | `Ctrl+B` + `Espaço` | Retorna imediatamente para o workspace Local (de qualquer máquina) |
| **Adicionar Máquina SSH** | `Ctrl+B` + `m` | Abre o popup com `fzf` para buscar e conectar servidores |
| **Remover / Desconectar Máquina** | `Ctrl+B` + `Shift+M` | Abre popup de máquinas ativas; `Enter` duas vezes confirma |
| **Alternar entre Máquinas 1..9** | `Ctrl+B` + `Alt+1..9` | `Alt+1` vai para Local, `Alt+2` Máquina 2, `Alt+3` Máquina 3... |
| **Próxima / Máquina Anterior** | `Ctrl+B` + `Seta Dir/Esq` | Navega sequencialmente entre as máquinas conectadas |
| **Workspace Picker Geral** | `Ctrl+B` + `w` | Menu seletor visual nativo do Herdr (funciona em qualquer contexto) |

---

## Funcionalidades

- **Adicionar Máquina SSH (`prefix + m` / `Ctrl+B m`):**
  - Abre um popup no Herdr listando todos os servidores configurados no seu `~/.ssh/config`.
  - Busca instantânea com `fzf` por **Host**, **Cliente/Grupo** ou **IP**.
  - Janela de preview mostrando `HostName`, `User`, `Port` e cliente correspondente.
  - Opção no topo para **digitar qualquer Host ou IP avulso** manualmente sem precisar ter cadastrado previamente no `~/.ssh/config`.
  - Ao selecionar e dar `Enter`, executa `herdr machine add <host> --label <host>`, conectando a máquina ao Herdr e listando-a na barra lateral.
- **Remover / Desconectar Máquina Conectada (`prefix + M` / `Ctrl+B Shift+M`):**
  - Abre um popup listando as máquinas atualmente ativas no Herdr.
  - Confirmação rápida apertando **`Enter`** novamente (ou `n` / `Esc` para cancelar).
  - Fecha o túnel SSH persistente do OpenSSH em segundo plano (`ControlPersist`) e retorna automaticamente a tela para o workspace Local.

---

## Configuração Completa (`~/.config/herdr/config.toml`)

Copie e cole o bloco abaixo no seu `~/.config/herdr/config.toml`:

```toml
[keys]
prefix = "ctrl+b"

# Navegar diretamente entre as máquinas (Workspaces):
# Ctrl+B depois Alt+1 = Máquina Local (Workspace 1)
# Ctrl+B depois Alt+2 = Máquina Remota 2
# Ctrl+B depois Alt+3 = Máquina Remota 3 (e assim por diante até Alt+9)
switch_workspace = "prefix+alt+1..9"

# Navegar para a máquina anterior / próxima usando as setas:
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

> **Dica após alterar:** Rode `herdr server reload-config` no terminal. No cliente TUI do Herdr, pressione `Ctrl+B q` para desanexar e rode `herdr` para reanexar com os novos atalhos ativos.

---

## Fluxo de Uso Recomendado

### 1. Adicionar uma nova máquina SSH
1. Caso você esteja trabalhando em um servidor remoto, pressione **`Ctrl+B`** e em seguida a **barra de espaço** (`prefix+space`) para voltar à Máquina Local.
2. Pressione **`Ctrl+B`** e depois **`m`**.
3. O popup abrirá com a busca interativa `fzf`. Digite o nome do servidor, cliente ou IP.
4. Pressione **`Enter`**. A máquina será conectada e adicionada à barra lateral do Herdr!

### 2. Remover uma máquina conectada
1. Pressione **`Ctrl+B`** e depois **`Shift+M`** (M maiúsculo).
2. Selecione a máquina que deseja desconectar com as setas do `fzf` e pressione **`Enter`**.
3. A tela de confirmação solicitará validação: basta pressionar **`Enter` novamente** para confirmar.
4. O túnel SSH será finalizado e o Herdr alternará sua visão de volta para o Local!

### 3. Navegação entre máquinas
* Pressione **`Ctrl+B`** e depois **`Alt+1`** para ir para a máquina local.
* Pressione **`Ctrl+B`** e depois **`Alt+2`** para ir para o segundo servidor.
* Pressione **`Ctrl+B`** e depois **`Seta Direita`** ou **`Seta Esquerda`** para alternar sequencialmente.

---

## Organizando Servidores por Clientes/Grupos no `~/.ssh/config`

O plugin detecta grupos e clientes de forma automática:

### Opção 1: Usando Comentários (Recomendado)
Adicione um comentário `# Cliente: Nome` ou simplesmente `# Nome` antes ou na mesma linha do `Host`:

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

No `fzf`, ao digitar `Alfa` ou `Loja`, o filtro trará instantaneamente todos os servidores daquele cliente!

### Opção 2: Arquivos separados com `Include`
No seu `~/.ssh/config`:
```ssh
Include conf.d/*.conf
```
Arquivos em `~/.ssh/conf.d/cliente-alfa.conf` usarão automaticamente o nome do arquivo (`cliente-alfa`) como o grupo.

---

## Pré-requisitos

1. **Herdr** >= 0.8.0 instalado.
2. **fzf** instalado no sistema:
   - Ubuntu / Debian: `sudo apt install fzf`
   - Fedora: `sudo dnf install fzf`
   - Arch Linux: `sudo pacman -S fzf`
   - macOS: `brew install fzf`
3. **Python 3** (padrão em distribuições Linux e macOS).

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
