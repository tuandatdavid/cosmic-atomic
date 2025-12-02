say-hello ACTION="":
  #!/usr/bin/env bash
  echo hello
# vim: set ft=make :
########################
### bluefin-apps.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

alias cockpit := setup-cockpit

# Enable Cockpit for web-based system management | https://cockpit-project.org/
setup-cockpit ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    COCKPIT_SERVICE_STATUS="$(systemctl is-enabled cockpit.service)"
    if [ "$COCKPIT_SERVICE_STATUS" == "enabled" ]; then
      COCKPIT_SERVICE_STATUS="${green}${b}Enabled${n}"
    elif [ "$COCKPIT_SERVICE_STATUS" == "disabled" ]; then
      COCKPIT_SERVICE_STATUS="${red}${b}Disabled${n}"
    else
      COCKPIT_SERVICE_STATUS="${invert}${b}Not Installed${n}"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust setup-cockpit <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'install' to select Install Cockpit"
      echo "  Use 'enable' to select Enable Cockpit"
      echo "  Use 'disable' to select Disable Cockpit"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}Cockpit Setup${normal}"
      echo "Cockpit service is currently: $COCKPIT_SERVICE_STATUS"
      if [[ "${COCKPIT_SERVICE_STATUS}" =~ "Not Installed" ]]; then
        OPTION=$(Choose "Install Cockpit" "Cancel")
      else
        OPTION=$(Choose "Enable Cockpit" "Disable Cockpit")
      fi
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
      echo 'Installing Cockpit'
      echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
      sudo systemctl try-restart sshd
      sudo systemctl enable --now sshd
      sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
      sudo podman container runlabel INSTALL quay.io/cockpit/ws
      OPTION="Enable Cockpit"
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
      echo "${green}${b}Enabling${n} pmlogger"
      sudo mkdir /var/lib/pcp/tmp
      sudo mkdir /var/log/pcp/pmlogger
      sudo chown -R pcp:pcp /var/lib/pcp
      sudo chown pcp:pcp /var/log/pcp/pmlogger
      sudo systemctl enable --now pmlogger
      echo "${green}${b}Enabling${n} Cockpit"
      sudo systemctl enable cockpit.service
      echo "$(Urllink "http://localhost:9090" "Open Cockpit${n}") -> http://localhost:9090"
    elif [[ "${OPTION,,}" =~ ^disable ]]; then
      echo "${red}${b}Disabling${n} Cockpit"
      sudo systemctl disable cockpit.service
      echo "Cockpit has been ${b}${red}disabled${n}"
    fi

alias jetbrains-toolbox := install-jetbrains-toolbox

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
install-jetbrains-toolbox:
    #!/usr/bin/env bash
    pushd "$(mktemp -d)"
    echo "Get latest JetBrains Toolbox version"
    # Get the json with latest releases
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    # Extract information
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    echo "Launching JetBrains Toolbox"
    ./jetbrains-toolbox-"${BUILD_VERSION}"/jetbrains-toolbox

alias atuin := install-atuin

# Add atuin
install-atuin:
    #!/usr/bin/bash 
    shell=$(basename $SHELL) 
    if test $shell = "fish"; then 
        echo "Adding atuin to your config.fish"
        printf '\nif status is-interactive\n\tif type -q atuin\n\t\tatuin init fish | source\n\tend\nend\n' >> ${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish
    elif test $shell = "zsh"; then 
        echo "Adding atuin to your .zshrc"
        printf '\n[[ "$(command -v atuin)" ]] && eval "$(atuin init zsh)"\n' >> ${ZDOTDIR:-$HOME}/.zshrc 
    elif test $shell = "bash"; then 
        echo "Adding bash-prexec and atuin to your .bashrc" 
        printf '\n[[ -f /usr/share/bash-prexec ]] && source /usr/share/bash-prexec\n[[ "$(command -v atuin)" ]] && eval "$(atuin init bash)"\n' >> ~/.bashrc
    fi

alias incus := install-incus

# Install and configure Incus
install-incus:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -Eq "bluefin-dx|aurora-dx" <<< $CURRENT_IMAGE
    then
        echo 'Installing and configuring Incus.'
        /usr/libexec/bluefin-incus
    else
        echo "Developer mode is currently ${b}${red}Disabled${n}."
        echo "Run \"just devmode\" to turn on Developer mode."
        exit
    fi
# vim: set ft=make :
########################
### bluefin-system.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run a one minute system benchmark
benchmark:
    echo 'Running a 1 minute benchmark ...'
    cd /tmp && stress-ng --matrix 0 -t 1m --times

# Configure Bluefin-CLI Terminal Experience with Brew
bluefin-cli:
    @brew bundle --file /usr/share/ublue-os/homebrew/bluefin-cli.Brewfile --no-lock
    echo 'Installation complete ... please close and reopen your terminal!'

# Configure Bluefin-CLI Terminal Experience
[private]
bluefin-cli-container:
    @/usr/libexec/enable-bluefin-cli.sh

# Configure Terminal Experience
[private]
configure-terminal:
    @/usr/libexec/configure-terminal.sh

# Toggle between Bazzite and the Bluefin-like Developer Experience
devmode:
    #!/usr/bin/env bash
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "/var/ublue-os/image" <<< $CURRENT_IMAGE
    then
        echo ""
        echo "Before we can switch to the Bazzite Developer Experience"
        echo "the current system needs an update. Please run 'just update'"
        echo "and reboot your system when the update is finished."
        exit
    fi
    if grep -q "dx" <<< $CURRENT_IMAGE
    then
        CURRENT_STATE="enabled"
    else
        CURRENT_STATE="disabled"
    fi
    echo "Developer mode is currently ${CURRENT_STATE}"
    echo "Enable or Disable developer mode"
    OPTION=$(gum choose Enable Disable)
    if [ "$OPTION" = "Enable" ]
    then
        if [ "$CURRENT_STATE" = "enabled" ]
        then
            echo "You are already on a developer image"
        else
            echo "Rebasing to a developer image"
            NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/ublue-os\/bazzite/sparkrai\/bazzite-dx/")
            rpm-ostree rebase $NEW_IMAGE
        fi
    elif [ "$OPTION" = "Disable" ]
    then
        if [ "$CURRENT_STATE" = "enabled" ]
        then
            echo "Rebasing to a non developer image"
            NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/sparkrai\/bazzite-dx/ublue-os\/bazzite/")
            rpm-ostree rebase $NEW_IMAGE
        else
            echo "You are currently not on a developer image"
        fi
    fi
# Switch to a different shell
configure-shell ACTION="":
    #!/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_SHELL="$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust shell <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'fish' to select fish"
      echo "  Use 'zsh' to select zsh"
      echo "  Use 'bash' to select bash"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}Shell configuration${normal}"
      echo "${USER}'s shell is currently ${CURRENT_SHELL}"
      OPTION=$(Choose "fish" "zsh" "bash")
    fi
    if [ -z "$OPTION" ]; then
      exit 0
    else
      sudo usermod $USER --shell /usr/bin/$OPTION 
      printf "${USER}'s shell is now %s.\n" "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"
    fi

alias gnome-vrr := toggle-gnome-vrr

# Enable or Disable Gnome-VRR
toggle-gnome-vrr:
    #!/usr/bin/env bash
    if gsettings get org.gnome.mutter experimental-features | grep -q "variable-refresh-rate"
    then
      CURRENT_STATE="Enabled"
    else
      CURRENT_STATE="Disabled"
    fi
    echo "Gnome-VRR is currently ${CURRENT_STATE}"
    echo "Enable or Disable Gnome-VRR"
    OPTION=$(gum choose Enable Disable)
    if [ "$OPTION" = "Enable" ]
    then
      echo "Enabling Gnome-VRR"
      gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate','scale-monitor-framebuffer']"
    elif [ "$OPTION" = "Disable" ]
    then
      echo "Disabling Gnome-VRR"
      gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
    fi
    echo "To apply the changes make sure you logout and restart your session"

# Ptyxis terminal transparency
ptyxis-transparency opacity="0.95":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
      printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>={{ opacity }}" | bc -q) -eq 1 ]]; then
      raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
      uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
      for i in ${uuids}; do
        location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
        gsettings set "${location}" opacity "{{ opacity }}"; done
      printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
      printf "Value must be greater than 0 and less than or equal to 1: %s.\n" "{{ opacity }}"
    fi

# Configure docker,incus-admin,lxd,libvirt container manager permissions
dx-group:
    sudo usermod -aG docker $USER
    sudo usermod -aG incus-admin $USER
    sudo usermod -aG lxd $USER
    sudo usermod -aG libvirt $USER
    @echo "Logout to use docker, incus-admin, lxd, libvirt"

# Configure system to use vfio and kvmfr
configure-vfio ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "dx" <<< $CURRENT_IMAGE
    then
      DEVMODE="enabled"
    else
      DEVMODE="disabled"
    fi
    if [ "$DEVMODE" == "disabled" ]; then
      echo 'Please run "ujust devmode" first'
      exit 0
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust configure-vfio <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'vfio-on' to select Enable VFIO drivers"
      echo "  Use 'vfio-off' to select Disable VFIO drivers"
      echo "  Use 'kvmfr' to select Autocreate Looking-Glass shm"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}VFIO and kvmfr Configuration${normal}"
      echo "This is only used for GPU passthrough of a secondary dGPU."
      echo "It will enable vfio and configure kvmfr for use with $(Urllink "https://looking-glass.io" "Looking Glass")"
      echo "If you do not plan to use any of this then press ESC."
      echo "${bold}NOTE:${normal} Since this is a niche use case, support will be ${b}very limited${n}"
      OPTION=$(Choose \
        "Enable VFIO drivers" \
        "Disable VFIO drivers" \
        "Enable kvmfr module" \
      )
    fi
    if [[ "${OPTION,,}" =~ (^enable[[:space:]]vfio|vfio-on) ]]; then
      echo "Enabling VFIO..."
      VIRT_TEST=$(rpm-ostree kargs)
      CPU_VENDOR=$(grep "vendor_id" "/proc/cpuinfo" | uniq | awk -F": " '{ print $2 }')
      VENDOR_KARG="unset"
      if [[ ${VIRT_TEST} == *kvm.report_ignored_msrs* ]]; then
        echo 'add_drivers+=" vfio vfio_iommu_type1 vfio-pci "' | sudo tee /etc/dracut.conf.d/vfio.conf
        rpm-ostree initramfs --enable
        if [[ ${CPU_VENDOR} == "AuthenticAMD" ]]; then
          VENDOR_KARG="amd_iommu=on"
        elif [[ ${CPU_VENDOR} == "GenuineIntel" ]]; then
          VENDOR_KARG="intel_iommu=on"  
        fi
        if [[ ${VENDOR_KARG} == "unset" ]]; then
          echo "Failed to get CPU vendor, exiting..."
          exit 1
        else
          rpm-ostree kargs \
            --append-if-missing="${VENDOR_KARG}" \
            --append-if-missing="iommu=pt" \
            --append-if-missing="rd.driver.pre=vfio_pci" \
            --append-if-missing="vfio_pci.disable_vga=1"
          echo "VFIO will be enabled on next boot, make sure you enable IOMMU, VT-d or AMD-v in your BIOS!"
          echo "Please understand that since this is such a niche use case, support will be very limited!"
          echo "To add your unused/second GPU device ids to the vfio driver by running"
          echo 'rpm-ostree kargs --append-if-missing="vfio-pci.ids=xxxx:yyyy,xxxx:yyzz"'
          echo "NOTE: Your second GPU will not be usable by the host after you do this!"
        fi
      fi
    elif [[ "${OPTION,,}" =~ (^disable[[:space:]]vfio|vfio-off) ]]; then
      echo ""
      echo "Make sure you have ${b}disabled autostart of all VMs using VFIO${n} before continuing!"
      CONFIRM=$(Choose Cancel Continue)
      if [ "$CONFIRM" == "Continue" ]; then
        echo "Disabling VFIO..."
        VFIO_IDS="$(rpm-ostree kargs | sed -E 's/.+(vfio_pci.ids=.+\s)/\1/' | awk '{ print $1 }' | grep vfio_pci.ids)"
        VFIO_IDS_KARG=""
        if [ -n "$VFIO_IDS" ]; then
          echo "Found VFIO ids in kargs, adding the below line to removal list"
          echo "$VFIO_IDS"
          VFIO_IDS_KARG="--delete-if-present=\"$VFIO_IDS\""
        fi
        echo "Removing dracut modules"
        sudo rm /etc/dracut.conf.d/vfio.conf
        rpm-ostree initramfs --enable
        rpm-ostree kargs \
        --delete-if-present="iommu=pt" \
        --delete-if-present="iommu=on" \
        --delete-if-present="amd_iommu=on" \
        --delete-if-present="intel_iommu=on" \
        --delete-if-present="rd.driver.pre=vfio_pci" \
        --delete-if-present="vfio_pci.disable_vga=1" \
        --delete-if-present="vfio_pci.disable_vga=0" \
        $VFIO_IDS_KARG
      fi
    elif [[ "${OPTION,,}" =~ kvmfr ]]; then
      sudo /usr/libexec/bluefin-dx-kvmfr-setup
    fi

# Install system flatpaks for rebasers
[private]
install-system-flatpaks:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
        FLATPAKS="bluefin_flatpaks/flatpaks"
    elif [[ ${BASE_IMAGE_NAME} == 'kinoite' ]]; then
        FLATPAKS="aurora_flatpaks/flatpaks"
    fi
    FLATPAK_LIST="$(curl https://raw.githubusercontent.com/ublue-os/bluefin/main/${FLATPAKS} | tr '\n' ' ')"
    flatpak --system -y install --or-update ${FLATPAK_LIST}

# Configure grub bootmenu visibility
configure-grub:
    @/usr/libexec/configure-grub.sh

# # Rebase assistant
# rebase-helper:
#     @/usr/bin/ublue-rollback-helper

# alias rollback-helper := rebase-helper

# update-ng:
#     echo "Note: This command doesn't work if you have locally layered packages" 
#     sudo bootc upgrade
#     flatpak update -y
#     brew upgrade
# vim: set ft=make :
########################
### bluefin-tools.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run pytorch
pytorch:
    echo 'Follow the prompts and check the tutorial: https://docs.anaconda.com/free/anaconda/jupyter-notebooks/'
    podman pull docker.io/continuumio/miniconda3
    podman run -i -t -p 8888:8888 docker.io/continuumio/miniconda3 /bin/bash -c "/opt/conda/bin/conda install jupyter -y --quiet && mkdir \
    /opt/notebooks && /opt/conda/bin/jupyter notebook \
    --notebook-dir=/opt/notebooks --ip='*' --port=8888 \
    --no-browser --allow-root"

# Run Tensorflow
tensorflow:
    echo 'Follow the prompts and check the tutorial: https://www.tensorflow.org/tutorials/quickstart/beginner'
    podman pull docker.io/tensorflow/tensorflow:latest
    podman run -it -p 8888:8888 docker.io/tensorflow/tensorflow:latest-jupyter  # Start Jupyter server

# Setup a local Ollama instance in a container. Detect hardware, offer a choice if needed.
ollama:
    #!/usr/bin/env bash
    echo 'Detecting Hardware...'
    echo
    GPU_CHOICES=("Nvidia (CUDA)" "AMD (ROCm)" "CPU (slow)")
    DETECTED_OPTIONS=()
    # Detect nvidia drivers
    if which nvidia-smi > /dev/null 2>&1; then
        DETECTED_OPTIONS+=("${GPU_CHOICES[0]}")
    fi
    # Detect AMD hardware
    if lspci | grep ' VGA ' | grep -sq AMD; then
        DETECTED_OPTIONS+=("${GPU_CHOICES[1]}")
    fi
    # Nothing detected, ask the user
    if [ ${#DETECTED_OPTIONS[@]} -eq 0 ]; then
        GPU_SELECTION=$(printf '%s\n' "${GPU_CHOICES[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
    else
        GPU_SELECTION=$(printf '%s\n' "${DETECTED_OPTIONS[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
    fi
    echo "Selected ${GPU_SELECTION}!"
    case "$GPU_SELECTION" in
        "Nvidia (CUDA)")
            IMAGE=latest
            CUSTOM_ARGS="AddDevice=nvidia.com/gpu=all"
            ;;

        "AMD (ROCm)")
            IMAGE=rocm
            read -r -d '' CUSTOM_ARGS <<-'EOF'
    AddDevice=/dev/dri
    AddDevice=/dev/kfd
    EOF
            ;;
        *)
            IMAGE=latest
            CUSTOM_ARGS=""
            ;;
    esac

    read -r -d '' QUADLET <<-EOF
    [Unit]
    Description=The Ollama container
    After=local-fs.target

    [Service]
    Restart=always
    TimeoutStartSec=60
    # Ensure there's a userland podman.sock
    ExecStartPre=/bin/systemctl --user enable podman.socket
    # Ensure that the dir exists
    ExecStartPre=-mkdir -p %h/.ollama

    [Container]
    ContainerName=ollama
    PublishPort=11434:11434
    RemapUsers=keep-id
    RunInit=yes
    NoNewPrivileges=no
    Network=ollama.network
    Volume=%h/.ollama:/.ollama
    PodmanArgs=--userns=keep-id
    PodmanArgs=--group-add=keep-groups
    PodmanArgs=--ulimit=host
    PodmanArgs=--security-opt=label=disable
    PodmanArgs=--cgroupns=host

    Image=docker.io/ollama/ollama:${IMAGE}
    ${CUSTOM_ARGS}

    [Install]
    RequiredBy=multi-user.target
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama.container ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET}" > ~/.config/containers/systemd/ollama.container
    else
        echo "Ollama container already exists, skipping..."
    fi

    read -r -d '' QUADLET_NETWORK <<-EOF
    [Network]
    NetworkName=ollama
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama.network ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET_NETWORK}" > ~/.config/containers/systemd/ollama.network
    else
        echo "Ollama network already exists, skipping..."
    fi

    systemctl --user daemon-reload
    systemctl --user start ollama.service || echo "Error starting Ollama Quadlet."
    echo "Please install the ollama cli via \`brew install ollama\`"

# Setup a local Ollama WebUI in a container
ollama-web: ollama
    #!/usr/bin/env bash

    read -r -d '' QUADLET <<-EOF
    [Unit]
    Description=An Ollama WebUI container
    After=network-online.target ollama.service
    Requires=ollama.service

    [Container]
    Image=ghcr.io/open-webui/open-webui:latest
    AutoUpdate=registry
    ContainerName=ollama-web
    Environment=OLLAMA_BASE_URL=http://ollama:11434
    Environment=WEBUI_SECRET_KEY=abc123
    Environment=DEFAULT_USER_ROLE=admin
    Volume=open-webui:/app/backend/data
    # Open WebUI does not allow access without a user account, nor does it allow
    # account creation via environment variables.
    Environment=ENABLE_SIGNUP=true
    PublishPort=8080:8080
    Network=ollama.network

    [Service]
    TimeoutStartSec=900

    [Install]
    WantedBy=multi-user.target
    EOF
    if [  ! -f ~/.config/containers/systemd/ollama-web.container ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${QUADLET}" > ~/.config/containers/systemd/ollama-web.container
    else
        echo "Ollama WebUI container already exists, skipping..."
    fi
    systemctl --user daemon-reload
    systemctl --user start ollama-web.service
    echo "Ollama Web UI container started. You can access it at http://localhost:8080"

# Setup InvokeAI in a container
invokeai:
    #!/usr/bin/env bash
    echo 'Detecting Hardware...'
    echo
    GPU_CHOICES=("Nvidia (CUDA)" "AMD (ROCm)" "CPU (slow)")
    DETECTED_OPTIONS=()
    # Detect nvidia drivers
    if which nvidia-smi > /dev/null 2>&1; then
        DETECTED_OPTIONS+=("${GPU_CHOICES[0]}")
    fi
    # Detect AMD hardware
    if lspci | grep ' VGA ' | grep -sq AMD; then
        DETECTED_OPTIONS+=("${GPU_CHOICES[1]}")
    fi
    # Nothing detected, ask the user
    if [ ${#DETECTED_OPTIONS[@]} -eq 0 ]; then
        GPU_SELECTION=$(printf '%s\n' "${GPU_CHOICES[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
    else
        GPU_SELECTION=$(printf '%s\n' "${DETECTED_OPTIONS[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
    fi
    echo "Selected ${GPU_SELECTION}!"
    case "${GPU_SELECTION}" in
        "Nvidia (CUDA)")
            IMAGE=latest
            CUSTOM_ARGS="AddDevice=nvidia.com/gpu=all"
            ;;
        "AMD (ROCm)")
            IMAGE=main-rocm
            read -r -d '' CUSTOM_ARGS <<-'EOF'
    AddDevice=/dev/dri
    AddDevice=/dev/kfd
    EOF
            ;;
        *)
            IMAGE=latest
            CUSTOM_ARGS=""
            ;;
    esac

    read -r -d '' CONTAINER_QUADLET <<-EOF
    [Unit]
    Description=The InvokeAI container
    After=network-online.target

    [Service]
    TimeoutStartSec=1200

    [Container]
    Image=ghcr.io/invoke-ai/invokeai:${IMAGE}
    ContainerName=invokeai
    AutoUpdate=registry
    Environment=INVOKEAI_ROOT=/var/lib/invokeai
    PublishPort=9090:9090
    Volume=invokeai.volume:/var/lib/invokeai
    SecurityLabelDisable=true
    ${CUSTOM_ARGS}

    [Install]
    WantedBy=multi-user.target
    EOF

    read -r -d '' VOLUME_QUADLET <<-EOF
    [Volume]
    VolumeName=invokeai
    EOF

    if [ ! -f ~/.config/containers/systemd/invokeai.container ] || [ ! -f ~/.config/containers/systemd/invokeai.volume ]; then
        mkdir -p ~/.config/containers/systemd
        echo "${CONTAINER_QUADLET}" > ~/.config/containers/systemd/invokeai.container
        echo "${VOLUME_QUADLET}" > ~/.config/containers/systemd/invokeai.volume
    else
        echo "InvokeAI container already exists, skipping..."
    fi
    systemctl --user daemon-reload
    systemctl --user start invokeai.service
    echo "InvokeAI container started. You can access it at http://localhost:9090"
