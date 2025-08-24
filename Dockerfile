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
# Cài đặt ngrok
# =============================
RUN curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
    | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
    | tee /etc/apt/sources.list.d/ngrok.list \
    && apt update \
    && apt install -y ngrok \
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
# Chạy QEMU + Ngrok khi container start
# =============================
CMD bash -c '\
    echo "[+] Khởi động QEMU Windows..."; \
    qemu-system-x86_64 \
        -M q35,hpet=off,nvdimm=on,hmat=on \
        -usb -device usb-tablet -device usb-kbd \
        -cpu qemu64,+ssse3,+sse4.1,+sse4.2,+aes,+xsave,+xsaveopt,+xsavec,+xgetbv1,+avx,+avx2,+fma,+fma4,+popcnt,+cx16,+mmx,+sse,+sse2,+x2apic,+lahf_lm,+rdrand \
        -smp sockets=1,cores=2,threads=1 \
        -m 1024 \
        -drive file=/disk.qcow2,if=none,format=qcow2,cache=unsafe,aio=threads,discard=on,id=hd0 \
        -device virtio-blk-pci,drive=hd0 \
        -drive file=/win.iso,media=cdrom,if=none,id=cdrom0 \
        -device ahci,id=ahci0 \
        -device ide-cd,drive=cdrom0,bus=ahci0.0 \
        -drive file=/virtio.iso,media=cdrom,if=none,id=cdrom1 \
        -device ide-cd,drive=cdrom1,bus=ahci0.1 \
        -device qxl-vga,vgamem_mb=512 \
        -device virtio-balloon,id=balloon0 \
        -display vnc=:0 \
        -netdev user,id=n0,hostfwd=tcp::5900-:5900,restrict=off -device virtio-net-pci,netdev=n0 \
        -accel tcg,thread=multi,tb-size=34388608,split-wx=on \
        -rtc clock=host,base=utc \
        -boot order=d,menu=on; \
    \
    echo "[+] Port 5900 Pinggy.io..."; \
    ssh -p 443 -R0:localhost:5900 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 lVuaQjAzw82+tcp@free.pinggy.io; \
    
