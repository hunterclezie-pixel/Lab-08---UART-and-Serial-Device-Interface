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

    ; Enable Serial Port
    BANKSEL RCSTA
    CLRF RCSTA       ; Clear receiver/serial port settings
    BSF RCSTA,7      ; SPEN = 1, enable serial port

    ; Enable EUSART Transmitter
    BANKSEL TXSTA
    BSF TXSTA,5      ; TXEN = 1, enable transmission

GOTO Main    

Main:
    ; Check EUSART transmit buffer
    BANKSEL PIR1
    BTFSC PIR1,4     ; TXIF = 1 when TXREG is empty
    GOTO MakeItRain
    GOTO Main

MakeItRain:
    ; Send ASCII '$'
    BANKSEL TXREG
    MOVLW 0x24
    MOVWF TXREG
    GOTO Main
    
END