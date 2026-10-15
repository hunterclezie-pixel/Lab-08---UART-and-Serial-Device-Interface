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
    rx_byte       EQU 0x70 ; Used to store the received byte
    rx_state      EQU 0x71 ; Used to track the current receive state
    rx_command    EQU 0x72 ; Used to store the received command
    reply_pending EQU 0x73 ; Used to track if a reply is needed
    adc_state     EQU 0x74 ; Used to track the ADC conversion state
    adc_high      EQU 0x75 ; Used to store the high ADC byte
    adc_low       EQU 0x76 ; Used to store the low ADC byte
    tx_length     EQU 0x77 ; Used to store the number of bytes to send
    tx_count      EQU 0x78 ; Used to count the bytes being sent
     
    ; Transmit Packet Buffer
    tx_data0      EQU 0x79 ; Packet byte 0
    tx_data1      EQU 0x7A ; Packet byte 1
    tx_data2      EQU 0x7B ; Packet byte 2
    tx_data3      EQU 0x7C ; Packet byte 3
    tx_data4      EQU 0x7D ; Packet byte 4
    tx_data5      EQU 0x7E ; Packet byte 5
      
    ; Delay GPRs
    Count5ms	  EQU 0x20
    Count50us	  EQU 0x21
 
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
    ; Pulse RB0 so we can see how often the main loop runs
    BANKSEL PORTB
    BSF PORTB,0      ; Turn RB0 HIGH
    BCF PORTB,0      ; Turn RB0 LOW

    ; Check for received data, prepare replies, and send data
    CALL ServiceRx
    CALL ServiceReply
    CALL ServiceTx
    
    ; add a 5ms delay to casue over run 
    ; CAll Delay5ms
    GOTO Main        ; Keep repeating the main loop

ServiceRx:
    ; RCSTA, PIR1, RCREG, and our GPRs are all in bank 0
    BANKSEL RCSTA

    ; Check if the receiver has an overrun error
    BTFSC RCSTA,1
    GOTO RxOverrun

    ; Check if a new byte has been received
    BTFSS PIR1,5
    RETURN          ; No new byte, return to Main

    ; Check if the received byte has a framing error
    BTFSC RCSTA,2
    GOTO RxFraming

    ; Read the received byte and save it in rx_byte
    MOVF RCREG,W
    MOVWF rx_byte

    ; Check if we are already working on a reply
    MOVF reply_pending,F
    BTFSS STATUS,2
    RETURN          ; Ignore new data until the reply is prepared

    ; Send the received byte to the packet parser
    CALL ParseRxByte
    RETURN

RxOverrun:
    ; An overrun means the receiver was not read fast enough
    BCF RCSTA,4      ; Turn the receiver OFF
    BSF RCSTA,4      ; Turn the receiver back ON
    MOVLW 0x04       ; 4 means an overrun error
    GOTO RxError

RxFraming:
    ; A framing error means the received byte was not valid
    MOVF RCREG,W     ; Read and discard the bad byte
    MOVLW 0x03       ; 3 means a framing error

RxError:
    ; Save the error so we can send a response later
    MOVWF reply_pending

    ; Reset the packet parser so we wait for a new '$'
    CLRF rx_state

    ; Reset the ADC state in case a conversion was started
    CLRF adc_state
    RETURN

ParseRxByte:
    ; Check if we are waiting for the start byte
    MOVF rx_state,F
    BTFSC STATUS,2
    GOTO WaitStart

    ; Check if we are waiting for the command byte
    MOVF rx_state,W
    XORLW 0x01
    BTFSC STATUS,2
    GOTO GetCommand

    ; Check if we are waiting for the length byte
    MOVF rx_state,W
    XORLW 0x02
    BTFSC STATUS,2
    GOTO GetLength

    ; Check if we are waiting for the channel byte
    MOVF rx_state,W
    XORLW 0x03
    BTFSC STATUS,2
    GOTO GetChannel

    ; If the state is not valid, restart the packet
    GOTO ResetParser

WaitStart:
    ; Every packet should begin with '$' (0x24)
    MOVF rx_byte,W
    XORLW 0x24
    BTFSS STATUS,2
    RETURN          ; Not '$', keep waiting

    ; Start byte found, move to command state
    MOVLW 0x01
    MOVWF rx_state
    RETURN

GetCommand:
    ; Check if the command is 'I' for Device ID
    MOVF rx_byte,W
    XORLW 0x49
    BTFSC STATUS,2
    GOTO SaveCommand

    ; Check if the command is 'A' for ADC
    MOVF rx_byte,W
    XORLW 0x41
    BTFSS STATUS,2
    GOTO ResetParser    ; Not I or A, restart packet

SaveCommand:
    ; Save the command so we know what was requested
    MOVF rx_byte,W
    MOVWF rx_command

    ; Move to the packet length state
    MOVLW 0x02
    MOVWF rx_state
    RETURN

GetLength:
    ; Check if the saved command was for Device ID
    MOVF rx_command,W
    XORLW 0x49
    BTFSC STATUS,2
    GOTO IDLength

    ; ADC requests must have a length of 1
    MOVF rx_byte,W
    XORLW 0x01
    BTFSS STATUS,2
    GOTO ResetParser

    ; Correct ADC length, move to channel state
    MOVLW 0x03
    MOVWF rx_state
    RETURN

IDLength:
    ; ID requests only have 3 bytes, so the packet is done
    CLRF rx_state

    ; The ID request must have a data length of 0
    MOVF rx_byte,F
    BTFSS STATUS,2
    RETURN          ; Wrong length, ignore request

    ; Request a Device ID response
    MOVLW 0x01
    MOVWF reply_pending
    RETURN

GetChannel:
    ; The last byte of the request has been received
    CLRF rx_state

    ; We only support channel AN0, which is 0x00
    MOVF rx_byte,F
    BTFSS STATUS,2
    RETURN          ; Wrong channel, ignore request

    ; Reset ADC state before starting a new reading
    CLRF adc_state

    ; Request an ADC response
    MOVLW 0x02
    MOVWF reply_pending
    RETURN

ResetParser:
    ; Go back to waiting for the '$' start byte
    CLRF rx_state
    RETURN

ServiceReply:
    BANKSEL reply_pending

    ; Check if a response needs to be sent
    MOVF reply_pending,F
    BTFSC STATUS,2
    RETURN          ; No reply needed

    ; Check if the previous packet has finished being queued
    MOVF tx_length,W
    XORWF tx_count,W
    BTFSS STATUS,2
    RETURN          ; Still sending the previous packet

    ; Check if we need to send the Device ID
    MOVF reply_pending,W
    XORLW 0x01
    BTFSC STATUS,2
    GOTO BuildID

    ; Check if we need to send an ADC reading
    MOVF reply_pending,W
    XORLW 0x02
    BTFSC STATUS,2
    GOTO BuildADC

    ; Otherwise we need to send an error response
    GOTO BuildError

BuildID:
    ; Device ID packet: 24 49 02 33 75
    MOVLW 0x49       ; 'I' means Device ID
    MOVWF tx_data1
    MOVLW 0x02       ; Two data bytes
    MOVWF tx_data2

    ; Our Device ID is 0x3375
    MOVLW 0x33       ; High byte of ID
    MOVWF tx_data3
    MOVLW 0x75       ; Low byte of ID
    MOVWF tx_data4

    ; Five bytes total in the response
    MOVLW 0x05
    GOTO FinishPacket

BuildADC:
    ; First we need to get an ADC reading
    CALL ServiceAdc

    ; Check if the ADC conversion is finished
    BANKSEL adc_state
    MOVF adc_state,W
    XORLW 0x02
    BTFSS STATUS,2
    RETURN          ; Not ready yet, try again next loop

    ; ADC packet: 24 41 03 00 HH LL
    MOVLW 0x41       ; 'A' means ADC response
    MOVWF tx_data1
    MOVLW 0x03       ; Three data bytes
    MOVWF tx_data2
    CLRF tx_data3    ; Channel number is AN0 (0)

    ; Put the high and low ADC bytes into the packet
    MOVF adc_high,W
    MOVWF tx_data4
    MOVF adc_low,W
    MOVWF tx_data5

    ; Reset ADC state for the next reading
    CLRF adc_state

    ; Six bytes total in the response
    MOVLW 0x06
    GOTO FinishPacket

BuildError:
    ; Error packet: 24 45 02 EE 00
    MOVLW 0x45       ; 'E' means error
    MOVWF tx_data1
    MOVLW 0x02       ; Two data bytes
    MOVWF tx_data2

    ; reply_pending = 3 for framing error
    ; reply_pending = 4 for overrun error
    ; Subtract 2 to get the correct error code
    MOVF reply_pending,W
    ADDLW -2
    MOVWF tx_data3   ; Save error code (1 or 2)
    CLRF tx_data4    ; Error detail is always 0

    ; Five bytes total in the response
    MOVLW 0x05
    GOTO FinishPacket

FinishPacket:
    ; W already contains the total packet length
    MOVWF tx_length

    ; Every response starts with '$' (0x24)
    MOVLW 0x24
    MOVWF tx_data0

    ; Start transmitting from the first byte
    CLRF tx_count

    ; Clear the reply flag because the packet is ready
    CLRF reply_pending
    RETURN

ServiceAdc:
    BANKSEL adc_state

    ; adc_state = 0 means the ADC is not running
    MOVF adc_state,F
    BTFSC STATUS,2
    GOTO StartAdc

    ; adc_state = 1 means a conversion is running
    MOVF adc_state,W
    XORLW 0x01
    BTFSS STATUS,2
    RETURN          ; Already finished or invalid state

    ; Check the GO/DONE bit to see if ADC is finished
    BTFSC ADCON0,1
    RETURN          ; Conversion is still running

    ; Read the high byte of the ADC result
    MOVF ADRESH,W
    MOVWF adc_high

    ; ADRESL is in bank 1, so switch banks
    BANKSEL ADRESL
    MOVF ADRESL,W

    ; Go back to bank 0 and save the low byte
    BANKSEL adc_low
    MOVWF adc_low

    ; Set adc_state to 2 to show the result is ready
    MOVLW 0x02
    MOVWF adc_state
    RETURN

StartAdc:
    ; Start a new ADC conversion on AN0
    BSF ADCON0,1     ; Set GO/DONE to start conversion

    ; Set adc_state to 1 because ADC is now busy
    MOVLW 0x01
    MOVWF adc_state
    RETURN

ServiceTx:
    ; Our packet buffer and UART registers are in bank 0
    BANKSEL tx_count

    ; Check if all packet bytes have been sent
    MOVF tx_length,W
    XORWF tx_count,W
    BTFSC STATUS,2
    RETURN          ; All bytes have been queued

    ; Check if TXREG is ready for another byte
    BTFSS PIR1,4
    RETURN          ; Transmit register is still full

    ; Find the next byte in our transmit buffer
    MOVF tx_count,W
    ADDLW tx_data0
    MOVWF FSR

    ; Make sure indirect addressing uses bank 0/1
    BCF STATUS,7   ; IRP = 0
    MOVF INDF,W	   ; INDF reads the byte at the address stored in FSR
    MOVWF TXREG    ; Send that byte through the UART

    ; Increase the counter to point to the next byte
    INCF tx_count,F
    RETURN
    
Delay5ms:
    MOVLW   0x5E
    MOVWF   Count5ms
    
Delay5msLoop:
    Call    Delay50usLoop
    DECFSZ  Count5ms
    GOTO    Delay5msLoop
    MOVLW   0x04
    MOVWF   Count5ms
    DECFSZ  Count5ms
    GOTO    $-1
    RETURN
    
Delay50usLoop:
    ;Delay loop is equals 44 Tcy when count is 15
    MOVLW 0x0F             ;1 Tcy move W=15 to count
    MOVWF Count50us        ;1 Tcy make count equal 15                                    
    DECFSZ Count50us,1     ;1 Tcy if not zero, 2 Tcy if zero
    GOTO $-1               ;2 Tcy delay runs 15 times before skiping
    RETURN

END
