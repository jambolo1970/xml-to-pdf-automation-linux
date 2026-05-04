#!/usr/bin/env bash
set -u

APP_NAME="XML to PDF Automation"
APP_ID="xml-to-pdf-automation"
LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_APP_DIR="$HOME/.local/share/applications"
LOCAL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"

LAUNCHER_PATH="$LOCAL_BIN_DIR/$APP_ID"
DESKTOP_PATH="$LOCAL_APP_DIR/$APP_ID.desktop"
DESKTOP_COPY="$DESKTOP_DIR/$APP_ID.desktop"
ICON_DEST="$LOCAL_ICON_DIR/$APP_ID.svg"

notify() {
  local text="$1"
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="$APP_NAME" --width=620 --text="$text" 2>/dev/null || true
  elif command -v kdialog >/dev/null 2>&1; then
    kdialog --msgbox "$text" 2>/dev/null || true
  else
    printf '%s\n' "$text"
  fi
}

confirm() {
  local text="Vuoi disinstallare il lanciatore di $APP_NAME?\n\nVerranno rimossi solo:\n- voce di menu\n- icona sul desktop\n- comando in ~/.local/bin\n- icona applicazione\n\nLa cartella del progetto e gli script non verranno cancellati."
  if command -v zenity >/dev/null 2>&1; then
    zenity --question --title="$APP_NAME" --width=620 --text="$text" 2>/dev/null
  elif command -v kdialog >/dev/null 2>&1; then
    kdialog --yesno "$text" 2>/dev/null
  else
    printf '%b\n' "$text"
    read -r -p "Confermi? [s/N]: " risposta
    [[ "$risposta" == "s" || "$risposta" == "S" || "$risposta" == "si" || "$risposta" == "SI" ]]
  fi
}

refresh_desktop() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$LOCAL_APP_DIR" >/dev/null 2>&1 || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
  fi
  if command -v xdg-desktop-menu >/dev/null 2>&1; then
    xdg-desktop-menu forceupdate >/dev/null 2>&1 || true
  fi
}

confirm || exit 0
rm -f "$LAUNCHER_PATH" "$DESKTOP_PATH" "$DESKTOP_COPY" "$ICON_DEST"
refresh_desktop
notify "Disinstallazione completata.\n\nLa cartella del progetto non è stata cancellata."
