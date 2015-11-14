; Call wrappers for routines that are called from C

.include "bindwrappers.asm"

show_version:
  nop

ShowVersion:

  safe_call_c show_version
  ret

asm_PrintString:
  push_all
  movw r30, r24
  call PrintString
  pop_all
  ret

asm_LcdUpdate:
  safe_called_from_c LcdUpdate
  ret

asm_GetButtonsBlocking:
  push_for_call_return_value
  call GetButtonsBlocking
  clr r25
  mov r24, t
  pop_for_call_return_value
  ret

asm_ShowNoAccessDlg:
  push_all
  movw r30, r24
  call ShowNoAccessDlg
  pop_all
  ret

asm_Print16Signed:
  push_all
  clr xh
  clr yh
  clr r25
  mov xl, r24
  call Print16Signed
  pop_all
  ret
