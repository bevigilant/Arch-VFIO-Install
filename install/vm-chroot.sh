#!/bin/bash
# run this once you're in the chroot

echo "Enter the target hostname..."
read HOSTNAME
echo "Enter the main user (usually alex)..."
read USER
echo "Enter rootfs partition to install systemd-boot, usually sda2:"
read PARTITION

echo "Hostname:               '$HOSTNAME'"
echo "Username:               '$USER'"
echo "systemd-boot partition: '/dev/$PARTITION'"
echo ""
echo ""

### Doing actual stuff
echo en_GB.UTF-8 UTF-8 > /etc/locale.gen
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf
export LANG=en_GB.UTF-8
ln -s /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc --utc
echo $HOSTNAME > /etc/hostname

# packages
cat <<EOT >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist

[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
EOT

pacman -Syu \
  curl \
  firefox \
  git \
  gnome \
  gnome-tweak-tool \
  libvirt \
  networkmanager \
  openssh \
  qemu \
  steam \
  sudo \
  virt-manager \
  wget \
  yaourt \
 
useradd -m -g users -s /bin/bash $USER
usermod -aG wheel docker $USER

echo "root:22" | chpasswd
echo "$USER:22" | chpasswd

systemctl enable sshd
systemctl enable gdm
systemctl enable NetworkManager

# systemd-boot
bootctl --path=/boot/$esp install
rm /boot/loader/loader.conf

cat <<EOT >> /boot/loader/loader.conf
default arch
timeout 1
editor 0
EOT

cat <<EOT >> /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=/dev/$PARTITION rw intel_iommu=on
EOT

nvidia-xconfig
cp /etc/X11/xorg.conf /etc/X11/xorg.conf.d/20-nvidia.conf

mkinitcpio -p linux

echo ""
echo "Place the following modules into your mkinitcpio.conf MODULES"
echo "vfio vfio_iommu_type1 vfio_pci vfio_virqfd"
echo ""
echo "Also make sure to edit the VM.xml file with <kvm>hidden</> stuff..."
