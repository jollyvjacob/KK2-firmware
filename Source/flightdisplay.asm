

UpdateFlightDisplay:

	rvsetflagfalse flagHomeScreen

	rvsetflagtrue flagMutePwm

	call LcdClear12x16

	rvbrflagtrue flagGimbalMode, udp5	;skip ahead when in gimbal controller mode

	;error log
	call ErrorLog				;will show the error log if any error has been logged
	brcc udp1

	rjmp udp21				;the error log is displayed so we'll just skip to the end

udp1:	;battery log
	call BatteryLog				;will show the battery log when activated
	brcc udp2

	rjmp udp21				;the battery log is displayed so we'll just skip to the end

udp2:	rvsetflagtrue flagHomeScreen

	;armed status
	rvbrflagfalse flagArmed, udp3

	lrv X1, 34				;armed
	lrv Y1, 22
	ldz armed*2
	call PrintHeader

	ldz udp7*2				;banner
	call PrintSelector

	lrv Y1, 45
	call PrintMotto
	rjmp udp21

udp3:	ldz eeBigHomeScreen
	call ReadEepromP
	brflagfalse t, udp5

	rjmp BigHomeScreen

udp5:	lrv X1, 38				;safe
	ldz safe*2
	call PrintString

	;user profile
	lrv X1, 102
	rcall PrintUserProfile
	lrv FontSelector, f6x8
	lrv X1, 0

	;gimbal controller mode
	rvbrflagfalse flagGimbalMode, udp4

	lrv Y1, 17				;stand-alone gimbal controller mode
	ldi t, 2
	ldz gblmode*2
	call PrintStringArray

	lrv X1, 1				;camera icon
	lrv Y1, 0
	lrv FontSelector, s16x16
	ldi t, 4
	call PrintChar
	lrv FontSelector, f6x8

	lrv Y1, 44				;LVA setting and footer
	rjmp udp20

udp4:	;flight timer
	lrv Y1, 1
	lds xl, Timer1min
	lds yl, Timer1sec
	rcall PrintTimer

	;status message
	lrv X1, 0
	lrv Y1, 17
	ldz ok*2				;default string is "OK"
	rcall LoadStatusString
	call PrintString

	brts udp25				;skip ahead when status bits are set (T flag is set in LoadStatusString)

	rvbrflagfalse flagPortExpTuning, udp26

	ldz udp6*2				;tuning altitude hold (Port Expander)
	call PrintString
	ldz alth*2
	call PrintString
	rjmp udp51

udp26:	lds t, TuningMode			;display the selected tuning mode
	tst t
	breq udp51

	ldz udp6*2				;tuning
	call PrintString
	lds t, TuningMode
	cpi t, 1				;print "Ail+Ele" if tuning aileron when linked with elevator
	brne udp24

	lds xl, flagRollPitchLink
	tst xl
	breq udp24

	ldz ailele*2
	call PrintString
	rjmp udp51

udp24:	ldz tunmode*2
	call PrintFromStringArray
	rjmp udp51

udp25:	lds t, StatusFlag			;flashing status text banner
	inc t
	andi t, 0x01
	sts StatusFlag, t
	breq udp51

	ldz udp8*2				;highlight the status text
	call PrintSelector

udp51:	;flight mode and stick scaling offset
	lrv X1, 0				;flight mode
	lrv Y1, 27
	ldz flmode*2
	rcall PrintFlightMode

	lrv X1, 84				;stick scaling offset selected from AUX switch position
	lds t, AuxStickScaling
	andi t, 0x03				;skip printing when zero
	breq udp54
	
	push t
	ldz ss*2
	call PrintString
	pop t
	ldz auxss*2
	call PrintFromStringArray

udp54:	;battery voltages
	lrv X1, 0				;live battery voltage
	call LineFeed
	ldz batt*2
	call PrintString
	b16loadx BatteryVoltage
	rcall PrintVoltage

	lrv X1, 84				;lowest battery voltage logged
	b16loadx BatteryVoltageLogged
	rcall PrintVoltage
	call LineFeed

udp20:	lrv X1, 0				;LVA setting
	ldz lvalbl*2
	call PrintString
	b16loadx BattAlarmVoltage
	rcall PrintVoltage2

	;footer
udp23:	lrv Y1, 57
	lrv X1, 36
	ldz upd1*2
	call PrintString

udp21:	call LcdUpdate

	rvsetflagfalse flagMutePwm
	sts flagRxBufferFull, t
	ret



	;--- Print voltage value ---

PrintVoltage:

	b16loadz BatteryVoltageOffset		;zero input voltage?
	cp xl, zl
	cpc xh, zh
	brne PrintVoltage2

	clr xh					;yes
	clr xl

PrintVoltage2:

	clr yh					;calculate and print voltage value
	b16muli 2.5

	b16muli 0.3203125			;divide by 100
	b16muli 0.03125

 	call Print16Signed
	rcall PrintDecimal
	ldi t, 'V'
	call PrintChar
	ret



	;--- Print decimal point and one digit ---

PrintDecimal:

	ldi t, '.'
	call PrintChar

PrintDecimalNoDP:

	mov xl, yh				;print the fractional part (one digit)
	clr xh
	clr yh
	b16muli 0.0390625
	call Print16Signed
	ret



	;--- Print timer value ---

PrintTimer:

	cpi xl, 10				;minutes
	brge ptim1

	ldi t, '0'				;print leading zero
	call PrintChar

ptim1:	clr xh
	call Print16Signed
	ldi t, ':'
	call PrintChar

	mov xl, yl				;seconds
	cpi xl, 10
	brge ptim2

	ldi t, '0'				;print leading zero
	call PrintChar

ptim2:	call Print16Signed
	ret



	;--- Print flight mode ---

PrintFlightMode:

	call PrintString			;register Z (input parameter) points to the label
	rvbrflagfalse flagSlOn, pfm1

	ldz selflvl*2				;(normal) SL
	rjmp pfm3

pfm1:	rvbrflagfalse flagSlStickMixing, pfm2

	ldz slmix*2				;SL mix
	rjmp pfm3

pfm2:	ldz acro*2				;acro

pfm3:	call PrintString
	ret



	;--- Print user profile ---

PrintUserProfile:

	ldi t, 'P'
	call PrintChar
	ldi t, '1'
	lds xl, UserProfile
	add t, xl
	call PrintChar
	ret



upd1:	.db "<PROFILE>  MENU", 0
safe:	.db "SAFE", 0, 0
armed:	.db "ARMED", 0

upd2:	.db "Stand-alone Gimbal", 0, 0
upd3:	.db "Controller mode.", 0, 0

gblmode:.dw upd2*2, upd3*2

udp6:	.db ". Tuning ", 0
alth:	.db "Alt. Hold", 0

udp7:	.db 0, 19, 127, 40
udp8:	.db 0, 16, 127, 25

flmode:	.db "Mode: ", 0, 0
batt:	.db "Batt: ", 0, 0
lvalbl:	.db "LVA : ", 0, 0

sta1:	.db "ACC not calibrated.", 0
sta2:	.db "No aileron input.", 0
sta3:	.db "No elevator input.", 0, 0
sta4:	.db "No throttle input.", 0, 0
sta5:	.db "No rudder input.", 0, 0
sta6:	.db "Sanity check failed.", 0, 0
sta7:	.db "No motor layout!", 0, 0
sta8:	.db "Check throttle level.", 0
sta9:	.db "RX signal was lost!", 0

sta11:	.db "Check aileron level.", 0, 0
sta12:	.db "Check elevator level.", 0
sta13:	.db "Motor Spin is active.", 0

sta21:	.db "No CPPM input!", 0, 0

sta31:	.db "No S.Bus input!", 0
sta32:	.db "FAILSAFE!", 0

sta41:	.db "No Satellite input!", 0
sta45:	.db "Sat protocol error!", 0

sta51:	.db "No serial data!", 0
sta52:	.db "Protocol error!", 0
sta53:	.db "No RX input!", 0, 0
sta54:	.db "RX problem!", 0



	;--- Load status string ---

LoadStatusString:

	set					;set the T flag to indicate error/warning (assuming that one or more status bits are set)

	lds t, StatusBits
	cbr t, LvaWarning			;no error message displayed for LVA warning
	brne lss11

	rvbrflagtrue flagThrottleZero, lss8	;no critical flags are set so we'll display a warning if throttle is above idle

	rvbrflagtrue flagMotorSpin, lss12	;display a warning when the Motor Spin feature is active

	ldz sta8*2				;check throttle level
	ret

lss12:	ldz sta13*2				;motor spin is active
	ret

lss8:	rvbrflagtrue flagAileronCentered, lss9

	ldz sta11*2				;check aileron level
	ret

lss9:	rvbrflagtrue flagElevatorCentered, lss10

	ldz sta12*2				;check elevator level
	ret

lss10:	clt					;no errors/warnings (clear the T flag)
	ret

lss11:	lds t, StatusBits
	andi t, RxSignalLost
	cpi t, RxSignalLost
	brne lss1

	ldz sta9*2				;RX signal was lost
	ret

lss1:	lds t, StatusBits
	andi t, NoMotorLayout
	breq lss2

	ldz sta7*2				;no motor layout
	ret

lss2:	lds t, StatusBits
	andi t, AccNotCalibrated
	breq lss3

	ldz sta1*2				;ACC not calibrated
	ret

lss3:	lds t, StatusBits
	andi t, SanityCheckFailed
	breq lss4

	ldz sta6*2				;sanity check failed
	ret

lss4:	lds t, RxMode
	cpi t, RxModeStandard
	brne lss5

	rcall GetStdStatus			;standard RX mode
	ret

lss5:	cpi t, RxModeCppm
	brne lss6

	rcall GetCppmStatus			;CPPM RX mode
	ret

lss6:	cpi t, RxModeSBus
	brne lss7

	rcall GetSBusStatus			;S.Bus RX mode
	ret

lss7:	cpi t, RxModeSerialLink
	breq lss17

	rcall GetSatStatus			;Satellite mode
	ret

lss17:	rcall GetSerialLinkStatus		;Serial Link mode
	ret



	;--- Get status for standard RX mode ---

GetStdStatus:

	lds t, StatusBits
	andi t, NoAileronInput
	breq std6

	ldz sta2*2				;no aileron input
	ret

std6:	lds t, StatusBits
	andi t, NoElevatorInput
	breq std7

	ldz sta3*2				;no elevator input
	ret

std7:	lds t, StatusBits
	andi t, NoThrottleInput
	breq std8

	ldz sta4*2				;no throttle input
	ret

std8:	ldz sta5*2				;no rudder input
	ret



	;--- Get status for CPPM mode ---

GetCppmStatus:

	ldz sta21*2				;no CPPM input
	ret



	;--- Get status for S.Bus mode ---

GetSBusStatus:

	lds t, StatusBits
	andi t, NoSBusInput
	breq gsbs1

	ldz sta31*2				;no S.Bus input
	ret

gsbs1:	ldz sta32*2				;failsafe
	ret



	;--- Get status for Satellite mode ---

GetSatStatus:

	lds t, StatusBits
	andi t, SatProtocolError
	breq gss1

	ldz sta45*2				;Satellite protocol error
	ret

gss1:	ldz sta41*2				;no Satellite input
	ret



	;--- Get status for Serial Link mode ---

GetSerialLinkStatus:

	lds t, StatusBits
	andi t, NoSerialData
	breq gsls1

	ldz sta51*2				;no serial data
	ret

gsls1:	lds t, StatusBits
	andi t, RxInputProblem
	brne gsls2

	ldz sta52*2				;protocol error
	ret

gsls2:	lds t, RxFlags
	andi t, NoRxInput
	cpi t, NoRxInput
	brne gsls3

	ldz sta53*2				;no RX input
	ret

gsls3:	lds t, RxFlags
	andi t, NoRxInput
	breq gsls4

	lds xl, StatusBits			;no aileron/elevator/throttle/rudder input
	sts StatusBits, t
	rcall GetStdStatus
	sts StatusBits, xl
	ret

gsls4:	ldz sta53*2				;RX problem (S.Bus failsafe or Satellite protocol error)
	ret



	;--- Print an alternative home screen using large font ---

BigHomeScreen:

	;status message
	rcall LoadStatusString
	brtc bhs11

	pushz					;display status message screen
	call PrintWarningHeader

	lrv X1, 115				;user profile (normal font)
	lrv Y1, 1
	rcall PrintUserProfile

	lrv X1, 0				;status message (normal font)
	lrv Y1, 17
	popz
	call PrintString

	lds t, StatusBits			;show flight mode only when the Motor Spin warning is displayed
	cbr t, LvaWarning
	brne bhs10

	rvbrflagfalse flagMotorSpin, bhs10

	lrv X1, 0				;flight mode
	lrv Y1, 35
	ldz flmode*2
	rcall PrintFlightMode

	lrv X1, 84				;stick scaling offset
	lds t, AuxStickScaling
	andi t, 0x03				;skip printing when zero
	breq bhs10

	push t
	ldz ss*2
	call PrintString
	pop t
	ldz auxss*2
	call PrintFromStringArray

bhs10:	rjmp udp23				;footer

bhs11:	;flight timer
	lrv X1, 0
	lds xl, Timer1min
	lds yl, Timer1sec
	rcall PrintTimer

	;user profile
	lrv X1, 103
	rcall PrintUserProfile

	;flight mode
	lrv X1, 0
	lrv Y1, 17
	ldz null*2				;print no label
	rcall PrintFlightMode

	;stick scaling offset
	lrv X1, 91
	lds t, AuxStickScaling
	andi t, 0x03				;skip printing when zero
	breq bhs13

	ldz auxss*2
	call PrintFromStringArray

bhs13:	;live battery voltage
	lrv X1, 0
	lrv Y1, 34
	b16loadx BatteryVoltage
	rcall PrintVoltage

	;logged battery voltage
	lrv X1, 67
	b16loadx BatteryVoltageLogged

	ldz 400					;adjust cursor position?
	cp xl, zl
	cpc xh, zh
	brge bhs15

	lrv X1, 79				;yes (less than 10V)

bhs15:	rcall PrintVoltage

	;footer
	lrv FontSelector, f6x8
	rjmp udp23

