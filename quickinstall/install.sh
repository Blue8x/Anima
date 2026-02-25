#!/usr/bin/env bash
set -e

# Colores para la terminal
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}Iniciando la instalación de Anima (Arquitectura Cognitiva Local)...${NC}"

# 1. Crear la carpeta de instalación en el directorio "Home" del usuario (~/Anima)
INSTALL_DIR="$HOME/Anima"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 2. Detectar el Sistema Operativo
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    echo -e "${YELLOW}Detectado macOS. Preparando entorno Apple Silicon/Intel...${NC}"
    # Aquí pondrás el enlace al .zip de Mac cuando lo compiles
    APP_URL="https://github.com/tu-usuario/anima/releases/latest/download/anima-macos.zip"
elif [ "$OS" = "Linux" ]; then
    echo -e "${YELLOW}Detectado Linux. Preparando entorno...${NC}"
    # Aquí pondrás el enlace al .zip de Linux cuando lo compiles
    APP_URL="https://github.com/tu-usuario/anima/releases/latest/download/anima-linux.zip"
else
    echo -e "${RED}Sistema operativo no soportado por este script.${NC}"
    exit 1
fi

# 3. Descargar y extraer la App
echo -e "${YELLOW}Descargando la aplicación Anima...${NC}"
curl -L --progress-bar "$APP_URL" -o "anima_app.zip"
unzip -o -q anima_app.zip
rm anima_app.zip

# Dar permisos de ejecución (por si se pierden al comprimir)
chmod +x anima 2>/dev/null || true

# 4. Descargar el Cerebro Digital (El archivo de 5GB)
MODEL_URL="https://huggingface.co/bartowski/Dolphin3.0-Llama3.1-8B-GGUF/resolve/main/Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf?download=true"
MODEL_PATH="anima_v1.gguf"

if [ ! -f "$MODEL_PATH" ]; then
    echo -e "${YELLOW}Descargando el Cerebro Digital (5GB). Esto puede tardar varios minutos dependiendo de tu conexión...${NC}"
    # curl con -C - permite reanudar la descarga si se corta
    curl -L -C - --progress-bar "$MODEL_URL" -o "$MODEL_PATH"
else
    echo -e "${GREEN}El Cerebro Digital ya está instalado.${NC}"
fi

echo -e "${GREEN}¡Instalación completada con éxito en $INSTALL_DIR!${NC}"
echo -e "${CYAN}Para iniciar Anima, simplemente abre tu terminal y ejecuta:${NC}"
echo -e "cd ~/Anima && ./anima"
