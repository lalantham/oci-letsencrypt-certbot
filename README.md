# OCI Let's Encrypt Certbot — Auto-renewal with OCI Load Balancer

Automates Let's Encrypt certificate issuance and renewal, uploading updated certs directly to an **OCI Load Balancer** via the OCI CLI deploy hook.

## Files

| File | Description |
|---|---|
| `oci-lb-deploy-hook-standalone.sh` | Deploy hook using hardcoded domain path (`/etc/letsencrypt/live/<domain>/`) |
| `oci-lb-deploy-hook-dynamic.sh` | Deploy hook using Certbot env vars (`$RENEWED_DOMAINS`, `$RENEWED_LINEAGE`) — better for automated renewal |

---

## Prerequisites

### 1. Install OCI CLI

Follow the official docs: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm

### 2. Install Certbot

**Ubuntu / Debian:**
```bash
apt install certbot python3-certbot-apache

```

**Oracle Linux:**

```bash
dnf install oracle-epel-release-el8 -y
dnf install snapd -y
systemctl enable snapd && systemctl start snapd
snap install core && snap refresh core
ln -s /var/lib/snapd/snap /snap
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

```

---

## Setup

### 1. Edit the configuration block in each script

Open `oci-lb-deploy-hook-standalone.sh` and/or `oci-lb-deploy-hook-dynamic.sh` and update the variables at the top:

```bash
OCI_CLI="/home/youruser/.local/bin/oci"   # path to oci binary
LB_ID="ocid1.loadbalancer.oc1.ap-mumbai-1.YOUR_LB_OCID_HERE"
LISTENER_NAME="https-listener"            # your HTTPS listener name
BACKEND_SET_NAME="https-listener"         # your backend set name
DOMAIN="your.domain.com"                  # your domain (oci-lb-deploy-hook-standalone.sh only)

```

### 2. Make scripts executable

```bash
chmod +x oci-lb-deploy-hook-standalone.sh oci-lb-deploy-hook-dynamic.sh

```

---

## Requesting a Certificate

**Standalone mode** (stops any running web server temporarily):

```bash
certbot certonly --standalone -d your.domain.com \
  --deploy-hook /path/to/oci-lb-deploy-hook-standalone.sh

```

**Webroot mode** (web server stays running):

```bash
certbot certonly --webroot -w /var/www/html/web -d your.domain.com \
  --deploy-hook /path/to/oci-lb-deploy-hook-dynamic.sh --force-renewal

```

**Manual DNS challenge** (for wildcard certs or no port 80):

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d your.domain.com --deploy-hook /path/to/oci-lb-deploy-hook-dynamic.sh

```

---

## Automated Renewal (Cron)

Let's Encrypt certs are valid for **90 days**. Add a cron job to renew automatically:

```bash
crontab -e

```

Add this line (runs at midnight on the 1st of every month):

```
0 0 1 * * certbot renew --standalone --deploy-hook /path/to/oci-lb-deploy-hook-dynamic.sh

```

Adjust the schedule as needed. The deploy hook only runs when a certificate is actually renewed.

---

## How It Works

1. Certbot renews the certificate from Let's Encrypt
2. On success, Certbot calls the deploy hook script
3. The script uploads the new cert to OCI LB via `oci lb certificate create`
4. The script updates the HTTPS listener via `oci lb listener update` to use the new cert

### Difference between `oci-lb-deploy-hook-standalone.sh` and `oci-lb-deploy-hook-dynamic.sh`

|  | `oci-lb-deploy-hook-standalone.sh` | `oci-lb-deploy-hook-dynamic.sh` |
| --- | --- | --- |
| Domain path | Hardcoded (`/etc/letsencrypt/live/<domain>/`) | Uses `$RENEWED_LINEAGE` (set by Certbot) |
| Cert name | `<domain>-<date>` | `$RENEWED_DOMAINS-<date>` |
| Best for | Manual one-off runs | Automated `certbot renew` cron |

```
