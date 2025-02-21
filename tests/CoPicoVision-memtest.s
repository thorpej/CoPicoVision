;       
; Copyright (c) 2022, 2023, 2025 Jason R. Thorpe.   
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

	org	0x8000

	; ColecoVision cartridge header
ColecoVision_header:
	defb	0x55		; (swap to skip splash screen)
	defb	0xaa		; Display splash screen
	defw	0		; RAM sprite attr table pointer
	defw	0		; RAM sprite index table pointer
	defw	0		; pointer to temp work buffer (40 bytes)
	defw	0		; pointer to ctlr state table (2 + 2x5 bytes)
	defw	main		; start of cartridge code
	jp	rst		; RST 0x08
	jp	rst		; RST 0x10
	jp	rst		; RST 0x18
	jp	rst		; RST 0x20
	jp	rst		; RST 0x28
	jp	rst		; RST 0x30
	jp	irq		; RST 0x38
	jp	VDP_intr	; NMI (vertical blank interrupt)
	defb	"COPICOVISION MEMORY TEST"
	defb	"/PRESENTS THORPEJ'S/2025"

include 'tms9918a-font-spleen.s'
include 'tms9918a-regs.s'

ram_base:	equ	0x6000	; start of base RAM
ram_base_e1:	equ	0x6400	; first echo
ram_base_e2:	equ	0x6800
ram_base_e3:	equ	0x6c00
ram_base_e4:	equ	0x7000
ram_base_e5:	equ	0x7400
ram_base_e6:	equ	0x7800
ram_base_e7:	equ	0x7c00	; last echo

cart_base:	equ	0x8000

page_size:	equ	0x2000
ram_ext:	equ	0x2000	; 2 pages
bios:		equ	0x0000	; 1 page

stack_top:	equ	ram_base+0x400
vlbank_cnt:	equ	ram_base+0x100

VDP_IO_BASE:	equ	0xa0
VDP_IO_MODE0:	equ	VDP_IO_BASE+0
VDP_IO_MODE1:	equ	VDP_IO_BASE+1

.enable_ext_ram_str:
	defm	"  *** Enabling extended RAM ***"
.enable_ext_ram_str_end:
.enable_ext_ram_str_len:	equ	.enable_ext_ram_str_end - .enable_ext_ram_str

.disable_rom_str:
	defm	"  *** Disabling BIOS ROM ***"
.disable_rom_str_end:
.disable_rom_str_len:	equ	.disable_rom_str_end - .disable_rom_str

.zero_ext_base_ram_str:
	defm	"  *** Zeroing extended base RAM ***"
.zero_ext_base_ram_str_end:
.zero_ext_base_ram_str_len:	equ	.zero_ext_base_ram_str_end - .zero_ext_base_ram_str

.wait_vlank_str:
	defm	"  *** Waiting for VBLANK NMI ***"
.wait_vlank_str_end:
.wait_vlank_str_len:		equ	.wait_vlank_str_end - .wait_vlank_str

wait_vblank:
	ld	HL, .wait_vlank_str
	ld	BC, .wait_vlank_str_len
	call	VDP_copyin_continue

	ld	HL, vlbank_cnt
	ld	A, (HL)
.wait_vblank_loop:
	cp	(HL)
	jp	NZ, .wait_vblank_loop
	ret

main:
	di			; disable interrupts
	ld	SP, stack_top	; stack at top of base RAM
	call	VDP_init	; initialize the VDP to text mode

	; Copy the font into the VDP Pattern Table
	ld	HL, VDP_text_font
	ld	DE, VDP_text_font_ptoffset
	ld	BC, VDP_text_font_size
	call	VDP_pt_copyin

	; Announce ourselves.
	ld	C, 0		; Row 0
	ld	A, 2		; Column 2
	call	VDP_setrowcol
	ld	HL, .title_str
	ld	BC, .title_str_len
	call	VDP_copyin_continue

	ld	C, 2
	call	VDP_setrow
	call	test1

	ld	C, 3
	call	VDP_setrow
	call	test2

	ld	C, 4
	call	VDP_setrow
	call	test3

	; Enable the extended RAM.
	ld	C, 5
	call	VDP_setrow
	ld	HL, .enable_ext_ram_str
	ld	BC, .enable_ext_ram_str_len
	call	VDP_copyin_continue

	ld	A, 0x01
	out	(0x53), A

	ld	C, 6
	call	VDP_setrow
	call	test4

	ld	C, 7
	call	VDP_setrow
	call	test5

	; Zero the "extended base" RAM.
	ld	C, 8
	call	VDP_setrow
	ld	HL, .zero_ext_base_ram_str
	ld	BC, .zero_ext_base_ram_str_len
	call	VDP_copyin_continue

	xor	A			  ; A <- 0
	ld	HL, ram_base_e1		  ; HL <- destination
	ld	BC, cart_base-ram_base_e1 ; BC <- byte count
	call	memset

	ld	C, 9
	call	VDP_setrow
	call	test6

	ld	C, 10
	call	VDP_setrow
	call	test7

	ld	C, 11
	call	VDP_setrow
	call	wait_vblank

	; Disable the ROM.  The contents were copied to the underying
	; RAM in test 2, which will allow the NMI vector to continue
	; working.
	ld	C, 12
	call	VDP_setrow
	ld	HL, .disable_rom_str
	ld	BC, .disable_rom_str_len
	call	VDP_copyin_continue

	ld	A, %00001101
	out	(0x7f), A

	ld	C, 13
	call	VDP_setrow
	call	wait_vblank

	ld	C, 14
	call	VDP_setrow
	call	test8

	ld	C, 23		; Row 23
	call	VDP_setrow
	ld	HL, .tests_complete_str
	ld	BC, .tests_complete_str_len
	call	VDP_copyin_continue

.spin:	jp	.spin

.title_str:
	defm	"CoPicoVision Memory Map Test Utility"
.title_str_end:
.title_str_len:	equ	.title_str_end - .title_str

.tests_complete_str:
	defm	"All tests complete."
.tests_complete_str_end:
.tests_complete_str_len:	equ .tests_complete_str_end - .tests_complete_str

.test_pass_str:
	defm	"--pass--"
.test_pass_str_end:
.test_pass_str_len:	equ	.test_pass_str_end - .test_pass_str

.test_fail_str:
	defm	"--fail--"
.test_fail_str_end:
.test_fail_str_len:	equ	.test_fail_str_end - .test_fail_str

.generic_test_pass:
	ld	HL, .test_pass_str
	ld	BC, .test_pass_str_len
	call	VDP_copyin_continue
	ret

.generic_test_fail:
	ld	HL, .test_fail_str
	ld	BC, .test_fail_str_len
	call	VDP_copyin_continue
	ret

;
; Test 1 -- Ensure that in the default memory map, base RAM is mirrored
; every 1K in its 8K page.
;
test1:
	ld	HL, .test1_preamble_str
	ld	BC, .test1_preamble_str_len
	call	VDP_copyin_continue

	ld	HL, ram_base		; HL <- RAM base
	ld	(HL), 0			; Put 0 in the first byte of RAM.

	ld	IX, ram_base_e1		; IX <- RAM base, first mirror
	ld	(IX+0), 1		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	1
	jp	NZ, test1_e1_fail

	ld	IX, ram_base_e2		; IX <- RAM base, second mirror
	ld	(IX+0), 2		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	2
	jp	NZ, test1_e2_fail

	ld	IX, ram_base_e3		; IX <- RAM base, third mirror
	ld	(IX+0), 3		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	3
	jp	NZ, test1_e3_fail

	ld	IX, ram_base_e4		; IX <- RAM base, fourth mirror
	ld	(IX+0), 4		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	4
	jp	NZ, test1_e4_fail

	ld	IX, ram_base_e5		; IX <- RAM base, fifth mirror
	ld	(IX+0), 5		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	5
	jp	NZ, test1_e5_fail

	ld	IX, ram_base_e6		; IX <- RAM base, sixth mirror
	ld	(IX+0), 6		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	6
	jp	NZ, test1_e6_fail

	ld	IX, ram_base_e7		; IX <- RAM base, seventh mirror
	ld	(IX+0), 7		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	7
	jp	NZ, test1_e7_fail

	jp	.generic_test_pass

.test1_preamble_str:
	defm	"1 base RAM mirror "
.test1_preamble_str_end:
.test1_preamble_str_len:	equ .test1_preamble_str_end - .test1_preamble_str

test1_e1_fail:
	ld	HL, .test1_e1_fail_str
	ld	BC, .test1_e1_fail_str_len
	call	VDP_copyin_continue
	ret

test1_e2_fail:
	ld	HL, .test1_e2_fail_str
	ld	BC, .test1_e2_fail_str_len
	call	VDP_copyin_continue
	ret

test1_e3_fail:
	ld	HL, .test1_e3_fail_str
	ld	BC, .test1_e3_fail_str_len
	call	VDP_copyin_continue
	ret

test1_e4_fail:
	ld	HL, .test1_e4_fail_str
	ld	BC, .test1_e4_fail_str_len
	call	VDP_copyin_continue
	ret

test1_e5_fail:
	ld	HL, .test1_e5_fail_str
	ld	BC, .test1_e5_fail_str_len
	call	VDP_copyin_continue
	ret

test1_e6_fail:
	ld	HL, .test1_e6_fail_str
	ld	BC, .test1_e6_fail_str_len
	call	VDP_copyin_continue
	ret

test1_e7_fail:
	ld	HL, .test1_e7_fail_str
	ld	BC, .test1_e7_fail_str_len
	call	VDP_copyin_continue
	ret

.test1_e1_fail_str:
	defm	"--failed-- at 0x6400"
.test1_e1_fail_str_end:
.test1_e1_fail_str_len:		equ	.test1_e1_fail_str_end - .test1_e1_fail_str

.test1_e2_fail_str:
	defm	"--failed-- at 0x6800"
.test1_e2_fail_str_end:
.test1_e2_fail_str_len:		equ	.test1_e2_fail_str_end - .test1_e2_fail_str

.test1_e3_fail_str:
	defm	"--failed-- at 0x6c00"
.test1_e3_fail_str_end:
.test1_e3_fail_str_len:		equ	.test1_e3_fail_str_end - .test1_e3_fail_str

.test1_e4_fail_str:
	defm	"--failed-- at 0x7000"
.test1_e4_fail_str_end:
.test1_e4_fail_str_len:		equ	.test1_e4_fail_str_end - .test1_e4_fail_str

.test1_e5_fail_str:
	defm	"--failed-- at 0x7400"
.test1_e5_fail_str_end:
.test1_e5_fail_str_len:		equ	.test1_e5_fail_str_end - .test1_e5_fail_str

.test1_e6_fail_str:
	defm	"--failed-- at 0x7800"
.test1_e6_fail_str_end:
.test1_e6_fail_str_len:		equ	.test1_e6_fail_str_end - .test1_e6_fail_str

.test1_e7_fail_str:
	defm	"--failed-- at 0x7c00"
.test1_e7_fail_str_end:
.test1_e7_fail_str_len:		equ	.test1_e7_fail_str_end - .test1_e7_fail_str

;
; test2 -- Ensure that the ROM area is read-only in the default
; config.  The pattern that we write into the ROM area is, however,
; expected to land in the "hidden" RAM, and we will test for that
; later.
;
; Put the test pattern near the end of the BIOS page.
;
test2_dest:	equ	bios+page_size-64
test2:
	ld	HL, .test2_preamble_str
	ld	BC, .test2_preamble_str_len
	call	VDP_copyin_continue

	;
	; The CoPicoVision's memory address decoder is designed to
	; pass writes through to RAM even if the BIOS ROM is still
	; enabled.  This will be confirmed in a subsequent test.
	; First, however, we must copy the entire BIOS ROM into the
	; RAM below so that things continue to work when we disable
	; it later.
	;
	ld	HL, bios		; HL <- BIOS ROM
	ld	DE, bios		; DE <- destination (BIOS page)
	ld	BC, page_size		; BC <- length
	ldir				; Copy it

	; XXX
	ld	A, 0x01
	out	(0x53), A

	ld	HL, .test2_testpat	; HL <- test pattern
	ld	DE, test2_dest		; DE <- destination
	ld	BC, .test2_testpat_len	; BC <- length
	push	HL			; preserve the arguments
	push	DE
	push	BC
	ldir				; Copy it
	pop	BC			; restore the arguments
	pop	DE
	pop	HL

	; XXX
	xor	A
	out	(0x53), A

	call	memcmp			; Now, compare.
	jp	Z, .generic_test_fail	; Match -> FAIL - ROM is enabled!
	jp	.generic_test_pass

.test2_preamble_str:
	defm	"2 BIOS ROM read-only "
.test2_preamble_str_end:
.test2_preamble_str_len:	equ .test2_preamble_str_end - .test2_preamble_str

.test2_testpat:
	defm	"The quick brown fox jumps over the lazy dog."
.test2_testpat_end:
.test2_testpat_len:		equ	.test2_testpat_end - .test2_testpat

;
; test3 -- Ensure that extended RAM is disabled by writing a test pattern
; and verify that it does not stick.
;
test3:
	ld	HL, .test3_preamble_str
	ld	BC, .test3_preamble_str_len
	call	VDP_copyin_continue

	;
	; Write a different pattern to each page of extended RAM.
	;
	ld	A, 0xaa			; A <- test pattern
	ld	HL, ram_ext		; HL <- destination
	ld	BC, page_size		; BC <- byte count
	call	memset

	ld	A, 0x55			; A <- test pattern
	ld	HL, ram_ext+page_size	; HL <- destination
	ld	BC, page_size		; BC <- byte count
	call	memset

	;
	; Check the first page.
	;
	ld	A, 0xaa
	ld	HL, ram_ext
	ld	BC, page_size
	call	membytecmp
	jr	Z, test3_p1_fail	; match -> FAIL

	;
	; Check the second page.
	;
	ld	A, 0x55
	ld	HL, ram_ext+page_size
	ld	BC, page_size
	call	membytecmp
	jr	Z, test3_p2_fail	; match -> FAIL

	jp	.generic_test_pass

test3_p1_fail:
	ld	HL, .test3_p1_fail_str
	ld	BC, .test3_p1_fail_str_len
	call	VDP_copyin_continue
	ret

test3_p2_fail:
	ld	HL, .test3_p2_fail_str
	ld	BC, .test3_p2_fail_str_len
	call	VDP_copyin_continue
	ret

.test3_preamble_str:
	defm	"3 ext RAM disabled "
.test3_preamble_str_end:
.test3_preamble_str_len:	equ	.test3_preamble_str_end - .test3_preamble_str

.test3_p1_fail_str:
	defm	"--failed-- at 0x2000"
.test3_p1_fail_str_end:
.test3_p1_fail_str_len:		equ	.test3_p1_fail_str_end - .test3_p1_fail_str

.test3_p2_fail_str:
	defm	"--failed-- at 0x4000"
.test3_p2_fail_str_end:
.test3_p2_fail_str_len:		equ	.test3_p2_fail_str_end - .test3_p2_fail_str

;
; test 4 -- Verify that the base RAM range does not mirror every 1K when
; extended RAM is enabled.
;
test4:
	ld	HL, .test4_preamble_str
	ld	BC, .test4_preamble_str_len
	call	VDP_copyin_continue

	ld	HL, ram_base		; HL <- RAM base
	ld	(HL), 0			; Put 0 in the first byte of RAM.

	ld	IX, ram_base_e1		; IX <- RAM base, first mirror
	ld	(IX+0), 1		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	1
	jp	Z, test1_e1_fail

	ld	IX, ram_base_e2		; IX <- RAM base, second mirror
	ld	(IX+0), 2		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	2
	jp	Z, test1_e2_fail

	ld	IX, ram_base_e3		; IX <- RAM base, third mirror
	ld	(IX+0), 3		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	3
	jp	Z, test1_e3_fail

	ld	IX, ram_base_e4		; IX <- RAM base, fourth mirror
	ld	(IX+0), 4		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	4
	jp	Z, test1_e4_fail

	ld	IX, ram_base_e5		; IX <- RAM base, fifth mirror
	ld	(IX+0), 5		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	5
	jp	Z, test1_e5_fail

	ld	IX, ram_base_e6		; IX <- RAM base, sixth mirror
	ld	(IX+0), 6		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	6
	jp	Z, test1_e6_fail

	ld	IX, ram_base_e7		; IX <- RAM base, seventh mirror
	ld	(IX+0), 7		; Store a value there.
	ld	A, (HL)			; Read it back from base
	cp	7
	jp	Z, test1_e7_fail

	jp	.generic_test_pass

.test4_preamble_str:
	defm	"4 ext base non-mirror "
.test4_preamble_str_end:
.test4_preamble_str_len:	equ .test4_preamble_str_end - .test4_preamble_str

;
; test5 -- Verify extended RAM is working by zeroing it, checking for zeros,
; and then writing a different test pattern to each 1K region and verifying
; it.
;
test5:
	ld	HL, .test5_preamble_str
	ld	BC, .test5_preamble_str_len
	call	VDP_copyin_continue

	;
	; Zero out both pages and check that it stuck.
	;
	xor	A			; A <- 0
	ld	HL, ram_ext		; HL <- destination
	ld	BC, page_size*2		; BC <- byte_count
	call	memset

	; Args were preserved; just check now.
	call	membytecmp
	jp	NZ, .test5_z_fail

	;
	; Write a different pattern to each 1K region of extended RAM.
	;
	ld	A, 0x01			; A <- test pattern
	ld	HL, ram_ext		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x02			; A <- test pattern
	ld	HL, ram_ext+0x0400	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x04			; A <- test pattern
	ld	HL, ram_ext+0x0800	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x08			; A <- test pattern
	ld	HL, ram_ext+0x0c00	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x10			; A <- test pattern
	ld	HL, ram_ext+0x1000	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x20			; A <- test pattern
	ld	HL, ram_ext+0x1400	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x40			; A <- test pattern
	ld	HL, ram_ext+0x1800	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x80			; A <- test pattern
	ld	HL, ram_ext+0x1c00	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x03			; A <- test pattern
	ld	HL, ram_ext+0x2000	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x06			; A <- test pattern
	ld	HL, ram_ext+0x2400	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x0c			; A <- test pattern
	ld	HL, ram_ext+0x2800	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x18			; A <- test pattern
	ld	HL, ram_ext+0x2c00	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x30			; A <- test pattern
	ld	HL, ram_ext+0x3000	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x60			; A <- test pattern
	ld	HL, ram_ext+0x3400	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0xc0			; A <- test pattern
	ld	HL, ram_ext+0x3800	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x55			; A <- test pattern
	ld	HL, ram_ext+0x3c00	; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

test5_verify:
	;
	; Now check each 1K region.
	;
	ld	A, 0x01
	ld	HL, ram_ext
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_2000_fail

	ld	A, 0x02
	ld	HL, ram_ext+0x0400
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_2400_fail

	ld	A, 0x04
	ld	HL, ram_ext+0x0800
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_2800_fail

	ld	A, 0x08
	ld	HL, ram_ext+0x0c00
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_2c00_fail

	ld	A, 0x10
	ld	HL, ram_ext+0x1000
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_3000_fail

	ld	A, 0x20
	ld	HL, ram_ext+0x1400
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_3400_fail

	ld	A, 0x40
	ld	HL, ram_ext+0x1800
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_3800_fail

	ld	A, 0x80
	ld	HL, ram_ext+0x1c00
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_3c00_fail

	ld	A, 0x03
	ld	HL, ram_ext+0x2000
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_4000_fail

	ld	A, 0x06
	ld	HL, ram_ext+0x2400
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_4400_fail

	ld	A, 0x0c
	ld	HL, ram_ext+0x2800
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_4800_fail

	ld	A, 0x18
	ld	HL, ram_ext+0x2c00
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_4c00_fail

	ld	A, 0x30
	ld	HL, ram_ext+0x3000
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_5000_fail

	ld	A, 0x60
	ld	HL, ram_ext+0x3400
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_5400_fail

	ld	A, 0xc0
	ld	HL, ram_ext+0x3800
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_5800_fail

	ld	A, 0x55
	ld	HL, ram_ext+0x3c00
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, .test5_5c00_fail

	jp	.generic_test_pass

.test5_z_fail:
	ld	HL, .test5_z_fail_str
	ld	BC, .test5_z_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_2000_fail:
	ld	HL, .test5_2000_fail_str
	ld	BC, .test5_2000_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_2400_fail:
	ld	HL, .test5_2400_fail_str
	ld	BC, .test5_2400_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_2800_fail:
	ld	HL, .test5_2800_fail_str
	ld	BC, .test5_2800_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_2c00_fail:
	ld	HL, .test5_2c00_fail_str
	ld	BC, .test5_2c00_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_3000_fail:
	ld	HL, .test5_3000_fail_str
	ld	BC, .test5_3000_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_3400_fail:
	ld	HL, .test5_3400_fail_str
	ld	BC, .test5_3400_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_3800_fail:
	ld	HL, .test5_3800_fail_str
	ld	BC, .test5_3800_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_3c00_fail:
	ld	HL, .test5_3c00_fail_str
	ld	BC, .test5_3c00_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_4000_fail:
	ld	HL, .test5_4000_fail_str
	ld	BC, .test5_4000_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_4400_fail:
	ld	HL, .test5_4400_fail_str
	ld	BC, .test5_4400_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_4800_fail:
	ld	HL, .test5_4800_fail_str
	ld	BC, .test5_4800_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_4c00_fail:
	ld	HL, .test5_4c00_fail_str
	ld	BC, .test5_4c00_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_5000_fail:
	ld	HL, .test5_5000_fail_str
	ld	BC, .test5_5000_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_5400_fail:
	ld	HL, .test5_5400_fail_str
	ld	BC, .test5_5400_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_5800_fail:
	ld	HL, .test5_5800_fail_str
	ld	BC, .test5_5800_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_5c00_fail:
	ld	HL, .test5_5c00_fail_str
	ld	BC, .test5_5c00_fail_str_len
	call	VDP_copyin_continue
	ret

.test5_preamble_str:
	defm	"5 ext RAM enabled "
.test5_preamble_str_end:
.test5_preamble_str_len:	equ	.test5_preamble_str_end - .test5_preamble_str

.test5_z_fail_str:
	defm	"--failed-- to zero"
.test5_z_fail_str_end:
.test5_z_fail_str_len:		equ	.test5_z_fail_str_end - .test5_z_fail_str

.test5_2000_fail_str:
	defm	"--failed-- at 0x2000"
.test5_2000_fail_str_end:
.test5_2000_fail_str_len:	equ	.test5_2000_fail_str - .test5_2000_fail_str_end

.test5_2400_fail_str:
	defm	"--failed-- at 0x2400"
.test5_2400_fail_str_end:
.test5_2400_fail_str_len:	equ	.test5_2400_fail_str - .test5_2400_fail_str_end

.test5_2800_fail_str:
	defm	"--failed-- at 0x2800"
.test5_2800_fail_str_end:
.test5_2800_fail_str_len:	equ	.test5_2800_fail_str - .test5_2800_fail_str_end

.test5_2c00_fail_str:
	defm	"--failed-- at 0x2c00"
.test5_2c00_fail_str_end:
.test5_2c00_fail_str_len:	equ	.test5_2c00_fail_str - .test5_2c00_fail_str_end

.test5_3000_fail_str:
	defm	"--failed-- at 0x3000"
.test5_3000_fail_str_end:
.test5_3000_fail_str_len:	equ	.test5_3000_fail_str - .test5_3000_fail_str_end

.test5_3400_fail_str:
	defm	"--failed-- at 0x3400"
.test5_3400_fail_str_end:
.test5_3400_fail_str_len:	equ	.test5_3400_fail_str - .test5_3400_fail_str_end

.test5_3800_fail_str:
	defm	"--failed-- at 0x3800"
.test5_3800_fail_str_end:
.test5_3800_fail_str_len:	equ	.test5_3800_fail_str - .test5_3800_fail_str_end

.test5_3c00_fail_str:
	defm	"--failed-- at 0x3c00"
.test5_3c00_fail_str_end:
.test5_3c00_fail_str_len:	equ	.test5_3c00_fail_str - .test5_3c00_fail_str_end

.test5_4000_fail_str:
	defm	"--failed-- at 0x4000"
.test5_4000_fail_str_end:
.test5_4000_fail_str_len:	equ	.test5_4000_fail_str - .test5_4000_fail_str_end

.test5_4400_fail_str:
	defm	"--failed-- at 0x4400"
.test5_4400_fail_str_end:
.test5_4400_fail_str_len:	equ	.test5_4400_fail_str - .test5_4400_fail_str_end

.test5_4800_fail_str:
	defm	"--failed-- at 0x4800"
.test5_4800_fail_str_end:
.test5_4800_fail_str_len:	equ	.test5_4800_fail_str - .test5_4800_fail_str_end

.test5_4c00_fail_str:
	defm	"--failed-- at 0x4c00"
.test5_4c00_fail_str_end:
.test5_4c00_fail_str_len:	equ	.test5_4c00_fail_str - .test5_4c00_fail_str_end

.test5_5000_fail_str:
	defm	"--failed-- at 0x5000"
.test5_5000_fail_str_end:
.test5_5000_fail_str_len:	equ	.test5_5000_fail_str - .test5_5000_fail_str_end

.test5_5400_fail_str:
	defm	"--failed-- at 0x5400"
.test5_5400_fail_str_end:
.test5_5400_fail_str_len:	equ	.test5_5400_fail_str - .test5_5400_fail_str_end

.test5_5800_fail_str:
	defm	"--failed-- at 0x5800"
.test5_5800_fail_str_end:
.test5_5800_fail_str_len:	equ	.test5_5800_fail_str - .test5_5800_fail_str_end

.test5_5c00_fail_str:
	defm	"--failed-- at 0x5c00"
.test5_5c00_fail_str_end:
.test5_5c00_fail_str_len:	equ	.test5_5c00_fail_str - .test5_5c00_fail_str_end

;
; test6 -- Re-verify the patterns written to extended RAM in test5.
;
test6:
	ld	HL, .test6_preamble_str
	ld	BC, .test6_preamble_str_len
	call	VDP_copyin_continue
	jp	test5_verify

.test6_preamble_str:
	defm	"6 ext RAM re-check "
.test6_preamble_str_end:
.test6_preamble_str_len:	equ	.test6_preamble_str_end - .test6_preamble_str

;
; test 7 -- Write a different pattern to each 1K region of "extended base"
; and verify.
;
test7:
	ld	HL, .test7_preamble_str
	ld	BC, .test7_preamble_str_len
	call	VDP_copyin_continue

	;
	; Write a different pattern to each 1K region of extended base RAM.
	;
	ld	A, 0x11			; A <- test pattern
	ld	HL, ram_base_e1		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x22			; A <- test pattern
	ld	HL, ram_base_e2		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x33			; A <- test pattern
	ld	HL, ram_base_e3		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x44			; A <- test pattern
	ld	HL, ram_base_e4		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x55			; A <- test pattern
	ld	HL, ram_base_e5		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x66			; A <- test pattern
	ld	HL, ram_base_e6		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	ld	A, 0x77			; A <- test pattern
	ld	HL, ram_base_e7		; HL <- destination
	ld	BC, 0x400		; BC <- byte count
	call	memset

	;
	; Now check each 1K region.
	;
	ld	A, 0x11
	ld	HL, ram_base_e1
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e1_fail

	ld	A, 0x22
	ld	HL, ram_base_e2
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e2_fail

	ld	A, 0x33
	ld	HL, ram_base_e3
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e3_fail

	ld	A, 0x44
	ld	HL, ram_base_e4
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e4_fail

	ld	A, 0x55
	ld	HL, ram_base_e5
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e5_fail

	ld	A, 0x66
	ld	HL, ram_base_e6
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e6_fail

	ld	A, 0x77
	ld	HL, ram_base_e7
	ld	BC, 0x400
	call	membytecmp
	jp	NZ, test1_e7_fail

	jp	.generic_test_pass

.test7_preamble_str:
	defm	"7 ext base RAM "
.test7_preamble_str_end:
.test7_preamble_str_len:	equ	.test7_preamble_str_end - .test7_preamble_str

;
; test 8 -- Check the test pattern written in test2 now that the ROM
; has been disabled.
;
test8:
	ld	HL, .test8_preamble_str
	ld	BC, .test8_preamble_str_len
	call	VDP_copyin_continue

	ld	HL, test2_dest		; HL <- test pattern written to
	ld	DE, .test2_testpat	; DE <- test pattern written from
	ld	BC, .test2_testpat_len	; BC <- length
	call	memcmp			; Now, compare.
	jp	NZ, .test8_fail
	jp	.generic_test_pass

.test8_fail:
	call	hexdump			; HL and BC already set
	jp	.generic_test_fail

.test8_preamble_str:
	defm	"8 check ROM area test pattern "
.test8_preamble_str_end:
.test8_preamble_str_len:	equ	.test8_preamble_str_end - .test8_preamble_str

rst:
	ret

irq:
	ei
	reti

;
; memset(3)
;
; Arguments:
;	A	The value to set
;	HL	Destination
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
memset:
	push	AF			; save AF
	push	BC			; save BC
	push	DE			; save DE
	push	HL			; save HL

	ld	D, A			; get value into D
.memset_loop:
	ld	(HL), D
	inc	HL
	dec	BC
	ld	A, C
	or	B			; mix all length bits together
	jr	NZ, .memset_loop	; Loop if not 0

	pop	HL
	pop	DE
	pop	BC
	pop	AF
	ret

;
; memcmp(3)
;
; Arguments:
;	DE	One of the buffers
;	HL	The other of the buffers
;	BC	Byte count
;
; Returns:
;	Z flag set if entire buffer is equal, not set if .. not.
;	A contains the difference: *DE - *HL
;
; Clobbers:
;	AF
;
memcmp:
	push	BC			; save BC
	push	DE			; save DE
	push	HL			; save HL

.memcmp_loop:
	ld	A, (DE)
	sub	(HL)
	jr	NZ, .memcmp_done
	inc	DE
	inc	HL
	dec	BC
	ld	A, C
	or	B			; mix all length bits together
	jr	NZ, .memcmp_loop

.memcmp_done:
	pop	HL
	pop	DE
	pop	BC
	ret

;
; membytecmp:
;	Like memcmp(3), but we're only comparing against a single byte
;	value.
;
; Arguments:
;	A	Comparison byte
;	HL	Buffer to check
;	BC	Byte count
;
; Returns:
;	Z flag set if entire buffer is equal, not set if .. not.
;	A contains the difference: *HL - <byte>
;
; Clobbers:
;	AF
;
membytecmp:
	push	BC			; save BC
	push	DE			; save DE
	push	HL			; save HL

	ld	D, A			; value into D
.membytecmp_loop:
	ld	A, (HL)
	sub	D
	jr	NZ, .membytecmp_done
	inc	HL
	dec	BC
	ld	A, C
	or	B			; mix all length bits together
	jr	NZ, .membytecmp_loop

.membytecmp_done:
	pop	HL
	pop	DE
	pop	BC
	ret

;
; hexdump:
;	Dump a buffer as hexadecimal numbers.
;
; Arguments:
;	HL	Pointer to buffer
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
hexdump:
	push	AF			; save AF
	push	HL			; save HL
	push	BC			; save BC

.hexdump_loop:
	ld	A, (HL)
	call	printhex
	inc	HL
	dec	BC
	ld	A, ' '
	call	VDP_vram_put
	ld	A, C
	or	B
	jr	NZ, .hexdump_loop

	pop	BC
	pop	HL
	pop	AF
	ret

;
; printhex:
;	Prints an 8-bit hexadecimal number
;
; Arguments:
;	A	The value to print.
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
printhex:
	push	AF			; save AF
	push	BC			; save BC
	push	HL			; save HL

	push	AF			; save AF again
	ld	C, A			; get value into C
	ld	B, 0			; zero-extend to 16-bit
	srl	C			; get the upper nybble...
	srl	C
	srl	C
	srl	C			; ...into the lower nybble.
	call	.printhex_nybble

	pop	AF			; get saved value back
	and	0x0f			; mask off upper nybble
	ld	C, A			; get value into C
					; (B is still 0)
	call	.printhex_nybble

	pop	HL
	pop	BC
	pop	AF
	ret

.printhex_nybble:
	ld	HL, .printhex_digits
	add	HL, BC			; HL points to the digit
	ld	A, (HL)			; A = digit character
	call	VDP_vram_put		; ...and put it to the console.
	ret
.printhex_digits:
	defm	"0123456789ABCDEF"

;
; VDP_init:
;	Basic initialization of the VDP.
;
; Arguments:
;	None.
;
; Returns:
;	None.
;
; Clobbers:
;	A, BC, DE
;
VDP_init:
	; Load the default (text mode) config.
	call	VDP_load_config

	; Clear the Pattern Table.
	ld	DE, (VDP_Pattern_Table)
	ld	BC, 2048
	xor	A
	call	VDP_memset

	; Clear the Name Table.
	ld	DE, (VDP_Name_Table)
	ld	BC, 40*24
	xor	A
	call	VDP_memset

	ret

VDP_intr:
	push	HL
	ld	HL, vlbank_cnt
	inc	(HL)
	pop	HL
	retn

;
; VDP_set_address:
;	Set the VRAM address.
;
; Arguments:
;	A	read or write command
;	DE	VRAM address
;
; Returns:
;	None.
;
; Clobbers:
;	A
;
VDP_set_address:
	push	BC			; save BC

	or	D			; OR in MSB of VRAM address
	and	0x7f			; ensure upper bit is clear

	ld	C, VDP_IO_MODE1		; C <- destination port
	out	(C), E			; write LSB of VRAM address
	out	(C), A			; write MSB of VRAM address

	pop	BC
	ret

;
; VDP_setrow:
;	Set the VRAM address based on a row in the Name Table.
;
; Arguments:
;	C	Row
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_setrow:
	push	AF			; save AF
	xor	A			; clear A
	jp	.VDP_setrowcol_af	; go do the work

;
; VDP_setrowcol:
;	Set the VRAM address based on a row/column in the Name Table.
;
; Arguments:
;	C	Row
;	A	Column
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_setrowcol:
	push	AF			; save AF
.VDP_setrowcol_af:
	push	BC			; save BC
	push	DE			; save DE
	push	IX			; save IX

	ex	DE, HL			; save HL in DE

	; Get the row offset
	ld	B, 0			; zero-extend C
	sla	C			; index to table offset

	ld	IX, .VDP_rowaddrs
	add	IX, BC			; IX points to row address entry
	ld	L, (IX+0)		; L = LSB of row address
	ld	H, (IX+1)		; H = MSB of row address

	; HL now has the VRAM address of the beginning of the row

	ld	C, A			; column into C
	add	HL, BC			; add in column offset

	; HL now has the VRAM address of the desired character cell

	ex	DE, HL			; addr into DE, restore HL

	ld	A, VDP_VRAM_WRITE	; A <- VRAM write command
	call	VDP_set_address

	pop	IX
	pop	DE
	pop	BC
	pop	AF
	ret

;
; VDP_vram_put:
;	Put a single byte into VRAM.  This isn't done inline because
;	the VRAM is slow-ish, so burning the cycles isn't really a
;	problem.
;
; Arguments:
;	A	Byte to put into VRAM
;	Assumes the VRAM address has already been configured for writing.
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_vram_put:
	out	(VDP_IO_MODE0), A
	ret

;
; VDP_copyin_clobber:
;	Copy a memory buffer into VRAM.  This version doesn't bother
;	saving / restoring any registers so that it can be called
;	from an interrupt handler, which will be doing that anyway.
;
; Arguments:
;	HL	Source buffer
;	DE	The VRAM address
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	AF, BC, DE, HL
;
VDP_copyin_clobber:
	ld	A, VDP_VRAM_WRITE	; A <- VRAM write command
	call	VDP_set_address		; Set the VRAM address

.VDP_copyin_loop_start:
	ld	D, B			; get byte count...
	ld	E, C			; ...into DE.

	ld	C, VDP_IO_MODE0		; C <- destination port
.VDP_copyin_loop:
	outi				; VRAM <- *HL++, B-- (don't care)
	dec	DE			; decrement byte count
	; XXX Need any NOPs?  (Not on CoPicoVision...)
	ld	A, E
	or	D			; mix all length bits together
	jp	NZ, .VDP_copyin_loop	; Loop if not 0
	ret

;
; VDP_copyin:
;	Copy a memory buffer into VRAM.
;
; Arguments:
;	HL	Source buffer
;	DE	The VRAM address
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_copyin:
	push	AF			; save AF
	push	BC			; save BC
	push	DE			; save DE
	push	HL			; save HL

	call	VDP_copyin_clobber

	pop	HL
	pop	DE
	pop	BC
	pop	AF
	ret

;
; VDP_copyin_continue:
;	Continue copying a memory buffer into VRAM, starting at
;	the already set VRAM location.
;
; Arguments:
;	HL	Source buffer
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_copyin_continue:
	push	AF			; save AF
	push	BC			; save BC
	push	DE			; save DE
	push	HL			; save HL

	call	.VDP_copyin_loop_start

	pop	HL
	pop	DE
	pop	BC
	pop	AF
	ret

;
; VDP_pt_copyin:
;	Convenience routine that copies data to the pattern
;	table at the specified offset.
;
; Arguments:
;	HL	Source buffer
;	DE	Offset into the Pattern Table
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_pt_copyin:
	push	HL			; save HL temporarily
	ld	HL, (VDP_Pattern_Table)	; HL <- Pattern Table VRAM address
	add	HL, DE			; Add the offset
	ld	E, L			; Get the result...
	ld	D, H			; ...into DE.
	pop	HL			; restore HL
	jp	VDP_copyin		; tail-call to VDP_copyin()

;
; VDP_memset:
;	Set a region of VRAM to a value.
;
; Arguments:
;	A	The value to set
;	DE	The VRAM address
;	BC	Byte count
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_memset:
	push	AF			; save AF
	push	BC			; save BC
	push	DE			; save DE

	push	AF			; push AF again
	ld	A, VDP_VRAM_WRITE	; A <- VRAM write command
	call	VDP_set_address		; Set the VRAM address

	ld	E, C			; Get byte count...
	ld	D, B			; ...into DE.

	pop	BC			; pop value into B
	ld	C, VDP_IO_MODE0		; C <- destination port
.VDP_memset_loop:
	out	(C), B			; VRAM <- value
	dec	DE			; decrement byte count
	; XXX Need any NOPs?  (Not on CoPicoVision...)
	ld	A, E
	or	D			; mix all length bits together
	jp	NZ, .VDP_memset_loop	; Loop if not 0

	pop	DE
	pop	BC
	pop	AF
	ret

;
; VDP_load_config:
;	Load the VDP register configuration.
;
; Arguments:
;	None.
;
; Returns:
;	None.
;
; Clobbers:
;	None.
;
VDP_load_config:
	push	BC			; save BC
	push	HL			; save HL

	ld	HL, VDP_reg_r0		; HL <- address of table
	ld	B, 16			; B <- count
	ld	C, VDP_IO_MODE1		; C <- IO port
	otir				; Program VDP from table

	pop	HL
	pop	BC
	ret

;
; These are the example values for Graphics 2 in the 1984
;	"Video Display Processors Programmer's Guide".
;
.VDP_TXT_NTBA_DEFAULT:	equ	0x0800
.VDP_TXT_CTBA_DEFAULT:	equ	0x0000	; Don't care in Text mode
.VDP_TXT_PGBA_DEFAULT:	equ	0x0000
.VDP_TXT_SATBA_DEFAULT:	equ	0x0000	; Don't care in Text mode
.VDP_TXT_SPGBA_DEFAULT:	equ	0x0000	; Don't care in Text mode

;
; Shadow copies of VDP registers.  Note these are interleaved with
; the register indices they belong to that that VDP_load_config()
; can use an OTIR loop to write the config.  The values in code
; here represent the default values we want to boot up with (text mode,
; white-on-black characters).
;
; Even though each entry contains the register index for the VDP,
; keep them ordered because we use the register index as an index
; into this table, as well.
;
VDP_reg_r0:
	defb	0x00
	defb	0x80+VDP_R0
VDP_reg_r1:
	defb	VDP_R1_M1+VDP_R1_16K+VDP_R1_SCREEN
	defb	0x80+VDP_R1
VDP_reg_ntba:
	defb	.VDP_TXT_NTBA_DEFAULT >> 10
	defb	0x80+VDP_NTBA
VDP_reg_ctba:
	defb	.VDP_TXT_CTBA_DEFAULT >> 6
	defb	0x80+VDP_CTBA
VDP_reg_pgba:
	defb	.VDP_TXT_PGBA_DEFAULT >> 11
	defb	0x80+VDP_PGBA
VDP_reg_satba:
	defb	.VDP_TXT_SATBA_DEFAULT >> 7
	defb	0x80+VDP_SATBA
VDP_reg_spgba:
	defb	.VDP_TXT_SPGBA_DEFAULT >> 11
	defb	0x80+VDP_SPGBA
VDP_reg_textcolor:
	defb	(VDP_COLOR_WHITE << 4)+VDP_COLOR_LT_BLUE
	defb	0x80+VDP_TEXTCOLOR
;
; Base locations for the VDP tables in VRAM.  Again, these default
; to what we want in text mode.
;
VDP_Name_Table:
	defw	.VDP_TXT_NTBA_DEFAULT
VDP_Color_Table:
	defw	.VDP_TXT_CTBA_DEFAULT
VDP_Pattern_Table:
	defw	.VDP_TXT_PGBA_DEFAULT
VDP_Sprite_Attribute_Table:
	defw	.VDP_TXT_SATBA_DEFAULT
VDP_Sprite_Pattern_Table:
	defw	.VDP_TXT_SPGBA_DEFAULT

.VDP_rowaddrs:
	defw	.VDP_TXT_NTBA_DEFAULT +  0*40
	defw	.VDP_TXT_NTBA_DEFAULT +  1*40
	defw	.VDP_TXT_NTBA_DEFAULT +  2*40
	defw	.VDP_TXT_NTBA_DEFAULT +  3*40
	defw	.VDP_TXT_NTBA_DEFAULT +  4*40
	defw	.VDP_TXT_NTBA_DEFAULT +  5*40
	defw	.VDP_TXT_NTBA_DEFAULT +  6*40
	defw	.VDP_TXT_NTBA_DEFAULT +  7*40
	defw	.VDP_TXT_NTBA_DEFAULT +  8*40
	defw	.VDP_TXT_NTBA_DEFAULT +  9*40
	defw	.VDP_TXT_NTBA_DEFAULT + 10*40
	defw	.VDP_TXT_NTBA_DEFAULT + 11*40
	defw	.VDP_TXT_NTBA_DEFAULT + 12*40
	defw	.VDP_TXT_NTBA_DEFAULT + 13*40
	defw	.VDP_TXT_NTBA_DEFAULT + 14*40
	defw	.VDP_TXT_NTBA_DEFAULT + 15*40
	defw	.VDP_TXT_NTBA_DEFAULT + 16*40
	defw	.VDP_TXT_NTBA_DEFAULT + 17*40
	defw	.VDP_TXT_NTBA_DEFAULT + 18*40
	defw	.VDP_TXT_NTBA_DEFAULT + 19*40
	defw	.VDP_TXT_NTBA_DEFAULT + 20*40
	defw	.VDP_TXT_NTBA_DEFAULT + 21*40
	defw	.VDP_TXT_NTBA_DEFAULT + 22*40
	defw	.VDP_TXT_NTBA_DEFAULT + 23*40
