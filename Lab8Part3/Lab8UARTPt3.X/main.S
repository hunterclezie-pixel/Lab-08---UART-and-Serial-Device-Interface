// Hunter Clezie
// RCET3375
// Lab8UARTPt3
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
    rx_byte       EQU 0x20 ; Used to store the received byte
    rx_state      EQU 0x21 ; Used to track the current receive state
    rx_command    EQU 0x22 ; Used to store the received command
    reply_pending EQU 0x23 ; Used to track if a reply is needed
    adc_state     EQU 0x24 ; Used to track the ADC conversion state
    adc_high      EQU 0x25 ; Used to store the high ADC byte
    adc_low       EQU 0x26 ; Used to store the low ADC byte
    tx_length     EQU 0x27 ; Used to store the number of bytes to send
    tx_count      EQU 0x28 ; Used to count the bytes being sent
     
    ; Transmit Packet Buffer
    tx_data0      EQU 0x29 ; Packet byte 0
    tx_data1      EQU 0x2A ; Packet byte 1
    tx_data2      EQU 0x2B ; Packet byte 2
    tx_data3      EQU 0x2C ; Packet byte 3
    tx_data4      EQU 0x2D ; Packet byte 4
    tx_data5      EQU 0x2E ; Packet byte 5
 
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
; Configure UART pins
    BANKSEL TRISC
    BSF TRISC,6      ; RC6/TX for transmission
    BSF TRISC,7      ; RC7/RX for reception

    ; Configure RB0 as diagnostic output
    BANKSEL ANSELH
    CLRF ANSELH      ; Set PORTB analog pins to digital
    BANKSEL PORTB
    BCF PORTB,0      ; Start RB0 LOW
    BANKSEL TRISB
    BCF TRISB,0      ; RB0 as output

    ; Configure EUSART Transmitter
    BANKSEL TXSTA
    MOVLW 0x24       ; 8-bit, asynchronous, BRGH=1, TXEN=1
    MOVWF TXSTA

    ; Configure Baud Rate Generator
    BANKSEL BAUDCTL
    CLRF BAUDCTL     ; BRG16=0, 8-bit baud generator
    BANKSEL SPBRG
    MOVLW 25
    MOVWF SPBRG      ; 9600 baud at 4 MHz

    ; Configure AN0 for ADC
    BANKSEL TRISA
    BSF TRISA,0      ; RA0/AN0 as input
    BANKSEL ANSEL
    MOVLW 0x01
    MOVWF ANSEL      ; Enable AN0 analog input

    ; Configure ADC
    BANKSEL ADCON1
    MOVLW 0x80
    MOVWF ADCON1     ; Right-justified, VDD/VSS references
    BANKSEL ADCON0
    MOVLW 0x41
    MOVWF ADCON0     ; FOSC/8, AN0, ADC enabled

    ; Initialize General Purpose Registers
    BANKSEL rx_byte
    CLRF rx_byte
    CLRF rx_state
    CLRF rx_command
    CLRF reply_pending
    CLRF adc_state
    CLRF adc_high
    CLRF adc_low
    CLRF tx_length
    CLRF tx_count
    
    ; Use bank 0 for indirect addressing
    BCF STATUS,7     ; IRP = 0

    ; Enable EUSART Receiver
    BANKSEL RCSTA
    MOVLW 0x90
    MOVWF RCSTA      ; SPEN=1, CREN=1, 8-bit reception

    ; Disable interrupts for polling
    BANKSEL INTCON
    BCF INTCON,7     ; Disable global interrupts
    BCF INTCON,6     ; Disable peripheral interrupts

GOTO Main    

Main:
    ; Diagnostic pulse for receive service
    BANKSEL PORTB
    BSF PORTB,0
    BCF PORTB,0

    CALL ServiceRx
    CALL ServiceReply
    CALL ServiceTx
    GOTO Main

; Receive Service
ServiceRx:
    ; Check for receive overrun
    BANKSEL RCSTA
    BTFSC RCSTA,1
    GOTO RxOverrun

    ; Check whether a byte was received
    BANKSEL PIR1
    BTFSS PIR1,5
    RETURN

    ; Check for framing error
    BANKSEL RCSTA
    BTFSC RCSTA,2
    GOTO RxFraming

    ; Read received byte
    BANKSEL RCREG
    MOVF RCREG,W

    BANKSEL rx_byte
    MOVWF rx_byte

    ; Ignore new requests if a reply is active
    MOVF reply_pending,F
    BTFSS STATUS,2
    RETURN

    MOVF tx_length,W
    XORWF tx_count,W
    BTFSS STATUS,2
    RETURN
    CALL ParseRxByte
    RETURN

; Receive Errors
RxOverrun:
    BANKSEL RCSTA
    BCF RCSTA,4      ; Reset receiver
    BSF RCSTA,4
    BANKSEL rx_state
    CLRF rx_state
    CLRF adc_state
    MOVLW 0x04       ; Overrun error
    MOVWF reply_pending
    RETURN

RxFraming:
    BANKSEL RCREG
    MOVF RCREG,W     ; Discard invalid byte
    BANKSEL rx_state
    CLRF rx_state
    CLRF adc_state
    MOVLW 0x03       ; Framing error
    MOVWF reply_pending
    RETURN


; Packet Parser
ParseRxByte:
    BANKSEL rx_state
    MOVF rx_state,F
    BTFSC STATUS,2
    GOTO WaitStart
    MOVF rx_state,W
    XORLW 0x01
    BTFSC STATUS,2
    GOTO GetCommand
    MOVF rx_state,W
    XORLW 0x02
    BTFSC STATUS,2
    GOTO GetLength

    ; Remaining valid state is GET_CHANNEL
    GOTO GetChannel

; Wait for Start Byte
WaitStart:
    MOVF rx_byte,W
    XORLW 0x24      ; '$'
    BTFSS STATUS,2
    RETURN
    MOVLW 0x01
    MOVWF rx_state
    RETURN

; Read Command
GetCommand:
    MOVF rx_byte,W
    XORLW 0x49      ; 'I'
    BTFSC STATUS,2
    GOTO SaveCommand

    MOVF rx_byte,W
    XORLW 0x41      ; 'A'
    BTFSS STATUS,2
    GOTO ResetParser

SaveCommand:
    MOVF rx_byte,W
    MOVWF rx_command
    MOVLW 0x02
    MOVWF rx_state
    RETURN

; Read Packet Length
GetLength:
    MOVF rx_command,W
    XORLW 0x49      ; ID command
    BTFSC STATUS,2
    GOTO IDLength

    ; ADC command must have length 1
    MOVF rx_byte,W
    XORLW 0x01
    BTFSS STATUS,2
    GOTO ResetParser
    MOVLW 0x03
    MOVWF rx_state
    RETURN

IDLength:
    CLRF rx_state

    ; ID command must have length 0
    MOVF rx_byte,F
    BTFSS STATUS,2
    RETURN
    MOVLW 0x01      ; ID response
    MOVWF reply_pending
    RETURN


; Read ADC Channel
GetChannel:
    CLRF rx_state

    ; Only AN0 is supported
    MOVF rx_byte,F
    BTFSS STATUS,2
    RETURN
    CLRF adc_state
    MOVLW 0x02      ; ADC response
    MOVWF reply_pending
    RETURN

ResetParser:
    CLRF rx_state
    RETURN

; Prepare Response Packet
ServiceReply:
    BANKSEL reply_pending
    MOVF reply_pending,F
    BTFSC STATUS,2
    RETURN

    ; Wait until previous response is finished
    MOVF tx_length,W
    XORWF tx_count,W
    BTFSS STATUS,2
    RETURN

    ; Check response type
    MOVF reply_pending,W
    XORLW 0x01
    BTFSC STATUS,2
    GOTO BuildID
    MOVF reply_pending,W
    XORLW 0x02
    BTFSC STATUS,2
    GOTO BuildADC
    GOTO BuildError

; Device ID Response
BuildID:
    BANKSEL tx_data0
    MOVLW 0x49      ; 'I'
    MOVWF tx_data1
    MOVLW 0x02      ; Two data bytes
    MOVWF tx_data2
    MOVLW 0x33
    MOVWF tx_data3
    MOVLW 0x75
    MOVWF tx_data4
    MOVLW 0x05      ; Five total bytes
    GOTO FinishPacket

; ADC Response
BuildADC:
    CALL ServiceAdc
    BANKSEL adc_state
    MOVF adc_state,W
    XORLW 0x02
    BTFSS STATUS,2
    RETURN
    MOVLW 0x41      ; 'A'
    MOVWF tx_data1
    MOVLW 0x03      ; Three data bytes
    MOVWF tx_data2
    CLRF tx_data3    ; AN0 channel
    MOVF adc_high,W
    MOVWF tx_data4
    MOVF adc_low,W
    MOVWF tx_data5
    CLRF adc_state
    MOVLW 0x06      ; Six total bytes
    GOTO FinishPacket

; Error Response
BuildError:
    BANKSEL tx_data0
    MOVLW 0x45      ; 'E'
    MOVWF tx_data1
    MOVLW 0x02
    MOVWF tx_data2

    ; Framing = 1, Overrun = 2
    MOVF reply_pending,W
    ADDLW -2
    MOVWF tx_data3
    CLRF tx_data4    ; Detail = 0
    MOVLW 0x05
    GOTO FinishPacket

; Complete Packet Setup
FinishPacket:
    BANKSEL tx_length
    MOVWF tx_length
    MOVLW 0x24      ; '$'
    MOVWF tx_data0
    CLRF tx_count
    CLRF reply_pending
    RETURN

; ADC Conversion Service
ServiceAdc:
    BANKSEL adc_state

    ; State 0: IDLE
    MOVF adc_state,F
    BTFSC STATUS,2
    GOTO StartAdc

    ; State 1: BUSY
    MOVF adc_state,W
    XORLW 0x01
    BTFSS STATUS,2
    RETURN

    ; Wait for conversion to finish
    BANKSEL ADCON0
    BTFSC ADCON0,1
    RETURN

    ; Save 10-bit ADC result
    BANKSEL ADRESH
    MOVF ADRESH,W
    BANKSEL adc_high
    MOVWF adc_high
    BANKSEL ADRESL
    MOVF ADRESL,W
    BANKSEL adc_low
    MOVWF adc_low
    MOVLW 0x02      ; READY
    MOVWF adc_state
    RETURN

StartAdc:
    BANKSEL ADCON0
    BSF ADCON0,1     ; Start conversion
    BANKSEL adc_state
    MOVLW 0x01      ; BUSY
    MOVWF adc_state
    RETURN

; Transmit Service
ServiceTx:
    BANKSEL tx_count

    ; Check whether packet is finished
    MOVF tx_length,W
    XORWF tx_count,W
    BTFSC STATUS,2
    RETURN

    ; Check whether TXREG is available
    BANKSEL PIR1
    BTFSS PIR1,4
    RETURN

    ; Point FSR to the next packet byte
    BANKSEL tx_count
    MOVF tx_count,W
    ADDLW tx_data0
    BANKSEL FSR
    MOVWF FSR
    BCF STATUS,7     ; IRP = 0

    ; Read buffer byte and transmit it
    BANKSEL INDF
    MOVF INDF,W
    BANKSEL TXREG
    MOVWF TXREG

    ; Advance transmit index
    BANKSEL tx_count
    INCF tx_count,F
    RETURN

END