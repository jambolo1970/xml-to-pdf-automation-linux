#!/usr/bin/env bash
set -u

APP_NAME="XML to PDF Automation"
APP_ID="xml-to-pdf-automation"
APP_COMMENT="Trasforma fatture elettroniche XML e XML.P7M in PDF con fogli XSL"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
APP_SCRIPT="$SCRIPT_DIR/genera_pdf_gui.sh"
ICON_SRC="$SCRIPT_DIR/img/xml-to-pdf-automation.svg"

LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_APP_DIR="$HOME/.local/share/applications"
LOCAL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"

LAUNCHER_PATH="$LOCAL_BIN_DIR/$APP_ID"
DESKTOP_PATH="$LOCAL_APP_DIR/$APP_ID.desktop"
DESKTOP_COPY="$DESKTOP_DIR/$APP_ID.desktop"
ICON_DEST="$LOCAL_ICON_DIR/$APP_ID.svg"
UNINSTALL_SCRIPT="$SCRIPT_DIR/disinstalla-lanciatore.sh"

log() { printf '%s\n' "$*"; }
warn() { printf 'Attenzione: %s\n' "$*" >&2; }

ask_action() {
  if [[ "${1:-}" == "--uninstall" || "${1:-}" == "disinstalla" ]]; then
    printf 'uninstall'
    return 0
  fi
  if [[ "${1:-}" == "--install" || "${1:-}" == "installa" ]]; then
    printf 'install'
    return 0
  fi
  if command -v zenity >/dev/null 2>&1; then
    zenity --list --title="$APP_NAME" --text="Cosa vuoi fare?" --width=520 --height=240 \
      --column="Azione" --column="Descrizione" \
      install "Installa o aggiorna il lanciatore" \
      uninstall "Disinstalla il lanciatore" 2>/dev/null
  elif command -v kdialog >/dev/null 2>&1; then
    kdialog --menu "Cosa vuoi fare?" install "Installa o aggiorna il lanciatore" uninstall "Disinstalla il lanciatore" 2>/dev/null
  else
    log "1) Installa o aggiorna il lanciatore"
    log "2) Disinstalla il lanciatore"
    read -r -p "Scelta [1/2]: " scelta
    case "$scelta" in
      1) printf 'install' ;;
      2) printf 'uninstall' ;;
      *) return 1 ;;
    esac
  fi
}

notify_done() {
  local text="$1"
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="$APP_NAME" --width=620 --text="$text" 2>/dev/null || true
  elif command -v kdialog >/dev/null 2>&1; then
    kdialog --msgbox "$text" 2>/dev/null || true
  else
    log "$text"
  fi
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v pkexec >/dev/null 2>&1; then
    pkexec "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    warn "Non trovo pkexec o sudo. Installa manualmente le dipendenze."
    return 1
  fi
}

detect_os() {
  OS_ID="unknown"
  OS_LIKE=""
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
  fi
}

install_dependencies() {
  local missing=()
  for cmd in openssl xsltproc wkhtmltopdf; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  command -v zenity >/dev/null 2>&1 || command -v kdialog >/dev/null 2>&1 || missing+=("zenity")

  if (( ${#missing[@]} == 0 )); then
    log "Dipendenze già presenti."
    return 0
  fi

  detect_os
  log "Sistema rilevato: $OS_ID $OS_LIKE"
  log "Dipendenze mancanti: ${missing[*]}"

  if [[ "$OS_ID" == "opensuse"* || "$OS_ID" == "sles" || "$OS_LIKE" == *"suse"* ]]; then
    command -v zypper >/dev/null 2>&1 || { warn "zypper non trovato."; return 1; }
    run_as_root zypper --non-interactive install openssl libxslt-tools wkhtmltopdf zenity xdg-utils || \
    run_as_root zypper --non-interactive install openssl libxslt1 wkhtmltopdf zenity xdg-utils
  elif [[ "$OS_ID" == "linuxmint" || "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_LIKE" == *"debian"* || "$OS_LIKE" == *"ubuntu"* ]]; then
    command -v apt-get >/dev/null 2>&1 || { warn "apt-get non trovato."; return 1; }
    run_as_root apt-get update
    run_as_root apt-get install -y openssl xsltproc wkhtmltopdf zenity xdg-utils
  else
    warn "Distribuzione non riconosciuta automaticamente."
    warn "Installa manualmente: openssl, xsltproc/libxslt-tools, wkhtmltopdf, zenity o kdialog, xdg-utils."
    return 1
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

create_launcher() {
  mkdir -p "$LOCAL_BIN_DIR" "$LOCAL_APP_DIR" "$LOCAL_ICON_DIR" "$DESKTOP_DIR"

  if [ ! -f "$APP_SCRIPT" ]; then
    warn "File applicazione non trovato: $APP_SCRIPT"
    exit 1
  fi

  chmod +x "$APP_SCRIPT" "$SCRIPT_DIR/genera_pdf.sh" "$UNINSTALL_SCRIPT" 2>/dev/null || true

  cat > "$LAUNCHER_PATH" <<EOF2
#!/usr/bin/env bash
cd "$SCRIPT_DIR" || exit 1
exec "$APP_SCRIPT" "\$@"
EOF2
  chmod +x "$LAUNCHER_PATH"

  if [ -f "$ICON_SRC" ]; then
    cp -f "$ICON_SRC" "$ICON_DEST"
  else
    warn "Icona non trovata: $ICON_SRC"
  fi

  cat > "$DESKTOP_PATH" <<EOF2
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=$APP_COMMENT
Exec=$LAUNCHER_PATH
Path=$SCRIPT_DIR
Icon=$APP_ID
Terminal=false
StartupNotify=true
Categories=Utility;Office;Viewer;
Keywords=xml;p7m;fattura;elettronica;pdf;xslt;xsl;gestionale;open;
EOF2
  chmod +x "$DESKTOP_PATH"

  cp -f "$DESKTOP_PATH" "$DESKTOP_COPY" 2>/dev/null || true
  chmod +x "$DESKTOP_COPY" 2>/dev/null || true

  if command -v gio >/dev/null 2>&1; then
    gio set "$DESKTOP_COPY" metadata::trusted true >/dev/null 2>&1 || true
  fi
  refresh_desktop
}

uninstall_launcher() {
  rm -f "$LAUNCHER_PATH" "$DESKTOP_PATH" "$DESKTOP_COPY" "$ICON_DEST"
  refresh_desktop
}

ACTION="$(ask_action "${1:-}")" || exit 1
case "$ACTION" in
  install)
    install_dependencies || warn "Installazione dipendenze non completata. Il lanciatore verrà creato comunque."
    create_launcher
    notify_done "Installazione completata.\n\nVoce menu:\n$DESKTOP_PATH\n\nIcona desktop:\n$DESKTOP_COPY\n\nSe l'icona non compare subito, esci e rientra oppure riavvia il pannello/menu."
    ;;
  uninstall)
    uninstall_launcher
    notify_done "Disinstallazione completata.\n\nSono stati rimossi il lanciatore, la voce di menu e l'icona installata.\n\nLa cartella del progetto non è stata cancellata."
    ;;
  *) exit 1 ;;
esac
