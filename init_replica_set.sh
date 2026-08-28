#!/usr/bin/env bash
set -euo pipefail

: "${MONGO_ROOT_PW:?set MONGO_ROOT_PW env var first}"

script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$script_dir/infra/terraform"
private_ips_json=$(terraform output -json mongo_private_ips)
pub_ip=$(terraform output -json mongo_public_ips | python3 -c "import json,sys; print(next(iter(json.load(sys.stdin).values())))")
cd - >/dev/null

# node name -> private IP, ordered, becomes rs.initiate() member list
members=$(python3 -c "
import json
ips = json.loads('''$private_ips_json''')
print(','.join(f'{{_id:{i}, host:\"{ip}:27017\"}}' for i, ip in enumerate(v for _, v in sorted(ips.items()))))
")

# rs.status() fails with a non-zero exit until the set is initiated - use that to make this rerunnable
if mongosh --host "$pub_ip" --quiet --eval "rs.status().ok" >/dev/null 2>&1; then
  echo "replica set already initiated, skipping"
else
  mongosh --host "$pub_ip" --eval "rs.initiate({_id: 'rs0', members: [$members]})"
  sleep 5
  mongosh --host "$pub_ip" --eval "db.getSiblingDB('admin').createUser({user: 'root', pwd: '$MONGO_ROOT_PW', roles: ['root']})"
fi
