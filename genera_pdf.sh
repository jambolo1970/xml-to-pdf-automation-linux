#!/bin/bash

# Determina l'utente corrente automaticamente
USER=$(whoami)

# Percorso del foglio di stile XSL
STILE_DIR="/home/$USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/exe"
FOGLI_DI_STILE=("FoglioStile.xsl" "FoglioStileAssoSoftware.xsl" "FoglioStilePrivati.xsl" "FoglioStilePA.xsl")

# Directory di destinazione predefinita
# La directory di destinaizone di default, va assegnata manualmente perchè la voce ../documenti_UTNX/...
# va cambiata col nome dell'utente del gestionale, e si vuole stampare il pdf corrispondente
# nella cartella appropriata questo dovrà puntare nella directory che si decide assegnare nella stringa di 
# DESTINAZIONE_DEFAULT="..."
# se si vuole assegnare una a proprio piacere fate pure, in caso contrario si può utilizzare la directory dove
# si è salvati i propri file xml o con questa versione xml.p7m 
#
# Naturalmente se non si vuole stampare i pdf nell'anno corrente per qualsiasi motivo si può assegnare una directory
# fissa oppure utilizzare l'opzione di stampare nella directory di orgine dei dati
# Ottiene l'anno corrente

YEAR=$(date +%Y)

# Directory di destinazione predefinita
DESTINAZIONE_DEFAULT="/home/$USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/documenti_UTNX/Fatture_elettroniche_$YEAR"

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
    read -p "Inserisci la directory dei file XML (o XML.P7M): " DATI_DIR
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

    mkdir -p "$DESTINAZIONE"
}

# Funzione per estrarre XML dai file .p7m
estrai_tutti_p7m() {
    echo "🔍 Ricerca file .p7m nella directory..."
    for p7m_file in "$DATI_DIR"/*.xml.p7m; do
        if [[ -f "$p7m_file" ]]; then
            xml_file="${p7m_file%.p7m}"  # Rimuove l'estensione .p7m
            if [[ ! -f "$xml_file" ]]; then
                echo "🛠️ Estrazione di $p7m_file → $xml_file"
                openssl smime -verify -in "$p7m_file" -noverify -inform DER -out "$xml_file" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "✅ Estratto con successo: $xml_file"
                else
                    echo "❌ Errore nell'estrazione del file XML da $p7m_file"
                fi
            else
                echo "ℹ️ Il file XML esiste già: $xml_file (salto l'estrazione)"
            fi
        fi
    done
}

# Funzione per trasformare XML in PDF
trasforma_xml_in_pdf() {
    echo "📄 Inizio trasformazione XML → PDF"
    for file in "$DATI_DIR"/*.xml; do
        if [[ -f "$file" ]]; then
            base_name=$(basename "$file" .xml)
            output_html="/tmp/${base_name}.html"
            output_pdf="$DESTINAZIONE/${base_name}.pdf"

            echo "🔄 Trasformazione di $file con XSLT..."
            xsltproc "$STILE_DIR/$FOGLIO" "$file" > "$output_html"

            # Verifica che il file HTML non sia vuoto
            if [[ ! -s "$output_html" ]]; then
                echo "❌ Errore: La trasformazione XSLT non ha prodotto output valido per $file"
                continue
            fi

            echo "🖨️ Generazione PDF: $output_pdf"
            wkhtmltopdf --page-size A4 "$output_html" "$output_pdf"

            if [[ $? -eq 0 ]]; then
                echo "✅ PDF creato con successo: $output_pdf"
            else
                echo "❌ Errore nella generazione del PDF per $file"
            fi

            rm -f "$output_html"
        fi
    done
}

# Script principale
seleziona_foglio_stile
ottieni_directory_dati
determina_destinazione
estrai_tutti_p7m  # Prima estraiamo tutti i P7M in XML
trasforma_xml_in_pdf  # Poi trasformiamo tutti gli XML in PDF

echo "🎉 Tutti i file sono stati processati con successo."

