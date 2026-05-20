#!/bin/bash
# =============================================================================
# script.sh — Certbot deploy hook
# Uploads renewed Let's Encrypt certificates to OCI Load Balancer
#
# Usage: called automatically by certbot via --deploy-hook
# Replace LB_ID, listener name, and backend set name with your values.
# =============================================================================

# ── Configuration ─────────────────────────────────────────────────────────────
OCI_CLI="/home/lalantha/.local/bin/oci"
LB_ID="ocid1.loadbalancer.oc1.ap-mumbai-1.YOUR_LB_OCID_HERE"
LISTENER_NAME="https-listener"
BACKEND_SET_NAME="https-listener"
DOMAIN="web.lalantha.com"
CERT_DATE=$(date +"%Y-%m-%d")
# ──────────────────────────────────────────────────────────────────────────────

# Upload new certificate to OCI Load Balancer
$OCI_CLI lb certificate create \
  --load-balancer-id "$LB_ID" \
  --wait-for-state SUCCEEDED \
  --certificate-name "${DOMAIN}-${CERT_DATE}" \
  --ca-certificate-file  "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" \
  --private-key-file     "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" \
  --public-certificate-file "/etc/letsencrypt/live/${DOMAIN}/cert.pem"

# Update the HTTPS listener to use the new certificate
$OCI_CLI lb listener update --force \
  --load-balancer-id "$LB_ID" \
  --wait-for-state SUCCEEDED \
  --listener-name "$LISTENER_NAME" \
  --default-backend-set-name "$BACKEND_SET_NAME" \
  --port 443 \
  --protocol HTTP2 \
  --cipher-suite-name oci-default-http2-ssl-cipher-suite-v1 \
  --ssl-certificate-name "${DOMAIN}-${CERT_DATE}"
