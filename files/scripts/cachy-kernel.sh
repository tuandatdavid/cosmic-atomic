#!/usr/bin/env bash

dnf -y remove \
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
