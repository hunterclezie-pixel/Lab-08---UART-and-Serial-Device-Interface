// Hunter Clezie
// RCET3375
// Lab7ADCPt4
// https://github.com/hunterclezie-pixel/Lab-07---ADC-and-Servo-Control.git

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
    ccp_next_l EQU 0x21     ; Low byte of next CCP compare value
    ccp_next_h EQU 0x22     ; High byte of next CCP compare value
    adc_l EQU 0x23          ; Lower 8 bits of ADC result
    adc_h EQU 0x24          ; Upper 2 bits of ADC result
    ; Address 0x25 is used by supplied Part 4 mapping file
    ; Do not use 0x25 in this program

    pulse_busy EQU 0x74     ; 1 = servo pulse active, 0 = pulse finished
    W_TEMP EQU 0x75         ; Temporary storage for W during interrupt
    adc_done EQU 0x76       ; 1 = next ADC command ready, 0 = new command needed
    STATUS_TEMP EQU 0x77    ; Saves STATUS during interrupt
 
    ; Supplied Part 4 mapping routine
    GLOBAL ccp_next_l, ccp_next_h, adc_l, adc_h
    EXTRN MapAdcToCcp
 
; Reset Vector at 0000h. Execution starts here after reset.
PSECT resetVect,class=CODE,delta=2
ResetVector:
    goto Setup

; Interrupt Vector
PSECT isrVect,class=CODE,delta=2
InterruptVector:
    Goto ISRHandler

; Main code section starts at 0008h. User code goes here.
PSECT code,class=CODE,delta=2
 
Setup:
    BCF 0x03,6      ; Sets Bank 0
    BCF 0x03,5      ; Sets Bank 0
    CLRF 0x05	    ; Clearing PortA
    CLRF 0x06       ; Clearing PORTB
    CLRF 0x07       ; Clearing PORTC

    BCF 0x03,6      ; Sets Bank 1
    BSF 0x03,5      ; Sets Bank 1
    MOVLW 0x01
    MOVWF 0x85      ; TRISA: RA0 = input
    CLRF 0x86       ; TRISB: PORTB outputs
    CLRF 0x87       ; TRISC: RC2 = servo output
    CLRF ADCON1     ; Clear ADCON1
    BSF ADCON1,7    ; ADFM = 1, right justify result
    BCF ADCON1,5    ; VREF- = VSS
    BCF ADCON1,4    ; VREF+ = VDD

    BSF 0x03,6      ; Sets Bank 3
    BSF 0x03,5	    ; Sets Bank 3
    CLRF ANSEL      ; Clear analog selections
    CLRF ANSELH     ; Clear high analog selections
    BSF ANSEL,0     ; AN0 / RA0 = analog input
    
    ; ADC Setup
    BCF 0x03,6      ; Sets Bank 0
    BCF 0x03,5      ; Sets Bank 0
    CLRF ADCON0     ; Clear ADC settings
    BCF ADCON0,7    ; ADCS1 = 0
    BSF ADCON0,6    ; ADCS0 = 1                         
    ; Selects AN0 as ADC input
    BSF ADCON0,0    ; ADON = 1, turn ADC on

    ; CCP1 Setup
    BANKSEL CCP1CON
    MOVLW 0x0A
    MOVWF CCP1CON   ; CCP1 Compare mode, software interrupt on match

    ; Clear Program Flags
    CLRF adc_l
    CLRF adc_h
    CLRF ccp_next_l
    CLRF ccp_next_h
    CLRF pulse_busy
    CLRF adc_done

    ; Prepare first ADC command before Timer1 starts
    CALL ReadADC
    CALL MapADC
    BANKSEL adc_done
    MOVLW 0x01
    MOVWF adc_done
    
    ; Clear Interrupt Flags
    BANKSEL PIR1
    BCF PIR1,0    ; Clear TMR1IF
    BCF PIR1,2    ; Clear CCP1IF

    ; Enable Timer1 and CCP1 Interrupts
    BANKSEL PIE1
    BSF PIE1,0    ; TMR1IE = 1, enable Timer1 interrupt
    BSF PIE1,2    ; CCP1IE = 1, enable CCP1 interrupt
    
    ; Timer1 Setup
    BANKSEL T1CON
    CLRF T1CON      ; Timer1 off while configuring
    MOVLW 0xB1
    MOVWF TMR1H     ; Timer1 preload high byte
    MOVLW 0xE0
    MOVWF TMR1L     ; Timer1 preload low byte
    BCF PIR1,0      ; Clear Timer1 overflow flag
    BSF T1CON,0     ; Start Timer1
    
    ; Enable Peripheral and Global Interrupts
    BANKSEL INTCON
    BSF INTCON,6  ; PEIE = 1, enable peripheral interrupts
    BSF INTCON,7  ; GIE = 1, enable global interrupts

GOTO Main    

Main:
    ; Do not acquire ADC while servo pulse is active
    BANKSEL pulse_busy
    MOVF pulse_busy,F
    BTFSS STATUS,2
    GOTO Main

    ; Do not acquire another ADC value if next command is ready
    BANKSEL adc_done
    MOVF adc_done,F
    BTFSS STATUS,2
    GOTO Main

    ; Acquire one command for the next frame
    CALL ReadADC
    CALL MapADC

    ; Mark next command as ready
    BANKSEL adc_done
    MOVLW 0x01
    MOVWF adc_done
    Goto Main
   
ReadADC:
    ; Acquisition Delay that allows sample/hold capacitor to charge
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    
    ; Start ADC Conversion
    BANKSEL ADCON0
    BSF ADCON0,1    ; GO/DONE = 1, start conversion
    
WaitADC:
    BTFSC ADCON0,1
    GOTO WaitADC

    ; Save upper 2 ADC bits
    BANKSEL ADRESH
    MOVF ADRESH,W
    BANKSEL adc_h
    MOVWF adc_h
    
    ; Save lower 8 ADC bits
    BANKSEL ADRESL
    MOVF ADRESL,W
    BANKSEL adc_l
    MOVWF adc_l
    RETURN
    
MapADC:
    ; Use full 10-bit ADC result to calculate CCP match
    PAGESEL MapAdcToCcp
    CALL MapAdcToCcp
    PAGESEL $
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
    GOTO ISRDone

Timer1ISR:
    ; Timer1 overflow marks the beginning of a new 20 ms frame.
    BANKSEL PIR1
    BCF PIR1,0       ; Clear Timer1 interrupt flag

    ; Reload Timer1 with 0xB1E0 for another 20 ms frame.
    BANKSEL TMR1H
    MOVLW 0xB1
    MOVWF TMR1H
    MOVLW 0xE0
    MOVWF TMR1L

    ; Start servo pulse HIGH.
    BANKSEL PORTC
    BSF PORTC,2

    ; Load the saved CCP low byte.
    BANKSEL ccp_next_l
    MOVF ccp_next_l,W
    BANKSEL CCPR1L
    MOVWF CCPR1L

    ; Load the saved CCP high byte.
    BANKSEL ccp_next_h
    MOVF ccp_next_h,W
    BANKSEL CCPR1H
    MOVWF CCPR1H
    
    ; Allow one new ADC command for the next frame
    BANKSEL adc_done
    CLRF adc_done

    ; Clear any old CCP interrupt flag before enabling it.
    BANKSEL PIR1
    BCF PIR1,2     ; Clear CCP1IF

    ; Mark servo pulse as active.
    BANKSEL pulse_busy
    MOVLW 0x01
    MOVWF pulse_busy

    ; Enable CCP1 interrupt for this servo pulse.
    BANKSEL PIE1
    BSF PIE1,2     ; CCP1IE = 1
    GOTO ISRDone

CCP1ISR:
    ; Compare value from the supplied lookup table.
    BANKSEL PIR1
    BCF PIR1,2     ; Clear CCP1 interrupt flag

    ; End the servo pulse.
    BANKSEL PORTC
    BCF PORTC,2    ; Servo signal LOW

    ; Disable CCP interrupt until the next servo pulse.
    BANKSEL PIE1
    BCF PIE1,2     ; CCP1IE = 0

    ; Mark servo pulse as finished.
    BANKSEL pulse_busy
    CLRF pulse_busy
    GOTO ISRDone

ISRDone:
    ; Restore STATUS and W register
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    RETFIE

END