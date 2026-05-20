#!/bin/bash
# =============================================================================
# cert.sh — Certbot deploy hook (uses Certbot env vars for multi-domain support)
# Uploads renewed certificates to OCI Load Balancer using $RENEWED_DOMAINS
# and $RENEWED_LINEAGE set automatically by Certbot.
#
# Usage: called automatically by certbot via --deploy-hook
# Replace LB_ID, listener name, and backend set name with your values.
# =============================================================================

# ── Configuration ─────────────────────────────────────────────────────────────
OCI_CLI="/home/lalantha/.local/bin/oci"
LB_ID="ocid1.loadbalancer.oc1.ap-mumbai-1.YOUR_LB_OCID_HERE"
LISTENER_NAME="listener_lb_2024-1029-1603"
BACKEND_SET_NAME="bs_lb_2024-1029-1603"
CERT_DATE=$(date +"%Y-%m-%d")
# ──────────────────────────────────────────────────────────────────────────────

# Upload new certificate to OCI Load Balancer
$OCI_CLI lb certificate create \
  --load-balancer-id "$LB_ID" \
  --wait-for-state SUCCEEDED \
  --certificate-name "${RENEWED_DOMAINS}-${CERT_DATE}" \
  --ca-certificate-file  "${RENEWED_LINEAGE}/fullchain.pem" \
  --private-key-file     "${RENEWED_LINEAGE}/privkey.pem" \
  --public-certificate-file "${RENEWED_LINEAGE}/cert.pem"

# Update the HTTPS listener to use the new certificate
$OCI_CLI lb listener update --force \
  --load-balancer-id "$LB_ID" \
  --wait-for-state SUCCEEDED \
  --listener-name "$LISTENER_NAME" \
  --default-backend-set-name "$BACKEND_SET_NAME" \
  --port 443 \
  --protocol HTTP2 \
  --cipher-suite-name oci-default-http2-ssl-cipher-suite-v1 \
  --ssl-certificate-name "${RENEWED_DOMAINS}-${CERT_DATE}"
