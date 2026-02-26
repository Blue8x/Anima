$ProgressPreference = 'SilentlyContinue'

Write-Host "Starting Anima (Local Cognitive Architecture) installation..." -ForegroundColor Cyan

# 1. Create installation directory in AppData
$installDir = "$env:LOCALAPPDATA\Anima"
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}
Set-Location $installDir

# 2. Download the App (Your .exe and Flutter files)
$appUrl = "https://github.com/Blue8x/Anima/releases/latest/download/anima-windows.zip"
$zipPath = "$installDir\anima.zip"

Write-Host "`n[1/4] Downloading the application core..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $appUrl -OutFile $zipPath -ErrorAction Stop
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force -ErrorAction Stop
    Remove-Item $zipPath -Force
    Write-Host "App downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not download the app (Repo might be private)." -ForegroundColor Red
    Write-Host "Skipping zip extraction for local testing purposes..." -ForegroundColor DarkGray
    # Cuando lances la app oficialmente, descomenta la palabra "exit" de abajo para que sea estricto
    # exit 
}

# 2.5 Download the Memory Core (Embedding Model) silently
Write-Host "`n[2/4] Downloading Memory Core (This will take a few seconds)..." -ForegroundColor Yellow
$embedUrl = "https://huggingface.co/bofenghuang/all-MiniLM-L6-v2-gguf/resolve/main/all-MiniLM-L6-v2-f16.gguf"
$embedPath = "$installDir\all-MiniLM-L6-v2.gguf"

try {
    Invoke-WebRequest -Uri $embedUrl -OutFile $embedPath -ErrorAction Stop
    Write-Host "Memory Core downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not download the Memory Core. Memory functions might be limited." -ForegroundColor Red
}

# 3. Choose and Download the Brain (Interactive Flow)
Write-Host "`n[3/4] Select the Brain (AI Model) size that fits your PC:" -ForegroundColor Cyan
Write-Host "  1. Small  (Fast, ~4GB RAM required) - Phi-3 Mini"
Write-Host "  2. Medium (Recommended, ~8GB RAM required) - Llama 3 / Dolphin 8B"
Write-Host "  3. Large  (High Quality, 16GB+ RAM required) - Mistral Nemo 12B"
Write-Host "  4. Skip   (I already have a .gguf model)"

$choice = Read-Host "Enter your choice (1-4)"
$hfUrl = ""

switch ($choice) {
    '1' { $hfUrl = "https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF/tree/main" }
    '2' { $hfUrl = "https://huggingface.co/bartowski/Dolphin3.0-Llama3.1-8B-GGUF/tree/main" }
    '3' { $hfUrl = "https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF/tree/main" }
    '4' { Write-Host "Skipping model download..." -ForegroundColor DarkGray }
    default { Write-Host "Invalid choice, skipping..." -ForegroundColor DarkGray }
}

if ($hfUrl -ne "") {
    Write-Host "`nOpening your browser and the installation folder..." -ForegroundColor Green
    Write-Host "-> Download any '.gguf' file from the HuggingFace page."
    Write-Host "-> Move that file into the folder that just opened."
    
    Start-Sleep -Seconds 2
    
    # Abrimos la URL en el navegador por defecto
    Start-Process $hfUrl
    # Abrimos la carpeta local para que el usuario suelte ahi el archivo
    Start-Process "explorer.exe" $installDir

    $modelFound = $false
    while (-not $modelFound) {
        $confirm = Read-Host "`nHave you moved the .gguf file to the folder? (Y/N)"
        if ($confirm -match "^[Yy]$") {
            # Buscamos si el usuario ha metido algun archivo .gguf (EXCLUYENDO el de memoria)
            $ggufFiles = Get-ChildItem -Path $installDir -Filter *.gguf | Where-Object { $_.Name -ne "all-MiniLM-L6-v2.gguf" }
            
            if ($ggufFiles.Count -gt 0) {
                Write-Host "Model found! Configuring it for Anima..." -ForegroundColor Green
                
                # Renombramos el primer gguf (el grande) que encuentre a 'anima_v1.gguf'
                $targetName = "anima_v1.gguf"
                if ($ggufFiles[0].Name -ne $targetName) {
                    Rename-Item -Path $ggufFiles[0].FullName -NewName $targetName -Force
                    Write-Host "Model automatically renamed to $targetName." -ForegroundColor DarkGray
                }
                
                $modelFound = $true
            } else {
                Write-Host "[ERROR] No main .gguf file found in $installDir." -ForegroundColor Red
                Write-Host "Please download it and move it to the folder before continuing." -ForegroundColor Yellow
            }
        }
    }
}

# 4. Create Desktop Shortcut
Write-Host "`n[4/4] Setting up shortcuts..." -ForegroundColor Yellow
try {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Anima.lnk")
    $Shortcut.TargetPath = "$installDir\anima.exe"
    $Shortcut.WorkingDirectory = "$installDir"
    
    # Solo le pone el icono si existe el exe
    if (Test-Path "$installDir\anima.exe") {
        $Shortcut.IconLocation = "$installDir\anima.exe"
    }
    $Shortcut.Save()
    Write-Host "Desktop shortcut created!" -ForegroundColor Green
} catch {
    Write-Host "Could not create shortcut." -ForegroundColor DarkGray
}

Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
Write-Host "Welcome to Cognitive Freedom." -ForegroundColor Cyan