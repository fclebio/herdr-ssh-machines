#!/usr/bin/env python3
"""
Parser para ~/.ssh/config com suporte a:
- Conexão manual rápida (opção [+ Conectar Manualmente])
- Detecção automática de Clientes/Grupos por comentários (#ClienteAlfa, #ClienteBeta, #EmpresaX, #Pessoal, etc.)
- Suporte a diretivas Include (ex: Include clients/*, Include conf.d/*.conf)
- Filtro inteligente de wildcards (* e ?)
- Formatação de lista e preview para fzf
"""

import os
import glob
import re
import sys
import json
from pathlib import Path

CONFIG_KEYWORDS = {
    "port", "hostname", "identityfile", "localforward", "remoteforward",
    "dynamicforward", "user", "host", "proxyjump", "serveraliveinterval",
    "addkeystoagent", "forwardagent", "usekeychain", "identitiesonly",
    "include", "só", "so", "ip", "todo", "fixme", "check"
}

def expand_path(path_str):
    return os.path.expanduser(os.path.expandvars(path_str))

def extract_group_from_comment(comment_line):
    stripped = comment_line.strip()
    if not stripped.startswith("#"):
        return None
    content = stripped.lstrip("#").strip()
    if not content:
        return None

    first_word = content.split()[0].lower()
    if first_word in CONFIG_KEYWORDS:
        return None

    # Verifica se tem formato explícito: # Cliente: X ou # Group: X
    m = re.search(r"#\s*(?:@group|group|grupo|cliente|client)\s*:\s*(.+)$", stripped, re.IGNORECASE)
    if m:
        return m.group(1).strip()

    # Comentário de cabeçalho limpo (ex: #ClienteAlfa, #ClienteBeta, #EmpresaX)
    if len(content) <= 30 and not any(c in content for c in "=*/\\"):
        return content

    return None

def parse_config_file(filepath, visited=None, inherited_group=None):
    if visited is None:
        visited = set()
    
    real_path = os.path.realpath(expand_path(filepath))
    if real_path in visited or not os.path.isfile(real_path):
        return []
    visited.add(real_path)

    hosts = []
    current_hosts = None
    current_data = {}
    active_group = inherited_group

    filename = os.path.basename(real_path)
    file_stem, _ = os.path.splitext(filename)
    if filename != "config" and active_group is None:
        active_group = file_stem

    try:
        with open(real_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except Exception as e:
        sys.stderr.write(f"Erro ao ler {filepath}: {e}\n")
        return []

    base_dir = os.path.dirname(real_path)

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue

        if stripped.startswith("#"):
            grp = extract_group_from_comment(stripped)
            if grp:
                active_group = grp
            continue

        # Verifica comentário inline
        if "#" in stripped:
            parts_hash = stripped.split("#", 1)
            stripped = parts_hash[0].strip()
            inline_comment = "#" + parts_hash[1]
            grp = extract_group_from_comment(inline_comment)
            if grp:
                active_group = grp

        parts = stripped.split(None, 1)
        if len(parts) == 0:
            continue
        key = parts[0].lower()
        val = parts[1].strip() if len(parts) > 1 else ""

        if key == "include":
            include_patterns = val.split()
            for pattern in include_patterns:
                expanded_pat = expand_path(pattern)
                if not os.path.isabs(expanded_pat):
                    expanded_pat = os.path.join(base_dir, expanded_pat)
                for matched_file in sorted(glob.glob(expanded_pat)):
                    inc_group = os.path.splitext(os.path.basename(matched_file))[0]
                    hosts.extend(parse_config_file(matched_file, visited, inherited_group=inc_group))
            continue

        if key == "host":
            if current_hosts:
                for h in current_hosts:
                    if "*" not in h and "?" not in h:
                        hosts.append({
                            "host": h,
                            "group": current_data.get("_group", active_group or "Geral"),
                            "config": dict(current_data),
                            "file": real_path
                        })
            current_hosts = val.split()
            current_data = {}
            if active_group:
                current_data["_group"] = active_group
            continue

        if current_hosts is not None:
            current_data[key] = val

    if current_hosts:
        for h in current_hosts:
            if "*" not in h and "?" not in h:
                hosts.append({
                    "host": h,
                    "group": current_data.get("_group", active_group or "Geral"),
                    "config": dict(current_data),
                    "file": real_path
                })

    return hosts

def get_all_hosts():
    default_config = os.path.expanduser("~/.ssh/config")
    if not os.path.exists(default_config):
        return []
    raw_hosts = parse_config_file(default_config)
    seen = set()
    unique_hosts = []
    for item in raw_hosts:
        h = item["host"]
        if h not in seen:
            seen.add(h)
            unique_hosts.append(item)
    return unique_hosts

def print_fzf_lines(hosts):
    print(f"{'+manual':<30} │ {'[Manual]':<16} │ Digitar Host ou IP avulso")

    for item in hosts:
        host = item["host"]
        grp = item["group"]
        cfg = item["config"]
        hostname = cfg.get("hostname", "")
        user = cfg.get("user", "")
        port = cfg.get("port", "")

        target = []
        if user:
            target.append(f"{user}@")
        if hostname:
            target.append(hostname)
        else:
            target.append(host)
        if port and port != "22":
            target.append(f":{port}")

        target_str = "".join(target)
        grp_str = f"[{grp}]"
        print(f"{host:<30} │ {grp_str:<16} │ {target_str}")

def preview_host(host_name, hosts):
    if host_name in ("+manual", "+"):
        print("CONEXÃO MANUAL / HOST AVULSO")
        print("=" * 45)
        print("Permite conectar diretamente digitando:")
        print(" - IP (ex: 192.168.1.50)")
        print(" - Hostname (ex: dev.meuservidor.com)")
        print(" - Usuário + IP (ex: ubuntu@10.0.0.5)")
        return

    for item in hosts:
        if item["host"] == host_name:
            cfg = item["config"]
            print(f"Host:          {item['host']}")
            print(f"Cliente/Grupo: {item['group']}")
            print(f"Arquivo:       {item['file']}")
            print("=" * 45)
            for k, v in cfg.items():
                if k.startswith("_"):
                    continue
                print(f"  {k:<14}: {v}")
            return
    print(f"Host '{host_name}' não encontrado.")

def main():
    hosts = get_all_hosts()
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "--json":
            print(json.dumps(hosts, indent=2))
        elif cmd == "--preview" and len(sys.argv) > 2:
            preview_host(sys.argv[2], hosts)
        elif cmd == "--list-names":
            for h in hosts:
                print(h["host"])
        else:
            print_fzf_lines(hosts)
    else:
        print_fzf_lines(hosts)

if __name__ == "__main__":
    main()
