# Alpine Linux Custom APK Repository

Automated build pipeline and upstream release mirror for Alpine Linux packages (`soft-serve`, `es-de`, `umu-launcher`, `unrar`).

## Repository Structure

```
repo/
  .github/workflows/
    daily-sync.yml          # Daily cron job (00:00 UTC) to check, build & publish
  packages/
    soft-serve/             # Upstream APK release mirror
      recipe.yaml
    es-de/                  # Source build from GitLab releases
      recipe.yaml
      APKBUILD
    umu-launcher/           # Upstream zipapp tarball (noarch)
      recipe.yaml
      APKBUILD
    unrar/                  # RARLAB source build
      recipe.yaml
      APKBUILD
  keys/
    jheronimus-82bae039.rsa      # Package signing private key
    jheronimus-82bae039.rsa.pub  # Public verification key
  scripts/
    build-all.sh            # Pipeline engine inside Alpine container
  index.html                # Repository web landing page
```

## Adding to Alpine Linux

```sh
# 1. Trust public signing key
wget -O /etc/apk/keys/jheronimus-82bae039.rsa.pub https://jheronimus.github.io/repo/alpine/jheronimus-82bae039.rsa.pub

# 2. Add repository URL
echo "https://jheronimus.github.io/repo/alpine/v3.24/main" >> /etc/apk/repositories

# 3. Update index and install packages
apk update
apk add soft-serve es-de umu-launcher unrar
```

## Adding a New Package

1. Create `packages/<name>/recipe.yaml`:
   - For binary fetch:
     ```yaml
     name: mypkg
     type: fetch
     source: github
     repo: owner/mypkg
     assets:
       x86_64: mypkg_{version}_x86_64.apk
       aarch64: mypkg_{version}_aarch64.apk
     ```
   - For source build:
     ```yaml
     name: mypkg
     type: build
     source: github # or gitlab
     repo: owner/mypkg
     arch:
       - x86_64
     ```
     and provide a standard `APKBUILD`.
2. The daily sync workflow will automatically detect new releases, build/fetch the APKs, update `APKINDEX.tar.gz`, and publish to GitHub Pages.
