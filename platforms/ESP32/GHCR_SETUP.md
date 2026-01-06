# GHCR (GitHub Container Registry) Setup Guide

## Overview

The Jenkins pipeline can pull Docker images from GitHub Container Registry (GHCR). If the image is private, you need to configure credentials in Jenkins.

## Quick Setup

### Option 1: Make Image Public (Easiest)

1. Go to your GitHub repository
2. Navigate to **Packages** → `ats-node-test`
3. Click **Package settings**
4. Scroll to **Danger Zone** → **Change visibility** → **Make public**

### Option 2: Configure Jenkins Credentials (For Private Images)

#### Step 1: Create GitHub Personal Access Token

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Give it a name (e.g., "Jenkins GHCR Access")
4. Select scopes:
   - ✅ `read:packages` (to pull images)
   - ✅ `write:packages` (if you want to push images)
5. Click **Generate token**
6. **Copy the token** (you won't see it again!)

#### Step 2: Add Credentials to Jenkins

1. Go to Jenkins → **Manage Jenkins** → **Credentials**
2. Click **Add Credentials**
3. Fill in:
   - **Kind**: `Username with password`
   - **Scope**: `Global` (or specific)
   - **Username**: Your GitHub username
   - **Password**: The Personal Access Token from Step 1
   - **ID**: `ghcr-creds` (or any name you prefer)
   - **Description**: "GHCR credentials for ats-node-test"
4. Click **OK**

#### Step 3: Configure Pipeline

Set the environment variable in Jenkins:

1. Go to your Jenkins job → **Configure**
2. Under **Build Environment**, check **Use secret text(s) or file(s)**
3. Add binding:
   - **Variable**: `GHCR_CREDENTIALS_ID`
   - **Credentials**: Select the credential ID you created (e.g., `ghcr-creds`)

Or set it globally in Jenkins:

1. **Manage Jenkins** → **Configure System**
2. Under **Global properties** → **Environment variables**
3. Add:
   - **Name**: `GHCR_CREDENTIALS_ID`
   - **Value**: `ghcr-creds` (or your credential ID)

## How It Works

The pipeline will:

1. Check if `GHCR_CREDENTIALS_ID` environment variable is set
2. If set, login to GHCR using those credentials
3. Try to pull the image
4. If pull fails, fall back to building the image locally

## Testing

After setup, run the pipeline and check logs:

```
🔐 Attempting to login to GHCR with credentials...
Login Succeeded
✅ Image pulled successfully: ghcr.io/picopiece/ats-node-test:latest
```

## Troubleshooting

### "unauthorized" error

- Check if credentials ID is correct
- Verify token has `read:packages` scope
- Check if token is expired (tokens can expire)

### "Image not found"

- Verify image exists on GHCR
- Check if image supports your platform (arm64/amd64)
- Consider building multi-arch image (see below)

## Building Multi-Arch Images (Recommended)

To support both ARM64 (Raspberry Pi) and AMD64 (Xeon), build multi-arch image:

```bash
# On CI server (Xeon)
docker buildx create --use
docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --push \
  -t ghcr.io/picopiece/ats-node-test:latest \
  .
```

This ensures `docker pull` works on both platforms.

## References

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Jenkins Credentials Plugin](https://plugins.jenkins.io/credentials/)

