

SBusMainMenu:

smm23:	ldy smm1 * 2

	lds xl, MainMenuListYposSave
	lds xh, MainMenuCursorYposSave

	ldi t, 19		;number of menu items
#ifndef IN_FLIGHT_TUNING
  dec t
#endif

	call Menu

	sts MainMenuListYposSave, yl
	sts MainMenuCursorYposSave, yh

	brcs smm22		;BACK pressed?
	ret			;Yes, return
	
smm22:	lsl xl			;No, calculate index    Z = *smm18 * 2 + xl * 2
	ldz smm18 * 2
	add zl, xl
	clr t
	adc zh, t

	lpm xl, z+		;x = (Z)
	lpm xh, z
	
	movw z, x		;z = x
	
	icall			;go to choosen menu item code  (sound like an apple product!  lawlz)

	call Beep

	call LcdClear		;blank screen
	call LcdUpdate	

	call ReleaseButtons
	
	jmp smm23




smm1:	
#ifdef IN_FLIGHT_TUNING
  .db "Remote Tuning       "
#endif
	.db "PI Editor           "
	.db "Self-level Settings "
	.db "Stick Scaling       "
	.db "Mode Settings       "
	.db "Misc. Settings      "
	.db "Gimbal Settings     "
	.db "Advanced Settings   "
	.db "AUX Switch Setup    "
	.db "DG2 Switch Setup    "
	.db "Initial Setup       "
	.db "Receiver Test       "
	.db "Sensor Test         "
	.db "Show Motor Layout   "
	.db "User Profile        "
	.db "Extra Features      "
	.db "ESC Calibration     "
	.db "Version Information "
#ifdef ADJUSTABLE_CONTRAST
	.db "LCD Contrast        "
#endif

smm18:
#ifdef IN_FLIGHT_TUNING
  .dw RemoteTuningDlg
#endif
	.dw PiEditor
	.dw SelflevelSettings
	.dw StickScaling
	.dw ModeSettings
	.dw MiscSettings
	.dw GimbalSettings
	.dw AdvancedSettings
	.dw AuxSwitchSetup
	.dw SBusDG2SwitchSetup
	.dw InitialSetup
	.dw SerialRxTest
	.dw SensorTest
	.dw MotorLayout
	.dw UserProfileSetup
	.dw ExtraFeatures
	.dw EscCalWarning
	.dw ShowVersion
#ifdef ADJUSTABLE_CONTRAST
	.dw Contrast
#endif

