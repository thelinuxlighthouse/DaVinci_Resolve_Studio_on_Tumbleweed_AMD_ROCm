# DaVinci_Resolve_Studio_on_Tumbleweed_AMD_ROCm
DaVinci Resolve on openSUSE Tumbleweed (AMD) — Rock-Solid Fix with Distrobox + Rocky Linux
Here’s a clean, self-contained Containerfile (Dockerfile syntax) you can build once and then use with Distrobox. It bakes in EPEL, base GUI/OpenGL/ALSA deps, AMD’s ROCm OpenCL userspace (no DKMS), and a couple of niceties. You’ll still pass the GPU devices from the host at runtime (with Distrobox flags).

# Prerequisites on the host (Tumbleweed)
### Goal: Ensure your user can access the GPU devices /dev/dri and /dev/kfd and that containers can see them.
## 1.	Add your user to video/render (host side).
sudo usermod -aG video,render "$USER"

##### log out and back in (or reboot) so the new group memberships apply

##### Why: Those groups govern access to GPU device nodes that we will pass into the container. 

## 2.	Install Distrobox + Podman (host side).
sudo zypper install --recommends distrobox podman

##### Why: Distrobox is a thin layer over Podman that gives you desktop-friendly containers (HOME sharing, X11/Wayland, audio, USB) without custom Dockerfiles.

# How to build and use it
## 1- Build the image (host / Tumbleweed):
podman build -t davinci-rocky8:latest -f Containerfile

## 2- Create the distrobox with GPU access:
distrobox-create \
  --image davinci-rocky8:latest \
  --name davinci \
  --additional-flags "--device /dev/dri --device /dev/kfd --group-add keep-groups"

## 3- Enter the container:
distrobox-enter davinci

## 4- (Optional) quick checks inside the container:
cat /etc/os-release

clinfo | egrep -m6 "Platform Name|Device Name|Version"

You should see the AMD OpenCL platform and your GPU.

## 5- Install DaVinci Resolve Studio into your shared HOME (inside the container):
cd "$HOME"

chmod +x DaVinci_Resolve_Studio_20.2_Linux.run

./DaVinci_Resolve_Studio_20.2_Linux.run -n -C "$HOME/resolve"

## 6- Add a KDE launcher on the host (so it feels native):
### Program: /usr/bin/distrobox-enter
### Arguments: davinci -- '/home/<your-user>/resolve/bin/resolve' %u

## Note: (Use the absolute path—don’t rely on $HOME in the launcher.)

# Notes / gotchas

- No amdgpu-dkms in the image: kernel modules must be installed on the host (Tumbleweed). The container only needs user-space ROCm/OpenCL.
- Devices & permissions: make sure your host user is in video, render groups and pass /dev/dri and /dev/kfd as shown. Log out/in if you just added the groups.
- Wayland/X11: Distrobox forwards display automatically. Resolve will use XWayland under Wayland sessions.
- Upgrading ROCm later: rebuild with a newer AMD_RPM_URL or enter the container and dnf update.
