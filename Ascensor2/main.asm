;---------------------ENCABEZADO----------------------------------
list p=16f887
#include "p16f887.inc"
; CONFIG1
; __config 0xE0FD
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_ON & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;------------------MEMORIA DE PROGRAMA-----------------------------
conf_int equ b'10011000'
conf_timer equ b'11000111'
pisoactual equ 0x20
proximopiso equ 0x21
controlpiso equ 0x22
controlasen equ 0x22
CONTA_3 equ 0x23
CONTA_2 equ 0x24 
CONTA_1 equ 0x25 
;------------------PROGRAMA PRINCIPAL------------------------------ 
org 0x00
    goto inicio

org 0x04    ;espacio de memoria asignado para la interrupcion
    call rsi	;llama a rsi
    movwf controlpiso	;mueve el valor de controlpiso a f
    bcf INTCON,INTF	;apaga las interrupciones para despues volver a llamarlo
    bcf INTCON,RBIF	;
    retfie    
 
inicio
    nop
    nop
    
    bsf STATUS,RP0  ;ingresamos al banco 1
    bcf STATUS,RP1
    
    ;------ENTRADAS-----------------
    movlw b'11100000'
    movwf TRISB	    ;declaramos el puerto B como etrada, especificamente, los 2 bits mas significativos
    ;------SALIDAS------------------
    clrf TRISA
    clrf TRISC
    clrf TRISD	    ;declaramos los puertos A, C y D como salidas
    ;------INTERRUPCIONES-----------
    movlw conf_int
    movwf INTCON    ;cargamos intcon con 10011000
    movlw conf_timer	
    movwf OPTION_REG	;cargamos el option_reg con 11000111
    movlw 0xFF
    movwf IOCB	    ;ponemos IOCB como entrada
    
    bcf STATUS,RP0
    bcf STATUS,RP1  ;regresamos al banco 0
    
    ;------LIMPIAR PUERTOS-----------
    clrf PORTA	
    clrf PORTB
    clrf PORTC
    clrf PORTD
    
    ;------INICIALIZAR VALORES-------
    movlw b'00000001'
    movwf pisoactual	;ponemos por defecto el piso 1
    movlw b'11001111'	;pone el numero 1 en el displya
    movwf PORTD		;ubicado en el puerto D
    movlw 0x00	    
    movwf controlpiso	
    
;-----------------------------BUCLE------------------------------
bucle
    bsf PORTC,7		;enciende un led, en señal de que se espera recibir una orden 
_bucle    
    btfsc controlpiso,0	    ;verifica si se presiono el pulsador que va al piso 1
    goto PISO1		    ;de ser asi va a la subrrutina PISO1
    btfsc controlpiso,1	    ;verifica si se presiono el pulsador que va al piso 2
    goto PISO2		    ;de ser asi va a la subrrutina PISO2
    btfsc controlpiso,2	    ;verifica si se presiono el pulsador que va al piso 1
    goto PISO3		    ;de ser asi va a la subrrutina PISO3
    goto _bucle		    ;regresa al bucle 
    
;-------------------------RUTINA DE INTERRUPCION------------------    
rsi
    btfsc PORTB,7	;se presiono el boton ubicado en el pin 7 del puerto b?
    retlw b'00000001'	;asigna el bit 1 al numero 1
    btfsc PORTB,6	;se presiono el boton ubicado en el pin 6 del puerto b?
    retlw b'00000010'	;asigna el bit 2 al numero 2
    btfsc PORTB,5	;se presiono el boton ubicado en el pin 5 del puerto b?
    retlw b'00000100'	;asigna el bit 4 al numero 3	
    return		;regresa donde los llamaron 

;-------------------RUTINA DE PISO 1-------------------------------
PISO1
    btfsc pisoactual,0;pisoactual es igual a 1
    goto mismopiso  ;de presionarse el mismo boton del piso 1, va la subrrutina mismopiso
    btfsc pisoactual,1;pisoactual es igual a 2, se ser asi...
    goto _pp1	    ;... va a la subrrutina _pp1
    btfsc pisoactual,2;pisoactual es igual a 4, de ser asi...
    goto _pp1	    ; ...de ser asi va a la subrruitina _pp1
    goto _bucle    ; regresa al bucle 
_pp1
    movlw b'00000001'	;mueve el valor de "1"
    movwf proximopiso    ;a la variable proximopiso
    btfsc pisoactual,2	;
    decf pisoactual,f	 ;decrementa pisoactual    
    movfw pisoactual	;
    subwf proximopiso,W	;hace la reta proximopiso - pisoactual 
    btfss STATUS,C  ;hace la bifuracion
    goto _menor	    ;si la bifuracion da 0, va a la subrrutina _menor
    goto _mayor	    ;si la bifuracion da 1, va a la subrrutina _mayor 
    
_mayor		;subrrutina mayor 
    movwf controlasen	;mueve el valor de controlasen a f
    goto mover		; va a la subrrutina mover
_menor			;subrrutina menor
    movfw proximopiso	 ;mueve el valor de f a proximopiso
    subwf pisoactual,W	;hace la resta entre entre proximopiso - piso actual 
    movwf controlasen	;mueve el resultado a controlasen
    bsf controlasen,7	
    goto mover		;va a la subrrutina mover
;-------------------RUTINA DE PISO 2-------------------------------
PISO2
    btfsc pisoactual,0;pisoactual es igual a 1
    goto _pp2	    ;si la bifuracion es 1 va a _pp2
    btfsc pisoactual,1;pisoactual es igual a 2
    goto mismopiso  ;si la bifuracion es 1 va a mismopiso
    btfsc pisoactual,2;pisoactual es igual a 4
    goto _pp2	    ;si la bifuracion es 1 va a _pp2	
    goto _bucle	    ;regresa al bucle
_pp2		;subrrutina _pp2
    movlw b'00000010'	;mueve el valor de "2"
    movwf proximopiso    ;... a proximopiso
    btfsc pisoactual,2	
    decf pisoactual,f	 ;decrementa piso actual con el valor de f 
    movfw pisoactual	    ;mueve el resultado a pisoactual
    subwf proximopiso,W	    ;hace la reta entre proximopiso - pisoactual
    btfss STATUS,C	    ;hace la bifuracion
    goto _menor	    ;...    si la bifuracion es 0, va a _menor  
    goto _mayor	    ;...    si al bifuracion es 1 va a _mayor
;-------------------RUTINA DE PISO 3-------------------------------    
PISO3
    btfsc pisoactual,0;pisoactual es igual a 1
    goto _pp3	    ;va a la subrrutina _pp3
    btfsc pisoactual,1;pisoactual es igual a 2
    goto _pp3	    ;;va a la subrrutina _pp3
    btfsc pisoactual,2;pisoactual es igual a 4
    goto mismopiso  ;va a la subrrutina mismopiso
    goto _bucle	    ;va a la subrrutina _bucle 
_pp3		    ;subrrutina _pp3
    movlw b'00000011'	;mueve el valor de 3...
    movwf proximopiso   ;a proximopiso  
    btfsc pisoactual,2	    
    decf pisoactual,f    ;decrementa pisoactual 
    movfw pisoactual	;mueve el valor de pisoactual a w
    subwf proximopiso,W	;hace la resta entre proximopiso - pisoactual
    btfss STATUS,C  ;hace la bifuracacion
    goto _menor	    ;...    si la bifuracion es 0, va a _menor  
    goto _mayor     ;...    si al bifuracion es 1 va a _mayor
    
;-------------------ABRIR PUERTA DE ASCENSOR-----------------------
mismopiso
    bsf PORTC,1	;enciende el led ubicado en el pin 1 del puerto C
    clrf PORTB	;se limpia el Puerto B
    call retardo ; se llama al retardo
    goto bucle	;va a bucle
;-------------------RUTINA DE MOVER-----------------------    
mover	    
    btfsc controlasen, 7; hace la bifuracion...
    goto bajar		;... si es 1 va a la subrrutina bajar
    goto subir		;...si es 1 va al subrutina subir
    ;---------------MOVER SUBRUTINAS---------------------
bajar	
    btfsc controlasen, 1 
    goto _bajar2    
    goto _bajar1    
subir
    btfsc controlasen, 1
    goto _subir2    
    goto _subir1
    
_bajar1		;subrrutina _bajar1
    btfss pisoactual, 2	; el piso actual es 3?
    goto _bajar12	;si no es 3 vaya a _vajar12
    movlw b'00000010'	;mueve el valor de 2, para que el servomotor baje...
    movwf PORTA		;... ubicado en el puerto A
    bsf PORTC, 2	;enciende el led ubicado en el pin 2 del puerto C
    movlw b'10110000'	;pone el numero 3...
    movwf PORTD		;en el puerto D
    movlw b'00000011'	;mueve el valor de 3 ...
    movwf pisoactual	;a piso actual 
    call retardo	;llama la retardo
    movlw b'10100100'	;pone el numero 2...
    movwf PORTD		;... en el puerto D
    movlw b'00000010'	;mueve el valor de 2...
    movwf pisoactual	;... a pisoactual
    bcf PORTC, 2	;apaga el led ubicado en el pin 2 del puerto C
    clrf PORTA		;para el servo
    goto mismopiso	;va a la subrrutina mismopiso
    
_bajar12		;subrrutina _bajar12
    movlw b'00000010'	;mueve el el valor de 2...
    movwf PORTA		;al puerto A
    bsf PORTC, 2	;enciende el led ubicado en el pin 2 del puerto C
    movlw b'10100100'	;pone el numero 2...
    movwf PORTD		;...en el display ubicado en el puerto D
    movlw b'00000010'	;mueve el valor de 2 
    movwf pisoactual	;a pisoactual
    call retardo	;llama al retardo
    movlw b'11111001'	;pone el numero 1...
    movwf PORTD		;...en el display ubicado en el puerto D
    movlw b'00000001'	;mueve el valor de 1...
    movwf pisoactual    ;... a pisoactual 
    bcf PORTC, 2	; apaga el led ubicado en el pin 2 del puerto C
    clrf PORTA		;para el servo
    goto mismopiso	;va la subrrutina mismopiso
    
_bajar2    ;subrrutina bajar 2
    movlw b'00000010'	;mueve el valor de 2, para que el motor gira hacia abajo
    movwf PORTA		;...en el puerto A
    bsf PORTC, 2	;enciende el led ubicado en el pin 2 del puerto C
    movlw b'10110000'	;pone el numero 3...
    movwf PORTD		;en el display ubicado en el puerto D
    movlw b'00000011'	;mueve el valor de 3...
    movwf pisoactual	;a piso actual
    call retardo	;llama al retardo
    movlw b'10100100'	;pone el numero 2
    movwf PORTD		;ubicado en el display ubicado en el puerto D
    movlw b'00000010'	;mueve el valor de 2...
    movwf pisoactual	;...a pisoactual
    bcf PORTC, 2	;apaga el led ubicado en el pin 2 del puerto C
    clrf PORTA		;para el servo
    goto _bajar1	; va a la subrrutiana _bajar1
    
_subir1		;subrrutina _subir1
    btfss pisoactual, 0	;piso actual es 1?
    goto _subir12	 ;de no ser asi, va a _subir12
    movlw b'00000001'	;mueve el valor de 1, para que el servomotor suba...
    movwf PORTA		;al servomotor ubicado en el puerto A
    movlw b'11111001'	;pone el numero 1
    movwf PORTD		;en el display 
    movlw b'00000001'	;mueve el valor de 1...
    movwf pisoactual	;...a piso actual 
    call retardo	;llama al retardo
    movlw b'10100100'	;pone el numero 2    
    movwf PORTD		;en el display
    movlw b'00000010'	;mueve el valor de 2...
    movwf pisoactual	;... a pisoactual 
    clrf PORTA		;para el servo
    goto mismopiso	;va a la subrrutina mismopiso
    
_subir12		;subrrutina _subir12
    movlw b'00000001'	;mueve el valor de 1, para que el servomotor suba
    movwf PORTA		;ubicado en el puerto A
    movlw b'10100100'	;pone el numero 2...
    movwf PORTD		;... en el display
    movlw b'00000010'	;mueve el valor de 2...
    movwf pisoactual	;a piso actual	
    call retardo	;llama al retardo
    movlw b'10110000'	;pone el numero 3...
    movwf PORTD		;... en el display 
    movlw b'00000011'	;pone el valor de 3...
    movwf pisoactual	;a pisoactual
    clrf PORTA		;para el servo
    goto mismopiso	;va a la subrrutina mismopiso
    
_subir2		    ;subrrutina _subir2
    movlw b'00000001'	;pone el valor de 1 para que el servomotor suba
    movwf PORTA		;ubicado en el puerto A
    bsf PORTC, 0	;enciende el led ubicado en el pin 0 del puerto C
    movlw b'11111001'	;pone el numero 1...
    movwf PORTD		;... en el puerto D
    movlw b'00000001'	;pone el valor de 1...
    movwf pisoactual	;a pisoactual
    call retardo	;llama a retardo
    movlw b'10100100'	;pone el numero 2...
    movwf PORTD		;... en el display
    movlw b'00000010'	;pone el valor de 2....
    movwf pisoactual	;... en pisoactual
    bcf PORTC, 0	;apaga el led ubicado en el pin 0 del puerto C
    clrf PORTA	;para el servo
    goto _subir1      
   
;--------------RETARDO---------------------------------------------
retardo ;vamos a generar un retardo de 9 segundos
    movlw d'20'		;movemos el valor 20
    movwf CONTA_3	;movemos el valor a CONTA_3
    movlw d'250'	;movemos el valor 250
    movwf CONTA_2	;movemos el valor a CONTA_2
    movlw d'250'		;movemos el valor 250
    movwf CONTA_1	;movemos el valor a CONTA_1
    nop			;
    decfsz CONTA_1, f	;decrementa CONTA_1 en 1,(CONTA_1 - 1) si es 0 salta
    goto $-.2		;se devuleve 2 lineas
    decfsz CONTA_2, F	;decrementa CONTA_2 en 1,(CONTA_2 - 1) si es 0 salta
    goto $-.6		;Se devuelve 6 lineas
    decfsz CONTA_3, F	;decrementa CONTA_3 en 1,(CONTA_3 - 1) si es 0 salta
    goto $-.10		;Se devuelve 10 lineas
    return  
;---------------FIN DE PROGRAMA PRINCIPAL--------------------------     
    end
;