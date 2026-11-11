FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        debootstrap squashfs-tools xorriso mtools dosfstools \
        grub-common grub2-common ca-certificates \
    && case "$(dpkg --print-architecture)" in \
         amd64) apt-get install -y --no-install-recommends grub-pc-bin grub-efi-amd64-bin ;; \
         arm64) apt-get install -y --no-install-recommends grub-efi-arm64-bin ;; \
       esac \
    && rm -rf /var/lib/apt/lists/*
