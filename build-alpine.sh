#!/bin/sh
set -e

apk update
apk add --no-cache alpine-sdk abuild tar curl bash make g++ cmake

# Use static key generated and committed to the repo
mkdir -p /root/.abuild /etc/apk/keys
cp jheronimus.rsa /root/.abuild/jheronimus.rsa
cp jheronimus.rsa.pub /root/.abuild/jheronimus.rsa.pub
cp jheronimus.rsa.pub /etc/apk/keys/jheronimus.rsa.pub
echo 'PACKAGER_PRIVKEY="/root/.abuild/jheronimus.rsa"' > /etc/abuild.conf

mkdir -p public/alpine/v3.24/main/x86_64 public/alpine/v3.24/main/noarch APKBUILD_esde APKBUILD_umu APKBUILD_unrar

cat << 'EOF' > APKBUILD_esde/APKBUILD
# Maintainer: Ilya Ilembitov <ilembitov@users.noreply.github.com>
pkgname=es-de
pkgver=3.1.0
pkgrel=4
pkgdesc="EmulationStation Desktop Edition"
url="https://es-de.org"
arch="x86_64 aarch64"
license="MIT"
makedepends="cmake samurai curl-dev ffmpeg-dev freeimage-dev freetype-dev harfbuzz-dev icu-dev gettext-dev libgit2-dev pugixml-dev sdl2-dev alsa-lib-dev bluez-dev eudev-dev poppler-dev"
options="!check"
source="${pkgname}-${pkgver}.tar.gz::https://gitlab.com/es-de/emulationstation-de/-/archive/v${pkgver}/emulationstation-de-v${pkgver}.tar.gz"
builddir="$srcdir/emulationstation-de-v${pkgver}"

build() {
  cmake -B build \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build
}

package() {
  DESTDIR="$pkgdir" cmake --install build
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

# Export the public key to the web root so clients can download and trust it
cp jheronimus.rsa.pub public/alpine/jheronimus.rsa.pub

cd public/alpine/v3.24/main/x86_64 && apk index -o APKINDEX.tar.gz *.apk && abuild-sign -k /root/.abuild/jheronimus.rsa APKINDEX.tar.gz
cd ../noarch && apk index -o APKINDEX.tar.gz *.apk && abuild-sign -k /root/.abuild/jheronimus.rsa APKINDEX.tar.gz

