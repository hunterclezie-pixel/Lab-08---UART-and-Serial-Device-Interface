// Hunter Clezie
// RCET3375
// Lab8UARTPt4
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
    ; General Purpose Registers (bank 0)
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
      
    ; New servo registers
    servo_rx_h    EQU 0x30  ; High byte from S packet
    servo_rx_l    EQU 0x31  ; Low byte from S packet
    servo_next_h  EQU 0x32  ; Saved high byte for next frame
    servo_next_l  EQU 0x33  ; Saved low byte for next frame
    servo_busy    EQU 0x34  ; 1 while RC2 servo pulse is HIGH

    ; Interrupt save registers (shared/common RAM)
    W_TEMP        EQU 0x70
    STATUS_TEMP   EQU 0x71
    PCLATH_TEMP   EQU 0x72
 
; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector:
    goto Setup

; Interrupt Vector
PSECT isrVect,class=CODE,delta=2
InterruptVector:
    GOTO ISRHandler

; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup: 
; Configure UART pins
    BANKSEL PORTC
    BCF PORTC,2	     ; Making RC2 an output
    BANKSEL TRISC
    BCF TRISC,2      ; RC2 is the servo signal output
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
    BSF TRISA,0      ; RA0/AN0 input
    BCF TRISA,1      ; RA1 diagnostic output
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
    CLRF servo_rx_h
    CLRF servo_rx_l
    CLRF servo_busy
    
    ; Start with 1500 us: 0xB1E0 + 1500 = 0xB7BC
    MOVLW 0xB7
    MOVWF servo_next_h
    MOVLW 0xBC
    MOVWF servo_next_l
    BCF STATUS,7     ; IRP=0: FSR will point into bank 0

    ; Enable EUSART Receiver
    BANKSEL RCSTA
    MOVLW 0x90
    MOVWF RCSTA      ; SPEN=1, CREN=1, 8-bit reception

    ; Disable interrupts for polling
    BANKSEL INTCON
    BCF INTCON,7     ; Disable global interrupts
    BCF INTCON,6     ; Disable peripheral interrupts
    
    ; CCP1 compare generates an interrupt without controlling RC2
    BANKSEL CCP1CON
    MOVLW 0x0A       ; Software interrupt on compare match
    MOVWF CCP1CON
    BANKSEL CCPR1H
    MOVLW 0xB7
    MOVWF CCPR1H
    MOVLW 0xBC
    MOVWF CCPR1L

    ; Set Timer1 for internal clock and 1:1 prescaler (1 us/tick)
    BANKSEL T1CON
    CLRF T1CON       ; Stop Timer1 while setting it up
    BANKSEL TMR1H
    MOVLW 0xB1
    MOVWF TMR1H
    MOVLW 0xE0
    MOVWF TMR1L      ; 65536 - 20000 = 0xB1E0

    ; Clear old interrupt flags
    BANKSEL PIR1
    BCF PIR1,0       ; Timer1 flag
    BCF PIR1,2       ; CCP1 flag

    ; Enable Timer1 interrupt; CCP1 enabled at frame start
    BANKSEL PIE1
    BSF PIE1,0       ; TMR1IE=1
    BCF PIE1,2       ; CCP1IE=0 until first frame
    BANKSEL INTCON
    BSF INTCON,6     ; Enable peripheral interrupts
    BSF INTCON,7     ; Enable global interrupts
    BANKSEL T1CON
    BSF T1CON,0      ; Start Timer1


GOTO Main    

Main:
    ; Only start foreground work when servo pulse is LOW
    BANKSEL servo_busy
    MOVF servo_busy,F
    BTFSS STATUS,2
    GOTO Main        ; Do not start work while servo is HIGH

    ; Pulse RA1 to show each receive-service opportunity
    BANKSEL PORTA
    BSF PORTA,1
    BCF PORTA,1
    CALL ServiceRx

    BANKSEL servo_busy
    MOVF servo_busy,F
    BTFSS STATUS,2
    GOTO Main
    CALL ServiceReply

    BANKSEL servo_busy
    MOVF servo_busy,F
    BTFSS STATUS,2
    GOTO Main
    CALL ServiceTx
    GOTO Main            

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
    
    MOVF rx_state,W
    XORLW 0x04
    BTFSC STATUS,2
    GOTO GetServoHigh

    MOVF rx_state,W
    XORLW 0x05
    BTFSC STATUS,2
    GOTO GetServoLow

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
    MOVF rx_byte,W
    XORLW 0x49       ; 'I'
    BTFSC STATUS,2
    GOTO SaveCommand

    MOVF rx_byte,W
    XORLW 0x53       ; 'S'
    BTFSC STATUS,2
    GOTO SaveCommand

    MOVF rx_byte,W
    XORLW 0x41       ; 'A'
    BTFSS STATUS,2
    GOTO ResetParser

SaveCommand:
    ; Save the command so we know what was requested
    MOVF rx_byte,W
    MOVWF rx_command

    ; Move to the packet length state
    MOVLW 0x02
    MOVWF rx_state
    RETURN

GetLength:
    MOVF rx_command,W
    XORLW 0x49           ; 'I'
    BTFSC STATUS,2
    GOTO IDLength

    MOVF rx_command,W
    XORLW 0x53           ; 'S'
    BTFSC STATUS,2
    GOTO ServoLength

    ; 'A' request: length must be 1
    MOVF rx_byte,W
    XORLW 0x01
    BTFSS STATUS,2
    GOTO ResetParser

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
    
ServoLength:
    MOVF rx_byte,W
    XORLW 0x02           ; S length must be 2
    BTFSS STATUS,2
    GOTO ResetParser

    MOVLW 0x04
    MOVWF rx_state       ; Next byte is high compare byte
    RETURN

GetServoHigh:
    MOVF rx_byte,W
    MOVWF servo_rx_h     ; Save the first compare byte

    MOVLW 0x05
    MOVWF rx_state       ; Next byte is low compare byte
    RETURN

GetServoLow:
    MOVF rx_byte,W
    MOVWF servo_rx_l     ; Save the second compare byte
    CLRF rx_state        ; Entire S packet received

    CALL CheckServo      ; Make sure compare value is allowed
    RETURN

ResetParser:
    ; Go back to waiting for the '$' start byte
    CLRF rx_state
    RETURN
    
CheckServo:
    ; Check high byte is not below 0xB3
    MOVLW 0xB3
    SUBWF servo_rx_h,W   ; W = high - 0xB3
    BTFSS STATUS,0      ; C=0 means value is smaller
    GOTO InvalidServo

    MOVF servo_rx_h,W
    XORLW 0xB3
    BTFSC STATUS,2
    GOTO CheckMinLow     ; At minimum high byte, check low

    ; Check high byte is no greater than 0xBB
    MOVLW 0xBB
    SUBWF servo_rx_h,W
    BTFSS STATUS,0
    GOTO SaveServo       ; 0xB4..0xBA is allowed
    MOVF servo_rx_h,W
    XORLW 0xBB
    BTFSS STATUS,2
    GOTO InvalidServo    ; Above 0xBB

    ; 0xBBxx needs a low byte no greater than 0xA4
    MOVF servo_rx_l,W
    SUBLW 0xA4           ; 0xA4 - low byte
    BTFSS STATUS,0
    GOTO InvalidServo
    GOTO SaveServo

CheckMinLow:
    ; 0xB3xx needs a low byte at least 0xD4
    MOVLW 0xD4
    SUBWF servo_rx_l,W
    BTFSS STATUS,0
    GOTO InvalidServo

SaveServo:
    ; Disable interrupts only while saving both bytes together
    BCF INTCON,7
    MOVF servo_rx_h,W
    MOVWF servo_next_h
    MOVF servo_rx_l,W
    MOVWF servo_next_l
    BSF INTCON,7         ; Re-enable interrupts
    RETURN               ; Valid S command has NO response

InvalidServo:
    MOVLW 0x05           ; Use reply 5 for servo range error
    MOVWF reply_pending
    RETURN               ; Previous valid compare value stays saved

ServiceReply:
    ; Prepare an ID, ADC, or error response
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
    MOVLW 0x45           ; 'E'
    MOVWF tx_data1
    MOVLW 0x02
    MOVWF tx_data2

    ; internal 3,4,5 -> packet code 1,2,3
    MOVLW 0x02
    SUBWF reply_pending,W
    MOVWF tx_data3

    ; detail = 1 only for the servo range error
    CLRF tx_data4
    MOVF reply_pending,W
    XORLW 0x05
    BTFSC STATUS,2
    INCF tx_data4,F

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
    
ISRHandler:
   ; Save W and STATUS before changing anything in interrupt
    MOVWF W_TEMP
    SWAPF STATUS,W
    MOVWF STATUS_TEMP

    ; Check Timer1 overflow interrupt first.
    BANKSEL PIR1
    BTFSC PIR1,0      ; Did Timer1 overflow?
    GOTO Timer1ISR

    ; Check CCP1 compare interrupt.
    BTFSC PIR1,2      ; Did Timer1 match CCPR1?
    GOTO CCP1ISR
    GOTO LeaveISR
    
Timer1ISR:
    ; Timer1 overflow: begin a new 20 ms servo frame
    BANKSEL PIR1
    BCF PIR1,0       ; Clear Timer1 interrupt flag
    BCF PIR1,2       ; Clear any old CCP1 match flag

    ; Copy the saved command to the CCP compare hardware
    BANKSEL servo_next_h
    MOVF servo_next_h,W
    BANKSEL CCPR1H
    MOVWF CCPR1H

    BANKSEL servo_next_l
    MOVF servo_next_l,W
    BANKSEL CCPR1L
    MOVWF CCPR1L

    ; Reload Timer1; compare target is relative to 0xB1E0
    BANKSEL TMR1H
    MOVLW 0xB1
    MOVWF TMR1H
    MOVLW 0xE0
    MOVWF TMR1L

    ; Start the servo HIGH pulse
    BANKSEL PORTC
    BSF PORTC,2
    BANKSEL servo_busy
    MOVLW 0x01
    MOVWF servo_busy

    ; Allow the CCP match to end this pulse
    BANKSEL PIE1
    BSF PIE1,2       ; Enable CCP1 interrupt
    Goto LeaveISR

CCP1ISR:
    ; CCP match: end the servo pulse
    BANKSEL PIR1
    BCF PIR1,2       ; Clear CCP1 interrupt flag
    BANKSEL PORTC
    BCF PORTC,2      ; Bring RC2 LOW
    BANKSEL servo_busy
    CLRF servo_busy  ; Safe to service foreground again
    BANKSEL PIE1
    BCF PIE1,2       ; Disable CCP1 until next frame
    Goto LeaveISR
    
    LeaveISR:
    ; Restore STATUS and W register
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    RETFIE

END