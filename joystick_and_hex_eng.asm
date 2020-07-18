BasicUpstart2(install)
// -----------------------------------------------------------------------------
// Questo programma installa nel interrupt una routine che gestisce il joystick.
// Ad ogni movimento del joystick corrisponde una modifica del colore del 
// bordo dello schermo e uno spostamento di uno sprite su schermo.
// Alla pressione del fire, viene spostato il cursore vicino allo sprite   
// -----------------------------------------------------------------------------

.const v = $d000
.const chrget = $73
.const chrgot = $79
.const ieval = $030a

        * = $c000 "Interrupt main routine"
        
sprx:   .byte $1b,0
spry:   .byte $34,0
col:    .byte 0
riga:   .byte 0

routine:
        lda $dc00   // leggo valore porta 2 del joystick
        and #$01    // il bit 0 è impostato?
        beq si_0    
        
        lda $dc00   // leggo valore porta 2 del joystick
        and #$02    // il bit 1 è impostato?
        beq si_1
        
        lda $dc00   // leggo valore porta 2 del joystick
        and #$04    // il bit 2 è impostato?
        beq si_2
        
        lda $dc00   // leggo valore porta 2 del joystick
        and #$08    // il bit 3 è impostato?
        beq si_3
        
        lda $dc00   // leggo valore porta 2 del joystick
        and #$10    // il bit 4 è impostato?
        beq si_4
        
        rts         // nessun movimento del joy: fine routine
        
si_0:   lda #$01    // colore bianco su (decr y)
        sta $d020   // nel bordo
        
        dec spry
        
        jsr move
        
        rts         // fine routine
        
si_1:   lda #$02    // colore rosso giu (incr y)
        sta $d020   // nel bordo
        
        inc spry
        
        jsr move
        
        rts         // fine routine
        
si_2:   lda #$03    // colore ciano sx (decr x)
        sta $d020   // nel bordo
        
        dec sprx
        
        lda sprx    
        cmp #$ff
        bne !skip+
        
                    //dec sprx+1  dirty <-- bit 9
        lda sprx+1  // x<256? si: il bit 9 va azzerato
        and #$fe    
        sta sprx+1
        
        
        
!skip:  jsr move
        
        rts         // fine routine
        
si_3:   lda #$04    // colore rosa dx (incr x)
        sta $d020   // nel bordo
        
        inc sprx
        bne !skip+
        
                    //inc sprx+1  dirty <-- bit 9
        lda sprx+1  // x>255? si: il bit 9 va impostato
        ora #$01
        sta sprx+1
        
        
!skip:  jsr move
        
        
        rts         // fine routine
        
si_4:   lda #$05    // colore verde  
        sta $d020   // nel bordo = premuto il pulsante fire del joystick
        jsr move    // aggiorno posizione sprite 
        jsr getcoord   // trasforma coordinate sprite da pixel a mappa schermo
        
        
        ldx riga
        ldy col
        
        lda $cf     // flag cursore acceso
        bne salta   // se il cursore e' visibile salto la routine
        
        lda #$00    // stampa nessun carattere nella nuova posizione
        tya         // tolgo due dalla colonna 
        clc
        sbc #2
        tay
        
        txa         // tolgo cinque dalla riga
        clc
        sbc #5
        tax
        
        clc         // chiede alla routine il set del cursore ad una nuova posizione specificata dai registri x,y
        jsr $fff0
salta:        
        rts         // fine routine

move:   lda sprx    // muove lo sprite
        sta v       // x
        lda sprx+1
        sta v+16    // x (bit 9)
        
        lda spry
        sta v+1     // y
        rts

getcoord:           // trasforma le coordinate da pixel a riga, colonna
        ldx v      
        ldy v+1     
        lda v+16        
        and #%00000001  
        jsr getcoor     // -> X = 0...39
                        // -> Y = 0...24
        stx col
        sty riga
        
        rts

getcoor:
        pha              // salvo acc in stack
        txa              // X -> A inizio calcolo colonna
        
        lsr              // divido per 8
        lsr
        lsr
        and #%00011111
        tax              // A -> X
        
        pla              // recupero acc dallo stack
        cmp #$01         // il bit 9 è impostato?
        bne nonimpostato
        txa              // imposto il bit
        ora #%00100000
        tax 
nonimpostato:

        tya              // Y -> A inizio calcolo riga
        lsr              // divido per 8
        lsr
        lsr
        and #%00011111
        tay              // A -> Y
        
        rts        

install:
        // Puntatore ai dati dello Sprite0  
        lda #13     // blocco 13 -> 64 byte * 13 -> 832 = indirizzo destinazione in memoria
        sta 2040
        lda #1
        sta v+21    // abilita sprite 0 
        sta v+39    // e imposta il colore bianco

        ldx #62     // creo la forma dello sprite,
                    // lda #255   <--- se imposto 255 per ogni locazione dei dati dello sprite ottengo un rettangolo
                    // altrimenti ricopio i dati che definiscono la forma
!loop:  lda sprite1,x
        sta 832,x
        dex
        bpl !loop-

        sei         // stop interrupt
        lda #<myirq // imposto nuovo vettore interrupt
        sta $0314   // il puntatore si trova nelle locazioni $314,$315
        lda #>myirq 
        sta $0315
        cli         // start interrupt
        
        jsr hexinstall // supporto hex aggiunto al basic es. poke $d020,0 viene riconosciuto
        
        rts         // finito: esco dal programma
        
myirq:  
        jsr routine
        jmp $ea31   // codice successivo nel interrupt del basic


// hex support in basic
temp:   .byte 0 
temp2:  .byte 0

hexinstall:
        lda #<evalhex
        sta ieval
        lda #>evalhex
        sta ieval+1
        rts
        
evalhex:
        lda #0      // 0=numeric data, ff=string data
        sta $0d     // VALTYPE basic flag
        
                    // cerco il $ come primo carattere
        jsr chrget
        cmp #'$'    // $24
        beq ishex   // si: trovato il $ analizzo il numero in formato hex
        
                    // no: continuo
        jsr chrgot  // current char 
        jmp $ae8d   // continua normalmente
        
        
// Converte il carattere presente nel acc '0'..'9' 'a'..'f' nel valore corrispondente 
// e lo mette nel acc
        
getreal:
        cmp #$40    // $40'@'
        bcc !skip+  // il codice carattere precede la @ nella tabella ascii? si -> e' un numero, salto l'adc 
        adc #$08    // no -> e' una lettera del numero hex da leggere, sommo 8+carry=9 trovo valore corrispondente alla lettera
!skip:  
        and #$0f    // solo quattro bit per rappresentare un numero da zero a quindici
        rts
      
// Analizzo il numero in formato hex che segue il simbolo del dollaro
//      
ishex:
        ldx #0      // conto i caratteri processati e lo utilizzo per
        stx $63     // azzerare le locazioni risultato: 0 = valore di default se non ci sono caratteri dopo il $
        stx $62
!loop:
        
        jsr chrget  // carattere nel buffer -> acc
        beq finestringa
        
        cmp #$2c    // "," per il caso poke $d020,$a
        beq finestringa
        
        cmp #$29    // ")" per il caso peek ($d020)
        beq finestringa
        
        // Controllo che il carattere analizzato sia un carattere permesso
        // ovvero rientri nel intervallo 0-9 o a-f
        // se il carattere rientra in uno dei due intervalli previsti salto a okcontinue
        // altrimenti segnalo il Syntax Error
        
        // Se ci sono più di quattro caratteri dopo il dollaro segnalo il superamento
        // delle capacità di calcolo della routine mediante Overflow Error
        
        cmp #$30    // "0"
        bmi syntaxerr
        cmp #$3a    // ":"
        bmi okcontinue
        
        cmp #$41    // "a"
        bmi syntaxerr
        cmp #$47    // "g"
        bmi okcontinue
        bpl syntaxerr

syntaxerr:
        ldx #$0b    // indice messaggio. vedi disassembleato kernel basic v2
        jmp $e38b   // stampa messaggio errore syntax err 

        
okcontinue:        
        jsr getreal
        
        cpx #0
        beq primocarattere
        cpx #1
        beq quartocarattere //secondocarattere
        cpx #2
        beq quartocarattere //terzocarattere
        cpx #3
        beq quartocarattere
        
        // quinto carattere: overflow
        
        ldx #15     // indice messaggio. vedi disassembleato kernel basic v2
        jmp $e38b   // stampa messaggio errore overflow 

primocarattere:
        sta $63     // basso
        lda #0
        sta $62     // alto
        jmp prossimo
        

        
quartocarattere:
        sta temp
        
        ldy #$03 //0b
        clc
shiftbit:
        rol $63
        rol $62
        dey
        bpl shiftbit
        
        lda $63       
        ora temp
        sta $63
        
prossimo:

        inx 
        bne !loop-

finestringa:
        
        ldx #$90 // esponente 2^16
        sec
        jsr $bc49 // converte da 16bit int a float
        
        // prossimo carattere e uscita
        jmp chrgot
//---------------------------------------------
.align $40	
sprite1: 	.byte %10000000, %00000000, %00000000 	
		 	.byte %11000000, %00000000, %00000000 	
		 	.byte %11100000, %00000000, %00000000 	
		 	.byte %11110000, %00000000, %00000000 	
		 	.byte %11111000, %00000000, %00000000 	
		 	.byte %11111100, %00000000, %00000000 	
		 	.byte %11111110, %00000000, %00000000 	
		 	.byte %11111000, %00000000, %00000000 	
		 	.byte %11011000, %00000000, %00000000 	
		 	.byte %10011000, %00000000, %00000000 	
		 	.byte %00001100, %00000000, %00000000 	
		 	.byte %00001100, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
		 	.byte %00000000, %00000000, %00000000 	
			.byte $00       