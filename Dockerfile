version: 1.0.{build}

image: Visual Studio 2022

build_script:
  - ps: |
      Write-Host "🔑 Thiết lập mật khẩu cho Administrator..."
      $password = ConvertTo-SecureString "Xy!9#2025_RdpStrong*" -AsPlainText -Force
      Set-LocalUser -Name "Administrator" -Password $password
      Enable-LocalUser -Name "Administrator"

      Write-Host "🌐 Cài ngrok..."
      Invoke-WebRequest https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -OutFile ngrok.zip
      Expand-Archive ngrok.zip -DestinationPath C:\ngrok
      $env:Path += ";C:\ngrok"

      Write-Host "🔑 Đăng nhập ngrok..."
      & C:\ngrok\ngrok.exe config add-authtoken 2ww60Uf9irvEr2KylKE2P5ASMGw_2Mer1U56aKeQsqVK5Mczs

      Write-Host "🚀 Mở port RDP (3389)..."
      Start-Process -NoNewWindow -FilePath "C:\ngrok\ngrok.exe" -ArgumentList "tcp 3389"

      Write-Host "
IP: vào ngrok endpoint
User: Administrator
Password: Xy!9#2025_RdpStrong*
VPS này chạy 24/24 vĩnh viễn yaml bởi TamNguyenDepTrai"
      for ($i=0; $i -lt 1440; $i++) {
        Start-Sleep -Seconds 60
        Write-Host "Đang giữ: $i phút (tổng $($i/60) giờ)"
      }
