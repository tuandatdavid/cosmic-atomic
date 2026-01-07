#!/usr/bin/env bash
# create a shims to bypass kernel install triggering dracut/rpm-ostree
# seems to be minimal impact, but allows progress on build
pushd /usr/lib/kernel/install.d
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd
dnf5 -y remove \
    kernel \
    kernel-* &&
    rm -r -f /usr/lib/modules/*

# Enable repos
dnf5 -y copr enable bieszczaders/kernel-cachyos-lto

dnf5 -y install --setopt=install_weak_deps=false \
    kernel-cachyos-lto kernel-cachyos-lto-devel-matched

# Clean up repos from earlier
rm -f /etc/yum.repos.d/{*copr*}

setsebool -P domain_kernel_load_modules on
