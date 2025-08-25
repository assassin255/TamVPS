FROM ubuntu:latest

# =============================
# Cài các gói cần thiết
# =============================
RUN apt update && apt upgrade -y && apt install -y \
    htop \
    curl \
    ca-certificates \
    git \
    unzip \
    wget \
    python3 \
    python3-pip \
    qemu-kvm \
    qemu-utils \
    ssh \
    jq \
    && rm -rf /var/lib/apt/lists/*

# =============================
# Tải ISO Windows + Virtio
# =============================
RUN echo "[+] Đang tải Windows ISO..."; \
    wget -O /win.iso "https://archive.org/download/windows-10-lite-edition-19h2-x64/Windows%2010%20Lite%20Edition%2019H2%20x64.iso" --progress=dot:giga; \
    echo "[+] Đang tải Virtio ISO..."; \
    wget -O /virtio.iso "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-0.1.271.iso" --progress=dot:giga

# =============================
# Tạo ổ cứng qcow2
# =============================
RUN qemu-img create -f qcow2 /disk.qcow2 50G

# =============================
# CMD chạy QEMU + SSH reverse
# =============================
CMD bash -c '\
echo "[+] Khởi động QEMU Windows..."; \
qemu-system-x86_64 \
    -M q35,hpet=on,nvdimm=on,hmat=on \
    -usb -device usb-tablet -device usb-kbd \
    -cpu qemu64,+ssse3,+sse4.1,+sse4.2,+aes,+xsave,+xsaveopt,+popcnt,+cx16,+mmx,+sse,+sse2,+x2apic,+lahf_lm,+rdrand \
    -smp sockets=1,cores=4,threads=1 \
    -object memory-backend-memfd,id=mem,size=8192M,share=on,prealloc=on \
    -m 4192 -mem-prealloc -machine memory-backend=mem \
    -drive file=/disk.qcow2,if=none,format=qcow2,cache=unsafe,aio=threads,discard=on,id=hd0 \
    -device virtio-blk-pci,drive=hd0 \
    -drive file=/win.iso,media=cdrom,if=none,id=cdrom0 \
    -device ahci,id=ahci0 \
    -device ide-cd,drive=cdrom0,bus=ahci0.0 \
    -drive file=/virtio.iso,media=cdrom,if=none,id=cdrom1 \
    -device ide-cd,drive=cdrom1,bus=ahci0.1 \
    -device qxl-vga,vgamem_mb=2048,ram_size=268435456,vram_size=268435456 \
    -device virtio-balloon,id=balloon0 \
    -display vnc=:0 \
    -netdev user,id=n0,hostfwd=tcp::5900-:5900,restrict=off \
    -device virtio-net-pci,netdev=n0 \
    -accel tcg,thread=multi \
    -rtc clock=host,base=utc \
    -boot order=d,menu=on \
    -daemonize
echo "[+] SSH Reverse Tunnel qua Pinggy.io..."; \
ssh -p $PINGGY_PORT -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 $PINGGY_USER@$PINGGY_HOST'
