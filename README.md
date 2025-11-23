# cosmic-atomic &nbsp; [![bluebuild build badge](https://github.com/tuandatdavid/cosmic-atomic/actions/workflows/build.yml/badge.svg)](https://github.com/tuandatdavid/cosmic-atomic/actions/workflows/build.yml)
See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

This basically copies everything around it to be cosmic but with dx.

## Credits:
- Sparkrai's bluebuild implementation of [Bazzite-dx](https://github.com/Sparkrai/bazzite-dx)
- Bluebuild maintainers for their base [images](https://github.com/blue-build/base-images)
- [Universal Blue](universal-blue.org)
## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/tuandatdavid/cosmic-atomic:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/tuandatdavid/cosmic-atomic:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/tuandatdavid/cosmic-atomic
```
