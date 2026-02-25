Write-Host "Iniciando la instalacion de Anima (Arquitectura Cognitiva Local)..." -ForegroundColor Cyan

# 1. Crear la carpeta de instalacion en el disco C:
$installDir = "C:\Anima"
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}
Set-Location $installDir

# 2. Descargar la App (Tu .exe y los archivos de Flutter)
# NOTA: Aqui pondras el enlace al .zip de tu app cuando la subas a GitHub Releases
$appUrl = "https://github.com/tu-usuario/anima/releases/latest/download/anima-windows.zip"
$zipPath = "$installDir\anima.zip"

Write-Host "Descargando la aplicacion (Esto sera rapido)..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $appUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath

# 3. Descargar el Cerebro (Dolphin Llama 3 - 5GB)
# Descarga directamente desde HuggingFace
$modelUrl = "https://huggingface.co/bartowski/Dolphin3.0-Llama3.1-8B-GGUF/resolve/main/Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf?download=true"
$modelPath = "$installDir\anima_v1.gguf"

if (!(Test-Path $modelPath)) {
    Write-Host "Descargando el Cerebro Digital (5GB). Esto puede tardar varios minutos dependiendo de tu conexion. Por favor, no cierres esta ventana..." -ForegroundColor Yellow
    # Usamos BitsTransfer porque es mas estable para archivos gigantes y muestra barra de progreso
    Start-BitsTransfer -Source $modelUrl -Destination $modelPath
} else {
    Write-Host "El Cerebro Digital ya esta instalado." -ForegroundColor Green
}

# 4. Crear acceso directo en el Escritorio
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Anima.lnk")
$Shortcut.TargetPath = "$installDir\anima.exe"
$Shortcut.IconLocation = "$installDir\anima.exe"
$Shortcut.Save()

Write-Host "¡Instalacion completada con exito! Tienes un acceso directo en tu escritorio." -ForegroundColor Green
Write-Host "Bienvenido a la Libertad Cognitiva." -ForegroundColor Cyan
