#!/bin/bash

# Determina l'utente corrente automaticamente
USER=$(whoami)

# Directory fissa dei fogli di stile
STILE_DIR="/home/$USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/exe"
FOGLI_DI_STILE=("FoglioStile.xsl" "FoglioStileAssoSoftware.xsl" "FoglioStilePrivati.xsl" "FoglioStilePA.xsl")

# Directory di destinazione predefinita
DESTINAZIONE_DEFAULT="/home/$USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/documenti_TEX9/Fatture_elettroniche_AAAA"

# Funzione per selezionare il foglio di stile
seleziona_foglio_stile() {
    echo "Seleziona il foglio di stile:"
    for i in "${!FOGLI_DI_STILE[@]}"; do
        echo "$((i + 1))) ${FOGLI_DI_STILE[$i]}"
    done

    read -p "Inserisci il numero del foglio di stile: " scelta
    if [[ $scelta -ge 1 && $scelta -le ${#FOGLI_DI_STILE[@]} ]]; then
        FOGLIO="${FOGLI_DI_STILE[$((scelta - 1))]}"
        echo "Hai selezionato: $FOGLIO"
    else
        echo "Scelta non valida. Esco."
        exit 1
    fi
}

# Funzione per ottenere la directory dei dati
ottieni_directory_dati() {
    read -p "Inserisci la directory dei file XML: " DATI_DIR
    if [[ ! -d "$DATI_DIR" ]]; then
        echo "La directory specificata non esiste. Esco."
        exit 1
    fi
}

# Funzione per determinare la directory di destinazione
determina_destinazione() {
    echo "Vuoi salvare i PDF nella directory dei dati ($DATI_DIR) o nella destinazione predefinita ($DESTINAZIONE_DEFAULT)?"
    echo "1) Directory dei dati"
    echo "2) Destinazione predefinita"

    read -p "Inserisci 1 o 2: " scelta_destinazione
    if [[ $scelta_destinazione == "1" ]]; then
        DESTINAZIONE="$DATI_DIR"
    elif [[ $scelta_destinazione == "2" ]]; then
        DESTINAZIONE="$DESTINAZIONE_DEFAULT"
    else
        echo "Scelta non valida. Esco."
        exit 1
    fi

    # Crea la directory di destinazione se non esiste
    mkdir -p "$DESTINAZIONE"
}

# Funzione per trasformare XML in PDF
trasforma_xml_in_pdf() {
    for file in "$DATI_DIR"/*.xml; do
        if [[ -f "$file" ]]; then
            base_name=$(basename "$file" .xml)
            output_html="/tmp/${base_name}.html"
            output_pdf="$DESTINAZIONE/${base_name}.pdf"

            # Trasformazione con xsltproc
            xsltproc "$STILE_DIR/$FOGLIO" "$file" > "$output_html"

            # Conversione in PDF con wkhtmltopdf
            wkhtmltopdf --page-size A4 "$output_html" "$output_pdf"

            if [[ $? -eq 0 ]]; then
                echo "Generato PDF: $output_pdf"
            else
                echo "Errore nella generazione del PDF per $file"
            fi

            # Rimuove il file HTML temporaneo
            rm -f "$output_html"
        else
            echo "Nessun file XML trovato nella directory $DATI_DIR."
        fi
    done
}

# Script principale
seleziona_foglio_stile
ottieni_directory_dati
determina_destinazione
trasforma_xml_in_pdf

echo "Tutti i file sono stati processati con successo."
