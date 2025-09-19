# Rocky Linux 8 aligns well with DaVinci Resolve’s Linux target
FROM rockylinux:8

# --- dnf quality-of-life + EPEL ---
RUN set -eux; \
    # keep container leaner/faster
    sed -i 's/^# *install_weak_deps=.*/install_weak_deps=False/' /etc/dnf/dnf.conf || true; \
    grep -q '^install_weak_deps=False' /etc/dnf/dnf.conf || echo 'install_weak_deps=False' >> /etc/dnf/dnf.conf; \
    grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf; \
    grep -q '^fastestmirror=' /etc/dnf/dnf.conf || echo 'fastestmirror=True' >> /etc/dnf/dnf.conf; \
    dnf -y install epel-release && dnf -y upgrade && dnf clean all

# --- base tooling & libs Resolve typically needs on EL8 ---
# Note: no amdgpu-dkms here — kernel modules belong on the host
RUN set -eux; \
    dnf -y install \
      dnf-plugin-config-manager \
      python3-setuptools python3-wheel \
      fuse fuse-libs \
      alsa-lib alsa-plugins-pulseaudio pulseaudio-libs \
      apr apr-util \
      fontconfig freetype \
      libglvnd libglvnd-egl libglvnd-glx libglvnd-opengl mesa-libGLU libgomp \
      librsvg2 \
      libXcursor libXfixes libXi libXinerama libxkbcommon libxkbcommon-x11 \
      libXrandr libXrender libXtst libXxf86vm \
      mtdev \
      xcb-util xcb-util-cursor xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm \
      mesa-dri-drivers \
      ocl-icd clinfo \
      tar xz unzip which less procps-ng; \
    dnf clean all

# --- AMD ROCm OpenCL userspace (no DKMS) ---
# You can override AMD_RPM_URL at build-time if a newer release is out.
ARG AMD_RPM_URL="https://repo.radeon.com/amdgpu-install/latest/rhel/8.10/amdgpu-install-6.4.60403-1.el8.noarch.rpm"
RUN set -eux; \
    dnf -y install "${AMD_RPM_URL}" && \
    dnf -y install rocm rocm-opencl rocm-opencl-runtime && \
    dnf clean all

# Optional: set a sane, generic locale to avoid warnings
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Distrobox will inject your user and share $HOME, X11/Wayland, audio, etc.
# No ENTRYPOINT/CMD needed; distrobox-enter will handle the session.
