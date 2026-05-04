#!/usr/bin/env bash
set -u

APP_TITLE="XML to PDF Automation"
CURRENT_USER="$(id -un)"
YEAR="$(date +%Y)"
LOG_FILE="${TMPDIR:-/tmp}/xml-to-pdf-automation-$$.log"

STILE_DIR="/home/$CURRENT_USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/exe"
FOGLI_DI_STILE=("FoglioStile.xsl" "FoglioStileAssoSoftware.xsl" "FoglioStilePrivati.xsl" "FoglioStilePA.xsl")
DESTINAZIONE_DEFAULT="/home/$CURRENT_USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/documenti_UTNX/Fatture_elettroniche_$YEAR"

msg() {
    if command -v zenity >/dev/null 2>&1; then
        zenity --info --title="$APP_TITLE" --width=620 --text="$1" 2>/dev/null || true
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --msgbox "$1" 2>/dev/null || true
    else
        printf '%s\n' "$1"
    fi
}

error_msg() {
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --title="$APP_TITLE" --width=680 --text="$1" 2>/dev/null || true
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --error "$1" 2>/dev/null || true
    else
        printf 'Errore: %s\n' "$1" >&2
    fi
}

show_log() {
    if command -v zenity >/dev/null 2>&1; then
        zenity --text-info --title="Log - $APP_TITLE" --width=900 --height=560 --filename="$LOG_FILE" 2>/dev/null || true
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --textbox "$LOG_FILE" 900 560 2>/dev/null || true
    fi
}

choose_list() {
    local title="$1" text="$2"; shift 2
    if command -v zenity >/dev/null 2>&1; then
        zenity --list --title="$title" --text="$text" --width=720 --height=330 --column="Valore" --column="Descrizione" "$@" 2>/dev/null
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --menu "$text" "$@" 2>/dev/null
    else
        return 1
    fi
}

choose_dir() {
    local title="$1"
    if command -v zenity >/dev/null 2>&1; then
        zenity --file-selection --directory --title="$title" 2>/dev/null
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --getexistingdirectory "$HOME" "$title" 2>/dev/null
    else
        return 1
    fi
}

append_log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG_FILE"
}

progress_line() {
    local percent="$1" text="$2"
    printf '%s\n# %s\n' "$percent" "$text"
    append_log "$text"
}

check_comandi() {
    local mancanti=()
    for cmd in openssl xsltproc wkhtmltopdf; do
        command -v "$cmd" >/dev/null 2>&1 || mancanti+=("$cmd")
    done
    if (( ${#mancanti[@]} > 0 )); then
        error_msg "Mancano questi programmi: ${mancanti[*]}\n\nEsegui prima installa-lanciatore.sh."
        exit 1
    fi
    if ! command -v zenity >/dev/null 2>&1 && ! command -v kdialog >/dev/null 2>&1; then
        error_msg "Manca una interfaccia grafica: installa zenity o kdialog."
        exit 1
    fi
}

seleziona_foglio_stile() {
    local args=() f scelta
    for f in "${FOGLI_DI_STILE[@]}"; do
        args+=("$f" "$STILE_DIR/$f")
    done
    scelta="$(choose_list "Foglio di stile" "Seleziona il foglio di stile XSL da usare:" "${args[@]}")" || exit 1
    [[ -n "$scelta" ]] || exit 1
    FOGLIO="$scelta"
    if [[ ! -f "$STILE_DIR/$FOGLIO" ]]; then
        error_msg "Foglio di stile non trovato:\n$STILE_DIR/$FOGLIO"
        exit 1
    fi
}

ottieni_directory_dati() {
    DATI_DIR="$(choose_dir "Scegli la cartella che contiene i file XML o XML.P7M")" || exit 1
    [[ -d "$DATI_DIR" ]] || { error_msg "Directory non valida."; exit 1; }
}

determina_destinazione() {
    local scelta
    scelta="$(choose_list "Destinazione PDF" "Dove vuoi salvare i PDF?" \
        "dati" "Nella stessa cartella dei file XML" \
        "default" "$DESTINAZIONE_DEFAULT")" || exit 1
    case "$scelta" in
        dati) DESTINAZIONE="$DATI_DIR" ;;
        default) DESTINAZIONE="$DESTINAZIONE_DEFAULT" ;;
        *) exit 1 ;;
    esac
    mkdir -p "$DESTINAZIONE" || { error_msg "Impossibile creare la destinazione:\n$DESTINAZIONE"; exit 1; }
}

collect_files() {
    mapfile -d '' -t P7M_FILES < <(find "$DATI_DIR" -maxdepth 1 -type f \( -iname '*.xml.p7m' -o -iname '*.p7m' \) -print0 | sort -z)
    mapfile -d '' -t XML_FILES < <(find "$DATI_DIR" -maxdepth 1 -type f -iname '*.xml' -print0 | sort -z)
}

xml_name_from_p7m() {
    local p7m_file="$1"
    if [[ "$p7m_file" == *.xml.p7m || "$p7m_file" == *.XML.P7M ]]; then
        printf '%s' "${p7m_file%.*}"
    else
        printf '%s' "${p7m_file}.xml"
    fi
}

process_with_progress() {
    : > "$LOG_FILE"
    append_log "Avvio programma"
    append_log "Foglio di stile: $STILE_DIR/$FOGLIO"
    append_log "Directory dati: $DATI_DIR"
    append_log "Destinazione PDF: $DESTINAZIONE"

    collect_files
    local p7m_count="${#P7M_FILES[@]}"
    local xml_initial_count="${#XML_FILES[@]}"
    local total_steps=$(( p7m_count + xml_initial_count + 1 ))
    (( total_steps < 1 )) && total_steps=1
    local step=0 percent=0
    local p7m_file xml_file file base_name output_html output_pdf
    local estratti=0 pdf_creati=0 errori=0 saltati=0

    progress_line 0 "Preparazione: trovati $p7m_count file P7M e $xml_initial_count file XML."

    for p7m_file in "${P7M_FILES[@]}"; do
        [[ -f "$p7m_file" ]] || continue
        xml_file="$(xml_name_from_p7m "$p7m_file")"
        ((step++)); percent=$(( step * 100 / total_steps ))
        progress_line "$percent" "Estrazione P7M: $(basename "$p7m_file")"
        if [[ -f "$xml_file" ]]; then
            append_log "XML già presente, non sovrascrivo: $xml_file"
            ((saltati++))
            continue
        fi
        if openssl smime -verify -in "$p7m_file" -noverify -inform DER -out "$xml_file" >/dev/null 2>>"$LOG_FILE"; then
            append_log "Estratto XML: $xml_file"
            ((estratti++))
        elif openssl smime -verify -in "$p7m_file" -noverify -inform PEM -out "$xml_file" >/dev/null 2>>"$LOG_FILE"; then
            append_log "Estratto XML: $xml_file"
            ((estratti++))
        else
            rm -f "$xml_file"
            append_log "ERRORE: estrazione non riuscita: $p7m_file"
            ((errori++))
        fi
    done

    mapfile -d '' -t XML_FILES < <(find "$DATI_DIR" -maxdepth 1 -type f -iname '*.xml' -print0 | sort -z)
    local xml_count="${#XML_FILES[@]}"
    if (( xml_count == 0 )); then
        progress_line 100 "Nessun file XML trovato dopo l'estrazione."
        append_log "ERRORE: nessun XML da convertire."
        return 1
    fi

    total_steps=$(( p7m_count + xml_count ))
    (( total_steps < 1 )) && total_steps=1

    for file in "${XML_FILES[@]}"; do
        [[ -f "$file" ]] || continue
        ((step++)); percent=$(( step * 100 / total_steps )); (( percent > 99 )) && percent=99
        base_name="$(basename "$file")"
        base_name="${base_name%.*}"
        output_html="${TMPDIR:-/tmp}/${base_name}_$$.html"
        output_pdf="$DESTINAZIONE/${base_name}.pdf"

        progress_line "$percent" "Trasformazione XML in HTML: $(basename "$file")"
        if ! xsltproc "$STILE_DIR/$FOGLIO" "$file" > "$output_html" 2>>"$LOG_FILE"; then
            append_log "ERRORE xsltproc: $file"
            rm -f "$output_html"
            ((errori++))
            continue
        fi
        if [[ ! -s "$output_html" ]]; then
            append_log "ERRORE: HTML vuoto per $file"
            rm -f "$output_html"
            ((errori++))
            continue
        fi

        progress_line "$percent" "Generazione PDF A4: $(basename "$output_pdf")"
        if wkhtmltopdf --encoding UTF-8 --page-size A4 --enable-local-file-access "$output_html" "$output_pdf" >/dev/null 2>>"$LOG_FILE"; then
            append_log "PDF creato: $output_pdf"
            ((pdf_creati++))
        else
            append_log "ERRORE wkhtmltopdf: $file"
            ((errori++))
        fi
        rm -f "$output_html"
    done

    progress_line 100 "Operazione completata. PDF creati: $pdf_creati - Errori: $errori."
    RISULTATO="PDF creati: $pdf_creati\nXML estratti da P7M: $estratti\nFile saltati perché già presenti: $saltati\nErrori: $errori\n\nDestinazione:\n$DESTINAZIONE\n\nLog:\n$LOG_FILE"
    return 0
}

check_comandi
seleziona_foglio_stile
ottieni_directory_dati
determina_destinazione

if command -v zenity >/dev/null 2>&1; then
    if process_with_progress | zenity --progress \
        --title="$APP_TITLE" \
        --width=760 \
        --text="Preparazione conversione..." \
        --percentage=0 \
        --auto-close \
        --no-cancel 2>/dev/null; then
        msg "Operazione completata.\n\n$(tail -n 8 "$LOG_FILE")"
    else
        error_msg "Operazione interrotta o non completata.\n\nControlla il log:\n$LOG_FILE"
    fi
else
    process_with_progress
    msg "Operazione completata.\n\n$RISULTATO"
fi

if command -v zenity >/dev/null 2>&1; then
    if zenity --question --title="$APP_TITLE" --width=520 --text="Vuoi visualizzare il log completo dell'operazione?" 2>/dev/null; then
        show_log
    fi
fi
