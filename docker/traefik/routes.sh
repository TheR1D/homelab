#!/bin/sh
set -eu

# Load environment variables from .env if exists
SCRIPT_DIR="$(dirname "$0")"
[ -f "$SCRIPT_DIR/../.env" ] && . "$SCRIPT_DIR/../.env"
OUTPUT_DIR="${OUTPUT_DIR:-/srv/docker-data/traefik/dynamic}"

# Fetch static DHCP leases from MikroTik router API
# Comment format: "hostname" or "hostname:port" (e.g., proxmox:8006)
# Output format: "hostname:port:ip_address" per line (port defaults to 80)
HOSTS=$(curl -ksS -u "$ROUTER_USERNAME:$ROUTER_PASSWORD" \
  "http://$ROUTER_IP/rest/ip/dhcp-server/lease?dynamic=false" \
  | tr -d '\r' \
  | jq -r '.[] | select(.comment != null and .comment != "") |
    (.comment | split(":") | if length > 1 then .[1] else "80" end) as $port |
    (.comment | split(":")[0] | ascii_downcase | gsub(" "; "-") | gsub("[^a-z0-9-]"; "")) + ":" + $port + ":" + .address')

# Check if server accepts HTTPS (returns "https" or "http")
check_scheme() {
  if curl -ksSo /dev/null --connect-timeout 2 "https://$1:$2" 2>/dev/null; then
    echo "https"
  else
    echo "http"
  fi
}

# Initialize valid hosts tracking file
: > "$OUTPUT_DIR/.valid_hosts"

# Generate Traefik dynamic config for each host
for entry in $HOSTS; do
  # Split "hostname:port:ip" into separate variables
  host="${entry%%:*}"; rest="${entry#*:}"; port="${rest%%:*}"; addr="${rest#*:}"
  echo "$host" >> "$OUTPUT_DIR/.valid_hosts"

  # Detect HTTP or HTTPS
  scheme=$(check_scheme "$addr" "$port")

  # Write Traefik config (routes subdomain to host IP:port)
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
        servers: [{url: "${scheme}://${addr}:${port}"}]
EOF

  # Only update if content changed (atomic write via tmp file)
  if ! cmp -s "$OUTPUT_DIR/${host}.yml.tmp" "$OUTPUT_DIR/${host}.yml" 2>/dev/null; then
    mv "$OUTPUT_DIR/${host}.yml.tmp" "$OUTPUT_DIR/${host}.yml"
    echo "Updated: ${host}.${DOMAIN} -> ${scheme}://${addr}:${port}"
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
