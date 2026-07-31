#!/bin/sh
set -e

apk add --no-cache alpine-sdk abuild tar curl bash
abuild-keygen -a -n
cp /root/.abuild/*.rsa.pub /etc/apk/keys/

mkdir -p public/alpine/v3.24/main/x86_64 public/alpine/v3.24/main/noarch APKBUILD_esde APKBUILD_umu

cat << 'EOF' > APKBUILD_esde/APKBUILD
# Maintainer: Ilya Ilembitov <ilembitov@users.noreply.github.com>
pkgname=es-de
pkgver=3.1.0
pkgrel=0
pkgdesc="EmulationStation Desktop Edition"
url="https://es-de.org"
arch="noarch"
license="GPL-3.0-or-later"
options="!check"
package() {
  mkdir -p "$pkgdir/usr/bin"
  echo "#!/bin/sh" > "$pkgdir/usr/bin/es-de"
  echo "echo ES-DE Launcher" >> "$pkgdir/usr/bin/es-de"
  chmod +x "$pkgdir/usr/bin/es-de"
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

cd APKBUILD_esde && abuild -F checksum && abuild -F -r
cd ../APKBUILD_umu && abuild -F checksum && abuild -F -r
cd ..

find /root/packages/ -name "*.apk" -exec cp {} public/alpine/v3.24/main/x86_64/ \;
find /root/packages/ -name "*.apk" -exec cp {} public/alpine/v3.24/main/noarch/ \;

cd public/alpine/v3.24/main/x86_64 && apk index -o APKINDEX.tar.gz *.apk
cd ../noarch && apk index -o APKINDEX.tar.gz *.apk
