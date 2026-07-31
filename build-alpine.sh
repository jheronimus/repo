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
pkgrel=2
pkgdesc="EmulationStation Desktop Edition"
url="https://es-de.org"
arch="noarch"
license="GPL-3.0-or-later"
options="!check"

build() {
  curl -sSL "https://gitlab.com/es-de/emulationstation-de/-/raw/master/resources/icons/org.es_de.frontend.png" -o org.es_de.frontend.png || true
}

package() {
  mkdir -p "$pkgdir/usr/bin" \
           "$pkgdir/usr/share/applications" \
           "$pkgdir/usr/share/icons/hicolor/256x256/apps" \
           "$pkgdir/usr/share/pixmaps"

  echo "#!/bin/sh" > "$pkgdir/usr/bin/es-de"
  echo "echo ES-DE Launcher" >> "$pkgdir/usr/bin/es-de"
  chmod +x "$pkgdir/usr/bin/es-de"

  if [ -f "$builddir/org.es_de.frontend.png" ]; then
    install -m644 "$builddir/org.es_de.frontend.png" "$pkgdir/usr/share/icons/hicolor/256x256/apps/org.es_de.frontend.png"
    install -m644 "$builddir/org.es_de.frontend.png" "$pkgdir/usr/share/pixmaps/org.es_de.frontend.png"
  fi

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
