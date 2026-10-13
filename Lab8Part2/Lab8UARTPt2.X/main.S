// Hunter Clezie
// RCET3375
// Lab8UARTPt2
// https://github.com/hunterclezie-pixel/Lab-08---UART-and-Serial-Device-Interface.git

; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

; config statements should precede project file includes.
#include <xc.inc>  
    ; General Purpose Registers
    rx_byte     EQU 0x20  ; Most recently received byte
    tx_byte     EQU 0x21  ; Byte waiting for transmission
    rx_ready    EQU 0x22  ; Received byte ready flag
    tx_pending  EQU 0x23  ; Transmit byte pending flag
 
; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector:
    goto Setup

; Interrupt Vector
PSECT isrVect,class=CODE,delta=2
InterruptVector:

; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup:
    ; Configure RC6/TX for EUSART transmission
    BANKSEL TRISC
    BSF TRISC,6      ; Allow EUSART to control RC6/TX
    BSF TRISC,7      ; RC7/RX receive input
    
    ; Configure RB0 as diagnostic output
    BANKSEL ANSELH
    CLRF ANSELH      ; Set PORTB analog pins to digital
    BANKSEL PORTB
    BCF PORTB,0      ; Start diagnostic pin LOW
    BANKSEL TRISB
    BCF TRISB,0      ; RB0 is an output

    ; Configure EUSART Transmitter
    BANKSEL TXSTA
    CLRF TXSTA       ; Clear transmitter settings
    BCF TXSTA,6      ; TX9 = 0, 8-bit transmission
    BCF TXSTA,4      ; SYNC = 0, asynchronous mode
    BSF TXSTA,2      ; BRGH = 1, high-speed baud rate

    ; Configure Baud Rate Generator
    BANKSEL BAUDCTL
    CLRF BAUDCTL     ; Clear baud rate control settings
    BCF BAUDCTL,3    ; BRG16 = 0, 8-bit baud generator

    ; Set Baud Rate to approximately 9600
    BANKSEL SPBRG
    MOVLW 25
    MOVWF SPBRG      ; 9600 baud at FOSC = 4 MHz
    
    ; Initialize General Purpose Registers
    BANKSEL rx_byte
    CLRF rx_byte
    CLRF tx_byte
    CLRF rx_ready
    CLRF tx_pending

    ; Enable Serial Port
    BANKSEL RCSTA
    CLRF RCSTA       ; Clear receiver/serial port settings
    BSF RCSTA,7      ; SPEN = 1, enable serial port
    BSF RCSTA,4      ; Enable continuous reception

    ; Enable EUSART Transmitter
    BANKSEL TXSTA
    BSF TXSTA,5      ; TXEN = 1, enable transmission
    
    ; Use polling instead of interrupts
    BANKSEL INTCON
    BCF INTCON,7     ; Disable global interrupts
    BCF INTCON,6     ; Disable peripheral interrupts

GOTO Main    

Main:
    CALL ServiceRx
    CALL ProcessEcho
    CALL ServiceTx
    GOTO Main

ServiceRx:
    ; Pulse RB0 to show receive service
    BANKSEL PORTB
    BSF PORTB,0
    BCF PORTB,0

    ; Check whether previous byte is still waiting
    BANKSEL rx_ready
    MOVF rx_ready,F
    BTFSS STATUS,2
    RETURN

    ; Check for receive overrun
    BANKSEL RCSTA
    BTFSC RCSTA,1    ; OERR = 1
    GOTO RxOverrun

    ; Check whether a byte was received
    BANKSEL PIR1
    BTFSS PIR1,5     ; RCIF = 1 when data is available
    RETURN

    ; Check for framing error
    BANKSEL RCSTA
    BTFSC RCSTA,2    ; FERR = 1
    GOTO RxFraming

    ; Read the received byte
    BANKSEL RCREG
    MOVF RCREG,W
    BANKSEL rx_byte
    MOVWF rx_byte

    ; Set received byte ready flag
    MOVLW 0x01
    MOVWF rx_ready
    RETURN

RxOverrun:
    ; Recover from an overrun error
    BANKSEL RCSTA
    BCF RCSTA,4      ; Disable receiver
    BSF RCSTA,4      ; Enable receiver again
    RETURN

RxFraming:
    ; Discard a byte with a framing error
    BANKSEL RCREG
    MOVF RCREG,W     ; Read to remove invalid byte
    RETURN

ProcessEcho:
    ; Check whether a received byte is ready
    BANKSEL rx_ready
    MOVF rx_ready,F
    BTFSC STATUS,2
    RETURN

    ; Check whether previous transmit byte is pending
    MOVF tx_pending,F
    BTFSS STATUS,2
    RETURN

    ; Copy received byte to transmit byte
    MOVF rx_byte,W
    MOVWF tx_byte

    ; Clear receive flag
    CLRF rx_ready

    ; Set transmit pending flag
    MOVLW 0x01
    MOVWF tx_pending
    RETURN

ServiceTx:
    ; Check whether a byte is waiting
    BANKSEL tx_pending
    MOVF tx_pending,F
    BTFSC STATUS,2
    RETURN

    ; Check whether transmit buffer is available
    BANKSEL PIR1
    BTFSS PIR1,4     ; TXIF = 1 when TXREG is empty
    RETURN

    ; Send the stored byte
    BANKSEL tx_byte
    MOVF tx_byte,W
    BANKSEL TXREG
    MOVWF TXREG

    ; Clear transmit pending flag
    BANKSEL tx_pending
    CLRF tx_pending
    RETURN
    
END