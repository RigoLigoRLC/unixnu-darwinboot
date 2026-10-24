// SPDX-License-Identifier: BSD-2-Clause-Patent
#include <AsmMacroLib.h>

ASM_FUNC(DarwinCurrentEl)
  mrs x0, CurrentEL
  ret

// x0=boot_args PA, x1=entry PA, x2=owned PA, x3=owned size, x4=frame buffer
// PA (0 for none), x5=its size in bytes. EL1 only.
ASM_FUNC(DarwinEnter)
  msr daifset, #15
  mov x12, x4
  lsr x13, x5, #4
  bic x13, x13, #7

  // The first green band records entry after ExitBootServices succeeded.
  cbz x4, 2f
  cbz x13, 2f
  mov x9, x13
  mov w10, #0xFF00
  movk w10, #0xFF00, lsl #16
  mov x11, x4
3:
  stp w10, w10, [x11], #8
  subs x9, x9, #8
  b.hi 3b
  dsb sy
2:
  add x5, x2, x3
  mrs x6, ctr_el0
  ubfx x6, x6, #16, #4
  mov x7, #4
  lsl x6, x7, x6
  sub x7, x6, #1
  bic x4, x2, x7
  dsb sy
1:
  dc civac, x4
  add x4, x4, x6
  cmp x4, x5
  b.lo 1b
  dsb sy
  ic iallu
  dsb sy
  isb

  // The second cyan band records completion of the kernel-window cache work.
  cbz x12, 5f
  cbz x13, 5f
  mov x9, x13
  mov w10, #0xFFFF
  movk w10, #0xFF00, lsl #16
  add x11, x12, x13
4:
  stp w10, w10, [x11], #8
  subs x9, x9, #8
  b.hi 4b
  dsb sy
5:
  mrs x4, sctlr_el1
  bic x4, x4, #1
  bic x4, x4, #4
  bic x4, x4, #0x1000
  msr sctlr_el1, x4
  isb
  tlbi vmalle1
  dsb sy
  isb

  // The third blue band records execution with EL1 MMU and caches disabled.
  cbz x12, 7f
  cbz x13, 7f
  mov x9, x13
  mov w10, #0x00FF
  movk w10, #0xFF00, lsl #16
  add x11, x12, x13, lsl #1
6:
  stp w10, w10, [x11], #8
  subs x9, x9, #8
  b.hi 6b
  dsb sy
7:
  br x1
