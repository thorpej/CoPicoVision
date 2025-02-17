;
; Copyright (c) 2023 Jason R. Thorpe.
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
; BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
; AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.
;

;
; There is only one CPU address line connected to the TMS9918, "MODE",
; which is typically tied to the low-order address line of the CPU.  All
; access to TMS9918 registers is indirect using some combination of MODE=0
; and MODE=1.
;
; The steps, from Table 2-1 of the TMS9918 manual.  Note that the bit
; numbers are reversed in the manual from the normal convention (bit 7
; is the LSB).
;
; CPU write to VDP register:
; 1. MODE1 <- data byte
; 2. MODE1 <- 0x80 | reg
;
; CPU write to VRAM:
; 1. MODE1 <- addrL
; 2. MODE1 <- 0x40 | addrH		N.B. 2 MSB of addrH MBZ!
; 3. MODE0 <- data byte
;    [addr auto-increments]
;    MODE0 <- data byte
;    ...
;
; CPU read from VDP register:
; 1. MODE1 -> data byte
;
; CPU read from VRAM:
; 1. MODE1 <- addrL
; 2. MODE1 <- addrH			N.B. 2 MSB of addrH MBZ!
; 3. MODE0 -> data byte
;    [addr auto-increments]
;    MODE0 -> data byte
;    ...
; Note that reads from VRAM are *extremely* slow.  See section 2.1.5 of
; the TMS9918 manual for details.
;

;
; Write-only configuration registers.
;
VDP_R0:			equ	0
VDP_R0_EXTIN_EN:	equ	0x01	; external input enable
VDP_R0_M3:		equ	0x02	; mode bit 3 (see mode table)
VDP_R0_MODE_MASKOUT:	equ	0xfd

VDP_R1:			equ	1
VDP_R1_SPRITE_MAG:	equ	0x01	; 2x sprite magnification
VDP_R1_SPRITE_SIZE:	equ	0x02	; 0=8x8, 1=16x16
VDP_R1_M2:		equ	0x08	; mode bit 2 (see mode table)
VDP_R1_M1:		equ	0x10	; mode bit 1 (see mode table)
VDP_R1_IE:		equ	0x20	; interrupt enable
VDP_R1_SCREEN:		equ	0x40	; 0=screen blank, 1=screen active
VDP_R1_16K:		equ	0x80	; 0=4K (4027s), 1=16K (4108s / 4116s)
VDP_R1_MODE_MASKOUT:	equ	0xe5

;
; Commands mixed with the VRAM address when setting the internal pointer.
;
VDP_VRAM_READ:		equ	0x00
VDP_VRAM_WRITE:		equ	0x40

;
; VIDEO MODES
;
; 	M1	M2	M3
;	0	0	0	Graphics I
;	0	0	1	Graphics II
;	0	1	0	Multicolor
;	1	0	0	Text
;

; Name Table Base Address -- 4 MSB MBZ!
VDP_NTBA:		equ	2
	; Name table at NTBA * 0x400 (a.k.a. NTBA << 10)

; Color Table Base Address
VDP_CTBA:		equ	3
	; Color table at CTBA * 0x40 (a.k.a. CTBA << 6)

; Pattern Generator Base Address - 5 MSB MBZ!
VDP_PGBA:		equ	4
	; Pattern Generator table at PGBA * 0x800 (a.k.a. PGBA << 11)

; Sprite Attribute Table Base Address - 1 MSB MBZ!
VDP_SATBA:		equ	5
	; Sprite Attribute table at SATBA * 0x80 (a.k.a. SATBA << 7)

; Sprite Pattern Generator Base Address - 5 MSB MBZ!
VDP_SPGBA:		equ	6
	; Sprite Pattern Generator table at SPGBA * 0x800 (e.k.a. SPGBA << 11)

; Text Color
; 4 MSB -- text color1
; 4 LSB -- text color0 / backdrop color
VDP_TEXTCOLOR:		equ	7

; Status register:
VDP_STS_5S_NUM:		equ	0x1f	; fifth sprite number
VDP_STS_C:		equ	0x20	; sprite coincidence
VDP_STS_5S:		equ	0x40	; fifth sprite
VDP_STS_F:		equ	0x80	; interrupt flag

; Color codes
VDP_COLOR_TRANS:	equ	0	; transparent
VDP_COLOR_BLACK:	equ	1
VDP_COLOR_MED_GREEN:	equ	2
VDP_COLOR_LT_GREEN:	equ	3
VDP_COLOR_DK_BLUE:	equ	4
VDP_COLOR_LT_BLUE:	equ	5
VDP_COLOR_DK_RED:	equ	6
VDP_COLOR_CYAN:		equ	7
VDP_COLOR_MED_RED:	equ	8
VDP_COLOR_LT_RED:	equ	9
VDP_COLOR_DK_YELLOW:	equ	10
VDP_COLOR_LT_YELLOW:	equ	11
VDP_COLOR_DK_GREEN:	equ	12
VDP_COLOR_MAGENTA:	equ	13
VDP_COLOR_GRAY:		equ	14
VDP_COLOR_WHITE:	equ	15
