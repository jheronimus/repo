#!/bin/sh
set -eu

echo "=== Initializing Alpine Package Pipeline ==="
apk update
apk add --no-cache alpine-sdk abuild tar curl bash make cmake samurai jq yq-go git

ROOT_DIR="$(pwd)"
KEY_NAME="jheronimus-82bae039.rsa"
KEY_PRIV="$ROOT_DIR/keys/$KEY_NAME"
KEY_PUB="$ROOT_DIR/keys/${KEY_NAME}.pub"

if [ ! -f "$KEY_PRIV" ]; then
  echo "Error: Private key $KEY_PRIV not found!" >&2
  exit 1
fi

mkdir -p /root/.abuild /etc/apk/keys /root/packages
cp "$KEY_PRIV" /root/.abuild/"$KEY_NAME"
cp "$KEY_PUB" /root/.abuild/"${KEY_NAME}.pub"
cp "$KEY_PUB" /etc/apk/keys/"${KEY_NAME}.pub"

cat << EOF > /root/.abuild/abuild.conf
PACKAGER_PRIVKEY="/root/.abuild/$KEY_NAME"
REPODEST="/root/packages"
EOF
cp /root/.abuild/abuild.conf /etc/abuild.conf

# Setup output directories for Alpine v3.24 repository
REPO_BASE="$ROOT_DIR/public/alpine/v3.24/main"
mkdir -p "$REPO_BASE/x86_64" "$REPO_BASE/aarch64" "$REPO_BASE/noarch"
cp "$KEY_PUB" "$ROOT_DIR/public/alpine/${KEY_NAME}.pub"

FORCE_BUILD="${FORCE_BUILD:-false}"
HOST_ARCH=$(apk --print-arch)
echo "Running on architecture: $HOST_ARCH"

echo "=== Processing Package Recipes ==="
for pkg_dir in "$ROOT_DIR"/packages/*; do
  [ -d "$pkg_dir" ] || continue
  recipe="$pkg_dir/recipe.yaml"
  [ -f "$recipe" ] || continue

  pkg_name=$(yq '.name' "$recipe")
  pkg_type=$(yq '.type' "$recipe")
  echo "--> Package: $pkg_name (Type: $pkg_type)"

  if [ "$pkg_type" = "fetch" ]; then
    source_type=$(yq '.source' "$recipe")
    if [ "$source_type" = "github" ]; then
      repo=$(yq '.repo' "$recipe")
      latest_tag=$(curl -sSL "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name // empty')
      if [ -z "$latest_tag" ]; then
        echo "Warning: Could not fetch latest release for $repo" >&2
        continue
      fi
      clean_ver=$(echo "$latest_tag" | sed 's/^v//')
      echo "  Latest upstream version: $clean_ver ($latest_tag)"

      # Check x86_64
      x86_asset_tmpl=$(yq '.assets.x86_64' "$recipe")
      if [ "$x86_asset_tmpl" != "null" ] && [ -n "$x86_asset_tmpl" ]; then
        asset_name=$(echo "$x86_asset_tmpl" | sed "s/{version}/$clean_ver/g")
        target_file="$REPO_BASE/x86_64/${pkg_name}-${clean_ver}.apk"
        if [ ! -f "$target_file" ] || [ "$FORCE_BUILD" = "true" ]; then
          echo "  Fetching x86_64 APK: $asset_name..."
          url="https://github.com/$repo/releases/download/$latest_tag/$asset_name"
          curl -fSL "$url" -o "$target_file" || echo "  Warning: failed to download $url"
        else
          echo "  x86_64 APK already up to date ($clean_ver)"
        fi
      fi

      # Check aarch64
      arm_asset_tmpl=$(yq '.assets.aarch64' "$recipe")
      if [ "$arm_asset_tmpl" != "null" ] && [ -n "$arm_asset_tmpl" ]; then
        asset_name=$(echo "$arm_asset_tmpl" | sed "s/{version}/$clean_ver/g")
        target_file="$REPO_BASE/aarch64/${pkg_name}-${clean_ver}.apk"
        if [ ! -f "$target_file" ] || [ "$FORCE_BUILD" = "true" ]; then
          echo "  Fetching aarch64 APK: $asset_name..."
          url="https://github.com/$repo/releases/download/$latest_tag/$asset_name"
          curl -fSL "$url" -o "$target_file" || echo "  Warning: failed to download $url"
        else
          echo "  aarch64 APK already up to date ($clean_ver)"
        fi
      fi
    fi

  elif [ "$pkg_type" = "build" ]; then
    apkbuild="$pkg_dir/APKBUILD"
    if [ ! -f "$apkbuild" ]; then
      echo "Warning: APKBUILD missing for build package $pkg_name" >&2
      continue
    fi

    # Read current pkgver from APKBUILD
    cur_ver=$(grep '^pkgver=' "$apkbuild" | cut -d= -f2)
    cur_rel=$(grep '^pkgrel=' "$apkbuild" | cut -d= -f2)
    target_ver="$cur_ver"

    source_type=$(yq '.source' "$recipe")
    if [ "$source_type" = "gitlab" ]; then
      repo=$(yq '.repo' "$recipe")
      encoded_repo=$(echo "$repo" | sed 's/\//%2F/g')
      latest_tag=$(curl -sSL "https://gitlab.com/api/v4/projects/$encoded_repo/releases" | jq -r '.[0].tag_name // empty')
      if [ -n "$latest_tag" ]; then
        upstream_ver=$(echo "$latest_tag" | sed 's/^v//')
        if [ "$upstream_ver" != "$cur_ver" ]; then
          echo "  Found new upstream version: $upstream_ver (was $cur_ver)"
          target_ver="$upstream_ver"
          sed -i "s/^pkgver=.*/pkgver=$target_ver/" "$apkbuild"
          sed -i "s/^pkgrel=.*/pkgrel=0/" "$apkbuild"
          cur_rel=0
        fi
      fi
    elif [ "$source_type" = "github" ]; then
      repo=$(yq '.repo' "$recipe")
      latest_tag=$(curl -sSL "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name // empty')
      if [ -n "$latest_tag" ]; then
        upstream_ver=$(echo "$latest_tag" | sed 's/^v//')
        if [ "$upstream_ver" != "$cur_ver" ]; then
          echo "  Found new upstream version: $upstream_ver (was $cur_ver)"
          target_ver="$upstream_ver"
          sed -i "s/^pkgver=.*/pkgver=$target_ver/" "$apkbuild"
          sed -i "s/^pkgrel=.*/pkgrel=0/" "$apkbuild"
          cur_rel=0
        fi
      fi
    fi

    # Check if target apk already exists in repository
    existing_apk=$(find "$REPO_BASE" -name "${pkg_name}-${target_ver}-r${cur_rel}.apk" 2>/dev/null | head -n 1)
    if [ -z "$existing_apk" ] || [ "$FORCE_BUILD" = "true" ]; then
      echo "  Building $pkg_name v${target_ver}-r${cur_rel}..."
      cd "$pkg_dir"
      
      # Install makedepends and depends explicitly
      makedeps=$(grep '^makedepends=' "$apkbuild" | cut -d= -f2- | tr -d '"' || true)
      if [ -n "$makedeps" ]; then
        apk add --no-cache $makedeps
      fi
      deps=$(grep '^depends=' "$apkbuild" | cut -d= -f2- | tr -d '"' || true)
      if [ -n "$deps" ]; then
        apk add --no-cache $deps
      fi

      abuild -F checksum
      abuild -F -k -d
      cd "$ROOT_DIR"

      # Copy built packages from /root/packages/
      mkdir -p /root/packages
      find /root/packages/ -name "${pkg_name}*.apk" -exec cp {} "$REPO_BASE/$HOST_ARCH/" \; 2>/dev/null || true
      find /root/packages/ -name "${pkg_name}*.apk" -exec cp {} "$REPO_BASE/noarch/" \; 2>/dev/null || true
    else
      echo "  Package $pkg_name v${target_ver}-r${cur_rel} already exists in repo. Skipping build."
    fi
  fi
done

echo "=== Indexing and Signing Repositories ==="
for dir in "$REPO_BASE"/*; do
  if [ -d "$dir" ] && ls "$dir"/*.apk >/dev/null 2>&1; then
    arch=$(basename "$dir")
    echo "  Generating APKINDEX for $arch..."
    cd "$dir"
    apk index --allow-untrusted -o APKINDEX.tar.gz *.apk
    abuild-sign -k "/root/.abuild/$KEY_NAME" APKINDEX.tar.gz
    cd "$ROOT_DIR"
  fi
done

# Copy web landing page to public root
if [ -f "$ROOT_DIR/index.html" ]; then
  cp "$ROOT_DIR/index.html" "$ROOT_DIR/public/index.html"
fi

echo "=== Alpine Repository Pipeline Complete ==="
