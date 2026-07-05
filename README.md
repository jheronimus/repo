# Unofficial ES-DE APT repo for Debian Trixie

## Installing ES-DE on Debian Trixie (13)

```bash
# 1. Download the public key to authenticate packages
sudo wget -O /usr/share/keyrings/es-de-archive-keyring.gpg https://<your-username>.github.io/<repo-name>/public.gpg

# 2. Add the repository to sources.list
echo "deb [signed-by=/usr/share/keyrings/es-de-archive-keyring.gpg] https://<your-username>.github.io/<repo-name>/ ./" | sudo tee /etc/apt/sources.list.d/es-de.list

# 3. Install
sudo apt update
sudo apt install es-de
```
