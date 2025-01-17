# xml-to-pdf-automation-linux
Permette di trasformare in file pdf le fatture elettroniche xml scaricate dallo SDI attraverso i fogli di stile presenti nel prgramma Gestionale Open

# Script di automazione da XML a PDF per Linux

## 🛠️ Panoramica

Questo repository contiene uno script bash, `genera_pdf.sh`, progettato per automatizzare la conversione di file XML in PDF utilizzando i fogli di stile XSL su sistemi Linux. È stato scritto principalmente per il programma Gestionale Open per tanto i fogli di stile verranno cercati nella sotto cartella dell'utente in /home/utente/.wine/... Lo script è altamente flessibile e facile da usare, consentendo agli utenti di:

- Selezionare tra più fogli di stile XSLT, presenti nella directory `exe` del programma GestionaleOpen.
- Elaborare i file da qualsiasi directory specificata.
- Produrre file PDF nella directory dei dati o in una destinazione predefinita.

Questo strumento è ideale per sviluppatori, aziende o chiunque abbia bisogno di automatizzare la trasformazione di dati XML in documenti PDF dall'aspetto professionale, da un singolo file a una quantità anche annuale di file.

---

## ✨ Caratteristiche

- **Rilevamento automatico dell'utente**: Non è necessario configurare manualmente il nome utente; si adatta all'utente Linux corrente.
- Percorsi di ingresso e di uscita dinamici**: Supporta directory XML personalizzate e posizioni di output predefinite.
- Selezione interattiva**: Permette di scegliere tra una serie di fogli di stile XSLT per una maggiore flessibilità.
- **Generazione di PDF**: Crea automaticamente file PDF in formato A4 utilizzando `wkhtmltopdf`.
- **Gestione degli errori**: Assicura un funzionamento regolare con messaggi informativi per gli errori e i file mancanti.

---
## 📝 Modifiche da Effetture dall'utente
- file **genera_pdf.sh** : va modificato il nome della directory finale,
     1. dove `documenti_XXXX` corrisponde alla cartelle documenti dell'utente che utilizzate
     2. dove `Fatture_elettroniche_AAAA` : corrisponde alla cartella dove volete salvare le vostre fatture in formato PDF o entrambe sia XLS che PDF

- La riga da modificare è riga 11 corrispondente alla directoy di default.
  ```bash
  ../documenti_TEX9/Fatture_elettroniche_AAAA
  ```

## 🚀 Requisiti

Prima di eseguire lo script, assicuratevi di avere installato i seguenti strumenti:

1. **xsltproc**  
   Per applicare le trasformazioni XSLT, serve per trasformare  XML con un maschera XSL in HTML:
2. **wkhtmltopdf**
   Per trasformare da HTML a file PDF:

## 🛠️ Installazione per derivate Debian
   ```bash
   sudo apt-get install xsltproc wkhtmltopdf
```

## 🛠️ Installazione per OpenSuse

Vanno installati tramite Yast i seguenti file:
- **xlstproc** (serve per trasformare  XML con un maschera XSL in HTML)
- **wkhtmltopdf** (serve per trasformare un file HTML in file PDF)

per gli utenti OpenSuse effettuare la ricerca anche per tipo di file in quanto potrebbe essere contenuto il file all'interno di altre librerie/programmi
## 🎥 Video Dimostrativo

Guarda il video dimostrativo su [YouTube]([https://www.youtube.com/watch?v=WmFyPfeM_6o](https://youtu.be/WmFyPfeM_6o).

[![Guarda il Video su YouTube](https://img.youtube.com/vi/WmFyPfeM_6o/0.jpg)]([https://www.youtube.com/watch?v=WmFyPfeM_6o])

## 🤝 Contribuire

I contributi sono benvenuti! Sentitevi liberi di inviare una richiesta di pull o di aprire un problema per suggerire miglioramenti o segnalare bug, sarò ben lieto di modificare e migliorare questo script.
