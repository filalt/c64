# c64
Questo programma permette di aggiungere alcune funzionalità al basic standard del c64.

Il programma è scritto in assembly ed è stato assemblato utilizzando Kick Assembler v5.4.

Per verificarne il funzionamento ho utilizzato Vice in versione 2.4.


# Prima funzionalità
Vi è la possibilità di spostare il cursore utilizzando uno sprite a forma di pointer.
Il pointer è controllato dal joystick in porta due.
Il pointer si può muovere nelle quattro consuete direzioni e utilizzando il tasto di fire
si sposta il cursore nelle vicinanze del pointer.
Ogni azione sul joystick è accompagnata da un feedback; il bordo dello schermo cambia colore.

# Seconda funzionalità
E' stata aggiunta la funzionalità di lettura di un numero in formato hex dal basic precedendolo
con il simbolo di dollaro.
Sono supportate da un minimo di una cifra ad un massimo di quattro cifre che descrivono il numero 
in formato hex.
Per utilizzare questa funzionalità dopo aver installato il programma mediante il suo sys ricordatevi di impartire un comando new dal basic.
