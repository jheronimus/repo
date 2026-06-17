# Unofficial ES-DE APT Repository Builder for Debian Trixie

This repository contains a GitHub Actions workflow that automatically compiles **ES-DE (EmulationStation Desktop Edition)** from its official GitLab source code inside a native **Debian Trixie (13)** container, generates a Debian package (`.deb`) via CPack, and publishes the package to a self-hosted APT repository on **GitHub Pages**.

The repository updates weekly on a schedule, or can be triggered manually.

---

## 🛠️ Repository Contents

- `.github/workflows/build-and-deploy.yml` — The GHA workflow containing compilation, packaging, signing, indexing, and deployment logic.
- `index.html` — A beautifully-styled dark mode entry landing page served by GitHub Pages containing copy-paste installation instructions.

---

## 🚀 Setup Instructions

Follow these steps to host and run this repository in your own GitHub account:

### Step 1: Create a New GitHub Repository
1. Create a new **public** repository on GitHub (e.g., `repo`).
2. Push this folder to your repository:
   ```bash
   git init
   git checkout -b main
   git add .
   git commit -m "Initialize ES-DE repository builder"
   git remote add origin https://github.com/<your-username>/<repo-name>.git
   git push -u origin main
   ```

### Step 2: Generate a GPG Key
APT repositories require cryptographic signing so clients can verify packages.
1. Run this command locally on your machine to generate an unencrypted GPG key:
   ```bash
   gpg --batch --generate-key <<EOF
   Key-Type: RSA
   Key-Length: 4096
   Name-Real: ES-DE APT Builder
   Name-Email: builder@example.com
   Expire-Date: 0
   %no-ask-passphrase
   %commit
   EOF
   ```
2. Export the GPG **private key** as armor-encoded text (this will be added to GitHub Secrets):
   ```bash
   gpg --armor --export-secret-keys "ES-DE APT Builder"
   ```
   *Copy the output of this command.*

### Step 3: Configure GitHub Secrets & Permissions
1. In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions** and click **New repository secret**.
   - Name: `GPG_PRIVATE_KEY`
   - Value: *Paste the exported private key.*
2. Go to **Settings** > **Actions** > **General**.
   - Scroll down to **Workflow permissions**.
   - Select **Read and write permissions** (required for the bot to commit files to the `gh-pages` branch).
   - Click **Save**.

### Step 4: Configure GitHub Pages
1. Go to your repository's **Settings** > **Pages**.
2. Under **Build and deployment** > **Source**, select **GitHub Actions**.

### Step 5: Run the Initial Build
1. Go to the **Actions** tab in your GitHub repository.
2. Select **Build and Deploy ES-DE APT Repo** in the left sidebar.
3. Click **Run workflow** > **Run workflow** (this will trigger compilation).
4. The workflow will:
   - Compile the latest ES-DE release.
   - Package it as a `.deb` file.
   - Create a `gh-pages` branch.
   - Set up the repository index and sign it with your GPG key.
   - Publish it to your GitHub Pages URL: `https://<your-username>.github.io/<repo-name>/`.

---

## 💻 Installing ES-DE on Debian Trixie (13)

Once your GitHub Pages site is live, users (or your own HTPC host) can install ES-DE using standard `apt`:

```bash
# 1. Download the public key to authenticate packages
sudo wget -O /usr/share/keyrings/es-de-archive-keyring.gpg https://<your-username>.github.io/<repo-name>/public.gpg

# 2. Add the repository to sources.list
echo "deb [signed-by=/usr/share/keyrings/es-de-archive-keyring.gpg] https://<your-username>.github.io/<repo-name>/ trixie main" | sudo tee /etc/apt/sources.list.d/es-de.list

# 3. Install
sudo apt update
sudo apt install emulationstation-de
```

---

## 🔄 How Updates Work
- **Automated Check:** A cron job runs every Sunday at midnight (UTC) to check if the official ES-DE GitLab repository has a newer release tag than what is currently hosted in your APT repo.
- **Incremental Build:** If a new version is found, compilation is triggered inside a `debian:trixie` docker environment to compile, package, and commit the update.
- **Manual Overrides:** You can manually run the workflow at any time and set `force_build` to `true` to force a rebuild of the current version.
