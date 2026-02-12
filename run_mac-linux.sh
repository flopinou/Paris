#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/../../cities/data/PAR"

# --- AUTO-UPDATE ---
echo "[Paris Mod] Checking for updates..."

LOCAL_VERSION=$(grep '"version"' "$SCRIPT_DIR/manifest.json" | sed -E 's/.*"version": "([^"]+)".*/\1/')

if [ -n "$LOCAL_VERSION" ]; then
    if command -v curl >/dev/null 2>&1; then
        RELEASE_INFO=$(curl -s "https://api.github.com/repos/flopinou/paris-sb/releases/latest")
        REMOTE_VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
        
        if [ -n "$REMOTE_VERSION" ]; then
            if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
                echo ""
                echo "[Paris Mod] NEW VERSION AVAILABLE: $REMOTE_VERSION (Current: $LOCAL_VERSION)"
                echo ""
                
                read -p "Do you want to update now? (y/n): " CHOICE
                if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
                    echo "[Paris Mod] Downloading update..."
                    DOWNLOAD_URL="https://github.com/flopinou/paris-sb/releases/download/$REMOTE_VERSION/Paris.zip"
                    
                    if curl -L -o "$SCRIPT_DIR/update.zip" "$DOWNLOAD_URL"; then
                        rm -rf "$SCRIPT_DIR/update_temp"
                        mkdir -p "$SCRIPT_DIR/update_temp"
                        unzip -o "$SCRIPT_DIR/update.zip" -d "$SCRIPT_DIR/update_temp"
                        
                        EXTRACTED_DIR=$(find "$SCRIPT_DIR/update_temp" -maxdepth 1 -type d | head -n 2 | tail -n 1)
                        if [ -n "$EXTRACTED_DIR" ]; then
                            if [ -d "$EXTRACTED_DIR/Paris" ]; then
                                cp -R "$EXTRACTED_DIR/Paris/"* "$SCRIPT_DIR/"
                            else
                                cp -R "$EXTRACTED_DIR/"* "$SCRIPT_DIR/"
                            fi
                            rm -rf "$SCRIPT_DIR/update_temp"
                            rm "$SCRIPT_DIR/update.zip"
                            echo "[Paris Mod] Update complete!"
                            exit 0
                        fi
                    fi
                fi
            fi
        fi
    fi
fi

# --- DATA COPY ---
mkdir -p "$TARGET"
cp -f "$SCRIPT_DIR/data/PAR/"* "$TARGET/"

# --- PMTILES CHECK ---
if [ ! -f "$SCRIPT_DIR/pmtiles" ]; then
    echo "[Paris Mod] 'pmtiles' binary not found. Downloading..."
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    RELEASE_INFO=$(curl -s "https://api.github.com/repos/protomaps/go-pmtiles/releases/latest")
    PMTILES_TAG=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
    PMTILES_VER=${PMTILES_TAG#v}

    if [ -z "$PMTILES_TAG" ]; then exit 1; fi

    if [ "$OS" = "Darwin" ]; then
        if [ "$ARCH" = "arm64" ]; then
            URL="https://github.com/protomaps/go-pmtiles/releases/download/${PMTILES_TAG}/go-pmtiles_${PMTILES_VER}_Darwin_arm64.zip"
        else
            URL="https://github.com/protomaps/go-pmtiles/releases/download/${PMTILES_TAG}/go-pmtiles_${PMTILES_VER}_Darwin_x86_64.zip"
        fi
        curl -L -o "$SCRIPT_DIR/pmtiles.zip" "$URL"
        unzip -j -o "$SCRIPT_DIR/pmtiles.zip" "pmtiles" -d "$SCRIPT_DIR"
        rm "$SCRIPT_DIR/pmtiles.zip"
        
    elif [ "$OS" = "Linux" ]; then
        if [ "$ARCH" = "aarch64" ]; then
             URL="https://github.com/protomaps/go-pmtiles/releases/download/${PMTILES_TAG}/go-pmtiles_${PMTILES_VER}_Linux_arm64.tar.gz"
        else
             URL="https://github.com/protomaps/go-pmtiles/releases/download/${PMTILES_TAG}/go-pmtiles_${PMTILES_VER}_Linux_x86_64.tar.gz"
        fi
        curl -L -o "$SCRIPT_DIR/pmtiles.tar.gz" "$URL"
        tar -xzf "$SCRIPT_DIR/pmtiles.tar.gz" -C "$SCRIPT_DIR" pmtiles
        rm "$SCRIPT_DIR/pmtiles.tar.gz"
    fi
    chmod +x "$SCRIPT_DIR/pmtiles"
fi

# --- START SERVER ---
echo "[Paris Mod] Starting tile server on port 8080..."
"$SCRIPT_DIR/pmtiles" serve "$SCRIPT_DIR" --port 8080 --cors=*