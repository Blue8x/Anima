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

# 3. Download the Memory Core (Interactive Flow)
Write-Host "`n[2/4] Setting up the Memory Core (Required for long-term memory):" -ForegroundColor Cyan
Write-Host "Opening your browser and the installation folder..." -ForegroundColor Green
Write-Host "-> Please download ANY .gguf file from the list (e.g., 'all-MiniLM-L6-v2-Q4_K_M.gguf')."
Write-Host "-> Move it into the Anima installation folder that just opened."

$memoryUrl = "https://huggingface.co/second-state/All-MiniLM-L6-v2-Embedding-GGUF/tree/main"
Start-Sleep -Seconds 2

# Abrimos la URL de memoria en el navegador
Start-Process $memoryUrl
# Abrimos la carpeta local
Start-Process "explorer.exe" $installDir

$memoryFound = $false
while (-not $memoryFound) {
    $confirm = Read-Host "`nHave you moved the Memory Core .gguf file to the folder? (Y/N)"
    if ($confirm -match "^[Yy]$") {
        # Buscamos cualquier archivo que contenga "MiniLM" en el nombre
        $memFiles = Get-ChildItem -Path $installDir -Filter *MiniLM*.gguf
        
        if ($memFiles.Count -gt 0) {
            Write-Host "Memory Core found! Configuring it..." -ForegroundColor Green
            
            $targetMemName = "all-MiniLM-L6-v2.gguf"
            if ($memFiles[0].Name -ne $targetMemName) {
                Rename-Item -Path $memFiles[0].FullName -NewName $targetMemName -Force
                Write-Host "Memory Core automatically renamed to $targetMemName." -ForegroundColor DarkGray
            }
            $memoryFound = $true
        } else {
            Write-Host "[ERROR] No Memory Core file found in $installDir." -ForegroundColor Red
            Write-Host "Make sure you downloaded the file containing 'MiniLM' and moved it to the folder." -ForegroundColor Yellow
        }
    }
}

# 4. Choose and Download the Brain (Interactive Flow)
Write-Host "`n[3/4] Select the Main Brain (AI Model) size that fits your PC:" -ForegroundColor Cyan
Write-Host "  1. Small  (Fast & Uncensored, ~2.4GB) - Dolphin Phi-3 Mini"
Write-Host "  2. Medium (Smart & Uncensored, ~4.5GB) - Dolphin Llama 3.1 8B"
Write-Host "  3. Skip   (I already have a main .gguf model)"

$choice = Read-Host "Enter your choice (1-3)"
$hfUrl = ""

switch ($choice) {
    '1' { $hfUrl = "https://huggingface.co/bartowski/dolphin-2.9.3-phi-3-mini-4k-instruct-GGUF/tree/main" }
    '2' { $hfUrl = "https://huggingface.co/bartowski/Dolphin3.0-Llama3.1-8B-GGUF/tree/main" }
    '3' { Write-Host "Skipping model download..." -ForegroundColor DarkGray }
    default { Write-Host "Invalid choice, skipping..." -ForegroundColor DarkGray }
}

if ($hfUrl -ne "") {
    Write-Host "`nOpening your browser for the Main Brain..." -ForegroundColor Green
    Write-Host "-> Download a '.gguf' file from the HuggingFace page."
    Write-Host "-> TIP: Download the 'Q4_K_M' version for the best balance of speed and size."
    Write-Host "-> Move that file into the same folder."
    
    Start-Sleep -Seconds 2
    Start-Process $hfUrl

    $modelFound = $false
    while (-not $modelFound) {
        $confirm = Read-Host "`nHave you moved the Main Brain .gguf file to the folder? (Y/N)"
        if ($confirm -match "^[Yy]$") {
            # Buscamos si el usuario ha metido el archivo grande (EXCLUYENDO el de memoria que ya renombramos)
            $ggufFiles = Get-ChildItem -Path $installDir -Filter *.gguf | Where-Object { $_.Name -ne "all-MiniLM-L6-v2.gguf" }
            
            if ($ggufFiles.Count -gt 0) {
                Write-Host "Main Brain found! Configuring it for Anima..." -ForegroundColor Green
                
                # Renombramos el primer gguf (el grande) que encuentre a 'anima_v1.gguf'
                $targetName = "anima_v1.gguf"
                if ($ggufFiles[0].Name -ne $targetName) {
                    Rename-Item -Path $ggufFiles[0].FullName -NewName $targetName -Force
                    Write-Host "Main Brain automatically renamed to $targetName." -ForegroundColor DarkGray
                }
                
                $modelFound = $true
            } else {
                Write-Host "[ERROR] No Main Brain .gguf file found in $installDir." -ForegroundColor Red
                Write-Host "Please download it and move it to the folder before continuing." -ForegroundColor Yellow
            }
        }
    }
}

# 5. Create Desktop Shortcut
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