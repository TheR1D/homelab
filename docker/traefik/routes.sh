#!/bin/sh
set -eu

# Load environment variables from .env if exists
SCRIPT_DIR="$(dirname "$0")"
[ -f "$SCRIPT_DIR/../.env" ] && . "$SCRIPT_DIR/../.env"
OUTPUT_DIR="${OUTPUT_DIR:-/srv/docker-data/traefik/dynamic}"

# Fetch static DHCP leases from MikroTik router API
# Sanitize comment: lowercase, spaces→hyphens, remove invalid chars
# Output format: "hostname:ip_address" per line
HOSTS=$(curl -ksS -u "$ROUTER_USERNAME:$ROUTER_PASSWORD" \
  "http://$ROUTER_IP/rest/ip/dhcp-server/lease?dynamic=false" \
  | tr -d '\r' \
  | jq -r '.[] | select(.comment != null and .comment != "") |
    (.comment | ascii_downcase | gsub(" "; "-") | gsub("[^a-z0-9-]"; "")) + ":" + .address')

# Initialize valid hosts tracking file
: > "$OUTPUT_DIR/.valid_hosts"

# Generate Traefik dynamic config for each host
for entry in $HOSTS; do
  # Split "hostname:ip" into separate variables
  host="${entry%%:*}" addr="${entry#*:}"
  echo "$host" >> "$OUTPUT_DIR/.valid_hosts"

  # Write Traefik config (routes subdomain to host IP)
  cat > "$OUTPUT_DIR/${host}.yml.tmp" <<EOF
http:
  routers:
    ${host}:
      rule: "Host(\`${host}.${DOMAIN}\`)"
      entryPoints: [websecure]
      service: ${host}
      tls: {certResolver: cloudflare}
  services:
    ${host}:
      loadBalancer:
        servers: [{url: "http://${addr}"}]
EOF

  # Only update if content changed (atomic write via tmp file)
  if ! cmp -s "$OUTPUT_DIR/${host}.yml.tmp" "$OUTPUT_DIR/${host}.yml" 2>/dev/null; then
    mv "$OUTPUT_DIR/${host}.yml.tmp" "$OUTPUT_DIR/${host}.yml"
    echo "Updated: ${host}.${DOMAIN} -> ${addr}"
  else
    rm "$OUTPUT_DIR/${host}.yml.tmp"
  fi
done

# Remove configs for hosts no longer in DHCP leases
for f in "$OUTPUT_DIR"/*.yml; do
  [ -f "$f" ] && ! grep -qx "$(basename "$f" .yml)" "$OUTPUT_DIR/.valid_hosts" 2>/dev/null && rm -v "$f"
done

# Cleanup tracking file
rm -f "$OUTPUT_DIR/.valid_hosts"
