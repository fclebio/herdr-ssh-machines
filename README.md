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
  - Seleção com `fzf` e confirmação antes de remover via `herdr machine remove <id>`.

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

Se você publicou o plugin no seu GitHub (ex.: `github.com/SEU_USUARIO/herdr-ssh-machines`), basta rodar na máquina de destino:

```bash
herdr plugin install SEU_USUARIO/herdr-ssh-machines
```

O Herdr baixará, validará e ativará o plugin automaticamente!

---

### Método 2: Instalação Manual via Git Clone

Se preferir clonar manualmente o repositório na máquina:

```bash
# 1. Clone o repositório em uma pasta de sua escolha (ex: ~/herdr-ssh-machines)
git clone https://github.com/SEU_USUARIO/herdr-ssh-machines.git ~/herdr-ssh-machines

# 2. Acesse a pasta e vincule o plugin no Herdr
cd ~/herdr-ssh-machines
herdr plugin link .
```

Você pode confirmar que o plugin está ativo rodando:
```bash
herdr plugin list
```

---

## Configuração dos Atalhos (`~/.config/herdr/config.toml`)

Na máquina onde o plugin foi instalado, abra o arquivo `~/.config/herdr/config.toml` (crie se não existir) e adicione:

```toml
[keys]
prefix = "ctrl+b"

# Atalho para abrir o seletor de adicionar máquinas
[[keys.command]]
key = "prefix+m"
type = "plugin_action"
command = "herdr-ssh-machines.add-machine"
description = "Adicionar máquina SSH ao Herdr"

# Atalho para abrir o seletor de remover máquinas
[[keys.command]]
key = "prefix+shift+m"
type = "plugin_action"
command = "herdr-ssh-machines.remove-machine"
description = "Remover máquina SSH do Herdr"
```

*(Opcional: se preferir usar atalhos simultâneos diretos sem prefixo, você também pode adicionar `key = "ctrl+alt+m"`).*

### Aplicar a Configuração

1. Recarregue a configuração no servidor:
   ```bash
   herdr server reload-config
   ```
2. Para o cliente do terminal compilar os novos atalhos de teclado:
   - Pressione **`Ctrl+B`** e depois **`q`** para desanexar da sessão.
   - Execute **`herdr`** no terminal para reanexar (todos os seus processos, telas e agentes continuarão rodando normalmente).

---

## Organizando Servidores por Clientes/Grupos no `~/.ssh/config`

O plugin detecta grupos de servidores de duas maneiras práticas:

### Opção 1: Comentários no `~/.ssh/config` (Recomendado)

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

No `fzf`, ao digitar `Alfa` ou `Loja`, o filtro já trará apenas os servidores daquele cliente!

### Opção 2: Arquivos separados com `Include`

Você pode separar cada cliente em um arquivo próprio dentro de `~/.ssh/conf.d/`:

No seu `~/.ssh/config`:
```ssh
Include conf.d/*.conf
```

E os arquivos:
- `~/.ssh/conf.d/cliente-alfa.conf`
- `~/.ssh/conf.d/cliente-beta.conf`

O plugin usará automaticamente o nome do arquivo (`cliente-alfa`, `cliente-beta`) como o grupo de cada máquina.

---

## Como Usar

1. Pressione **`Ctrl+B`**, solte e pressione **`m`**:
   - O popup abrirá com a busca interativa `fzf`.
   - Digite o nome do servidor, do cliente ou do IP.
   - Pressione **`Enter`**: a máquina será conectada e adicionada à barra lateral do Herdr!
2. Pressione **`Ctrl+B`**, solte e pressione **`Shift+M`** (ou seja, `M` maiúsculo):
   - Selecione a máquina ativa que deseja remover e confirme com `s`.
