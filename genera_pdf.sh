#!/usr/bin/env bash
set -u

CURRENT_USER="$(id -un)"
YEAR="$(date +%Y)"

STILE_DIR="/home/$CURRENT_USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/exe"
FOGLI_DI_STILE=("FoglioStile.xsl" "FoglioStileAssoSoftware.xsl" "FoglioStilePrivati.xsl" "FoglioStilePA.xsl")
DESTINAZIONE_DEFAULT="/home/$CURRENT_USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/documenti_UTNX/Fatture_elettroniche_$YEAR"

log() { printf '%s\n' "$*"; }
err() { printf 'Errore: %s\n' "$*" >&2; }

check_comandi() {
    local mancanti=()
    for cmd in openssl xsltproc wkhtmltopdf; do
        command -v "$cmd" >/dev/null 2>&1 || mancanti+=("$cmd")
    done
    if (( ${#mancanti[@]} > 0 )); then
        err "mancano questi programmi: ${mancanti[*]}"
        err "Esegui prima ./installa-lanciatore.sh oppure installali con il gestore pacchetti."
        exit 1
    fi
}

seleziona_foglio_stile() {
    log "Seleziona il foglio di stile:"
    for i in "${!FOGLI_DI_STILE[@]}"; do
        log "$((i + 1))) ${FOGLI_DI_STILE[$i]}"
    done

    read -r -p "Inserisci il numero del foglio di stile: " scelta
    if [[ "$scelta" =~ ^[0-9]+$ ]] && (( scelta >= 1 && scelta <= ${#FOGLI_DI_STILE[@]} )); then
        FOGLIO="${FOGLI_DI_STILE[$((scelta - 1))]}"
        if [[ ! -f "$STILE_DIR/$FOGLIO" ]]; then
            err "foglio di stile non trovato: $STILE_DIR/$FOGLIO"
            exit 1
        fi
        log "Hai selezionato: $FOGLIO"
    else
        err "scelta non valida."
        exit 1
    fi
}

ottieni_directory_dati() {
    read -r -p "Inserisci la directory dei file XML o XML.P7M: " DATI_DIR
    if [[ ! -d "$DATI_DIR" ]]; then
        err "la directory specificata non esiste."
        exit 1
    fi
}

determina_destinazione() {
    log "Vuoi salvare i PDF nella directory dei dati ($DATI_DIR) o nella destinazione predefinita ($DESTINAZIONE_DEFAULT)?"
    log "1) Directory dei dati"
    log "2) Destinazione predefinita"
    read -r -p "Inserisci 1 o 2: " scelta_destinazione

    case "$scelta_destinazione" in
        1) DESTINAZIONE="$DATI_DIR" ;;
        2) DESTINAZIONE="$DESTINAZIONE_DEFAULT" ;;
        *) err "scelta non valida."; exit 1 ;;
    esac

    mkdir -p "$DESTINAZIONE"
}

estrai_tutti_p7m() {
    shopt -s nullglob
    local p7m_files=("$DATI_DIR"/*.xml.p7m "$DATI_DIR"/*.XML.P7M "$DATI_DIR"/*.p7m "$DATI_DIR"/*.P7M)
    local p7m_file xml_file estratti=0 errori=0

    log "Ricerca file P7M nella directory..."
    for p7m_file in "${p7m_files[@]}"; do
        [[ -f "$p7m_file" ]] || continue

        if [[ "$p7m_file" == *.xml.p7m || "$p7m_file" == *.XML.P7M ]]; then
            xml_file="${p7m_file%.*}"
        else
            xml_file="${p7m_file}.xml"
        fi

        if [[ -f "$xml_file" ]]; then
            log "Il file XML esiste già: $xml_file"
            continue
        fi

        log "Estrazione: $p7m_file -> $xml_file"
        if openssl smime -verify -in "$p7m_file" -noverify -inform DER -out "$xml_file" >/dev/null 2>&1; then
            log "Estratto: $xml_file"
            ((estratti++))
        elif openssl smime -verify -in "$p7m_file" -noverify -inform PEM -out "$xml_file" >/dev/null 2>&1; then
            log "Estratto: $xml_file"
            ((estratti++))
        else
            rm -f "$xml_file"
            err "estrazione non riuscita: $p7m_file"
            ((errori++))
        fi
    done
    shopt -u nullglob

    log "Estrazione P7M conclusa. XML estratti: $estratti - errori: $errori"
}

trasforma_xml_in_pdf() {
    shopt -s nullglob
    local xml_files=("$DATI_DIR"/*.xml "$DATI_DIR"/*.XML)
    local file base_name output_html output_pdf convertiti=0 errori=0

    if (( ${#xml_files[@]} == 0 )); then
        err "nessun file XML trovato in $DATI_DIR"
        exit 1
    fi

    log "Inizio trasformazione XML -> PDF"
    for file in "${xml_files[@]}"; do
        [[ -f "$file" ]] || continue
        base_name="$(basename "$file")"
        base_name="${base_name%.*}"
        output_html="/tmp/${base_name}_$$.html"
        output_pdf="$DESTINAZIONE/${base_name}.pdf"

        log "Trasformazione XSLT: $file"
        if ! xsltproc "$STILE_DIR/$FOGLIO" "$file" > "$output_html" 2>"/tmp/${base_name}_xslt_$$.log"; then
            err "xsltproc non è riuscito su $file"
            cat "/tmp/${base_name}_xslt_$$.log" >&2
            rm -f "$output_html" "/tmp/${base_name}_xslt_$$.log"
            ((errori++))
            continue
        fi
        rm -f "/tmp/${base_name}_xslt_$$.log"

        if [[ ! -s "$output_html" ]]; then
            err "HTML vuoto per $file"
            rm -f "$output_html"
            ((errori++))
            continue
        fi

        log "Creazione PDF: $output_pdf"
        if wkhtmltopdf --encoding UTF-8 --page-size A4 --enable-local-file-access "$output_html" "$output_pdf" >/dev/null 2>&1; then
            log "PDF creato: $output_pdf"
            ((convertiti++))
        else
            err "wkhtmltopdf non è riuscito su $file"
            ((errori++))
        fi
        rm -f "$output_html"
    done
    shopt -u nullglob

    log "Conversione conclusa. PDF creati: $convertiti - errori: $errori"
}

check_comandi
seleziona_foglio_stile
ottieni_directory_dati
determina_destinazione
estrai_tutti_p7m
trasforma_xml_in_pdf
log "Operazione terminata."
