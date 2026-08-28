#!/usr/bin/env bash
# rebuilds inventory.ini from terraform outputs - run after every `terraform apply`
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
tmp_json="$script_dir/.instance_ids.json"

cd "$script_dir/../terraform"
key_path=$(terraform output -raw ssh_private_key_path)
terraform output -json mongo_public_ips > "$tmp_json"
cd - >/dev/null

python3 - "$key_path" "$tmp_json" "$script_dir/inventory.ini" <<'EOF'
import json
import sys

key_path, tmp_json, out_path = sys.argv[1:4]

with open(tmp_json) as f:
    ips = json.load(f)

with open(out_path, "w") as f:
    f.write("[mongo]\n")
    for name, public_ip in ips.items():
        f.write(
            f"{name} ansible_host={public_ip} "
            f"ansible_user=ec2-user "
            f"ansible_ssh_private_key_file={key_path}\n"
        )
EOF

rm -f "$tmp_json"
echo "inventory.ini regenerated"
