# XML to PDF Automation Linux

Script Bash per trasformare fatture elettroniche italiane in PDF partendo da file `.xml` oppure `.xml.p7m`, usando i fogli di stile XSL di Gestionale Open.

Il programma lavora in due fasi:

1. cerca i file `.xml.p7m` e li estrae in `.xml`, senza cancellare il file XML generato;
2. prende tutti i file `.xml` presenti nella cartella e li trasforma in PDF A4 tramite XSLT e `wkhtmltopdf`.

## Novità principali

- Avvio grafico senza terminale.
- Barra di avanzamento durante la conversione.
- Testo descrittivo che mostra cosa sta facendo il programma: estrazione P7M, trasformazione XML, generazione PDF.
- Visualizzazione del file log a fine processo per vedere eventuali anomalie.
- Installazione o aggiornamento del lanciatore dal file `installa-lanciatore.sh`.
- Disinstallazione del lanciatore dal file `disinstalla-lanciatore.sh` oppure dal menu di `installa-lanciatore.sh`.
- Icona dedicata del progetto, senza dipendere da icone di altri programmi come `masterpdfeditor`.
- Riconoscimento base della distribuzione Linux tramite `/etc/os-release`.
- Installazione automatica delle dipendenze su openSUSE e Linux Mint/Ubuntu/Debian.
- Interfaccia grafica con `zenity`, con fallback a `kdialog` dove disponibile.
- Versione da terminale ancora disponibile tramite `genera_pdf.sh`.

## Dipendenze

Il programma usa:

- `openssl`, per estrarre XML dai file `.p7m`;
- `xsltproc`, per applicare il foglio di stile XSL;
- `wkhtmltopdf`, per generare il PDF;
- `zenity` o `kdialog`, per usare il lanciatore senza aprire il terminale;
- `xdg-utils`, per aggiornare menu e integrazione desktop.

Su openSUSE il pacchetto che fornisce `xsltproc` può essere `libxslt-tools` o, su alcune versioni/repository, `libxslt1`.

## Installazione rapida

Scarica il progetto, entra nella cartella e avvia:

```bash
chmod +x installa-lanciatore.sh disinstalla-lanciatore.sh genera_pdf.sh genera_pdf_gui.sh
```
Oppure in modalità grafica seleziona all'interno della cartella i file *.sh e poi Tasto dx --> prorietà  e metti il flag sul tag "Permessi" ✔️ Eseguibile
poi da terminale

```bash
./installa-lanciatore.sh
```

Lo script chiede se vuoi:

- installare o aggiornare il lanciatore;
- disinstallare il lanciatore.

Durante l'installazione vengono creati:

- un comando in `~/.local/bin/xml-to-pdf-automation`;
- una voce nel menu in `~/.local/share/applications/xml-to-pdf-automation.desktop`;
- una copia del lanciatore sul desktop;
- l'icona in `~/.local/share/icons/hicolor/scalable/apps/xml-to-pdf-automation.svg`.

Dopo l'installazione puoi avviare il programma dal menu oppure dall'icona sul desktop.

## Disinstallazione

Per rimuovere solo il lanciatore, la voce di menu e l'icona:

```bash
./disinstalla-lanciatore.sh
```

In alternativa puoi usare:

```bash
./installa-lanciatore.sh --uninstall
```

La disinstallazione non cancella la cartella del progetto e non cancella gli script.

## Uso grafico

Avvia **XML to PDF Automation** dal menu o dal desktop.

Il programma chiede:

1. quale foglio di stile usare presenti nella directory di Gestionale Open /home/$CURRENT_USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/exe :
   - `FoglioStile.xsl`
   - `FoglioStileAssoSoftware.xsl`
   - `FoglioStilePrivati.xsl`
   - `FoglioStilePA.xsl`

   Se i vostri XSL sono presenti in un altra directoy la riga 9 del file genera_pdf_gui.sh va cambiata la voce : STILE_DIR="/home/$CURRENT_USER/METTI_LA_TUA_DIRECTORY_DOVE_REPERIRE_I_FILE_XSL"
2. la cartella che contiene i file `.xml` o `.xml.p7m`;
3. dove salvare i PDF:
   - nella stessa cartella dei dati;
   - nella cartella predefinita di Gestionale Open.

Durante la conversione compare una finestra con barra di avanzamento e messaggi sul lavoro in corso.

A fine processo puoi visualizzare il log completo con il dettaglio delle operazioni effettuate.

## Uso da terminale

```bash
./genera_pdf.sh
```

La versione da terminale usa la stessa logica della versione grafica.

## Percorsi di Gestionale Open

Per impostazione predefinita i fogli di stile sono cercati in:

```text
/home/$USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/exe
```

La destinazione predefinita usa l'anno corrente:

```text
/home/$USER/.wine/drive_c/Gestionale_Open/Files/Programma_GO/documenti_UTNX/Fatture_elettroniche_$YEAR
```

La parte `documenti_UTNX` deve essere adattata al proprio utente/documenti di Gestionale Open se necessario.

## Note importanti

- I file `.xml.p7m` vengono convertiti in `.xml` e il file `.xml` generato non viene cancellato.
- Se un file `.xml` esiste già, non viene sovrascritto.
- Tutti i file `.xml` presenti nella cartella vengono poi trasformati in PDF.
- I file PDF vengono creati in formato A4.

## Licenza

GPL-3.0.
