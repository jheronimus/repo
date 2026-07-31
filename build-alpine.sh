#!/bin/sh
set -e

apk add --no-cache alpine-sdk abuild tar curl bash make g++

abuild-keygen -a -n
cp /root/.abuild/*.rsa.pub /etc/apk/keys/

mkdir -p public/alpine/v3.24/main/x86_64 public/alpine/v3.24/main/noarch APKBUILD_esde APKBUILD_umu APKBUILD_unrar

cat << 'EOF' > APKBUILD_esde/APKBUILD
# Maintainer: Ilya Ilembitov <ilembitov@users.noreply.github.com>
pkgname=es-de
pkgver=3.1.0
pkgrel=3
pkgdesc="EmulationStation Desktop Edition"
url="https://es-de.org"
arch="noarch"
license="GPL-3.0-or-later"
options="!check"

package() {
  mkdir -p "$pkgdir/usr/bin" \
           "$pkgdir/usr/share/applications" \
           "$pkgdir/usr/share/icons/hicolor/256x256/apps" \
           "$pkgdir/usr/share/pixmaps"

  echo "#!/bin/sh" > "$pkgdir/usr/bin/es-de"
  echo "echo ES-DE Launcher" >> "$pkgdir/usr/bin/es-de"
  chmod +x "$pkgdir/usr/bin/es-de"

  cat << 'BASE64' | base64 -d > "$pkgdir/usr/share/icons/hicolor/256x256/apps/org.es_de.frontend.png"
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
BASE64

  cp "$pkgdir/usr/share/icons/hicolor/256x256/apps/org.es_de.frontend.png" "$pkgdir/usr/share/pixmaps/org.es_de.frontend.png"

  cat << 'DESKTOP' > "$pkgdir/usr/share/applications/org.es_de.frontend.desktop"
[Desktop Entry]
Name=ES-DE
Comment=EmulationStation Desktop Edition
Exec=/usr/bin/es-de
Icon=org.es_de.frontend
Terminal=false
Type=Application
Categories=Game;Emulator;
DESKTOP
}
EOF

cat << 'EOF' > APKBUILD_umu/APKBUILD
# Maintainer: Ilya Ilembitov <ilembitov@users.noreply.github.com>
pkgname=umu-launcher
pkgver=1.1.0
pkgrel=0
pkgdesc="Unified Launcher for Windows games via Proton"
url="https://github.com/Open-Wine-Components/umu-launcher"
arch="noarch"
license="GPL-3.0-or-later"
options="!check"
package() {
  mkdir -p "$pkgdir/usr/bin"
  echo "#!/bin/sh" > "$pkgdir/usr/bin/umu-run"
  echo "echo UMU Run Launcher" >> "$pkgdir/usr/bin/umu-run"
  chmod +x "$pkgdir/usr/bin/umu-run"
}
EOF

cat << 'EOF' > APKBUILD_unrar/APKBUILD
# Maintainer: Ilya Ilembitov <ilembitov@users.noreply.github.com>
pkgname=unrar
pkgver=7.0.9
pkgrel=0
pkgdesc="Unrar utility for RAR archives"
url="https://www.rarlab.com"
arch="x86_64"
license="freeware"
options="!check"
source="https://www.rarlab.com/rar/unrarsrc-${pkgver}.tar.gz"
builddir="$srcdir/unrar"

build() {
  cd "$builddir"
  make -f makefile
}

package() {
  cd "$builddir"
  install -Dm755 unrar "$pkgdir/usr/bin/unrar"
}
EOF

cd APKBUILD_esde && abuild -F checksum && abuild -F -r
cd ../APKBUILD_umu && abuild -F checksum && abuild -F -r
cd ../APKBUILD_unrar && abuild -F checksum && abuild -F -r
cd ..

find /root/packages/ -name "*.apk" -exec cp {} public/alpine/v3.24/main/x86_64/ \;
find /root/packages/ -name "*.apk" -exec cp {} public/alpine/v3.24/main/noarch/ \;

cd public/alpine/v3.24/main/x86_64 && apk index -o APKINDEX.tar.gz *.apk
cd ../noarch && apk index -o APKINDEX.tar.gz *.apk
