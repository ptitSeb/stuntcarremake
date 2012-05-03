	section	StuntCarRacer,code_c


;RECORD	equ	1
;RECORD_OPPONENT_RWP	equ	1
;RECORD_OPPONENT_AWH	equ	1
;RECORD_OPPONENT_ROS	equ	1
;RECORD_OPPONENT_GOEA	equ	1
;RECORD_OPPONENT_AOEA	equ	1
;RECORD_OPPONENT_UOZS	equ	1
;RECORD_OPPONENT_OM	equ	1
;RECORD_OPPONENT_OPI	equ	1
;RECORD_OPPONENT_MOTOS	equ	1
;RECORD_PLAYER_UER	equ	1


*!!! $400 ONWARDS POSSIBLY WRITTEN TO !!!
*!!! BUG CORRECTED IN calculate.road.wheel.heights !!!


;SELECTED.ROAD	equ	4
;I.WANT.TO.RACE	equ	1
;I.WANT.SUPER.LEAGUE	equ	1


MIN.FRAMES	equ	5		; originally 6
ROAD.WIDTH	equ	$180
WIDTH.REDUCTION	equ	65536/(ROAD.WIDTH-1)
REDUCTION	equ	238		(238 / 256)
CAR.WEIGHT	equ	317


ROAD.COLOURA	equ	1
ROAD.COLOURB	equ	2
ROAD.PIT.COLOUR	equ	0

START.LINE.COLOUR	equ	15

SIDES.COLOURA	equ	15

SIDES.COLOURB	equ	10
SUPER.SIDES.COLOURB	equ	8

SIDE.LINES.COLOUR	equ	9
SUPER.SIDE.LINES.COLOUR	equ	0

SKY.COLOUR	equ	7
GROUND.COLOUR	equ	13

SLAVE	equ	$40
MASTER	equ	$80


* HELP during menu selection to quit
* F1 during season to end that season

	move.l	4.w,a6
	jsr	-132(a6)		Forbid

	moveq	#0,d0
	lea	graf.name(pc),a1
	jsr	-552(a6)		OpenLibrary
	move.l	d0,gfxbase
	beq	exit_now


*"""""""""""""""""""""""""
*" INITIALISE INTERRUPTS "
*"			 "
*"""""""""""""""""""""""""

	lea	custom,a6
	move.w	intenar(a6),old.ints	save system interrupt status

	move.w	#$7fff,intena(a6)	disable all interrupts

	move.l	$64.w,old.level1
	move.l	$68.w,old.level2
	move.l	$6c.w,old.level3
	move.l	$70.w,old.level4
	move.l	$74.w,old.level5
	move.l	$78.w,old.level6
	move.l	$7c.w,old.level7
	move.l	#new.level1,$64.w
	move.l	#new.level2,$68.w
	move.l	#new.level3,$6c.w
	move.l	#new.level4,$70.w
	move.l	#new.level5,$74.w
	move.l	#new.level6,$78.w
	move.l	#new.level7,$7c.w

	move.w	#$e839,intena(a6)	enable copper and vertb interrupt


*"""""""""""""""""""""""""""""
*" INITIALISE SCREEN DISPLAY "
*"			     "
*"""""""""""""""""""""""""""""

	move.w	#$07ff,dmacon(a6)	DMA off

	move.w	#$4200,bplcon0(a6)	initialise screen
	move.w	#$3c81,diwstrt(a6)
	move.w	#$04c1,diwstop(a6)
	move.w	#$38,ddfstrt(a6)
	move.w	#$d0,ddfstop(a6)
	move.w	#0,bplcon1(a6)
	move.w	#%100100,bplcon2(a6)
	moveq	#0,d0
	move.w	d0,bpl1mod(a6)
	move.w	d0,bpl2mod(a6)

	move.l	#screen1.space,visible.screen
	jsr	set.copper.list		initialise copper
	jsr	set.blank.sprites

	move.l	#copper.list,cop1lch(a6)
	move.w	d0,copjmp1(a6)

	move.w	#$8380,dmacon(a6)	DMA on
	move.w	#$00ff,adkcon(a6)


*"""""""""""""""""""""
*" CALL MAIN PROGRAM "
*"		     "
*"""""""""""""""""""""

	jsr	set.CIAs
	moveq	#0,d1
	moveq	#0,d2
	jsr	main.game.selection


*""""""""""""""""
*" EXIT ROUTINE	"
*"		"
*""""""""""""""""

	lea	custom,a6
	move.w	#$7fff,intena(a6)	disable all interrupts

	move.l	old.level1(pc),$64.w
	move.l	old.level2(pc),$68.w
	move.l	old.level3(pc),$6c.w
	move.l	old.level4(pc),$70.w
	move.l	old.level5(pc),$74.w
	move.l	old.level6(pc),$78.w
	move.l	old.level7(pc),$7c.w

	move.w	old.ints(pc),d0
	or.w	#$c000,d0		set SET and INTEN bits
	move.w	d0,intena(a6)		restore system interrupt status

	move.w	#$07ff,dmacon(a6)	DMA off

	move.l	gfxbase(pc),a1
	move.l	38(a1),cop1lch(a6)	restore system copper

	move.w	#$87f0,dmacon(a6)	DMA on

	move.l	4.w,a6
	jsr	-414(a6)		CloseLibrary

exit_now
	jsr	-138(a6)		Permit

	IFD	RECORD
	bsr	store.recording
	ENDC

	moveq	#0,d0
	rts


	IFD	RECORD
store.recording

* Open the DOS library

	moveq	#0,d0
	lea	dosname(pc),a1
	move.l	4.w,a6
	jsr	-552(a6)		OpenLibrary
	move.l	d0,DOSBase
	beq	exit_now2

* Open output file

	move.l	#OutputFilename,d1
	move.l	#1006,d2		MODE_NEWFILE
	move.l	DOSBase(pc),a6
	jsr	-30(a6)			Open
	move.l	d0,OutputHandle
	beq	exit_closedos

* Write to output file

	move.l	OutputHandle(pc),d1
	move.l	#recording.buffer,d2
	move.l	recording.ptr,d3
	sub.l	d2,d3
	move.l	DOSBase(pc),a6
	jsr	-48(a6)			Write
;	tst.l	d0
;	bmi	error

* Close output file

exit_closeoutput
	move.l	OutputHandle(pc),d1
	move.l	DOSBase(pc),a6
	jsr	-36(a6)			Close

* Close the DOS library

exit_closedos
	move.l	DOSBase(pc),a1
	move.l	4.w,a6
	jsr	-414(a6)		CloseLibrary

exit_now2
	rts

dosname	dc.b	'dos.library',0
	even

DOSBase	dc.l	0

OutputHandle	dc.l	0
OutputFilename	dc.b	'SCRecording.bin'
	even
	ENDC


*""""""""""""""""""""""
*" WORD PRINT ROUTINE "
*"		      "
*""""""""""""""""""""""

word.print
	move.b	#16,word.print.column
	move.b	#18,word.print.row
	move.w	the.word1(pc),the.word
	bsr.s	word.print.now

	move.b	#21,word.print.column
	move.b	#18,word.print.row
	move.w	the.word2(pc),the.word
	bsr.s	word.print.now

	move.b	#26,word.print.column
	move.b	#18,word.print.row
	move.w	the.word3(pc),the.word

word.print.now
	move.b	#31,d0
	jsr	print.character
	move.b	word.print.column(pc),d0
	jsr	print.character
	move.b	word.print.row(pc),d0
	jsr	print.character

	move.b	#0,print.fine.x
	move.b	#0,print.fine.y

	move.b	the.word,d0
	lsr.b	#4,d0
	bsr.s	print.hex.digit

	move.b	the.word,d0
	andi.b	#$f,d0
	bsr.s	print.hex.digit

	move.b	the.word+1,d0
	lsr.b	#4,d0
	bsr.s	print.hex.digit

	move.b	the.word+1,d0
	andi.b	#$f,d0

print.hex.digit
	andi.w	#$f,d0
	move.b	hex.digits(pc,d0.w),d0
	jmp	print.character

hex.digits	dc.b	'0123456789ABCDEF'

word.print.column	dc.b	0
word.print.row	dc.b	0

the.word1	dc.w	0
the.word2	dc.w	0
the.word3	dc.w	0

the.word	dc.w	0


*"""""""""""""
*" VARIABLES "
*"	     "
*"""""""""""""

gfxbase	dc.l	0
old.ints	dc.w	0
old.level1	dc.l	0
old.level2	dc.l	0
old.level3	dc.l	0
old.level4	dc.l	0
old.level5	dc.l	0
old.level6	dc.l	0
old.level7	dc.l	0


*"""""""""""""
*" CONSTANTS "
*"	     "
*"""""""""""""

graf.name	dc.b	'graphics.library',0
	even


*"""""""""""""""""""
*" STUNT CAR RACER "
*"		   "
*"""""""""""""""""""

edge.space
	ds.w	4500
end.edge.space
	ds.w	500


****************************************


cbits	incbin	graphics_data/cbits.bin


****************************************


R.e700	move.l	#R.e730,a0
	move.l	#$63ba8,d3
	clr.l	d0

.add	add.w	(a0)+,d0
	subq.l	#2,d3
	bne	.add

	move.w	#22580,d0
	bra	R.e726

	move.b	#$80,DAT.e72a

R.e726	bra	R.e730

DAT.e72a
	dc.w	0,$7a1,0

R.e730	move.l	#R.e73c,$80
	trap	#0

R.e73c	move.l	#stack,sp
	jsr	initialise.machine
	jmp	R.1ba08


*"""""""""""""""""""
*" THE COPPER LIST "
*"		   "
*"""""""""""""""""""

copper.list
	dc.w	bpl1pth,7
	dc.w	bpl1ptl,$2294
	dc.w	bpl2pth,7
	dc.w	bpl2ptl,$41d4
	dc.w	bpl3pth,7
	dc.w	bpl3ptl,$6114
	dc.w	bpl4pth,7
	dc.w	bpl4ptl,$8054

colour0	dc.w	$180,0
	dc.w	$182,0
	dc.w	$184,0
	dc.w	$186,0
	dc.w	$188,0
	dc.w	$18a,0
	dc.w	$18c,0
	dc.w	$18e,0
	dc.w	$190,0
	dc.w	$192,0
	dc.w	$194,0
	dc.w	$196,0
	dc.w	$198,0
	dc.w	$19a,0
	dc.w	$19c,0
	dc.w	$19e,0

colour16
	dc.w	$1a0,0
	dc.w	$1a2,0
	dc.w	$1a4,$fff
	dc.w	$1a6,$c88
	dc.w	$1a8,0
	dc.w	$1aa,0
	dc.w	$1ac,$fff
	dc.w	$1ae,$c88
	dc.w	$1b0,0
	dc.w	$1b2,0
	dc.w	$1b4,0
	dc.w	$1b6,0
	dc.w	$1b8,0
	dc.w	$1ba,0
	dc.w	$1bc,0
	dc.w	$1be,0

sprite0	dc.w	spr0pth,0
	dc.w	spr0ptl,$f4b4
	dc.w	spr1pth,0
	dc.w	spr1ptl,$f4b4
	dc.w	spr2pth,0
	dc.w	spr2ptl,$f4b4
	dc.w	spr3pth,0
	dc.w	spr3ptl,$f4b4
	dc.w	spr4pth,0
	dc.w	spr4ptl,$f4b4
	dc.w	spr5pth,0
	dc.w	spr5ptl,$f4b4
	dc.w	spr6pth,0
	dc.w	spr6ptl,$f4b4
	dc.w	spr7pth,0
	dc.w	spr7ptl,$f4b4

	dc.w	$fa01,$ff00
	dc.w	intreq,$8010
	dc.w	$ffff,$fffe


st.colours
	ds.w	16
st.dest.colours
	ds.w	16


	ds.w	300
stack	dc.l	0


key.array	ds.w	64


receive.data	ds.w	128
transmit.data	ds.w	128


****************************************


initialise.machine
	move.w	#$2700,sr

	move.w	#$7fff,intena+custom
	move.w	#$7fff,intreq+custom
	move.w	#$e839,intena+custom
	move.w	#$7cdf,dmacon+custom

	move.l	#new.level1,$64
	move.l	#new.level2,$68
	move.l	#new.level3,$6c
	move.l	#new.level4,$70
	move.l	#new.level5,$74
	move.l	#new.level6,$78
	move.l	#new.level7,$7c

	move.w	#$2000,sr

	move.l	#screen1.space,d0
	move.l	d0,screen.mem
	move.l	d0,screen2
	addi.l	#32000,d0
	move.l	d0,screen1

	jsr	set.current.scene
	jsr	set.blank.sprites
	jsr	set.sprite.colours

	move.w	#$4200,bplcon0+custom
	move.w	#$3c81,diwstrt+custom
	move.w	#$04c1,diwstop+custom
	move.w	#$3c,hardware.start
	move.w	#$38,ddfstrt+custom
	move.w	#$d0,ddfstop+custom
	move.w	#0,bpl1mod+custom
	move.w	#0,bpl2mod+custom
	move.w	#0,bplcon1+custom
	move.w	#%100100,bplcon2+custom

	move.l	#copper.list,a0
	move.l	a0,cop1lch+custom
	move.w	copjmp1+custom,d0
	move.w	#$8380,dmacon+custom
	jsr	set.CIAs

	move.l	#chime,a0
	move.l	#engine.pitch2,a2
.eor	eori.b	#$80,(a0)+
	cmp.l	a2,a0
	blt	.eor

	move.w	#$00ff,adkcon+custom
	jsr	make.engine.samples
	rts


****************************************


set.CIAs
	lea	CIAA,a0
	move.b	#%00001000,CRA(a0)
	move.b	#%00001000,CRB(a0)
	move.b	#%01110101,ICR(a0)
	move.b	#%10001010,ICR(a0)	allow SP and Timer B interrupts

	lea	CIAB,a0
	move.b	#%00001000,CRA(a0)
	move.b	#%00001000,CRB(a0)
	move.b	#%01111101,ICR(a0)	allow Timer B interrupts
	move.b	#%10000010,ICR(a0)
	rts


*"""""""""""""""""""""
*" LEVEL 1 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level1
	btst	#0,intreqr+1+custom
	beq	not.tbe
	jsr	transmit.serial
	move.w	#1,intreq+custom
	rte

not.tbe	btst	#1,intreqr+1+custom
	beq	not.dskblk
	jsr	dummy.handle.dskblk
	move.w	#2,intreq+custom
	rte

not.dskblk
	move.w	#4,intreq+custom
	rte


*"""""""""""""""""""""
*" LEVEL 2 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level2
	jsr	handle.CIAA
	move.w	#8,intreq+custom
	rte


*"""""""""""""""""""""
*" LEVEL 3 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level3
	btst	#4,intreqr+1+custom
	beq	test.vertb
	jsr	copper.interrupt
	move.w	#$10,intreq+custom

test.vertb
	btst	#5,intreqr+1+custom
	beq	end.level3
	jsr	vertb.interrupt
	move.w	#$20,intreq+custom
	rte

end.level3
	move.w	#$40,intreq+custom
	rte


*"""""""""""""""""""""
*" LEVEL 4 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level4
	btst	#7,intreqr+1+custom
	beq	test.aud1
	jsr	aud0.interrupt
	move.w	#$80,intreq+custom

test.aud1
	btst	#0,intreqr+custom
	beq	test.aud2
	jsr	aud1.interrupt
	move.w	#$100,intreq+custom

test.aud2
	btst	#1,intreqr+custom
	beq	test.aud3
	jsr	aud2.interrupt
	move.w	#$200,intreq+custom

test.aud3
	btst	#2,intreqr+custom
	beq	end.level4
	jsr	aud3.interrupt
	move.w	#$400,intreq+custom

end.level4
	rte


*"""""""""""""""""""""
*" LEVEL 5 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level5
	btst	#3,intreqr+custom
	beq	not.rbf
	jsr	receive.serial
	move.w	#$800,intreq+custom
	rte

not.rbf	jsr	dummy.handle.dsksyn
	move.w	#$1000,intreq+custom
	rte


*"""""""""""""""""""""
*" LEVEL 6 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level6
	jsr	handle.CIAB
	move.w	#$2000,intreq+custom
	rte


*"""""""""""""""""""""
*" LEVEL 7 INTERRUPT "
*"		     "
*"""""""""""""""""""""

new.level7
	rte


****************************************


handle.CIAA
	movem.l	d0/a0/a3,-(sp)
	lea	CIAA,a3
	move.b	ICR(a3),d0
	bpl	end.handle.CIAA		if IR not set

	btst	#1,d0			TB
	beq	test.SP
	clr.b	CIAA.timer.B.countdown

test.SP	btst	#3,d0			SP
	beq	end.handle.CIAA

	move.l	#key.array,a0
	clr.w	d0
	move.b	KEY(a3),d0
	ror.b	#1,d0
	eori.b	#$ff,d0
	cmpi.b	#$f0,d0
	bcc	handshake

	tst.b	d0
	bpl	key.pressed

key.released
	andi.b	#$7f,d0
	move.b	#0,(a0,d0.w)
	bra	handshake

key.pressed
	move.b	#$b3,(a0,d0.w)

handshake
	jsr	start.handshake

end.handle.CIAA
	movem.l	(sp)+,d0/a0/a3
	rts


****************************************


start.handshake
	tst.b	CIAB.timer.B.countdown
	bne	timer.running

	move.b	#$80,CIAB.timer.B.countdown

	lea	CIAA,a0
	bset	#6,CRA(a0)		set SP to output

	lea	CIAB,a0
	move.b	#%00001000,CRB(a0)
	move.b	#%10000010,ICR(a0)
	move.b	#176,TBLO(a0)		245us
	move.b	#0,TBHI(a0)
timer.running
	rts


****************************************


CIAB.timer.B.countdown
	dc.b	0,0


****************************************


handle.CIAB
	movem.l	d0/a0,-(sp)
	lea	CIAB,a0
	move.b	ICR(a0),d0
	bpl	end.handle.CIAB		if IR not set

	btst	#1,d0			TB
	beq	end.handle.CIAB

end.handshake
	lea	CIAA,a0
	bclr	#6,CRA(a0)		set SP back to input
	clr.b	CIAB.timer.B.countdown

end.handle.CIAB
	movem.l	(sp)+,d0/a0
	rts


****************************************


vertb.interrupt
	movem.l	d0-d7/a0-a6,-(sp)
	clr.w	d1
	clr.w	d2
	jsr	frames.wheels.engine
	btst	#5,serdatr+custom
	beq	transmit.buffer.not.empty

	move.b	transmit.byte.queue.end,d0
	cmp.b	next.transmit.byte,d0
	beq	transmit.buffer.not.empty
	jsr	transmit.serial

transmit.buffer.not.empty
****************************************
;	btst	#6,CIAA
;	bne.s	not.quit
;	move.b	#$b3,key.array+$45
;
;not.quit
;	btst	#2,potgor+custom
;	bne.s	not.pause
;
;	tst.b	release.wait
;	bne.s	pause.done
;
;	st	release.wait
;
;	cmpi.b	#$b3,key.array+$19
;	beq.s	unpauses
;
;pauses	move.b	#0,key.array+$18
;	move.b	#$b3,key.array+$19
;	bra.s	pause.done
;
;unpauses
;	move.b	#$b3,key.array+$18
;	move.b	#0,key.array+$19
;	bra.s	pause.done
;
;release.wait	dc.w	0
;
;not.pause
;	sf	release.wait
;
;pause.done
****************************************
	movem.l	(sp)+,d0-d7/a0-a6
	rts


copper.interrupt
	tst.b	show.new.screen
	beq	ci2

	movem.l	d0-d7/a0-a6,-(sp)
	jsr	set.copper.list
	clr.b	show.new.screen

	tst.b	adjust.sprites
	beq	ci1

	jsr	update.sprites
	clr.b	adjust.sprites
ci1	movem.l	(sp)+,d0-d7/a0-a6
ci2	rts


****************************************


transmit.serial
	tst.b	transmit.busy
	bpl	set.transmit.busy

* Following value needed to count times that a level1 TBE interrupt
* occured whilst transmitting from a non-interrupt routine.

	addq.w	#1,transmit.times.busy
	rts

set.transmit.busy
	move.b	#$80,transmit.busy

transmit.test.empty
	btst	#5,serdatr+custom
	beq	transmit.buffer.not.empty2

	movem.l	d0/d3/a0,-(sp)
	move.w	#16-1,d3
.delay	dbra	d3,.delay

	clr.w	d3
	move.b	next.transmit.byte,d3
	cmp.b	transmit.byte.queue.end,d3
	beq	no.more.transmit.bytes

	move.l	#transmit.data,a0
	move.b	(a0,d3.w),d0		get next byte to transmit
	addq.b	#1,next.transmit.byte
	andi.w	#$ff,d0
	move.w	#8-1,d3
	bset	#8,d0			even parity

set.parity
	ror.b	#1,d0
	bcc	.bit.clear
	bchg	#8,d0
.bit.clear
	dbra	d3,set.parity

	bset	#9,d0			set stop bit
	move.w	d0,serdat+custom	send serial data

no.more.transmit.bytes
	movem.l	(sp)+,d0/d3/a0

transmit.buffer.not.empty2
	clr.b	transmit.busy
	tst.w	transmit.times.busy
	beq	transmit.end

	subq.w	#1,transmit.times.busy
	bra	transmit.test.empty

transmit.end
	rts


****************************************


receive.serial
	movem.l	d0/d3/a0,-(sp)
	move.w	serdatr+custom,d0
	move.w	#8-1,d3

check.parity
	ror.b	#1,d0
	bcc	.bit.clear
	bchg	#8,d0
.bit.clear
	dbra	d3,check.parity

	btst	#8,d0
	beq	receive.end		if parity check failed

	clr.w	d3
	move.b	next.receive.byte,d3
	addq.b	#1,d3
	cmp.b	receive.byte.queue.end,d3
	beq	receive.end		if no more bytes to receive

	subq.b	#1,d3
	move.l	#receive.data,a0
	move.b	d0,(a0,d3.w)
	addi.b	#1,next.receive.byte

receive.end
	movem.l	(sp)+,d0/d3/a0
	rts


****************************************


initialise.serial
	clr.l	next.receive.byte	clear four values below
	move.w	#$8174,serper+custom	set 9 data bits, 9600 baud
	lea	CIAB,a0
	ori.b	#$40,$200(a0)
	andi.b	#$bf,$000(a0)		clear RTS signal
	rts


****************************************


next.receive.byte	dc.b	0
receive.byte.queue.end	dc.b	0
transmit.byte.queue.end	dc.b	0
next.transmit.byte	dc.b	0

transmit.busy	dc.b	0,0
transmit.times.busy	dc.w	0


****************************************


compare.received.bytes
	move.b	next.receive.byte,d0
	cmp.b	receive.byte.queue.end,d0
	rts


****************************************


get.next.received.byte
	move.l	#receive.data,a0
	clr.w	d1

wait.receive
	move.b	receive.byte.queue.end,d1
	cmp.b	next.receive.byte,d1
	beq	wait.receive

	move.b	(a0,d1.w),d0
	addq.b	#1,receive.byte.queue.end
	rts


****************************************


transmit.byte.when.ready
	move.l	#transmit.data,a0
	clr.w	d1
	move.b	transmit.byte.queue.end,d1
	addq.b	#1,d1
	cmp.b	next.transmit.byte,d1
	beq	transmit.byte.when.ready

	subq.b	#1,d1
	move.b	d0,(a0,d1.w)
	addq.b	#1,transmit.byte.queue.end

	btst	#5,serdatr+custom
	beq	transmit.buffer.not.empty3
	jsr	transmit.serial

transmit.buffer.not.empty3
	rts


****************************************


dummy.handle.dsksyn
	rts


dummy.handle.dskblk
	rts


****************************************


aud0.interrupt
	move.w	engine.period,aud0per+custom
	rts

aud1.interrupt
	movem.l	d0/a0,-(sp)
	move.w	#4,d0
	bra	aud.interrupt

aud2.interrupt
	movem.l	d0/a0,-(sp)
	move.w	#8,d0
	bra	aud.interrupt

aud3.interrupt
	movem.l	d0/a0,-(sp)
	move.w	#12,d0

aud.interrupt
	lea	channel.bits,a0
	lea	(a0,d0.w),a0
	move.w	dmaconr+custom,d0
	and.w	2(a0),d0
	bne	ai2

	move.w	2(a0),d0
	and.w	channel.to.activate,d0
	bne	ai3

	move.w	2(a0),d0
	asl.w	#7,d0
	move.w	d0,intena+custom
	bra	ai3

ai2	addq.w	#1,(a0)
	cmpi.w	#2,(a0)
	blt	ai3

	move.w	2(a0),d0
	move.w	d0,dmacon+custom
	asl.w	#7,d0
	move.w	d0,intena+custom

ai3	movem.l	(sp)+,d0/a0
	rts


****************************************


channel.bits
	dc.w	0,1
	dc.w	0,2
	dc.w	0,4
	dc.w	0,8

effect	dc.b	0,0

sound.effect
	movem.l	d0/d3-d4/a0-a1,-(sp)
	andi.w	#7,d0
	asl.w	#4,d0
	lea	effect.table,a0
	lea	(a0,d0.w),a0
	move.w	12(a0),d0
	asl.w	#2,d0
	lea	channel.bits,a1
	move.w	2(a1,d0.w),d3
	move.w	d3,d4
	asl.w	#7,d4
	move.w	d4,intena+custom
	move.w	d3,dmacon+custom
	move.w	#0,(a1,d0.w)
	asl.w	#2,d0
	lea	custom,a1
	lea	(a1,d0.w),a1
	move.l	(a0),aud0lch(a1)
	move.l	4(a0),d0
	lsr.l	#1,d0
	move.w	d0,aud0len(a1)
	move.w	10(a0),aud0vol(a1)
	move.w	8(a0),aud0per(a1)
	move.w	d3,channel.to.activate
	bset	#15,d3
	move.w	d4,intreq+custom
	bset	#15,d4
	move.w	d4,intena+custom	interrupt generated now

	move.w	d3,dmacon+custom
	clr.w	channel.to.activate

	movem.l	(sp)+,d0/d3-d4/a0-a1
	rts


channel.to.activate	dc.w	0


****************************************


sound.off
	move.w	#$f,dmacon+custom
	move.w	#$780,intena+custom
	rts


****************************************


make.engine.samples
	move.l	#3172,d6		tick.over length in bytes
	move.l	#engine.pitch2,a1
	move.l	#tick.over,a2
	move.l	#7-1,d5			make seven higher pitched samples

	move.l	#engine.pitch.table,a5
	move.l	#tick.over,(a5)+
	lsr.l	#1,d6
	move.l	d6,(a5)+		save word length of tick.over
	asl.l	#1,d6

next.sample.up
	move.l	a2,a0			current source sample
	move.l	a1,a2			current destination sample
	move.l	a1,(a5)+		save sample pointer
	lsr.w	#1,d6
	move.w	d6,d0
	subq.w	#1,d0

copy.alternate.samples
	move.b	(a0)+,(a1)+
	add.l	#1,a0
	dbra	d0,copy.alternate.samples

	move.l	a1,d0
	bclr	#0,d0
	move.l	d0,a1
	sub.l	-4(a5),d0
	lsr.l	#1,d0
	move.l	d0,(a5)+		save word length of sample
	dbra	d5,next.sample.up

	move.l	engine.pitch.table,effect.table+7*16
	move.l	engine.pitch.table+4,d0
	asl.l	#1,d0
	move.l	d0,effect.table+7*16+4
	rts


****************************************


engine.period	dc.w	198


engine.pitch.table
*	address, length (in words)

	dc.l	tick.over,1586
	dc.l	engine.pitch2,793
	dc.l	engine.pitch3,396
	dc.l	engine.pitch4,198
	dc.l	engine.pitch5,99
	dc.l	engine.pitch6,49
	dc.l	engine.pitch7,24
	dc.l	engine.pitch8,12


blank.sprite.data
	dc.l	0


chime	incbin	sound_data/chime.bin
wreck	incbin	sound_data/wreck.bin
hit.car	incbin	sound_data/hit.car.bin
grounded	incbin	sound_data/grounded.bin
creak	incbin	sound_data/creak.bin
smash	incbin	sound_data/smash.bin
off.road	incbin	sound_data/off.road.bin
tick.over	incbin	sound_data/tick.over.bin
engine.pitch2	incbin	sound_data/engine.pitch2.bin
engine.pitch3	incbin	sound_data/engine.pitch3.bin
engine.pitch4	incbin	sound_data/engine.pitch4.bin
engine.pitch5	incbin	sound_data/engine.pitch5.bin
engine.pitch6	incbin	sound_data/engine.pitch6.bin
engine.pitch7	incbin	sound_data/engine.pitch7.bin
engine.pitch8	incbin	sound_data/engine.pitch8.bin

	ds.w	29

effect.table
*	address, length (in bytes)
*	period, volume, channel no.

	dc.l	chime,2436	; This sound effect is only used when defining keys (press F1 while games paused)
	dc.w	150,30,1,0

	dc.l	wreck,9032
	dc.w	180,64,1,0

	dc.l	hit.car,8014
	dc.w	238,56,1,0

	dc.l	grounded,3108
	dc.w	400,50,1,0

	dc.l	creak,5170
	dc.w	238,64,2,0

	dc.l	smash,8430
	dc.w	280,64,3,0

	dc.l	off.road,7120
	dc.w	500,64,1,0

	dc.l	tick.over,3172
	dc.w	300,48,0,0


****************************************


read.joystick
	movem.l	d3-d4/a0,-(sp)
	clr.b	d4
	move.w	joy1dat+custom,d0
	move.w	d0,d3
	lsr.w	#1,d3
	eor.w	d0,d3
	btst	#8,d3
	beq	not.forward1
	bset	#0,d4
not.forward1
	btst	#0,d3
	beq	not.back1
	bset	#1,d4
not.back1
	btst	#9,d0
	beq	not.left1
	bset	#2,d4
not.left1
	btst	#1,d0
	beq	not.right1
	bset	#3,d4
not.right1
	lea	CIAA,a0
	andi.b	#$7f,$200(a0)
	btst	#7,$000(a0)
	bne	not.fire1
	bset	#4,d4
not.fire1
	eori.b	#$ff,d4
	move.b	d4,joystick.state
	movem.l	(sp)+,d3-d4/a0
	rts


****************************************


set.current.scene
	move.l	screen2,d3
	addi.l	#16*40+4,d3
	move.l	d3,current.scene
	move.l	screen1,visible.screen
	move.b	#$80,show.new.screen
	rts


****************************************


set.copper.list
	movem.l	d3-d4,-(sp)
	move.l	visible.screen,d0
	move.l	#copper.list,a0
	move.w	#4-1,d4

.loop	move.l	d0,d3
	swap	d3
	move.w	d3,2(a0)
	move.w	d0,6(a0)
	add.l	#8,a0
	addi.l	#8000,d0
	dbra	d4,.loop
	movem.l	(sp)+,d3-d4
	rts


visible.screen	dc.l	screen2.space
show.new.screen	dc.b	0,0


R.1b818	move.l	#$1800,d0
.wait	subi.l	#1,d0
	bne	.wait
	rts


R.1b82a	move.b	or.with.screen,d0
	move.w	d0,-(sp)
	move.w	print.column,-(sp)
	move.l	screen2,-(sp)
	move.l	screen1,screen2
	move.w	d1,-(sp)
	move.b	#0,or.with.screen
	move.b	#1,d0
	jsr	set.text.masks
	move.b	#3,d0
	jsr	set.bground.masks
	move.w	#208,d1
	jsr	R.625a8
	move.w	(sp)+,d1
	jsr	R.625a8
	move.l	(sp)+,screen2
	move.w	(sp)+,print.column
	move.w	(sp)+,d0
	move.b	d0,or.with.screen
	rts


joystick.state	dc.w	-1


lower.case.ptr	dc.l	lower.case.letters
upper.case.ptr	dc.l	upper.case.letters

upper.case.letters
 dc.b	0,'1234567890',0,0,0,0,'0'
 dc.b	'QWERTYUIOP',0,0,0,'123'
 dc.b	'ASDFGHJKL:',0,0,0,'456'
 dc.b	0,'ZXCVBNM,./',0,'.789'
 dc.b	' ',8,0,13,13,0
 ds.b	114

lower.case.letters
 dc.b	0,'1234567890',0,0,0,0,'0'
 dc.b	'qwertyuiop',0,0,0,'123'
 dc.b	'asdfghjkl:',0,0,0,'456'
 dc.b	0,'zxcvbnm,./',0,'.789'
 dc.b	' ',8,0,13,13,0
 ds.b	114


R.1ba08	clr.l	d1
	clr.l	d2
	move.l	#key.array,a0
	move.w	#127,d1

.label1	move.b	#0,(a0,d1.w)
	subq.b	#1,d1
	bpl	.label1
	move.l	#TAB.7a01a,a0

.label2	move.b	#0,(a0)+
	cmp.l	#section.data+412*4,a0
	blt	.label2

	tst.b	DAT.e72a
	beq	.label5

	move.w	#$ff0,d0
	move.l	#colour0+2,a0
	move.w	#32-1,d3
.label3	move.w	d0,(a0)
	add.l	#4,a0
	dbra	d3,.label3

.label4	tst.b	DAT.e72a
	bmi	.label4

.label5	jsr	R.69cfc
	jmp	R.5c890


copy.st.dest.colours
	move.l	#st.dest.colours,a0
	move.w	#16-1,d0
.copy	move.w	(a1)+,(a0)+
	dbra	d0,.copy
	rts


set.amiga.colours
	move.l	#st.colours,a1
	move.l	#colour0+2,a0
	move.w	#16-1,d4

set.blue
	move.w	(a1)+,d3
	asl.w	#1,d3

	move.b	d3,d0
	andi.b	#$f,d0
	beq	set.green
	ori.b	#1,d3

set.green
	move.b	d3,d0
	andi.b	#$f0,d0
	beq	set.red
	ori.b	#$10,d3

set.red	move.w	d3,d0
	andi.w	#$f00,d0
	beq	set.copper.colour
	ori.w	#$100,d3

set.copper.colour
	move.w	d3,(a0)+
	add.l	#2,a0
	dbra	d4,set.blue
	rts


make.car.screens
	move.l	screen.mem,a1
	move.l	#car.crunched,a0
	jsr	decrunch
	move.l	screen.mem,a0
	move.l	a0,a1
	add.w	#32000,a1
	move.w	#32000-1,d3
.loop	move.b	(a0)+,(a1)+
	dbra	d3,.loop
	rts


W.1baf8	dc.w	0
engine.power	dc.w	0
opponents.engine.power	dc.w	0
boost.unit.value	dc.b	0,0
	dc.b	0
road.cushion.value	dc.b	0
	dc.b	0,0

players.map.x	dc.b	0,0
players.map.z	dc.b	0
players.fine.map.x	dc.b	0,0
players.fine.map.z	dc.b	0
players.distance.into.section	dc.w	0		; player's centre (after adjustment for opposite direction)
opponents.distance.into.section	dc.w	0		; opponent's centre
players.distance.into.section.plus64	dc.w	0		; player's front
normal.distance.into.section	dc.w	0		; player's centre (before adjustment for opposite direction)

opponents.distance.into.section.minus64	dc.w	0		; opponent's rear
	dc.w	0
B.1bb16	dc.b	0
thousands	dc.b	0

acceleration.adjust
road.height	dc.w	0	; actually a longword, but bytes have more than 1 use
factor1	dc.b	0
value
product
	dc.b	0

players.road.section	dc.b	0
opponents.road.section	dc.b	0
B.1bb1e	dc.b	0,0
players.lap	dc.b	0
opponents.lap	dc.b	0

road.near.x.offset	dc.b	0
road.finest.x.offset	dc.b	0
	dc.w	0

road.near.z.offset	dc.b	0
road.finest.z.offset	dc.b	0
	dc.w	0

opp.zdiff	dc.b	0
inclination.sin	dc.b	0

opp.xdiff
surface.cosx	dc.b	0	; locations have more than 1 use
inclination.cos	dc.b	0

road.finer.x.offset	dc.b	0,0
	dc.w	0
road.finer.z.offset	dc.b	0,0
previous.left.top.y	dc.w	0
previous.right.top.y	dc.w	0
daft.flag	dc.b	0,0
	dc.w	0
byte.count	dc.b	0
boost.unit	dc.b	0
	dc.b	0
B.1bb3f	dc.b	0
opponents.road.section.m64	dc.w	0
	dc.b	0
opponents.x.span	dc.b	0
opp.touching.road	dc.b	0
opponents.required.z.speed.reached	dc.b	0
cars.collided	dc.b	0
players.input	dc.b	0
prompt.chars	dc.b	0,0
opponents.required.z.speed	dc.b	0,0
	dc.b	0
near.section.byte1	dc.b	0
	dc.b	0

front.left.damage	dc.b	0
front.right.damage	dc.b	0
rear.damage	dc.b	0

	dc.w	0
damaged	dc.b	0
B.1bb55	dc.b	0
damaged.count	dc.b	0
B.1bb57	dc.b	0
near.sections.done	dc.b	0
offset.for.after.last.coord	dc.b	0
offset.for.last.two.coords	dc.b	0
B.1bb5b	dc.b	0
B.1bb5c	dc.b	0
left.hand.bend	dc.b	0
B.1bb5e	dc.b	0
B.1bb5f	dc.b	0
offset.for.coord.pair.to.start.at	dc.b	0
section.flags2	dc.b	0
boost.activated	dc.b	0
turn.engine.off	dc.b	0
B.1bb64	dc.b	0
wheel.off.road	dc.b	0
use.lines.colour	dc.b	0
opponent.reached	dc.b	0
unused.flag	dc.b	0
B.1bb69	dc.b	0
number.of.segments	dc.b	0
B.1bb6b	dc.b	0
B.1bb6c	dc.b	0
print.fine.x	dc.b	0
print.fine.y	dc.b	0
B.1bb6f	dc.b	0
boost.flag	dc.b	0
mdb_first_time	dc.b	0
B.1bb72	dc.b	0
smashed.countdown	dc.b	0
B.1bb74	dc.b	0
B.1bb75	dc.b	0
B.1bb76	dc.b	0
standard.clip.flag	dc.b	0
	dc.b	0
y.coords.stored.as.words	dc.b	0
current.y.coord	dc.b	0
road.width.reduction	dc.b	0
opponents.coord	dc.b	0
grounded.count	dc.b	0
touching.road	dc.b	0
pits.are.black	dc.b	0
	dc.w	0
	dc.w	0
	dc.b	0
current.road.section	dc.b	0
near.section.piece	dc.b	0,0
white.prompts	dc.b	0
B.1bb89	dc.b	0
	dc.b	0
B.1bb8b	dc.b	0
B.1bb8c	dc.b	0
B.1bb8d	dc.b	0
prompt.required	dc.b	0
track.preview	dc.b	0
copy.prompt.groups	dc.b	0
piece.coords.offset	dc.b	0
B.1bb92	dc.b	0
B.1bb93	dc.b	0
B.1bb94	dc.b	0
boost.max.units	dc.b	0
	dc.b	0
number.of.coords	dc.b	0
number.of.coords.minus2	dc.b	0
lap.that.finishes.race	dc.b	0
at.side.byte	dc.b	0
B.1bb9b	dc.b	0
off.map.status	dc.b	0
B.1bb9d	dc.b	0
B.1bb9e	dc.b	0
B.1bb9f	dc.b	0
	dc.b	0
rear.wheel.surface.x.position	dc.b	0
	dc.b	0
surface.start.coord	dc.b	0
B.1bba4	dc.b	0
B.1bba5	dc.b	0
opponents.road.section.m255	dc.b	0

opponents.suggested.road.x.position
temp	dc.b	0	; location has more than 1 use

accelerating	dc.b	0,0
B.1bbaa	dc.b	0
B.1bbab	dc.b	0
main.loop.count	dc.b	0
B.1bbad	dc.b	0
dont.copy.coords	dc.b	0
laps.when.race.finished	dc.b	0
draw.bridge.frame.count	dc.b	0
B.1bbb1	dc.b	0
B.1bbb2	dc.b	0,0
B.1bbb4	dc.b	0
B.1bbb5	dc.b	0
new.damage	dc.b	0,0
opponent.behind.player	dc.b	0
no.wheel.update	dc.b	0
B.1bbba	dc.b	0
copy.swing.from.left	dc.b	0
second.screen	dc.b	0
B.1bbbd	dc.b	0
B.1bbbe	dc.b	0
B.1bbbf	dc.b	0
opponents.random.steering.count	dc.b	0
collision.in.air	dc.b	0
B.1bbc2	dc.b	0
B.1bbc3	dc.b	0
drop.start.done	dc.b	0
coord.offset.zero.or.four	dc.b	0
left.right.value	dc.b	0
player.close.to.opponent	dc.b	0
which.screen	dc.b	0
B.1bbc9	dc.b	0
B.1bbca	dc.b	0
B.1bbcb	dc.b	0
B.1bbcc	dc.b	0
fourteen.frames.elapsed	dc.b	0
	dc.b	0
B.1bbcf	dc.b	0
B.1bbd0	dc.b	0
clip.flag	dc.b	0
drs.flag	dc.b	0
or.with.screen	dc.b	0
section.steering.amount	dc.b	0
map.x.shift	dc.b	0
map.z.shift	dc.b	0
ferocity.of.sparks.or.clouds	dc.b	0
	dc.b	0
road.length.reduction	dc.b	0
which.side.byte	dc.b	0
wheel.frame.number	dc.b	0
other.road.line.colour	dc.b	0
B.1bbdd	dc.b	0
opponent.infront.behind.value	dc.b	0
car.on.chains.countdown	dc.b	0
B.1bbe0	dc.b	0
swing.from.left	dc.b	0
B.1bbe2	dc.b	0
wheel.frame.count	dc.b	0
edge.x1.offset	dc.b	0
coord.pair.to.start.at	dc.b	0
next.segment	dc.b	0,0
B.1bbe8	dc.b	0
B.1bbe9	dc.b	0
B.1bbea	dc.b	0
B.1bbeb	dc.b	0

opponents.road.x.position	dc.w	0
opponents.z.speed	dc.w	0
opponents.engine.z.acceleration	dc.w	0

rough.difference.angle	dc.w	0
engine.revs.change	dc.w	0

max.difference
player.to.right
difference.angle
near.x.coord
	dc.b	0	; location has more than 1 use
x.difference
	dc.b	0	; location has more than 1 use

height.adjust
near.z.coord	dc.w	0	; location has more than 1 use

y.pers.shift	dc.w	0
	dc.w	0
	dc.w	0

swing.magnitude	dc.w	0

surface.y.coord1	dc.w	0
surface.y.coord2	dc.w	0
surface.y.coord3	dc.w	0
surface.y.coord4	dc.w	0
surface.y.coord5	dc.w	0
surface.y.coord6	dc.w	0

overall.left.y.shift	dc.w	0
overall.right.y.shift	dc.w	0
opponents.offset	dc.w	0
edge.x2.offset	dc.b	0,0
B.1bc16	dc.b	0,0
new.speed.bar	dc.w	0
	dc.w	0
W.1bc1c	dc.w	0
dnr.value	dc.w	0
old.speed.bar	dc.w	0

wheel.road.x.position	dc.w	0
opponents.distance.into.section.minus255	dc.w	0
near.sections.done2	dc.w	0
W.1bc28	dc.w	0
pos.difference.angle	dc.w	0
	dc.w	0
x.shift	dc.w	0
rough.player.angle	dc.w	0
plus.180.degrees	dc.w	0
engine.revs	dc.w	0
perspective.z	dc.w	0
smallest.distance.between.players	dc.w	0
damage.value	dc.b	0,0
scaled.pos.difference.angle	dc.w	0
difference.between.players	dc.w	0
surface.z.position	dc.w	0
y.shift	dc.w	0
curve.to.left	dc.w	0
	dc.w	0
	dc.w	0
rough.piece.angle	dc.w	0
surface.x.position	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
B.1bc54	dc.b	0
B.1bc55	dc.b	0
W.1bc56	dc.w	0
fp.y2	dc.w	0
fp.y	dc.w	0

players.x.offset.from.road.centre	dc.w	0
players.road.x.position	dc.w	0

required.raise.height	dc.w	0
wheel.rotation.speed	dc.w	0
W.1bc64	dc.w	0
W.1bc66	dc.w	0
W.1bc68	dc.w	0
W.1bc6a	dc.w	0
W.1bc6c	dc.w	0
W.1bc6e	dc.w	0
W.1bc70	dc.w	0
W.1bc72	dc.w	0
W.1bc74	dc.w	0
W.1bc76	dc.w	0
W.1bc78	dc.w	0
W.1bc7a	dc.w	0
W.1bc7c	dc.w	0
W.1bc7e	dc.w	0
W.1bc80	dc.w	0
W.1bc82	dc.w	0
car.x.shift	dc.w	0
car.y.shift	dc.w	0
W.1bc88	dc.w	0
W.1bc8a	dc.w	0
left.y.coord.offset	dc.w	0
	dc.w	0
right.y.coord.offset	dc.w	0
	dc.w	0

front.left.actual.height	dc.l	0
front.right.actual.height	dc.l	0
rear.actual.height	dc.l	0

wreck.wheel.height.reduction	dc.l	0

front.left.road.height	dc.l	0
front.right.road.height	dc.l	0
rear.road.height	dc.l	0

front.left.height.difference	dc.l	0
front.right.height.difference	dc.l	0
rear.height.difference	dc.l	0

piece.data.offset	dc.w	0
	dc.w	0
road.data.offset	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
which.screen2	dc.b	0,0
	dc.w	0
current.players.x	dc.l	0
players.smaller.y	dc.w	0
	dc.w	0
current.players.z	dc.l	0

players.world.x	dc.l	0
players.world.y	dc.l	0
players.world.z	dc.l	0

players.x.angle	dc.w	0
players.y.angle	dc.w	0
players.z.angle	dc.w	0

players.world.x.speed	dc.w	0
players.world.y.speed	dc.w	0
players.world.z.speed	dc.w	0

players.x.rotation.speed	dc.w	0
players.y.rotation.speed	dc.w	0
players.z.rotation.speed	dc.w	0

total.world.x.acceleration	dc.w	0
total.world.y.acceleration	dc.w	0
total.world.z.acceleration	dc.w	0

players.x.rotation.acceleration	dc.w	0
players.y.rotation.acceleration	dc.w	0
players.z.rotation.acceleration	dc.w	0

front.left.wheel.x.offset	dc.w	0
front.right.wheel.x.offset	dc.w	0
rear.wheel.x.offset	dc.w	0

front.left.wheel.z.offset	dc.w	0
front.right.wheel.z.offset	dc.w	0
rear.wheel.z.offset	dc.w	0

gravity.x.acceleration	dc.w	0
gravity.y.acceleration	dc.w	0
gravity.z.acceleration	dc.w	0

new.front.left.difference	dc.w	0
new.front.right.difference	dc.w	0
new.rear.difference	dc.w	0

old.front.left.difference	dc.w	0
old.front.right.difference	dc.w	0
old.rear.difference	dc.w	0

front.left.amount.below.road	dc.w	0
front.right.amount.below.road	dc.w	0
rear.amount.below.road	dc.w	0

overall.difference.below.road	dc.w	0
front.difference.below.road	dc.w	0

engine.z.acceleration	dc.w	0

players.x.speed	dc.w	0
zero.word1	dc.w	0
players.z.speed	dc.w	0

players.x.acceleration	dc.w	0
players.y.acceleration	dc.w	0
players.z.acceleration	dc.w	0

average.amount.below.road	dc.w	0
	IFD	RECORD
average.front.amount.below.road	dc.w	0
	ENDC

players.final.x.rotation.speed	dc.w	0
players.final.y.rotation.speed	dc.w	0
players.final.z.rotation.speed	dc.w	0

car.collision.x.acceleration	dc.w	0
car.collision.y.acceleration	dc.w	0
car.collision.z.acceleration	dc.w	0

car.to.road.collision.z.acceleration	dc.w	0

z.inclination.to.road	dc.w	0
y.inclination.to.road	dc.w	0
x.inclination.to.road	dc.w	0

surface.cosx.sinz	dc.b	0,0
surface.cosx.cosz	dc.b	0,0
surface.sinx	dc.b	0,0

car.to.car.x.acceleration	dc.w	0
car.to.car.y.acceleration	dc.w	0
car.to.car.z.acceleration	dc.w	0

section.y.angle	dc.w	0
pos.players.z.speed	dc.w	0

opp.new.rear.left.difference	dc.w	0
opp.new.rear.right.difference	dc.w	0
opp.new.front.difference	dc.w	0
	dc.w	0

opp.rear.left.actual.height	dc.w	0
opp.rear.right.actual.height	dc.w	0
opp.front.actual.height	dc.w	0
	dc.w	0

opp.old.rear.left.difference	dc.w	0
opp.old.rear.right.difference	dc.w	0
opp.old.front.difference	dc.w	0
	dc.w	0

opp.rear.left.y.speed	dc.w	0
opp.rear.right.y.speed	dc.w	0
opp.front.y.speed	dc.w	0
	dc.w	0

opp.rear.left.y.acceleration	dc.w	0
opp.rear.right.y.acceleration	dc.w	0
opp.front.y.acceleration	dc.w	0
	dc.w	0

opp.rear.left.road.height	dc.w	0
opp.rear.right.road.height	dc.w	0
opp.front.road.height	dc.w	0
	dc.w	0

segment.x.coords	ds.w	16
segment.z.coords	ds.w	16
	dc.w	36

near.section.flags	ds.w	80

coord.visible.values	ds.w	160
x.values	ds.w	160
y.values	ds.w	160
sin.cos.values	ds.w	36
		ds.w	4


road.under.map
	ds.b	256


TAB.1c380
	ds.w	32
TAB.1c3c0
	ds.w	32
TAB.1c400
	ds.w	32
TAB.1c440
	ds.w	32
	ds.w	32


left.y.coordinate.IDs

* Bit 7 indicates that the y coords for that section are stored as words
* e.g. for steeper sections on the roller coaster or the high jump

	ds.b	100


right.y.coordinate.IDs

* Bit 7 goes to other.road.line.colour

	ds.b	100


road.section.xz.positions

* Top nibble	= Z position
* Bottom nibble	= X position

	ds.b	100


road.section.angle.and.piece

* Top two bits are the rough angle for the piece (0, 90, 180 or 270 degrees).
*
* Bit 4 indicates that piece is rotated through a further 180 degrees.
*
* Bottom nibble is the near section piece to use.

	ds.b	100


overall.left.y.shifts

* A value for each road section, used to shift all the left side y
* co-ordinates up by the same amount.

	ds.w	100


overall.right.y.shifts

* Same as above, but for the right side y co-ordinates.

	ds.w	100


distances.around.road
	ds.w	100


DAT.1c8a8
	ds.w	16
DAT.1c8c8
	ds.w	16
DAT.1c8e8
	ds.w	16

DAT.1c908
	ds.b	24
DAT.1c920
	ds.b	24
DAT.1c938
	ds.b	24


	dc.w	0


opponents.speed.values
	ds.b	100

DAT.1c9b6
	ds.b	12

DAT.1c9c2
	ds.b	12

B.1c9ce	dc.b	0
damage.hole.position	dc.b	0
league.offset	dc.b	0,0

DAT.1c9d2
	ds.b	12

DAT.1c9de
	ds.b	12

DAT.1c9ea
	ds.b	12

DAT.1c9f6
	ds.b	12

DAT.1ca02
	ds.b	12

DAT.1ca0e
	ds.b	12

number.of.road.sections	dc.b	0
players.start.section	dc.b	0
near.start.line.section	dc.b	0
half.a.lap.section	dc.b	0
total.road.distance	dc.w	0
boost.reserve	dc.b	0
B.1ca21	dc.b	0
race.mode	dc.b	0
B.1ca23	dc.b	0
B.1ca24	dc.b	0
B.1ca25	dc.b	0
B.1ca26	dc.b	0
B.1ca27	dc.b	0
B.1ca28	dc.b	0
opponents.ID	dc.b	0
B.1ca2a	dc.b	0
B.1ca2b	dc.b	0
standard.boost	dc.b	0
super.boost	dc.b	0
B.1ca2e	dc.b	0
B.1ca2f	dc.b	0
	dc.b	0
B.1ca31	dc.b	0
start.finish.section	dc.b	0
road.ID	dc.b	0
B.1ca34	dc.b	0
B.1ca35	dc.b	0

DAT.1ca36
	ds.b	12


sin.table	incbin	tables.bin
perspective.table	equ	sin.table+516
perspective.table2	equ	perspective.table+4096


sin.cos.offsets
	dc.b	22,20,2
	dc.b	24,15,4
	dc.b	23,21,3

	dc.b	22,24,23
	dc.b	20,15,21
	dc.b	2,4,3

	dc.b	17,16
	dc.b	18,17


	dc.b	'EM3,d0',13,9,'bne',9,'sco2'
	dc.b	13,9,13,9,'rts',13,9,13,'FETCH',9
	dc.b	'move.b',9,'0(a5,d5.w'
	dc.b	'),d0',13,9,'addq.w',9,'#1,'
	dc.b	'd5',13,'fetch',9,'andi.'


opponents.names
	dc.b	' Hot Rod      ',13,9
	dc.b	' Whizz Kid    ',9,'T'
	dc.b	' Bad Guy      ',9,'b'
	dc.b	' The Dodger   ',9,'b'
	dc.b	' Big Ed       ',9,'#'
	dc.b	' Max Boost    p1'
	dc.b	' Dare Devil   ',13,9
	dc.b	' High Flyer   .b'
	dc.b	' Bully Boy    ml'
	dc.b	' Jumping Jack ,d'
	dc.b	' Road Hog     b.  '
	dc.b	'            ',9,13,9,13
	dc.b	9,13,'GTRACK',13,9,13,9,'move'
	dc.b	'.b',9,'d1,d0',13,9,'asl.'


OBSTRUCTS_PLAYER	equ	2
WHEELIE			equ	4
DRIVES_NEAR_EDGE	equ	8
PUSH_PLAYER		equ	32

opponent.attributes
	dc.b	PUSH_PLAYER|OBSTRUCTS_PLAYER
	dc.b	PUSH_PLAYER
	dc.b	%1000000|PUSH_PLAYER|OBSTRUCTS_PLAYER
	dc.b	PUSH_PLAYER
	dc.b	%0010000|PUSH_PLAYER|DRIVES_NEAR_EDGE|WHEELIE|OBSTRUCTS_PLAYER
	dc.b	WHEELIE
	dc.b	%0010000|PUSH_PLAYER
	dc.b	%0010000|WHEELIE
	dc.b	%1000000|DRIVES_NEAR_EDGE|OBSTRUCTS_PLAYER
	dc.b	%0010000
	dc.b	DRIVES_NEAR_EDGE
	dc.b	%0000000			(unused)


;L.1ed96
	dc.b	'e.b',9,'d0,d2',13,9,'movea.l',9,'#'
;L.1edaa
track.names
	dc.b	'LITTLE RAMP     '
	dc.b	'STEPPING STONES '
	dc.b	'HUMP BACK       '
	dc.b	'BIG RAMP        '
	dc.b	'SKI JUMP        '
	dc.b	'DRAW BRIDGE     '
	dc.b	'HIGH JUMP       '
	dc.b	'ROLLER COASTER  '
	dc.b	0,129,148,0,'0',168,12,128,1,129,15,224
	dc.b	'd',8,30,128,1,129,15,224,20,8,30,128,1,129,0,240
	dc.b	3,8,3,128,1,'A',2,0,'d',152,1,128,2,0,0,255
	dc.b	'P',7,255,128,0,0,0,207,'P',7,255,128,'ve.b'
	dc.b	9,'d0,DV',13,9,'jsr',9,'FETC'
	dc.b	'H',13,9,'move.b',9,'d0,DUH'
	dc.b	13,9,'move.b',9,'d0,DVH',9
	dc.b	13,9,13,9,'move.b',9,'#0,d1'
	dc.b	13,9,'mo',233,229,250,243,248,227,237,226,254,138,237,239
	dc.b	229,236,236,138,233,248,235,231,231,229,228,238,138,155
	dc.b	147,146,146,'PDU'


cosine.conversion.table

* Used to convert a sin value from (0*256 - 1*256) into a cosine value.
*
* There are 128 values in this table representing sin values increasing in
* increments of 1/128.
*
* Each value is calculated by getting the inverse sin of the sin value, to
* give the actual angle, then taking the cosine of this angle.  The result
* is then multiplied by 256.
*
* First 8 values should ideally be 256.

	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe
	dc.b	$fe,$fe,$fd,$fd,$fd,$fd,$fc,$fc
	dc.b	$fb,$fb,$fb,$fa,$fa,$f9,$f9,$f8
	dc.b	$f8,$f7,$f7,$f6,$f6,$f5,$f4,$f4
	dc.b	$f3,$f3,$f2,$f1,$f0,$f0,$ef,$ee
	dc.b	$ed,$ec,$ec,$eb,$ea,$e9,$e8,$e7
	dc.b	$e6,$e5,$e4,$e3,$e2,$e1,$e0,$df
	dc.b	$de,$dd,$db,$da,$d9,$d8,$d6,$d5
	dc.b	$d4,$d2,$d1,$cf,$ce,$cc,$cb,$c9
	dc.b	$c8,$c6,$c5,$c3,$c1,$bf,$be,$bc
	dc.b	$ba,$b8,$b6,$b4,$b2,$b0,$ae,$ac
	dc.b	$a9,$a7,$a5,$a2,$a0,$9d,$9b,$98
	dc.b	$95,$92,$8f,$8c,$89,$86,$83,$7f
	dc.b	$7c,$78,$74,$70,$6c,$68,$63,$5e
	dc.b	$59,$53,$4d,$47,$3f,$37,$2d,$20


opponents.x.spans	* 32 values
	dc.b	27,27,27,27,27,26,26,26,25,25,25,24,23,23,22,21
	dc.b	20,19,18,17,15,14,11,9,7,7,7,7,7,7,7,7


	dc.b	'#16,d0',13,9,'beq',9,'gt11',13,9,'move.b'


piece.data.offsets
	dc.w	$50b2,$a3b2,$a9ff,$feb2,$59b3,$20da,$d8b3,$3bb4
	dc.w	$0a46,$2e20,$9eb4,$a980,$852e,$60a5,$30c9,$8190

* These first 16 words are used to give offsets to the data definitions of
* the different road pieces.  They are stored in low byte, high byte order
* so they are rotated by 8 bit positions to give a high byte, low byte word.
* This word then has #$b100 subtracted from it to give an offset to the data
* of the required piece.
*
* The resulting words are as follows :-
*
*	336,419,000,510,601,000,728,827
*	000,000,926,000,000,000,000,000
*
* Some values have been replaced by zeros because the actual values are
* bollocks and are not used by the program (for any of the roads).  The only
* values used by the program are words 0, 1, 3, 4, 6, 7 and 10.


y.coordinate.offsets
	dc.w	$0db5,$1bb5,$24b5,$36b5,$44b5,$52b5,$5cb5,$66b5
	dc.w	$6fb5,$78b5,$86b5,$94b5,$9db5,$a6b5,$b2b5,$cab5
	dc.w	$d3b5,$ebb5,$f7b5,$01b6,$0ab6,$14b6,$1db6,$27b6
	dc.w	$31b6,$3ab6,$43b6,$4db6,$57b6,$60b6,$69b6,$72b6
	dc.w	$7bb6,$84b6,$90b6,$99b6,$a2b6,$abb6,$b7b6,$c0b6
	dc.w	$c9b6,$d5b6,$e1b6,$edb6,$f9b6,$02b7,$0bb7,$14b7
	dc.w	$1db7,$26b7,$32b7,$3eb7,$4cb7,$56b7,$5fb7,$68b7
	dc.w	$7ab7,$83b7,$8cb7,$95b7,$9eb7,$a7b7,$b0b7,$b9b7
	dc.w	$c3b7,$ccb7,$d6b7,$e8b7,$f1b7,$fab7,$03b8,$0cb8
	dc.w	$16b8,$1fb8,$28b8,$31b8,$3ab8,$46b8,$4fb8,$58b8
	dc.w	$70b8,$a720,$7eb8,$87b8,$90b8,$9eb8,$acb8,$b5b8
	dc.w	$bfb8,$c9b8,$d5b8,$deb8,$e7b8,$f0b8,$fab8,$03b9
	dc.w	$15b9,$27b9,$39b9,$4bb9,$54b9,$60b9,$6ab9,$74b9
	dc.w	$7eb9,$88b9,$91b9,$9ab9,$a3b9,$acb9,$b5b9,$beb9
	dc.w	$cab9,$d4b9,$e0b9,$f8b9,$04ba,$0dba,$1fba,$28ba
	dc.w	$a320,$7da3,$31ba,$aa20,$3aba,$44ba,$4eba,$58ba

* The above words give the following offsets :-
*
*	1037,1051,1060,1078,1092,1106,1116,1126
*	1135,1144,1158,1172,1181,1190,1202,1226
*	1235,1259,1271,1281,1290,1300,1309,1319
*	1329,1338,1347,1357,1367,1376,1385,1394
*	1403,1412,1424,1433,1442,1451,1463,1472
*	1481,1493,1505,1517,1529,1538,1547,1556
*	1565,1574,1586,1598,1612,1622,1631,1640
*	1658,1667,1676,1685,1694,1703,1712,1721
*	1731,1740,1750,1768,1777,1786,1795,1804
*	1814,1823,1832,1841,1850,1862,1871,1880
*	1904,0000,1918,1927,1936,1950,1964,1973
*	1983,1993,2005,2014,2023,2032,2042,2051
*	2069,2087,2105,2123,2132,2144,2154,2164
*	2174,2184,2193,2202,2211,2220,2229,2238
*	2250,2260,2272,2296,2308,2317,2335,2344
*	0000,0000,2353,0000,2362,2372,2382,2392


road.data.offsets
	dc.w	$62ba,$deba,$6fbb,$00bc,$8ebc,$1fbd,$f4bd,$82be
	dc.w	$f5a7,$4c00,$a54c,$b2a3,$0017,$4163,$6375,$7261

* The above words give the following offsets :-
*
*	2402,2526,2671,2816,2958,3103,3316,3458
*	0000,0000,0000,0000,0000,0000,0000,0000


sections.car.can.be.put.on
	dc.b	$00,$80,$20,$c0,$00,$73,$80,$c0
	dc.b	$a9,$59,$00,$02,$a9,$5e,$85,$4b

* These 16 bytes are flags for each of the near sections.  The actual values
* used are as follows :-
*
*	dc.b	$00,$80,$00,$c0,$00,$00,$80,$c0
*	dc.b	$00,$00,$00,$00,$00,$00,$00,$00
*
* If bit 7 is set then the car cannot be lowered onto this section.


O336	dc.b	4			offset for number.of.coords
	dc.b	0			near.section.byte1
	dc.b	$40,$03
	dc.b	9*2			number.of.coords
	dc.b	0			gives curve.to.left
	dc.b	WIDTH.REDUCTION		road.width.reduction
	dc.b	128			road.length.reduction
	dc.b	$80,$01
	dc.b	$20			section.steering.amount

* Groups of X and Z co-ordinates follow.  There are two bytes for each
* co-ordinate - stored in low byte, high byte order.
*
* First line is :-	X = $340, Z = $000, X = $4c0, Z = $000

	dc.b	$40,$03,$00,$00,$c0,$04,$00,$00		straight 8
	dc.b	$40,$03,$00,$01,$c0,$04,$00,$01
	dc.b	$40,$03,$00,$02,$c0,$04,$00,$02
	dc.b	$40,$03,$00,$03,$c0,$04,$00,$03
	dc.b	$40,$03,$00,$04,$c0,$04,$00,$04
	dc.b	$40,$03,$00,$05,$c0,$04,$00,$05
	dc.b	$40,$03,$00,$06,$c0,$04,$00,$06
	dc.b	$40,$03,$00,$07,$c0,$04,$00,$07
	dc.b	$40,$03,$00,$08,$c0,$04,$00,$08

O419	dc.b	12
	dc.b	$80
	dc.b	$a8,$0d,$00,$00,$00,$ff,$80,$68,$0a,$87
	dc.b	9*2
	dc.b	0
	dc.b	WIDTH.REDUCTION
	dc.b	135
	dc.b	$80,$01
	dc.b	$3e

	dc.b	$40,$03,$00,$00,$c0,$04,$00,$00		curve right 8
	dc.b	$4c,$03,$05,$01,$ca,$04,$df,$00
	dc.b	$73,$03,$07,$02,$eb,$04,$bc,$01
	dc.b	$b2,$03,$05,$03,$22,$05,$95,$02
	dc.b	$0a,$04,$fb,$03,$6d,$05,$68,$03
	dc.b	$7a,$04,$e7,$04,$cd,$05,$32,$04
	dc.b	$00,$05,$c8,$05,$40,$06,$f2,$04
	dc.b	$9c,$05,$9a,$06,$c5,$06,$a6,$05
	dc.b	$4c,$06,$5b,$07,$5b,$07,$4c,$06

O510	dc.b	12
	dc.b	$c0
	dc.b	$57,$fa,$00,$00,$00,$01,$80,$e8,$08,$87
	dc.b	9*2
	dc.b	3
	dc.b	WIDTH.REDUCTION
	dc.b	135
	dc.b	$80,$01
	dc.b	$3e

	dc.b	$3f,$03,$00,$00,$bf,$04,$00,$00		curve left 8
	dc.b	$35,$03,$df,$00,$b3,$04,$05,$01
	dc.b	$14,$03,$bc,$01,$8c,$04,$07,$02
	dc.b	$dd,$02,$95,$02,$4d,$04,$05,$03
	dc.b	$92,$02,$68,$03,$f5,$03,$fb,$03
	dc.b	$32,$02,$32,$04,$85,$03,$e7,$04
	dc.b	$bf,$01,$f2,$04,$ff,$02,$c8,$05
	dc.b	$3a,$01,$a6,$05,$63,$02,$9a,$06
	dc.b	$a4,$00,$4c,$06,$b3,$01,$5b,$07

O601	dc.b	8
	dc.b	$40
	dc.b	$40,$ff,$00,$20,$80,$b5
	dc.b	14*2
	dc.b	0
	dc.b	WIDTH.REDUCTION
	dc.b	128
	dc.b	$80,$01
	dc.b	$20

	dc.b	$78,$ff,$87,$00,$87,$00,$78,$ff		straight 13
	dc.b	$2c,$00,$3c,$01,$3c,$01,$2c,$00
	dc.b	$e1,$00,$f0,$01,$f0,$01,$e1,$00
	dc.b	$96,$01,$a5,$02,$a5,$02,$96,$01
	dc.b	$4a,$02,$5a,$03,$5a,$03,$4a,$02
	dc.b	$ff,$02,$0e,$04,$0e,$04,$ff,$02
	dc.b	$b3,$03,$c3,$04,$c3,$04,$b3,$03
	dc.b	$68,$04,$77,$05,$77,$05,$68,$04
	dc.b	$1d,$05,$2c,$06,$2c,$06,$1d,$05
	dc.b	$d1,$05,$e1,$06,$e1,$06,$d1,$05
	dc.b	$86,$06,$95,$07,$95,$07,$86,$06
	dc.b	$3a,$07,$4a,$08,$4a,$08,$3a,$07
	dc.b	$ef,$07,$ff,$08,$ff,$08,$ef,$07
	dc.b	$a4,$08,$b3,$09,$b3,$09,$a4,$08

O728	dc.b	12
	dc.b	$80
	dc.b	$00,$10,$00,$00,$00,$ff,$90,$c0,$0c,$7a
	dc.b	10*2
	dc.b	0
	dc.b	WIDTH.REDUCTION
	dc.b	122
	dc.b	$80,$01
	dc.b	$32

	dc.b	$40,$03,$00,$00,$c0,$04,$00,$00		curve right 9
	dc.b	$4c,$03,$1c,$01,$ca,$04,$fb,$00
	dc.b	$71,$03,$36,$02,$eb,$04,$f4,$01
	dc.b	$af,$03,$4c,$03,$22,$05,$e9,$02
	dc.b	$04,$04,$5c,$04,$6d,$05,$d9,$03
	dc.b	$71,$04,$63,$05,$cd,$05,$c1,$04
	dc.b	$f5,$04,$60,$06,$41,$06,$a0,$05
	dc.b	$8e,$05,$50,$07,$c8,$06,$73,$06
	dc.b	$3b,$06,$32,$08,$61,$07,$3b,$07
	dc.b	$fc,$06,$03,$09,$0b,$08,$f4,$07

O827	dc.b	12
	dc.b	$c0
	dc.b	$00,$f8,$00,$00,$00,$01,$90,$40,$0b,$7a
	dc.b	10*2
	dc.b	3
	dc.b	WIDTH.REDUCTION
	dc.b	122
	dc.b	$80,$01
	dc.b	$32

	dc.b	$40,$03,$00,$00,$c0,$04,$00,$00		curve left 9
	dc.b	$35,$03,$fb,$00,$b3,$04,$1c,$01
	dc.b	$14,$03,$f4,$01,$8e,$04,$36,$02
	dc.b	$dd,$02,$e9,$02,$50,$04,$4c,$03
	dc.b	$92,$02,$d9,$03,$fb,$03,$5c,$04
	dc.b	$32,$02,$c1,$04,$8e,$03,$63,$05
	dc.b	$be,$01,$a0,$05,$0a,$03,$60,$06
	dc.b	$37,$01,$73,$06,$71,$02,$50,$07
	dc.b	$9e,$00,$3b,$07,$c4,$01,$32,$08
	dc.b	$f4,$ff,$f4,$07,$03,$01,$03,$09

O926	dc.b	8
	dc.b	$40
	dc.b	$40,$ff,$00,$20,$7c,$b0
	dc.b	12*2
	dc.b	0
	dc.b	WIDTH.REDUCTION
	dc.b	124
	dc.b	$80,$01
	dc.b	$20

	dc.b	$78,$ff,$87,$00,$87,$00,$78,$ff		straight 11
	dc.b	$32,$00,$41,$01,$41,$01,$32,$00
	dc.b	$ec,$00,$fc,$01,$fc,$01,$ec,$00
	dc.b	$a6,$01,$b6,$02,$b6,$02,$a6,$01
	dc.b	$60,$02,$70,$03,$70,$03,$60,$02
	dc.b	$1b,$03,$2a,$04,$2a,$04,$1b,$03
	dc.b	$d5,$03,$e4,$04,$e4,$04,$d5,$03
	dc.b	$8f,$04,$9f,$05,$9f,$05,$8f,$04
	dc.b	$49,$05,$59,$06,$59,$06,$49,$05
	dc.b	$03,$06,$13,$07,$13,$07,$03,$06
	dc.b	$be,$06,$cd,$07,$cd,$07,$be,$06
	dc.b	$78,$07,$87,$08,$87,$08,$78,$07


******** Start of y co-ordinates for near sections ********
*
*	B means co-ords are stored as bytes, W means words.
*

B1037	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

B1051	dc.b	$00,$60,$61,$03,$44,$26,$28,$2a,$2c

W1060	dc.b	$00,$00,$02,$00,$04,$00,$06,$00,$08,$00,$0a,$00,$0c,$00
	dc.b	$0e,$00,$10,$00

B1078	dc.b	$00,$20,$40,$60,$01,$21,$41,$61,$02,$02,$02,$02,$02,$02

B1092	dc.b	$02,$61,$41,$21,$01,$60,$40,$20,$00,$00,$00,$00,$00,$00

B1106	dc.b	$00,$60,$21,$51,$02,$22,$42,$62,$03,$13

B1116	dc.b	$00,$20,$40,$70,$21,$41,$61,$02,$22,$32

B1126	dc.b	$00,$02,$04,$06,$e7,$29,$ca,$4b,$2c

B1135	dc.b	$46,$96,$55,$85,$24,$33,$b2,$21,$00

B1144	dc.b	$00,$00,$00,$00,$00,$10,$20,$40,$60,$01,$21,$41,$61,$02

B1158	dc.b	$02,$02,$02,$02,$02,$71,$61,$41,$21,$01,$60,$40,$20,$00

B1172	dc.b	$00,$10,$10,$10,$10,$10,$10,$90,$80

B1181	dc.b	$10,$00,$00,$00,$00,$00,$00,$80,$90

B1190	dc.b	$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b

W1202	dc.b	$1b,$80,$1c,$80,$1d,$80,$1e,$80,$1f,$80,$20,$80,$a1,$80
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00,$00,$00

B1226	dc.b	$4e,$1d,$db,$0a,$a8,$36,$34,$22,$00

W1235	dc.b	$00,$00,$9b,$20,$19,$e0,$18,$a0,$17,$60,$16,$20,$14,$e0
	dc.b	$13,$a0,$12,$60,$11,$20,$0f,$e0,$0e,$a0

B1259	dc.b	$48,$27,$26,$35,$44,$63,$13,$42,$71,$21,$50,$00

B1271	dc.b	$13,$03,$62,$42,$22,$02,$51,$21,$e0,$80

B1281	dc.b	$05,$05,$85,$00,$00,$85,$05,$05,$05

B1290	dc.b	$32,$22,$02,$61,$41,$21,$70,$40,$a0,$80

B1300	dc.b	$00,$40,$01,$41,$02,$42,$03,$33,$63

B1309	dc.b	$00,$20,$30,$30,$30,$30,$30,$30,$30,$30

B1319	dc.b	$30,$10,$00,$00,$00,$00,$00,$00,$00,$00

B1329	dc.b	$00,$00,$00,$00,$00,$00,$00,$90,$b0

B1338	dc.b	$30,$30,$30,$30,$30,$30,$30,$a0,$80

B1347	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$90,$b0

B1357	dc.b	$30,$30,$30,$30,$30,$30,$30,$30,$a0,$80

B1367	dc.b	$00,$21,$42,$53,$e4,$65,$e6,$57,$48

B1376	dc.b	$00,$60,$41,$92,$62,$a3,$63,$14,$44

B1385	dc.b	$00,$20,$40,$d0,$60,$60,$d0,$40,$20

B1394	dc.b	$04,$63,$b3,$03,$42,$82,$31,$60,$00

B1403	dc.b	$a6,$80,$00,$00,$00,$00,$00,$80,$35

B1412	dc.b	$47,$87,$46,$75,$25,$44,$63,$03,$22,$41,$60,$00

B1424	dc.b	$08,$27,$36,$c5,$44,$43,$32,$21,$00

B1433	dc.b	$50,$50,$50,$50,$c0,$30,$20,$10,$00

B1442	dc.b	$00,$00,$10,$30,$60,$11,$51,$22,$72

B1451	dc.b	$00,$60,$41,$a2,$d2,$62,$f2,$72,$72,$72,$72,$72

B1463	dc.b	$22,$b2,$32,$a2,$12,$f1,$31,$60,$00

B1472	dc.b	$0a,$68,$47,$26,$05,$63,$42,$21,$00

B1481	dc.b	$00,$10,$30,$60,$21,$71,$42,$13,$63,$34,$05,$55

B1493	dc.b	$55,$26,$76,$47,$18,$68,$39,$8a,$00,$00,$00,$00

B1505	dc.b	$00,$c7,$76,$26,$55,$05,$34,$63,$13,$42,$71,$21

B1517	dc.b	$21,$60,$30,$10,$00,$00,$00,$00,$00,$00,$00,$00

B1529	dc.b	$8a,$80,$00,$00,$00,$00,$00,$80,$4c

B1538	dc.b	$00,$41,$03,$44,$06,$47,$09,$4a,$0c

B1547	dc.b	$70,$50,$30,$10,$00,$10,$30,$50,$70

B1556	dc.b	$aa,$80,$00,$00,$00,$00,$00,$80,$2a

B1565	dc.b	$59,$49,$39,$a9,$63,$63,$63,$63,$47

B1574	dc.b	$00,$00,$00,$10,$30,$50,$01,$31,$71,$42,$23,$14

B1586	dc.b	$62,$62,$62,$d2,$42,$a2,$02,$61,$b1,$01,$40,$00

B1598	dc.b	$00,$40,$01,$41,$02,$42,$03,$43,$04,$64,$45,$26,$07,$67

B1612	dc.b	$00,$10,$20,$30,$40,$40,$40,$40,$40,$40

B1622	dc.b	$00,$00,$00,$00,$00,$10,$30,$60,$21

B1631	dc.b	$8d,$80,$00,$00,$00,$00,$00,$00,$00

W1640	dc.b	$00,$00,$00,$00,$80,$00,$9c,$80,$1c,$80,$9c,$80,$80,$00
	dc.b	$00,$00,$00,$00

B1658	dc.b	$00,$00,$10,$20,$40,$60,$01,$31,$71

B1667	dc.b	$00,$10,$30,$70,$31,$71,$b2,$52,$62

B1676	dc.b	$00,$00,$00,$10,$30,$60,$21,$02,$03

B1685	dc.b	$00,$10,$30,$60,$21,$71,$62,$53,$44

B1694	dc.b	$00,$70,$61,$52,$43,$34,$25,$16,$07

B1703	dc.b	$00,$00,$00,$00,$00,$00,$00,$80,$2e

B1712	dc.b	$00,$01,$f1,$52,$a3,$63,$94,$34,$54

B1721	dc.b	$00,$30,$d0,$70,$11,$a1,$31,$41,$41,$41

B1731	dc.b	$40,$10,$00,$00,$00,$10,$40,$11,$61

B1740	dc.b	$40,$40,$40,$40,$40,$40,$30,$20,$10,$00

W1750	dc.b	$9a,$c0,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$80,$00,$0c,$80

B1768	dc.b	$24,$03,$02,$21,$60,$30,$10,$00,$00

B1777	dc.b	$47,$46,$65,$25,$05,$05,$15,$35,$75

B1786	dc.b	$80,$e6,$16,$45,$74,$24,$53,$23,$13

B1795	dc.b	$46,$25,$14,$13,$22,$41,$70,$30,$00

B1804	dc.b	$00,$01,$12,$33,$54,$75,$17,$38,$59,$7a

B1814	dc.b	$02,$71,$d1,$21,$60,$30,$10,$00,$00

B1823	dc.b	$00,$00,$10,$30,$60,$21,$d1,$71,$02

B1832	dc.b	$00,$40,$81,$31,$d1,$61,$f1,$71,$71

B1841	dc.b	$22,$61,$21,$60,$30,$10,$00,$00,$00

B1850	dc.b	$00,$60,$41,$22,$03,$63,$44,$25,$06,$66,$47,$28

B1862	dc.b	$00,$00,$10,$30,$60,$21,$71,$52,$43

B1871	dc.b	$24,$45,$e6,$80,$21,$42,$63,$05,$26

W1880	dc.b	$28,$60,$27,$c0,$27,$40,$26,$e0,$26,$a0,$26,$80,$26,$80
	dc.b	$26,$a0,$26,$e0,$27,$20,$a7,$60,$00,$00

B1904	dc.b	$00,$01,$02,$03,$04,$05,$06,$07,$08,$68,$49,$2a,$0b,$6b

B1918	dc.b	$00,$70,$51,$32,$13,$73,$54,$35,$06

B1927	dc.b	$00,$50,$31,$12,$72,$53,$34,$15,$06

B1936	dc.b	$00,$60,$41,$22,$03,$73,$64,$65,$66,$67,$68,$69,$6a,$6b

B1950	dc.b	$00,$60,$41,$22,$03,$53,$24,$64,$25,$65,$26,$66,$27,$67

B1964	dc.b	$00,$81,$61,$a2,$42,$52,$52,$52,$52

B1973	dc.b	$00,$41,$72,$14,$35,$56,$77,$19,$3a,$5b

B1983	dc.b	$00,$21,$42,$63,$05,$26,$47,$68,$1a,$5b

B1993	dc.b	$64,$14,$43,$72,$22,$51,$01,$40,$20,$10,$00,$00

B2005	dc.b	$05,$05,$05,$15,$25,$45,$e5,$00,$00

B2014	dc.b	$22,$12,$f1,$51,$31,$11,$60,$30,$00

B2023	dc.b	$00,$50,$31,$22,$23,$34,$55,$76,$18

B2032	dc.b	$00,$21,$42,$63,$05,$26,$47,$68,$79,$7a

B2042	dc.b	$52,$71,$21,$60,$30,$10,$00,$00,$00

W2051	dc.b	$00,$00,$00,$20,$00,$40,$00,$60,$32,$00,$00,$60,$00,$40
	dc.b	$00,$20,$00,$00

W2069	dc.b	$00,$00,$00,$20,$00,$40,$00,$60,$32,$00,$00,$60,$00,$40
	dc.b	$00,$20,$00,$00

W2087	dc.b	$00,$00,$00,$20,$00,$40,$00,$60,$32,$00,$00,$60,$00,$40
	dc.b	$00,$20,$00,$00

W2105	dc.b	$00,$00,$00,$20,$00,$40,$00,$60,$32,$00,$00,$60,$00,$40
	dc.b	$00,$20,$00,$00

B2123	dc.b	$63,$43,$a3,$f2,$42,$02,$41,$01,$40

B2132	dc.b	$28,$47,$66,$06,$25,$44,$63,$03,$22,$41,$60,$00

B2144	dc.b	$14,$73,$43,$03,$42,$02,$41,$01,$40,$00

B2154	dc.b	$74,$14,$43,$03,$42,$02,$41,$01,$40,$00

B2164	dc.b	$14,$53,$13,$52,$12,$51,$11,$50,$a0,$80

B2174	dc.b	$74,$34,$73,$33,$72,$32,$71,$31,$e0,$80

B2184	dc.b	$23,$62,$22,$61,$21,$70,$40,$20,$00

B2193	dc.b	$42,$42,$52,$72,$13,$43,$f3,$80,$00

B2202	dc.b	$00,$00,$00,$80,$85,$05,$05,$05,$05

B2211	dc.b	$0c,$59,$47,$55,$04,$52,$41,$50,$00

B2220	dc.b	$00,$10,$30,$50,$e0,$50,$30,$10,$00

B2229	dc.b	$00,$00,$00,$00,$80,$00,$00,$00,$00

B2238	dc.b	$04,$04,$04,$04,$04,$04,$73,$e3,$33,$52,$41,$00

B2250	dc.b	$44,$04,$43,$03,$42,$02,$41,$01,$40,$00

B2260	dc.b	$41,$41,$41,$41,$41,$41,$31,$a1,$01,$e0,$30,$00

W2272	dc.b	$18,$c0,$16,$80,$14,$40,$12,$00,$0f,$c0,$0d,$80,$0b,$40
	dc.b	$09,$00,$06,$c0,$04,$80,$02,$40,$00,$00

B2296	dc.b	$7e,$4c,$1a,$08,$16,$44,$13,$02,$11,$40,$10,$00

B2308	dc.b	$60,$30,$10,$00,$00,$10,$30,$60,$21

W2317	dc.b	$13,$00,$10,$a0,$0e,$40,$0b,$e0,$09,$80,$07,$20,$04,$c0
	dc.b	$02,$60,$00,$00

B2335	dc.b	$00,$e8,$18,$47,$76,$26,$55,$05,$34

B2344	dc.b	$00,$00,$00,$10,$30,$60,$21,$71,$42

B2353	dc.b	$00,$21,$42,$63,$05,$26,$47,$68,$0a

B2362	dc.b	$00,$60,$31,$71,$32,$72,$33,$73,$34,$74

B2372	dc.b	$00,$20,$50,$11,$51,$12,$52,$13,$53,$14

B2382	dc.b	$00,$40,$01,$41,$02,$42,$03,$43,$94,$f4

B2392	dc.b	$00,$40,$01,$41,$02,$42,$03,$43,$f3,$94


O2402					* Little Ramp

 dc.b	44				number.of.road.sections
 dc.b	15				players.start.section
 dc.b	15				near.start.line.section
 dc.b	37				half.a.lap.section

 dc.b	$00,$05

 dc.b	$a0,$cf,$6a,$9f,$6b,$24,$50,$50
 dc.b	$25,$00,$00,$19,$63,$80,$2f,$04,$64,$86,$1f,$65,$66,$57,$0e,$68
 dc.b	$67,$c0,$0d,$64,$04,$e0,$0c,$69,$9f,$17,$00,$00,$00,$00,$00,$00
 dc.b	$00,$00,$cc,$02,$c6,$01,$16,$17,$b7,$10,$00,$01,$20,$19,$18,$94
 dc.b	$31,$04,$03,$2a,$42,$00,$2a,$53,$00,$2a,$64,$00,$2a,$75,$28,$2a
 dc.b	$86,$29,$2a,$97,$00,$2a,$a8,$2a,$2a,$b9,$2b,$2a,$ca,$00,$2a,$db
 dc.b	$00,$04,$ec,$09,$0a,$d3,$fd,$16,$17,$66,$fe,$00,$17,$ef,$1b,$1a
 dc.b	$8d,$df,$06,$05,$22,$2f,$02,$02,$21,$46,$03,$58,$01,$22


O2526					* Stepping Stones

 dc.b	56
 dc.b	42
 dc.b	42
 dc.b	14

 dc.b	$00,$0f

 dc.b	$a0,$cf,$00,$9f,$3b,$3c,$3c,$25,$13,$48,$49,$00
 dc.b	$32,$80,$2f,$04,$64,$86,$1f,$65,$66,$57,$0e,$68,$67,$c0,$0d,$64
 dc.b	$04,$e0,$0c,$69,$9f,$2e,$2f,$2e,$2f,$2e,$2f,$2e,$2f,$38,$c0,$02
 dc.b	$4c,$03,$c6,$01,$7c,$7d,$97,$10,$7f,$7e,$00,$20,$03,$4c,$20,$30
 dc.b	$33,$9f,$33,$15,$1e,$1f,$64,$64,$64,$64,$5e,$0c,$d0,$06,$e0,$16
 dc.b	$17,$d7,$f1,$1b,$1a,$4d,$f2,$60,$f3,$00,$9f,$00,$49,$00,$5a,$6b
 dc.b	$00,$00,$48,$00,$4c,$fd,$46,$fe,$16,$17,$17,$ef,$1b,$1a,$8d,$df
 dc.b	$07,$09,$30,$34,$08,$09,$03,$d4,$08,$3f,$0f,$be,$11,$bd,$13,$bb
 dc.b	$15,$ba,$2c,$f3,$1e,$42,$10,$11,$12,$13,$14,$15,$16,$2f,$05


O2671					* Hump Back

 dc.b	53
 dc.b	$2e
 dc.b	$2e
 dc.b	$13

 dc.b	$40,$05

 dc.b	$60,$04,$3a,$8f,$7a,$1c,$1d,$1e,$1f,$22,$27
 dc.b	$43,$4d,$0d,$47,$0e,$17,$16,$96,$1f,$1a,$1b,$0c,$2f,$20,$3f,$00
 dc.b	$9f,$48,$00,$39,$00,$48,$49,$48,$00,$38,$00,$df,$03,$4c,$07,$ef
 dc.b	$7d,$7c,$56,$fe,$7e,$7f,$c0,$fd,$4c,$03,$e0,$fc,$33,$6f,$4a,$71
 dc.b	$1f,$64,$64,$5e,$cd,$f5,$c7,$f4,$17,$16,$16,$e3,$1a,$1b,$8c,$d3
 dc.b	$a0,$c3,$30,$1f,$4b,$8c,$a3,$81,$93,$0b,$0c,$14,$82,$04,$03,$84
 dc.b	$71,$0a,$09,$11,$60,$0c,$0b,$8c,$50,$a0,$40,$00,$1f,$00,$8d,$20
 dc.b	$87,$10,$17,$16,$d6,$01,$1a,$1b,$4c,$02,$60,$03,$00,$06,$05,$29
 dc.b	$31,$06,$01,$00,$52,$01,$4d,$1b,$4c,$25,$4f,$28,$4d,$34,$5c,$26


O2816					* Big Ramp

 dc.b	44
 dc.b	1
 dc.b	1
 dc.b	24

 dc.b	$80,$07

 dc.b	$a0,$c0,$00,$3f,$00,$00,$00,$80,$80,$6d
 dc.b	$6e,$4f,$6e,$6d,$6d,$6e,$6e,$6d,$6d,$6e,$a0,$30,$00,$8d,$20,$87
 dc.b	$10,$17,$16,$d6,$01,$1a,$1b,$4c,$02,$60,$03,$77,$9f,$29,$00,$00
 dc.b	$76,$40,$29,$00,$00,$45,$4d,$0d,$47,$0e,$17,$16,$b6,$1f,$00,$03
 dc.b	$2f,$18,$19,$54,$3e,$03,$04,$ea,$4d,$31,$ea,$5c,$0d,$ea,$6b,$0d
 dc.b	$ea,$7a,$8e,$ea,$89,$00,$ea,$98,$00,$ea,$a7,$00,$ea,$b6,$90,$ea
 dc.b	$c5,$11,$ea,$d4,$59,$c4,$e3,$0a,$09,$51,$f2,$17,$16,$e7,$f1,$00
 dc.b	$16,$e0,$1a,$1b,$8c,$d0,$0a,$09,$2b,$29,$05,$08,$20,$d6,$0e,$4e
 dc.b	$0f,$4b,$13,$4b,$14,$46,$10,$11,$15,$16,$20,$21,$22,$23


O2958					* Ski Jump

 dc.b	40
 dc.b	15
 dc.b	15
 dc.b	35

 dc.b	$40,$6a

 dc.b	$aa,$bd,$71,$aa,$ac,$21,$aa,$9b,$64,$aa,$8a,$cf
 dc.b	$aa,$79,$00,$aa,$68,$00,$aa,$57,$00,$aa,$46,$6f,$aa,$35,$f2,$aa
 dc.b	$24,$73,$84,$13,$09,$0a,$53,$02,$16,$17,$e6,$01,$00,$97,$10,$1b
 dc.b	$1a,$0d,$20,$20,$30,$24,$00,$40,$50,$33,$01,$50,$52,$53,$94,$61
 dc.b	$33,$50,$2a,$72,$4c,$04,$83,$55,$54,$91,$94,$53,$52,$00,$a4,$50
 dc.b	$33,$20,$b4,$4c,$1f,$25,$0c,$d4,$06,$e4,$16,$17,$d7,$f5,$1b,$1a
 dc.b	$4d,$f6,$60,$f7,$4d,$5f,$47,$7a,$4e,$7a,$56,$4c,$fd,$46,$fe,$16
 dc.b	$17,$37,$ef,$00,$81,$df,$19,$18,$14,$ce,$04,$03,$07,$08,$2b,$28
 dc.b	$06,$01,$03,$d8,$15,$54,$18,$36,$20,$c2,$00,$42,$27,$c9,$20


O3103					* Draw Bridge

 dc.b	78
 dc.b	42
 dc.b	42
 dc.b	4

 dc.b	$a0,$11

 dc.b	$a0,$cc,$00,$7f,$38,$33,$33,$2c,$00,$00,$32
 dc.b	$80,$4c,$04,$64,$86,$3c,$65,$66,$57,$2b,$68,$67,$c0,$2a,$64,$04
 dc.b	$e0,$29,$2b,$3f,$20,$35,$5c,$c0,$25,$2d,$0d,$c6,$24,$57,$47,$97
 dc.b	$33,$5d,$58,$00,$43,$0d,$2d,$20,$53,$1c,$3f,$1d,$3f,$00,$00,$93
 dc.b	$6d,$6e,$2f,$6d,$6e,$6e,$6d,$20,$c3,$32,$00,$d3,$64,$04,$07,$e3
 dc.b	$66,$65,$76,$f2,$70,$e7,$f1,$70,$16,$e0,$67,$68,$80,$d0,$04,$64
 dc.b	$a0,$c0,$70,$9f,$70,$70,$70,$c2,$00,$64,$64,$2b,$00,$8d,$20,$87
 dc.b	$10,$17,$16,$d6,$01,$1a,$1b,$4c,$02,$60,$03,$00,$9f,$00,$35,$df
 dc.b	$e0,$00,$e1,$e2,$2b,$38,$40,$0d,$03,$4c,$47,$0e,$7d,$7c,$96,$1f
 dc.b	$7e,$7f,$00,$2f,$4c,$03,$20,$3f,$33,$9f,$33,$33,$15,$1e,$1f,$22
 dc.b	$44,$64,$5e,$0d,$df,$07,$ef,$17,$16,$76,$fe,$00,$e7,$fd,$00,$16
 dc.b	$ec,$1a,$1b,$8c,$dc,$04,$04,$48,$48,$09,$07,$03,$62,$06,$55,$07
 dc.b	$50,$14,$43,$3d,$e4,$41,$d8,$2d,$5a,$2e,$50,$2f,$c6,$04,$0d,$26
 dc.b	$33,$34,$35,$36


O3316					* High Jump

 dc.b	52
 dc.b	29
 dc.b	29
 dc.b	4

 dc.b	$40,$06

 dc.b	$20,$3f,$00,$9f,$00,$3b
 dc.b	$25,$4d,$3e,$26,$64,$64,$2b,$0d,$df,$07,$ef,$17,$16,$56,$fe,$1a
 dc.b	$1b,$cc,$fd,$e0,$fc,$00,$5f,$00,$00,$00,$00,$00,$cd,$f6,$c3,$f5
 dc.b	$17,$16,$34,$e4,$00,$aa,$d3,$00,$aa,$c2,$00,$a4,$b1,$00,$11,$a0
 dc.b	$18,$19,$8c,$90,$a0,$80,$00,$5f,$00,$00,$00,$00,$00,$8d,$20,$87
 dc.b	$10,$17,$16,$d6,$01,$1a,$1b,$4c,$02,$60,$03,$00,$9f,$3a,$7a,$36
 dc.b	$00,$b7,$00,$3d,$27,$43,$4d,$0d,$47,$0e,$17,$16,$96,$1f,$1a,$1b
 dc.b	$0c,$2f,$06,$06,$2c,$2a,$06,$0e,$27,$d3,$28,$ce,$02,$d3,$17,$55
 dc.b	$16,$52,$15,$52,$1e,$1f,$20,$21,$22,$25,$26,$27,$28,$29,$2a,$2b
 dc.b	$2c,$2d


O3458					* Roller Coaster

 dc.b	78
 dc.b	0
 dc.b	0
 dc.b	37

 dc.b	$00,$05

 dc.b	$a0,$cf,$38,$9f,$01,$82,$82,$82
 dc.b	$82,$82,$07,$4a,$00,$8c,$2f,$86,$1f,$16,$17,$57,$0e,$1b,$1a,$cd
 dc.b	$0d,$e0,$0c,$19,$9f,$08,$0f,$f5,$f5,$f5,$f5,$6c,$74,$5c,$c0,$02
 dc.b	$2d,$0d,$c6,$01,$57,$47,$97,$10,$5d,$58,$00,$20,$0d,$2d,$20,$30
 dc.b	$1c,$9f,$1d,$1e,$1f,$22,$27,$27,$27,$43,$38,$00,$d0,$4c,$03,$06
 dc.b	$e0,$05,$06,$f7,$f1,$34,$66,$f2,$41,$17,$e3,$12,$14,$80,$d3,$64
 dc.b	$04,$a0,$c3,$70,$7f,$4b,$35,$33,$33,$33,$33,$33,$80,$43,$03,$4c
 dc.b	$87,$33,$06,$05,$f6,$24,$34,$67,$25,$00,$96,$36,$1a,$1b,$0c,$46
 dc.b	$20,$56,$00,$7f,$23,$5b,$70,$70,$70,$70,$70,$00,$d6,$04,$64,$06
 dc.b	$e6,$65,$66,$d7,$f7,$68,$67,$40,$f8,$64,$04,$60,$f9,$2b,$3f,$00
 dc.b	$00,$00,$4c,$fd,$46,$fe,$16,$17,$17,$ef,$1b,$1a,$8d,$df,$03,$03
 dc.b	$50,$59,$07,$00,$06,$2a,$07,$29,$0e,$36,$1a,$54,$1b,$4a,$4d,$52
 dc.b	$4c,$5a,$fe,$04,$bd,$ff,$04,$84,$0b,$85,$0c,$20,$77,$98,$4c,$a3
 dc.b	$8b,$a5,$26,$38,$e9,$0f,$85,$26,$a4,$1b,$84,$0a,$20,$97,$8a,$c9
 dc.b	$2c,$d0,$3e,$4c,$95,$b6,$20,$54,$b3,$a5,$26,$18,$69,$f4,$85,$4b
 dc.b	$a9,$05,$85,$4c,$20,$00,$a5,$a5,$2a,$85,$37,$a5,$2b,$85,$38,$20
 dc.b	$e9,$b4,$a5,$26,$85,$27,$18,$69,$f9,$85,$4b,$a9,$05,$85,$4c,$20
 dc.b	$5f,$9a,$f0,$ad,$bd,$f5,$04,$30,$04,$b0,$a6,$90,$b4,$90,$a2,$b0
 dc.b	$b0,$4c,$96,$8b,$00,$22,$e3,$20,$76,$61


DAT.1fe2c
	dc.b	$07,$07,$07,$07,$07,$07,$07,$07
	dc.b	$41,$3a,$3e,$41,$48,$51,$48,$4f
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$48,$41,$45,$48,$4f,$58,$4f,$56
	dc.b	$07,$03,$03,$03,$03,$03,$07,$03
	dc.b	$66,$57,$57,$59,$59,$69,$62,$64
	dc.b	$07,$03,$03,$03,$03,$01,$03,$03
	dc.b	$61,$55,$53,$56,$58,$5b,$5a,$62


league.values
* Standard league
	dc.b	$48,$00
	dc.b	$f0,$00			engine.power
	dc.b	$ec,$00			opponents.engine.power
	dc.b	16			boost.unit.value
	dc.b	$60,$5b
	dc.b	0			road.cushion.value
	dc.b	0
* Super league
	dc.b	$54,$0c
	dc.b	$40,$01
	dc.b	$3a,$01
	dc.b	12
	dc.b	$6e,$69
	dc.b	1
	dc.b	0


font7	dc.b	$00,$00,$00,$00,$00,$00,$00,$00		chars. 32 to 126
	dc.b	$95,$95,$95,$95,$aa,$ea,$ea,$ea
	dc.b	$15,$15,$15,$15,$15,$6a,$6a,$6a
	dc.b	$75,$c3,$00,$00,$00,$00,$80,$80
	dc.b	$40,$40,$c0,$00,$00,$80,$80,$80
	dc.b	$55,$55,$55,$55,$55,$aa,$aa,$aa
	dc.b	$55,$55,$55,$55,$55,$aa,$aa,$aa
	dc.b	$bd,$ff,$c3,$c0,$c3,$f3,$bf,$bf
	dc.b	$00,$00,$c0,$c0,$c0,$c0,$40,$40
	dc.b	$ff,$80,$80,$80,$80,$80,$80,$80
	dc.b	$80,$80,$80,$80,$80,$80,$80,$ff
	dc.b	$08,$08,$08,$7f,$08,$08,$08,$00
	dc.b	$01,$01,$01,$01,$01,$01,$01,$ff
	dc.b	$00,$00,$00,$7f,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$18,$18,$00
	dc.b	$00,$02,$04,$08,$10,$20,$40,$00
	dc.b	$00,$3c,$42,$42,$42,$42,$3c,$00
	dc.b	$00,$10,$30,$10,$10,$10,$38,$00
	dc.b	$00,$3c,$42,$0c,$30,$40,$7e,$00
	dc.b	$00,$7e,$04,$0c,$02,$42,$3c,$00
	dc.b	$00,$04,$0c,$14,$24,$7e,$04,$00
	dc.b	$00,$7e,$40,$7c,$02,$02,$7c,$00
	dc.b	$00,$3c,$40,$7c,$42,$42,$3c,$00
	dc.b	$00,$7e,$04,$08,$10,$20,$20,$00
	dc.b	$00,$3c,$42,$3c,$42,$42,$3c,$00
	dc.b	$00,$3c,$42,$3c,$04,$08,$10,$00
	dc.b	$00,$00,$10,$00,$00,$10,$00,$00
	dc.b	$00,$00,$10,$00,$00,$10,$20,$00
	dc.b	$18,$18,$18,$18,$18,$00,$18,$00
	dc.b	$00,$00,$7e,$00,$7e,$00,$00,$00
	dc.b	$30,$18,$0c,$06,$0c,$18,$30,$00
	dc.b	$00,$38,$44,$04,$08,$10,$00,$10
	dc.b	$3c,$66,$6e,$6a,$6e,$60,$3c,$00
	dc.b	$00,$3c,$42,$42,$7e,$42,$42,$00
	dc.b	$00,$78,$44,$7c,$42,$42,$7c,$00
	dc.b	$00,$3c,$42,$40,$40,$42,$3c,$00
	dc.b	$00,$7c,$42,$42,$42,$42,$7c,$00
	dc.b	$00,$7e,$40,$78,$40,$40,$7e,$00
	dc.b	$00,$7e,$40,$78,$40,$40,$40,$00
	dc.b	$00,$3c,$42,$40,$4e,$42,$3e,$00
	dc.b	$00,$42,$42,$7e,$42,$42,$42,$00
	dc.b	$00,$38,$10,$10,$10,$10,$38,$00
	dc.b	$00,$04,$04,$04,$04,$44,$38,$00
	dc.b	$00,$44,$48,$70,$48,$44,$42,$00
	dc.b	$00,$20,$20,$20,$20,$20,$3e,$00
	dc.b	$00,$42,$66,$5a,$42,$42,$42,$00
	dc.b	$00,$42,$62,$52,$4a,$46,$42,$00
	dc.b	$00,$3c,$42,$42,$42,$42,$3c,$00
	dc.b	$00,$7c,$42,$7c,$40,$40,$40,$00
	dc.b	$00,$3c,$42,$42,$42,$42,$3c,$06
	dc.b	$00,$7c,$42,$7c,$48,$44,$42,$00
	dc.b	$00,$3e,$40,$3c,$02,$02,$7c,$00
	dc.b	$00,$7c,$10,$10,$10,$10,$10,$00
	dc.b	$00,$42,$42,$42,$42,$42,$3e,$00
	dc.b	$00,$42,$42,$42,$42,$24,$18,$00
	dc.b	$00,$42,$42,$42,$5a,$66,$42,$00
	dc.b	$00,$42,$24,$18,$18,$24,$42,$00
	dc.b	$00,$44,$44,$28,$10,$10,$10,$00
	dc.b	$00,$7e,$04,$08,$10,$20,$7e,$00
	dc.b	$01,$00,$00,$00,$00,$00,$00,$ff
	dc.b	$80,$00,$00,$00,$00,$00,$00,$ff
	dc.b	$00,$00,$00,$ff,$00,$00,$00,$01
	dc.b	$00,$00,$00,$ff,$00,$00,$00,$80
	dc.b	$01,$00,$00,$00,$00,$00,$00,$01
	dc.b	$00,$00,$00,$ff,$00,$00,$00,$ff
	dc.b	$00,$00,$3c,$02,$3e,$42,$3e,$00
	dc.b	$00,$40,$7c,$42,$42,$42,$7c,$00
	dc.b	$00,$00,$3e,$40,$40,$40,$3e,$00
	dc.b	$00,$02,$3e,$42,$42,$42,$3e,$00
	dc.b	$00,$00,$3c,$42,$7e,$40,$3c,$00
	dc.b	$00,$1c,$22,$20,$78,$20,$20,$00
	dc.b	$00,$00,$3e,$42,$42,$3e,$02,$3c
	dc.b	$00,$40,$40,$7c,$42,$42,$42,$00
	dc.b	$10,$00,$30,$10,$10,$10,$38,$00
	dc.b	$00,$08,$00,$08,$08,$08,$48,$30
	dc.b	$00,$20,$20,$24,$38,$24,$22,$00
	dc.b	$00,$30,$10,$10,$10,$10,$38,$00
	dc.b	$00,$00,$24,$5a,$5a,$42,$42,$00
	dc.b	$00,$00,$7c,$42,$42,$42,$42,$00
	dc.b	$00,$00,$3c,$42,$42,$42,$3c,$00
	dc.b	$00,$00,$7c,$42,$42,$7c,$40,$40
	dc.b	$00,$00,$3e,$42,$42,$3e,$02,$02
	dc.b	$00,$00,$5c,$62,$40,$40,$40,$00
	dc.b	$00,$00,$3e,$60,$3c,$06,$7c,$00
	dc.b	$00,$20,$7c,$20,$20,$24,$18,$00
	dc.b	$00,$00,$42,$42,$42,$42,$3e,$00
	dc.b	$00,$00,$42,$42,$42,$24,$18,$00
	dc.b	$00,$00,$42,$42,$5a,$5a,$24,$00
	dc.b	$00,$00,$42,$24,$18,$24,$42,$00
	dc.b	$00,$00,$42,$42,$42,$3e,$02,$3c
	dc.b	$00,$00,$7e,$04,$18,$20,$7e,$00
	dc.b	$00,$00,$00,$ff,$00,$00,$00,$81
	dc.b	$81,$81,$81,$81,$81,$81,$81,$81
	dc.b	$81,$00,$00,$00,$00,$00,$00,$81
	dc.b	$ff,$00,$00,$00,$00,$00,$00,$ff


TAB.2017a
	dc.b	$30,$18,$0c,$06,$0c,$18,$30,$00,$80,$00


	section	pictures,code


car.colours
	dc.w	$000,$443,$554,$770,$451,$233,$257,$247
	dc.w	$123,$200,$311,$422,$644,$332,$555,$777

car.crunched	incbin	graphics_data/car.crunched.bin


title.colours
	dc.w	$000,$777,$555,$222,$000,$743,$632,$421
	dc.w	$310,$240,$021,$046,$025,$710,$500,$740

title.crunched	incbin	graphics_data/title.crunched.bin


preview.colours
	dc.w	$022,$443,$554,$770,$123,$222,$030,$247
	dc.w	$000,$200,$311,$050,$555,$332,$333,$777

preview.crunched	incbin	graphics_data/preview.crunched.bin


hallfame.colours
	dc.w	$000,$221,$332,$443,$034,$110,$030,$770
	dc.w	$000,$200,$311,$070,$555,$221,$333,$777

hallfame.crunched	incbin	graphics_data/hallfame.crunched.bin


people.colours
	dc.w	$222,$777,$555,$222,$000,$743,$632,$421
	dc.w	$310,$240,$030,$035,$025,$710,$500,$740

people.crunched	incbin	graphics_data/people.crunched.bin


wreck.colours
	dc.w	$000,$777,$555,$222,$000,$743,$632,$421
	dc.w	$310,$230,$021,$046,$025,$710,$500,$740

wreck.crunched	incbin	graphics_data/wreck.crunched.bin


won.colours
	dc.w	$000,$777,$555,$222,$000,$743,$632,$421
	dc.w	$310,$230,$021,$046,$025,$710,$500,$740

won.crunched	incbin	graphics_data/won.crunched.bin


lost.colours
	dc.w	$000,$777,$555,$222,$000,$743,$632,$421
	dc.w	$310,$230,$021,$046,$025,$710,$500,$740

lost.crunched	incbin	graphics_data/lost.crunched.bin


promotion.colours
	dc.w	$000,$777,$555,$222,$000,$743,$632,$421
	dc.w	$310,$230,$021,$046,$025,$710,$500,$740

promotion.crunched	incbin	graphics_data/promotion.crunched.bin


TAB.56ffc
	dc.l	won.colours-2
	dc.l	lost.colours-2
	dc.l	wreck.colours-2
	dc.l	promotion.colours-2


	section	restofcode,code_c


****************************************


add.and.transmit.byte
	andi.w	#$ff,d0
	add.w	d0,transmit.byte.total
	addq.w	#1,transmit.byte.total
	jsr	transmit.byte.when.ready
	clr.w	d1
	clr.w	d2
	rts


****************************************


add.and.transmit.word
	move.w	d0,-(sp)
	lsr.w	#8,d0
	jsr	add.and.transmit.byte	high byte
	move.w	(sp)+,d0
	jmp	add.and.transmit.byte	low byte


****************************************


received.byte.ready
	jmp	compare.received.bytes


****************************************


receive.byte.F5.exit
	jsr	received.byte.ready
	bne	add.received.byte

	jsr	test.key.F5
	bne	receive.byte.F5.exit

	move.b	#0,d0
	rts


****************************************


add.received.byte
	jsr	get.next.received.byte
	andi.w	#$ff,d0
	add.w	d0,receive.byte.total
	addq.w	#1,receive.byte.total
	addq.w	#1,W.57c44
	clr.w	d1
	clr.w	d2
	rts


****************************************


add.received.word
	jsr	receive.byte.F5.exit
	move.w	d0,-(sp)
	jsr	receive.byte.F5.exit
	move.b	d0,d3
	move.w	(sp)+,d0
	asl.w	#8,d0
	move.b	d3,d0
	rts


****************************************


retry.receive.byte.1000.times
	move.w	#1000,retry.receive.count
	bra	retry.receive

retry.receive.byte.3.times
	move.w	#3,retry.receive.count

retry.receive
	jsr	received.byte.ready
	bne	add.and.return

	jsr	delay.1ms
	subq.w	#1,retry.receive.count
	bne	retry.receive

	move.b	#0,d0
	ori.b	#1,ccr
	rts

add.and.return
	jsr	add.received.byte
	andi.b	#%11110,ccr
	rts


****************************************


flush.received.bytes
	jsr	received.byte.ready
	beq	.return

	jsr	add.received.byte
	bra	flush.received.bytes
.return	rts


****************************************


initialise.flush.serial
	jsr	initialise.serial
	clr.w	d1
	clr.w	d2
	jsr	flush.received.bytes
	rts


****************************************


data.link.test.key
	tst.b	machine
	bne	dltk1
	jmp	test.key

dltk1	tst.b	d0
	beq	dltk2

	move.b	#0,d0
	rts

dltk2	move.b	#$ff,d0
	rts


****************************************


delay.200ms
	jsr	delay.100ms

delay.100ms
	jsr	delay.10ms
	jsr	delay.30ms

delay.60ms
	jsr	delay.20ms
	jsr	delay.10ms

delay.30ms
	jsr	delay.10ms

delay.20ms
	jsr	delay.10ms

delay.10ms
	move.w	d0,-(sp)
	move.w	#7070,d0
	bra	timer.delay

delay.5ms
	jsr	delay.1ms
	jsr	delay.2ms
delay.2ms
	move.w	d0,-(sp)
	move.w	#1414,d0
	bra	timer.delay

delay.1ms
	move.w	d0,-(sp)
	move.w	#707,d0

timer.delay
	move.l	a0,-(sp)
	lea	CIAA,a0
	move.b	#$80,CIAA.timer.B.countdown

	move.b	#%00001000,CRB(a0)
	move.b	#%10000010,ICR(a0)
	move.b	d0,TBLO(a0)
	lsr.w	#8,d0
	move.b	d0,TBHI(a0)

wait.timeout
	tst.b	CIAA.timer.B.countdown
	bne	wait.timeout

	move.l	(sp)+,a0
	move.w	(sp)+,d0
	rts

CIAA.timer.B.countdown
	dc.b	0,0


****************************************


R.571aa	cmpi.b	#$40,d0
	beq	.label1
	cmpi.b	#$80,d0
	bne	.label3

.label1	tst.b	d3
	beq	.label2
	cmp.b	d0,d3
	beq	.label3
	move.b	#$80,d0

.label2	move.b	d0,d3
.label3	rts


R.571ce	move.b	#0,B.57c3a
	clr.w	transmit.byte.total
	move.b	players.road.section,d0
	jsr	add.and.transmit.byte
	move.w	players.distance.into.section,d0
	jsr	add.and.transmit.word
	move.w	players.world.y.speed,d0
	asr.w	#1,d0
	add.w	average.amount.below.road,d0
	asr.w	#3,d0
	bpl	.label1
	clr.w	d0

.label1	move.w	d0,W.57c70

	move.l	front.left.actual.height,d0
	asr.l	#3,d0
	add.w	W.57c70,d0
	bpl	.label2
	clr.w	d0

.label2	move.l	front.right.actual.height,d3
	asr.l	#3,d3
	add.w	W.57c70,d3
	bpl	.label3
	clr.w	d3

.label3	move.l	rear.actual.height,d4
	asr.l	#3,d4
	add.w	W.57c70,d4
	bpl	.label4
	clr.w	d4

.label4	move.w	d0,d7
	add.w	d3,d7
	lsr.w	#1,d7
	sub.w	d0,d3
	asr.w	#1,d3
	move.w	d4,d5
	sub.w	d3,d5
	move.w	d4,d6
	add.w	d3,d6
	move.w	#$8765,d0
	jsr	add.and.transmit.word
	move.w	d5,d0
	jsr	add.and.transmit.word
	move.w	d6,d0
	jsr	add.and.transmit.word
	move.w	d7,d0
	jsr	add.and.transmit.word
	move.w	players.z.speed,d0
	jsr	add.and.transmit.word
	move.w	players.road.x.position,d0
	tst.b	plus.180.degrees
	bpl	.label5
	neg.w	d0
	addi.w	#384,d0

.label5	move.w	d0,d0
	jsr	add.and.transmit.word
	cmpi.b	#$40,B.1bba5
	beq	.label7
	cmpi.b	#$80,B.1bba5
	beq	.label7
	move.b	#0,d4
	move.b	#25,d1
	jsr	test.key
	bne	.label6
	move.b	machine,d4

.label6	move.b	d4,B.1bba5

.label7	move.b	B.1bba5,d0
	jsr	add.and.transmit.byte
	cmpi.b	#$40,B.1bb64
	beq	.label9
	cmpi.b	#$80,B.1bb64
	beq	.label9
	move.b	#0,d4
	move.b	#69,d1
	jsr	test.key
	bne	.label8
	move.b	machine,d4

.label8	move.b	d4,B.1bb64

.label9	move.b	B.1bb64,d0
	jsr	add.and.transmit.byte
	move.b	B.1bb6c,d0
	jsr	add.and.transmit.byte
	move.b	B.1bbe2,d0
	jsr	add.and.transmit.byte
	move.b	car.on.chains.countdown,d0
	jsr	add.and.transmit.byte
	move.b	damage.hole.position,d0
	tst.b	car.on.chains.countdown
	beq	.labela
	bset	#7,d0

.labela	tst.b	swing.from.left
	bpl	.labelb
	bset	#6,d0

.labelb	move.b	d0,d0
	jsr	add.and.transmit.byte
	move.b	B.57c6b,d0
	jsr	add.and.transmit.byte
	move.b	B.57c6c,d0
	jsr	add.and.transmit.byte
	move.b	B.57c6d,d0
	jsr	add.and.transmit.byte
	move.b	B.1bbcc,d0
	jsr	add.and.transmit.byte
	move.b	B.1bbc9,d0
	jsr	add.and.transmit.byte
	move.w	transmit.byte.total,d0
	jsr	add.and.transmit.word
	tst.b	B.57c6e
	bne	.labeld
	move.b	opponents.road.section,B.57c6a
	move.w	opponents.distance.into.section,W.57c76
	tst.b	B.57c6e
	bne	.labeld
	clr.w	receive.byte.total
	jsr	receive.byte.F5.exit
	move.b	d0,opponents.road.section
	jsr	add.received.word
	move.w	d0,opponents.distance.into.section
	tst.b	race.mode
	bpl	.labelc
	move.b	opponents.road.section,d0
	cmp.b	number.of.road.sections,d0
	bcc	.labeld
	move.w	#255,d0
	jsr	calculate.section.position
.labelc	rts

.labeld	move.b	#$80,B.57c3a
	clr.b	B.57c6e
	rts


R.57440	tst.b	B.57c3a
	bne	.label8

	move.b	B.1bba5,B.57c50
	move.b	B.1bb64,B.57c51
	move.b	B.1bbe2,B.57c52
	move.b	B.1bb6c,B.57c53
	move.b	car.on.chains.countdown,B.57c54
	jsr	add.received.word
	move.w	d0,d0
	cmpi.w	#$8765,d0
	bne	.label8

	tst.b	B.57c3a
	bne	.label8

	jsr	add.received.word
	move.w	d0,W.57c46
	jsr	add.received.word
	move.w	d0,W.57c48
	jsr	add.received.word
	move.w	d0,W.57c4a
	move.w	#0,opp.smallest.difference
	jsr	add.received.word
	move.w	d0,W.57c4c
	jsr	add.received.word
	move.w	d0,d0
	move.w	#21845,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.w	d0,W.57c4e
	jsr	receive.byte.F5.exit
	move.b	d0,d0
	move.b	B.57c50,d3
	jsr	R.571aa
	move.b	d3,B.57c50
	jsr	receive.byte.F5.exit
	move.b	d0,d0
	move.b	B.57c51,d3
	jsr	R.571aa
	move.b	d3,B.57c51
	jsr	receive.byte.F5.exit
	move.b	d0,d0
	tst.b	d0
	beq	.label3
	bmi	.label2
	tst.b	B.57c53
	beq	.label2
	cmp.b	B.57c53,d0
	bcc	.label3

.label2	move.b	d0,B.57c53

.label3	jsr	receive.byte.F5.exit
	move.b	d0,d0
	move.b	B.57c52,d3
	jsr	R.571aa
	move.b	d3,B.57c52
	jsr	receive.byte.F5.exit
	move.b	d0,d0
	tst.b	drop.start.done
	bmi	.label4
	tst.b	machine
	bmi	.label4
	cmpi.b	#$e4,B.57c54
	bcc	.label4
	cmpi.b	#$e4,d0
	bcc	.label4
	move.b	d0,B.57c54

.label4	jsr	receive.byte.F5.exit
	move.b	d0,B.57c55
	jsr	receive.byte.F5.exit
	move.b	d0,B.57c56
	jsr	receive.byte.F5.exit
	move.b	d0,B.57c57
	jsr	receive.byte.F5.exit
	move.b	d0,B.57c58
	jsr	receive.byte.F5.exit
	move.b	d0,B.57c59
	jsr	receive.byte.F5.exit
	move.b	d0,B.57c5a
	move.w	receive.byte.total,W.57c42
	jsr	add.received.word
	move.w	d0,d0
	cmp.w	W.57c42,d0
	bne	.label8
	jsr	flush.received.bytes
	move.l	W.57c46,opp.rear.left.actual.height
	move.w	W.57c4a,opp.front.actual.height
	move.w	W.57c4c,opponents.z.speed
	move.w	W.57c4e,opponents.road.x.position
	move.b	B.57c50,B.1bba5
	move.b	B.57c51,B.1bb64
	move.b	B.57c52,B.1bbe2
	move.b	B.57c53,B.1bb6c
	move.b	B.57c54,car.on.chains.countdown
	move.b	B.57c55,d0
	move.b	d0,B.1bbe0
	andi.b	#$f,d0
	move.b	d0,B.57c61
	move.b	B.57c56,DAT.1c908+1
	move.b	B.57c57,DAT.1c920+1
	move.b	B.57c58,DAT.1c938+1
	move.b	B.57c59,B.1bb76
	move.b	B.57c5a,d0
	sub.b	B.1bbc9,d0
	bpl	.label5
	jsr	delay.100ms
	jsr	R.571ce
	jsr	delay.30ms
	bra	R.57440

.label5	beq	.label6
	move.b	#$80,B.57c6e

.label6	tst.b	race.mode
	bpl	.label7
	jsr	R.641b6
	jsr	calculate.distances.between.players
	jsr	opponent.player.interaction
	jsr	calculate.opponents.road.wheel.positions

.label7	rts

.label8	jsr	received.byte.ready
	beq	.label9
	jsr	R.5773a
	jsr	flush.received.bytes

.label9	move.b	B.57c6a,opponents.road.section
	move.w	W.57c76,opponents.distance.into.section
	tst.b	B.1bb76
	beq	.labela
	subq.b	#1,B.1bb76

.labela	move.b	#$80,B.57c3a
	move.w	#-1,opponents.offset
	rts


R.5773a	jsr	R.5786c
	bcs	.label5

	move.b	B.57c5d,d4
	tst.b	B.57c5c
	bne	.label2
	btst	#0,d4
	beq	.label1
	move.b	machine,d0
	eori.b	#$c0,d0
	move.b	d0,B.1bba5

.label1	rts

.label2	btst	#4,B.57c5c
	bne	.label5
	btst	#5,d4
	beq	.label3
	move.b	d4,d0
	andi.b	#$c0,d0
	eori.b	#$c0,d0
	move.b	d0,B.1bbb4
	move.b	#$80,B.1bb6f
	move.b	#5,laps.when.race.finished
	move.b	#0,B.1bbe2
	move.b	#0,B.1bb64
	move.b	#0,B.1bba5
	rts

.label3	btst	#4,d4
	beq	.label4
	move.b	machine,d0
	eori.b	#$c0,d0
	move.b	d0,B.1bb64
	rts

.label4	btst	#3,d4
	beq	.label5
	move.b	machine,d0
	eori.b	#$c0,d0
	move.b	d0,B.1bbe2
	move.b	#$80,B.1bb6f
	rts

.label5	rts


****************************************


R.577fa	clr.w	transmit.byte.total

* Transmit $125634

	move.w	#$1256,d0
	jsr	add.and.transmit.word

	move.b	#$34,d0
	jsr	add.and.transmit.byte

* Transmit info bytes

	move.b	B.57c63,d0
	jsr	add.and.transmit.byte

	move.b	B.57c62,d0
	jsr	add.and.transmit.byte

	move.b	B.57c66,d0
	jsr	add.and.transmit.byte

	move.b	B.57c64,d0
	jsr	add.and.transmit.byte

	move.b	B.57c65,d0
	jsr	add.and.transmit.byte

	move.w	transmit.byte.total,d0
	move.b	d0,d0
	jsr	add.and.transmit.byte

	jsr	delay.10ms
	jsr	delay.5ms
	rts


****************************************


R.5786c	move.w	d7,-(sp)
	move.w	#8,d7

* Receive $125634

.label2	clr.w	receive.byte.total

	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,d0
	cmpi.b	#$12,d0
	bne	.label3

	subq.w	#1,d7
	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,d0
	cmpi.b	#$56,d0
	bne	.label3

	subq.w	#1,d7
	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,d0
	cmpi.b	#$34,d0
	bne	.label3

* Receive info bytes

	subq.w	#1,d7
	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,B.57c5d

	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,B.57c5c

	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,B.57c60

	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,B.57c5e

	jsr	retry.receive.byte.3.times
	bcs	.label3
	move.b	d0,B.57c5f

	move.w	receive.byte.total,W.57c42

	jsr	receive.byte.F5.exit
	move.b	d0,d0
	move.w	W.57c42,d3
	cmp.b	d3,d0			check received bytes total
	bne	.label3

	move.w	(sp)+,d7
	jsr	delay.2ms
	jsr	received.byte.ready
	bne	R.5786c

	andi.b	#%11110,ccr
	rts

.label3	subq.w	#1,d7
	bpl	.label2

	move.w	(sp)+,d7
	jsr	delay.1ms
	jsr	delay.1ms
	jsr	received.byte.ready
	bne	R.5786c

	ori.b	#1,ccr
	rts


****************************************


R.57964	tst.b	machine
	beq	.label4

	move.b	#0,d0
	tst.b	laps.when.race.finished
	beq	.label1
	move.b	B.1bbb4,d0
	ori.b	#$20,d0

.label1	tst.b	B.1bb64
	beq	.label2
	ori.b	#$10,d0

.label2	move.b	B.1bbe2,d3
	cmp.b	machine,d3
	bne	.label3
	ori.b	#8,d0

.label3	move.b	d0,B.57c63
.label4	rts


****************************************


R.579b0	tst.b	machine
	beq	.label7

	jsr	flush.received.bytes

	tst.b	machine
	bmi	.master

.slave	jsr	test.key.F5
	beq	.label8

	jsr	R.577fa
	jsr	R.5786c
	bcs	.slave

	move.b	B.57c64,d0
	cmp.b	B.57c5e,d0
	beq	.label2

	cmpi.b	#$88,B.57c5e
	bne	.slave

	cmpi.b	#$c1,B.57c64
	bne	.slave
	bra	.label8

.label2	move.b	#$aa,B.57c64

.label3	jsr	test.key.F5
	beq	.label8

	jsr	R.577fa
	jsr	R.5786c
	bcc	.label3

	move.w	#30-1,d7
.label4	jsr	received.byte.ready
	bne	.label3

	jsr	delay.1ms
	dbra	d7,.label4
	bra	.label7

.master	jsr	test.key.F5
	beq	.label8

	jsr	R.577fa
	jsr	R.5786c
	bcs	.master

	move.b	B.57c5e,d0
	cmpi.b	#$aa,d0
	beq	.label6

	cmp.b	B.57c64,d0
	beq	.master

	tst.b	d0
	bpl	.master

	cmpi.b	#$e3,B.57c64
	beq	.label6

	cmpi.b	#$88,B.57c5e
	bne	.master

	cmpi.b	#$c1,B.57c64
	bne	.master
	bra	.label8

.label6	jsr	delay.100ms

.label7	andi.b	#%11110,ccr
	rts

.label8	ori.b	#1,ccr
	rts


****************************************


R.57ac0	move.b	d0,players.input
	move.b	#$80,B.57c6f
	tst.b	B.57c5b
	bpl	.label4
	tst.b	machine
	bpl	.label3
	move.w	#3,d2

.label1	move.l	#control.keys+5,a0
	move.b	(a0,d2.w),d1
	jsr	test.key
	bne	.label2
	move.b	d2,B.57c6f

.label2	subq.b	#1,d2
	bpl	.label1
	move.b	B.57c6f,B.57c65

.label3	move.b	players.input,B.57c66
	move.b	#$e3,B.57c64
	jsr	R.579b0
	bcs	.label4
	cmpi.b	#SLAVE,machine
	bne	.label4
	move.b	B.57c60,players.input
	move.b	B.57c5f,B.57c6f

.label4	move.b	#0,B.57c64
	move.b	players.input,d0
	rts


R.57b5c	move.b	B.57c6f,d0
	bmi	.label1

	move.b	B.1bb8d,d3
	addq.b	#1,d3
	cmp.b	d3,d0
	bgt	.label1

	move.b	B.57c6f,map.z.shift
	rts

.label1	move.b	#$80,d0
	rts


****************************************


unpause.request
	tst.b	machine
	beq	ur3

	move.b	#1,B.57c63
	move.b	#$f1,B.57c64
	jsr	R.579b0
	bcs	ur4

ur1	jsr	R.5f98a

	move.b	#$18,d1			O
	jsr	test.key
	beq	ur2

	jsr	test.key.F5
	beq	ur4

	jsr	R.577fa
	jsr	R.5786c
	bcs	ur1

	cmpi.b	#$f2,B.57c5e
	bne	ur1

ur2	move.b	#$f2,B.57c64
	jsr	R.579b0
	bra	ur4

ur3	jsr	R.5f98a			re-define keys

	move.b	#$18,d1			O
	jsr	test.key
	bne	ur3

ur4	move.b	#0,B.57c63
	move.b	#0,B.1bba5
	rts


****************************************


test.key.F5
	move.w	d1,W.57c38

	move.w	#$54,d1			F5
	jsr	test.key

	move.w	sr,-(sp)
	move.w	W.57c38,d1
	move.w	(sp)+,sr
	rts


****************************************


W.57c38	dc.w	0
B.57c3a	dc.b	0,0
machine	dc.b	0,0
transmit.byte.total	dc.w	0
receive.byte.total	dc.w	0
W.57c42	dc.w	0
W.57c44	dc.w	0
W.57c46	dc.w	0
W.57c48	dc.w	0
W.57c4a	dc.w	0
W.57c4c	dc.w	0
W.57c4e	dc.w	0
B.57c50	dc.b	0
B.57c51	dc.b	0
B.57c52	dc.b	0
B.57c53	dc.b	0
B.57c54	dc.b	0
B.57c55	dc.b	0
B.57c56	dc.b	0
B.57c57	dc.b	0
B.57c58	dc.b	0
B.57c59	dc.b	0
B.57c5a	dc.b	0
B.57c5b	dc.b	0

B.57c5c	dc.b	0			received info bytes
B.57c5d	dc.b	0
B.57c5e	dc.b	0
B.57c5f	dc.b	0
B.57c60	dc.b	0

B.57c61	dc.b	0

B.57c62	dc.b	0			transmitted info bytes
B.57c63	dc.b	0
B.57c64	dc.b	0
B.57c65	dc.b	0
B.57c66	dc.b	0

B.57c67	dc.b	0
B.57c68	dc.b	0
opponent.draw.flag	dc.b	0
B.57c6a	dc.b	0
B.57c6b	dc.b	0
B.57c6c	dc.b	0
B.57c6d	dc.b	0
B.57c6e	dc.b	0
B.57c6f	dc.b	0
W.57c70	dc.w	0
W.57c72	dc.w	0
retry.receive.count	dc.w	0
W.57c76	dc.w	0


****************************************


establish.computer.link
	jsr	initialise.flush.serial

	move.l	screen2,-(sp)
	move.l	screen1,screen2
	jsr	clear.menu

	move.b	#1,B.1bb16
	jsr	fill.bar

	jsr	flush.received.bytes
	jsr	delay.30ms
	jsr	received.byte.ready
	beq	no.byte.received

byte.received				* MASTER is transmitting
	jsr	add.received.byte	* so I must be SLAVE
	cmpi.b	#$80,d0
	bne	bad.link

	move.b	#SLAVE,machine
	move.w	#6-1,d7

reply.to.master
	move.b	#$40,d0
	jsr	add.and.transmit.byte
	jsr	delay.10ms
	dbra	d7,reply.to.master
	bra	good.link

no.byte.received			* nothing transmitted from other
	move.b	#MASTER,machine		* machine, so I must be MASTER
	move.w	#35,d3
	jsr	R.57dc2			'Linking'
	move.w	#6-1,d7

wait.for.slave
	move.b	#$45,d1			ESCAPE
	jsr	test.key
	beq	bad.link

	move.b	#$80,d0
	jsr	add.and.transmit.byte
	jsr	delay.10ms
	jsr	received.byte.ready
	beq	wait.for.slave

	subq.w	#1,d7
	bmi	bad.link

	jsr	add.received.byte
	cmpi.b	#$40,d0
	bne	wait.for.slave

good.link
	move.b	#1,B.1bb16
	jsr	fill.bar

	move.w	#18,d3
	jsr	R.57dc2			'Link complete'

	move.b	#$80,B.57c5b
	jsr	wait.for.fire

	move.l	(sp)+,screen2
	jsr	clear.print.fine.y

	tst.b	machine
	bmi	.master
	jsr	please.wait		display on SLAVE screen

.master	jsr	initial.link.communication
	andi.b	#%11110,ccr
	rts

bad.link
	move.b	#0,machine
	move.b	#1,B.1bb16
	jsr	fill.bar

	move.w	#0,d3
	jsr	R.57dc2			'Link abandoned'

	jsr	wait.for.fire
	move.l	(sp)+,screen2

	jsr	clear.print.fine.y
	ori.b	#1,ccr
	rts


****************************************


R.57dc2	move.l	#TEXT.57e00,a0
	move.l	screen2,-(sp)
	move.l	screen1,screen2
	jsr	R.57de6
	move.l	(sp)+,screen2
	rts


****************************************


R.57de6	move.b	(a0,d3.w),d0
	cmpi.b	#$ff,d0
	beq	.return

	jsr	print.character
	addq.w	#1,d3
	bra	R.57de6
.return	rts


****************************************


TEXT.57e00
	dc.b	31,14,16,'Link abandoned',255
	dc.b	31,14,16,'Link complete',255
	dc.b	31,17,16,'Linking',255
	dc.b	31,15,16,'Please wait',255
	dc.b	0


****************************************


initial.link.communication
	move.b	#0,B.1ca31
	move.b	#$40,B.1bb6b
	tst.b	machine
	bmi	master

.slave	jsr	test.key.F5
	beq	initial.link.done

	move.w	#193-1,d7
	move.l	#DAT.7a41a,a6
	jsr	receive.data.block
	bmi	.slave

	move.l	#DAT.7a41a,a6
	move.b	(a6)+,d0
	cmpi.b	#8,d0
	blt	.players.ok
	move.b	#1,d0
.players.ok
	move.b	d0,multi.no.of.players

	move.l	#opponents.names,a0
	move.w	#192-1,d7
.copy	move.b	(a6)+,(a0)+
	dbra	d7,.copy

	jsr	R.5837e
	jsr	delay.200ms
	jsr	R.58292
	bra	initial.link.done


computer.link.enter.another
	clr.b	d0
	move.b	#1,d2
	move.b	#20,d1
	jsr	get.main.menu.selection

	cmpi.b	#0,d0
	bne	computer.link.continue
	addq.b	#1,multi.no.of.players

master	jsr	get.players.name
	move.b	multi.no.of.players,d0
	cmpi.b	#7,d0
	bcs	computer.link.enter.another

computer.link.continue
	tst.b	multi.no.of.players
	beq	computer.link.enter.another

	jsr	please.wait		display on MASTER screen

	move.l	#DAT.7a41a,a6
	move.b	multi.no.of.players,(a6)+
	move.w	#192-1,d7
	move.l	#opponents.names,a0
.copy	move.b	(a0)+,(a6)+
	dbra	d7,.copy

transmit.names.to.slave
	jsr	test.key.F5
	beq	initial.link.done

	move.w	#193-1,d7
	move.l	#DAT.7a41a,a6
	jsr	transmit.data.block
	bmi	transmit.names.to.slave

	jsr	R.58292
	jsr	delay.200ms
	jsr	R.5837e

initial.link.done
	jsr	delay.60ms
	rts


****************************************


transmit.data.block

* Transmit $16d9a8

	move.w	#$16d9,d0
	jsr	add.and.transmit.word

	move.b	#$a8,d0
	jsr	add.and.transmit.byte

* Transmit data bytes

	clr.w	transmit.byte.total

tx.block
	move.b	(a6)+,d0
	jsr	add.and.transmit.byte
	dbra	d7,tx.block

	move.w	transmit.byte.total,d0
	jsr	add.and.transmit.word

	move.b	#$c1,B.57c64
	jsr	R.579b0
	bcs	tx.block.fail

tx.block.done
	move.b	B.57c5f,d0
	rts

tx.block.fail
	move.b	#$80,d0
	rts


****************************************


receive.data.block
	move.w	#0,W.57c44

rx.block.header.retry
	cmpi.w	#10,W.57c44
	blt	rx.block.header

	jsr	test.key.F5
	beq	rx.block.error

	move.b	#$88,B.57c64
	jsr	R.577fa
	clr.b	B.57c64
	clr.w	W.57c44

* Receive $16d9a8

rx.block.header
	jsr	receive.byte.F5.exit
	move.b	d0,d0
	cmpi.b	#$16,d0
	bne	rx.block.header.retry

	jsr	receive.byte.F5.exit
	move.b	d0,d0
	cmpi.b	#$d9,d0
	bne	rx.block.header.retry

	jsr	receive.byte.F5.exit
	move.b	d0,d0
	cmpi.b	#$a8,d0
	bne	rx.block.header.retry

* Receive data bytes

	clr.w	receive.byte.total

rx.block
	jsr	receive.byte.F5.exit
	move.b	d0,d0
	move.b	d0,(a6)+
	dbra	d7,rx.block

	move.w	receive.byte.total,W.57c42

	jsr	receive.byte.F5.exit
	move.b	d0,d5
	asl.w	#8,d5
	jsr	receive.byte.F5.exit
	move.b	d0,d5
	cmp.w	W.57c42,d5		check received bytes total
	bne	rx.block.error

	move.b	#$33,d0
	bra	rx.block.done

rx.block.error
	move.b	#$99,d0

rx.block.done
	move.b	d0,B.57c65

	move.w	d0,-(sp)
	move.b	#$c1,B.57c64
	jsr	R.579b0
	bcs	rx.block.fail

	move.w	(sp)+,d0
	tst.b	d0
	rts

rx.block.fail
	move.w	(sp)+,d0
	move.b	#$80,d0
	rts


****************************************


new.lap.sub1
	tst.b	machine
	beq	nls11

	cmpi.b	#1,d1
	bne	nls11

	cmpi.b	#1,opponents.lap
	beq	nls11

	move.b	players.lap,B.580d6
	move.b	B.5eb79,B.580d7

	move.b	opponents.lap,players.lap
	move.b	opponents.ID,B.5eb79
	jsr	new.lap.sub2

	move.b	B.580d6,players.lap
	move.b	B.580d7,B.5eb79
nls11	rts


B.580d6	dc.b	0
B.580d7	dc.b	0


R.580d8	move.l	#TAB.58146,a2
	move.l	#TAB.58146+8,a1
	move.l	#TAB.58146+16,a0
	move.w	W.57c72,d3
	clr.w	d0
	move.b	multi.no.of.players,d0
	clr.w	d5
	move.b	(a1,d0.w),d5
	clr.w	d2
	move.b	(a2,d0.w),d2
	lea	(a0,d2.w),a0

.label1	cmp.w	d5,d3
	blt	.label2
	sub.w	d5,d3
	bra	.label1

.label2	asl.w	#1,d3
	move.b	#11,d0
	sub.b	(a0,d3.w),d0
	move.b	#11,d1
	sub.b	1(a0,d3.w),d1
	tst.b	machine
	bmi	.label3
	exg	d0,d1

.label3	move.b	d0,B.1ca27
	move.b	d0,B.5eb79
	move.b	d1,B.1ca28
	rts


TAB.58146
 dc.b	$00,$02,$04,$0a,$16,$2a,$48,$72,$01,$01,$03,$06,$0a,$0f,$15,$1c
 dc.b	$00,$01,$00,$01,$00,$01,$00,$02,$01,$02,$00,$01,$02,$03,$00,$02
 dc.b	$01,$03,$00,$03,$02,$01,$00,$01,$02,$03,$04,$00,$01,$02,$03,$04
 dc.b	$00,$02,$01,$03,$04,$02,$00,$03,$01,$04,$00,$01,$02,$03,$04,$05
 dc.b	$01,$02,$00,$05,$03,$04,$00,$02,$03,$05,$01,$04,$00,$03,$04,$02
 dc.b	$05,$01,$00,$04,$01,$03,$02,$05,$00,$01,$02,$03,$04,$05,$06,$00
 dc.b	$01,$02,$03,$04,$05,$06,$00,$02,$01,$04,$03,$05,$06,$02,$00,$04
 dc.b	$01,$05,$03,$06,$02,$04,$00,$05,$01,$03,$06,$04,$00,$03,$01,$06
 dc.b	$02,$05,$00,$01,$02,$03,$04,$05,$06,$07,$00,$02,$01,$03,$04,$06
 dc.b	$05,$07,$00,$03,$01,$02,$04,$07,$05,$06,$00,$04,$03,$07,$01,$05
 dc.b	$02,$06,$00,$05,$01,$04,$02,$07,$03,$06,$00,$07,$01,$06,$02,$05
 dc.b	$03,$04,$00,$06,$01,$07,$02,$04,$03,$05


****************************************


please.wait
	move.l	screen2,-(sp)
	move.l	screen1,screen2
	jsr	clear.menu

	move.b	#1,B.1bb16
	jsr	fill.bar

	move.w	#46,d3
	jsr	R.57dc2			'Please wait'

	jsr	clear.print.fine.y
	move.l	(sp)+,screen2
	rts


****************************************


R.5823c	cmpi.b	#MASTER,machine
	bne	R.58292

	move.b	B.1ca31,d0
	ori.b	#$10,d0
	tst.b	invalid.key.flag
	bpl	.label1
	bset	#3,d0
.label1	move.b	d0,B.57c66

	move.b	B.1bb6b,B.57c65
	move.b	#$b2,B.57c64
	jsr	R.579b0
	tst.b	B.1ca31
	bne	return1
	tst.b	invalid.key.flag
	bne	return1

R.58292	jsr	test.key.F5
	beq	return1

	tst.b	B.1bb6b
	bne	.label3

	move.l	#B.1c9ce,a6
	move.w	#3-1,d7
	bra	.label4

.label3	move.b	#1,B.1ca31
	move.b	#1,d0
	jsr	R.5f374
	move.b	#0,B.1ca31
	move.l	#DAT.7a41a,a6
	move.w	#256-1,d7
	cmpi.b	#$40,B.1bb6b
	bne	.label4
	move.w	#512-1,d7

.label4	jsr	transmit.data.block
	bmi	R.58292

return1	rts


****************************************


R.582f4	move.b	#0,B.1bb94
	jsr	please.wait
	move.b	#$b2,B.57c64
	jsr	R.579b0
	jsr	test.key.F5
	beq	.label1

	move.b	B.57c5f,B.1bb6b
	move.b	B.57c60,d0
	bpl	.label3

	jsr	main.initialisation2
	move.b	B.57c60,d0
	cmpi.b	#$c0,d0
	bne	.label2

.label1	bra	R.5bb8c

.label2	bra	R.5bbb2

.label3	cmpi.b	#32,d0
	beq	R.5bae4

	btst	#4,d0
	beq	.label4
	btst	#3,d0
	bne	.label4
	btst	#0,d0
	bne	.label4
	move.b	#0,B.1ca31
	jsr	R.5837e

.label4	jmp	R.5bc90


****************************************


R.5837e	jsr	test.key.F5
	beq	.label4

	move.w	#3-1,d7
	move.l	#DAT.7a41a,a6
	tst.b	B.1bb6b
	beq	.label1

	move.w	#256-1,d7
	cmpi.b	#$40,B.1bb6b
	bne	.label1
	move.w	#512-1,d7

.label1	jsr	receive.data.block
	bmi	R.5837e

	tst.b	B.1bb6b
	bne	.label3

	move.l	#B.1c9ce,a0
	move.l	#DAT.7a41a,a6
	move.w	#3-1,d7

.label2	move.b	(a6)+,(a0)+
	dbra	d7,.label2
	rts

.label3	move.b	#0,d0
	jsr	R.5f374
.label4	rts


****************************************


R.583e8	tst.b	machine
	beq	.label3
	jsr	R.584a0
	tst.b	machine
	bmi	.label2

.label1	jsr	test.key.F5
	beq	.label3

	move.l	#DAT.7a41a,a6
	move.w	#5-1,d7
	jsr	receive.data.block
	bmi	.label1

	jsr	R.584de
	move.b	opponents.ID,d0
	jsr	R.58472
	move.l	#DAT.7a41a,a1
	jsr	R.5848a
	tst.b	machine
	bmi	.label3

.label2	jsr	test.key.F5
	beq	.label3

	move.l	#DAT.5849a,a6
	move.w	#5-1,d7
	jsr	transmit.data.block
	bmi	.label2

	tst.b	machine
	bmi	.label1
.label3	rts


R.58472	subq.b	#4,d0
	move.b	d0,d3
	asl.b	#2,d0
	add.b	d3,d0
	addq.b	#4,d0
	move.b	d0,d2
	move.b	#4,d1
	move.l	#TAB.5fb3a,a2
	rts


R.5848a	move.b	(a1,d1.w),(a2,d2.w)
	subq.b	#1,d2
	subq.b	#1,d1
	bpl	R.5848a
	rts


DAT.5849a
	ds.w	3


R.584a0	move.l	#TAB.58500,a0
	move.l	#control.keys,a1
	move.l	#DAT.5849a,a2
	move.w	#4,d3

.label1	move.b	(a1,d3.w),d0
	move.w	#0,d2

.label2	cmp.b	(a0,d2.w),d0
	beq	.label3

	addq.b	#1,d2
	cmpi.b	#$80,d2
	bne	.label2
	move.b	#0,d2

.label3	move.b	d2,(a2,d3.w)
	dbra	d3,.label1
	rts


R.584de	move.l	#DAT.7a41a,a0
	move.l	#TAB.58500,a2
	clr.w	d0
	move.w	#4,d3

.loop	move.b	(a0,d3.w),d0
	move.b	(a2,d0.w),(a0,d3.w)
	dbra	d3,.loop
	rts


TAB.58500
 dc.b	$0e,$45,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$41,$42
 dc.b	$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$44,$63,$20,$21
 dc.b	$22,$23,$24,$25,$26,$27,$28,$29,$2a,$0d,$60,$00,$31,$32,$33,$34
 dc.b	$35,$36,$37,$38,$39,$3a,$61,$1c,$64,$40,$67,$50,$51,$52,$53,$54
 dc.b	$55,$56,$57,$58,$59,$2b,$2c,$3b,$4c,$47,$4a,$4f,$48,$4e,$5e,$49
 dc.b	$4d,$4b,$68,$69,$62,$6a,$66,$65,$6b,$6c,$6d,$6e,$6f,$70,$71,$72
 dc.b	$30,$5f,$46,$5a,$5b,$5c,$5d,$3d,$3e,$3f,$2d,$2e,$2f,$1d,$1e,$1f
 dc.b	$0f,$3c,$43,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f


R.58580	move.b	#$50,d1			F1
	jsr	test.key
	beq	.label1
	move.b	#$80,B.57c68
	bra	.label2

.label1	move.b	#0,B.57c68

.label2	tst.b	machine
	beq	.label5
	cmpi.b	#2,multi.no.of.players
	bge	.label3
	move.b	#$80,B.57c68
	rts

.label3	tst.b	machine
	bpl	.label4
	move.b	B.57c68,B.57c66

.label4	move.b	#$f4,B.57c64
	jsr	R.579b0
	tst.b	machine
	bmi	.label5
	move.b	B.57c60,B.57c68

.label5	tst.b	B.57c68
	rts


set.opponent.draw.flag
	move.b	#0,opponent.draw.flag
	tst.b	machine
	beq	sodf2

	move.w	opponents.road.x.position,d0
	bpl	sodf3

	neg.w	d0
	cmpi.w	#60,d0
	blt	sodf2
	move.b	#$80,opponent.draw.flag

sodf1	move.w	opponents.offset,d0
	bmi	sodf2
	addi.w	#32,opponents.offset
sodf2	rts

sodf3	subi.w	#256,d0
	cmpi.w	#60,d0
	blt	sodf2

	move.b	#1,opponent.draw.flag
	bra	sodf1


copy.lap.time
	move.b	DAT.1c908,B.57c6b
	move.b	DAT.1c920,B.57c6c
	move.b	DAT.1c938,B.57c6d
	rts


R.5867a	tst.b	machine
	beq	.label8
	bmi	.label4

.label1	jsr	test.key.F5
	beq	.label8

	move.l	#DAT.7a41a,a6
	move.w	#100-1,d7
	jsr	receive.data.block
	bmi	.label1

	move.l	#DAT.1c908,a0
	move.l	#DAT.7a41a,a6
	move.w	#72-1,d7

.label2	move.b	(a6)+,(a0)+
	dbra	d7,.label2

	move.b	(a6)+,B.1bbb4
	eori.b	#$c0,B.1bbb4
	move.b	(a6)+,B.1bbb1
	move.b	(a6)+,B.1ca23
	move.b	(a6)+,B.1ca24
	move.l	#TEXT.5ec48,a0
	move.w	#12-1,d7

.label3	move.b	12(a6),13(a0)
	move.b	(a6)+,(a0)+
	dbra	d7,.label3
	rts

.label4	move.l	#DAT.7a41a,a6
	move.l	#DAT.1c908,a0
	move.w	#72-1,d7

.label5	move.b	(a0)+,(a6)+
	dbra	d7,.label5

	move.b	B.1bbb4,(a6)+
	move.b	B.1bbb1,(a6)+
	move.b	B.1ca23,(a6)+
	move.b	B.1ca24,(a6)+
	move.l	#TEXT.5ec48,a0
	move.w	#12-1,d7

.label6	move.b	13(a0),12(a6)
	move.b	(a0)+,(a6)+
	dbra	d7,.label6

.label7	jsr	test.key.F5
	beq	.label8

	move.l	#DAT.7a41a,a6
	move.w	#100-1,d7
	jsr	transmit.data.block
	bmi	.label7

.label8	rts


coll1.sub2.sub3
	tst.b	machine
	beq	coll1.sub2.sub31

	tst.b	drop.start.done
	bpl	coll1.sub2.sub31

	move.b	B.1bbe0,d0
	bpl	coll1.sub2.sub31

	asl.b	#1,d0
	move.b	players.road.section,d3
	cmp.b	opponents.road.section,d3
	bne	coll1.sub2.sub31

	move.b	swing.from.left,d3
	eor.b	d3,d0
	bmi	coll1.sub2.sub31
	eori.b	#$80,swing.from.left

coll1.sub2.sub31
	rts


R.5879e	tst.b	machine
	beq	.label1

	move.l	#DAT.1c908,a0
	move.l	#DAT.1c920,a1
	move.l	#DAT.1c938,a2
	move.l	#DAT.58880,a3
	tst.b	d0
	bmi	.label2

	move.b	B.5eb79,d1
	addi.b	#12,d1
	move.b	#0,d2
	jsr	R.5886c
	move.b	opponents.ID,d1
	addi.b	#12,d1
	move.b	#1,d2
	jsr	R.5886c

.label1	rts

.label2	move.b	B.5eb79,d2
	addi.b	#12,d2
	move.b	#0,d1
	jsr	R.58812
	move.b	opponents.ID,d2
	addi.b	#12,d2
	move.b	#1,d1

R.58812	tst.b	(a3,d1.w)
	beq	.label4

	tst.b	(a0,d2.w)
	bne	.label3
	bra	R.58858

.label3	move.w	d2,-(sp)
	move.b	#3,d2
	jsr	R.58858
	move.w	#3,d1
	move.w	(sp)+,d2
	jsr	new.lap.sub3
	move.l	#DAT.1c908,a0
	move.l	#DAT.1c920,a1
	move.l	#DAT.1c938,a2
	move.l	#DAT.58880,a3
.label4	rts


R.58858	move.b	(a3,d1.w),(a0,d2.w)
	move.b	2(a3,d1.w),(a1,d2.w)
	move.b	4(a3,d1.w),(a2,d2.w)
	rts


R.5886c	move.b	(a0,d1.w),(a3,d2.w)
	move.b	(a1,d1.w),2(a3,d2.w)
	move.b	(a2,d1.w),4(a3,d2.w)
	rts


DAT.58880
	ds.w	4


R.58888	move.w	people.colours,d0
	jsr	fade.screen.out

	move.l	#people.colours,a1
	jsr	copy.st.dest.colours
	move.l	#people.crunched,a1
	move.l	screen1,a0
	move.l	a0,a3
	add.l	#8000,a3

.copy	move.w	(a1)+,(a0)+
	move.w	(a1)+,7998(a0)
	move.w	(a1)+,15998(a0)
	move.w	(a1)+,23998(a0)
	cmp.l	a3,a0
	bne	.copy

	move.l	screen2,-(sp)
	move.l	screen1,screen2
	move.l	#DAT.1c9c2,a6
	move.w	#0,d6

.loop	move.b	(a6,d6.w),d0
	move.b	d6,d3
	addi.b	#19,d3
	jsr	R.5893c
	addq.b	#1,d6
	cmpi.b	#12,d6
	blt	.loop

	move.l	(sp)+,screen2
	jsr	fade.screen.in
	jsr	wait.for.fire
	jmp	show.title.screen


R.58914	jsr	R.5ab46
	move.b	B.1ca27,d0
	move.b	#12,d3
	jsr	R.5893c
	move.b	B.1ca28,d0
	move.b	#13,d3
	jsr	R.5893c
	rts


R.5893c	move.b	d0,B.58bbb
	move.w	d6,-(sp)
	move.l	a6,-(sp)
	tst.b	multi.no.of.players
	beq	.label3
	tst.b	machine
	beq	.label2

.label1	move.b	#11,d0
	bra	.label3

.label2	cmp.b	B.5eb79,d0
	beq	.label1
	andi.w	#1,d0
	move.l	#DAT.59140,a0
	move.b	(a0,d0.w),d0

.label3	cmpi.b	#12,d0
	bge	.labelb
	cmpi.b	#31,d3
	bge	.labelb

	move.b	d0,B.58aa2
	move.l	#TAB.58b20,a0
	andi.w	#15,d0
	move.b	(a0,d0.w),d0
	move.l	#people.crunched,a0
	move.l	screen2,a3
	move.l	#TAB.58aa4,a1
	andi.w	#$ff,d0
	andi.w	#$ff,d3
	asl.w	#2,d0
	asl.w	#2,d3
	add.l	(a1,d0.w),a0
	add.l	(a1,d3.w),a3
	move.l	a3,L.5924c
	tst.b	B.58bba
	beq	.label4
	jsr	R.58b2c
	bra	.labela

.label4	move.b	#0,B.58bc8
	tst.b	multi.no.of.players
	beq	.label5
	cmpi.b	#11,B.58aa2
	bne	.label5
	move.b	#$80,B.58bc8
	move.b	B.58bbb,d1
	move.l	#TAB.58bbc,a2
	move.b	(a2,d1.w),d0
	jsr	make.masks
	move.l	d6,L.58bca
	move.l	d7,L.58bce
	move.l	#TAB.58bd6,L.58bd2

.label5	move.w	#54,d5

.label6	move.w	#4,d3

.label7	tst.b	B.58bc8
	beq	.label8
	move.l	(a0)+,d0
	jsr	R.58dfc
	move.w	d0,8000(a3)
	swap	d0
	move.w	d0,(a3)+
	move.l	(a0)+,d0
	jsr	R.58e20
	move.w	d0,23998(a3)
	swap	d0
	move.w	d0,15998(a3)
	bra	.label9

.label8	move.w	(a0)+,(a3)+
	move.w	(a0)+,7998(a3)
	move.w	(a0)+,15998(a3)
	move.w	(a0)+,23998(a3)

.label9	dbra	d3,.label7
	add.l	#120,a0
	add.l	#30,a3
	dbra	d5,.label6

.labela	cmpi.b	#11,B.58aa2
	bne	.labelb
	jsr	R.59250

.labelb	move.l	(sp)+,a6
	move.w	(sp)+,d6
	rts


B.58aa2	dc.b	0,0


TAB.58aa4
	dc.w	$0000,$0780,$0000,$29e0,$0000,$4c40
	dc.w	$0000,$07a8,$0000,$2a08,$0000,$4c68
	dc.w	$0000,$07d0,$0000,$2a30,$0000,$4c90
	dc.w	$0000,$07f8,$0000,$2a58,$0000,$4cb8
	dc.w	$0000,$0e66,$0000,$0e74
	dc.w	$0000,$156e,$0000,$157c
	dc.w	$0000,$0d72,$0000,$0d7c,$0000,$0d86
	dc.w	$0000,$01e0,$0000,$0a78,$0000,$1310
	dc.w	$0000,$01ea,$0000,$0a82,$0000,$131a
	dc.w	$0000,$01f4,$0000,$0a8c,$0000,$1324
	dc.w	$0000,$01fe,$0000,$0a96,$0000,$132e


TAB.58b20
	dc.b	3,7,11,9,6,8,10,4,0,1,5,2


R.58b2c	move.b	B.58bba,d3
	andi.l	#$f,d3
	move.b	#$36,value
	move.l	a0,a5
	move.l	a3,a0

.label1	move.w	#0,d1
	move.l	#TAB.58b9a,a2

.label2	move.w	#8,W.6a168
	move.l	#TAB.58bae,a1
	move.l	(a2)+,d0
	move.w	d0,(a1)
	move.l	(a5)+,2(a1)
	move.l	(a5)+,6(a1)
	not.l	d0
	and.l	d0,2(a1)
	and.l	d0,6(a1)
	jsr	draw.spark.sub2.sub
	addq.b	#1,d1
	cmpi.b	#5,d1
	blt	.label2
	add.l	#120,a5
	add.l	#30,a0
	subq.b	#1,value
	bpl	.label1
	rts


TAB.58b9a
 dc.b	$c0,$00,$c0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 dc.b	$00,$03,$00,$03

TAB.58bae
 dc.b	0,0,0,0,0,0,0,0,0,0,0,0

B.58bba	dc.b	0
B.58bbb	dc.b	0

TAB.58bbc
 dc.b	$0b,$0b,$0b,$0b,$05,$02,$0e,$01,$04,$0f,$09,$0b

B.58bc8	dc.b	0,0

L.58bca	dc.l	0
L.58bce	dc.l	0
L.58bd2	dc.l	0

TAB.58bd6
 dc.b	$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$e0,$00,$07,$ff,$ff,$ff,$f8,$00,$00,$1f
 dc.b	$e0,$00,$0f,$ff,$ff,$ff,$fc,$00,$00,$1f,$e0,$00,$1f,$ff,$ff,$ff
 dc.b	$fe,$00,$00,$1f,$e0,$00,$3f,$ff,$ff,$ff,$ff,$00,$00,$1f,$e0,$00
 dc.b	$3f,$ff,$ff,$ff,$ff,$00,$00,$1f,$e0,$00,$7f,$ff,$ff,$ff,$ff,$80
 dc.b	$00,$1f,$e0,$00,$7f,$ff,$ff,$ff,$ff,$80,$00,$1f,$e0,$00,$ff,$ff
 dc.b	$ff,$ff,$ff,$c0,$00,$1f,$e0,$00,$ff,$ff,$ff,$ff,$ff,$c0,$00,$1f
 dc.b	$e0,$01,$ff,$ff,$ff,$ff,$ff,$c0,$00,$1f,$e0,$01,$ff,$ff,$ff,$ff
 dc.b	$ff,$c0,$00,$1f,$e0,$01,$ff,$ff,$ff,$ff,$ff,$e0,$00,$1f,$e0,$03
 dc.b	$ff,$ff,$ff,$ff,$ff,$e0,$00,$1f,$e0,$03,$ff,$ff,$ff,$ff,$ff,$e0
 dc.b	$00,$1f,$e0,$03,$ff,$ff,$ff,$ff,$ff,$e0,$00,$1f,$e0,$07,$ff,$ff
 dc.b	$ff,$ff,$ff,$f8,$00,$1f,$e0,$07,$ff,$ff,$ff,$ff,$ff,$f8,$00,$1f
 dc.b	$e0,$07,$ff,$ff,$ff,$ff,$ff,$f8,$00,$1f,$e0,$03,$ff,$ff,$ff,$ff
 dc.b	$ff,$f0,$00,$1f,$e0,$03,$ff,$ff,$ff,$ff,$ff,$f0,$00,$1f,$e0,$03
 dc.b	$ff,$ff,$ff,$ff,$ff,$f0,$00,$1f,$e0,$03,$ff,$ff,$ff,$ff,$ff,$e0
 dc.b	$00,$1f,$e0,$03,$ff,$ff,$ff,$ff,$ff,$e0,$00,$1f,$e0,$03,$ff,$ff
 dc.b	$ff,$ff,$ff,$e0,$00,$1f,$e0,$01,$ff,$ff,$ff,$ff,$ff,$e0,$00,$1f
 dc.b	$e0,$01,$ff,$ff,$ff,$ff,$ff,$e0,$00,$1f,$e0,$01,$ff,$ff,$ff,$ff
 dc.b	$ff,$e0,$00,$1f,$e0,$01,$ff,$ff,$ff,$ff,$ff,$c0,$00,$1f,$e0,$01
 dc.b	$ff,$ff,$ff,$ff,$ff,$c0,$00,$1f,$e0,$01,$ff,$ff,$ff,$ff,$ff,$c0
 dc.b	$00,$1f,$e0,$00,$ff,$ff,$ff,$ff,$ff,$80,$00,$1f,$e0,$00,$7f,$ff
 dc.b	$ff,$ff,$ff,$80,$00,$1f,$e0,$00,$7f,$ff,$ff,$ff,$ff,$80,$00,$1f
 dc.b	$e0,$00,$7f,$ff,$ff,$ff,$ff,$80,$00,$1f,$e0,$00,$3f,$ff,$ff,$ff
 dc.b	$ff,$00,$00,$1f,$e0,$00,$0f,$ff,$ff,$ff,$fc,$00,$00,$1f,$e0,$00
 dc.b	$07,$ff,$ff,$ff,$f8,$00,$00,$1f,$e0,$00,$0f,$ff,$ff,$ff,$f8,$00
 dc.b	$00,$1f,$e0,$00,$3f,$ff,$ff,$ff,$ff,$f8,$00,$1f,$e0,$07,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$c0,$1f,$e0,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$1f
 dc.b	$e7,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
 dc.b	$ff,$ff


R.58dfc	move.l	L.58bd2,a4
	move.w	(a4),d4
	swap	d4
	move.w	(a4)+,d4
	move.l	a4,L.58bd2
	and.l	d4,d0
	move.l	L.58bca,d6
	not.l	d4
	and.l	d4,d6
	or.l	d6,d0
	not.l	d4
	rts


R.58e20	and.l	d4,d0
	move.l	L.58bce,d6
	not.l	d4
	and.l	d4,d6
	or.l	d6,d0
	rts


R.58e30	move.b	d0,league.text+13+2	set Y position
	move.b	#1,d0
	jsr	set.text.masks
	move.b	#13,d1
	jsr	print.league.text	'RACE  '

	move.b	B.5eb7b,d0
	addq.b	#1,d0
	jsr	R.5edca
	move.b	#244,d1			' of '
	jsr	print.league.text

	move.b	B.5eb78,d0
	tst.b	multi.no.of.players
	beq	.label1
	asl.b	#1,d0

.label1	jmp	R.5edca

R.58e7a	tst.b	B.1bbaa
	bmi	.label2

	jsr	clear.print.fine.y
	move.b	#11,d0
	jsr	R.58e30
	move.w	#0,d3
	jsr	R.5914a
	jsr	R.58914
	move.b	#15,d0
	jsr	set.text.masks

	jsr	clear.print.fine.y
	move.b	#20,d2
	jsr	R.5eae0
	move.b	#$80,d0
	jsr	R.5f25a
	jsr	R.5f074
	jmp	R.64828

.label2	jsr	four.print.fine.y
	move.b	#10,d0
	jsr	R.58e30
	jsr	R.5ab46
	move.b	#17,d0
	jsr	R.648d2

	jsr	clear.print.fine.y

	move.b	#96,d1			'RESULT'
	jsr	print.league.text

	jsr	four.print.fine.y
	move.b	#1,d0
	jsr	set.text.masks
	move.w	#5,d3
	jsr	R.5914a
	move.b	B.1ca25,d0
	move.b	#14,d3
	jsr	R.5893c
	move.b	B.1ca26,d0
	move.b	#15,d3
	jsr	R.5893c
	jmp	R.64828


R.58f44	move.l	#DAT.1ca0e,a6
	clr.w	d6
	move.b	B.1bbe8,d6
	move.b	#14,B.58bba
	move.b	(a6,d6.w),d0
	move.b	#$10,d3
	jsr	R.5893c
	move.b	#9,B.58bba
	move.b	1(a6,d6.w),d0
	move.b	#17,d3
	jsr	R.5893c
	move.b	#4,B.58bba
	move.b	2(a6,d6.w),d0
	move.b	#18,d3
	jsr	R.5893c
	move.b	#0,B.58bba
	jsr	four.print.fine.y
	move.b	#1,d0
	jsr	set.text.masks
	move.w	#73,d3
	move.b	#4,print.fine.x
	jsr	R.5914a
	clr.b	print.fine.x
	move.b	#15,d0
	jsr	set.text.masks
	move.b	#4,B.5913e

.label1	move.b	B.1bbe8,d2
	move.l	#DAT.1ca0e,a2
	move.b	(a2,d2.w),edge.x1.offset
	move.b	#15,d0
	jsr	set.text.masks

	move.b	B.5913e,d1
	move.b	#19,d2
	jsr	set.print.column.row

	jsr	four.print.fine.y
	move.w	#37,d3
	jsr	R.5914a
	move.b	#1,d0
	jsr	set.text.masks
	move.l	#DAT.1c9f6,a1
	clr.w	d0
	move.b	edge.x1.offset,d0
	move.b	(a1,d0.w),d0
	jsr	R.5edd2
	move.b	#15,d0
	jsr	set.text.masks

	move.b	B.5913e,d1
	move.b	#21,d2
	jsr	set.print.column.row

	jsr	clear.print.fine.y
	move.w	#46,d3
	jsr	R.5914a
	move.b	#1,d0
	jsr	set.text.masks
	move.l	#DAT.1c9de,a1
	clr.w	d0
	move.b	edge.x1.offset,d0
	move.b	(a1,d0.w),d0
	jsr	R.5edd2
	move.b	#15,d0
	jsr	set.text.masks

	move.b	B.5913e,d1
	move.b	#22,d2
	jsr	set.print.column.row

	jsr	four.print.fine.y
	move.w	#55,d3
	jsr	R.5914a
	move.b	#1,d0
	jsr	set.text.masks
	move.l	#DAT.1c9ea,a1
	clr.w	d0
	move.b	edge.x1.offset,d0
	move.b	(a1,d0.w),d0
	jsr	R.5edd2
	move.b	#15,d0
	jsr	set.text.masks

	move.b	B.5913e,d1
	move.b	#24,d2
	jsr	set.print.column.row

	jsr	clear.print.fine.y
	move.w	#64,d3
	jsr	R.5914a
	move.b	#1,d0
	jsr	set.text.masks
	move.l	#DAT.1ca02,a1
	clr.w	d0
	move.b	edge.x1.offset,d0
	move.b	(a1,d0.w),d0
	jsr	R.5edd2
	addi.b	#11,B.5913e
	addq.b	#1,B.1bbe8
	move.b	B.1bbe8,d0
	cmp.b	fp.y2+1,d0
	bne	.label1
	jmp	R.64828


B.5913e	dc.b	0,0


DAT.59140
	dc.b	0,0


R.59142	jsr	print.character
	addq.w	#1,d3

R.5914a	move.l	#TEXT.5915e,a0
	move.b	(a0,d3.w),d0
	cmpi.b	#$ff,d0
	bne	R.59142
	rts


TEXT.5915e
	dc.b	31,20,15,'V',255
	dc.b	31,7,16,'Winner 2pts     Best Lap 1pt',255
	dc.b	' Raced  ',255
	dc.b	' Wins   ',255
	dc.b	' Laps   ',255
	dc.b	' Points ',255
	dc.b	31,7,10,'First     Second     Third',255
	dc.b	0


print.sub1
	andi.w	#$7f,d0
	move.l	#title.crunched+13936,a0

ps11	cmpi.b	#32,d0
	blt	ps12

	subi.b	#32,d0
	add.l	#3840,a0
	bra	ps11

ps12	move.w	#6,d3
	mulu	d3,d0
	move.w	d0,d3
	lsr.w	#4,d3
	andi.w	#$f,d0
	bra	ps14

ps13	add.l	#8,a0
ps14	dbra	d3,ps13
	move.b	d0,B.5924b
	rts


print.sub2
	move.w	#5,d5
	move.b	B.5924b,d0
	eori.b	#$f,d0
	andi.l	#$f,d0
	move.w	(a0),d4
	clr.l	d7

ps21	btst	d0,d4
	beq	ps22
	bset	#0,d7

ps22	asl.b	#1,d7
	subq.b	#1,d0
	bpl	ps23

	move.w	8(a0),d4
	move.b	#15,d0
ps23	dbra	d5,ps21

	asl.b	#1,d7
	add.l	#160,a0
	rts

font.narrow	dc.b	0
B.5924b	dc.b	0
L.5924c	dc.l	0


R.59250	move.b	or.with.screen,d0
	move.w	d0,-(sp)
	move.b	#$80,or.with.screen
	move.l	L.5924c,d0
	addi.l	#1760,d0
	move.l	d0,L.5924c
	move.b	B.58bba,print.fine.x
	addq.b	#3,print.fine.x
	move.b	#$80,font.narrow
	move.b	B.58bbb,d1
	asl.b	#4,d1
	move.l	#opponents.names,a0
	lea	1(a0,d1.w),a0
	move.b	#0,d0
	move.w	#11,d3

.label1	cmpi.b	#32,(a0,d3.w)
	bne	.label2
	addq.b	#1,d0
	dbra	d3,.label1

.label2	lsr.b	#1,d0
	move.b	d0,d1
	move.b	#0,d2
	jsr	set.print.column.row

	move.b	#1,d0
	jsr	set.text.masks

	jsr	clear.print.fine.y
	move.b	B.58bbb,d1
	asl.b	#4,d1
	move.w	#12,d2

.label3	move.l	#opponents.names,a0
	move.b	1(a0,d1.w),d0
	jsr	print.character
	addq.b	#1,d1
	subq.b	#1,d2
	bne	.label3
	clr.b	print.fine.x
	clr.b	font.narrow
	move.w	(sp)+,d0
	move.b	d0,or.with.screen
	rts


R.5930c	move.l	#1,d0
	tst.b	B.1bbb4
	bpl	.label1

	move.l	#2,d0
	tst.b	wreck.wheel.height.reduction+2
	beq	.label1

	clr.l	d0
	move.b	#3,d0

.label1	jsr	R.59352
	rts


R.5933a	tst.b	B.593f6
	bmi	.return
	move.l	#4,d0
	jmp	R.59352
.return	rts


R.59352	asl.w	#2,d0
	move.w	d0,-(sp)
	move.w	#0,d0
	jsr	fade.screen.out

	move.w	(sp)+,d0
	move.l	#TAB.56ffc-4,a0
	move.l	(a0,d0.w),a6
	lea	2(a6),a1
	jsr	copy.st.dest.colours
	lea	34(a6),a0
	move.l	screen1,a1
	tst.b	(a6)
	bpl	.label1
	jsr	decrunch
	bra	.label3

.label1	move.l	a1,a3
	add.l	#8000,a3

.label2	move.w	(a0)+,(a1)+
	move.w	(a0)+,7998(a1)
	move.w	(a0)+,15998(a1)
	move.w	(a0)+,23998(a1)
	cmp.l	a3,a1
	bne	.label2

.label3	jsr	fade.screen.in
	jsr	wait.for.fire
	rts


R.593ba	move.l	screen.mem,a0
	move.l	screen1,a3
	add.l	#320,a0
	add.l	#320,a3
	move.l	a0,a2
	add.l	#5440,a2

.label1	move.w	(a0)+,(a3)+
	move.w	7998(a0),7998(a3)
	move.w	15998(a0),15998(a3)
	move.w	23998(a0),23998(a3)
	cmp.l	a2,a0
	blt	.label1
	rts


B.593f6	dc.b	$80,0


decrunch
	move.l	a1,a2
	move.w	#200-1,d6
d.line	move.w	#4-1,d5

d.bitplane
	move.l	a2,a1
	add.l	#8000,a2
	move.w	#0,d3

d.byte	move.b	(a0)+,d0
	bpl	next.n.bytes.literally
	neg.b	d0
	bmi	d.byte

next.byte.n.times
	andi.w	#$ff,d0
	move.b	(a0)+,d4
.copy	move.b	d4,(a1)+
	addq.b	#1,d3
	dbra	d0,.copy
	bra	check.byte.count

next.n.bytes.literally
	andi.w	#$ff,d0
.copy	move.b	(a0)+,(a1)+
	addq.b	#1,d3
	dbra	d0,.copy

check.byte.count
	cmpi.b	#40,d3
	bne	d.byte

	dbra	d5,d.bitplane

	add.l	#40-32000,a2
	dbra	d6,d.line
	rts


R.59450	move.l	a1,a2
	move.w	#199,d6

.label1	move.w	#3,d5

.label2	move.l	a2,a1
	add.l	#2,a2
	move.w	#0,d3

.label3	move.b	(a0)+,d0
	bpl	.label6
	neg.b	d0
	bmi	.label3
	andi.w	#255,d0
	move.b	(a0)+,d4

.label4	move.b	d4,(a1)+
	addq.b	#1,d3
	btst	#0,d3
	bne	.label5
	add.l	#6,a1

.label5	dbra	d0,.label4
	bra	.label9

.label6	andi.w	#255,d0

.label7	move.b	(a0)+,d4
	move.b	d4,(a1)+
	addq.b	#1,d3
	btst	#0,d3
	bne	.label8
	add.l	#6,a1

.label8	dbra	d0,.label7

.label9	cmpi.b	#40,d3
	bne	.label3
	dbra	d5,.label2
	add.l	#152,a2
	dbra	d6,.label1
	rts


print.character
	movem.l	d0-d5/a0-a1,-(sp)
	jsr	pc1
	movem.l	(sp)+,d0-d5/a0-a1
	rts

pc1	tst.b	set.print.pos
	beq	check.print.cmd

	addq.b	#1,print.cmd
	move.b	print.cmd,d3
	cmpi.b	#2,d3
	beq	set.print.row

	move.b	d0,print.column
	rts

set.print.row
	move.b	d0,print.row
	move.b	#0,set.print.pos
	rts

check.print.cmd
	cmpi.b	#31,d0
	bne	check.print.char

	move.b	d0,set.print.pos
	move.b	#0,print.cmd
	rts

check.print.char
	cmpi.b	#$7f,d0
	bcs	ascii.char
	bne	not.delete

	subq.b	#1,print.column
	move.b	or.with.screen,copy.or.with.screen
	move.b	#0,or.with.screen
	move.b	#$20,d0			SPACE
	jsr	pc1
	move.b	copy.or.with.screen,or.with.screen
	subq.b	#1,print.column
not.delete
	rts

ascii.char
	subi.b	#$20,d0
	move.b	print.column,d3
	andi.w	#$ff,d3
	move.w	d3,d4
	asl.w	#3,d3
	sub.w	d4,d3
	tst.b	font.narrow
	beq	times7
	sub.w	d4,d3

times7	move.b	print.fine.x,d4
	andi.w	#$ff,d4
	add.w	d4,d3
	move.w	d3,d4
	lsr.w	#4,d4
	move.b	d4,print.word
	move.b	d3,d4
	andi.b	#$f,d4
	move.b	d4,print.shift
	andi.l	#$ff,d0
	tst.b	font.narrow
	beq	standard.font
	jsr	print.sub1
	bra	print.dest

standard.font
	asl.l	#3,d0
	move.l	#font7,a0
	add.l	d0,a0

print.dest
	move.b	print.row,d0
	asl.b	#3,d0
	add.b	print.fine.y,d0
	andi.l	#$ff,d0
	move.l	d0,d4
	asl.l	#2,d4
	add.l	d4,d0
	asl.l	#3,d0
	move.l	screen.mem,a1
	add.l	#32000,a1
	tst.b	second.screen
	bpl	print.scr.set
	move.l	screen2,a1

print.scr.set
	tst.b	font.narrow
	beq	standard.font2
	move.l	L.5924c,a1

standard.font2
	add.l	d0,a1
	move.b	print.word,d3
	andi.l	#$ff,d3
	asl.l	#1,d3
	add.l	d3,a1
	cmpi.b	#$41,B.5d724
	bne	print.count
	tst.b	font.narrow
	bne	print.count
	add.l	#-8*40,a1

print.count
	move.b	#8,d2

print.byte
	tst.b	font.narrow
	beq	standard.font3
	jsr	print.sub2
	move.l	#%11111100000000000,d5
	bra	print.first.word

standard.font3
	move.b	(a0)+,d7
	andi.l	#$ff,d7
	move.l	#%11111110000000000,d5

print.first.word
	asl.l	#8,d7
	asl.l	#1,d7
	move.b	print.shift,d3
	eori.b	#$f,d3
	andi.l	#$f,d3
	asl.l	d3,d7
	asl.l	d3,d5

	move.l	d7,d6
	swap	d7
	move.w	d7,d6

	move.l	d5,d4
	swap	d5
	move.w	d5,d4

	move.l	bground.masks,d3
	and.l	d4,d3
	not.l	d4
	move.w	(a1),d0
	swap	d0
	move.w	8000(a1),d0
	tst.b	or.with.screen
	bmi	no.or1
	and.l	d4,d0
	or.l	d3,d0

no.or1	move.l	text.masks,d3
	and.l	d6,d3
	not.l	d6
	and.l	d6,d0
	or.l	d3,d0
	move.w	d0,8000(a1)
	swap	d0
	move.w	d0,(a1)
	tst.b	second.screen
	bmi	not.scr2
	move.w	d0,-32000(a1)
	swap	d0
	move.w	d0,-24000(a1)

not.scr2
	add.l	#16000,a1
	not.l	d4
	not.l	d6
	move.l	bground.masks+4,d3
	and.l	d4,d3
	not.l	d4
	move.w	(a1),d0
	swap	d0
	move.w	8000(a1),d0
	tst.b	or.with.screen
	bmi	no.or2
	and.l	d4,d0
	or.l	d3,d0

no.or2	move.l	text.masks+4,d3
	and.l	d6,d3
	not.l	d6
	and.l	d6,d0
	or.l	d3,d0
	move.w	d0,8000(a1)
	swap	d0
	move.w	d0,(a1)
	tst.b	second.screen
	bmi	print.second.word
	move.w	d0,-32000(a1)
	swap	d0
	move.w	d0,-24000(a1)

print.second.word
	add.l	#2-16000,a1

	move.l	d7,d6
	swap	d7
	move.w	d7,d6

	move.l	d5,d4
	swap	d5
	move.w	d5,d4

	move.l	bground.masks,d3
	and.l	d4,d3
	not.l	d4
	move.w	(a1),d0
	swap	d0
	move.w	8000(a1),d0
	tst.b	or.with.screen
	bmi	no.or3
	and.l	d4,d0
	or.l	d3,d0

no.or3	move.l	text.masks,d3
	and.l	d6,d3
	not.l	d6
	and.l	d6,d0
	or.l	d3,d0
	move.w	d0,8000(a1)
	swap	d0
	move.w	d0,(a1)
	tst.b	second.screen
	bmi	no.scr22
	move.w	d0,-32000(a1)
	swap	d0
	move.w	d0,-24000(a1)

no.scr22
	add.l	#16000,a1
	not.l	d4
	not.l	d6
	move.l	bground.masks+4,d3
	and.l	d4,d3
	not.l	d4
	move.w	(a1),d0
	swap	d0
	move.w	8000(a1),d0
	tst.b	or.with.screen
	bmi	no.or4
	and.l	d4,d0
	or.l	d3,d0

no.or4	move.l	text.masks+4,d3
	and.l	d6,d3
	not.l	d6
	and.l	d6,d0
	or.l	d3,d0
	move.w	d0,8000(a1)
	swap	d0
	move.w	d0,(a1)
	tst.b	second.screen
	bmi	print.next
	move.w	d0,-32000(a1)
	swap	d0
	move.w	d0,-24000(a1)

print.next
	add.l	#40-2-16000,a1
	subq.b	#1,d2
	bne	print.byte

	move.b	print.column,d0
	addq.b	#1,d0
	cmpi.b	#45,d0
	bcs	column.ok
	move.b	#0,d0
column.ok
	move.b	d0,print.column
	rts


set.text.masks
	jsr	make.masks
	move.l	d6,text.masks
	move.l	d7,text.masks+4
	rts


set.bground.masks
	jsr	make.masks
	move.l	d6,bground.masks
	move.l	d7,bground.masks+4
	rts


bground.masks	ds.w	4
text.masks	ds.w	4
print.column	dc.b	0
print.row	dc.b	0
print.word	dc.b	0
print.shift	dc.b	0
copy.or.with.screen	dc.b	0
set.print.pos	dc.b	0
print.cmd	dc.b	0,0


release.and.wait.for.key
	jsr	get.pressed.key
	bcc	release.and.wait.for.key
wait.for.key
	jsr	get.pressed.key
	bcs	wait.for.key
	rts


get.pressed.key
	jsr	read.joystick

	move.w	#127,d0
	move.l	#key.array,a0

key.test
	cmpi.b	#$b3,(a0,d0.w)
	bne	previous.key

	cmpi.b	#$60,d0			LEFT SHIFT
	beq	previous.key
	cmpi.b	#$61,d0			RIGHT SHIFT
	bne	found.valid.key

previous.key
	dbra	d0,key.test

	btst	#0,joystick.state
	bne	not.forward2
	move.w	#$4c00,d0
	bra	return.valid.key

not.forward2
	btst	#1,joystick.state
	bne	not.back2
	move.w	#$4d00,d0
	bra	return.valid.key

not.back2
	btst	#2,joystick.state
	bne	not.left2
	move.w	#$4f00,d0
	bra	return.valid.key

not.left2
	btst	#3,joystick.state
	bne	not.right2
	move.w	#$4e00,d0
	bra	return.valid.key

not.right2
	btst	#4,joystick.state
	bne	not.fire2
	move.w	#$440d,d0
	bra	return.valid.key

not.fire2
	ori.b	#1,ccr
	rts

found.valid.key
	move.b	#0,(a0,d0.w)
	tst.b	$60(a0)			LEFT SHIFT
	bne	shift.key
	tst.b	$61(a0)			RIGHT SHIFT
	beq	not.shift.key

shift.key
	move.l	upper.case.ptr,a0
	bra	get.ASCII.key

not.shift.key
	move.l	lower.case.ptr,a0

get.ASCII.key
	lea	(a0,d0.w),a0
	asl.w	#8,d0
	move.b	(a0),d0

return.valid.key
	andi.b	#%11110,ccr
	rts


validate.ASCII.key
	move.b	#0,invalid.key.flag
	cmpi.b	#0,d0
	bne	ASCII.key.valid

	lsr.w	#8,d0			get raw key code
	cmpi.b	#$45,d0			ESCAPE
	bne	check.cursor.up
	move.b	#$80,invalid.key.flag
	rts

check.cursor.up
	cmpi.b	#$4c,d0
	bne	check.cursor.down
	move.b	#$20,invalid.key.flag
	rts

check.cursor.down
	cmpi.b	#$4d,d0
	bne	check.cursor.left
	move.b	#$40,invalid.key.flag
	rts

check.cursor.left
	cmpi.b	#$4f,d0
	bne	check.cursor.right
	move.b	#$10,invalid.key.flag
	rts

check.cursor.right
	cmpi.b	#$4e,d0
	bne	ASCII.key.valid
	move.b	#8,invalid.key.flag

ASCII.key.valid
	rts


* rotate opponent's corner point
rotate.opponent
	move.l	#segment.x.coords,a0
	move.w	(a0,d2.w),near.x.coord
	move.w	32(a0,d2.w),near.z.coord
	jsr	calculate.screen.x
	jsr	calculate.screen.y

	move.l	#x.values,a0
	move.w	(a0,d1.w),d0
	addi.w	#36,d1
	move.w	d0,(a0,d1.w)		take copy for shadow x co-ordinate
	jsr	calculate.screen.y
	jsr	z.rotate0

	subi.w	#36,d1
	andi.w	#$ff,d1
	jmp	z.rotate0


OppRearLeftWheelY	equ	244
OppRearRightWheelY	equ	248
OppFrontLeftWheelY	equ	246
OppFrontRightWheelY	equ	250

* $599e2
make.opponent
	move.w	coord.visible.values+OppRearLeftWheelY,d0
	move.w	opp.rear.left.road.height,d3
	addi.w	#80,d3
	cmp.w	d3,d0
	bge	mo1
	move.w	d0,d3					use lower of road and wheel height
mo1	move.w	d3,coord.visible.values+280		shadow y1

	move.w	coord.visible.values+OppRearRightWheelY,d0
	move.w	opp.rear.right.road.height,d3
	addi.w	#80,d3
	cmp.w	d3,d0
	bge	mo2
	move.w	d0,d3
mo2	move.w	d3,coord.visible.values+284		shadow y3

	move.w	opp.rear.right.road.height,d4
	sub.w	opp.rear.left.road.height,d4
	asr.w	#1,d4
	move.w	opp.front.road.height,d5
	sub.w	d4,d5
	move.w	coord.visible.values+OppFrontLeftWheelY,d0
	move.w	d5,d3					front left road height
	addi.w	#80,d3
	cmp.w	d3,d0
	bge	mo3
	move.w	d0,d3
mo3	move.w	d3,coord.visible.values+282		shadow y2

	move.w	opp.front.road.height,d5
	add.w	d4,d5
	move.w	coord.visible.values+OppFrontRightWheelY,d0
	move.w	d5,d3					front right road height
	addi.w	#80,d3
	cmp.w	d3,d0
	bge	mo4
	move.w	d0,d3
mo4	move.w	d3,coord.visible.values+286		shadow y4

* Create screen co-ords of opponent's four corners
	move.b	#10,d2
	move.b	#OppRearLeftWheelY,d1
	jsr	rotate.opponent

	move.b	#14,d2
	move.b	#OppRearRightWheelY,d1
	jsr	rotate.opponent

	move.b	#16,d2
	move.b	#OppFrontLeftWheelY,d1
	jsr	rotate.opponent

	move.b	#20,d2
	move.b	#OppFrontRightWheelY,d1
	jsr	rotate.opponent

	move.b	#OppRearLeftWheelY,d1
	jsr	rotate.opponent2
	jsr	opponents.back

	move.w	W.1bc66,d0
	move.w	W.1bc6a,d3
	subq.w	#1,d3
	sub.w	d0,x.values+280
	sub.w	d0,x.values+284
	sub.w	d3,y.values+280
	sub.w	d3,y.values+284
	move.b	#OppFrontLeftWheelY,d1
	jsr	rotate.opponent2
	jsr	opponents.sides

	move.w	W.1bc66,d0
	move.w	W.1bc6a,d3
	sub.w	d0,x.values+282
	sub.w	d0,x.values+286
	sub.w	d3,y.values+282
	sub.w	d3,y.values+286
	jsr	opponents.shadow
	rts


opponents.shadow
	move.w	#47*32,d0
	addi.w	#128,d0
	move.w	d0,road.section.offset

	move.w	#280,d1
	move.w	#284,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#280,d1
	move.w	#282,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#282,d1
	move.w	#286,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#284,d1
	move.w	#286,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	rts


opponent.fatten
	move.w	W.1bc64,d0
	bpl	ofn1
	neg.w	d0
ofn1	lsr.w	#1,d0
	move.w	d0,W.1bc6c
	lsr.w	#1,d0
	move.w	d0,W.1bc74
	lsr.w	#1,d0
	move.w	d0,W.1bc7c

	tst.w	W.1bc64
	bpl	ofn2
	neg.w	W.1bc6c
	neg.w	W.1bc74
	neg.w	W.1bc7c

***

ofn2	move.w	W.1bc66,d0
	bpl	ofn3
	neg.w	d0
ofn3	lsr.w	#1,d0
	move.w	d0,W.1bc6e
	lsr.w	#1,d0
	move.w	d0,W.1bc76
	lsr.w	#1,d0
	move.w	d0,W.1bc7e

	tst.w	W.1bc66
	bpl	ofn4
	neg.w	W.1bc6e
	neg.w	W.1bc76
	neg.w	W.1bc7e

***

ofn4	move.w	W.1bc68,d0
	bpl	ofn5
	neg.w	d0
ofn5	lsr.w	#1,d0
	move.w	d0,W.1bc70
	lsr.w	#1,d0
	move.w	d0,W.1bc78
	lsr.w	#1,d0
	move.w	d0,W.1bc80

	tst.w	W.1bc68
	bpl	ofn6
	neg.w	W.1bc70
	neg.w	W.1bc78
	neg.w	W.1bc80

***

ofn6	move.w	W.1bc6a,d0
	bpl	ofn7
	neg.w	d0
ofn7	lsr.w	#1,d0
	move.w	d0,W.1bc72
	lsr.w	#1,d0
	move.w	d0,W.1bc7a
	lsr.w	#1,d0
	move.w	d0,W.1bc82

	tst.w	W.1bc6a
	bpl	ofn8
	neg.w	W.1bc72
	neg.w	W.1bc7a
	neg.w	W.1bc82
ofn8	rts


opponents.back
	move.w	#47*32,d0
	addi.w	#64,d0
	move.w	d0,road.section.offset
	jsr	opponents.left.wheel
	jsr	opponents.right.wheel

	move.w	#47*32,d0
	addi.w	#16,d0
	move.w	d0,road.section.offset

	move.w	W.1bc6c,d0
	sub.w	W.1bc6e,d0
	move.w	d0,x.values+270

	move.w	W.1bc70,d0
	sub.w	W.1bc72,d0
	move.w	d0,y.values+270

	move.w	W.1bc6c,d0
	neg.w	d0
	sub.w	W.1bc6e,d0
	move.w	d0,x.values+264

	move.w	W.1bc70,d0
	neg.w	d0
	sub.w	W.1bc72,d0
	move.w	d0,y.values+264

	move.w	W.1bc66,d0
	add.w	W.1bc74,d0
	add.w	W.1bc7c,d0
	move.w	d0,x.values+268

	move.w	W.1bc6a,d0
	add.w	W.1bc78,d0
	add.w	W.1bc80,d0
	move.w	d0,y.values+268

	move.w	W.1bc66,d0
	sub.w	W.1bc74,d0
	sub.w	W.1bc7c,d0
	move.w	d0,x.values+266

	move.w	W.1bc6a,d0
	sub.w	W.1bc78,d0
	sub.w	W.1bc80,d0
	move.w	d0,y.values+266

	move.w	car.x.shift,d0
	move.w	car.y.shift,d3

	add.w	d0,x.values+264
	add.w	d3,y.values+264

	add.w	d0,x.values+266
	add.w	d3,y.values+266

	add.w	d0,x.values+268
	add.w	d3,y.values+268

	add.w	d0,x.values+270
	add.w	d3,y.values+270

	addq.w	#1,x.values+268
	addq.w	#1,x.values+270
	addq.w	#1,y.values+264
	addq.w	#1,y.values+270
	move.w	#264,d1
	move.w	#266,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#266,d1
	move.w	#268,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#268,d1
	move.w	#270,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#270,d1
	move.w	#264,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	rts


opponents.sides
	move.w	W.1bc6c,d0
	move.w	d0,x.values+276

	sub.w	W.1bc6e,d0
	move.w	d0,x.values+278
	move.w	W.1bc70,d0

	move.w	d0,y.values+276
	sub.w	W.1bc72,d0
	move.w	d0,y.values+278

	move.w	W.1bc6c,d0
	neg.w	d0
	move.w	d0,x.values+274

	sub.w	W.1bc6e,d0
	move.w	d0,x.values+272

	move.w	W.1bc70,d0
	neg.w	d0
	move.w	d0,y.values+274

	sub.w	W.1bc72,d0
	move.w	d0,y.values+272

	move.w	car.x.shift,d0
	move.w	car.y.shift,d3

	add.w	d0,x.values+272
	add.w	d3,y.values+272

	add.w	d0,x.values+274
	add.w	d3,y.values+274

	add.w	d0,x.values+276
	add.w	d3,y.values+276

	add.w	d0,x.values+278
	add.w	d3,y.values+278

	addq.w	#1,x.values+276
	addq.w	#1,x.values+278
	addq.w	#1,y.values+272
	addq.w	#1,y.values+278

	move.w	#47*32,d0
	addi.w	#32,d0
	move.w	d0,road.section.offset
	move.w	#272,d1
	move.w	#274,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#274,d1
	move.w	#276,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#276,d1
	move.w	#278,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#278,d1
	move.w	#272,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#264,d1
	move.w	#272,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#270,d1
	move.w	#278,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#266,d1
	move.w	#274,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#268,d1
	move.w	#276,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#47*32,d0
	addi.w	#96,d0
	move.w	d0,road.section.offset
	jsr	opponents.left.wheel
	jsr	opponents.right.wheel
	rts


opponents.left.wheel
	move.w	W.1bc64,d0
	neg.w	d0
	move.w	d0,W.1bc88

	move.w	W.1bc68,d0
	neg.w	d0
	move.w	d0,W.1bc8a
	bra	opponents.wheel

opponents.right.wheel
	move.w	W.1bc64,d0
	sub.w	W.1bc6c,d0
	move.w	d0,W.1bc88

	move.w	W.1bc68,d0
	sub.w	W.1bc70,d0
	move.w	d0,W.1bc8a

opponents.wheel
	move.w	W.1bc88,d0
	move.w	d0,x.values+258
	add.w	W.1bc6c,d0
	move.w	d0,x.values+260

	move.w	W.1bc8a,d0
	move.w	d0,y.values+258
	add.w	W.1bc70,d0
	move.w	d0,y.values+260

	move.w	W.1bc88,d0
	sub.w	W.1bc66,d0
	move.w	d0,x.values+256
	add.w	W.1bc6c,d0
	move.w	d0,x.values+262

	move.w	W.1bc8a,d0
	sub.w	W.1bc6a,d0
	move.w	d0,y.values+256
	add.w	W.1bc70,d0
	move.w	d0,y.values+262

	move.w	car.x.shift,d0
	move.w	car.y.shift,d3

	add.w	d0,x.values+256
	add.w	d3,y.values+256

	add.w	d0,x.values+258
	add.w	d3,y.values+258

	add.w	d0,x.values+260
	add.w	d3,y.values+260

	add.w	d0,x.values+262
	add.w	d3,y.values+262

	addq.w	#1,x.values+260
	addq.w	#1,x.values+262
	addq.w	#1,y.values+256
	addq.w	#1,y.values+262
	move.w	#256,d1
	move.w	#258,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#258,d1
	move.w	#260,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#260,d1
	move.w	#262,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	move.w	#262,d1
	move.w	#256,d2
	jsr	clip.line.make.edge

	addq.w	#4,road.section.offset
	rts


* make component x and y values
rotate.opponent2
	move.l	#x.values,a4
	move.l	#y.values,a5
	move.w	4(a4,d1.w),d4
	sub.w	(a4,d1.w),d4		right x - left x
	asr.w	#1,d4
	move.w	4(a5,d1.w),d5
	sub.w	(a5,d1.w),d5		right y - left y
	asr.w	#1,d5

	move.w	d4,d0
	bpl	ro21
	neg.w	d0
ro21	cmpi.w	#255,d0
	bcs	ro22
	move.w	#255,d0
ro22	move.w	d0,W.1bc6a		abs half x diff

	move.w	d5,d0
	bpl	ro23
	neg.w	d0
ro23	cmpi.w	#255,d0
	bcs	ro24
	move.w	#255,d0
ro24	move.w	d0,W.1bc68		abs half y diff

	move.w	W.1bc6a,W.1bc64		half x diff

	tst.w	d4
	bpl	ro25

	neg.w	W.1bc64
	bra	ro26

ro25	neg.w	W.1bc6a
ro26	move.w	W.1bc68,W.1bc66		half y diff

	tst.w	d5
	bpl	ro27

	neg.w	W.1bc66
	neg.w	W.1bc68

ro27	asr.w	W.1bc66
	asr.w	W.1bc6a
	move.w	(a4,d1.w),d0
	add.w	d4,d0
	move.w	d0,car.x.shift

	move.w	(a5,d1.w),d0
	add.w	d5,d0
	move.w	d0,car.y.shift
	bra	opponent.fatten


* calculates opponent's road wheel heights and also x,z positions
calculate.opponents.road.wheel.positions
	IFD	RECORD_OPPONENT_RWP
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	#0,d0
	move.b	opponents.road.section,d0
	move.w	d0,(a0)+
	move.w	opponents.distance.into.section,(a0)+
	move.w	opponents.road.x.position,(a0)+
	move.l	a1,-(sp)
	move.l	#opp.rear.left.actual.height,a1
	move.l	(a1)+,(a0)+			rear left and rear right
	move.w	(a1)+,(a0)+			front
	move.l	(sp)+,a1
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.w	#64,d0
	jsr	calculate.section.position
	IFD	RECORD_OPPONENT_RWP
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	d0,-(sp)
	move.w	#0,d0
	move.b	d1,d0
	move.w	d0,(a0)+		opponents.road.section.m64
	move.w	(sp)+,d0
	move.w	d0,(a0)+		opponents.distance.into.section.minus64
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC
	move.w	d0,opponents.distance.into.section.minus64
	move.b	d1,opponents.road.section.m64

	jsr	fetch.near.section.stuff
	move.w	d1,d0
	jsr	fetch.xz.position
	move.w	rough.player.angle,d0
	sub.w	rough.piece.angle,d0
	move.w	d0,rough.difference.angle

	move.w	left.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a4

	move.w	right.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5

	move.b	opponents.distance.into.section.minus64,d1
	asl.w	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord1

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord2

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord3

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord4

	addq.b	#1,d1
	cmp.b	number.of.coords,d1
	bcs	.label1

* If on last segment of road section then get data for next section, then get last two co-ords

	jsr	to.next.road.section
	jsr	fetch.near.section.stuff

	move.w	left.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a4

	move.w	right.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5

	move.w	#2,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord5

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord6

* Move back to previous section

	addq.b	#1,d1
	jsr	to.previous.road.section
	jsr	fetch.near.section.stuff

	move.w	left.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a4

	move.w	right.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5
	bra	.label2

* Get last two co-ords

.label1	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord5

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord6

	addq.b	#1,d1

* Have now got all 6 co-ords (i.e. of two segments that opponent is on)

.label2	move.b	opponents.distance.into.section.minus64,d0	get segment number
	jsr	fetch.segment.xz.coords			fetch segment's four world x,z co-ords

* Calculate segment left side x,z at opponents.distance.into.section.minus64
	move.w	#8,d2		store at offset 8
	move.w	#0,d1		source offset
	jsr	calculate.segment.xz.at.opp.rear

* Calculate segment right side x,z at opponents.distance.into.section.minus64
	move.w	#12,d2		store at offset 12
	move.w	#2,d1		source offset
	jsr	calculate.segment.xz.at.opp.rear

	bclr	#7,next.segment
	move.l	#opp.rear.left.actual.height,a0
	move.l	#opponents.x.spans,a3
	move.w	(a0),d0
	sub.w	2(a0),d0	rear left height - rear right height
	bpl	.plus
	neg.w	d0

.plus	asr.w	#4,d0
	move.b	(a3,d0.w),opponents.x.span	half the x distance that the opponent's rear wheels span
	move.b	opponents.distance.into.section.minus64+1,surface.z.position+1
*
* Calculate opp.rear.left.road.height
*
	move.w	opponents.road.x.position,d0
	clr.w	d3
	move.b	opponents.x.span,d3
	sub.w	d3,d0
	move.w	d0,surface.x.position		x position of rear left wheel
	move.w	#0,d1
	jsr	calculate.opponents.road.wheel.height

* Calculate rear left wheel x,z
	move.w	#10,d2		store at offset 10
	move.w	#8,d1		source offset
	move.w	surface.x.position,d0
	jsr	calculate.segment.xz
*
* Calculate opp.rear.right.road.height
*
	move.w	opponents.road.x.position,d0
	clr.w	d3
	move.b	opponents.x.span,d3
	add.w	d3,d0
	move.w	d0,surface.x.position		x position of rear right wheel
	move.w	#2,d1
	jsr	calculate.opponents.road.wheel.height

* Calculate rear right wheel x,z
	move.w	#14,d2		store at offset 14
	move.w	#8,d1		source offset
	move.w	surface.x.position,d0
	jsr	calculate.segment.xz

*
* Calculate opp.front.road.height
*
	move.w	surface.y.coord1,d0
	sub.w	surface.y.coord3,d0
	bpl	.label4
	neg.w	d0

.label4	cmpi.w	#20,d0
	blt	.label5
	move.b	#$80,B.1bbba		flag to not draw opponent's shadow

.label5	jsr	calculate.opp.front.road.height

	move.w	surface.y.coord1,d0
	sub.w	surface.y.coord3,d0
	bpl	.label6
	neg.w	d0

.label6	cmpi.w	#20,d0
	blt	.label7
	move.b	#$80,B.1bbba		flag to not draw opponent's shadow

* Finally calculate section position for opponents.distance.into.section.minus255 (used for drawing)

.label7	move.w	#255,d0

calculate.section.position
	move.b	opponents.road.section,d1
	move.b	d1,current.road.section

	move.w	opponents.distance.into.section,d3
	sub.w	d3,d0
	neg.w	d0
	bpl	.label8

	move.w	d0,-(sp)
	jsr	to.previous.road.section
	jsr	fetch.near.section.stuff
	move.w	(sp)+,d3
	move.b	number.of.segments,d0
	asl.w	#8,d0
	add.w	d3,d0

.label8	move.w	d0,opponents.distance.into.section.minus255
	move.b	d1,opponents.road.section.m255
	rts


calculate.opponents.road.wheel.height
	jsr	calculate.road.surface.height
	move.l	road.height,d0
	asr.l	#3,d0
	move.l	#opp.rear.left.road.height,a0
	move.w	d0,(a0,d1.w)
	IFD	RECORD_OPPONENT_RWP
	tst.b	recording
	beq.s	.done
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	d0,(a0)+
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done
	ENDC
	rts


* Now have:
* segment.x.coords	x1,		x2,		x3,		x4
*			left edge x,	left wheel x,	right edge x,	right wheel x		; at car's rear
*
* segment.z.coords	z1,		z2,		z3,		z4
*			left edge z,	left wheel z,	right edge z,	right wheel z		; at car's rear

calculate.opp.front.road.height
	move.l	#segment.x.coords,a0
	move.w	14(a0),d0		rear right wheel x
	sub.w	10(a0),d0		rear right wheel x - rear left wheel x
	move.w	d0,opp.xdiff
	asr.w	#1,d0
	add.w	d0,opp.xdiff

	move.w	14+32(a0),d0		rear right wheel z
	sub.w	10+32(a0),d0		rear right wheel z - rear left wheel z
	move.w	d0,opp.zdiff
	asr.w	#1,d0
	add.w	d0,opp.zdiff

* Calculate x,z of front wheels
	move.w	10(a0),d0		rear left wheel x
	sub.w	opp.zdiff,d0
	move.w	d0,16(a0)		front left wheel x

	move.w	10+32(a0),d0		rear left wheel z
	add.w	opp.xdiff,d0
	move.w	d0,16+32(a0)		front left wheel z

	move.w	14(a0),d0		rear right wheel x
	sub.w	opp.zdiff,d0
	move.w	d0,20(a0)		front right wheel x

	move.w	14+32(a0),d0		rear right wheel z
	add.w	opp.xdiff,d0
	move.w	d0,20+32(a0)		front right wheel z

	move.b	opponents.distance.into.section.minus64+1,d0
	addi.b	#128,d0		add 128 to get z of opponent's front
	bcc	.store

	move.w	surface.y.coord3,surface.y.coord1
	move.w	surface.y.coord4,surface.y.coord2
	move.w	surface.y.coord5,surface.y.coord3
	move.w	surface.y.coord6,surface.y.coord4

.store	move.b	d0,surface.z.position+1
	move.b	opponents.road.x.position+1,surface.x.position+1
	move.w	#4,d1
	IFD	RECORD_OPPONENT_RWP_TEMP
	tst.b	recording
	beq.s	.done
	move.l	a0,-(sp)
	move.w	d0,-(sp)
	move.l	recording.ptr,a0
	clr.w	d0
	move.b	surface.x.position+1,d0
	move.w	d0,(a0)+
	move.b	surface.z.position+1,d0
	move.w	d0,(a0)+
	move.w	surface.y.coord1,(a0)+
	move.w	surface.y.coord2,(a0)+
	move.w	surface.y.coord3,(a0)+
	move.w	surface.y.coord4,(a0)+
	move.l	a0,recording.ptr
	move.w	(sp)+,d0
	move.l	(sp)+,a0
.done
	ENDC
	bra	calculate.opponents.road.wheel.height


calculate.segment.coord
	move.l	#segment.x.coords,a0
	move.w	4(a0,d1.w),d0
	sub.w	(a0,d1.w),d0
	move.w	surface.position,d3
	muls	d3,d0
	asr.l	#8,d0
	tst.b	next.segment
	bpl	store.segment.coord

* Otherwise use co-ord from next segment
	addq.b	#4,d1
	jsr	store.segment.coord
	subq.b	#4,d1
	rts


surface.position	dc.w	0	(x or z position)


store.segment.coord
	add.w	(a0,d1.w),d0
	move.w	d0,(a0,d2.w)
	rts


calculate.segment.xz.at.opp.rear
	move.b	opponents.distance.into.section.minus64+1,d0
	move.l	#B.1bbbe,a0		random z shift?
	add.b	(a0,d1.w),d0
	roxr.b	#1,d3
	move.b	d3,next.segment		flag indicating moved to next segment
	andi.w	#$ff,d0

calculate.segment.xz
	move.w	d0,surface.position

	jsr	calculate.segment.coord
	addi.b	#32,d2
	addi.b	#32,d1
	bra	calculate.segment.coord


make.optional.screen.coord
	move.l	#segment.x.coords,a0
	move.w	(a0,d2.w),near.x.coord
	move.w	32(a0,d2.w),near.z.coord
	jsr	calculate.screen.x
	jsr	calculate.screen.y
	jmp	z.rotate0


fetch.segment.xz.coords
	move.b	d0,d2
	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0

	move.l	d0,a3
	move.b	(a3),d0
	addq.b	#7,d0
	move.b	d0,piece.coords.offset

	tst.b	plus.180.degrees
	bne	fsxzc2

	asl.b	#3,d2
	add.b	piece.coords.offset,d2
	move.b	#0,d1

fsxzc1	jsr	store.segment.xz.coord
	addq.b	#2,d1
	cmpi.b	#8,d1
	bne	fsxzc1
	rts

fsxzc2	move.b	number.of.segments,d0
	sub.b	d2,d0
	subq.b	#1,d0
	asl.b	#3,d0
	add.b	piece.coords.offset,d0
	move.b	d0,d2
	move.b	#6,d1

fsxzc3	jsr	store.segment.xz.coord
	subq.b	#2,d1
	bpl	fsxzc3
	rts


store.segment.xz.coord
	jsr	fetch.near.xz.coords

	move.l	#segment.x.coords,a1
	move.w	near.x.coord,(a1,d1.w)

	move.l	#segment.z.coords,a1
	move.w	near.z.coord,(a1,d1.w)
	rts


R.5a64e	jsr	print.character
	addq.b	#1,d1
R.5a656	tst.b	B.5eb75
	bmi	R.5a67c

	move.l	#TEXT.5a69a,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#255,d0
	bne	R.5a64e
	rts

print.sub3
	jsr	print.character
	addq.b	#1,d1
R.5a67c	move.l	#main.game.selection.text,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#255,d0
	bne	print.sub3
	rts


	dc.b	23,19,25,8,21,10,8,21,9,31


TEXT.5a69a
	dc.b	31,17,11,'SELECT',255,'Practise ',255
	dc.b	'Start the Racing Season',255
	dc.b	'Load/Save/Replay       ',255
	dc.b	'Load',255
	dc.b	'Save',255
	dc.b	'Replay',255
	dc.b	'Cancel',255
	dc.b	'LOAD from Tape',255
	dc.b	'LOAD from Disc',255
	dc.b	'SAVE to Tape',255
	dc.b	'SAVE to Disc',255
	dc.b	31,7,20,'   Filename?  >',255
	dc.b	'to the SUPER LEAGUE',255
	dc.b	31,12,9,'SUPER DIVISION ',255
	dc.b	'EXCELLENT DRIVING - WELL DONE',255
	dc.b	'Hall of Fame',255
	dc.b	0


move.draw.bridge
	move.b	road.ID,d0
	cmpi.b	#5,d0
	beq	mdb1
	rts

mdb1	cmpi.b	#56,players.road.section
	bcc	mdb2
	cmpi.b	#51,players.road.section
	bcc	mdb3

mdb2	cmpi.b	#56,opponents.road.section
	bcc	mdb4
	cmpi.b	#51,opponents.road.section
	bcc	mdb3

	tst.b	B.1bb3f
	beq	mdb4
	cmpi.b	#48,opponents.road.section
	bcs	mdb4

mdb3	move.b	#12,d0
	move.b	d0,B.1bb3f
	add.b	draw.bridge.frame.count,d0
	bra	mdbb

mdb4	tst.b	fourteen.frames.elapsed
	bmi	mdb5

	addq.b	#1,draw.bridge.frame.count

mdb5	move.w	#0,pos.difference.angle
	move.b	#0,B.1bb3f
	move.b	draw.bridge.frame.count,d0
	andi.w	#$1f,d0
	subi.w	#16,d0
	bpl	mdb6
	not.w	d0

mdb6	move.b	d0,d2
	addq.w	#4,d0
	move.l	#TAB.5a996,a0
	move.b	(a0,d2.w),opponents.speed.values+51
	move.b	(a0,d2.w),opponents.speed.values+52
	asl.w	#5,d0
	move.w	d0,near.x.coord
	move.b	#2,d2

	move.b	#190,d1
	move.l	#y.coordinate.offsets,a1
	move.w	(a1,d1.w),road.data.offset
	move.w	road.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a0
	move.b	#15,d1

mdb7	move.w	pos.difference.angle,d0
	add.w	near.x.coord,d0
	move.w	d0,pos.difference.angle

mdb8	move.b	pos.difference.angle,d0
	cmpi.b	#32,d2
	bne	mdb9
	ori.b	#$80,d0

mdb9	move.b	d0,-(sp)
	move.b	d0,(a0,d2.w)
	addq.b	#1,d2
	move.b	pos.difference.angle+1,(a0,d2.w)

	addq.b	#1,d2
	move.b	d2,value

	move.b	#72,d2
	sub.b	value,d2
	move.b	(sp)+,(a0,d2.w)

	addq.b	#1,d2
	move.b	pos.difference.angle+1,(a0,d2.w)

	move.b	value,d2
	cmpi.b	#18,d2
	beq	mdb8

	subq.b	#1,d1
	bne	mdb7

	tst.b	mdb_first_time
	beq	mdba

	move.l	#far.section.ptrs+51*4,a1
	move.l	(a1),a1
	move.b	16(a0),d0
	asl.w	#8,d0
	move.b	19(a0),d0
	bclr	#15,d0
	add.w	overall.left.y.shifts+51*2,d0
	move.w	d0,6(a1)
	move.w	d0,12(a1)
	move.w	d0,76(a1)
	move.w	d0,82(a1)

	move.b	32(a0),d0
	asl.w	#8,d0
	move.b	33(a0),d0
	bclr	#15,d0
	add.w	overall.left.y.shifts+52*2,d0
	move.w	d0,20(a1)
	move.w	d0,26(a1)
	move.w	d0,62(a1)
	move.w	d0,68(a1)

mdba	move.b	#$80,mdb_first_time
	move.b	opponents.road.section,d0
	cmpi.b	#47,d0
	bne	mdbd
	move.b	draw.bridge.frame.count,d0

mdbb	move.l	#TAB.5a9a6,a1
	move.l	#opponents.speed.values+48,a2
	andi.b	#$1f,d0
	lsr.b	#1,d0
	move.b	d0,d2
	move.b	#0,d1
	move.b	#$c6,d0

mdbc	add.b	(a1,d2.w),d0
	move.b	d0,(a2,d1.w)
	addq.b	#1,d1
	cmpi.b	#3,d1
	bne	mdbc

mdbd	rts


TAB.5a996
 dc.b	$d2,$bb,$b7,$b3,$b1,$ad,$ab,$a7,$a6,$a4,$a2,$a1,$9f,$9f,$9f,$9e

TAB.5a9a6
 dc.b	$f7,$f7,$f6,$f6,$f5,$f5,$f6,$f7,$f8,$f9,$fb,$fd,$ff,$02,$05,$fd


main.initialisation
	move.l	#W.1baf8,a0
.clear	move.b	#0,(a0)+
	cmp.l	#DAT.1ca36,a0
	bne	.clear

	jsr	initialise.data
	move.b	#0,B.5d724
	move.b	#11,d1

.set	move.b	d1,d0
	move.l	#DAT.1c9c2,a1
	move.b	d0,(a1,d1.w)
	jsr	randomize.long
	subq.b	#1,d1
	bpl	.set

	jsr	main.initialisation2

	move.b	#10,damage.hole.position

	move.b	#0,font7+14*8+5		change decimal point
	move.b	#$10,font7+14*8+6

	move.b	#$7e,font7+13*8+3	change minus sign

	move.l	#0,font7+63*8		change underscore
	move.l	#0,font7+63*8+4
	move.b	#$7e,font7+63*8+6
	rts


main.initialisation2
	move.w	#0,d0
	move.b	d0,B.1ca35
	move.b	d0,B.57c67
	move.w	d0,W.57c72
	move.b	#59,d1

mi21	move.l	#DAT.1c9de,a1
	move.b	#0,(a1,d1.w)
	cmpi.b	#12,d1
	bcc	mi22

	move.l	#DAT.1ca0e,a0
	move.b	d1,(a0,d1.w)

	move.l	#DAT.1ca36,a0
	move.b	#10,(a0,d1.w)

mi22	subq.b	#1,d1
	bpl	mi21
	rts


R.5aa84	move.l	#TAB.5aaf4,a0
	move.l	#DAT.1c9d2,a1
	move.w	#11,d1

.label1	jsr	randomize.long
	andi.b	#$3f,d0
	add.b	(a0,d1.w),d0
	move.b	d0,(a1,d1.w)
	subq.b	#1,d1
	bpl	.label1
	move.b	B.1ca35,d1
	move.b	#0,d0

.label2	move.b	d0,B.1bb5f
	tst.b	multi.no.of.players
	beq	.label3
	cmp.b	B.1c9ce,d0
	bne	.label4

.label3	jsr	R.5ab46
	jsr	R.5abd4
	jsr	R.5acfe

.label4	move.b	B.1bb5f,d0
	addq.b	#1,d0
	cmpi.b	#4,d0
	blt	.label2
	rts


TAB.5aaf4
	dc.b	120,110,100,90,80,70,60,50,40,30,20,10


R.5ab00	move.b	multi.no.of.players,d0
	beq	.label1

	eori.b	#$ff,d0
	addi.b	#12,d0
	move.b	d0,fp.y+1
	move.b	#12,fp.y2+1
	rts

.label1	move.b	B.1bb5f,d1
	move.l	#TAB.5ab42,a1
	move.b	(a1,d1.w),d0
	move.b	d0,fp.y+1
	addq.b	#3,d0
	move.b	d0,fp.y2+1
	rts


TAB.5ab42
	dc.b	9,6,3,0


R.5ab46	jsr	R.5ab00
	tst.b	multi.no.of.players

R.5ab52	beq	R.5ab7c

R.5ab56	tst.b	machine
	bne	R.580d8

	move.b	#11,d0
	sub.b	B.1ca35,d0
	move.b	d0,B.1ca27
	move.b	d0,d2
	move.b	B.5eb77,d0
	bra	R.5abba

R.5ab7c	move.l	#TAB.5abc8,a0
	move.l	#TAB.5abce,a1
	move.b	B.1ca35,d1
	move.b	(a0,d1.w),d2
	add.b	fp.y+1,d2
	move.l	#DAT.1c9c2,a2
	move.b	(a2,d2.w),d0
	move.b	d0,B.1ca27
	move.b	(a1,d1.w),d2
	add.b	fp.y+1,d2
	move.b	(a2,d2.w),d0
	move.b	#11,d2

R.5abba	move.b	d0,B.1ca28
	move.b	d2,B.5eb79
	rts


TAB.5abc8
	dc.b	0,0,0,0,1,1
TAB.5abce
	dc.b	1,1,2,2,2,2


R.5abd4	move.w	#0,d1
	jsr	randomize.long
	cmpi.b	#160,d0
	bcs	.label1
	move.b	#64,d1

.label1	move.b	d1,near.x.coord+1
	move.b	B.1ca27,d2
	move.b	B.1ca28,d1
	move.l	#DAT.1c9f6,a1
	addq.b	#1,(a1,d1.w)
	addq.b	#1,(a1,d2.w)
	move.b	B.1bbb4,d0
	cmp.b	B.5eb79,d1
	beq	.label2
	cmp.b	B.5eb79,d2
	bne	.label3
	eori.b	#$c0,d0

.label2	move.b	d0,near.x.coord+1
	jmp	.label5

.label3	move.l	#DAT.1c9d2,a2
	move.b	(a2,d2.w),d0
	cmp.b	(a2,d1.w),d0
	bcs	.label5
	bne	.label4
	jsr	randomize.long
	lsr.b	#1,d0
	bcs	.label5

.label4	move.b	near.x.coord+1,d0
	eori.b	#$c0,d0
	move.b	d0,near.x.coord+1

.label5	tst.b	near.x.coord+1
	bmi	.label7
	move.b	d1,road.height+1
	btst	#6,near.x.coord+1
	bne	.label8

.label6	move.b	d1,road.height
	jmp	R.5aca6

.label7	move.b	d2,road.height+1
	btst	#6,near.x.coord+1
	beq	.label6

.label8	move.b	d2,road.height

R.5aca6	tst.b	machine
	beq	.label9
	tst.b	B.1bb5b
	bmi	.labela

.label9	move.b	road.height+1,d1
	move.l	#DAT.1c9de,a1
	addq.b	#1,(a1,d1.w)
	move.b	road.height,d1
	move.l	#DAT.1c9ea,a1
	addq.b	#1,(a1,d1.w)
	move.b	B.1bb5f,d0
	cmp.b	B.1c9ce,d0
	bne	.labela
	move.b	d1,B.1ca26
	move.b	road.height+1,d0
	move.b	d0,B.1ca25

.labela	rts


R.5acfe	jsr	R.5ab00
	move.l	#DAT.1ca0e,a3
	move.b	fp.y+1,d2

.label1	move.l	#DAT.1c9c2,a2
	move.b	(a2,d2.w),d1
	move.b	d1,d0
	move.b	d0,(a3,d2.w)
	move.l	#DAT.1c9de,a0
	move.b	(a0,d1.w),d0
	asl.b	#1,d0
	move.l	#DAT.1c9ea,a0
	add.b	(a0,d1.w),d0
	move.l	#DAT.1ca02,a1
	move.b	d0,(a1,d1.w)
	addq.b	#1,d2
	cmp.b	fp.y2+1,d2
	blt	.label1

.label2	move.b	#0,d0
	move.b	d0,road.height+1
	move.b	fp.y+1,d2

.label3	move.b	d2,road.height
	move.b	(a3,d2.w),d1
	move.b	1(a3,d2.w),d0
	move.b	d0,d2
	move.l	#DAT.1ca02,a1
	move.b	(a1,d1.w),d0
	cmp.b	(a1,d2.w),d0
	blt	.label5
	bne	.label6
	move.l	#DAT.1c9de,a1
	move.b	(a1,d1.w),d0
	cmp.b	(a1,d2.w),d0
	blt	.label5
	bne	.label6
	tst.b	multi.no.of.players
	beq	.label4
	cmp.b	d2,d1
	bcs	.label5
	bra	.label6

.label4	jsr	randomize.long
	lsr.b	#1,d0
	bcc	.label6

.label5	move.b	d2,factor1
	move.b	road.height,d2
	move.b	d1,d0
	move.b	d0,1(a3,d2.w)
	move.b	factor1,d0
	move.b	d0,(a3,d2.w)
	addq.b	#1,road.height+1

.label6	move.b	road.height,d2
	addq.b	#1,d2
	addq.b	#1,d2
	cmp.b	fp.y2+1,d2
	bge	.label7
	subq.b	#1,d2
	bra	.label3

.label7	move.b	road.height+1,d0
	bne	.label2
	rts


get.road.data.byte
	move.b	(a5,d5.w),d0
	addq.w	#1,d5
	andi.b	#$ff,d0
	rts


srd1.sub3
	tst.b	factor1
	bmi	srd1s32

	btst	#6,factor1
	bne	srd1s31
	addi.b	#16,d0
	rts

srd1s31	addi.b	#1,d0
	rts

srd1s32	btst	#6,factor1
	bne	srd1s33
	subi.b	#16,d0
	rts

srd1s33	subi.b	#1,d0
	rts


set.road.data1
	move.b	d1,d0
	asl.b	#1,d0
	move.b	d0,d2
	move.l	#road.data.offsets,a2
	move.w	(a2,d2.w),road.data.offset
	move.w	road.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5
	move.w	#0,d5

.copy	jsr	get.road.data.byte	copy first 4 bytes
	move.l	#number.of.road.sections-1,a2
	move.b	d0,(a2,d5.w)
	cmpi.b	#4,d5
	bne	.copy

	jsr	get.road.data.byte
	move.b	d0,near.x.coord+1
	move.b	d0,near.z.coord+1

	jsr	get.road.data.byte
	move.b	d0,near.x.coord
	move.b	d0,near.z.coord

	move.b	#0,d1
	move.b	d1,other.road.line.colour
	move.b	d1,pos.difference.angle+1
	move.b	d1,pos.difference.angle
	move.b	d1,prompt.chars

srd11a	move.b	prompt.chars,d0
	beq	srd13

	subq.b	#1,prompt.chars
	move.b	B.1bc55,d0
	move.b	d0,factor1

	move.l	#road.section.angle.and.piece,a1
	move.b	d0,(a1,d1.w)
	andi.b	#$10,d0
	beq	srd12

	move.b	factor1,d0
	eori.b	#$c0,d0
	move.b	d0,factor1

srd12	move.b	B.1bb8b,d0
	jsr	srd1.sub3
	jmp	srd14a

srd13	jsr	get.road.data.byte
	move.b	d0,factor1

	move.l	#road.section.angle.and.piece,a1
	move.b	d0,(a1,d1.w)

	andi.b	#$f,d0
	cmpi.b	#$f,d0
	bne	srd14

	move.b	factor1,d0
	lsr.b	#4,d0
	move.b	d0,prompt.chars
	jmp	srd11a

srd14	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	move.b	d0,B.1bc55

	jsr	get.road.data.byte
srd14a	move.l	#road.section.xz.positions,a1
	move.b	d0,(a1,d1.w)
	move.b	d0,B.1bb8b

	move.b	other.road.line.colour,d0
	lsr.b	#2,d0
	roxr.b	#1,d0
	move.b	d0,value

	move.b	factor1,d0
	andi.b	#$f,d0
	cmpi.b	#12,d0
	blt	srd15

	move.b	d0,d2
	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f0,d0
	move.l	#road.section.angle.and.piece,a1
	move.b	d0,(a1,d1.w)

	move.l	#TAB.5b2c4-12,a2
	move.b	(a2,d2.w),d0
	move.l	#left.y.coordinate.IDs,a1
	move.b	d0,(a1,d1.w)

	move.l	#TAB.5b2c4-12+2,a2
	move.b	(a2,d2.w),d0
	jmp	srd16a

srd15	jsr	get.road.data.byte
	move.l	#left.y.coordinate.IDs,a1
	move.b	d0,(a1,d1.w)

	move.b	factor1,d0
	andi.b	#$20,d0
	beq	srd16

	move.l	#left.y.coordinate.IDs,a1
	move.b	(a1,d1.w),d0
	jmp	srd16a

srd16	jsr	get.road.data.byte

srd16a	andi.b	#$7f,d0
	or.b	value,d0
	move.l	#right.y.coordinate.IDs,a1
	move.b	d0,(a1,d1.w)

	move.b	d2,d0
	move.b	d0,-(sp)
	asl.b	#1,d1
	move.l	#distances.around.road,a1
	move.w	pos.difference.angle,d0
	asl.w	#5,d0
	move.w	d0,(a1,d1.w)

	lsr.b	#1,d1
	jsr	fetch.near.section.stuff
	asl.b	#1,d1
	move.b	other.road.line.colour,d0
	add.b	number.of.coords.minus2,d0
	andi.b	#2,d0
	move.b	d0,other.road.line.colour

	move.b	number.of.segments,d0
	andi.w	#$ff,d0
	add.w	d0,pos.difference.angle
	move.b	#0,d2
	jsr	get.road.data.left.y
	move.b	d0,factor1

	move.l	#overall.left.y.shifts,a3
	move.l	#overall.right.y.shifts,a4
	move.w	near.x.coord,d4
	sub.w	factor1,d4
	move.w	d4,(a3,d1.w)

	move.b	number.of.segments,d2
	jsr	get.road.data.left.y
	move.b	d0,factor1

	add.w	factor1,d4
	move.w	d4,near.x.coord

	move.b	#0,d2
	jsr	get.road.data.right.y
	move.b	d0,factor1

	move.w	near.z.coord,d4
	sub.w	factor1,d4
	move.w	d4,(a4,d1.w)

	move.b	number.of.segments,d2
	jsr	get.road.data.right.y
	move.b	d0,factor1

	add.w	factor1,d4
	move.w	d4,near.z.coord

	lsr.b	#1,d1
	move.b	(sp)+,d0
	move.b	d0,d2
	addq.b	#1,d1
	cmp.b	number.of.road.sections,d1
	beq	srd17
	jmp	srd11a

srd17	move.b	near.start.line.section,d1
	addq.b	#1,d1
	cmp.b	number.of.road.sections,d1
	blt	srd18
	move.b	#0,d1

srd18	move.b	d1,start.finish.section

	move.w	pos.difference.angle,d0
	asl.w	#5,d0
	move.w	d0,total.road.distance
	move.b	#0,d1

srd19	jsr	get.road.data.byte
	move.l	#B.1ca2a,a1
	move.b	d0,(a1,d1.w)
	addq.b	#1,d1
	cmpi.b	#6,d1
	bne	srd19

	move.b	B.1ca2e,d0
	beq	srd1b
	move.b	#0,d1

srd1a	jsr	get.road.data.byte
	move.l	#DAT.1c8a8,a1
	move.b	d0,(a1,d1.w)

	jsr	get.road.data.byte
	move.l	#DAT.1c8c8,a1
	move.b	d0,(a1,d1.w)

	addq.b	#1,d1
	cmp.b	B.1ca2e,d1
	bne	srd1a

srd1b	move.b	B.1ca2f,d0
	beq	srd1d
	move.b	#0,d1

srd1c	jsr	get.road.data.byte
	move.l	#DAT.1c8e8,a1
	move.b	d0,(a1,d1.w)
	addq.b	#1,d1
	cmp.b	B.1ca2f,d1
	bne	srd1c

srd1d	jsr	srd1.sub4
	move.b	#0,d0
	move.b	d0,prompt.chars
	move.b	#$7c,d0
	move.b	d0,value
	move.b	#2,d0
	move.b	d0,copy.prompt.groups
	bne	srd116

srd1e	move.b	B.1ca2e,d2
	jmp	srd1fa

srd1f	move.b	d1,d0
	move.l	#DAT.1c8a8,a2
	cmp.b	(a2,d2.w),d0
	beq	srd110

srd1fa	subq.b	#1,d2
	bpl	srd1f
	jmp	srd111a

srd110	move.l	#DAT.1c8c8,a2
	move.b	(a2,d2.w),d0
	move.l	#opponents.speed.values,a1
	move.b	d0,(a1,d1.w)
	bpl	srd111

	move.b	#3,d2
	move.b	d2,prompt.chars

srd111	andi.b	#$7f,d0
	move.b	d0,value
	bpl	srd115

srd111a	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	move.b	d0,d2
	move.l	#sections.car.can.be.put.on,a2
	move.b	(a2,d2.w),d0
	bpl	srd112

	move.b	B.63ce1,d0
	subi.b	#10,d0
	move.b	d0,value
	move.b	B.63ce1,d0
	jmp	srd113a

srd112	move.b	value,d0
	addi.b	#10,d0
	bmi	srd113
	move.b	d0,value

srd113	move.b	value,d0

srd113a	move.b	prompt.chars,d2
	beq	srd114

	subq.b	#1,prompt.chars
	ori.b	#$80,d0

srd114	move.l	#opponents.speed.values,a1
	move.b	d0,(a1,d1.w)

srd115	subq.b	#1,d1
	bpl	srd1e

srd116	move.b	number.of.road.sections,d1
	subq.b	#1,d1
	subq.b	#1,copy.prompt.groups
	bne	srd1e
	rts


TAB.5b2c4
	dc.b	3,4,4,3


get.road.data.right.y
	move.w	right.y.coord.offset,left.y.coord.offset
get.road.data.left.y
	move.w	left.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a0

	move.b	y.coords.stored.as.words,d0
	bpl	get.road.data.byte.y

get.road.data.word.y
	move.b	d2,d0
	asl.b	#1,d0
	move.b	d0,d2
	addq.b	#1,d2
	move.b	(a0,d2.w),d0
	move.b	d0,value
	subq.b	#1,d2
	move.b	(a0,d2.w),d0
	andi.b	#$7f,d0
	rts

get.road.data.byte.y
	move.b	(a0,d2.w),d0
	asl.b	#1,d0
	andi.b	#$e0,d0
	move.b	d0,value
	move.b	(a0,d2.w),d0
	andi.b	#$f,d0
	rts


lift.car.onto.track
	move.b	car.on.chains.countdown,d1
	beq	car.not.on.chains

	cmpi.b	#230,d1
	bcs	lift.car.stage1

	jsr	coll1.sub2.sub3

	move.b	#44,d0
	tst.b	swing.from.left
	bpl	from.right
	move.b	#256-44,d0

from.right
	move.b	d0,swing.magnitude
	move.b	#0,swing.magnitude+1

car.on.chains.less
	subq.b	#1,car.on.chains.countdown
	rts


lift.car.stage1
	cmpi.b	#229,d1
	bne	lift.car.stage2

	move.b	#0,d0			no adjustment to amount of swing
	jsr	swing.car

	move.b	#3,d0
	jsr	raise.car.off.ground
	bpl	car.on.chains.less

car.not.on.chains
	rts


lift.car.stage2
	cmpi.b	#228,d1
	bne	lift.car.stage3

	move.b	#4,d0
	jsr	raise.car.off.ground

	move.b	#-1,d0			reduce amount of swing
	jsr	swing.car
	bne	not.minimum.magnitude

	jsr	randomize.long
	andi.b	#$1f,d0
	addi.b	#160,d0

	move.b	#44,d2			drop start
	tst.b	drop.start.done
	bpl	not.press.fire

	move.b	#60,d2			press fire

not.press.fire
	tst.b	race.mode
	bmi	not.practise
	move.b	#$8c,d0

not.practise
	move.b	d0,car.on.chains.countdown

	tst.b	B.1bb74
	beq	.label1
	move.b	#50,B.1bb74

.label1
	move.b	#4,d0
	jmp	signal.prompt.required

not.minimum.magnitude
	rts


lift.car.stage3
	move.b	#0,d0			no adjustment to amount of swing
	jsr	swing.car

	move.b	#2,d0
	jsr	raise.car.off.ground

	tst.b	fourteen.frames.elapsed
	bmi	.label1

	subq.b	#1,car.on.chains.countdown
	bne	.label1
	addq.b	#1,car.on.chains.countdown

.label1
	move.b	drop.start.done,d0
	bne	subsequent.lift

	tst.b	car.on.chains.countdown
	bpl	car.off.chains
	rts

subsequent.lift
	move.b	boost.flag,d0
	bne	not.off.chains.yet	if fire not pressed

car.off.chains
	move.b	#0,d0
	move.b	d0,car.on.chains.countdown
	move.b	d0,off.map.status
	move.b	d0,prompt.required

* Car only wants a drop start at the start of the race.

	move.b	#$80,d0
	move.b	d0,drop.start.done

not.off.chains.yet
	rts


raise.car.off.ground
	asl.w	#8,d0
	move.w	players.smaller.y,d3
	sub.w	required.raise.height,d3
	sub.w	d0,d3
	move.w	d3,d0
	asr.w	#3,d0
	subi.w	#256,d0
	bpl	less.negative

	cmpi.w	#-512,d0
	bcc	less.negative
	move.w	#-512,d0

less.negative
	sub.w	d0,car.collision.y.acceleration

	lsr.w	#8,d3
	move.b	d3,d0
	addq.b	#2,d0
	rts


swing.car
	move.b	#16,d4
	tst.b	swing.from.left
	bpl	.label1

	neg.b	d0
	move.b	#-16,d4

.label1
	asl.w	#8,d0
	move.b	#REDUCTION,d2
	beq	.zero
	muls	d2,d0
	asr.l	#8,d0

.zero	move.w	players.x.offset.from.road.centre,d3
	asl.w	#5,d3
	move.b	swing.magnitude,d7
	cmp.b	d4,d7
	beq	magnitude.reached

	add.w	d0,swing.magnitude	reduce amount of swing

magnitude.reached
	move.w	swing.magnitude,d0
	sub.w	d3,d0
	move.w	d0,players.z.angle

	move.w	#0,d0
	move.w	d0,overall.difference.below.road

	move.b	swing.magnitude,d0
	cmp.b	d4,d0
	rts


player.to.side.of.road

* Shift player in his x direction by 160*8192.
*
* Uses cosx.siny and cosx.cosy, but players.x.angle is 0 so these values
* become siny and cosy.
*
* If player is to start to the right of the road :-
*
* 	players.world.x + 160*8192cosy
*	players.world.z - 160*8192siny
*
* If player is to start to the left of the road :-
*
*	players.world.x - 160*8192cosy
*	players.world.z + 160*8192siny
*
* This is actually x = 160*8192, z = 0 being rotated about the y axis
* and then added to the player x and z.

	move.w	#8,d1
	move.w	#4,d2			cosx.siny = siny
	move.l	#players.world.x,a3

ptsor1	move.l	#sin.cos.values,a2
	move.w	(a2,d2.w),d0
	cmpi.b	#8,d1
	bne	ptsor2
	neg.w	d0

ptsor2	move.b	swing.from.left,copy.swing.from.left
	move.b	#160,factor1

	move.b	factor1,d3
	andi.w	#$ff,d3
	tst.b	copy.swing.from.left
	bpl	ptsor3
	neg.w	d3

ptsor3	asl.w	#7,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	ext.l	d0
	asl.l	#6,d0
	add.l	d0,(a3,d1.w)

	move.b	#6,d2			cosx.cosy = cosy
	subq.b	#8,d1
	bpl	ptsor1
	rts


update.engine.revs
	IFD	RECORD_PLAYER_UER
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	touching.road,d7
	move.w	d7,(a0)+

	move.b	players.input,d7
	move.w	d7,(a0)+

	move.w	players.z.speed,(a0)+
	move.w	engine.revs,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.b	touching.road,d0
	bne	uer1

* Not touching road, so test if joystick is held forwards or backwards

	move.w	#0,d0
	move.b	players.input,d0
	andi.b	#3,d0
	beq	uer2			not forwards or backwards

	move.w	#$9000,d0		set required revs.
	bne	uer2

* Touching road

uer1	move.w	players.z.speed,d0
	andi.w	#$fff0,d0
	bpl	uer2
	neg.w	d0

uer2	addi.w	#$580,d0
	lsr.w	#3,d0
	move.w	engine.revs,d3
	cmpi.w	#192,d3
	bge	uer3

* If engine revs. are low then increase them slowly (e.g. at race start)

	move.w	#2,d0
	bra	uer4

* Otherwise calculate revs. change depending on current engine revs.

uer3	sub.w	d3,d0
	asr.w	#3,d0
uer4	move.w	d0,engine.revs.change

* Now adjust revs. change

	move.b	engine.revs.change,d0
	bmi	uer5
	beq	uer9

* If revs. change is $100 or greater then set to $100

	move.b	#0,engine.revs.change+1
	move.b	#1,d0
	jmp	uer8

* Revs. change is negative

uer5	move.b	touching.road,d2
	beq	uer6

* Touching road, so set revs. change to $ff00 minimum

	cmpi.b	#$ff,d0
	beq	uer9

	move.b	#0,engine.revs.change+1
	move.b	#$ff,d0			set to $ff00
	jmp	uer8

* Not touching road, so set revs. change to $ffe0 minimum

uer6	cmpi.b	#$ff,d0
	bne	uer7

	move.b	engine.revs.change+1,d0
	cmpi.b	#$e0,d0
	bcc	uer9

uer7	move.b	#$e0,engine.revs.change+1
	move.b	#$ff,d0			set to $ffe0

uer8	move.b	d0,engine.revs.change

uer9	jsr	randomize.long
	andi.b	#$f,d0
	move.b	#0,engine.fluctuation

	IFD	RECORD_PLAYER_UER
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	engine.revs.change,(a0)+
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC
	rts


engine.fluctuation	dc.b	0,0


get.players.name
	jsr	clear.menu

	move.b	#224,d1			'NAME?'
	jsr	print.league.text

	move.b	#1,d0
	move.b	d0,B.1bb16
	jsr	fill.bar

	move.b	#10,d0			line colour
	move.w	#106,d4			X1
	move.w	#190,d6			X2
	move.w	#133,d5			Y
	jsr	underline.text

	jsr	copy.screen.part
	move.l	screen2,-(sp)
	move.l	screen1,screen2

input.again
	move.b	#2,d0
	jsr	set.bground.masks

	jsr	input.name
	jsr	four.print.fine.y

	move.w	#11,d0
	sub.b	multi.no.of.players,d0
	asl.w	#4,d0
	move.l	#opponents.names,a0
	cmpi.b	#' ',1(a0,d0.w)
	beq	input.again

	jsr	clear.print.fine.y
	move.b	#3,d0
	jsr	set.bground.masks

	move.l	(sp)+,screen2
	rts


input.name
	move.b	#14,d1
	move.b	#16,d2
	jsr	set.print.column.row

	move.b	#'>',d0
	jsr	print.character

.wait	jsr	get.pressed.key		wait until keys released
	bcc	.wait

	move.b	#0,d0
	move.b	#12,d3
	move.b	#0,B.5b83e
	move.b	#11,d0
	sub.b	multi.no.of.players,d0
	asl.b	#4,d0

input.filename
	move.b	d0,map.x.shift
	move.b	d3,max.name.length

	move.b	#0,invalid.key.flag
	move.b	B.5b83e,d1
	add.b	d1,print.column
	bra	next.name.key

first.name.key
	move.b	#0,d1

next.name.key
	move.b	d1,d2
	add.b	map.x.shift,d2

	jsr	wait.for.key
	tst.b	do.key.validation
	bpl	no.key.validation

	jsr	validate.ASCII.key
	tst.b	invalid.key.flag
	bne	name.entered

no.key.validation
	cmpi.b	#13,d0			CARRIAGE RETURN
	beq	name.entered

	cmpi.b	#8,d0			BACKSPACE
	beq	backspace

	cmpi.b	#' ',d0
	bne	not.name.space

	cmpi.b	#0,d1
	beq	next.name.key
	bra	valid.name.letter

not.name.space
	cmpi.b	#'.',d0
	bcs	next.name.key

	cmpi.b	#';',d0
	bcs	valid.name.letter

	cmpi.b	#'A',d0
	bcs	next.name.key

	cmpi.b	#'Z'+1,d0
	bcs	valid.name.letter

	cmpi.b	#'a',d0
	bcs	next.name.key

	cmpi.b	#'z'+1,d0
	bcs	valid.name.letter
	bra	next.name.key

backspace
	subq.b	#1,d1
	bmi	first.name.key

	move.b	#127,d0
	jsr	print.character
	jmp	next.name.key

valid.name.letter
	cmpi.b	#'a'-1,d0
	bcs	not.lower.case

	cmpi.b	#$c0,map.x.shift
	bne	not.lower.case
	subi.b	#$20,d0			to upper case

not.lower.case
	cmp.b	max.name.length,d1
	bge	next.name.key		print no more

	jsr	print.character
	move.l	#opponents.names+1,a2
	move.b	d0,(a2,d2.w)		save name character
	addq.b	#1,d1
	jmp	next.name.key

blank.rest.of.name
	move.b	d1,d2
	add.b	map.x.shift,d2
	move.b	#' ',d0
	move.l	#opponents.names+1,a2
	move.b	d0,(a2,d2.w)
	addq.b	#1,d1

name.entered
	cmp.b	max.name.length,d1
	blt	blank.rest.of.name

	jmp	clear.print.fine.y


max.name.length	dc.b	0
invalid.key.flag	dc.b	0
B.5b83e	dc.b	0,0


get.main.menu.selection
	subq.b	#1,d2
	move.b	d2,B.1bb8d
	move.b	d1,B.1bb8b
	move.b	d0,map.z.shift
	jsr	R.645c6

	move.b	#1,d0
	jsr	set.text.masks

	move.b	#0,d1
	move.b	d1,B.1bbca
	jsr	R.5a656			'SELECT'

	move.b	#0,d0
	jsr	set.text.masks

gmms1	move.b	#0,d0
	move.b	d0,B.1bb16

gmms2	move.b	B.1bb16,d2
	move.b	d2,road.height
	cmp.b	map.z.shift,d2
	bne	gmms4

	move.b	#0,d0
	move.b	B.1bbca,d2
	bne	gmms3
	move.b	#1,d0

gmms3	move.b	d0,B.64c18

gmms4	jsr	fill.bar

	move.b	road.height,d0
	addq.b	#1,d0
	jsr	print.dec.digit2

	move.b	#'.',d0
	jsr	print.character
	move.b	#' ',d0
	jsr	print.character

	move.b	road.height,d2
	add.b	B.1bb8b,d2
	move.l	#TAB.5bcd0,a2
	move.b	(a2,d2.w),d1
	jsr	R.5a656
	cmpi.b	#24,B.1bb8b
	bne	gmms5

	move.b	road.height,d0
	addq.b	#1,d0
	jsr	print.dec.digit2

gmms5	move.b	B.1bb8d,d0
	cmp.b	road.height,d0
	bcs	gmms6

	move.b	B.1bb8b,d0
	cmpi.b	#28,d0
	bne	gmms2

	move.b	#35,d1			'The '
	jsr	print.league.text

	move.b	B.5eb7c,d0
	asl.b	#1,d0
	add.b	road.height,d0
	move.b	d0,d2
	move.l	#TAB.648c2,a2
	move.b	(a2,d2.w),d1
	jsr	print.track.name
	jmp	gmms2

gmms6	jsr	copy.screen.part
	move.b	#15,d2
	jsr	delay
	move.b	B.1bbca,d0
	beq	wait.joystick.released

	jsr	clear.print.fine.y
	move.b	map.z.shift,d0
	rts

wait.joystick.released
	jsr	get.players.input
	bne	wait.joystick.released

	move.b	#2,d2
	jsr	delay

gmms8	jsr	get.players.input
	andi.b	#$10,d0
	move.b	d0,B.1bbca
	bne	gmms1			if fire pressed

	tst.b	machine
	beq	gmms9

	jsr	R.57b5c
	bmi	gmmsc
	bra	gmms1

gmms9	move.b	B.1bb8d,d2
	addq.b	#1,d2

gmmsa	move.l	#control.keys+5,a2
	move.b	(a2,d2.w),d1
	jsr	test.key
	bne	gmmsb

	move.b	d2,map.z.shift
	jmp	gmms1

gmmsb	subq.b	#1,d2
	bpl	gmmsa

gmmsc	move.b	map.z.shift,d1
	move.b	players.input,d0
	andi.b	#3,d0
	beq	gmms8			joystick not forward or back

	andi.b	#1,d0
	beq	next.menu.bar.down

next.menu.bar.up
	subq.b	#1,d1
	bpl	gmmsf

	move.b	#0,d1
	beq	gmmsf

next.menu.bar.down
	cmp.b	B.1bb8d,d1
	beq	gmmse
	bcc	gmmsf

gmmse	addq.b	#1,d1

gmmsf	move.b	d1,map.z.shift
	jmp	gmms1


R.5ba3e	move.b	#20,d2

delay	move.b	#20,d0
	move.b	d0,factor1

delay1	subq.b	#1,value
	bne	delay1

	subq.b	#1,factor1
	bne	delay1

	subq.b	#1,d2
	bne	delay
	rts


R.5ba68	tst.b	d0
	bne	R.5ba78

	jsr	R.5fbc6
	bra	R.5baea

R.5ba78	jsr	R.5fb62
	cmpi.b	#2,d0
	bcc	R.5baea

	move.b	d0,race.mode
	move.b	#1,B.5eb7d
	move.b	B.5eb7c,d0
	asl.b	#1,d0
	add.b	race.mode,d0
	jsr	R.5bcf0
	jmp	R.5ba3e


R.5baae	move.b	#0,d0
	jsr	R.609ae

	move.b	#$80,d0
	move.b	d0,race.mode
	rts


R.5bac4	tst.b	machine
	bpl	R.5bae4

	move.b	#$20,B.57c66
	move.b	#$b2,B.57c64
	jsr	R.579b0

R.5bae4	jsr	R.5ba3e


R.5baea	move.b	#0,invalid.key.flag
	tst.b	B.5eb7d
	bne	R.5ba78

	move.b	#1,d0
	tst.b	race.mode
	bpl	.label1

	move.b	#2,d0

.label1	move.b	#3,d2
	move.b	#0,d1
	jsr	get.main.menu.selection
	cmpi.b	#2,d0
	beq	R.5baae
	blt	R.5ba68

	jsr	R.5ba3e
	cmpi.b	#SLAVE,machine
	beq	R.582f4

	move.b	#3,d2
	move.b	#3,d0
	move.b	#4,d1
	jsr	get.main.menu.selection
	cmpi.b	#2,d0
	blt	R.5bbda
	bne	R.5bac4

	jsr	main.initialisation2
	move.b	#$50,d1			F1
	jsr	test.key
	bne	R.5bb92

	tst.b	machine
	bpl	R.5bb8c

	move.b	#$c0,B.57c66
	move.b	#$b2,B.57c64
	jsr	R.579b0

R.5bb8c	jmp	main.game.selection

R.5bb92	tst.b	machine
	bpl	R.5bbb2

	move.b	#$80,B.57c66
	move.b	#$b2,B.57c64
	jsr	R.579b0

R.5bbb2	tst.b	multi.no.of.players
	bne	.label2

	move.b	#$80,d0
	jsr	R.609ae
	bcc	R.5bc9c

.label2	jsr	main.initialisation
	jsr	show.title.screen
	bra	R.5bc9c

R.5bbda	move.b	d0,B.1ca31
	asl.b	#2,d0
	addi.b	#8,d0
	move.b	d0,d1
	move.b	#0,d2

.label3	move.l	#TAB.7a01a,a2
	move.b	(a2,d2.w),d0
	move.l	#road.under.map,a2
	move.b	d0,(a2,d2.w)
	subq.b	#1,d2
	bne	.label3

	move.b	B.1ca34,d0
	move.b	d0,B.1bbd0
	jsr	R.5ba3e
	move.b	#0,d0
	jsr	R.609ae
	jsr	R.62748
	tst.b	B.1bb6b
	bne	.label5
	tst.b	B.1bb92
	bmi	.label4
	move.b	B.1ca31,d0
	bne	.label4
	move.b	#$80,d0
	jsr	R.609ae
	bcc	.label5
	move.b	#$81,B.1bb94

.label4	jsr	R.5bca8

.label5	cmpi.b	#$81,B.1bb94
	bne	.label6
	move.w	#104,d1
	jsr	R.1b82a
	jsr	wait.for.key

.label6	cmpi.b	#MASTER,machine
	bne	R.5bc90
	jsr	R.5823c

R.5bc90	cmpi.b	#$40,B.1bb6b
	beq	R.5bca2

R.5bc9c	jsr	R.648b2

R.5bca2	jmp	R.5baea


R.5bca8	move.b	#0,d2
	move.b	B.1bbd0,B.1ca34
	move.l	#road.under.map,a2
	move.l	#TAB.7a01a,a0

.loop	move.b	(a2,d2.w),(a0,d2.w)
	subq.b	#1,d2
	bne	.loop
	rts


TAB.5bcd0
 dc.b	$ec,$0a,$14,$2c,$44,$49,$4e,$55,$5c,$6b,$55,$00,$7a,$87,$55,$00
 dc.b	$0a,$1f,$71,$00,$2b,$40,$00,$00,$49,$49,$49,$49,$0a,$0a,$55,$00


R.5bcf0	move.b	d0,d1
	move.l	#TAB.648c2,a0
	move.b	(a0,d1.w),road.ID
	tst.b	league.offset
	beq	.label
	bchg	#0,d1
.label
	move.l	#TAB.648c2+8,a0
	move.b	(a0,d1.w),B.1ca21
	rts


randomize.opponents.steering
	IFD	RECORD_OPPONENT_ROS
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opponents.ID,d7
	move.w	d7,(a0)+
	move.b	opp.touching.road,d7
	move.w	d7,(a0)+
	move.b	opponents.random.steering.count,d7
	move.w	d7,(a0)+
	move.b	B.1bb9d,d7
	move.w	d7,(a0)+
	move.b	B.1bbc2,d7
	move.w	d7,(a0)+
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+
	move.b	opponent.behind.player,d7
	move.w	d7,(a0)+
	move.b	fourteen.frames.elapsed,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.b	opp.touching.road,d0
	beq	.label6

	tst.b	machine
	bne	.label6

	move.b	#0,d1
	move.b	d1,B.1bbbe
	move.b	d1,B.1bbbf
	move.b	d1,B.1bbbd
	move.b	opponents.random.steering.count,d0
	beq	.label3

	tst.b	fourteen.frames.elapsed
	bmi	.label1
	subq.b	#1,opponents.random.steering.count

.label1	add.b	B.1bbc2,d0
	andi.b	#$f,d0
	move.b	d0,d2
	move.l	#TAB.5be34,a2
	move.b	(a2,d2.w),d0
	bpl	.label2

	neg.b	d0
	addq.b	#1,d1

.label2	move.l	#B.1bbbe,a1
	move.b	d0,(a1,d1.w)
	addq.b	#5,d2
	andi.b	#$f,d2
	move.l	#TAB.5be34,a2
	move.b	(a2,d2.w),d0
	move.b	d0,B.1bbbd
	jmp	.label5

.label3	move.b	opponents.road.section,d2
	move.l	#opponents.speed.values,a0
	tst.b	(a0,d2.w)
	bmi	.label5

	tst.b	opponent.behind.player
	bmi	.label5

	tst.b	near.section.byte1
	bmi	.label5

	move.b	#8,d2
	tst.b	B.1bb9d
	bpl	.label5

	btst	#6,B.1bb9d
	beq	.label4
	move.b	#16,d2

.label4	move.b	d2,B.1bbc2

	jsr	randomize.long
	andi.b	#$1f,d0
	move.b	d0,value

	IFD	RECORD_OPPONENT_ROS
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	value,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC

	move.b	opponents.ID,d0
	cmp.b	value,d0
	blt	.label5

	move.b	#16,d0
	move.b	d0,opponents.random.steering.count

.label5	move.b	plus.180.degrees,d0
	lsr.b	#1,d0
	move.b	near.section.byte1,d3
	eor.b	d3,d0
	move.b	d0,B.1bb9d

	IFD	RECORD_OPPONENT_ROS
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	B.1bbbe,d7
	move.w	d7,(a0)+
	move.b	B.1bbbf,d7
	move.w	d7,(a0)+
	move.b	opponents.random.steering.count,d7
	move.w	d7,(a0)+
	move.b	B.1bb9d,d7
	move.w	d7,(a0)+
	move.b	B.1bbc2,d7
	move.w	d7,(a0)+
	move.b	B.1bbbd,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC

.label6	rts


TAB.5be34
	dc.b	$20,$50,$60,$70,$70,$60,$50,$20
	dc.b	$e0,$b0,$a0,$90,$90,$a0,$b0,$e0


calculate.players.road.position
	move.b	current.road.section,d1
	jsr	fetch.near.section.stuff
	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5
	move.w	d1,d0
	jsr	fetch.xz.position

	move.w	rough.player.angle,d0
	sub.w	rough.piece.angle,d0
	move.w	d0,rough.difference.angle

	tst.b	near.section.byte1
	bmi	.label2

	btst	#6,near.section.byte1
	bne	.label1

	jsr	get.players.xz.coord
	move.b	3(a5),d3
	asl.w	#8,d3
	move.b	2(a5),d3
	move.w	near.x.coord,d0
	sub.w	d3,d0
	move.w	d0,players.road.x.position

	move.w	near.z.coord,normal.distance.into.section
	move.w	rough.piece.angle,section.y.angle
	rts

.label1	jsr	get.players.xz.coord
	move.b	#$b5,factor1

	move.w	near.x.coord,d0
	sub.w	near.z.coord,d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.b	3(a5),d3
	asl.w	#8,d3
	move.b	2(a5),d3
	sub.w	d3,d0
	move.w	d0,players.road.x.position

	move.b	7(a5),factor1

	move.w	near.x.coord,d0
	add.w	near.z.coord,d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.w	d0,normal.distance.into.section

	move.b	5(a5),d3
	asl.w	#8,d3
	move.b	4(a5),d3
	add.w	rough.piece.angle,d3
	move.w	d3,section.y.angle
	rts

.label2	move.b	#2,d2
	jsr	fetch.near.xz.coords

	move.w	near.x.coord,d0
	move.w	near.z.coord,d3
	jsr	calculate.perspective.coord

	move.w	d0,-(sp)
	jsr	calculate.perspective.value
	move.w	d0,perspective.z

	move.w	(sp)+,d0
	add.w	rough.player.angle,d0
	bpl	.label3

	addi.w	#$8000,d0
	bra	.label4

.label3	subi.w	#$8000,d0

.label4	move.w	d0,W.1bc1c

	addi.w	#$4000,d0
	sub.w	curve.to.left,d0
	move.w	d0,section.y.angle

	move.b	near.section.byte1,d4
	andi.b	#3,d4
	neg.b	d4
	addq.b	#1,d4
	move.b	7(a5),d3
	asl.w	#8,d3
	move.b	6(a5),d3
	asl.w	#6,d3
	move.w	W.1bc1c,d0
	sub.w	d3,d0
	sub.w	rough.piece.angle,d0
	bpl	.label5
	neg.w	d0

.label5	move.b	8(a5),factor1

	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	tst.b	d4
	bpl	.label6

	neg.b	d4
	andi.l	#7,d4
	asl.w	d4,d0
	bra	.label7

.label6	andi.l	#7,d4
	lsr.w	d4,d0

.label7	move.w	d0,normal.distance.into.section

	lsr.w	#7,d0
	addq.b	#2,d0
	cmp.b	number.of.coords,d0
	blt	.labelc

	move.b	near.section.piece,d0
	cmpi.b	#1,d0
	beq	.label8

	cmpi.b	#3,d0
	bne	.labelc

.label8	move.b	current.road.section,road.height+1
	tst.b	plus.180.degrees
	beq	.label9

	jsr	to.previous.road.section
	jmp	.labela

.label9	jsr	to.next.road.section

.labela	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	cmpi.b	#4,d0
	bne	.labelb
	bra	calculate.players.road.position

.labelb	move.b	road.height+1,current.road.section

.labelc	jsr	cprp.sub1

	move.b	10(a5),d3
	asl.w	#8,d3
	move.b	9(a5),d3
	sub.w	perspective.z,d3
	tst.b	curve.to.left
	bpl	.labeld
	neg.w	d3

.labeld	move.w	d3,players.road.x.position
	rts


fetch.surface.y.coord

* d1.b = offset for co-ord

	move.b	d1,d2
	tst.b	y.coords.stored.as.words
	bpl	get.byte.y.coord

get.word.y.coord
	bclr	#0,d2
	btst	#0,d1
	bne	right.y.coord

	move.b	1(a4,d2.w),d3
	move.b	(a4,d2.w),d0
	andi.b	#$7f,d0
	asl.w	#8,d0
	or.b	d3,d0
	add.w	overall.left.y.shift,d0
	bra	got.surface.y.coord

right.y.coord
	move.b	1(a5,d2.w),d3
	move.b	(a5,d2.w),d0
	andi.b	#$7f,d0
	asl.w	#8,d0
	or.b	d3,d0
	add.w	overall.right.y.shift,d0
	bra	got.surface.y.coord

get.byte.y.coord
	lsr.b	#1,d2
	bcs	right.y.coord2

	move.b	(a4,d2.w),d0
	move.b	d0,d3
	asl.b	#1,d0
	andi.w	#$e0,d0
	andi.b	#$f,d3
	asl.w	#8,d3
	or.w	d3,d0
	add.w	overall.left.y.shift,d0
	bra	got.surface.y.coord

right.y.coord2
	move.b	(a5,d2.w),d0
	move.b	d0,d3
	asl.b	#1,d0
	andi.w	#$e0,d0
	andi.b	#$f,d3
	asl.w	#8,d3
	or.w	d3,d0
	add.w	overall.right.y.shift,d0

got.surface.y.coord
	asr.w	#5,d0
	rts


detail.near.road
	move.w	normal.distance.into.section,d0
	move.b	number.of.segments,d4
	asl.w	#8,d4
	tst.b	plus.180.degrees
	bpl	det1

	sub.w	d4,d0
	neg.w	d0
det1	move.w	d0,players.distance.into.section

	addi.w	#64,d0
	move.w	d0,players.distance.into.section.plus64

	cmp.w	d4,d0
	blt	det2

	move.b	#$80,players.distance.into.section.plus64
	move.w	#0,d0

det2	lsr.w	#8,d0
	addq.b	#1,d0
	asl.b	#1,d0
	move.b	d0,coord.pair.to.start.at

	asl.b	#1,d0
	move.b	d0,offset.for.coord.pair.to.start.at

	move.b	plus.180.degrees,d0
	bpl	det3

	move.w	d4,d0
	sub.w	normal.distance.into.section,d0
	lsr.w	#8,d0
	bra	det4

det3	move.b	normal.distance.into.section,d0

det4	move.b	#32,d3
	sub.b	d0,d3
	tst.b	players.distance.into.section.plus64
	bpl	det5

	add.b	number.of.segments,d3

det5	move.b	d3,near.sections.done
	andi.w	#$ff,d3
	move.w	d3,near.sections.done2
	rts


calculate.road.wheel.heights
	move.b	players.road.section,d1
	move.b	d1,current.road.section
	jsr	fetch.near.section.stuff
	move.b	#0,at.side.byte
	move.b	#4,d1

next.wheel
	move.b	d1,near.z.coord+1

	move.b	players.road.section,d0
	cmp.b	current.road.section,d0
	beq	no.section.change

	move.b	d0,d1
	move.b	d1,current.road.section
	jsr	fetch.near.section.stuff
	move.b	near.z.coord+1,d1

no.section.change
	move.b	road.width.reduction,factor1
	move.l	#front.left.wheel.x.offset,a1
	move.w	(a1,d1.w),d0		x offset for current wheel
	asr.w	#4,d0
	add.w	players.road.x.position,d0
	cmpi.w	#ROAD.WIDTH,d0
	bcs	wheel.not.off.road

	bset	#7,wheel.off.road
	move.w	d0,wheel.road.x.position
	bmi	wheel.off.left

wheel.off.right
	move.b	#$ff,d0
	bra	save.surface.x

wheel.off.left
	move.b	#0,d0
	bra	save.surface.x

wheel.not.off.road

* Reduce wheel.road.x.position from (0 - road width) to (0 - 255) and save it
* for use by the height calculate routine, which can only take (0 - 255).

	tst.w	d0
	bpl	.plus
	neg.w	d0

.plus	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0			value is now reduced

	cmpi.w	#256,d0
	blt	save.surface.x
	move.b	#$ff,d0			BUG - didn't have the # infront
save.surface.x
	move.b	d0,surface.x.position+1

	tst.b	plus.180.degrees
	bpl	.plus
	eori.b	#$ff,d0
.plus	cmpi.b	#4,d1
	bne	not.rear.wheel
	move.b	d0,rear.wheel.surface.x.position

not.rear.wheel

* Reduce the wheel road z position in a similar way to above.

	move.b	road.length.reduction,factor1
	move.l	#front.left.wheel.z.offset,a1
	move.w	(a1,d1.w),d0		z offset for current wheel
	asr.w	#3,d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0			value is now reduced

	add.w	normal.distance.into.section,d0
	move.w	d0,surface.z.position

	move.b	surface.z.position,d0	this byte is sub-section number
	asl.b	#1,d0			doubling gives co-ords to skip
	move.b	d0,surface.start.coord
	bmi	section.change

	cmp.b	number.of.coords.minus2,d0
	blt	no.section.change2

section.change
	jsr	to.appropriate.road.section

no.section.change2
	move.w	left.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a4

	move.w	right.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5

	tst.b	plus.180.degrees
	bmi	start.with.last.coords

start.with.first.coords
	move.b	surface.start.coord,d1
	IFD	RECORD
	move.b	d1,wheel.y.offset+1
	ENDC
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord1

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord2

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord3

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord4

	addq.b	#1,d1
	bra	got.four.surface.coords

start.with.last.coords
	move.b	number.of.coords,d1
	sub.b	surface.start.coord,d1
	subi.b	#4,d1
	IFD	RECORD
	move.b	d1,wheel.y.offset+1
	ENDC
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord4

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord3

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord2

	addq.b	#1,d1
	jsr	fetch.surface.y.coord
	move.w	d0,surface.y.coord1

	addq.b	#1,d1

got.four.surface.coords
	move.b	near.z.coord+1,d1
	jsr	calculate.road.wheel.height
	subq.b	#2,d1
	bpl	next.wheel
	rts


get.players.xz.coord
	tst.b	rough.difference.angle
	bmi	.label2

	btst	#6,rough.difference.angle
	bne	.label1

	move.w	#0,d0
	sub.w	road.near.x.offset,d0
	move.w	d0,near.x.coord

	move.w	#0,d0
	sub.w	road.near.z.offset,d0
	move.w	d0,near.z.coord
	rts

.label1	move.w	#0,d0
	sub.w	road.near.z.offset,d0
	move.w	d0,near.x.coord

	move.w	#$800,d0
	add.w	road.near.x.offset,d0
	move.w	d0,near.z.coord
	rts

.label2	btst	#6,rough.difference.angle
	bne	.label3

	move.w	#$800,d0
	add.w	road.near.x.offset,d0
	move.w	d0,near.x.coord

	move.w	#$800,d0
	add.w	road.near.z.offset,d0
	move.w	d0,near.z.coord
	rts

.label3	move.w	#$800,d0
	add.w	road.near.z.offset,d0
	move.w	d0,near.x.coord

	move.w	#0,d0
	sub.w	road.near.x.offset,d0
	move.w	d0,near.z.coord
	rts


to.appropriate.road.section

* Player has crossed the start or end of the road section.

	move.b	surface.z.position,d0
	move.b	plus.180.degrees,d3
	eor.b	d3,d0
	bpl	crossed.section.end

crossed.section.start
	jsr	to.previous.road.section
	jsr	fetch.near.section.stuff
	move.b	plus.180.degrees,d0
	bpl	last.section.surface
	bmi	first.section.surface

crossed.section.end
	jsr	to.next.road.section
	jsr	fetch.near.section.stuff
	tst.b	plus.180.degrees
	bmi	last.section.surface

first.section.surface
	move.b	#0,surface.start.coord
	tst.b	surface.z.position
	bpl	same.section.orientation
	bmi	opposite.section.orientation

last.section.surface
	move.b	number.of.coords,d0
	subq.b	#4,d0
	move.b	d0,surface.start.coord
	tst.b	surface.z.position
	bmi	same.section.orientation

* If the starts or ends of the old and new sections meet each other, rather
* than the old end meeting the new start (or vice versa).

opposite.section.orientation
	neg.b	surface.z.position+1
	bne	not.zero
	move.b	#$ff,surface.z.position+1
not.zero
	neg.b	surface.x.position+1
	bne	same.section.orientation
	move.b	#$ff,surface.x.position+1

same.section.orientation
	rts


to.next.road.section
	move.b	current.road.section,d1
	addq.b	#1,d1
	cmp.b	number.of.road.sections,d1
	blt	tnrs
	move.b	#0,d1

tnrs	move.b	d1,current.road.section
	rts


to.previous.road.section
	move.b	current.road.section,d1
	subq.b	#1,d1
	bpl	tprs
	move.b	number.of.road.sections,d1
	subq.b	#1,d1

tprs	move.b	d1,current.road.section
	rts


calculate.road.surface.height

* Calculates the height of the current road patch,
* at the specified x and z position.

	move.b	surface.x.position+1,d3
	andi.w	#$ff,d3
	move.w	surface.y.coord2,d0
	sub.w	surface.y.coord1,d0
	muls	d3,d0
	move.w	surface.y.coord1,d4
	ext.l	d4
	asl.l	#8,d4
	add.l	d4,d0
	move.l	d0,d5

	move.w	surface.y.coord4,d0
	sub.w	surface.y.coord3,d0
	muls	d3,d0
	move.w	surface.y.coord3,d4
	ext.l	d4
	asl.l	#8,d4
	add.l	d4,d0

	move.b	surface.z.position+1,d3
	andi.w	#$ff,d3
	sub.l	d5,d0
	move.l	d0,d4
	bpl	crsh1
	neg.l	d4
crsh1	cmpi.l	#$8000,d4
	blt	fits.into.a.word

needs.a.longword
	asr.l	#3,d0
	tst.w	d0
	bpl	crsh2
	neg.w	d0
	mulu	d3,d0
	move.b	#0,d0
	neg.l	d0
	bra	crsh3

crsh2	mulu	d3,d0
crsh3	asl.l	#3,d0
	bra	crsh6

fits.into.a.word
	tst.w	d0
	bpl	crsh5
	neg.w	d0
	mulu	d3,d0
	move.b	#0,d0
	neg.l	d0
	bra	crsh6

crsh5	mulu	d3,d0
crsh6	asr.l	#8,d0
	add.l	d5,d0
	move.l	d0,road.height
	rts


calculate.road.wheel.height
	jsr	calculate.road.surface.height

	IFD	RECORD
* Store values for recording
	cmp.b	#0,d1
	bne.s	.not.front.left.wheel
	move.b	current.road.section,front.left.wheel.piece+1
	move.w	wheel.y.offset,front.left.wheel.y.offset
	move.b	surface.x.position+1,front.left.wheel.x+1
	move.b	surface.z.position+1,front.left.wheel.z+1

.not.front.left.wheel
	cmp.b	#2,d1
	bne.s	.not.front.right.wheel
	move.b	current.road.section,front.right.wheel.piece+1
	move.w	wheel.y.offset,front.right.wheel.y.offset
	move.b	surface.x.position+1,front.right.wheel.x+1
	move.b	surface.z.position+1,front.right.wheel.z+1

.not.front.right.wheel
	cmp.b	#4,d1
	bne.s	.not.rear.wheel
	move.b	current.road.section,rear.wheel.piece+1
	move.w	wheel.y.offset,rear.wheel.y.offset
	move.b	surface.x.position+1,rear.wheel.x+1
	move.b	surface.z.position+1,rear.wheel.z+1
	move.w	surface.y.coord1,rear.wheel.y1
	move.w	surface.y.coord2,rear.wheel.y2
	move.w	surface.y.coord3,rear.wheel.y3
	move.w	surface.y.coord4,rear.wheel.y4
	move.l	road.height,rear.wheel.height

.not.rear.wheel
	ENDC

	asl.b	#1,d1
	move.l	#front.left.road.height,a3
	bclr	#7,wheel.off.road
	beq	wheel.not.off.road2

	jsr	calculate.if.car.off.road

wheel.not.off.road2
	move.b	pos.players.z.speed,d0
	cmpi.b	#$a,d0
	blt	speed.not.big.enough

* Save calculated wheel height if speed is greater than $a00 or car is at an
* x angle of more than $500 degrees forwards or backwards.

save.wheel.height
	move.l	#front.left.road.height,a0
	move.l	road.height,(a3,d1.w)
	lsr.b	#1,d1
	rts

speed.not.big.enough
	move.b	players.x.angle,d0
	bpl	.plus
	neg.b	d0
.plus	cmpi.b	#5,d0			if |x angle| > $500 degrees
	bgt	save.wheel.height

* Otherwise save the average of the calculated wheel height and the old wheel
* height.  (This is for when the car is being lowered onto the road.)

	move.l	(a3,d1.w),d0
	add.l	road.height,d0
	roxr.l	#1,d0
	move.l	d0,(a3,d1.w)
	lsr.b	#1,d1
	rts


cprp.sub1
	move.w	near.x.coord,d0
	jsr	square.it
	move.l	d0,d4

	move.w	near.z.coord,d0
	jsr	square.it
	add.l	d0,d4

	move.w	perspective.z,d0
	jsr	square.it
	move.b	near.section.piece,d2
	move.l	#TAB.5c6b8,a0
	move.b	(a0,d2.w),factor1

	sub.l	d0,d4
	lsr.l	#8,d4
	move.w	d4,d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	asr.w	#4,d0
	add.w	d0,perspective.z
	rts


TAB.5c6b8
	dc.b	0,$d4,$80,$d4,0,0,$ab,$ab,$40,$40,0,0


fetch.near.xz.coords

* d2.w = offset for co-ord pair (multiple of four)

	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5
	tst.b	rough.difference.angle
	bmi	fnxzc2

	btst	#6,rough.difference.angle
	bne	fnxzc1

* Save X and Z

	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.x.offset,near.x.coord
	add.w	d3,near.x.coord

	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.z.offset,near.z.coord
	add.w	d3,near.z.coord
	rts

* Save Z and $800-X

fnxzc1	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.z.offset,near.z.coord
	add.w	d3,near.z.coord

	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.x.offset,near.x.coord
	sub.w	d3,near.x.coord
	addi.w	#$800,near.x.coord
	rts

fnxzc2	btst	#6,rough.difference.angle
	bne	fnxzc3

* Save $800-X and $800-Z

	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.x.offset,near.x.coord
	sub.w	d3,near.x.coord
	addi.w	#$800,near.x.coord

	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.z.offset,near.z.coord
	sub.w	d3,near.z.coord
	addi.w	#$800,near.z.coord
	rts

* Save $800-Z and X

fnxzc3	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.z.offset,near.z.coord
	sub.w	d3,near.z.coord
	addi.w	#$800,near.z.coord

	move.b	1(a5,d2.w),d3
	asl.w	#8,d3
	move.b	(a5,d2.w),d3
	addq.b	#2,d2
	move.w	road.near.x.offset,near.x.coord
	add.w	d3,near.x.coord
	rts


calculate.if.car.off.road

* Calculate how far the current wheel is off the left or right of the road

	move.w	wheel.road.x.position,d0
	bmi	cior1

	move.w	#ROAD.WIDTH,d0
	sub.w	wheel.road.x.position,d0
	bpl	cior2

cior1	neg.w	d0

* If the wheel is more than $30 off the road then the car is off the road

cior2	cmpi.w	#$30,d0
	bgt	signal.car.is.off.road

* Otherwise use the amount the wheel is off the road to drop the height of
* the wheel - to make the car fall gradually off the edge.
*
* If the new wheel height is less than $1000 then the car is off the road

	andi.l	#$ff,d0
	asl.l	#4,d0
	move.l	road.height,d3
	sub.l	d0,d3
	subi.l	#$100,d3
	cmpi.l	#$1000,d3
	blt	signal.car.is.off.road

	move.l	d3,road.height		save reduced wheel height

* Also store which side the car is falling off

	move.b	wheel.road.x.position,d3
	move.b	plus.180.degrees,d0
	eor.b	d3,d0
	andi.b	#$80,d0
	bmi	left.side
	move.b	#$40,d0
left.side
	move.b	d0,which.side.byte	should perhaps instead be called 'car.on.edge'
	rts

signal.car.is.off.road
	move.l	#$1000,road.height

	move.b	at.side.byte,d0		another wheel is off the road
	lsr.b	#1,d0
	bset	#7,d0
	move.b	d0,at.side.byte
	rts


R.5c890	move.w	#0,title.colours
	move.w	#255,d0
	move.l	#opponents.names,a0
	move.l	#opponents.names.source,a1

.label1	move.b	(a0)+,(a1)+
	dbra	d0,.label1

	move.l	#TAB.5cf2c+4,a0
	move.l	#TEXT.7a61a,a1
	move.l	#TEXT.7a71a,a2
	clr.w	d1
	clr.w	d2

.label2	move.b	(a0,d2.w),(a1,d1.w)
	move.b	(a0,d2.w),(a2,d1.w)
	subq.b	#1,d2
	bpl	.label3
	move.b	#15,d2

.label3	subq.b	#1,d1
	bne	.label2

	tst.b	L.64af0
	bne	R.5cf26

	jsr	R.62d0a
	bra	R.5c960


TAB.5c8f4
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$ffff,$ffff


R.5c960	move.l	#$9cedcd02,d0
	move.l	d0,$24.w
	bra	R.5ceaa


TAB.5c96e							* garbage
	dc.w	$2d5f,$fff8,$2239,$0000,$0010,$487a,$000a,$23df
	dc.w	$0000,$0010,$4afc,$487a,$001c,$23df,$0000,$0010
	dc.w	$224f,$4e7a,$0002,$41fa,$ffc6,$2080,$0880,$0000
	dc.w	$4e7b,$0002,$2e49,$23c1,$0000,$0010,$4cf9,$00ff
	dc.w	$0000,$0008,$48d6,$00ff,$41fa,$007e,$23c8,$0000
	dc.w	$0010,$4afc,$d503,$ffe1,$601e,$2ac6,$b539,$9f83
	dc.w	$007c,$4acc,$d533,$ff89,$6076,$2ad6,$b529,$9fab
	dc.w	$0054,$4a84,$d57b,$0049,$9fb6,$2a82,$b57d,$6047
	dc.w	$ffb8,$4a98,$d567,$0071,$9f8e,$2ab6,$b549,$6063
	dc.w	$ff9c,$b554,$2aab,$ff81,$607e,$d5c0,$4a3f,$9f87
	dc.w	$0078,$4a7e,$d581,$ff81,$607e,$d5cc,$4a33,$603b
	dc.w	$ffc4,$4a06,$d5f9,$ffe9,$6016,$d5e8,$4a17,$601f
	dc.w	$ffe0,$4a3e,$d5c1,$fff5,$48e7,$80c0,$41fa,$0034
	dc.w	$23c8,$0000,$0024,$41fa,$0464,$23c8,$0000,$0020
	dc.w	$06af,$0000,$0002,$000e,$002f,$0007,$000c,$086f
	dc.w	$0007,$000c,$43fa,$fef0,$671a,$2051,$20a9,$0004
	dc.w	$6026,$027c,$f8ff,$48e7,$80c0,$43fa,$feda,$2051
	dc.w	$20a9,$0004,$206f,$000e,$2288,$2350,$0004,$2028
	dc.w	$fffc,$4680,$4840,$b190,$4cdf,$0301,$4e73,$f076
	dc.w	$fce0,$40e6,$0f89,$0008,$ba0d,$0ece,$8136,$0cc9
	dc.w	$c12e,$ec5b,$3165,$9f52,$ec52,$73ad,$60bf,$05ca
	dc.w	$054a,$00d6,$060a,$064a,$06ca,$054a,$0110,$ded5
	dc.w	$0493,$b53a,$dec0,$69d8,$7a05,$e4fa,$96c7,$1f3b
	dc.w	$81c4,$687e,$f181,$7ebb,$b56a,$f192,$6f6d,$48d1
	dc.w	$d62e,$914e,$2cdf,$d627,$5dda,$c325,$296a,$e6bb
	dc.w	$c32c,$ec93,$215a,$3c2b,$b3fc,$6c6d,$3c26,$a2d9
	dc.w	$92d6,$0c29,$5c5a,$c5eb,$3644,$e70c,$7edd,$834a
	dc.w	$4da6,$0012,$99cb,$27dc,$fff5,$7006,$eef9,$00d2
	dc.w	$4f51,$1152,$829d,$710c,$eeaf,$fff6,$6707,$9496
	dc.w	$000a,$fff6,$670f,$288c,$0005,$90e0,$3ed5,$0056
	dc.w	$f9c7,$c12b,$fff6,$0c67,$3ed0,$fff6,$6693,$f86c
	dc.w	$00e9,$8f16,$10c5,$8e3a,$7031,$c94e,$50a7,$9f76
	dc.w	$c95b,$64e4,$995b,$36a7,$f418,$994e,$377a,$f485
	dc.w	$7b7a,$e48b,$3b1a,$7b77,$f68c,$7973,$5614,$f822
	dc.w	$7970,$c576,$07dd,$03d4,$bdd1,$fabc,$6443,$4270
	dc.w	$8fa1,$6456,$d776,$7352,$c2f3,$5d0c,$8e11,$5180
	dc.w	$5d01,$d0f4,$6d93,$c3a5,$d0f7,$617d,$9cc2,$2f0b
	dc.w	$edb4,$9cd7,$5e54,$124a,$ffec,$41ea,$edb5,$03d4
	dc.w	$d163,$edb8,$2f3b,$a789,$fff8,$3d7b,$d162,$fffa
	dc.w	$3d79,$a78c,$fffc,$3d7f,$d161,$fffe,$3d7d,$d161
	dc.w	$ffee,$41e8,$2e9e,$03d4,$bfd1,$d35f,$5eaa,$838d
	dc.w	$2dbb,$5ea9,$ef23,$587b,$d156,$1ca9,$b017,$3fe8
	dc.w	$d60f,$5df7,$410b,$daf6,$7749,$d97c,$daf1,$74c7
	dc.w	$d973,$6a13,$8b36,$3abc,$a443,$7427,$ead8,$5afe
	dc.w	$c309,$01b7,$5af1,$d50e,$6484,$a63b,$d501,$648b
	dc.w	$b474,$7fa5,$6484,$f07f,$6e80,$9b93,$056c,$91dd
	dc.w	$4e3d,$ffb7,$43b1,$b11d,$f000,$3c83,$cef2,$0096
	dc.w	$cc15,$710d,$0024,$cca7,$e8f2,$009e,$cc1d,$820d
	dc.w	$009e,$cc20,$7d8c,$a13b,$33ff,$ff7c,$5ec6,$009c
	dc.w	$1d2b,$e294,$7f63,$b3dc,$1d4f,$d1f0,$4c07,$fd8d
	dc.w	$418b,$b327,$f000,$2fc3,$4cd8,$0bb8,$9547,$b2a7
	dc.w	$4571,$6ab9,$001f,$99f6,$0709,$fe86,$678b,$ab08
	dc.w	$017b,$009c,$cc1f,$be84,$0024,$8f24,$3eae,$f22d
	dc.w	$70d9,$009c,$cc1f,$cf26,$0024,$8fdb,$3e51,$e192
	dc.w	$7024,$0bb8,$9547,$8e93,$7955,$6abd,$00bf,$e001
	dc.w	$78f4,$e60b,$1ed2,$87dd,$08dd,$b957,$36a8,$8722
	dc.w	$0a22,$e61c,$7862,$d100,$1ed1,$7877,$d108,$2f76
	dc.w	$c348,$2e48,$d100,$2f3e,$c300,$2e40,$d100,$1d03
	dc.w	$d5bf,$00df,$f09e,$4114,$cc14,$202a,$be54,$d100
	dc.w	$267e,$41ac,$df9f,$005c,$be53,$001e,$9ee1,$4162
	dc.w	$f0e8,$3f39,$4173,$d48a,$4a75,$beba,$2775,$e788
	dc.w	$fa3f,$e78a,$6a74,$01cb,$992e,$0cd5,$81d5,$3a68
	dc.w	$b594,$fe57,$c596,$546b,$f814,$66eb,$abde,$2422
	dc.w	$889f,$1196,$d336,$888e,$1671,$2cab,$a354,$12de
	dc.w	$a5c6,$7cab,$f701,$00c7,$8350,$00bf,$e001,$78ee
	dc.w	$f712,$7a12,$e4ed,$08cd,$a6f8,$e4fe,$6bfe,$f411
	dc.w	$4980,$6bef,$f510,$b649,$3be3,$569e,$4a28,$c5d7
	dc.w	$76f7,$b5d3,$0459,$d4a6,$4a59,$fb88,$4e76,$da8d
	dc.w	$2df2,$b188,$46f7,$d20d,$3e32,$b9b7,$d100,$263f
	dc.w	$4648,$aa77,$d97f,$d100,$0ee0,$912f,$0fd0,$f115
	dc.w	$1d2a,$f090,$d100,$608a,$8f4c,$2e40,$d100,$2eff
	dc.w	$d1c0,$113e,$dcef,$d1d5,$782b,$8454,$49b4,$be65
	dc.w	$7bab,$ffef,$6714,$906b,$0012,$b198,$2f67,$ffcd
	dc.w	$080b,$d098,$00bf,$ee01,$7708,$db77,$4266,$f3ec
	dc.w	$042a,$bd99,$00bf,$ee01,$77e2,$db9d,$437a,$af79
	dc.w	$246a,$00bf,$ee01,$0202,$ff8c,$00bf,$e401,$0802
	dc.w	$ff42,$00bf,$e501,$548b,$ab74,$1afe,$e501,$548b
	dc.w	$ab74,$1afe,$e501,$548b,$ab74,$1afe,$e501,$548b
	dc.w	$ab74,$1afe,$e501,$548b,$ab74,$1afe,$e501,$548b
	dc.w	$ab74,$1afe,$e501,$548b,$ea8e,$e032,$3e8d,$156d
	dc.w	$ab68,$3bf6,$e489,$3a37,$c40d,$7708,$c537,$fab8
	dc.w	$257e,$3ac8,$0004,$ddfb,$63fe,$ffd9,$2f6e,$9c03
	dc.w	$2900,$203a,$faca,$6b04,$4e7b,$0002,$48f9,$00ff
	dc.w	$0000,$0008,$4cfa,$7fff,$fa4e,$4e73


R.5ceaa	jsr	R.5ceb4
	bra	R.5cefa


R.5ceb4	btst	#6,dmaconr+custom
	bne	R.5ceb4

	ori.b	#8,$bfd100
	move.w	#$450,dmacon+custom
	clr.w	d1
	clr.w	d2
	move.b	#0,B.1bb94
	jmp	set.CIAs


	ds.w	12


R.5cefa	move.l	d0,special.long
	move.l	TEXT.7a21a,d0
	add.l	TEXT.7a21a+4*127,d0
	move.l	TAB.5cf2c,d3
	eor.l	d3,d0
	move.l	d0,TAB.5cf2c
	move.b	#$80,L.64af0
	clr.w	d1
	clr.w	d2

R.5cf26	jmp	main.game.selection


TAB.5cf2c
 dc.b	$a0,$87,$f7,$58,$2d,$2d,$2d,$2d,$2d,$2d,$2d,$2d,$2d,$2d,$2d,$2d
 dc.b	$09,$00,$00,$00


main.game.selection
;	move.l	#stack,sp		set starting stack

	move.w	#256-1,d0		copy opponent's names
	move.l	#opponents.names,a0
	move.l	#opponents.names.source,a1
.copy	move.b	(a1)+,(a0)+
	dbra	d0,.copy

	move.b	#0,machine

	move.b	#$40,B.57c62
	tst.b	B.60fbc
	bne	mgs2
	move.b	#$80,B.60fbc

mgs2	jsr	main.initialisation

	move.b	#$80,B.64530
	jsr	show.title.screen
	clr.b	B.64530

	jsr	main.menu.selection	enter name, print menus

	jsr	R.648b2			display opponents

	jsr	save.random.values

	move.b	#$f3,B.57c64
	jsr	R.579b0			for datalink

mgs3	bclr	#7,B.1bb5b

	move.b	#16,B.57c62
	jsr	R.5baea			menu selection

****************************************
	move.b	#$5f,d1			HELP
	jsr	test.key
	bne.s	not.to.DOS
	rts
****************************************

****************************************
;	move.b	#SELECTED.ROAD,road.ID
;
;	IFD	I.WANT.TO.RACE
;	move.b	#$80,race.mode
;	ENDC
;
;	IFD	I.WANT.SUPER.LEAGUE
;	move.b	#11,league.offset
;	ENDC
****************************************

not.to.DOS
	tst.b	race.mode
	bmi	mgs5

	move.b	#18,B.57c62
	jsr	set.and.preview.road	set course data, draw course

	move.b	#0,B.57c62
	jsr	race.and.practise

****************************************
;	rts
****************************************

	jsr	show.title.screen
	jmp	mgs3

mgs4	move.b	#$c0,d0
	move.b	d0,B.1bb5b
	move.b	d0,B.1bbb4
	bra	mgs9

******** If race selected ********

mgs5	jsr	R.5ee68

	cmpi.b	#2,B.5eb78
	bne	mgs6
	tst.b	machine
	beq	mgs6
	move.b	#1,B.5eb78

mgs6	move.b	#23,d1
mgs7	jsr	clear.three.bytes
	cmpi.b	#16,d1
	bge	mgs8

	move.l	#DAT.1c908,a0
	move.b	#9,(a0,d1.w)
mgs8	subq.b	#1,d1
	bpl	mgs7

	clr.b	B.1ca23
	clr.b	B.1ca24

mgs9	move.b	B.1c9ce,B.1bb5f
	jsr	R.5ab46
	tst.b	B.1bb5b
	bmi	mgsa

	move.b	B.1ca28,d2
	move.b	B.1ca27,d0
	cmp.b	B.5eb79,d0
	beq	mgsb

	cmp.b	B.5eb79,d2
	bne	mgsa

	move.b	d0,d2
	jmp	mgsb

mgsa	jsr	R.5aa84			promotion
	jmp	mgsd

mgsb	move.b	d2,opponents.ID

	move.b	#$c0,B.1bbb1
	move.b	#17,B.57c62
	jsr	R.64664
	jsr	R.58580
	beq	mgs4

	move.b	#0,d0
	jsr	R.5879e

	move.b	#18,B.57c62
	jsr	set.and.preview.road	set course data, draw course

	move.b	#$80,d0
	jsr	R.5faf2

	move.b	#0,B.57c62
	jsr	race.and.practise

****************************************
;	rts
****************************************

	move.b	#$80,d0
	jsr	R.5879e
	jsr	R.5867a

	move.b	#0,d0
	jsr	R.5faf2

	move.b	#0,d0
	jsr	R.5f25a
	jsr	R.5aa84
	jsr	R.5930c

	jsr	show.title.screen

	tst.b	B.1bbb1
	beq	mgsc

	move.b	#1,B.57c62
	jsr	R.64664
	clr.b	B.1bbb1

mgsc	move.b	#2,B.57c62
	jsr	R.6465c
	move.b	#3,B.57c62
	jsr	R.646e8
	tst.b	multi.no.of.players
	beq	mgsd

	jsr	R.5ef76

mgsd	addq.b	#1,B.5eb7b
	addq.b	#1,B.1ca35
	addq.w	#1,W.57c72
	move.b	B.1ca35,d0
	cmp.b	B.5eb78,d0
	bcs	mgs9

	clr.b	B.1ca35
	tst.b	multi.no.of.players
	bne	mgsf

	jsr	R.646d6
	jsr	R.5933a
	jsr	R.648b2

mgse	jsr	main.initialisation2
	jmp	mgs3

mgsf	jsr	R.5ef42
	clr.b	B.1bb5b
	subq.b	#1,B.5eb77
	bmi	mgs10
	bra	mgs6

mgs10	addq.b	#1,B.57c67
	cmpi.b	#4,B.57c67
	bcc	mgse
	bra	mgs3


set.and.preview.road
	jsr	initialise.data

	move.w	preview.colours,d0
	jsr	fade.screen.out

	move.b	#$40,d0
	move.b	d0,B.5d724

	move.l	#preview.colours,a1
	jsr	copy.st.dest.colours

	move.b	#15,d0
	jsr	set.text.masks

	move.b	#$80,or.with.screen

	move.l	#preview.crunched,a0
	move.l	screen.mem,a1
	jsr	decrunch

	move.l	screen.mem,a1
	move.l	screen1,a0
	move.l	a0,screen2
	move.l	screen2,d3
	addi.l	#16*40+4,d3
	move.l	d3,current.scene

	move.l	a0,a3
	add.l	#32000,a3
sapr1	move.l	(a1)+,(a0)+
	cmp.l	a3,a0
	bne	sapr1

	move.b	#SIDE.LINES.COLOUR,d3	standard league colours
	move.b	#SIDES.COLOURB,d0
	tst.b	league.offset
	beq	standard.league

	move.b	#8,d3			super league colours
	move.b	#4,d0

standard.league
	move.b	d3,side.lines.colour
	move.b	d0,sides.colour

	jsr	R.61260			print road title

	move.b	#3,d0
	jsr	set.text.masks

	jsr	id2

	move.b	road.ID,d1
	jsr	set.road.data1
	jsr	make.road.under.map
	jsr	move.draw.bridge
	jsr	initialise.mountains
	jsr	set.road.data2
	jsr	R.604b4			draw road preview

	move.b	#44,d1			'Broken by QUARTEX ...'
	jsr	print.league.text

sapr2	jsr	R.5d980			read input for other views
	bcc	sapr3

	jsr	R.604b4			draw road preview
	jmp	sapr2

sapr3	move.w	#0,d0
	jsr	fade.screen.out

	move.b	#0,B.5d724
	rts


race.and.practise
	IFD	RECORD
	sf.b	recording
	sf.b	has.been.e4
	clr.w	recording.count
	move.l	#recording.buffer,recording.ptr
	ENDC
	tst.b	machine
	beq	rap1

	jsr	delay.100ms
	jsr	delay.100ms
	jsr	flush.received.bytes
	jsr	delay.60ms

rap1	move.b	#0,B.57c5b
	move.b	#0,B.57c63
	jsr	initialise.data

	jsr	make.car.screens
	move.l	#car.colours,a1
	jsr	copy.st.dest.colours

	move.b	#14,d0
	jsr	set.bground.masks
	move.b	#0,d0
	jsr	set.text.masks

	jsr	initialise.damage.bar

	move.b	#SIDE.LINES.COLOUR,d3	standard league colours
	move.b	#SIDES.COLOURB,d0
	tst.b	league.offset
	beq	standard.league2

	move.b	#SUPER.SIDE.LINES.COLOUR,d3	super league colours
	move.b	#SUPER.SIDES.COLOURB,d0

standard.league2
	move.b	d3,side.lines.colour
	move.b	d0,sides.colour

	jsr	print.lap.boost.text

	move.b	#11,d2
	jsr	copy.chequered.flag.dull
	jsr	copy.stop.watch

	move.b	players.start.section,d1
	move.b	d1,opponents.road.section
	move.b	#4,opponents.distance.into.section	$400, half way into section
	move.b	#$4c,opponents.road.x.position+1
	jsr	initialise.opponent.data

	move.b	players.start.section,d1
	cmpi.b	#SLAVE,machine
	bne	rap3
	move.b	#$80,swing.from.left

rap3	jsr	set.players.restart.position
	jsr	update.wheel.positions
	jsr	initialise.sparks.table
	jsr	draw.world
	jsr	display.lap.time
	subq.b	#1,main.loop.count
	jsr	update.screens

	jsr	car.movement
	jsr	draw.world
	jsr	display.lap.time
	subq.b	#1,main.loop.count
	jsr	display.speed.bar
	jsr	update.screens

	move.b	#$80,d0
	move.b	d0,B.1bb72
	move.b	d0,B.5d724

	move.b	#3,d2
	jsr	delay
	jsr	fade.screen.in

	move.w	#$8020,sprite.DMA.value
	jsr	start.engine.sound

race.loop
	subq.b	#1,main.loop.count
	jsr	car.control

****************************************
	jsr	word.print
****************************************

	jsr	car.movement
	jsr	update.engine.revs
	jsr	draw.world
	jsr	move.draw.bridge
	jsr	display.speed.bar
	jsr	update.damage
	jsr	display.lap.time
	jsr	display.opponents.distance

	move.b	B.1bb6f,d0
	and.b	which.screen,d0
	bpl	rapa

	tst.b	B.1bbcc
	bne	rapa

	tst.b	machine
	beq	rap5

	tst.b	B.1bb76
	bne	rapa

rap5	tst.b	car.on.chains.countdown
	bne	rap6

	move.b	touching.road,d0
	beq	rapa			if not touching road

* Touching road

rap6	tst.b	laps.when.race.finished
	bne	rap8

	move.b	machine,d0
	beq	rap7

	move.b	#0,B.1bbb4
	cmp.b	B.1bbe2,d0
	bne	rap8

rap7	move.b	#11,d2
	jsr	copy.stop.watch
	move.b	#$c0,B.1bbb4

rap8	jsr	copy.message.panel
	move.b	#60,d2			press fire
	move.b	#4,d0
	jsr	initialise.race.prompts

	move.w	#-8,engine.revs.change
	move.b	#0,wheel.rotation.speed
	cmpi.b	#69,smashed.countdown
	bne	rap9

	move.b	damage.hole.position,d2
	beq	rap9
	jsr	copy.damage.hole

rap9	jsr	update.screens
	move.b	#$80,turn.engine.off
	move.b	#$80,B.57c5b
	jsr	R.57964
	jsr	sound.off
	jsr	wait.for.fire
	bra	rap11

rapa	jsr	update.screens
	jsr	pause.request
	move.b	car.on.chains.countdown,d0
	bne	rapd

	move.b	off.map.status,d2
	bpl	rapd

	move.b	touching.road,d0
	beq	rapd			if not touching road

* Touching road

	move.b	players.smaller.y,d0
	bmi	rapb

	cmpi.b	#2,d0
	bge	rapc

rapb	move.b	d2,B.1bb75

rapc	subq.b	#1,opponents.road.section.m64+1
	bpl	rapd

	addq.b	#1,opponents.road.section.m64+1
	move.b	B.1bb6c,d0
	bne	rapd

	jsr	sound.off
	move.b	B.1bb9b,d1
	jmp	rap3			lower car back onto track

rapd	tst.b	car.on.chains.countdown
	bne	rape

	tst.b	off.map.status
	bmi	race.loop

	tst.b	touching.road
	beq	race.loop		can't quit if not touching road

* Touching road

rape	move.b	#$45,d1			ESCAPE
	move.b	B.1bb64,d0
	jsr	data.link.test.key
	bne	race.loop

	tst.b	laps.when.race.finished
	bne	rap10

	move.b	machine,d0
	beq	rapf

	move.b	#0,B.1bbb4
	cmp.b	B.1bb64,d0
	bne	rap10

rapf	move.b	#$c0,B.1bbb4

rap10	jsr	R.57964

rap11	move.w	#$0020,sprite.DMA.value
	move.w	title.colours,d0
	jsr	fade.screen.out

	move.b	#0,d0
	move.b	d0,B.5d724
	jsr	sound.off
	tst.b	race.mode
	bpl	no.opponent

	tst.b	multi.no.of.players
	beq	rap14

	move.b	B.5eb79,d1
	move.l	#DAT.1ca36,a0
	move.b	damage.hole.position,(a0,d1.w)
	tst.b	machine
	beq	rap12

	move.b	opponents.ID,d1
	move.b	B.57c61,(a0,d1.w)

	cmpi.b	#4,opponents.lap
	beq	rap12

	addi.b	#12,d1
	jsr	clear.three.bytes

rap12	cmpi.b	#4,players.lap
	beq	no.opponent

	move.b	B.5eb79,d1
	addi.b	#12,d1
	jsr	clear.three.bytes

no.opponent
	move.b	B.1bbb5,damage.hole.position

rap14	jsr	save.random.values
	move.b	#$80,B.57c5b
	rts


B.5d724	dc.b	0,0


initialise.data
	move.l	#W.1baf8,a0
.clear	move.b	#0,(a0)+
	cmp.l	#near.section.flags,a0
	bne	.clear

	move.l	#league.values,a0
	move.l	#W.1baf8,a1
	move.b	league.offset,d1
	move.b	#0,d2
.copy	move.b	(a0,d1.w),(a1,d2.w)
	addq.b	#1,d1
	addq.b	#1,d2
	cmpi.b	#11,d2
	bne	.copy

	move.w	#127,old.speed.bar
	move.b	#$ba,B.1bbdd

	move.b	#2,d1
.set	move.b	#9,d0
	move.l	#DAT.1c908,a1
	move.b	d0,(a1,d1.w)
	subq.b	#1,d1
	bpl	.set

	move.b	B.5eb79,d1
	addi.b	#12,d1
	jsr	clear.three.bytes

	tst.b	machine
	beq	.nolink

	move.b	opponents.ID,d1
	addi.b	#12,d1
	jsr	clear.three.bytes

.nolink
	jsr	make.sin.cos
	move.w	#1024,y.shift
	move.w	#$ff00,W.1bc56
	jsr	sound.off

	move.b	#4,lap.that.finishes.race
	jsr	set.random.values
	move.b	#$3b,random.long+3

	move.b	standard.boost,d1
	tst.b	league.offset
	beq	standard.league3
	move.b	super.boost,d1

standard.league3
	move.b	#0,d0
	move.b	#1,d3
	andi.b	#%1111,ccr
.add	abcd.b	d3,d0
	subq.b	#1,d1
	bne	.add

	move.b	d0,boost.reserve
	move.b	d0,boost.max.units
	move.b	damage.hole.position,B.1bbb5

	move.l	#key.array,a0
	move.w	#128-1,d0
.clear.key
	move.b	#0,(a0,d0.w)
	dbra	d0,.clear.key

	move.l	#edge.space,a0
	move.w	#10000-1,d3
	move.b	#0,d0
.clear	move.b	d0,(a0)+
	dbra	d3,.clear

	jsr	set.sprite.colours
	jsr	set.CIAs

id2	move.b	#62,d1
	move.l	#coord.visible.values,a1
	move.l	#near.section.flags,a2
.set	move.w	#$8000,120(a1,d1.w)
	move.b	#$80,(a2,d1.w)
	subq.b	#2,d1
	bpl	.set
	rts


initialise.damage.bar
	tst.b	multi.no.of.players
	beq	idb

	move.b	B.5eb79,d1
	move.l	#DAT.1ca36,a0
	move.b	(a0,d1.w),damage.hole.position
idb	jmp	initialise.damage.bar2


car.control
	jsr	get.players.input
	move.b	touching.road,d0
	beq	left.right.done		if not touching road

	move.b	car.on.chains.countdown,d0
	bne	left.right.done

	move.b	players.input,d0
	andi.b	#$c,d0
	beq	left.right.done

	cmpi.b	#4,d0
	beq	car.left

car.right
	move.b	#15,d0
	bne	left.right.done

car.left
	move.b	#-15,d0

left.right.done
	move.b	d0,left.right.value

	move.b	players.input,d0
	andi.b	#$10,d0
	eori.b	#$10,d0
	move.b	d0,boost.flag

	move.b	#0,d2
	move.b	#0,d1
	move.b	players.z.speed,d0
	bmi	car.going.backwards

	cmpi.b	#$78,d0
	bcc	save.accelerate.value

car.going.backwards
	move.b	car.on.chains.countdown,d0
	bne	save.accelerate.value

	move.b	wreck.wheel.height.reduction+2,d0
	bne	save.accelerate.value

	move.b	players.input,d0
	andi.b	#3,d0
	cmpi.b	#1,d0
	beq	car.accelerate
	bgt	car.brake

	move.b	accelerating,d0
	bpl	save.accelerate.value

car.accelerate
	move.b	engine.power,d1
	move.b	engine.power+1,d2
	move.b	#$80,d0
	bne	save.accel.flag

car.brake
	move.b	#$10,d1
	move.b	#$ff,d2			$ff10 for braking
	move.b	#0,d0
save.accel.flag
	move.b	d0,accelerating

save.accelerate.value
	move.b	d1,engine.z.acceleration+1
	move.b	d2,engine.z.acceleration
	jsr	boost.power
	rts


R.5d980	move.b	#31,B.5d9da

.label1	jsr	get.players.input
	and.b	d0,B.5d9da
	bne	.label1
	move.b	players.input,d1
	move.b	d1,d0
	andi.b	#4,d0
	bne	.label3
	move.b	d1,d0
	andi.b	#8,d0
	bne	.label2
	move.b	d1,d0
	andi.b	#$10,d0
	beq	.label1

	andi.b	#%11110,ccr
	rts

.label2	subq.b	#1,B.1bb57
	ori.b	#1,ccr
	rts

.label3	addq.b	#1,B.1bb57
	ori.b	#1,ccr
	rts


B.5d9da	dc.b	0,0


pause.request
	tst.b	B.1bba4
	bmi	pr1

	move.b	#$19,d1			P
	move.b	B.1bba5,d0
	jsr	data.link.test.key
	beq	pr1
	rts

pr1	tst.b	B.1bba4
	bmi	pr2

	move.b	#$80,B.1bba4
	rts

pr2	move.b	#0,B.1bba4
	move.b	#$80,B.57c5b
	move.b	#$80,no.wheel.update
	jsr	sound.off

	move.w	#0,engine.revs.change

	move.b	prompt.required,d0
	move.w	d0,-(sp)
	move.b	prompt.offset,d0
	move.w	d0,-(sp)
	move.b	prompt.groups,d0
	move.w	d0,-(sp)

	move.l	screen2,-(sp)
	move.l	screen1,screen2		draw into visible screen
	jsr	copy.message.panel

	move.b	#76,d2			paused
	move.b	#2,d0
	jsr	signal.prompt.required
	jsr	race.prompts
	move.l	(sp)+,screen2

	jsr	unpause.request

	move.w	(sp)+,d0
	move.b	d0,prompt.groups
	move.w	(sp)+,d0
	move.b	d0,prompt.offset
	move.w	(sp)+,d0
	move.b	d0,prompt.required

	move.b	#0,B.57c5b
	move.b	#0,no.wheel.update

start.engine.sound
	move.b	#7,d0			tick over
	jsr	sound.effect
	jsr	update.engine.revs
	rts


which.screen3
	dc.b	0,0


update.screens
	tst.b	frame.count
	bne	update.screens

	eori.b	#1,which.screen3
	move.b	which.screen3,d0
	addi.b	#5,d0
	move.b	#MIN.FRAMES,frame.count

	move.l	screen.mem,d0
	move.l	d0,d3
	move.b	which.screen,d4
	eori.b	#$80,d4
	move.b	d4,which.screen
	bpl	uscr2

	move.b	#$80,which.screen2
	addi.l	#32000,d0
	jmp	uscr3

uscr2	move.b	#0,which.screen2
	addi.l	#32000,d3

uscr3	move.l	d0,screen1
	move.l	d3,screen2
	jmp	set.current.scene


display.lap.time
	addq.b	#1,B.1bbc9

	move.b	#0,d2
	move.b	#$ee,d0
	beq	dlt1

	add.b	d0,B.1bbcf
	bcs	dlt1
	subq.b	#1,d2
dlt1	move.b	d2,fourteen.frames.elapsed

	move.b	B.1bbcc,d0
	beq	dlt2

	subq.b	#1,B.1bbcc
	bne	dlt2
	jsr	show.best.lap.time

dlt2	tst.b	race.mode
	bpl	no.opponent2

	move.b	#1,d1
	tst.b	machine
	beq	dlt3

	tst.b	B.57c3a
	bne	no.opponent2

	tst.b	B.1bb76
	bne	dlt4

dlt3	jsr	add.to.lap.time
dlt4	jsr	start.of.new.lap

no.opponent2
	move.b	#0,d1
	jsr	add.to.lap.time
	jsr	copy.lap.time
	jsr	start.of.new.lap
	jsr	display.lap.time.sub

	tst.b	B.1bb75
	bpl	dlt6
	jsr	dlt6

dlt6	move.b	B.1bb6c,d0
	beq	dlt9
	bmi	dlt8

	lsr.b	#2,d0
	andi.b	#1,d0
	move.b	d0,white.prompts

	tst.b	car.on.chains.countdown
	bne	dlt7

	move.b	touching.road,d0
	bne	dlt7			if touching road

* Not touching road

	move.b	B.1bb6c,d0
	cmpi.b	#6,d0
	bcs	dlt9

dlt7	tst.b	fourteen.frames.elapsed
	bmi	dlt9

	subq.b	#1,B.1bb6c
	bne	dlt9

dlt8	move.b	#$80,d0
	move.b	d0,B.1bb6f
	move.b	d0,B.1bb6c
dlt9	rts


new.lap.sub3
	move.l	#DAT.1c938,a0
	move.l	#DAT.1c920,a1
	move.l	#DAT.1c908,a2
	move.b	(a2,d1.w),d0
	cmp.b	(a2,d2.w),d0
	bcs	nls32
	bne	nls31

	move.b	(a1,d1.w),d0
	cmp.b	(a1,d2.w),d0
	bcs	nls32
	bne	nls31

	move.b	(a0,d1.w),d0
	cmp.b	(a0,d2.w),d0
	bcs	nls32

nls31	ori.b	#1,ccr
	rts

nls32	move.l	#DAT.1c938,a1
	move.b	(a1,d1.w),(a1,d2.w)
	move.l	#DAT.1c920,a1
	move.b	(a1,d1.w),(a1,d2.w)
	move.l	#DAT.1c908,a1
	move.b	(a1,d1.w),(a1,d2.w)
	andi.b	#%11110,ccr
	rts


show.best.lap.time
	move.b	d1,d0
	move.b	d0,-(sp)
	jsr	copy.stop.watch0

	move.b	#2,d2
	move.b	#3,d1
	move.b	#$80,d0
	jsr	print.lap.time

	move.b	(sp)+,d0
	move.b	d0,d1
	rts


start.of.new.lap
	tst.b	d1
	bne	sonl1

	btst	#6,off.map.status
	bne	sonl2

sonl1	move.l	#players.road.section,a1
	move.b	(a1,d1.w),d0
	move.l	#B.1bb1e,a1
	move.b	(a1,d1.w),d2
	bpl	sonl3

	cmp.b	half.a.lap.section,d0
	bne	sonl2

	move.b	#0,(a1,d1.w)
sonl2	rts

sonl3	cmp.b	start.finish.section,d0
	bne	sonl2

	move.b	#$80,(a1,d1.w)
	move.l	#players.lap,a1
	addq.b	#1,(a1,d1.w)
	cmpi.b	#1,(a1,d1.w)
	beq	sonl5

	tst.b	machine
	beq	sonl4

	cmpi.b	#1,d1
	bne	sonl4

	tst.b	B.1bb76
	bne	sonl5

sonl4	jsr	new.lap.sub

sonl5	jsr	new.lap.sub1
	tst.b	d1
	bne	sonl7

	move.b	players.lap,d0
	cmpi.b	#1,d0
	beq	sonl6

	jsr	new.lap.sub2
	move.b	#27,d0
	move.b	d0,B.1bbcc
	jsr	show.lap.time
	jsr	copy.lap.time

sonl6	move.b	d1,edge.x1.offset

	move.b	#31,d0
	jsr	print.character
	move.b	#6,d0			column
	jsr	print.character
	move.b	#22,d0			row
	jsr	print.character

	move.b	#2,print.fine.x
	move.b	#2,print.fine.y
	move.b	players.lap,d0
	jsr	print.dec.digit1

	move.b	#0,print.fine.x
	move.b	#0,print.fine.y
	move.b	edge.x1.offset,d1

sonl7	move.l	#players.lap,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#1,d0
	beq	sonl8

	move.b	#2,d2
	jsr	new.lap.sub3
	bcs	sonl8

	move.b	d1,d0
	lsr.b	#1,d0
	roxr.b	#2,d0
	move.b	d0,B.1bbb2
	beq	sonl8

	move.b	#0,B.1bbcc
	jsr	show.best.lap.time

sonl8	jsr	clear.three.bytes
	rts


display.lap.time.sub
	move.w	#1,d1

dlts1	tst.b	laps.when.race.finished
	bne	dlts5

	move.l	#players.lap,a1
	move.b	(a1,d1.w),d0
	cmp.b	lap.that.finishes.race,d0
	bne	dlts5
	move.b	d0,laps.when.race.finished

	move.b	B.1bb6c,d0
	bne	dlts2

	move.b	#44,d0
	move.b	d0,B.1bb6c

dlts2	move.w	d1,-(sp)
	jsr	copy.chequered.flag
	move.w	(sp)+,d1
	cmpi.w	#11,d2
	beq	dlts3

	move.b	#84,d2			laps over
	tst.b	race.mode
	bpl	no.opponent3

	move.b	#8,d2			race won
	bne	no.opponent3

dlts3	move.b	#$80,d0
	move.b	d0,B.1bbb4
	move.b	#28,d2			race lost

no.opponent3
	move.b	#4,d0
	jsr	signal.prompt.required

dlts5	move.b	B.1bbb4,d0
	andi.b	#$bf,d0
	or.b	B.1bbb2,d0
	move.b	d0,B.1bbb4

	subq.b	#1,d1
	bpl	dlts1
	rts


set.print.column.row
	move.b	#31,d0
	jsr	print.character
	move.b	d1,d0			column
	jsr	print.character
	move.b	d2,d0			row
	jmp	print.character


show.lap.time
	move.b	d1,d0
	move.b	d0,-(sp)
	move.b	#2,d1
	move.b	#0,d2
	move.b	B.1bbcc,d0
	beq	slt1
	move.b	#$80,d0

slt1	jsr	print.lap.time
	move.b	(sp)+,d0
	move.b	d0,d1
	rts


print.dec.digit1
	addq.b	#1,print.fine.x
	bra	print.dec.digit2

print.dec.digit2
	addi.b	#'0',d0
	jmp	print.character


clear.three.bytes
	move.b	#0,d0
	move.l	#DAT.1c920,a1
	move.b	d0,(a1,d1.w)
	move.l	#DAT.1c938,a1
	move.b	d0,(a1,d1.w)
	move.l	#DAT.1c908,a1
	move.b	d0,(a1,d1.w)
	rts


add.to.lap.time
	move.b	#19,d0
add.to.lap.time1
	move.l	#DAT.1c938,a0
	move.l	#DAT.1c920,a1
	move.l	#DAT.1c908,a2
	andi.b	#%1111,ccr
	move.b	(a0,d1.w),d3
	abcd	d3,d0
	bcc	atlt3

	move.b	d0,(a0,d1.w)
	move.b	(a1,d1.w),d0
	move.b	#0,d3
	abcd	d3,d0
	move.b	d0,(a1,d1.w)
	cmpi.b	#96,d0
	bcs	atlt1

	move.b	#0,(a1,d1.w)
	andi.b	#%1111,ccr
	move.b	(a2,d1.w),d0
	move.b	#1,d3
	abcd	d3,d0
	cmpi.b	#10,d0
	bge	atlt1
	move.b	d0,(a2,d1.w)

atlt1	tst.b	d1
	bne	atlt2

	tst.b	B.1bbcc
	bne	atlt2

	tst.b	players.lap
	beq	atlt2
	jsr	show.lap.time
atlt2	rts

atlt3	move.b	d0,(a0,d1.w)
	rts


update.damage
	move.b	damaged,d0
	beq	no.new.damage

	move.b	front.left.damage,d0
	add.b	front.right.damage,d0
	roxr.b	#1,d0			average front damage
	add.b	rear.damage,d0
	roxr.b	#1,d0			total average damage
	move.b	d0,new.damage
	jsr	damage.line

no.new.damage
	move.b	smashed.countdown,d0
	beq	test.if.smashed

	subq.b	#1,smashed.countdown
	cmpi.b	#69,d0
	beq	change.smash.to.hole

	move.b	damaged,d0
	bne	dam4
	rts

change.smash.to.hole
	move.b	damage.hole.position,d2
	jsr	copy.damage.hole
	jmp	dam4

test.if.smashed
	move.b	damaged,d0
	beq	dam8

	move.w	damage.value,d0
	cmpi.w	#$1400,d0
	bcs	dam4

	move.b	damage.hole.position,d2
	beq	dam4
	subq.b	#1,d2
	move.b	d2,damage.hole.position

	jsr	copy.damage.hole.smashed

	move.b	#69,d0
	move.b	d0,smashed.countdown

	move.b	#10,d0
	move.b	#5,d0			smash
	bne	dam7

dam4	move.b	damage.value,d0
	cmpi.b	#7,d0
	bcc	dam5
	move.b	#7,d0

dam5	asl.b	#2,d0
	cmpi.b	#64,d0
	bcs	dam6
	move.b	#64,d0

dam6	move.b	d0,effect.table+4*16+11	creak volume
	move.b	#4,d0			creak

dam7	jsr	sound.effect
	move.b	#0,d0
	move.b	d0,damaged
dam8	rts


copy.stop.watch0
	move.b	#11,d2
	move.b	B.1bbb2,d0
	bne	copy.stop.watch
	move.b	#7,d2

copy.stop.watch
	move.b	d2,B.1bb8c
	move.b	#17,d0			stop watch bright
	cmpi.b	#7,d2
	beq	copy.stop.watch.bright
	move.b	#18,d0			stop watch dull

copy.stop.watch.bright
	bra	copy.watch.or.flag

copy.chequered.flag
	move.b	#11,d2
	jsr	calculate.if.winning
	bpl	copy.chequered.flag.dull
	move.b	#7,d2			if winning

copy.chequered.flag.dull
	move.b	d2,opponent.infront.behind.value
	move.b	#15,d0			chequered flag bright
	cmpi.b	#7,d2
	beq	copy.watch.or.flag
	move.b	#16,d0			chequered flag dull

copy.watch.or.flag
	move.w	d2,-(sp)
	move.l	screen2,-(sp)
	move.l	screen.mem,screen2
	move.w	d0,-(sp)
	jsr	copy.graphic
	move.w	(sp)+,d0

	move.l	screen2,d3
	addi.l	#32000,d3
	move.l	d3,screen2
	jsr	copy.graphic

	move.l	(sp)+,screen2
	move.w	(sp)+,d2
	rts


display.opponents.distance
	move.b	main.loop.count,d0
	andi.b	#3,d0
	beq	dod1			do every fourth frame
	rts

dod1	move.b	#0,d1			tens
	move.b	d1,d5			thousands
	move.b	#0,d2			hundreds
	move.w	smallest.distance.between.players,d0
	move.w	d0,d3
	lsr.w	#2,d3
	add.w	d3,d0
	lsr.w	#2,d0
	jmp	dod3

dod2	subi.w	#1000,d0		calculate thousands
	addq.b	#1,d5
dod3	cmpi.w	#1000,d0
	bge	dod2
	jmp	dod5

dod4	subi.w	#100,d0			calculate hundreds
	addq.b	#1,d2
dod5	cmpi.w	#100,d0
	bge	dod4
	jmp	dod7

dod6	subi.b	#10,d0			calculate tens
	addq.b	#1,d1
dod7	cmpi.b	#10,d0
	bge	dod6

	move.b	d0,road.height
	move.b	d1,factor1
	move.b	d2,road.height+1
	move.b	d5,thousands

	move.b	#1,print.fine.x
	move.b	#4,print.fine.y

	move.b	#31,d0
	jsr	print.character
	move.b	#6,d0			column
	jsr	print.character
	move.b	#23,d0			row
	jsr	print.character

	move.b	#' '-'0',d0
	tst.b	opponent.behind.player
	bpl	dod8			if player behind opponent

	move.b	#'-'-'0',d0
dod8	jsr	print.dec.digit1

	move.b	thousands,d0		print distance
	jsr	print.dec.digit1
	move.b	road.height+1,d0
	jsr	print.dec.digit1
	move.b	factor1,d0
	jsr	print.dec.digit1
	move.b	road.height,d0
	jsr	print.dec.digit1

	move.b	#0,print.fine.x
	move.b	#0,print.fine.y

	tst.b	laps.when.race.finished
	bne	dod9

	jsr	copy.chequered.flag
dod9	rts


display.speed.bar
	move.w	players.z.speed,d0
	subi.w	#$1100,d0
	bpl	dsb1
	move.w	#0,d0

dsb1	move.w	#$b700,d3
	mulu	d3,d0
	swap	d0			reduce (183 / 256)
	lsr.w	#7,d0
	cmpi.w	#128,d0			max. position on screen
	blt	dsb2

	subi.w	#128,d0
dsb2	move.w	d0,new.speed.bar

	sub.w	old.speed.bar,d0
	bne	dsb3
	jmp	dsb7

dsb3	move.l	screen.mem,a6
	add.l	#174*40+12,a6
	move.w	old.speed.bar,d4
	move.w	new.speed.bar,d5
	addq.w	#1,d4
	addq.w	#1,d5
	tst.w	d0
	bmi	dsb4

	move.b	#3,d0
	bra	dsb5

dsb4	move.b	#0,d0
	exg	d4,d5

dsb5	jsr	make.masks
	move.l	#start.masks,a5
	jsr	fill.horizontal.line	in first screen
	move.l	a6,a0
	add.l	#32000,a0
	move.w	#8-1,d3

dsb6	move.w	(a6),40(a6)		in first screen, line 2
	move.w	8000(a6),8040(a6)
	move.w	16000(a6),16040(a6)
	move.w	24000(a6),24040(a6)

	move.w	(a6),(a0)		in second screen
	move.w	8000(a6),8000(a0)
	move.w	16000(a6),16000(a0)
	move.w	24000(a6),24000(a0)

	move.w	(a6),40(a0)		in second screen, line 2
	move.w	8000(a6),8040(a0)
	move.w	16000(a6),16040(a0)
	move.w	24000(a6),24040(a0)

	add.l	#2,a6
	add.l	#2,a0
	dbra	d3,dsb6

dsb7	move.w	new.speed.bar,old.speed.bar
	rts


print.lap.time
	move.b	d2,B.1bbe8
	move.b	d0,B.1bb89
	move.l	#TAB.5e46c,a1
	move.b	4(a1,d1.w),print.fine.y
	move.b	#$80,or.with.screen

	move.b	#31,d0
	jsr	print.character
	move.b	#34,d0			column
	jsr	print.character
	move.b	(a1,d1.w),d0		row
	jsr	print.character

	move.b	#5,print.fine.x
	move.b	#':',d0
	jsr	print.character

	addq.b	#2,print.column
	subq.b	#2,print.fine.y
	move.b	#2,print.fine.x
	move.b	#'.',d0
	jsr	print.character

	move.b	#0,or.with.screen
	addq.b	#2,print.fine.y
	subq.b	#5,print.column
	move.b	#6,print.fine.x

	move.l	#DAT.1c908,a2
	move.b	(a2,d2.w),d0
	andi.b	#$f,d0
	jsr	print.dec.digit2

	addq.b	#1,print.column
	move.b	#3,print.fine.x
	move.b	B.1bbe8,d2
	move.l	#DAT.1c920,a2
	move.b	(a2,d2.w),d0
	lsr.b	#4,d0
	jsr	print.dec.digit2

	move.b	B.1bbe8,d2
	move.l	#DAT.1c920,a2
	move.b	(a2,d2.w),d0
	andi.b	#$f,d0
	jsr	print.dec.digit2

	addq.b	#4,print.fine.x
	move.b	B.1bbe8,d2
	move.l	#DAT.1c938,a2
	move.b	(a2,d2.w),d0
	lsr.b	#4,d0
	tst.b	B.1bb89
	bmi	plt1
	move.b	#$f0,d0
plt1	jsr	print.dec.digit2

	move.b	B.1bbe8,d2
	move.l	#DAT.1c938,a2
	move.b	(a2,d2.w),d0
	andi.b	#$f,d0
	tst.b	B.1bb89
	bmi	plt2
	move.b	#$f0,d0
plt2	jsr	print.dec.digit2

	move.b	#0,print.fine.x
	move.b	#0,print.fine.y
	rts


TAB.5e46c	dc.b	22,23,22,23,2,4,2,4


print.lap.boost.text
	move.b	#2,print.fine.y
	move.b	#2,print.fine.x

	move.b	#31,d0
	jsr	print.character
	move.b	#5,d0			column
	jsr	print.character
	move.b	#22,d0			row
	jsr	print.character

	move.b	#'L',d0
	jsr	print.character
	addq.b	#2,print.fine.x

	move.b	#31,d0
	jsr	print.character
	move.b	#8,d0			column
	jsr	print.character
	move.b	#22,d0			row
	jsr	print.character

	move.b	#'B',d0
	jsr	print.character

	move.b	#0,print.fine.x
	move.b	#0,print.fine.y
	rts


signal.prompt.required
	move.b	#$80,prompt.required
	move.b	d2,prompt.offset
	move.b	d0,prompt.groups
	rts


initialise.race.prompts
	jsr	signal.prompt.required

race.prompts
	tst.b	prompt.required
	bmi	rp2
rp1	rts

rp2	move.b	B.1bb6c,d0
	beq	rp4
	bmi	rp3

	cmpi.b	#3,d0
	bge	rp4

rp3	cmpi.b	#60,prompt.offset
	bne	rp1

rp4	tst.b	B.1bba4
	bmi	rp1

	move.b	#$80,or.with.screen
	move.b	#$80,second.screen

	move.b	#0,d0
	tst.b	white.prompts
	beq	rp5
	move.b	#15,d0
rp5	jsr	set.text.masks

	move.b	prompt.groups,copy.prompt.groups
	move.b	prompt.offset,d2
	move.b	d1,-(sp)
	move.b	#4,print.row
	move.b	#19,print.column
	move.b	#3,print.fine.x
	move.b	#0,print.fine.y
	cmpi.b	#2,prompt.groups
	bne	rp6
	move.b	#5,print.fine.y

rp6	move.l	#race.prompt.text,a2
	move.b	(a2,d2.w),d1
	cmpi.b	#'!',d1
	bne	rp7

	move.b	#19,print.column	to next row down
	move.b	#5,print.row
	move.b	#3,print.fine.x
	move.b	#2,print.fine.y

rp7	addq.b	#1,d2
	move.b	#3,d0			print groups of 3 chars.
	move.b	d0,prompt.chars

rp8	move.l	#race.prompt.text,a2
	move.b	(a2,d2.w),d0
	cmpi.b	#'<',d0
	bne	rp9

	addq.b	#4,print.fine.x		half a character across
	bra	rpa

rp9	jsr	print.character
	addq.b	#1,print.fine.x

rpa	addq.b	#1,d2
	addq.b	#1,d1
	subq.b	#1,prompt.chars
	bne	rp8

	subq.b	#1,copy.prompt.groups
	bne	rp6

	move.b	(sp)+,d1
	move.b	#0,or.with.screen
	move.b	#0,second.screen
	move.b	#0,print.fine.x
	move.b	#0,print.fine.y
	move.b	#0,d0
	jsr	set.text.masks
	rts


prompt.groups	dc.b	0
prompt.offset	dc.b	0


race.prompt.text
	dc.b	3,'<WRCECK'			0
	dc.b	3,' RACCE !< WaON aT  '		8
	dc.b	3,' RACCE ! LOaST '		28
	dc.b	3,' DRCOP !<STaART'		44
	dc.b	3,'<PRCESS! FIaRE '		60
	dc.b	3,'PAUCSED'			76
	dc.b	3,' LACPS ! OVaER '		84
	dc.b	3,'DEFCINE! KEaYS '		100
	dc.b	3,'<STCEER! LEaFT '		116
	dc.b	3,'<STCEER!<RIaGHT'		132
	dc.b	3,'<AHCEAD!+BOaOST'		148
	dc.b	3,' BACCK !+BOaOST'		164
	dc.b	3,' BACCK !   a   '		180
	dc.b	3,'VERCIFY! KEaYS '		196
	dc.b	3,'<FACULT!<FOaUND<T'		212
	dc.b	6,26


set.wheel.frame.number
	move.b	wheel.frame.number,d0
	tst.w	players.z.speed
	bpl	swfn1

	subq.b	#1,d0			wheels rotating backwards
	bpl	swfn2
	move.b	#2,d0
	bra	swfn2

swfn1	addq.b	#1,d0			wheels rotating forwards
	cmpi.b	#3,d0
	bcs	swfn2
	move.b	#0,d0

swfn2	move.b	d0,wheel.frame.number
	rts


update.wheel.positions
	move.b	#0,d1
	move.w	#48,d3
	move.l	#graphic.info,a2

uwp1	move.l	#new.front.left.difference,a0
	move.w	(a0,d1.w),d0
	addi.w	#256,d0
	bpl	uwp2
	move.w	#0,d0

uwp2	cmpi.w	#2048,d0
	bcs	uwp3
	move.w	#2047,d0

uwp3	lsr.w	#3,d0
	not.b	d0
	asl.w	#1,d0
	move.l	#sin.table,a1
	move.w	(a1,d0.w),d0
	rol.w	#5,d0
	andi.b	#$1f,d0
	not.b	d0
	add.b	B.1bbdd,d0
	move.b	which.side.byte,d4
	asl.w	#1,d4
	move.b	d4,which.side.byte

	btst	#8,d4
	bne	uwp4

	cmpi.b	#$ba,d0
	bcs	uwp5

uwp4	move.b	#$b9,d0

uwp5	cmpi.b	#$97,d0
	bcc	uwp6
	move.b	#$97,d0

uwp6	subi.b	#50,d0
	andi.w	#$ff,d0
	move.l	a2,a4
	add.l	#37*16,a4
	cmpi.w	#126,d0
	bge	uwp7
	add.l	#6*16,a4

uwp7	move.w	#158,d5
	sub.w	d0,d5
	move.w	#2,d4

uwp8	move.w	d0,10(a2,d3.w)
	move.w	d0,10(a4,d3.w)
	move.w	d5,6(a2,d3.w)
	addi.w	#16,d3
	dbra	d4,uwp8

	move.w	#0,d3
	addq.b	#2,d1
	cmpi.b	#4,d1
	blt	uwp1

	move.b	#$80,adjust.sprites
	rts


car.is.wrecked
	move.b	B.1bb6c,d0
	bne	wrck2

	cmpi.b	#$40,B.1bbe2
	beq	wrck1

	cmpi.b	#$80,B.1bbe2
	beq	wrck1
	move.b	machine,B.1bbe2

wrck1	move.b	#2,d0
	move.b	d0,wreck.wheel.height.reduction+2

	move.b	#$92,d0
	move.b	d0,B.1bbdd

	move.b	#$82,d0
	move.b	d0,W.1bc56

	move.b	#$3c,d0
	move.b	d0,B.1bb6c

	move.b	#2,d0
	move.b	#0,d2			wreck
	jsr	signal.prompt.required
wrck2	rts


main.menu.selection
	move.b	#$80,d0
	move.b	d0,B.5eb75

	move.b	#0,d0
	move.b	d0,multi.no.of.players
	move.b	#2,d2
	move.b	#16,d1
	jsr	get.main.menu.selection

	cmpi.b	#1,d0
	beq	multiplayer.chosen
	bgt	computer.link.chosen

single.player.league.chosen
	jsr	get.players.name
	jmp	main.menu.selection.done

multiplayer.enter.another
	move.b	#0,d0
	move.b	#1,d2
	move.b	#20,d1
	jsr	get.main.menu.selection

	cmpi.b	#0,d0
	bne	multiplayer.continue
	addq.b	#1,multi.no.of.players

multiplayer.chosen
	jsr	get.players.name
	move.b	multi.no.of.players,d0
	cmpi.b	#7,d0
	bcs	multiplayer.enter.another

multiplayer.continue
	move.b	multi.no.of.players,d0
	beq	multiplayer.enter.another

main.menu.selection.done
	move.b	#0,d0
	move.b	d0,B.5eb75
	rts

computer.link.chosen
	jsr	establish.computer.link
	bcs	main.menu.selection
	bra	main.menu.selection.done


R.5e93e	jsr	R.5acfe
	move.b	#16,d0
	move.b	d0,menu.bar.positions+14
	move.b	#14,d0
	move.b	d0,TEXT.5ec92+142
	move.b	B.1bbcb,d0
	and.b	B.5eb7a,d0
	bpl	.label4
	jsr	clear.menu
	move.b	#1,d0
	jsr	set.text.masks

	move.b	#11,d1
	move.b	#9,d2
	jsr	set.print.column.row

	move.b	#0,d1
	jsr	R.5ec7e
	move.b	multi.no.of.players,d0
	cmpi.b	#5,d0
	bcs	.label1
	jsr	four.print.fine.y

.label1	move.b	multi.no.of.players,d1
	move.l	#TAB.5eb64,a1
	move.b	(a1,d1.w),d0
	move.b	d0,d2
	addq.b	#2,d0
	move.b	d0,menu.bar.positions+14
	jsr	R.5eae0
	move.b	#0,d0
	jsr	set.text.masks
	jsr	R.5ef8e
	move.b	multi.no.of.players,d0
	cmpi.b	#6,d0
	beq	.label2
	cmpi.b	#5,d0
	beq	.label2

	jsr	clear.print.fine.y

.label2	move.b	multi.no.of.players,d1
	move.l	#TAB.5eb64+8,a1
	move.b	(a1,d1.w),d0
	move.b	d0,TEXT.5ec92+142
	addq.b	#2,d0
	move.b	multi.no.of.players,d2
	cmpi.b	#7,d2
	bne	.label3
	subq.b	#1,d0

.label3	move.b	d0,menu.bar.positions+14
	jmp	.label6

.label4	jsr	R.645c6
	move.b	#1,d0
	jsr	set.text.masks
	tst.b	B.1bbcb
	bmi	.label5

	move.b	#134,d1			'RESULTS TABLE'
	jsr	print.league.text	'DRIVER     RACED WIN LAP  PTS'

	cmpi.b	#3,B.57c67
	bcs	.label7
	move.b	#15,d0
	jsr	set.text.masks
	jsr	four.print.fine.y
	move.b	#19,d1
	jsr	R.5ec7e

	jsr	clear.print.fine.y
	jmp	.label7

.label5	move.b	#11,d2
	jsr	R.5eae0

.label6	move.b	#1,d0
	jsr	set.text.masks
	move.b	#$8c,d1
	jsr	R.5ec7e

.label7	move.b	#14,d0
	move.b	d0,B.1bb16
	move.b	multi.no.of.players,d0
	addq.b	#2,d0
	jsr	R.64b12

.label8	jsr	R.5eac8
	addq.b	#1,B.1bb5e
	jsr	R.64718
	bne	.label8
	rts


R.5eac8	move.b	#5,d1
	move.b	B.1bb5e,d2
	jsr	set.print.column.row

	addq.b	#1,B.1bb16
	rts


R.5eae0	move.b	d2,B.5eb74
	move.b	road.ID,d1
	move.l	#TAB.6129a,a0
	move.b	(a0,d1.w),d1
	subq.b	#6,d1
	tst.b	multi.no.of.players
	beq	.label1
	tst.b	league.offset
	beq	.label1
	subq.b	#2,d1

.label1	jsr	set.print.column.row

	move.b	#15,d0
	jsr	set.text.masks
	move.b	#$93,d1
	jsr	R.5a67c
	move.b	road.ID,d1
	jsr	print.track.name
	move.b	multi.no.of.players,d0
	beq	.label2
	move.b	league.offset,d0
	beq	.label2

	move.b	#33,d1
	move.b	B.5eb74,d2
	jsr	set.print.column.row

	move.b	#99,d1
	jsr	R.5a67c

.label2	rts


TAB.5eb64
	dc.b	12,12,12,12,11,11,10,10,19,19,19,18,17,16,15,15


B.5eb74	dc.b	0
B.5eb75	dc.b	0
multi.no.of.players	dc.b	0
B.5eb77	dc.b	0
B.5eb78	dc.b	6
B.5eb79	dc.b	11
B.5eb7a	dc.b	0
B.5eb7b	dc.b	0
B.5eb7c	dc.b	0
B.5eb7d	dc.b	0
B.5eb7e	dc.b	0


main.game.selection.text
	dc.b	31,17,11,'SELECT',255
	dc.b	'Single Player League',255
	dc.b	'Multiplayer',255
	dc.b	'Enter another driver',255
	dc.b	'Continue',255
	dc.b	'Tracks in DIVISION ',255
	dc.b	0,0,0,0,0,0
	dc.b	' S.',255
	dc.b	'        s',255
	dc.b	'Computer Link',255
	dc.b	'ssssssssssssssssssss'
	dc.b	'Track:  The ',255
	dc.b	31,10,9,'DRIVERS CHAMPIONSHIP',255
	dc.b	31,14,20,'Track record',255
	dc.b	0


TEXT.5ec48
	dc.b	'------------',255
	dc.b	'------------',255
	dc.b	31,12,15,'New track record',255


R.5ec76	jsr	print.character
	addq.b	#1,d1

R.5ec7e	move.l	#TEXT.5ec92,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#$ff,d0
	bne	R.5ec76
	rts


TEXT.5ec92
	dc.b	'TRACK BONUS POINTS',255
	dc.b	31,14,12,'FINAL SEASON',255
	dc.b	'Race Time: ',255
	dc.b	'Best Lap : ',255
	dc.b	31,16,1,'HALL of FAME',255
	dc.b	31,16,5,'SUPER LEAGUE',255
	dc.b	31,0,7,'TRACK  DRIVER   LAP-TIME    DRIVER  RACE-TIME',255
	dc.b	31,6,14,'DRIVER      BEST-LAP RACE-TIME',255


R.5ed40	move.l	#DAT.1c908,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#9,d0
	bcc	.label1
	move.l	#DAT.1c920,a1
	or.b	(a1,d1.w),d0
	beq	.label1

	move.l	#DAT.1c908,a1
	move.b	(a1,d1.w),d0
	jsr	print.dec.digit2
	move.b	#58,d0
	jsr	print.character
	move.l	#DAT.1c920,a1
	move.b	(a1,d1.w),d0
	jsr	R.5edee
	move.b	#46,d0
	jsr	print.character
	move.l	#DAT.1c938,a1
	move.b	(a1,d1.w),d0
	jmp	R.5edee

.label1	move.b	#45,d0
	move.b	#7,d2

.label2	jsr	print.character
	subq.b	#1,d2
	bne	.label2
	rts


R.5edba	move.b	d0,-(sp)
	jsr	R.5ef2e
	move.b	(sp)+,d0
	jmp	R.5edd2


R.5edca	cmpi.b	#10,d0
	bcs	R.5edfe

R.5edd2	cmpi.b	#10,d0
	bcc	.label1
	move.b	d0,-(sp)
	jsr	R.5ef38
	jmp	R.5edf8

.label1	jsr	R.5f028

R.5edee	move.b	d0,-(sp)
	lsr.b	#4,d0
	jsr	print.dec.digit2

R.5edf8	move.b	(sp)+,d0
	andi.b	#$f,d0

R.5edfe	jmp	print.dec.digit2


new.lap.sub2.sub1
	move.l	#DAT.1c938,a0
	move.l	#DAT.1c920,a1
	move.l	#DAT.1c908,a2
	andi.b	#%1111,ccr
	move.b	(a0,d1.w),d3
	move.b	(a0,d2.w),d0
	abcd	d3,d0
	move.b	d0,(a0,d2.w)
	move.b	(a1,d1.w),d3
	move.b	(a1,d2.w),d0
	abcd	d3,d0
	bcs	nls2s11

	cmpi.b	#$60,d0
	bcs	nls2s12

nls2s11	move.b	#$60,d3
	andi.b	#%1111,ccr
	sbcd	d3,d0
	ori.b	#%10000,ccr
	bra	nls2s13

nls2s12	andi.b	#%1111,ccr

nls2s13	move.b	d0,(a1,d2.w)
	move.b	(a2,d1.w),d3
	move.b	(a2,d2.w),d0
	abcd	d3,d0
	move.b	d0,(a2,d2.w)
	rts


R.5ee68	move.b	#6,d1
	tst.b	multi.no.of.players
	beq	.label5
	move.b	#1,d1
	move.b	#1,B.5eb77

.label1	move.b	d1,factor1
	move.b	d1,d0
	move.b	B.1c9ce,d2
	beq	.label3

	jsr	randomize.long
	andi.b	#1,d0
	addq.b	#1,d0
	add.b	B.5eb7e,d0
	cmpi.b	#3,d0
	bcs	.label2
	subq.b	#3,d0

.label2	move.b	d0,B.5eb7e

.label3	move.l	#TAB.5ab42,a0
	move.l	#opponents.names.source+224,a1
	move.l	#opponent.attributes,a2
	move.l	#opponents.names.source,a3
	move.l	#opponents.names,a4
	move.l	#DAT.59140,a5
	add.b	(a0,d2.w),d0
	move.b	d0,d2
	move.b	d0,(a5,d1.w)
	move.b	(a1,d2.w),(a2,d1.w)
	asl.b	#4,d1
	asl.b	#4,d2
	move.w	#15,d3

.label4	move.b	(a3,d2.w),(a4,d1.w)
	addq.b	#1,d1
	addq.b	#1,d2
	dbra	d3,.label4

	move.b	factor1,d1
	subq.b	#1,d1
	bpl	.label1
	move.b	multi.no.of.players,d1
	addq.b	#1,d1

.label5	move.b	d1,B.5eb78
	move.b	#0,B.5eb7b
	rts


R.5ef24	move.b	#32,d0
	jsr	print.character

R.5ef2e	move.b	#32,d0
	jsr	print.character

R.5ef38	move.b	#32,d0
	jmp	print.character


R.5ef42	tst.b	machine
	beq	.label1

	cmpi.b	#2,multi.no.of.players
	blt	.label2

.label1	move.b	#$80,d0
	move.b	d0,B.5eb7a
	jsr	R.5ef76
	jsr	R.646e8
	clr.b	B.5eb7a
.label2	rts


R.5ef76	move.b	#$80,d0
	move.b	d0,B.1bbcb
	jsr	R.646e8
	clr.b	B.1bbcb
	rts


R.5ef8e	move.b	#0,d0
	jsr	set.text.masks
	move.b	#14,d0
	move.b	d0,B.1bb16
	move.b	#0,B.64c18
	move.b	#3,d0
	jsr	R.64b12
	move.b	#35,d1
	jsr	R.5ec7e
	move.b	B.1ca24,d1
	beq	.label1

	move.l	#DAT.1c9de,a1
	addq.b	#1,(a1,d1.w)
	jsr	print.opponents.name

	move.b	#233,d1			' 2pts'
	jsr	print.league.text

.label1	move.b	#5,d1
	move.b	B.1bb5e,d2
	addq.b	#1,d2
	jsr	set.print.column.row

	move.b	#47,d1
	jsr	R.5ec7e
	move.b	B.1ca23,d1
	beq	.label2
	move.l	#DAT.1c9ea,a1
	addq.b	#1,(a1,d1.w)
	jsr	print.opponents.name

	move.b	#239,d1			' 1pt'
	jsr	print.league.text

.label2	jmp	R.5acfe


R.5f028	andi.b	#%1111,ccr
	move.w	d1,-(sp)
	clr.w	d1
	move.b	d0,d1
	beq	.label3
	move.b	#1,d3
	clr.b	d0
	bra	.label2

.label1	abcd.b	d3,d0

.label2	dbra	d1,.label1

.label3	move.w	(sp)+,d1
	rts


****************************************


R.5f04a	move.l	#DAT.7a41a,a0
	move.l	#TAB.7a01a,a1
	move.w	#192-1,d0
	tst.b	B.1ca31
	bne	.label2

.label1	move.b	(a0)+,(a1)+
	dbra	d0,.label1
	rts

.label2	move.b	(a1)+,(a0)+
	dbra	d0,.label2
	rts


****************************************


R.5f074	move.b	B.1bbb1,d0
	beq	.label3

	move.b	#1,d0
	jsr	set.text.masks
	move.b	#$b8,d1
	move.b	#4,B.64c18
	move.b	#3,d0
	move.b	d0,B.1bb16
	move.b	B.1bbb1,d0
	andi.b	#1,d0
	beq	.label1
	move.b	#$e3,d1
	move.b	#1,d2
	move.b	#16,d0
	move.b	d0,B.1bb16
	move.b	d2,B.64c18
	jsr	R.5a67c
	move.b	B.1bbb1,d0
	andi.b	#$c0,d0
	cmpi.b	#$c0,d0
	bne	.label1
	move.b	#111,d1
	jsr	R.5a67c

.label1	move.b	#0,d0
	jsr	set.text.masks
	move.b	#3,d0
	jsr	R.64b12
	tst.b	B.1bbb1
	bpl	.label2
	move.b	#35,d1
	jsr	R.5ec7e
	move.b	#214,d1
	jsr	R.5a67c
	jsr	R.5ef38
	move.b	#15,d1
	jsr	R.5ed40

.label2	btst	#6,B.1bbb1
	beq	.label3

	move.b	#5,d1
	move.b	B.1bb5e,d2
	addq.b	#1,d2
	jsr	set.print.column.row

	move.b	#47,d1
	jsr	R.5ec7e
	move.b	#201,d1
	jsr	R.5a67c
	jsr	R.5ef38
	move.b	#14,d1
	jmp	R.5ed40

.label3	rts


new.lap.sub2
	move.w	d1,-(sp)
	move.b	#12,d2
	jsr	new.lap.sub3
	bcs	nls21

	move.b	B.5eb79,d0
	move.b	d0,B.1ca23

nls21	move.b	#14,d2
	jsr	new.lap.sub3
	bcs	nls22

	move.b	#201,d2
	jsr	R.5f21e			copy player's name

	move.b	B.1bbb1,d0
	ori.b	#65,d0
	move.b	d0,B.1bbb1

nls22	move.b	B.5eb79,d2
	jsr	new.lap.sub3

	addi.b	#12,d2
	jsr	new.lap.sub2.sub1

	move.b	players.lap,d0
	cmpi.b	#4,d0
	bne	nls24

	move.b	d2,d0
	move.b	d0,d1
	move.b	#13,d2
	jsr	new.lap.sub3
	bcs	nls23

	move.b	B.5eb79,d0
	move.b	d0,B.1ca24

nls23	move.b	#15,d2
	jsr	new.lap.sub3
	bcs	nls24

	move.b	#214,d2
	jsr	R.5f21e

	move.b	B.1bbb1,d0
	ori.b	#$81,d0
	move.b	d0,B.1bbb1

nls24	move.w	(sp)+,d1
	rts


R.5f21e	move.w	d1,-(sp)
	move.b	B.5eb79,d0
	asl.b	#4,d0
	move.b	d0,d1
	move.b	#12,d0
	move.b	d0,value
.loop
	move.l	#opponents.names+1,a1
	move.b	(a1,d1.w),d0
	move.l	#main.game.selection.text,a2
	move.b	d0,(a2,d2.w)
	addq.b	#1,d1
	addq.b	#1,d2
	subq.b	#1,value
	bne	.loop
	move.w	(sp)+,d1
	rts


R.5f25a	move.b	d0,value
	move.b	road.ID,d1
	move.l	#TAB.648c2,a1
	move.b	(a1,d1.w),d0
	move.b	league.offset,d2
	beq	.label1
	addi.b	#8,d0

.label1	asl.b	#4,d0
	move.b	d0,d1
	move.b	#0,d2
	tst.b	value
	bmi	.label3

.label2	move.l	#TEXT.5ec48,a2
	move.b	(a2,d2.w),d0
	move.l	#TEXT.7a61a,a1
	move.b	d0,(a1,d1.w)
	move.l	#TEXT.5ec48+13,a2
	move.b	(a2,d2.w),d0
	move.l	#TEXT.7a71a,a1
	move.b	d0,(a1,d1.w)
	addq.b	#1,d1
	addq.b	#1,d2
	cmpi.b	#12,d2
	bne	.label2
	move.l	#TEXT.7a61a,a1
	move.b	DAT.1c908+14,(a1,d1.w)
	move.b	DAT.1c920+14,1(a1,d1.w)
	move.b	DAT.1c938+14,2(a1,d1.w)
	move.l	#TEXT.7a71a,a1
	move.b	DAT.1c908+15,(a1,d1.w)
	move.b	DAT.1c920+15,1(a1,d1.w)
	move.b	DAT.1c938+15,2(a1,d1.w)
	rts

.label3	move.l	#TEXT.7a61a,a1
	move.b	(a1,d1.w),d0
	move.l	#TEXT.5ec48,a2
	move.b	d0,(a2,d2.w)
	move.l	#TEXT.7a71a,a1
	move.b	(a1,d1.w),d0
	move.l	#TEXT.5ec48+13,a2
	move.b	d0,(a2,d2.w)
	addq.b	#1,d1
	addq.b	#1,d2
	cmpi.b	#12,d2
	bne	.label3
	move.l	#TEXT.7a61a,a1
	move.b	(a1,d1.w),DAT.1c908+14
	move.b	1(a1,d1.w),DAT.1c920+14
	move.b	2(a1,d1.w),DAT.1c938+14
	move.l	#TEXT.7a71a,a1
	move.b	(a1,d1.w),DAT.1c908+15
	move.b	1(a1,d1.w),DAT.1c920+15
	move.b	2(a1,d1.w),DAT.1c938+15
	rts


****************************************


R.5f374	move.b	B.1ca31,d3
	eor.b	d3,d0
	bne	.label4

	move.b	B.1bb94,d0
	bmi	.label4

	move.b	B.1bb6b,d0
	bmi	.label4
	beq	R.5f04a

	cmpi.b	#$40,d0
	beq	.label2
	jmp	R.5f8a8

.label2	move.b	B.1ca31,d0
	beq	.label5
	move.b	#0,d1

.label3	move.l	#TEXT.7a61a,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.7a41a,a1
	move.b	d0,(a1,d1.w)
	move.l	#TEXT.7a71a,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.7a51a,a1
	move.b	d0,(a1,d1.w)
	subq.b	#1,d1
	bne	.label3
	jsr	R.5f87c

.label4	rts

.label5	jsr	R.5f892
	bcs	.label4
	move.l	#DAT.7a41a,a0
	move.l	#TEXT.7a61a,a1
	move.b	#0,d1

.label6	move.b	12(a0,d1.w),d0
	cmp.b	12(a1,d1.w),d0
	bcs	.label7
	bne	.label9
	move.b	13(a0,d1.w),d0
	cmp.b	13(a1,d1.w),d0
	bcs	.label7
	bne	.label9
	move.b	14(a0,d1.w),d0
	cmp.b	14(a1,d1.w),d0
	bcc	.label9

.label7	move.b	#16,d2

.label8	move.b	(a0,d1.w),(a1,d1.w)
	addq.b	#1,d1
	subq.b	#1,d2
	bne	.label8
	jmp	.labela

.label9	addi.b	#16,d1
.labela	cmpi.b	#0,d1
	bne	.label6

	move.l	#DAT.7a51a,a0
	move.l	#TEXT.7a71a,a1

.labelb	move.b	12(a0,d1.w),d0
	cmp.b	12(a1,d1.w),d0
	bcs	.labelc
	bne	.labele
	move.b	13(a0,d1.w),d0
	cmp.b	13(a1,d1.w),d0
	bcs	.labelc
	bne	.labele
	move.b	14(a0,d1.w),d0
	cmp.b	14(a1,d1.w),d0
	bcc	.labele

.labelc	move.b	#16,d2

.labeld	move.b	(a0,d1.w),(a1,d1.w)
	addq.b	#1,d1
	subq.b	#1,d2
	bne	.labeld
	jmp	.labelf

.labele	addi.b	#16,d1
.labelf	cmpi.b	#0,d1
	bne	.labelb
	jmp	.label4


****************************************


R.5f4b6	move.b	#0,d2
	move.b	#3,d1

.label1	move.l	#opponents.names+193,a1
	move.b	(a1,d1.w),d0
	move.l	#TEXT.5f586+4,a1
	cmp.b	(a1,d1.w),d0
	bne	.label2
	subq.b	#1,d1
	bpl	.label1
	move.b	#64,d2
	bne	.label4

.label2	move.b	#1,d1

.label3	move.l	#opponents.names+193,a1
	move.b	(a1,d1.w),d0
	move.l	#TEXT.5f586+8,a1
	cmp.b	(a1,d1.w),d0
	bne	.label4
	subq.b	#1,d1
	bpl	.label3
	move.b	#1,d2

.label4	move.b	d2,B.1bb6b
	move.b	B.1ca31,d0
	beq	.label5
	move.b	d2,d0
	beq	.label6
	cmpi.b	#1,d2
	bne	.label5
	move.b	multi.no.of.players,d0
	beq	.label7

.label5	andi.b	#%11110,ccr
	rts

.label6	move.b	multi.no.of.players,d0
	beq	.label5

.label7	jsr	four.print.fine.y

	move.b	#6,d1
	move.b	#22,d2
	jsr	set.print.column.row

	move.b	#87,d1
	jsr	R.5f6f2
	jsr	release.and.wait.for.key
	move.b	#25,d1

.label8	move.b	#127,d0
	jsr	print.character
	subq.b	#1,d1
	bne	.label8

	jsr	clear.print.fine.y
	ori.b	#1,ccr
	rts


TEXT.5f586
	dc.b	'DIR HALLMP$',0


R.5f592	move.b	B.1bb94,d0
	bmi	.label1
	move.b	B.1bb6b,d0
	bmi	.label4

.label1	jsr	show.title.screen
	move.b	#1,d0
	move.b	d0,B.1bb16
	jsr	fill.bar
	move.b	#12,d1
	jsr	print.opponents.name
	move.b	B.1bb94,d0
	bpl	.label2
	move.b	#0,d1
	jsr	R.5f6f2

.label2	move.b	B.1ca31,d2
	move.l	#TEXT.5f636,a2
	move.b	(a2,d2.w),d1
	jsr	R.5f6f2
	move.b	B.1bb94,d0
	bpl	.label3
	jsr	fill.bar
	move.b	B.1bb94,d2
	addq.b	#2,d2
	andi.b	#7,d2
	move.l	#TEXT.5f636,a2
	move.b	(a2,d2.w),d1
	jsr	R.5f6f2

.label3	jsr	fade.screen.in
	jsr	wait.for.fire
	jsr	clear.print.fine.y

.label4	move.b	B.1bb94,d0
	rts


TEXT.5f636
	dc.b	5,13,'C',20,'*CCCq',143,148
	dc.b	' NOT',255
	dc.b	' loaded',255
	dc.b	' saved',255
	dc.b	'Incorrect data found ',255
	dc.b	'File name already exists',255
	dc.b	'Problem encountered',255
	dc.b	'File name is not suitable',255
	dc.b	31,5,19,'Insert game position save ',255
	dc.b	'tape',255
	dc.b	'disc',255
	dc.b	127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,255


R.5f6ea	jsr	print.character
	addq.b	#1,d1

R.5f6f2	move.l	#TEXT.5f636+11,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#$ff,d0
	bne	R.5f6ea
	rts
	rts


****************************************


R.5f708	move.w	W.5f720,d0
	asl.w	#2,d0
	add.w	W.5f720,d0
	move.w	d0,W.5f720
	lsr.w	#2,d0
	rts


****************************************


W.5f720	dc.w	$683b


R.5f722	move.b	#0,d0
	jmp	R.5f730

R.5f72c	move.b	#$80,d0

R.5f730	move.b	d0,B.1bb16
	move.l	#DAT.7a41a,road.data.offset
	move.w	#$683b,W.5f720
	move.b	#0,d1

.label1	jsr	R.5f708
	move.l	#DAT.7a81a,a1
	move.b	d0,(a1,d1.w)
	addq.b	#1,d1
	bne	.label1

	move.b	#15,d2
	tst.b	B.1bb16
	bmi	.label2
	move.b	joystick.reads,d0
	move.l	road.data.offset,a0
	move.b	d0,(a0,d2.w)
	jmp	R.5f796

.label2	move.l	road.data.offset,a0
	move.b	(a0,d2.w),d0
	move.b	d0,joystick.reads

R.5f796	move.b	#0,d2
	move.l	road.data.offset,a0
	move.l	#DAT.7a81a,a1
	tst.b	B.1bb16
	bmi	.label3
	move.b	d2,d0
	move.b	#$ef,d2
	move.b	d0,(a0,d2.w)
	move.b	#31,d2
	move.b	d0,(a0,d2.w)
	move.b	#$ff,d2
	move.b	d0,(a0,d2.w)
	move.b	d0,d2

.label3	move.b	#0,d1

.label4	move.b	(a0,d2.w),d0
	move.b	d0,road.height
	move.b	d1,thousands
	move.b	joystick.reads,d1
	move.b	(a1,d1.w),d0
	addq.b	#1,joystick.reads
	move.b	thousands,d1
	addq.b	#1,d1
	tst.b	B.1bb16
	bpl	.label5
	cmp.b	road.height,d1
	beq	.label6
	bne	.label4

.label5	cmp.b	road.height,d0
	bne	.label4
	move.b	d1,d0

.label6	move.l	road.data.offset,a0
	move.b	d0,(a0,d2.w)
	move.b	joystick.reads,d0
	add.b	(a1,d1.w),d0
	move.b	d0,joystick.reads
	cmpi.b	#14,d2
	bne	.label7
	addq.b	#1,d2

.label7	addq.b	#1,d2
	bne	.label3
	tst.b	B.1bb16
	bpl	.label8
	move.b	#$ef,d2
	move.b	(a0,d2.w),d0
	move.b	#$ff,d2
	or.b	(a0,d2.w),d0
	move.b	#31,d2
	or.b	(a0,d2.w),d0
	beq	.label8
	move.b	#$81,d0
	move.b	d0,B.1bb94
	ori.b	#1,ccr

.label8	rts


****************************************


R.5f87c	jsr	R.5f722
	addi.l	#$100,road.data.offset
	jmp	R.5f796


****************************************


R.5f892	jsr	R.5f72c
	addi.l	#$100,road.data.offset
	jmp	R.5f796


****************************************


R.5f8a8	move.b	B.1ca31,d0
	beq	.label4
	move.b	#127,d1

.label1	move.l	#opponents.names+64,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.7a41a+32,a1
	move.b	d0,(a1,d1.w)
	cmpi.b	#$3c,d1
	bcc	.label2
	move.l	#DAT.1c9de,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.7a41a+160,a1
	move.b	d0,(a1,d1.w)

.label2	cmpi.b	#12,d1
	bcc	.label3
	move.l	#DAT.1ca36,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.7a41a+224,a1
	move.b	d0,(a1,d1.w)

.label3	subq.b	#1,d1
	bpl	.label1
	move.b	multi.no.of.players,d0
	move.b	d0,DAT.7a41a+220
	jsr	R.5f722
	rts

.label4	jsr	R.5f72c
	bcs	.label8
	move.b	#127,d1

.label5	move.l	#DAT.7a41a+32,a1
	move.b	(a1,d1.w),d0
	move.l	#opponents.names+64,a1
	move.b	d0,(a1,d1.w)
	cmpi.b	#$3c,d1
	bcc	.label6
	move.l	#DAT.7a41a+160,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.1c9de,a1
	move.b	d0,(a1,d1.w)

.label6	cmpi.b	#12,d1
	bcc	.label7
	move.l	#DAT.7a41a+224,a1
	move.b	(a1,d1.w),d0
	move.l	#DAT.1ca36,a1
	move.b	d0,(a1,d1.w)

.label7	subq.b	#1,d1
	bpl	.label5
	move.b	DAT.7a41a+220,d0
	move.b	d0,multi.no.of.players

.label8	rts


****************************************


R.5f98a	move.b	#$50,d1			F1
	jsr	test.key
	bne	.labelc

	move.l	screen2,-(sp)
	move.l	screen1,screen2

.label1	jsr	copy.message.panel
	move.b	#100,d2
	move.b	#4,d0
	jsr	initialise.race.prompts
	move.b	#1,TAB.5fadc+1

.label2	move.b	#40,d2
	jsr	delay
	move.b	#4,d1

.label3	jsr	copy.message.panel
	move.b	d1,TAB.5fadc
	move.l	#TAB.5fadc+7,a1
	move.b	(a1,d1.w),d2
	move.b	#4,d0
	jsr	initialise.race.prompts

.label4	move.b	#103,d1

.label5	move.b	d1,road.height
	jsr	test.key
	bne	.label9
	move.b	road.height,d0
	move.b	TAB.5fadc,d1
	move.l	#TAB.5fadc+2,a1
	move.b	(a1,d1.w),d2
	move.l	#control.keys,a2
	tst.b	TAB.5fadc+1
	bne	.label6
	cmp.b	(a2,d2.w),d0
	beq	.label7
	jsr	copy.message.panel
	move.b	#212,d2
	move.b	#4,d0
	jsr	initialise.race.prompts
	move.b	#40,d2
	jsr	delay
	jmp	.label1

.label6	move.b	d0,(a2,d2.w)

.label7	move.b	#0,d0
	jsr	sound.effect

.label8	move.b	road.height,d1
	jsr	test.key
	beq	.label8
	move.b	#3,d2
	jsr	delay
	jmp	.labela

.label9	move.b	road.height,d1
	subq.b	#1,d1
	bne	.label5
	bra	.label4

.labela	move.b	TAB.5fadc,d1
	subq.b	#1,d1
	bpl	.label3
	jsr	copy.message.panel
	subq.b	#1,TAB.5fadc+1
	bmi	.labelb
	move.b	#196,d2
	move.b	#4,d0
	jsr	initialise.race.prompts
	jmp	.label2

.labelb	move.b	#76,d2
	move.b	#2,d0
	jsr	initialise.race.prompts
	move.l	(sp)+,screen2

.labelc	rts


TAB.5fadc
	dc.b	$00,$00,$00,$01,$04,$03,$02,$b4,$a4,$94,$84,$74


copy.message.panel
	move.b	#51,d0			message panel
	jmp	copy.graphic


R.5faf2	move.b	d0,value
	move.b	multi.no.of.players,d0
	beq	.label2

	move.b	B.5eb79,d0
	jsr	R.58472
	move.l	#control.keys,a1
	tst.b	value
	bpl	.label3

.label1	move.b	(a2,d2.w),(a1,d1.w)
	subq.b	#1,d2
	subq.b	#1,d1
	bpl	.label1

.label2	rts

.label3	jsr	R.5848a
	jmp	R.583e8


TAB.5fb3a
 dc.b	$2a,$40,$21,$22,$44,$2a,$40,$21,$22,$44,$2a,$40,$21,$22,$44,$2a
 dc.b	$40,$21,$22,$44,$2a,$40,$21,$22,$44,$2a,$40,$21,$22,$44,$2a,$40
 dc.b	$21,$22,$44,$2a,$40,$21,$22,$44


R.5fb62	move.b	#$80,d0
	move.b	d0,B.5eb75
	bclr	#0,B.5eb7d
	bne	.label

	move.b	#3,d2
	move.b	B.1c9ce,d0
	eori.b	#3,d0
	move.b	#24,d1
	jsr	get.main.menu.selection
	eori.b	#3,d0
	move.b	d0,B.5eb7c

.label	move.b	#$40,B.5eb75
	move.b	#2,d2
	move.b	race.mode,d0
	andi.b	#1,d0
	move.b	#28,d1
	jsr	get.main.menu.selection
	move.b	#0,d2
	move.b	d2,B.5eb75
	rts


R.5fbc6	move.b	#66,B.5d724
	move.w	hallfame.colours,d0
	jsr	fade.screen.out

	move.l	screen2,-(sp)
	move.l	screen1,screen2
	move.b	#127,d1
	move.b	#127,d2
	move.b	league.offset,d0
	beq	.label1
	move.b	#$ff,d2

.label1	move.l	#TEXT.7a61a,a2
	move.b	(a2,d2.w),d0
	move.l	#road.section.angle.and.piece,a1
	move.b	d0,(a1,d1.w)
	move.l	#TEXT.7a71a,a2
	move.b	(a2,d2.w),d0
	move.l	#overall.left.y.shifts+28,a1
	move.b	d0,(a1,d1.w)
	subq.b	#1,d2
	subq.b	#1,d1
	bpl	.label1
	move.l	#hallfame.colours,a1
	jsr	copy.st.dest.colours
	move.b	#15,d0
	jsr	set.text.masks
	move.b	#$80,or.with.screen
	move.l	#hallfame.crunched,a0
	move.l	screen1,a1
	jsr	decrunch
	move.b	#2,print.fine.x
	move.b	#59,d1
	move.b	league.offset,d0
	beq	.label2
	move.b	#7,d0
	jsr	set.text.masks
	move.b	#75,d1
	jsr	R.5ec7e

.label2	move.b	#8,d0
	jsr	set.text.masks
	move.b	#91,d1
	jsr	R.5ec7e
	move.b	#7,B.1bb16

.label3	move.b	#7,d0
	sub.b	B.1bb16,d0
	asl.b	#1,d0
	addi.b	#9,d0
	move.b	d0,d2
	move.b	#0,d1
	jsr	set.print.column.row

	move.b	B.1bb16,d0
	asl.b	#1,d0
	move.b	d0,d1
	move.b	#1,d0
	move.b	d0,print.fine.x
	move.b	#15,d0
	jsr	set.text.masks
	move.l	#TEXT.5fde0,a1
	move.b	(a1,d1.w),d0
	jsr	print.character
	move.l	#TEXT.5fde0+1,a1
	move.b	(a1,d1.w),d0
	jsr	print.character
	jsr	R.5ef38
	move.b	#4,print.fine.x
	move.b	#0,prompt.chars

.label4	move.b	B.1bb16,d0
	asl.b	#4,d0
	or.b	prompt.chars,d0
	move.b	d0,d1
	move.b	#7,d0
	jsr	set.text.masks
	move.b	#12,d2

.label5	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	jsr	print.character
	addq.b	#1,d1
	subq.b	#1,d2
	bne	.label5
	move.b	#15,d0
	jsr	set.text.masks
	jsr	R.5ef38
	subq.b	#1,print.fine.x
	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),DAT.1c908
	move.b	1(a1,d1.w),DAT.1c920
	move.b	2(a1,d1.w),DAT.1c938
	move.b	#0,d1
	jsr	R.5ed40
	move.b	prompt.chars,d0
	eori.b	#$80,d0
	move.b	d0,prompt.chars
	bpl	.label6
	jsr	R.5ef2e
	move.b	#2,d0
	move.b	d0,print.fine.x
	jmp	.label4

.label6	subq.b	#1,B.1bb16
	bpl	.label3
	move.b	#0,d0
	move.b	d0,print.fine.x
	jsr	fade.screen.in
	jsr	wait.for.fire
	move.l	(sp)+,screen2
	jmp	show.title.screen


TEXT.5fde0
	dc.b	'LR'
	dc.b	'HB'
	dc.b	'SS'
	dc.b	'BR'
	dc.b	'HJ'
	dc.b	'RC'
	dc.b	'SJ'
	dc.b	'DB'


R.5fdf0	jsr	make.masks
	move.w	#4000-1,d0

.loop	move.l	d6,(a0)+
	move.l	d7,(a0)+
	dbra	d0,.loop
	rts


****************************************


get.valid.map.number
	move.b	players.map.z,d0
	add.b	map.z.shift,d0
	cmpi.b	#16,d0
	bcc	gvmn1

	asl.b	#4,d0
	move.b	d0,value

	move.b	players.map.x,d0
	add.b	map.x.shift,d0
	cmpi.b	#16,d0
	bcc	gvmn1

	andi.b	#$f,d0
	or.b	value,d0
	move.b	d0,d1
	move.l	#road.under.map,a1
	move.b	(a1,d1.w),d0
	andi.b	#%11110,ccr
	rts

gvmn1	ori.b	#1,ccr
	rts


****************************************


fetch.near.section.stuff

* d1.w = road section

	move.l	#left.y.coordinate.IDs,a1
	move.b	(a1,d1.w),d2
	move.b	d2,y.coords.stored.as.words
	asl.b	#1,d2
	move.l	#y.coordinate.offsets,a2
	move.w	(a2,d2.w),left.y.coord.offset

	move.l	#right.y.coordinate.IDs,a1
	move.b	(a1,d1.w),d2
	asl.b	#1,d2
	move.b	#0,d0
	roxl.b	#1,d0
	asl.b	#1,d0
	move.b	d0,other.road.line.colour
	move.l	#y.coordinate.offsets,a2
	move.w	(a2,d2.w),d0
	move.w	d0,right.y.coord.offset

	asl.b	#1,d1
	move.l	#overall.left.y.shifts,a1
	move.w	(a1,d1.w),overall.left.y.shift

	move.l	#overall.right.y.shifts,a1
	move.w	(a1,d1.w),overall.right.y.shift
	lsr.b	#1,d1

	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$c0,d0
	move.b	d0,rough.piece.angle

	move.b	(a1,d1.w),d0
	andi.b	#$10,d0
	asl.b	#3,d0
	move.b	d0,plus.180.degrees

	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	move.b	d0,near.section.piece

	asl.b	#1,d0
	move.b	d0,d2
	move.l	#piece.data.offsets,a2
	move.w	(a2,d2.w),piece.data.offset

	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a0
	move.b	1(a0),near.section.byte1

	move.b	0(a0),d2
	move.b	(a0,d2.w),d0
	addq.b	#1,d2
	move.b	d0,d3
	move.b	d0,number.of.coords
	asl.b	#1,d3
	move.b	d3,offset.for.after.last.coord
	subq.b	#2,d0
	move.b	d0,number.of.coords.minus2
	asl.b	#1,d0
	move.b	d0,offset.for.last.two.coords
	move.b	number.of.coords,d0
	lsr.b	#1,d0
	subq.b	#1,d0
	move.b	d0,number.of.segments

	move.b	(a0,d2.w),d0
	addq.b	#1,d2
	lsr.b	#1,d0
	roxr.b	#1,d0
	andi.b	#$80,d0
	move.b	d0,curve.to.left

	move.b	(a0,d2.w),road.width.reduction
	addq.b	#1,d2
	move.b	(a0,d2.w),road.length.reduction
	addq.b	#3,d2
	move.b	(a0,d2.w),section.steering.amount
	addq.b	#1,d2
	rts


****************************************


fetch.xz.position

* d0.b = road section

	move.l	#road.section.xz.positions,a1
	andi.w	#$ff,d0
	move.b	(a1,d0.w),d3
	lsr.b	#4,d3
	move.b	(a1,d0.w),d0
	andi.b	#$f,d0
	sub.b	players.map.x,d0
	sub.b	players.map.z,d3
	tst.b	rough.player.angle
	bmi	fxzp1

	btst	#6,rough.player.angle
	beq	fxzp3

	exg	d0,d3
	neg.b	d0
	jmp	fxzp3

fxzp1	btst	#6,rough.player.angle
	bne	fxzp2

	neg.b	d0
	neg.b	d3
	jmp	fxzp3

fxzp2	exg	d0,d3
	neg.b	d3

fxzp3	move.b	d0,road.section.x.offset
	move.b	d3,road.section.z.offset

	asl.b	#3,d0
	add.b	road.finer.x.offset,d0
	move.b	d0,road.near.x.offset

	asl.b	#3,d3
	add.b	road.finer.z.offset,d3
	move.b	d3,road.near.z.offset
	rts


****************************************


to.closest.adjacent.map.square
	move.b	d0,value
	move.b	d2,factor1
	cmp.b	value,d2
	bcc	tcams2

	add.b	factor1,d0
	bcc	tcams1

	move.b	d1,d0
	andi.b	#$f,d0
	cmpi.b	#$f,d0
	beq	tcams5
	addq.b	#1,d1
	jmp	tcams4

tcams1	move.b	d1,d0
	andi.b	#$f0,d0
	beq	tcams5
	subi.b	#$10,d1
	jmp	tcams4

tcams2	add.b	factor1,d0
	bcc	tcams3

	move.b	d1,d0
	andi.b	#$f0,d0
	cmpi.b	#$f0,d0
	beq	tcams5
	addi.b	#$10,d1
	jmp	tcams4

tcams3	move.b	d1,d0
	andi.b	#$f,d0
	beq	tcams5
	subq.b	#1,d1

tcams4	move.l	#road.under.map,a1
	move.b	(a1,d1.w),d0
	rts

tcams5	move.b	#-1,d0
	rts


****************************************


set.current.players.xz
	lsr.w	#8,d0
	move.b	d0,road.height+1

	move.l	#players.world.x,a0
	move.l	#players.fine.map.x,a1
	move.l	#players.map.x,a2

	tst.w	2(a0)
	bne	scpxz1
	addq.w	#1,2(a0)
scpxz1	move.l	(a0),d0
	asl.l	#1,d0
	swap	d0		/ $8000, because each map square = $800000
	move.b	d0,(a1)
	lsr.w	#8,d0
	move.b	d0,(a2)

	tst.w	10(a0)
	bne	scpxz2
	addq.w	#1,10(a0)
scpxz2	move.l	8(a0),d0
	asl.l	#1,d0
	swap	d0		/ $8000, because each map square = $800000
	move.b	d0,2(a1)
	lsr.w	#8,d0
	move.b	d0,2(a2)

	tst.b	road.height+1
	bmi	scpxz4

	btst	#6,road.height+1
	bne	scpxz3

	move.l	players.world.x,current.players.x
	move.l	players.world.z,current.players.z
	rts

scpxz3	move.l	players.world.x,current.players.z

	move.l	#$8000000,d0
	sub.l	players.world.z,d0
	move.l	d0,current.players.x
	rts

scpxz4	btst	#6,road.height+1
	bne	scpxz5

	move.l	#$8000000,d0
	sub.l	players.world.x,d0
	move.l	d0,current.players.x

	move.l	#$8000000,d0
	sub.l	players.world.z,d0
	move.l	d0,current.players.z
	rts

scpxz5	move.l	#$8000000,d0
	sub.l	players.world.x,d0
	move.l	d0,current.players.z

	move.l	players.world.z,current.players.x
	rts


****************************************


set.road.position.values
	move.w	players.y.angle,d0
	addi.w	#$2000,d0
	andi.w	#$c000,d0
	move.w	d0,rough.player.angle	calculate closest angle

	jsr	set.current.players.xz
	move.l	players.world.y,d0
	lsr.l	#8,d0
	lsr.l	#3,d0
	move.w	d0,players.smaller.y

******** Calculate y perspective shift value, using x angle ********

	move.w	#$780,d3
	move.w	average.amount.below.road,d0
	cmpi.w	#$500,d0
	bcs	srpv1

	asl.w	#1,d0
	move.w	#$280,d3

srpv1	add.w	d3,d0
	move.w	players.x.angle,d3
	bpl	srpv2

	asr.w	#1,d3
	sub.w	d3,d0

srpv2	asr.w	#4,d0
	add.w	players.smaller.y,d0
	move.w	d0,y.pers.shift

******** Calculate fine road offset values ********

	move.l	current.players.x,d0
	lsr.l	#8,d0
	lsr.l	#4,d0
	andi.w	#$7ff,d0
	neg.w	d0
	move.b	d0,road.finest.x.offset
	lsr.w	#8,d0
	move.b	d0,road.finer.x.offset

	move.l	current.players.z,d0
	lsr.l	#8,d0
	lsr.l	#4,d0
	andi.w	#$7ff,d0
	neg.w	d0
	move.b	d0,road.finest.z.offset
	lsr.w	#8,d0
	move.b	d0,road.finer.z.offset

******** Calculate x shift value, using y angle ********

	move.w	players.y.angle,d0
	addi.w	#$2000,d0
	andi.w	#$3ffe,d0
	subi.w	#$2000,d0
	move.w	d0,x.shift
	rts


****************************************


set.road.centre.values
	move.b	#0,clip.flag

	move.w	players.road.x.position,d0
	subi.w	#ROAD.WIDTH/2,d0
	tst.b	plus.180.degrees
	bpl	srcv1
	neg.w	d0
srcv1	move.w	d0,players.x.offset.from.road.centre

	bpl	srcv2
	neg.w	d0

srcv2	cmpi.w	#ROAD.WIDTH/2,d0
	blt	srcv3

	move.b	#$80,clip.flag
	tst.w	players.x.offset.from.road.centre
	bmi	srcv3
	move.b	#2,clip.flag

srcv3	cmpi.w	#$100,d0
	blt	srcv5

	tst.b	off.map.status
	bmi	srcv4

	move.b	#$80,off.map.status
	move.b	players.x.offset.from.road.centre,swing.from.left
	move.b	#$10,opponents.road.section.m64+1
	jsr	initialise.sparks.table
srcv4	rts

srcv5	btst	#6,off.map.status
	bne	srcv4

	move.b	#0,off.map.status
	move.b	#0,B.1bb75
	rts


****************************************


R.602e4	move.b	#16,d2

.label1	move.b	#8,d1
	move.b	#0,B.1bb93

.label2	jsr	R.60324
	subq.b	#1,d1
	bne	.label2

	move.b	#248,d1
	move.b	#$80,B.1bb93

.label3	jsr	R.60324
	addq.b	#1,d1
	bmi	.label3
	beq	.label3

	subq.b	#1,d2
	bpl	.label1
	rts


R.60324	move.b	d1,B.1bb8b
	move.b	d2,B.1bb8d
	tst.b	rough.player.angle
	bmi	.label1

	btst	#6,rough.player.angle
	beq	.label3

	move.b	B.1bb8d,d1
	move.b	B.1bb8b,d2
	neg.b	d2
	jmp	.label3

.label1	btst	#6,rough.player.angle
	bne	.label2

	move.b	B.1bb8b,d1
	neg.b	d1
	move.b	B.1bb8d,d2
	neg.b	d2
	jmp	.label3

.label2	move.b	B.1bb8d,d1
	neg.b	d1
	move.b	B.1bb8b,d2

.label3	move.b	d1,map.x.shift
	move.b	d2,map.z.shift
	move.w	#0,d0
	move.w	d0,near.sections.done2
	move.b	d0,near.sections.done
	jsr	get.valid.map.number
	bcs	.label7
	cmpi.b	#$ff,d0
	beq	.label7

	move.b	d0,current.road.section
	move.b	#0,coord.offset.zero.or.four
	move.b	#$80,d0
	move.b	d0,edge.x2.offset
	move.b	d0,B.1bc16
	jsr	make.near.road.coords
	move.b	#$e0,at.side.byte
	move.b	#$80,players.x.offset.from.road.centre
	move.l	#y.values,a0
	move.w	(a0),d0
	cmp.w	2(a0),d0
	bgt	.label4

	move.w	16(a0),d0
	cmp.w	18(a0),d0
	bgt	.label4

	move.b	offset.for.last.two.coords,d1
	move.w	(a0,d1.w),d0
	cmp.w	2(a0,d1.w),d0
	ble	.label5

.label4	move.b	#0,players.x.offset.from.road.centre

.label5	move.b	#0,use.lines.colour
	move.b	near.section.byte1,d0
	andi.b	#$c0,d0
	bne	.label6
	btst	#6,rough.difference.angle
	bne	.label6
	move.b	#$80,use.lines.colour

.label6	move.b	offset.for.last.two.coords,d1
	move.l	#near.section.flags,a0
	move.b	#0,(a0)
	move.b	#0,(a0,d1.w)
	move.w	dnr.value,road.section.offset
	move.w	#0,d1
	move.b	#0,pit.and.start.byte
	move.b	#0,edge.x2.offset
	move.b	#0,edge.x1.offset
	addi.w	#16,road.section.offset
	move.l	#edge.space,edge.space.ptr
	jsr	mnre13
	jsr	draw.near.road

.label7	move.b	B.1bb8b,d1
	move.b	B.1bb8d,d2
	rts


R.604b4	move.w	#96,dnr.value
	move.b	#$80,unused.flag
	move.b	B.1bb57,d1
	andi.b	#3,d1
	move.l	#TAB.60552,a1
	move.b	(a1,d1.w),players.world.x

	move.l	#TAB.60552+4,a1
	move.b	(a1,d1.w),players.world.z

	move.l	#TAB.60552+8,a1
	move.b	(a1,d1.w),players.y.angle

	move.b	#3,players.world.y
	move.b	#$f0,players.world.y+1
	move.b	#0,which.screen2
	move.w	#1792,y.shift
	jsr	draw.world.initialisation
	jsr	R.593ba
	jsr	fade.screen.in
	move.b	#$80,track.preview
	jsr	R.602e4
	move.b	#0,track.preview
	move.w	#0,dnr.value
	move.b	#0,unused.flag
	rts


TAB.60552
	dc.b	$04,$00,$04,$08,$00,$04,$08,$04,$00,$40,$80,$c0


****************************************


unused.sub1				* Not used
	move.l	#coord.visible.values,a6
	move.l	#near.section.flags,a0
	move.b	number.of.coords,d4
	lsr.b	#1,d4
	move.w	#0,d1
	move.b	number.of.coords,d2
	subq.b	#1,d2
	asl.b	#1,d2

.label1	move.w	(a6,d1.w),d0
	move.w	(a6,d2.w),(a6,d1.w)
	move.w	d0,(a6,d2.w)
	subq.b	#2,d2
	btst	#1,d1
	bne	.label2

	move.b	(a0,d1.w),d0
	move.b	(a0,d2.w),(a0,d1.w)
	move.b	d0,(a0,d2.w)

.label2	addq.b	#2,d1
	subq.b	#1,d4
	bne	.label1
	rts


****************************************


previous.restart.position
	jsr	to.previous.road.section

set.players.restart.position
	move.b	d1,current.road.section
	move.b	d1,players.road.section

******** Find section to lower car onto ********

	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	move.b	d0,d2
	move.l	#sections.car.can.be.put.on,a2
	move.b	(a2,d2.w),d0
	bmi	previous.restart.position

	move.b	B.1ca2f,d2
	beq	sprp2
	subq.b	#1,d2

sprp1	move.b	d1,d0
	move.l	#DAT.1c8e8,a2
	cmp.b	(a2,d2.w),d0
	beq	previous.restart.position
	subq.b	#1,d2
	bpl	sprp1

sprp2	move.l	#current.players.x,a0	clear player variables
.clear	move.b	#0,(a0)+
	cmp.l	#opp.new.rear.left.difference,a0
	bne	.clear

	move.b	#240,car.on.chains.countdown
	jsr	fetch.near.section.stuff
	move.l	#road.section.xz.positions,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	move.b	d0,map.x.shift
	move.b	(a1,d1.w),d0
	lsr.b	#4,d0
	move.b	d0,map.z.shift

	move.w	#0,d0
	move.w	d0,players.world.x+2
	move.w	d0,players.world.z+2

******** Put player into middle of map square ********

	move.b	map.x.shift,d0
	andi.w	#$ff,d0
	asl.w	#7,d0
	addi.w	#128/2,d0
	move.w	d0,players.world.x

	move.b	map.z.shift,d0
	andi.w	#$ff,d0
	asl.w	#7,d0
	addi.w	#128/2,d0
	move.w	d0,players.world.z

******** Put player just above ground to prevent immediate damage ********

	move.b	#4,players.world.y

******** Set player's y angle ********

	move.b	#0,d1
	move.b	near.section.piece,d0
	cmpi.b	#4,d0
	beq	add.45.degrees

	cmpi.b	#10,d0
	bne	set.y.angle

add.45.degrees
	move.b	#$20,d1			if piece 4 or 10

set.y.angle
	move.b	rough.piece.angle,d0
	move.b	plus.180.degrees,d3
	eor.b	d3,d0
	add.b	d1,d0
	move.b	d0,players.y.angle

********

	jsr	set.road.position.values
	jsr	calculate.players.road.position
	jsr	set.road.centre.values
	jsr	car.movement
	move.w	#0,players.world.y+2
	move.w	#16,players.world.y

	move.l	rear.road.height,d0
	move.l	d0,d3
	move.b	drop.start.done,d2
	beq	sprp5

* If not a drop start then put the car at a fixed height above the road

	asl.l	#8,d0
	asl.l	#1,d0
	addi.l	#$180000,d0
	move.l	d0,players.world.y
	move.b	#230,car.on.chains.countdown

sprp5	lsr.l	#2,d3
	move.w	d3,required.raise.height

	jsr	player.to.side.of.road
	move.b	#8,d1
	move.l	#front.left.road.height,a1
	move.l	#front.left.actual.height,a2

sprp6	move.l	#$1000,(a1,d1.w)
	move.l	#$1000,(a2,d1.w)
	subq.b	#4,d1
	bpl	sprp6

	move.l	#0,old.front.left.difference
	move.w	#0,old.rear.difference

	jsr	set.road.position.values
	move.b	#176,B.1bbea
	move.b	#8,B.1bbe9
	rts


****************************************


calculate.distances.between.players
	move.w	opponents.distance.into.section,d0
	sub.w	players.distance.into.section,d0
	asr.w	#3,d0
	move.b	opponents.road.section,d1
	move.b	players.road.section,d2
	move.l	#distances.around.road,a0
	asl.b	#1,d1
	asl.b	#1,d2
	move.w	(a0,d1.w),d3
	sub.w	(a0,d2.w),d3
	add.w	d3,d0
	move.w	d0,d5
	move.w	d0,difference.between.players
	bpl	cdbp1
	neg.w	d0

cdbp1	move.w	total.road.distance,d4
	sub.w	d0,d4

	cmp.w	d0,d4			compare two road distances
	bcs	cdbp2

	move.w	d0,d4			get smallest distance
	eori.w	#$8000,d5		opposite sign

cdbp2	move.w	d4,smallest.distance.between.players

	eori.w	#$8000,d5		opposite sign
	lsr.w	#8,d5
	move.b	d5,opponent.behind.player
	rts


****************************************


calculate.if.winning

* Returns negative if winning

	move.b	opponents.lap,d0
	sub.b	players.lap,d0
	bne	ciw3			if on different laps

	move.b	players.road.section,d0
	sub.b	start.finish.section,d0
	bcc	ciw1
	add.b	number.of.road.sections,d0

ciw1	move.b	opponents.road.section,d3
	sub.b	start.finish.section,d3
	bcc	ciw2
	add.b	number.of.road.sections,d3

ciw2	sub.b	d0,d3
	bne	ciw3			if on different sections

	move.w	difference.between.players,d0
	bne	ciw3			if at different distances

	move.b	machine,d0
ciw3	rts


****************************************


boost.print
	move.b	boost.reserve,d3
	andi.b	#%1111,ccr
	abcd	d3,d0
	cmp.b	boost.max.units,d0
	bcs	boost.ok
	move.b	boost.max.units,d0
boost.ok
	move.b	d0,boost.reserve

	move.b	#31,d0
	jsr	print.character
	move.b	#9,d0			column
	jsr	print.character
	move.b	#22,d0			row
	jsr	print.character

	move.b	#4,print.fine.x
	move.b	#2,print.fine.y
	move.b	boost.reserve,d0
	lsr.b	#4,d0
	jsr	print.dec.digit1

	move.b	boost.reserve,d0
	andi.b	#$f,d0
	jsr	print.dec.digit1

	move.b	#0,print.fine.x
	move.b	#0,print.fine.y
	rts


****************************************


boost.power
	move.b	boost.flag,d0
	or.b	wreck.wheel.height.reduction+2,d0
	bne	boost.off

	move.b	accelerating,d0
	bmi	update.boost

	move.b	players.input,d0
	andi.b	#3,d0
	beq	boost.off

update.boost
	move.b	boost.reserve,d0
	beq	boost.off

	tst.b	fourteen.frames.elapsed
	bmi	boost.on

	subq.b	#1,boost.unit
	bpl	boost.on

	move.b	boost.unit.value,d2
	move.b	d2,boost.unit
	move.b	#$99,d0			subtract 1 from boost reserve
	jsr	boost.print

boost.on
	move.b	#$80,boost.activated
	asl.w	engine.z.acceleration	double car acceleration
	rts

boost.off
	move.b	#0,boost.activated
	rts


****************************************


copy.damage.hole
	move.b	#23,d1
	bra	copy.damage.graphic

copy.damage.hole.smashed
	move.b	#25,d1
	bra	copy.damage.graphic

copy.damage.clear
	move.b	#27,d1

copy.damage.graphic
	move.w	d1,-(sp)
	move.l	#graphic.info+8,a0
	move.b	d2,d0
	asl.b	#1,d0
	add.b	d2,d0
	addq.b	#6,d0
	lsr.b	#1,d0
	bcc	cdg2
	addq.b	#1,d1

cdg2	andi.w	#$ff,d0
	move.w	d1,d3
	asl.w	#4,d3
	move.w	d0,(a0,d3.w)

	move.l	screen2,-(sp)
	move.l	screen.mem,screen2
	move.b	d1,d0
	jsr	copy.graphic

	move.l	#32000,d0
	add.l	d0,screen2
	move.b	d1,d0
	jsr	copy.graphic

	move.l	(sp)+,screen2
	move.w	(sp)+,d1
	rts


****************************************


initialise.damage.bar2
	move.b	#9,d2
idb21	cmp.b	damage.hole.position,d2
	bge	idb22

	jsr	copy.damage.clear
	bra	idb23

idb22	jsr	copy.damage.hole

idb23	subq.b	#1,d2
	bpl	idb21
	rts


R.609ae	move.b	d0,B.1bb16
	move.l	#random.long,a0
	move.l	#TAB.7a01a+27,a1
	move.b	#4,d1

.label1	tst.b	B.1bb16
	bmi	.label3

	move.b	(a0)+,(a1,d1.w)
	jmp	.label4

.label2	andi.b	#%11110,ccr
	rts

.label3	move.b	B.1ca34,d0
	bpl	.label2

	move.b	(a1,d1.w),(a0)+
.label4	subq.b	#1,d1
	bpl	.label1
	tst.b	B.1bb16
	bmi	.label6
	move.b	#11,d1

.label5	move.l	#opponents.names+177,a1
	move.b	(a1,d1.w),d0
	eori.b	#59,d0
	move.l	#DAT.1c9b6,a1
	move.b	d0,(a1,d1.w)
	subq.b	#1,d1
	bpl	.label5

.label6	move.b	#26,d1

.label7	tst.b	B.1bb16
	bpl	.label8
	move.l	#TAB.7a01a,a1
	move.b	(a1,d1.w),d0
	move.b	d0,road.height
	move.l	#TAB.7a01a+37,a1
	move.b	(a1,d1.w),d0
	move.b	d0,road.height+1

.label8	move.b	#0,d2
	move.b	d2,factor1

.label9	addq.b	#1,factor1
	bne	.labela
	addq.b	#1,d2
	bmi	.label15

.labela	jsr	randomize.long
	move.b	d0,thousands
	tst.b	B.1bb16
	bmi	.labelb
	move.l	#DAT.1c9b6,a1
	cmp.b	(a1,d1.w),d0
	bne	.label9
	move.b	d2,d0
	move.l	#TAB.7a01a,a1
	move.b	d0,(a1,d1.w)
	move.b	factor1,d0
	move.l	#TAB.7a01a+37,a1
	move.b	d0,(a1,d1.w)
	jmp	.labelc

.labelb	cmp.b	road.height,d2
	bne	.label9
	move.b	factor1,d0
	cmp.b	road.height+1,d0
	bne	.label9
	move.b	thousands,d0
	move.l	#DAT.7a41a,a1
	move.b	d0,(a1,d1.w)
.labelc	subq.b	#1,d1
	bpl	.label7
	move.l	#random.long,a0
	move.b	#4,d1
	move.b	#9,d2

.labeld	move.b	(a0)+,d0
	tst.b	B.1bb16
	bmi	.labele
	move.l	#TAB.7a01a+32,a1
	move.b	d0,(a1,d1.w)
	bpl	.labelf

.labele	move.l	#TAB.7a01a+32,a1
	cmp.b	(a1,d1.w),d0
	bne	.label15

.labelf	subq.b	#1,d1
	bpl	.labeld
	tst.b	B.1bb16
	bpl	.label14
	move.l	#DAT.1c9b6,a3
	move.l	#DAT.7a41a,a0
	move.b	#26,d1

.label10
	tst.b	multi.no.of.players
	beq	.label11
	cmpi.b	#24,d1
	bcs	.label12

.label11
	move.b	(a0,d1.w),(a3,d1.w)

.label12
	subq.b	#1,d1
	bpl	.label10
	move.b	#11,d1

.label13
	move.l	#DAT.1c9b6,a1
	move.b	(a1,d1.w),d0
	eori.b	#59,d0
	move.l	#opponents.names+177,a1
	move.b	d0,(a1,d1.w)
	subq.b	#1,d1
	bpl	.label13

.label14
	move.b	#$80,d0
	move.b	d0,B.1ca34
	andi.b	#%11110,ccr
	rts

.label15
	move.b	#59,random.long+3
	move.b	B.1bb16,d0
	bpl	R.609ae
	ori.b	#1,ccr
	rts


R.60b9a	move.b	#3,fade.frame.count

.loop	tst.b	fade.frame.count
	bne	.loop
	rts


****************************************


get.players.input
	jsr	randomize.long
	move.b	#$10,d7
	move.b	#0,d6
	move.l	#control.keys,a4
	move.b	#4,d2
next.key
	move.b	(a4,d2.w),d1
	jsr	test.key
	bne	not.pressed
	or.b	d7,d6
not.pressed
	lsr.b	#1,d7
	subq.b	#1,d2
	bpl	next.key

* Now d6 bits are (read vertically) :-
* %RDSSH
*  E  PA
*  T  AS
*  U  CH
*  R  E
*  N

* And players.input bits are defined as (read vertically):-
* %BRLBA
*  OIERC
*  OGFAC
*  SHTKE
*  TT EL

	move.b	d6,d0
	btst	#4,d6
	beq	not.return
	bset	#0,d0		boost also selects accelerate
not.return
	btst	#1,d6
	beq	not.space
	bset	#4,d0		brake also selects boost
not.space
	btst	#0,d6
	beq	not.hash
	bset	#1,d0		HASH key is changed to be brake
	bclr	#0,d0
not.hash
	tst.b	d0
	bne	some.control

	addq.b	#1,joystick.reads
	jsr	read.joystick
	move.b	joystick.state,d0
	eori.b	#$ff,d0
	bne	some.control

	tst.b	B.5d724
	bmi	some.control

	move.b	#$44,d1			RETURN
	jsr	test.key
	bne	not.return2

	move.b	#$10,d0
	bra	some.control

not.return2
	move.b	#0,d0

some.control
	andi.b	#$1f,d0
	tst.b	machine
	beq	save.input

	move.b	d0,players.input

	move.b	#$45,d1			ESCAPE
	jsr	test.key
	move.w	sr,-(sp)
	move.b	players.input,d0
	move.w	(sp)+,sr
	beq	save.input
	jsr	R.57ac0

save.input
	move.b	d0,players.input
	rts

joystick.reads	dc.b	$11,$11

control.keys
* $44=RETURN
* $22=D
* $21=S
* $40=SPACE
* $2a=HASH
	dc.b	$2a,$40,$21,$22,$44,1,2,3,4,0


****************************************


draw.dust.clouds
	move.b	#6,effect		off road
	move.b	pos.players.z.speed,d0
	cmpi.b	#16,d0
	blt	ddc1
	move.b	#16,d0			set to maximum
ddc1	move.b	d0,ferocity.of.sparks.or.clouds

	move.b	#15,d1
	tst.b	machine
	beq	ddc2
	move.b	#3,d1

ddc2	jsr	randomize.long
	andi.w	#$1c,d0
	addi.w	#450,d0
	move.w	d0,effect.table+6*16+8	off road period
	bra	sparks.or.clouds


no.sparks
	rts


initialise.sparks.table
	move.w	#62,d1
	move.w	#212,d0
it	move.l	#TAB.1c3c0,a1
	move.w	d0,(a1,d1.w)
	subq.b	#2,d1
	bpl	it
	rts


draw.sparks
	move.b	#1,effect		wreck
	move.b	which.side.byte,d0
	bne	on.an.edge

	move.b	wreck.wheel.height.reduction+2,d0
	beq	no.sparks		if car is not scraping on road

on.an.edge
	tst.b	off.map.status
	bmi	no.sparks		dust clouds will be drawn instead

	move.b	pos.players.z.speed,d0
	cmpi.b	#1,d0
	blt	no.sparks		if speed is not large enough

	cmpi.b	#50,d0
	blt	ds1
	move.b	#50,d0			set to maximum
ds1	move.b	d0,ferocity.of.sparks.or.clouds

	move.b	#31,d1

	jsr	randomize.long
	andi.b	#7,d0
	move.b	d0,d2
	move.b	ferocity.of.sparks.or.clouds,d0
	lsr.b	#1,d0
	bra	ds3

******** Not used ********

	cmpi.b	#8,d0
	bge	ds2

	move.b	#8,d0
	bne	ds3

ds2	cmpi.b	#6,d2
	blt	ds3

	move.b	#13,d0
	cmpi.b	#7,d2
	bne	ds3
	move.b	#3,d0

**************************

ds3	cmp.b	#$1f,d0
	bcs	ds4
	move.b	#$1f,d0
ds4	eori.b	#$1f,d0
	andi.w	#$ff,d0
	asl.w	#2,d0
	addi.w	#170,d0
	move.w	d0,effect.table+16+8	wreck period

sparks.or.clouds
	asl.b	#1,d1
	move.b	d1,temp

	move.b	touching.road,d0
	beq	initialise.sparks.table	if not touching road

* Touching road

	move.b	effect,d0
	jsr	sound.effect

	move.l	#TAB.1c380,a4
	move.l	#TAB.1c400,a5
	move.b	temp,d1

ddcc	jsr	draw.spark
	bne	ddcd

	addq.w	#2,64(a5,d1.w)

	move.w	64(a5,d1.w),d0
	add.w	d0,64(a4,d1.w)

	move.w	(a5,d1.w),d0
	add.w	d0,(a4,d1.w)

ddcd	subq.b	#2,d1
	bpl	ddcc

	move.b	temp,d1

ddce	move.w	64(a4,d1.w),d0
	cmpi.w	#128,d0
	bcs	ddc12

	jsr	randomize.long
	andi.w	#7,d0
	move.w	d0,d3
	clr.w	d0
	move.b	ferocity.of.sparks.or.clouds,d0
	lsr.w	#1,d0
	tst.b	off.map.status
	bmi	ddcf
	lsr.w	#1,d0

ddcf	add.w	d3,d0
	not.w	d0
	move.w	d0,64(a5,d1.w)
	tst.b	off.map.status
	bpl	ddc10

	jsr	draw.spark2
	jmp	ddc11

ddc10	jsr	randomize.long
	andi.w	#$7f,d0
	addi.w	#64,d0
	move.w	d0,(a4,d1.w)
	move.w	d0,d5

	jsr	randomize.long
	ori.w	#$fff8,d0
	addi.w	#127,d0
	move.w	d0,64(a4,d1.w)

ddc11	move.w	d5,d0
	subi.w	#128,d0
	asr.w	#3,d0
	move.w	d0,(a5,d1.w)
	jsr	draw.spark

ddc12	subq.b	#2,d1
	bpl	ddce
	rts


draw.spark
	move.b	d1,edge.x1.offset

	move.w	64(a4,d1.w),d5
	cmpi.w	#128,d5
	bcc	dspk1

	move.w	(a4,d1.w),d0
	cmpi.w	#256,d0
	bcc	dspk1

	cmpi.w	#1,d5
	bcc	dspk2

dspk1	move.w	#210,64(a4,d1.w)
	rts

dspk2	tst.b	off.map.status
	bpl	dspk3

	jsr	draw.spark.sub
	jmp	dspk4

dspk3	move.w	d0,d4
	cmpi.w	#$fe,d0
	bcc	dspk1

	move.l	current.scene,a0
	ext.l	d0
	ext.l	d5
	lsr.l	#3,d0
	andi.b	#$fe,d0
	add.l	d0,a0
	move.l	d5,d0
	asl.l	#2,d0
	add.l	d5,d0
	asl.l	#3,d0
	add.l	d0,a0

	move.b	#3,d0
	jsr	set.pixel.colour
	jsr	plot.pixel

	addq.w	#1,d4
	jsr	plot.pixel

	sub.l	#40,a0
	subq.w	#1,d4
	jsr	plot.pixel

	addq.w	#1,d4
	move.b	#15,d0
	jsr	set.pixel.colour
	jsr	plot.pixel

dspk4	move.b	edge.x1.offset,d1
	move.b	#0,d0
	rts


draw.spark2
	jsr	randomize.long
	andi.w	#$ff,d0
	move.w	d0,(a4,d1.w)
	move.w	d0,d5

	jsr	randomize.long
	andi.w	#7,d0
	addi.w	#118,d0
	move.w	d0,64(a4,d1.w)
	rts


draw.spark.sub
	move.b	d1,d2
	lsr.b	#1,d2
	add.b	main.loop.count,d2
	andi.w	#$f,d2
	move.l	#TAB.60fac,a0
	move.b	(a0,d2.w),d2

	asl.b	#1,d2
	move.w	(a4,d1.w),d4
	move.l	#TAB.60f9c,a0
	sub.w	(a0,d2.w),d4
	addi.w	#32,d4
	move.w	64(a4,d1.w),d5
	addi.w	#16,d5
	move.b	d2,d0
	lsr.b	#1,d0
	addi.b	#29,d0
	jmp	draw.spark.sub2


TAB.60f9c
	dc.w	$20,$20,$20,$28,$18,$20,$20,$20

TAB.60fac
	dc.b	3,6,7,2,1,5,0,4,0,5,1,2,7,6,2,7

B.60fbc	dc.b	0,0


****************************************


set.wheel.rotation.speed
	move.w	players.z.speed,d0
	bpl	swrs1
	neg.w	d0
swrs1	move.w	d0,pos.players.z.speed

	move.b	touching.road,d1
	bne	swrs2

* Not touching road, so reduce wheel speed by one quarter

	move.w	wheel.rotation.speed,d0
	lsr.w	#2,d0
	sub.w	d0,wheel.rotation.speed
	rts

* Touching road

swrs2	cmpi.w	#$800,d0
	bge	swrs3

* Less than $800, so multiply by 8 and use as wheel speed

	asl.w	#3,d0
	move.w	d0,wheel.rotation.speed
	rts

* Otherwise double it, add $3000 and use as wheel speed

swrs3	asl.w	#1,d0
	addi.w	#$3000,d0
	bcc	swrs4

	move.w	#$ff00,d0		set to maximum value
swrs4	move.w	d0,wheel.rotation.speed
	rts


****************************************


calculate.steering
	move.b	players.road.section,d1
	move.b	d1,current.road.section
	jsr	fetch.near.section.stuff

	move.w	section.y.angle,d4
	sub.w	players.y.angle,d4
	move.w	plus.180.degrees,d3
	eor.w	d3,d4			difference angle between
*					section and player
	IFD	RECORD
	move.w	d4,steer.value2
	ENDC

	move.b	#0,d2
	tst.b	near.section.byte1
	bpl	get.road.steering.change	if straight piece

	addq.b	#2,d2
	move.w	curve.to.left,d0
	eor.w	d3,d0
	bpl	get.road.steering.change	if right hand bend

	addq.b	#2,d2			for left hand bend

get.road.steering.change

* If player is on a curved section then adjust the difference angle

	move.l	#road.steering.changes,a0
	add.w	(a0,d2.w),d4		adjust difference angle
	IFD	RECORD
	move.w	d4,steer.value3
	ENDC

	move.w	d4,d0
	bpl	.plus
	neg.w	d0
.plus	move.w	d0,pos.difference.angle
	move.w	d4,difference.angle

* Save a scaled positive difference angle ranging from 0 to $7fff

	cmpi.w	#$800,d0
	bcs	diff.not.max
	move.w	#$7fff,d0		set to maximum
	bne	diff.ok

diff.not.max
	asl.w	#4,d0

diff.ok	move.w	d0,scaled.pos.difference.angle
	IFD	RECORD
	move.w	d0,steer.value4
	ENDC

* If on last segment of road section then get data for next section

	move.b	number.of.segments,d0
	sub.b	players.distance.into.section,d0
	cmpi.b	#2,d0
	bcc	not.last.segment

	jsr	to.next.road.section
	jsr	fetch.near.section.stuff

not.last.segment
	IFD	RECORD
	move.b	section.steering.amount,steer.value1+1
	ENDC

	move.b	curve.to.left,d0
	move.b	plus.180.degrees,d3
	eor.b	d3,d0
	move.b	d0,left.hand.bend

	move.b	left.right.value,d0
	beq	player.not.steering

player.is.steering
	move.b	difference.angle,d3
	eor.b	d3,d0
	move.b	d0,value	negative if pos.difference.angle
*					is going to increase
	move.b	near.section.byte1,d0
	bpl	straight.piece

	move.b	left.right.value,d0
	move.b	left.hand.bend,d3
	eor.b	d3,d0
	bmi	steering.away.from.bend

steering.into.the.bend
	move.b	section.steering.amount,d0
	addi.b	#45,d0			steering amount + 45
	jmp	plus.current.difference

steering.away.from.bend
	move.b	left.hand.bend,d0
	move.b	d0,left.right.value

	move.b	section.steering.amount,d0
	subi.b	#35,d0			steering amount - 35
	jmp	pos.difference.angle.increasing

straight.piece
	move.b	section.steering.amount,d0

plus.current.difference
	tst.b	value
	bmi	pos.difference.angle.increasing

* Add current difference (between player and road) onto steering amount

	add.b	scaled.pos.difference.angle,d0

pos.difference.angle.increasing
	jmp	calculate.steering.acceleration

player.not.steering
	move.w	#0,d4			zero steering acceleration

	move.b	near.section.byte1,d0
	bpl	align.car.with.road	if on a straight piece

	move.b	left.hand.bend,left.right.value
	move.b	section.steering.amount,d0	steering amount alone
	jmp	calculate.steering.acceleration

align.car.with.road
	move.b	difference.angle,left.right.value	not needed

* Following code used to gradually bring the car back in
* line with the road - this helps steering considerably

	move.w	pos.difference.angle,d0
	move.b	d0,d2
	move.b	pos.difference.angle,d3
	beq	diff.less.than.256

diff.greater.than.256
	subi.w	#30*256,d0
	bpl	diff.large		just use remainder to adjust y angle

	move.b	#$ff,d2			set adjustment amount to maximum
diff.less.than.256
	move.b	d2,factor1

	move.w	players.z.speed,d0
	bpl	.plus
	neg.w	d0
.plus	addi.w	#$a00,d0
	bpl	.not.max
	move.w	#$7f00,d0		set speed amount to maximum

* Adjustment of player's Y angle increases as player's speed increases

.not.max
	move.b	factor1,d3
	IFD	RECORD
	move.b	d3,steer.value8+1
	move.w	d0,steer.value9
	ENDC
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	lsr.w	#7,d0
	tst.b	d0
	bne	diff.large
	addq.b	#1,d0			atleast do some adjusting

diff.large
	tst.b	difference.angle
	bpl	.plus
	neg.w	d0
.plus	add.w	d0,players.y.angle	adjust player's Y angle now
	IFD	RECORD
	move.w	d0,steer.value7
	ENDC

* End of car re-alignment section

adjust.steering.acceleration
	move.w	#0,d2
	move.w	players.y.rotation.speed,d0
	andi.l	#$f,d2
	lsr.w	d2,d0
	sub.w	d0,d4

* Odd bit of code lying about

	move.l	#special.long+$14874,a0
	sub.l	#$14874,a0
	move.l	#$667b379f,d3
	addi.l	#$36729563,d3
	cmp.l	(a0),d3
	bne	steering.disabled

* Always gets to the following line

	tst.b	touching.road
	bne	store.steering.acceleration	if touching road

steering.disabled
	move.w	#0,d4

store.steering.acceleration
	move.w	d4,players.y.rotation.acceleration
	rts

calculate.steering.acceleration
	move.b	d0,factor1		store steering amount
	IFD	RECORD
	move.b	d0,steer.value5+1
	ENDC

* Steering acceleration increases as player's speed increases

	move.w	players.z.speed,d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	tst.b	left.right.value
	bpl	steering.right
	neg.w	d0			if steering left,
*					subtract from player's Y angle

steering.right
	asr.w	#3,d0
	move.w	d0,d4			store steering acceleration
	IFD	RECORD
	move.w	d0,steer.value6
	ENDC

	cmpi.b	#30,pos.difference.angle
	bcs	adjust.steering.acceleration	if difference less than 30
	bra	align.car.with.road


road.steering.changes
	dc.w	0			for straight road
	dc.w	217			for curve to right
	dc.w	-217			for curve to left


****************************************


R.61260	jsr	four.print.fine.y
	move.b	road.ID,d1
	move.l	#TAB.6129a,a1
	move.b	(a1,d1.w),d0
	move.b	d0,league.text+88+1	set X position

	move.b	#88,d1
	jsr	print.league.text	'The '

	move.b	road.ID,d1
	jsr	print.track.name
	jsr	clear.print.fine.y
	rts


TAB.6129a
	dc.b	$0f,$0d,$10,$10,$10,$0f,$10,$0d


****************************************


byte.multiply
	andi.w	#$ff,d0
	move.b	factor1,d3
	andi.w	#$ff,d3
	mulu	d0,d3
	move.w	d3,d0
	move.b	d0,product
	lsr.w	#8,d0
	rts


****************************************


test.key
	move.l	#key.array,a0
	move.b	(a0,d1.w),d1
	cmpi.b	#$b3,d1
	rts


****************************************


R.612ce	tst.b	d0
	bmi	.label2
	tst.b	copy.swing.from.left
	bmi	.label3

.label1	bra	byte.multiply

.label2	neg.b	d0
	tst.b	copy.swing.from.left
	bmi	.label1

.label3	jsr	byte.multiply
	neg.w	d3
	move.w	d3,d0
	move.b	d3,product
	lsr.w	#8,d0
	rts


R.61302	bclr	#7,copy.swing.from.left
	asl.w	#8,d0
	or.b	value,d0
	move.b	factor1,d3
	andi.w	#$ff,d3
	tst.b	copy.swing.from.left
	bpl	.label1
	neg.w	d3

.label1	muls	d0,d3
	asr.l	#8,d3
	move.w	d3,d0
	move.b	d0,value
	lsr.w	#8,d0
	rts


****************************************


mult.minus.weight
	move.w	#-CAR.WEIGHT,d0
	bra	sin.cos.mult

mult.weight
	move.w	#CAR.WEIGHT,d0

sin.cos.mult
	asl.w	#1,d1
	move.l	#sin.cos.values,a0
	move.w	(a0,d1.w),d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	lsr.w	#1,d1
	rts


****************************************


square.it
	move.w	d0,d3
	muls	d3,d0
	tst.l	d0
	bpl	sqr.pos
	neg.l	d0
sqr.pos	rts


****************************************


make.sin.cos
	move.l	#sin.cos.values,a5
	move.w	players.y.angle,d0
	jsr	get.sin
	move.w	d0,4(a5)
	move.w	d0,12(a5)
	move.w	d0,14(a5)
	move.w	d0,20(a5)
	move.w	d0,22(a5)

	move.w	players.y.angle,d0
	jsr	get.cos
	move.w	d0,6(a5)
	move.w	d0,16(a5)
	move.w	d0,18(a5)
	move.w	d0,24(a5)
	move.w	d0,26(a5)

	move.w	players.y.angle,d0
	sub.w	section.y.angle,d0
	move.w	d0,-(sp)
	jsr	get.sin
	move.w	d0,52(a5)
	move.w	d0,66(a5)
	move.w	d0,68(a5)

	move.w	(sp)+,d0
	jsr	get.cos
	move.w	d0,56(a5)
	move.w	d0,62(a5)
	move.w	d0,70(a5)

	move.w	players.x.angle,d0
	jsr	get.sin
	move.w	d0,8(a5)

	move.w	players.x.angle,d0
	jsr	get.cos
	move.w	d0,10(a5)
	move.w	d0,28(a5)
	move.w	d0,30(a5)

	move.w	players.z.angle,d0
	jsr	get.cos
	move.w	d0,34(a5)

	move.w	players.z.angle,d0
	jsr	get.sin
	move.w	d0,32(a5)

	move.w	8(a5),d5
	move.w	#12,d3
msc1	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#2,d3
	cmpi.w	#18,d3
	ble	msc1

	move.w	8(a5),d5
	move.w	#52,d3
msc2	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#4,d3
	cmpi.w	#56,d3
	ble	msc2

	move.w	12(a5),(a5)
	move.w	16(a5),2(a5)
	move.w	10(a5),d5
	move.w	#4,d3
msc3	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#2,d3
	cmpi.w	#6,d3
	ble	msc3

	move.w	10(a5),d5
	move.w	#68,d3
msc4	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#2,d3
	cmpi.w	#70,d3
	ble	msc4

	move.w	32(a5),d5
	move.w	#12,d3
msc5	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#4,d3
	cmpi.w	#28,d3
	ble	msc5

	move.w	32(a5),d5
	move.w	#52,d3
msc6	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#4,d3
	cmpi.w	#56,d3
	ble	msc6

	move.w	34(a5),d5
	move.w	#14,d3
msc7	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#4,d3
	cmpi.w	#30,d3
	ble	msc7

	move.w	34(a5),d5
	move.w	#62,d3
msc8	move.w	(a5,d3.w),d4
	muls	d5,d4
	asl.l	#1,d4
	swap	d4
	move.w	d4,(a5,d3.w)
	addi.w	#4,d3
	cmpi.w	#66,d3
	ble	msc8

	move.w	24(a5),d0
	sub.w	14(a5),d0
	move.w	d0,40(a5)

	move.w	18(a5),d0
	neg.w	d0
	sub.w	20(a5),d0
	move.w	d0,42(a5)

	move.w	26(a5),d0
	add.w	12(a5),d0
	move.w	d0,44(a5)

	move.w	16(a5),d0
	sub.w	22(a5),d0
	move.w	d0,46(a5)

	move.w	28(a5),48(a5)
	neg.w	48(a5)

	move.w	32(a5),d0
	neg.w	d0
	move.w	d0,36(a5)
	rts


****************************************


calculate.xz.speeds

* Saves player's actual X and Z speeds by rotating the world speed values.

	move.w	#2,d2
	move.l	#sin.cos.offsets,a5
	move.l	#players.x.speed,a4

calc.speeds
	move.w	#0,d5
	move.w	players.world.x.speed,d0
	move.b	(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5			add X component

	move.w	players.world.y.speed,d0
	move.b	3(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5			add Y component

	move.w	players.world.z.speed,d0
	move.b	6(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5			add Z component

	asl.w	#1,d2
	move.w	d5,(a4,d2.w)		save rotated value
	lsr.w	#1,d2
	subq.b	#2,d2
	bpl	calc.speeds
	rts


****************************************


calculate.gravity.acceleration

* Gravity acts on the Y axis only.  Therefore only Y components are used.
*
* X acceleration = -weight * -cosx.sinz
*
* Y acceleration = -weight * cosx.cosz
*
* Z acceleration = -weight * sinx

	move.w	#15,d1
	jsr	mult.minus.weight
	move.w	d0,gravity.y.acceleration

	move.w	#4,d1
	jsr	mult.minus.weight
	move.w	d0,gravity.z.acceleration

	move.w	#14,d1
	jsr	mult.weight
	move.w	d0,gravity.x.acceleration
	rts


****************************************


calculate.world.acceleration

* Adds components of player's (i.e. rotated) X, Y and Z accelerations
* to give world acceleration values.

	move.w	#2,d2
	move.l	#sin.cos.offsets,a5
	move.l	#total.world.x.acceleration,a4

calc.acceleration
	move.w	#0,d5
	move.w	players.x.acceleration,d0
	move.b	9(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5			add component of rotated X

	move.w	players.y.acceleration,d0
	move.b	12(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5			add component of rotated Y

	move.w	players.z.acceleration,d0
	move.b	15(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5			add component of rotated Z

	asl.w	#1,d2
	move.w	d5,(a4,d2.w)
	lsr.w	#1,d2
	subq.b	#1,d2
	bpl	calc.acceleration
	rts


****************************************


calculate.final.rotation.speed
	move.w	#1,d2
	move.l	#sin.cos.offsets,a5
	move.l	#players.final.x.rotation.speed,a4

* Calculate final X and Y rotation speeds by rotating X and Y rotation
* speeds about the Z axis.

cfrs	move.w	#0,d5
	move.w	players.x.rotation.speed,d0
	move.b	18(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5

	move.w	players.y.rotation.speed,d0
	move.b	20(a5,d2.w),d1
	jsr	sin.cos.mult
	add.w	d0,d5

	asl.w	#1,d2
	move.w	d5,(a4,d2.w)
	lsr.w	#1,d2
	subq.b	#1,d2
	bpl	cfrs

* Calculate final Z rotation speed by rotating Y rotation speed about
* the X axis and adding it onto the Z rotation speed.

	move.w	players.final.y.rotation.speed,d0
	move.w	#4,d1			sinx
	jsr	sin.cos.mult

	add.w	players.z.rotation.speed,d0
	move.w	d0,players.final.z.rotation.speed
	rts


****************************************


	dc.w	0
frame.count	dc.b	0,0
fade.frame.count	dc.b	0,0


frames.wheels.engine
	clr.w	d1
	clr.w	d2
	tst.b	frame.count
	beq	fwe1
	subq.b	#1,frame.count

fwe1	tst.b	fade.frame.count
	beq	fwe2
	subq.b	#1,fade.frame.count

fwe2	tst.b	B.5d724
	bpl	fwe3

	tst.b	no.wheel.update
	bne	fwe3
	jsr	update.wheel.rotation

fwe3	move.w	sprite.DMA.value,dmacon+custom

	move.w	engine.revs,d0
	add.w	engine.revs.change,d0
	bpl	fwe5

	tst.b	turn.engine.off
	beq	fwe4

	move.w	#1,dmacon+custom	stop engine sound
	move.w	#$80,intena+custom
	bra	fwea

fwe4	move.w	#0,d0

fwe5	move.w	d0,engine.revs

	addi.w	#378,d0
	move.l	#4800000,d3
	divu	d0,d3
	cmpi.w	#$3fff,d3
	bcs	fwe6
	move.w	#$3ffe,d3

fwe6	or.b	engine.fluctuation,d3
	cmpi.w	#124,d3			lowest possible period
	bge	fwe7
	move.w	#124,d3

fwe7	move.w	#6,d4

fwe8	cmpi.w	#256,d3
	blt	fwe9

	lsr.w	#1,d3
	subq.w	#1,d4
	bpl	fwe8

	move.w	#0,d4
	bra	fwe8

fwe9	move.l	#engine.pitch.table,a0
	lea	custom,a1
	asl.w	#3,d4
	move.l	(a0,d4.w),aud0lch(a1)
	move.w	6(a0,d4.w),aud0len(a1)
	move.w	d3,engine.period
fwea	rts


****************************************


R.617c4	movem.l	(sp)+,d0-d7/a0-a6
	rts


TAB.617ca
	dc.b	0,0,$4b,$26,$49,$27


adjust.y.using.x
	move.b	edge.x1.offset,d1
	move.b	#2,d3

ayux1	eori.b	#2,d1
	move.l	#x.values,a4
	move.l	#y.values,a5
	move.w	(a4,d1.w),d0
	subi.w	#128,d0
	bpl	ayux2
	neg.w	d0

ayux2	subi.w	#160,d0
	bmi	ayux3

	lsr.w	#3,d0
	add.w	d0,(a5,d1.w)

ayux3	subq.b	#1,d3
	bne	ayux1
	rts


****************************************


calculate.difference
	move.w	#276,d3
	beq	.zero
	muls	d3,d0
	asr.l	#8,d0
.zero	add.w	d6,d0
	rts


****************************************


new.lap.sub
	move.w	d1,d3
	move.l	#players.distance.into.section,a0
	asl.b	#1,d3
	tst.b	(a0,d3.w)
	bne	nls2

	move.b	1(a0,d3.w),d0
	eori.b	#$ff,d0
	move.b	d0,factor1

	move.b	#13,d0
	jsr	byte.multiply

	cmpi.b	#10,d0
	bcs	nls1
	addi.b	#6,d0

nls1	jsr	add.to.lap.time1
nls2	rts


****************************************


	IFD	RECORD
recording	dc.b	0
has.been.e4	dc.b	0
recording.count	dc.w	0

recording.ptr	dc.l	recording.buffer


steer.value1	dc.w	0
steer.value2	dc.w	0
steer.value3	dc.w	0
steer.value4	dc.w	0
steer.value5	dc.w	0
steer.value6	dc.w	0
steer.value7	dc.w	0
steer.value8	dc.w	0
steer.value9	dc.w	0

front.left.wheel.piece	dc.w	0
front.left.wheel.y.offset	dc.w	0
front.left.wheel.x	dc.w	0
front.left.wheel.z	dc.w	0

front.right.wheel.piece	dc.w	0
front.right.wheel.y.offset	dc.w	0
front.right.wheel.x	dc.w	0
front.right.wheel.z	dc.w	0

rear.wheel.piece	dc.w	0
rear.wheel.y.offset	dc.w	0
rear.wheel.x	dc.w	0
rear.wheel.z	dc.w	0
rear.wheel.y1	dc.w	0
rear.wheel.y2	dc.w	0
rear.wheel.y3	dc.w	0
rear.wheel.y4	dc.w	0
rear.wheel.height	dc.l	0

wheel.y.offset	dc.w	0	* Intermediate storage
	ENDC


car.movement
	IFD	RECORD
	tst.b	recording
	bne.s	record.now

	move.b	car.on.chains.countdown,d0
	cmp.b	#$e4,d0
	bne.s	not.e4
	st.b	has.been.e4

not.e4	tst.b	d0
	bne	record.done
	tst.b	has.been.e4
	beq	record.done
	st.b	recording

record.now
* Do the job

	IFD	RECORD_PLAYER_VALUES
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

* Start of values

	move.w	#0,d0
	move.b	left.right.value,d0
	move.w	d0,(a0)+
	move.w	engine.z.acceleration,(a0)+

	IFD	RECORD_MORE_PLAYER_VALUES
	move.w	sin.cos.values+44,(a0)+
	move.w	sin.cos.values+48,(a0)+
	move.w	sin.cos.values+46,(a0)+

	move.w	sin.cos.values+40,(a0)+
	move.w	sin.cos.values+30,(a0)+
	move.w	sin.cos.values+42,(a0)+

	move.w	sin.cos.values+4,(a0)+
	move.w	sin.cos.values+8,(a0)+
	move.w	sin.cos.values+6,(a0)+

	move.w	sin.cos.values+32,(a0)+
	move.w	sin.cos.values+34,(a0)+
	move.w	sin.cos.values+36,(a0)+

	move.w	steer.value1,(a0)+
	move.w	steer.value2,(a0)+
	move.w	steer.value3,(a0)+
	move.w	steer.value4,(a0)+
	move.w	steer.value5,(a0)+
	move.w	steer.value6,(a0)+
	move.w	steer.value7,(a0)+
	move.w	steer.value8,(a0)+
	move.w	steer.value9,(a0)+
	ENDC

	move.l	players.world.x,(a0)+
	move.l	players.world.y,(a0)+
	move.l	players.world.z,(a0)+

	move.w	players.x.angle,(a0)+
	move.w	players.y.angle,(a0)+
	move.w	players.z.angle,(a0)+

	IFD	RECORD_MORE_PLAYER_VALUES
	move.w	players.world.x.speed,(a0)+
	move.w	players.world.y.speed,(a0)+
	move.w	players.world.z.speed,(a0)+

	move.w	players.x.speed,(a0)+
	move.w	zero.word1,(a0)+
	move.w	players.z.speed,(a0)+

	move.w	front.left.wheel.piece,(a0)+
	move.w	front.left.wheel.y.offset,(a0)+
	move.w	front.left.wheel.x,(a0)+
	move.w	front.left.wheel.z,(a0)+

	move.w	front.right.wheel.piece,(a0)+
	move.w	front.right.wheel.y.offset,(a0)+
	move.w	front.right.wheel.x,(a0)+
	move.w	front.right.wheel.z,(a0)+

	move.w	rear.wheel.piece,(a0)+
	move.w	rear.wheel.y.offset,(a0)+
	move.w	rear.wheel.x,(a0)+
	move.w	rear.wheel.z,(a0)+
	move.w	rear.wheel.y1,(a0)+
	move.w	rear.wheel.y2,(a0)+
	move.w	rear.wheel.y3,(a0)+
	move.w	rear.wheel.y4,(a0)+
	move.l	rear.wheel.height,(a0)+

	move.l	front.left.road.height,(a0)+
	move.l	front.right.road.height,(a0)+
	move.l	rear.road.height,(a0)+

	move.l	front.left.actual.height,(a0)+
	move.l	front.right.actual.height,(a0)+
	move.l	rear.actual.height,(a0)+

	move.b	touching.road,d0
	move.w	d0,(a0)+

	move.w	gravity.x.acceleration,(a0)+
	move.w	gravity.y.acceleration,(a0)+
	move.w	gravity.z.acceleration,(a0)+

	move.w	car.collision.x.acceleration,(a0)+
	move.w	car.collision.y.acceleration,(a0)+
	move.w	car.collision.z.acceleration,(a0)+

	move.w	players.x.acceleration,(a0)+
	move.w	players.y.acceleration,(a0)+
	move.w	players.z.acceleration,(a0)+

	move.w	total.world.x.acceleration,(a0)+
	move.w	total.world.y.acceleration,(a0)+
	move.w	total.world.z.acceleration,(a0)+

	move.w	players.x.rotation.speed,(a0)+
	move.w	players.y.rotation.speed,(a0)+
	move.w	players.z.rotation.speed,(a0)+

	move.w	players.final.x.rotation.speed,(a0)+
	move.w	players.final.y.rotation.speed,(a0)+
	move.w	players.final.z.rotation.speed,(a0)+

	move.w	players.x.rotation.acceleration,(a0)+
	move.w	players.y.rotation.acceleration,(a0)+
	move.w	players.z.rotation.acceleration,(a0)+

	move.w	front.left.amount.below.road,(a0)+
	move.w	front.right.amount.below.road,(a0)+
	move.w	rear.amount.below.road,(a0)+

	move.w	old.front.left.difference,(a0)+
	move.w	old.front.right.difference,(a0)+
	move.w	old.rear.difference,(a0)+

	move.b	front.left.damage,d0
	move.w	d0,(a0)+
	move.b	front.right.damage,d0
	move.w	d0,(a0)+
	move.b	rear.damage,d0
	move.w	d0,(a0)+

	move.w	average.front.amount.below.road,(a0)+
	move.w	average.amount.below.road,(a0)+

	move.w	front.difference.below.road,(a0)+
	move.w	overall.difference.below.road,(a0)+
	ENDC

* End of values

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
	ENDC

* Done the job
	addq.w	#1,recording.count

	cmp.w	#1024,recording.count
	blt.s	record.done
	sf.b	recording
	sf.b	has.been.e4

record.done
	move.b	recording,the.word1
	move.w	recording.count,the.word2
* Original car.movement follows
	ENDC

	jsr	make.sin.cos

	jsr	calculate.wheel.xz.offsets
	jsr	calculate.road.wheel.heights
	jsr	calculate.actual.wheel.heights

	jsr	calculate.xz.speeds
	jsr	set.wheel.rotation.speed
	jsr	calculate.gravity.acceleration
	jsr	car.collision.detection
	move.b	B.1bb72,d0
	beq	left.road

	jsr	calculate.total.acceleration
	jsr	calculate.steering
	jsr	calculate.world.acceleration
	jsr	reduce.world.acceleration

	jsr	calculate.xz.rotation.acceleration
	jsr	update.players.rotation.speed
	jsr	calculate.final.rotation.speed

left.road
	jsr	update.players.world.speed
	jsr	update.players.position
	rts


****************************************


calculate.wheel.xz.offsets
	move.w	sin.cos.values+62,d4
	move.w	sin.cos.values+52,d0
	asr.w	#1,d4
	asr.w	#1,d0
	sub.w	d0,d4			should be add.w

	move.w	sin.cos.values+56,d5
	move.w	sin.cos.values+66,d0
	asr.w	#1,d5
	asr.w	#1,d0
	sub.w	d0,d5

	move.w	sin.cos.values+68,d0
	move.w	sin.cos.values+70,d3
	asr.w	#5,d4
	asr.w	#5,d5
	asr.w	#5,d0
	asr.w	#5,d3

	move.w	d0,rear.wheel.x.offset
	neg.w	rear.wheel.x.offset

	move.w	d3,rear.wheel.z.offset
	neg.w	rear.wheel.z.offset

	move.w	d0,front.left.wheel.x.offset
	move.w	d0,front.right.wheel.x.offset

	move.w	d3,front.left.wheel.z.offset
	move.w	d3,front.right.wheel.z.offset

	sub.w	d4,front.left.wheel.x.offset
	sub.w	d5,front.left.wheel.z.offset

	add.w	d4,front.right.wheel.x.offset
	add.w	d5,front.right.wheel.z.offset
	rts


****************************************


update.players.position

******** Set player's new position ********

	move.w	players.world.x.speed,d0
	move.b	#REDUCTION,d2
	beq	upp1
	muls	d2,d0
	asr.l	#8,d0
upp1	ext.l	d0
	asl.l	#6,d0
	add.l	d0,players.world.x

	move.w	players.world.y.speed,d0
	move.b	#REDUCTION,d2
	beq	upp2
	muls	d2,d0
	asr.l	#8,d0
upp2	ext.l	d0
	asl.l	#7,d0
	add.l	d0,players.world.y

	move.w	players.world.z.speed,d0
	move.b	#REDUCTION,d2
	beq	upp3
	muls	d2,d0
	asr.l	#8,d0
upp3	ext.l	d0
	asl.l	#6,d0
	add.l	d0,players.world.z

	move.w	players.world.y,d0	limit player's height
	cmpi.w	#1000,d0
	blt	upp4
	move.w	#1000,players.world.y

******** Set player's new angles ********

upp4	move.w	players.final.x.rotation.speed,d0
	move.b	#REDUCTION,d2
	beq	upp5
	muls	d2,d0
	asr.l	#8,d0
upp5	add.w	d0,players.x.angle

	move.w	players.final.y.rotation.speed,d0
	move.b	#REDUCTION,d2
	beq	upp6
	muls	d2,d0
	asr.l	#8,d0
upp6	add.w	d0,players.y.angle

	move.w	players.final.z.rotation.speed,d0
	move.b	#REDUCTION,d2
	beq	upp7
	muls	d2,d0
	asr.l	#8,d0
upp7	add.w	d0,players.z.angle

******** Check player's X angle ********

	move.w	#0,d2
	tst.b	B.1bb75
	bpl	upp8

	move.b	at.side.byte,d0
	cmpi.b	#$e0,d0
	bne	upp8
	addq.b	#2,d2

upp8	move.l	#maximum.angles,a0
	move.w	players.x.angle,d3
	bmi	upp9

	move.w	(a0,d2.w),d0		positive value from table
	cmp.w	d3,d0
	bcc	uppb
	bra	uppa

upp9	move.w	4(a0,d2.w),d0		negative value from table
	cmp.w	d3,d0
	bcs	uppb

uppa	move.w	d0,players.x.angle	set maximum allowable x angle

	move.w	players.x.rotation.speed,d3
	eor.w	d3,d0
	bmi	uppb
	move.w	#0,players.x.rotation.speed

******** Check player's Z angle ********

uppb	move.w	players.z.angle,d3
	bmi	uppc

	move.w	(a0,d2.w),d0
	cmp.w	d3,d0
	bcc	uppe
	bra	uppd

uppc	move.w	4(a0,d2.w),d0
	cmp.w	d3,d0
	bcs	uppe

uppd	move.w	d0,players.z.angle

	move.w	players.z.rotation.speed,d3
	eor.w	d3,d0
	bmi	uppe
	move.w	#0,players.z.rotation.speed

****************************************

uppe	bclr	#7,B.1bbab
	move.b	players.x.angle,d0
	bpl	uppf
	neg.b	d0

uppf	cmpi.b	#15,d0
	blt	upp10
	bset	#7,B.1bbab

upp10	move.w	#0,d0
	sub.w	players.x.angle,d0
	move.w	d0,y.shift
	rts


maximum.angles
	dc.w	44*256,10*256
	dc.w	-45*256,-11*256


****************************************


update.players.world.speed
	move.w	total.world.x.acceleration,d0
	move.b	#REDUCTION,d2
	beq	upws1
	muls	d2,d0
	asr.l	#8,d0
upws1	add.w	d0,players.world.x.speed

	move.w	total.world.y.acceleration,d0
	move.b	#REDUCTION,d2
	beq	upws2
	muls	d2,d0
	asr.l	#8,d0
upws2	add.w	d0,players.world.y.speed

	move.w	total.world.z.acceleration,d0
	move.b	#REDUCTION,d2
	beq	upws3
	muls	d2,d0
	asr.l	#8,d0
upws3	add.w	d0,players.world.z.speed
	rts


****************************************


update.players.rotation.speed
	move.w	players.x.rotation.acceleration,d0
	move.b	#REDUCTION,d2
	beq	uprs1
	muls	d2,d0
	asr.l	#8,d0
uprs1	add.w	d0,players.x.rotation.speed

	move.w	players.y.rotation.acceleration,d0
	move.b	#REDUCTION,d2
	beq	uprs2
	muls	d2,d0
	asr.l	#8,d0
uprs2	add.w	d0,players.y.rotation.speed

	move.w	players.z.rotation.acceleration,d0
	move.b	#REDUCTION,d2
	beq	uprs3
	muls	d2,d0
	asr.l	#8,d0
uprs3	add.w	d0,players.z.rotation.speed
	rts


****************************************


calculate.actual.wheel.heights
	move.w	players.x.angle,d0
	jsr	get.sin
	move.w	d0,near.x.coord		sinx

	move.w	players.z.angle,d0
	jsr	get.sin
	ext.l	d0
	asl.l	#3,d0			8sinz

	move.w	near.x.coord,d3
	ext.l	d3
	asl.l	#4,d3			16sinx
	move.l	players.world.y,d4
	sub.l	d3,d4			players.world.y - 16sinx
	asr.l	#8,d4
	move.l	d4,rear.actual.height

	move.l	players.world.y,d4
	add.l	d3,d4			players.world.y + 16sinx
	move.l	d4,d5
	sub.l	d0,d5			players.world.y + 16sinx - 8sinz
	asr.l	#8,d5
	move.l	d5,front.right.actual.height

	add.l	d0,d4			players.world.y + 16sinx + 8sinz
	asr.l	#8,d4
	move.l	d4,front.left.actual.height
	rts


****************************************


car.collision.detection
	move.b	#0,grounded.count
	move.b	#0,damage.value

******** Front left wheel collision ********

	move.l	front.left.road.height,d0
	sub.l	front.left.actual.height,d0
	sub.l	wreck.wheel.height.reduction,d0
	move.l	d0,front.left.height.difference
	bmi	ccd1			limit to minimum or maximum

	cmpi.l	#$1400,d0
	bcs	ccd3
	bra	ccd2

ccd1	cmpi.l	#-$300,d0
	bcc	ccd3

	move.l	#-$300,d0
	bra	ccd3

ccd2	move.l	#$1400,d0

ccd3	move.w	d0,new.front.left.difference
	move.w	d0,d6
	move.w	old.front.left.difference,d3
	sub.w	d3,d0
	jsr	calculate.difference
	bmi	front.left.above.road

	move.w	front.left.amount.below.road,d4
	move.w	d0,front.left.amount.below.road
	cmpi.w	#$400,d0
	blt	front.left.not.grounded

	cmpi.w	#$200,d4
	bge	front.left.not.grounded
	addq.b	#1,grounded.count	update count of grounded wheels

front.left.not.grounded
	move.w	front.left.amount.below.road,d0
	move.b	road.cushion.value,d3
	asl.w	#8,d3
	sub.w	d3,d0
	bmi	front.left.not.damaged

	cmpi.w	#$700,d0
	blt	front.left.not.damaged

	cmp.w	damage.value,d0
	bcs	front.left.damage.is.less
	move.w	d0,damage.value		save damage value if it is larger

front.left.damage.is.less
	subi.w	#$600,d0
	tst.b	fourteen.frames.elapsed
	bmi	ccd5

	addq.b	#1,damaged.count
	move.b	damaged.count,d3
	cmp.b	damaged.limit,d3
	bge	ccd5

	lsr.w	#8,d0
	move.b	d0,d3
	lsr.b	#1,d3
	add.b	d3,d0
	add.b	front.left.damage,d0
	bcc	ccd4
	move.b	#$ff,d0

ccd4	move.b	d0,front.left.damage
	move.b	#$80,damaged

ccd5	move.w	front.left.amount.below.road,d0
	cmpi.w	#$1200,d0
	bcs	ccd6
	move.w	#$11ff,front.left.amount.below.road
ccd6	bra	save.front.left.difference

front.left.above.road
	move.w	#0,front.left.amount.below.road

front.left.not.damaged
	move.b	#0,damaged.count

save.front.left.difference
	move.w	new.front.left.difference,old.front.left.difference

******** Front right wheel collision ********

	move.l	front.right.road.height,d0
	sub.l	front.right.actual.height,d0
	sub.l	wreck.wheel.height.reduction,d0
	move.l	d0,front.right.height.difference
	bmi	ccd7			limit to minimum or maximum

	cmpi.l	#$1400,d0
	bcs	ccd9
	bra	ccd8

ccd7	cmpi.l	#-$300,d0
	bcc	ccd9

	move.l	#-$300,d0
	bra	ccd9

ccd8	move.l	#$1400,d0

ccd9	move.w	d0,new.front.right.difference
	move.w	d0,d6
	move.w	old.front.right.difference,d3
	sub.w	d3,d0
	jsr	calculate.difference
	bmi	front.right.above.road

	move.w	front.right.amount.below.road,d4
	move.w	d0,front.right.amount.below.road
	cmpi.w	#$400,d0
	blt	front.right.not.grounded

	cmpi.w	#$200,d4
	bge	front.right.not.grounded
	addq.b	#1,grounded.count	update count of grounded wheels

front.right.not.grounded
	move.w	front.right.amount.below.road,d0
	move.b	road.cushion.value,d3
	asl.w	#8,d3
	sub.w	d3,d0
	bmi	front.right.not.damaged

	cmpi.w	#$700,d0
	blt	front.right.not.damaged

	cmp.w	damage.value,d0
	bcs	front.right.damage.is.less
	move.w	d0,damage.value		save damage value if it is larger

front.right.damage.is.less
	subi.w	#$600,d0
	tst.b	fourteen.frames.elapsed
	bmi	ccdb

	addq.b	#1,damaged.count
	move.b	damaged.count,d3
	cmp.b	damaged.limit,d3
	bge	ccdb

	lsr.w	#8,d0
	move.b	d0,d3
	lsr.b	#1,d3
	add.b	d3,d0
	add.b	front.right.damage,d0
	bcc	ccda
	move.b	#$ff,d0

ccda	move.b	d0,front.right.damage
	move.b	#$80,damaged

ccdb	move.w	front.right.amount.below.road,d0
	cmpi.w	#$1200,d0
	bcs	ccdc
	move.w	#$11ff,front.right.amount.below.road
ccdc	bra	save.front.right.difference

front.right.above.road
	move.w	#0,front.right.amount.below.road

front.right.not.damaged
	move.b	#0,damaged.count

save.front.right.difference
	move.w	new.front.right.difference,old.front.right.difference

******** Rear wheel collision ********

	move.l	rear.road.height,d0
	sub.l	rear.actual.height,d0
	sub.l	wreck.wheel.height.reduction,d0
	move.l	d0,rear.height.difference
	bmi	ccdd			limit to minimum or maximum

	cmpi.l	#$1400,d0
	bcs	ccdf
	bra	ccde

ccdd	cmpi.l	#-$300,d0
	bcc	ccdf

	move.l	#-$300,d0
	bra	ccdf

ccde	move.l	#$1400,d0

ccdf	move.w	d0,new.rear.difference
	move.w	d0,d6
	move.w	old.rear.difference,d3
	sub.w	d3,d0
	jsr	calculate.difference
	bmi	rear.above.road

	move.w	rear.amount.below.road,d4
	move.w	d0,rear.amount.below.road
	cmpi.w	#$400,d0
	blt	rear.not.grounded

	cmpi.w	#$200,d4
	bge	rear.not.grounded
	addq.b	#1,grounded.count	update count of grounded wheels

rear.not.grounded
	move.w	rear.amount.below.road,d0
	move.b	road.cushion.value,d3
	asl.w	#8,d3
	sub.w	d3,d0
	bmi	rear.not.damaged

	cmpi.w	#$700,d0
	blt	rear.not.damaged

	cmp.w	damage.value,d0
	bcs	rear.damage.is.less
	move.w	d0,damage.value		save damage value if it is larger

rear.damage.is.less
	subi.w	#$600,d0
	tst.b	fourteen.frames.elapsed
	bmi	ccd11

	addq.b	#1,damaged.count
	move.b	damaged.count,d3
	cmp.b	damaged.limit,d3
	bge	ccd11

	lsr.w	#8,d0
	move.b	d0,d3
	lsr.b	#1,d3
	add.b	d3,d0
	add.b	rear.damage,d0
	bcc	ccd10
	move.b	#$ff,d0

ccd10	move.b	d0,rear.damage
	move.b	#$80,damaged

ccd11	move.w	rear.amount.below.road,d0
	cmpi.w	#$1200,d0
	bcs	ccd12
	move.w	#$11ff,rear.amount.below.road
ccd12	bra	save.rear.difference

rear.above.road
	move.w	#0,rear.amount.below.road

rear.not.damaged
	move.b	#0,damaged.count

save.rear.difference
	move.w	new.rear.difference,old.rear.difference

****************************************

	move.w	front.left.amount.below.road,d0
	add.w	front.right.amount.below.road,d0
	asr.w	#1,d0
	move.w	d0,near.x.coord		average front amount below road
	IFD	RECORD
	move.w	d0,average.front.amount.below.road
	ENDC

	add.w	rear.amount.below.road,d0
	asr.w	#1,d0
	move.w	d0,average.amount.below.road

	jsr	calculate.car.collision.acceleration

	move.w	front.left.amount.below.road,d0
	sub.w	front.right.amount.below.road,d0
	move.w	d0,d3
	asl.w	#1,d0
	add.w	d3,d0			difference * 3
	bpl	ccd13
	neg.w	d0

ccd13	cmpi.w	#$1000,d0
	blt	ccd14
	move.w	#$1000,d0		limit to maximum

ccd14	tst.w	d3
	bpl	ccd15
	neg.w	d0			correct sign

ccd15	move.w	d0,front.difference.below.road

****************************************

	move.w	near.x.coord,d0		average front amount below road
	sub.w	rear.amount.below.road,d0
	move.w	d0,overall.difference.below.road

****************************************

	move.b	average.amount.below.road,d0
	or.b	average.amount.below.road+1,d0
	move.b	d0,touching.road
	bne	ccd17			if touching road

* Not touching road

	tst.b	car.on.chains.countdown
	bne	ccd17

	move.w	#-128,d3
	move.w	players.x.angle,d0
	bpl	x.angle.plus

check.roller.coaster
	move.b	road.ID,d0
	cmpi.b	#7,d0
	bne	check.ski.jump

roller.coaster
	move.b	#248,d1			don't think this is used
	bra	x.angle.less

check.ski.jump
	cmp.b	#4,d0
	bne	ccd17

ski.jump
	move.w	#-8,d3
	bra	x.angle.less

x.angle.plus
	cmpi.w	#$1000,d0
	blt	x.angle.less
	move.w	#-256,d3

x.angle.less
	sub.w	overall.difference.below.road,d3
	bpl	ccd17

	move.b	players.x.rotation.speed,d0
	bpl	ccd16

	cmpi.b	#$ff,d0
	bne	ccd17

ccd16	move.w	d3,overall.difference.below.road

ccd17	jsr	lift.car.onto.track

	move.w	car.collision.z.acceleration,car.to.road.collision.z.acceleration

	jsr	car.to.car.collision

******** Play grounded sound if necessary ********

	tst.b	grounded.delay
	beq	ccd18
	subq.b	#1,grounded.delay

ccd18	tst.b	grounded.count
	beq	ccd1b

	move.b	damage.value,d0
	cmpi.b	#7,d0
	bcc	ccd19
	move.b	#7,d0			set volume to minimum of 28

ccd19	asl.b	#2,d0
	cmpi.b	#64,d0
	bcs	ccd1a
	move.b	#64,d0			set volume to maximum of 64

ccd1a	move.b	d0,effect.table+3*16+11	grounded volume

	tst.b	grounded.delay
	bne	ccd1b

	move.b	#3,d0			grounded
	jsr	sound.effect
	move.b	#5,grounded.delay
ccd1b	rts


grounded.delay	dc.b	0,0


****************************************


calculate.total.acceleration
	move.w	gravity.y.acceleration,d0
	add.w	car.collision.y.acceleration,d0
	move.w	d0,players.y.acceleration

	move.b	engine.z.acceleration,d0
	or.b	players.z.speed,d0
	bmi	cta1

	tst.b	engine.z.acceleration+1
	beq	cta1
	andi.w	#$ff,d0
	sub.w	d0,engine.z.acceleration

cta1	move.w	engine.z.acceleration,d3
	bpl	cta2
	neg.w	d3
cta2	jsr	get.twice.collision.y.acceleration
	sub.w	d0,d3
	bcs	cta4

	tst.b	engine.z.acceleration
	bpl	cta3
	neg.w	d0
cta3	move.w	d0,engine.z.acceleration

cta4	move.w	engine.z.acceleration,d0
	add.w	car.collision.z.acceleration,d0
	add.w	gravity.z.acceleration,d0
	move.w	d0,players.z.acceleration

	jsr	calculate.x.acceleration
	rts


****************************************


calculate.xz.rotation.acceleration

* Calculate values using current car rotation speeds and inclination values
* between the car and the road, in order to damp the car X and Z angles
* and keep the car level with the road, on its X and Z axes.  Also give
* effect of acceleration.
*
* overall.difference.below.road is effectively car X inclination.
*
* front.difference.below.road is effectively car Z inclination.

	move.w	players.x.rotation.speed,d3
	asr.w	#4,d3
	move.w	overall.difference.below.road,d0
	sub.w	d3,d0
	tst.b	touching.road
	beq	not.touching.road

* This part lifts the car up at the front during forwards acceleration
* and, vice versa, dips the front of the car during backwards acceleration.

	move.w	players.z.acceleration,d3
	asr.w	#2,d3
	add.w	d3,d0

not.touching.road
	move.w	d0,players.x.rotation.acceleration

	move.w	players.z.rotation.speed,d3
	asr.w	#4,d3
	move.w	front.difference.below.road,d0
	sub.w	d3,d0
	move.w	d0,players.z.rotation.acceleration
	rts


****************************************


calculate.x.acceleration
	move.w	gravity.x.acceleration,d4
	add.w	car.collision.x.acceleration,d4
	move.w	d4,d3			speed increase
	sub.w	players.x.speed,d3	minus current speed
	bpl	cxa1
	neg.w	d3

cxa1	jsr	get.twice.collision.y.acceleration
	cmp.w	d0,d3
	bcs	y.bigger.than.x

	tst.b	players.x.speed
	bpl	cxa2
	neg.w	d0
cxa2	sub.w	d0,d4
	move.w	d4,players.x.acceleration
	move.b	#$80,collision.in.air
	rts

y.bigger.than.x
	move.w	car.collision.x.acceleration,d0
	sub.w	players.x.speed,d0
	move.w	d0,players.x.acceleration
	move.b	#0,collision.in.air
	rts


****************************************


get.twice.collision.y.acceleration

* If on ground, returns value in d0

	tst.b	touching.road
	beq	not.touching.road1

	move.w	car.collision.y.acceleration,d0
	asl.w	#1,d0
	rts

not.touching.road1
	move.w	#0,d0
	rts


****************************************


reduce.world.acceleration
	move.l	#1,d7			set maximum reduction factor
	tst.b	touching.road
	beq	rwa1			if not touching road

* Touching road

	move.b	car.to.road.collision.z.acceleration,d0
	bpl	.plus
	eori.b	#$ff,d0
.plus	cmpi.b	#3,d0
	bge	rwa3			if collision.z.acceleration large

	tst.b	off.map.status
	bmi	rwa3			if off map

	tst.b	wreck.wheel.height.reduction+2
	bne	rwa2			if wrecked

* Not touching road
* OR
* collision.z.acceleration small, on map, not wrecked

rwa1	tst.b	car.on.chains.countdown
	beq	not.on.chains

* On chains
* OR
* collision.z.acceleration small, on map, wrecked

rwa2	move.l	#3,d7			set medium reduction factor

* On chains
* OR
* collision.z.acceleration large
* OR
* collision.z.acceleration small, off map
* OR
* collision.z.acceleration small, on map, wrecked

rwa3	move.w	#$6000,d0		set reduction amount
	bra	reduce.now

* Normal case - car not on chains, little Z collision with road

not.on.chains
	move.w	players.x.speed,d0	reduce accelerations
	bpl	.x.plus			depending on car speed
	neg.w	d0

.x.plus	move.w	zero.word1,d3
	bpl	.y.plus
	neg.w	d3

.y.plus	cmp.w	d3,d0
	bge	.greater
	move.w	d3,d0
.greater
	move.w	players.z.speed,d3
	bpl	.z.plus
	neg.w	d3

.z.plus	cmp.w	d3,d0
	bge	check.slipstream
	move.w	d3,d0			greatest of player's
*					x, y and z speeds

check.slipstream
	move.l	#5,d7			set minimum reduction factor
	tst.b	player.close.to.opponent
	bpl	reduce.now

	tst.b	opponent.behind.player
	bmi	reduce.now

* If player and opponent are close and the opponent is infront
* of the player then the player is in the slipstream of the
* opponent, so there is less drag on the player's car.

	move.w	#20,d3			subtract 20*128 to make
	asl.w	#7,d3			reduction smaller
	sub.w	d3,d0
	bcc	reduce.now
	move.w	#0,d0

* Reduce acceleration values using current speed values.
* d0 = reduction amount, d7 = overall reduction factor.

reduce.now
	move.w	players.world.x.speed,d3
	muls	d0,d3
	swap	d3
	asr.w	d7,d3
	sub.w	d3,total.world.x.acceleration

	move.w	players.world.y.speed,d3
	muls	d0,d3
	swap	d3
	asr.w	d7,d3
	sub.w	d3,total.world.y.acceleration

	move.w	players.world.z.speed,d3
	muls	d0,d3
	swap	d3
	asr.w	d7,d3
	sub.w	d3,total.world.z.acceleration
	rts


****************************************


calculate.car.collision.acceleration

* average.amount.below.road is the force exerted by the road on the car.
*
* Force is directed through the Y axis of the road surface.  Therefore only
* Y components are used.
*
* X acceleration = force * -cosx.sinz
*
* Y acceleration = force * cosx.cosz
*
* Z acceleration = force * sinx

	move.w	#0,y.inclination.to.road

* Above value is zero because road exists in X and Z planes only.

	move.l	front.left.height.difference,d0
	add.l	front.right.height.difference,d0
	asr.l	#1,d0			average front height difference
	sub.l	rear.height.difference,d0
	asr.l	#4,d0			X gradient to road surface

	move.w	d0,d3
	eori.w	#$8000,d3
	move.w	d3,x.inclination.to.road

* Calculate sin and cos of X angle between car and road surface

	jsr	calculate.inclination.sin.cos

	move.b	inclination.cos,surface.cosx
	move.b	inclination.sin,surface.sinx

	move.l	front.left.height.difference,d0
	sub.l	front.right.height.difference,d0
	asr.l	#3,d0			Z gradient to road surface
	move.w	d0,z.inclination.to.road

* Calculate sin and cos of Z angle between car and road surface

	jsr	calculate.inclination.sin.cos

	move.b	surface.cosx,factor1
	move.b	inclination.cos,d0	surface.cosz
	jsr	byte.multiply
	move.b	d0,surface.cosx.cosz

	move.b	inclination.sin,d0	surface.sinz
	jsr	byte.multiply
	move.b	d0,surface.cosx.sinz

******** Calculate car collision X acceleration ********

	move.b	surface.cosx.sinz,factor1

	move.b	z.inclination.to.road,copy.swing.from.left

	move.w	average.amount.below.road,d0
	move.b	factor1,d3
	andi.w	#$ff,d3
	tst.b	copy.swing.from.left
	bpl	ccca1
	neg.w	d3

ccca1	asl.w	#7,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.w	d0,car.collision.x.acceleration

******** Calculate car collision Y acceleration ********

	move.b	surface.cosx.cosz,factor1

	move.b	y.inclination.to.road,copy.swing.from.left

	move.w	average.amount.below.road,d0
	move.b	factor1,d3
	andi.w	#$ff,d3
	tst.b	copy.swing.from.left
	bpl	ccca2
	neg.w	d3

ccca2	asl.w	#7,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.w	d0,car.collision.y.acceleration

******** Calculate car collision Z acceleration ********

	move.b	surface.sinx,factor1

	move.b	x.inclination.to.road,copy.swing.from.left

	move.w	average.amount.below.road,d0
	move.b	factor1,d3
	andi.w	#$ff,d3
	tst.b	copy.swing.from.left
	bpl	ccca3
	neg.w	d3

ccca3	asl.w	#7,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.w	d0,car.collision.z.acceleration
	rts


****************************************


calculate.inclination.sin.cos

* d0.w is effectively the sin of the inclination angle

	tst.w	d0
	bpl	inclination.positive
	neg.w	d0

inclination.positive
	move.b	#$ff,d1			set maximum inclination
	cmpi.w	#256,d0
	bge	inclination.too.large
	move.b	d0,d1			use inclination if not too large

inclination.too.large
	move.b	d1,inclination.sin

	lsr.b	#1,d1			128 values in table
	move.l	#cosine.conversion.table,a0
	move.b	(a0,d1.w),d0
	move.b	d0,inclination.cos
	rts


****************************************


calculate.screen.x
	move.w	near.x.coord,d0
	move.w	near.z.coord,d3
	tst.b	track.preview
	bpl	calculate.screen.x2

	asr.w	#1,d0
	asr.w	#1,d3
	move.w	d3,perspective.z

	addi.b	#49,perspective.z
	asr.w	#1,d3
	addi.w	#$4900,d3
	jsr	calculate.perspective.coord

	sub.w	x.shift,d0
	asr.w	#3,d0
	move.l	#x.values,a0
	move.w	d0,(a0,d1.w)
	rts

calculate.screen.x2
	jsr	calculate.perspective.coord
	sub.w	x.shift,d0
	asr.w	#3,d0
	move.l	#x.values,a0
	move.w	d0,(a0,d1.w)

	jsr	calculate.perspective.value
	move.w	d0,perspective.z
	rts


****************************************


calculate.screen.y
	move.l	#coord.visible.values,a0
	move.w	(a0,d1.w),d0		get y value
	sub.w	y.pers.shift,d0
	neg.w	d0
	asr.w	#2,d0
	move.w	perspective.z,d3
	tst.b	track.preview
	bpl	calculate.screen.y2

	move.w	#19483,d4
	muls	d4,d0
	asl.l	#1,d0
	swap	d0			Y * 19483 / 32768

calculate.screen.y2
	jsr	calculate.perspective.coord
	sub.w	y.shift,d0
	asr.w	#3,d0
	move.l	#y.values,a0
	move.w	d0,(a0,d1.w)
	rts


****************************************


z.rotate0
	move.l	#coord.visible.values,a0
	tst.w	(a0,d1.w)
	bmi	zr.end
z.rotate
	move.l	#sin.cos.values,a3
	move.l	#x.values,a5
	move.l	#y.values,a4
z.rotate1
	move.w	(a5,d1.w),d5
	move.w	(a4,d1.w),d4

	move.w	34(a3),d0
	muls	d5,d0
	asl.l	#1,d0
	swap	d0
	move.w	32(a3),d3
	muls	d4,d3
	asl.l	#1,d3
	swap	d3
	add.w	d3,d0
	asr.w	#2,d0
	addi.w	#128,d0
	move.w	d0,(a5,d1.w)

	move.w	34(a3),d0
	muls	d4,d0
	asl.l	#1,d0
	swap	d0
	move.w	32(a3),d3
	muls	d5,d3
	asl.l	#1,d3
	swap	d3
	sub.w	d3,d0
	asr.w	#2,d0
	addi.w	#64,d0
	move.w	d0,(a4,d1.w)
zr.end	rts


****************************************


randomize.long
	move.w	random.long+2,d0
	lsr.w	#4,d0
	move.w	random.long,d3
	lsr.w	#1,d3
	eor.b	d3,d0
	move.l	random.long,d3
	asl.l	#8,d3
	move.b	random.byte,d3
	move.l	d3,random.long
	move.b	d0,random.byte
	rts


random.long	dc.l	0
random.byte	dc.b	0,0


****************************************


R.625a8	clr.w	d3
	move.w	d1,d3
	clr.w	d1
	bra	R.625ba

R.625b2	jsr	print.character
	addq.w	#1,d3

R.625ba	move.l	#TAB.625ce,a1
	move.b	(a1,d3.w),d0
	cmpi.b	#$ff,d0
	bne	R.625b2
	rts


TAB.625ce
	dc.b	31,11,9,'LOAD game position',255
	dc.b	31,11,9,'SAVE game position',255
	dc.b	'Drive not ready',255
	dc.b	'Disc write protected',255
	dc.b	'Insert disc',255
	dc.b	'Disc error',255
	dc.b	'Incorrect data found  ',255
	dc.b	'Type in file name',255
	dc.b	31,7,22,'                            '
	dc.b	31,7,23,'                            ',255
	dc.b	31,8,23,255
	dc.b	'Disc error: retry or escape',255
	dc.b	31,8,22,'Warning: this disc has not'
	dc.b	31,8,23,'been used for game saving',255
	dc.b	31,5,15,'Insert formatted game save disc'
	dc.b	31,14,17,'into drive 0.'
	dc.b	31,9,20,'Press any key to continue',255
	dc.b	0


R.62748	jsr	clear.menu
	jsr	copy.screen.part
	move.w	#298,d1
	jsr	R.1b82a
	jsr	release.and.wait.for.key
	jsr	clear.menu
	move.b	#15,d0
	jsr	set.text.masks
	move.w	#0,d1
	tst.b	B.1ca31
	beq	.label1
	move.w	#22,d1

.label1	jsr	R.625a8
	jsr	copy.screen.part
	move.l	screen2,-(sp)
	move.l	screen1,screen2

	move.b	#$80,do.key.validation
	jsr	R.627ca
	move.b	#0,do.key.validation

	move.b	#3,d0
	jsr	set.bground.masks
	move.l	(sp)+,screen2
	rts


R.627ca	jsr	R.62c28
	tst.b	B.1bb92
	bpl	.label1
	rts

.label1	jsr	R.62d34
	move.b	#0,or.with.screen

.label2	move.b	#15,B.62bb8
	move.b	#11,B.62bb9
	move.b	B.62bb6,d0
	tst.b	B.1ca31
	beq	.label3
	move.b	B.62bb7,d0

.label3	move.b	d0,B.62bb4
	move.b	#0,B.62bb8
	move.b	#0,B.62bb9
	move.b	#2,d0
	jsr	set.bground.masks
	jsr	R.62d8c
	subi.b	#9,print.column
	move.b	#0,d0
	jsr	set.text.masks
	move.b	#62,d0
	jsr	print.character
	jsr	R.62b22
	move.b	print.column,B.62bba
	tst.b	B.1ca31
	bne	.label5

.label4	jsr	wait.for.key
	jsr	validate.ASCII.key
	tst.b	invalid.key.flag
	bne	.label6
	cmpi.b	#13,d0
	bne	.label4
	cmpi.b	#32,opponents.names+193
	beq	.label4
	bra	.labelb

.label5	move.b	#0,d0
	jsr	set.text.masks
	move.b	#2,d0
	jsr	set.bground.masks
	move.b	#$c0,d0
	move.b	#8,d3
	jsr	input.filename

	move.w	#145,d1
	jsr	R.1b82a
	tst.b	invalid.key.flag
	bne	.label6
	cmpi.b	#32,opponents.names+193
	bne	.labelb
	move.b	#127,d1
	move.w	d1,d1
	jsr	R.1b82a
	move.b	#0,B.5b83e
	bra	.label5

.label6	bmi	R.62a66
	jsr	R.62a70
	btst	#6,invalid.key.flag
	bne	.label9
	btst	#5,invalid.key.flag
	bne	.label8
	btst	#3,invalid.key.flag
	bne	.label7
	jsr	R.62b12
	bra	.labela

.label7	jsr	R.62afe
	bra	.labela

.label8	jsr	R.62ab6
	bra	.labela

.label9	jsr	R.62aca

.labela	bra	.label2

.labelb	jsr	R.5f4b6
	bcs	.label2
	move.b	#2,d0
	jsr	set.bground.masks
	move.b	#1,d0
	jsr	set.text.masks
	jsr	R.62d80
	move.b	#1,d0
	jsr	R.5f374
	clr.w	d0
	move.b	B.62bb4,d0
	addi.w	#23,d0
	move.w	d0,W.62d32

.labelc	move.w	W.62d32,d0
	move.l	#DAT.7a41a,a0
	tst.b	B.1ca31
	beq	.labelf
	jsr	R.62b7c
	beq	.labeld
	bpl	.labelc
	rts

.labeld	move.b	B.62bb4,d3
	addq.b	#1,d3
	cmpi.b	#30,d3
	blt	.labele
	move.b	#0,d3

.labele	move.b	d3,B.62bb7
	jsr	R.62bbe
	rts

.labelf	jsr	R.62b74
	beq	.label10
	bpl	.labelc
	rts

.label10
	move.b	B.62bb4,B.62bb6
	jsr	R.62bbe
	move.b	#0,d0
	jsr	R.5f374
	rts

R.629fe	move.b	#0,B.1bb92
	tst.b	d0
	bne	.label1
	rts

.label1	move.b	#44,d1
	cmpi.b	#34,d0
	beq	.label2
	move.b	#$3c,d1
	cmpi.b	#28,d0
	beq	.label2
	move.b	#212,d1

.label2	move.w	d1,d1
	jsr	R.1b82a
	jsr	wait.for.key
	lsr.w	#8,d0
	cmpi.b	#69,d0
	beq	R.62a66
	move.b	#3,d0
	jsr	set.bground.masks
	move.w	#145,d1
	jsr	R.1b82a
	move.b	#50,d2
	jsr	delay
	move.b	#1,d0
	rts

R.62a66	move.b	#$80,B.1bb92
	rts


R.62a70	move.b	#3,d0
	jsr	set.bground.masks
	move.b	B.62bba,print.column
	subi.b	#1,print.column
	move.b	#32,d0
	jsr	print.character
	move.b	#15,B.62bb8
	move.b	#11,B.62bb9
	jsr	R.62d8c
	subi.b	#9,print.column
	rts


R.62ab6	move.b	B.62bb4,d0
	subq.b	#1,d0
	bpl	.plus
	move.b	#29,d0

.plus	bra	R.62ade


R.62aca	move.b	B.62bb4,d0
	addq.b	#1,d0
	cmpi.b	#30,d0
	blt	R.62ade
	move.b	#0,d0

R.62ade	move.b	d0,B.62bb4
	tst.b	B.1ca31
	beq	.label1

	move.b	d0,B.62bb7
	rts

.label1	move.b	d0,B.62bb6
	rts


R.62afe	move.b	B.62bb4,d0
	addi.b	#10,d0
	cmpi.b	#30,d0
	blt	R.62ade
	rts


R.62b12	move.b	B.62bb4,d0
	subi.b	#10,d0
	bpl	R.62ade
	rts


R.62b22	jsr	read.joystick
	move.b	joystick.state,d0
	andi.b	#$f,d0
	eori.b	#$f,d0
	bne	R.62b22

	move.b	#76,d1
	jsr	test.key
	beq	R.62b22

	move.b	#77,d1
	jsr	test.key
	beq	R.62b22

	move.b	#79,d1
	jsr	test.key
	beq	R.62b22

	move.b	#78,d1
	jsr	test.key
	beq	R.62b22
	rts


R.62b74	move.w	#0,d3
	bra	R.62b80

R.62b7c	move.w	#1,d3

R.62b80	cmpi.w	#800,d3
	bcc	.label2

	move.w	d0,d1
	move.w	#0,d0
	move.w	#1,d2
	move.l	#$400,a1
	jsr	R.62e78
	clr.w	d1
	clr.w	d2

.label1	jsr	R.629fe
	rts

.label2	move.b	#$80,d0
	bra	.label1


	dc.b	0,8


B.62bb4	dc.b	0
do.key.validation	dc.b	0
B.62bb6	dc.b	0
B.62bb7	dc.b	0
B.62bb8	dc.b	15
B.62bb9	dc.b	11
B.62bba	dc.b	0
B.62bbb	dc.b	0
B.62bbc	dc.b	0
	dc.b	0


R.62bbe	clr.l	d0
	move.w	W.62d32,d0
	subi.l	#23,d0
	asl.l	#4,d0
	move.w	#7,d3
	move.l	#opponents.names+193,a0
	move.l	#TEXT.7a21a,a1
	add.l	d0,a1

.label1	move.b	(a0,d3.w),(a1,d3.w)
	dbra	d3,.label1
	move.b	#0,15(a1)

.label2	move.l	#TEXT.7a21a,a0
	move.w	#22,d0
	move.l	#$47826653,TEXT.7a21a+26
	move.b	B.62bb6,TEXT.7a21a+10
	move.b	B.62bb7,TEXT.7a21a+11
	jsr	R.62b7c
	beq	.label3
	bpl	.label2

.label3	rts


R.62c28	move.b	#1,B.62d08

.label1	move.b	#0,B.62bbb
	move.b	#0,B.1bb92
	move.l	#TEXT.7a21a,a0
	move.w	#22,d0
	jsr	R.62b74
	beq	.label2
	bmi	.label7
	bra	R.62c28

.label2	move.b	TEXT.7a21a+10,d0
	move.b	TEXT.7a21a+11,d3
	cmpi.l	#$47826653,TEXT.7a21a+26
	beq	.label6

	move.b	#$80,B.62bbb
	tst.b	B.1ca31
	beq	.label5
	move.w	#240,d1
	jsr	R.1b82a
	subq.b	#1,B.62d08
	bmi	.label5
	jsr	release.and.wait.for.key
	cmpi.b	#0,d0
	bne	.label3
	lsr.w	#8,d0
	cmpi.b	#69,d0
	bne	.label3
	move.b	#$80,B.1bb92
	bra	.label5

.label3	jsr	clear.menu
	move.b	#1,print.fine.y
	move.w	#0,d1
	tst.b	B.1ca31
	beq	.label4
	move.w	#22,d1

.label4	jsr	R.625a8
	move.b	#0,print.fine.y
	bra	.label1

.label5	move.b	#0,d0
	move.b	#0,d3

.label6	move.b	d0,B.62bb6
	move.b	d3,B.62bb7

.label7	rts



B.62d08	dc.b	0,0


R.62d0a	move.w	#0,d0
	move.w	#5,d1
	move.w	#1,d2
	move.w	#0,d3
	move.l	#TEXT.7a21a,a0
	move.l	#$400,a1
	jsr	R.62e78
	clr.w	d1
	clr.w	d0
	rts


W.62d32	dc.w	$8000


R.62d34	move.b	#0,or.with.screen
	move.b	#3,d0
	jsr	set.bground.masks
	move.b	#15,B.62bb8
	move.b	#11,B.62bb9
	move.b	#0,B.62bb4

.loop	jsr	R.62d8c
	addq.b	#1,B.62bb4
	cmpi.b	#30,B.62bb4
	bne	.loop

	move.b	#$80,or.with.screen
	rts


R.62d80	move.b	#$80,B.62bbc
	bra	R.62d92

R.62d8c	clr.b	B.62bbc

R.62d92	move.l	#opponents.names+193,a1
	move.b	#0,B.5b83e
	move.b	#6,d4
	move.b	B.62bb4,d5
	cmpi.b	#30,d5
	bcs	.label1
	move.b	#0,d5

.label1	cmpi.b	#10,d5
	blt	.label2
	subi.b	#10,d5
	addi.b	#10,d4
	bra	.label1

.label2	addi.b	#11,d5
	move.b	#31,d0
	jsr	print.character
	move.b	d4,d0			column
	jsr	print.character
	move.b	d5,d0			row
	jsr	print.character
	clr.w	d0
	move.b	B.62bb4,d0
	asl.w	#4,d0
	move.l	#TEXT.7a21a,a0
	lea	(a0,d0.w),a0
	move.w	#0,d3

.label3	tst.b	B.62bbc
	bpl	.label4
	move.l	#opponents.names+193,a0
	move.b	(a0,d3.w),d0
	bra	.label6

.label4	tst.b	15(a0)
	bne	.label5
	tst.b	B.62bbb
	bne	.label5
	move.b	B.62bb8,d0
	jsr	set.text.masks
	move.b	(a0,d3.w),d0
	move.b	d0,(a1,d3.w)
	cmpi.b	#32,d0
	ble	.label5
	addq.b	#1,B.5b83e
	bra	.label6

.label5	move.b	#32,(a1,d3.w)
	move.b	B.62bb9,d0
	jsr	set.text.masks
	move.b	#95,d0

.label6	jsr	print.character
	addq.w	#1,d3
	cmpi.w	#8,d3
	bne	.label3
	rts


R.62e78	jsr	R.62e86
	jmp	R.5ceb4

	dc.w	0

R.62e86	movem.l	d1-d7/a0-a5,-(sp)	disk code
	link	a6,#65500
	move.w	d0,d4
	andi.w	#3,d4
	move.w	d4,-36(a6)
	move.w	d1,-34(a6)
	move.w	d2,-32(a6)
	move.w	d3,-30(a6)
	move.l	a0,-28(a6)
	move.l	a1,-24(a6)
	rol.w	#1,d0
	andi.w	#1,d0
	addq.w	#1,d0
	move.w	d0,-20(a6)
	moveq	#30,d0
	move.w	d2,d3
	beq	disk7
	add.w	d1,d3
	cmp.w	#1760,d3
	bgt	disk7
	andi.l	#$ffff,d1
	divu	#11,d1
	cmpi.w	#1,-20(a6)
	beq.s	disk1
	add.w	d1,d1

disk1	move.w	d1,-18(a6)
	swap	d1
	move.w	d1,-16(a6)
	bsr	disk3f

disk2	move.w	-16(a6),d0
	moveq	#11,d1
	sub.w	d0,d1
	cmp.w	-32(a6),d1
	ble.s	disk3
	move.w	-32(a6),d1

disk3	move.w	d1,-14(a6)
	bsr	disk8
	bne.s	disk5
	cmpi.w	#1,-30(a6)
	bne.s	disk4
	bsr	disk2b
	bsr	disk10
	bne.s	disk5

disk4	move.w	-32(a6),d0
	sub.w	-14(a6),d0
	beq.s	disk5
	move.w	d0,-32(a6)
	move.w	-14(a6),d0
	lsl.l	#8,d0
	add.l	d0,d0
	add.l	d0,-28(a6)
	clr.w	-16(a6)
	move.w	-20(a6),d0
	add.w	d0,-18(a6)
	bra.s	disk2

disk5	move.l	d0,-(sp)
	bsr	disk3d
	bsr	disk2f
	move.l	(sp)+,d0
	beq.s	disk7
	moveq	#0,d1
	move.w	-18(a6),d1
	cmpi.w	#1,-20(a6)
	beq.s	disk6
	lsr.w	#1,d1

disk6	mulu	#11,d1
	add.w	-16(a6),d1
	add.w	-6(a6),d1
	move.l	d1,40(sp)

disk7	unlk	a6
	tst.l	d0
	movem.l	(sp)+,d1-d7/a0-a5
	rts

disk8	moveq	#4,d4

disk9	clr.w	-4(a6)
	clr.w	-6(a6)
	clr.w	-8(a6)
	move.w	-18(a6),d2
	bsr	disk40
	bne	diskd
	moveq	#29,d0
	btst	#2,CIAA
	beq	diskd
	move.l	-24(a6),a5
	lea	1024(a5),a5
	move.l	#$aaaaaaaa,(a5)
	move.w	#$4489,4(a5)
	bsr	disk23
	bsr	disk2f
	bsr	disk14
	bne	diskd
	move.w	-12(a6),d0
	beq.s	diskb
	mulu	#1088,d0
	lea	6(a5),a0
	bsr	disk38
	lea	intreqr+custom,a4
	bsr	disk1b
	bne.s	diske
	cmpi.w	#1,-30(a6)
	beq.s	diska
	move.w	-6(a6),d0
	sub.w	-14(a6),d0
	beq.s	diskf

diska	move.l	-24(a6),a5
	lea	1024(a5),a5
	move.w	-12(a6),d0
	mulu	#1088,d0
	add.l	d0,a5
	move.l	#$aaaaaaaa,(a5)
	move.w	#$4489,4(a5)
	move.l	a5,a0
	bsr	disk32

diskb	move.w	-10(a6),d0
	beq.s	diskc
	mulu	#1088,d0
	lea	6(a5),a0
	bsr	disk38
	lea	-2(a6),a4
	clr.w	(a4)
	bsr	disk1b
	bne.s	diske

diskc	move.w	-6(a6),d0
	sub.w	-14(a6),d0
	beq.s	diskf
	moveq	#26,d0

diskd	move.l	d0,-(sp)
	moveq	#2,d2
	bsr	disk40
	bsr	disk46
	move.l	(sp)+,d0

diske	dbra	d4,disk9

diskf	bsr	disk3c
	rts

disk10	moveq	#4,d2
	clr.w	-6(a6)

disk11	bsr	disk4c
	move.l	#200,d0
	bsr	disk4f
	moveq	#28,d0
	btst	#3,CIAA
	beq.s	disk13
	lea	custom,a0
	move.w	#16384,36(a0)
	move.l	-24(a6),32(a0)
	move.w	#26112,158(a0)
	move.w	#37120,158(a0)
	cmpi.w	#80,-18(a6)
	bcs.s	disk12
	move.w	#40960,158(a0)

disk12	move.w	#32784,150(a0)
	move.w	#2,156(a0)
	move.w	#55649,36(a0)
	move.w	#55649,36(a0)
	bsr	disk39
	beq.s	disk13
	dbra	d2,disk11

disk13	move.l	d0,-(sp)
	move.l	#2,d0
	bsr	disk4f
	move.l	(sp)+,d0
	rts

disk14	moveq	#10,d2

disk15	lea	6(a5),a0
	move.w	#64,d0
	bsr	disk38
	bsr	disk39
	bne.s	disk17
	bsr	disk27
	beq.s	disk16
	dbra	d2,disk15
	bra.s	disk18

disk16	bsr	disk25
	bne.s	disk19
	cmp.w	-18(a6),d1
	bne.s	disk19
	cmp.b	#11,d2
	bge.s	disk19
	cmp.b	#11,d3
	bgt.s	disk19
	subq.b	#1,d3
	move.w	d3,-12(a6)
	move.w	#11,-10(a6)
	sub.w	d3,-10(a6)
	moveq	#0,d0

disk17	rts

disk18	moveq	#24,d0
	rts

disk19	moveq	#27,d0
	rts

disk1a	moveq	#25,d0
	rts

disk1b	move.l	-24(a6),a5
	lea	1024(a5),a5
	move.w	-8(a6),d0
	mulu	#1088,d0
	add.l	d0,a5
	move.l	#$1770,d0
	bsr	disk52

disk1c	btst	#1,1(a4)
	bne	disk1f
	bsr	disk51
	beq	disk20
	tst.l	1088(a5)
	beq.s	disk1c
	bsr	disk27
	bne.s	disk18
	bsr	disk25
	bne.s	disk19
	cmp.w	-18(a6),d1
	bne.s	disk19
	move.w	d2,d3
	lea	8(a5),a0
	bsr	disk26
	move.b	#11,d0
	sub.b	-7(a6),d0
	lea	8(a5),a0
	bsr	disk31
	bsr	disk28
	lea	48(a5),a0
	bsr	disk31
	cmp.w	-16(a6),d3
	blt	disk1e
	move.w	-14(a6),d0
	add.w	-16(a6),d0
	cmp.w	d0,d3
	bge	disk1e
	btst	#1,1(a4)
	bne	disk1f
	move.w	-4(a6),d0
	btst	d3,d0
	bne	disk1e
	cmpi.w	#1,-30(a6)
	bne.s	disk1d
	bsr	disk21
	move.l	-28(a6),a0
	add.l	d1,a0
	lea	64(a5),a1
	bsr	disk2e
	btst	#1,1(a4)
	bne	disk1f
	lea	64(a5),a0
	move.w	#1024,d1
	bsr	disk29
	lea	56(a5),a0
	bsr	disk31
	bsr	disk22
	bra.s	disk1e

disk1d	lea	64(a5),a0
	move.w	#1024,d1
	bsr	disk29
	move.l	d0,-(sp)
	lea	56(a5),a0
	bsr	disk26
	cmp.l	(sp)+,d0
	bne	disk1a
	btst	#1,1(a4)
	bne.s	disk1f
	bsr.s	disk21
	lea	64(a5),a0
	move.l	-28(a6),a1
	add.l	d1,a1
	bsr	disk2d
	bsr	disk22
	move.w	-6(a6),d0
	cmp.w	-14(a6),d0
	beq.s	disk1f

disk1e	addq.w	#1,-8(a6)
	cmpi.w	#11,-8(a6)
	bne	disk1b

disk1f	moveq	#0,d0
	rts

disk20	moveq	#-1,d0
	rts

disk21	move.l	d3,d1
	sub.w	-16(a6),d1
	move.l	#$200,d0
	mulu	d0,d1
	rts

disk22	move.w	-4(a6),d0
	bset	d3,d0
	move.w	d0,-4(a6)
	addq.w	#1,-6(a6)
	rts

disk23	move.l	a5,a0
	moveq	#10,d1
	moveq	#0,d0

disk24	lea	1088(a0),a0
	move.l	d0,(a0)
	dbra	d1,disk24
	rts

disk25	lea	8(a5),a0
	bsr	disk26
	move.w	d0,d3
	andi.w	#255,d3
	move.w	d0,d2
	lsr.w	#8,d2
	swap	d0
	move.w	d0,d1
	andi.w	#255,d1
	lsr.w	#8,d0
	cmp.b	#$ff,d0
	rts

disk26	move.l	(a0)+,d0
	move.l	(a0)+,d1
	andi.l	#$55555555,d0
	andi.l	#$55555555,d1
	add.l	d0,d0
	or.l	d1,d0
	rts

disk27	bsr	disk28
	move.l	d0,-(sp)
	lea	48(a5),a0
	bsr	disk26
	cmp.l	(sp)+,d0
	rts

disk28	lea	8(a5),a0
	moveq	#40,d1

disk29	move.l	d2,-(sp)
	lsr.w	#2,d1
	subq.w	#1,d1
	moveq	#0,d0

disk2a	move.l	(a0)+,d2
	eor.l	d2,d0
	dbra	d1,disk2a
	move.l	(sp)+,d2
	andi.l	#$55555555,d0
	rts

disk2b	move.l	-24(a6),a0
	lea	1024(a0),a1
	move.l	#$aaaaaaaa,d0
	move.l	d0,d1
	move.l	d0,d2
	move.l	d0,d3
	move.l	d0,d4
	move.l	d0,d5
	move.l	d0,d6
	move.l	d0,d7

disk2c	movem.l	d0-d7,-(a1)
	cmp.l	a1,a0
	bne.s	disk2c
	rts

disk2d	move.l	a2,-(sp)
	bsr	disk30
	add.l	d0,a0
	subq.l	#1,a0
	move.l	a0,80(a2)
	add.l	d0,a0
	move.l	a0,76(a2)
	add.l	d0,a1
	subq.l	#1,a1
	move.l	a1,84(a2)
	move.w	#7640,64(a2)
	move.w	#2,66(a2)
	lsl.w	#2,d0
	ori.w	#8,d0
	move.w	d0,88(a2)
	move.l	(sp)+,a2
	rts

disk2e	movem.l	d1-d3/a2,-(sp)
	bsr	disk30
	move.w	d0,d1
	lsl.w	#2,d1
	ori.w	#8,d1
	move.l	a0,80(a2)
	move.l	a0,76(a2)
	move.l	a1,84(a2)
	move.w	#7601,64(a2)
	move.w	#0,66(a2)
	move.w	d1,88(a2)
	bsr	disk2f
	move.l	a0,80(a2)
	move.l	a1,76(a2)
	move.l	a1,84(a2)
	move.w	#11660,64(a2)
	move.w	d1,88(a2)
	bsr	disk2f
	move.l	a0,d2
	add.l	d0,d2
	subq.l	#2,d2
	move.l	a1,d3
	add.l	d0,d3
	add.l	d0,d3
	subq.l	#2,d3
	move.l	d2,80(a2)
	move.l	d2,76(a2)
	move.l	d3,84(a2)
	move.w	#3505,64(a2)
	move.w	#4098,66(a2)
	move.w	d1,88(a2)
	bsr	disk2f
	move.l	a1,d3
	add.l	d0,d3
	move.l	a0,80(a2)
	move.l	d3,76(a2)
	move.l	d3,84(a2)
	move.w	#7564,64(a2)
	move.w	#0,66(a2)
	move.w	d1,88(a2)
	bsr	disk2f
	move.l	d0,d1
	move.l	a1,a0
	bsr	disk32
	add.l	d1,a0
	bsr	disk32
	add.l	d1,a0
	bsr.s	disk32
	movem.l	(sp)+,d1-d3/a2
	rts

disk2f	btst	#6,dmaconr+custom
	bne.s	disk2f
	rts

disk30	lea	custom,a2
	bsr	disk2f
	move.w	#32832,150(a2)
	move.l	#$ffffffff,68(a2)
	move.w	#21845,112(a2)
	clr.w	100(a2)
	clr.w	98(a2)
	clr.w	102(a2)
	rts

disk31	move.l	d0,-(sp)
	lsr.l	#1,d0
	bsr	disk36
	move.l	(sp)+,d0
	bsr	disk36

disk32	move.b	(a0),d0
	btst	#0,-1(a0)
	bne.s	disk33
	btst	#6,d0
	bne.s	disk35
	bset	#7,d0
	bra.s	disk34

disk33	bclr	#7,d0

disk34	move.b	d0,(a0)

disk35	rts

disk36	andi.l	#$55555555,d0
	move.l	d0,d2
	eori.l	#$55555555,d2
	move.l	d2,d1
	add.l	d2,d2
	lsr.l	#1,d1
	bset	#31,d1
	and.l	d2,d1
	or.l	d1,d0
	btst	#0,-1(a0)
	beq.s	disk37
	bclr	#31,d0

disk37	move.l	d0,(a0)+
	rts

disk38	lea	custom,a1
	move.w	#16384,36(a1)
	move.w	#32784,150(a1)
	move.w	#26112,158(a1)
	move.w	#38144,158(a1)
	move.w	#17545,126(a1)
	move.l	a0,32(a1)
	move.w	#2,156(a1)
	lsr.w	#1,d0
	ori.w	#32768,d0
	move.w	d0,36(a1)
	move.w	d0,36(a1)
	rts

disk39	lea	custom,a1
	move.l	#$1770,d0
	bsr	disk52

disk3a	btst	#1,31(a1)
	bne.s	disk3b
	bsr	disk51
	bne.s	disk3a
	moveq	#-1,d0
	bra.s	disk3c

disk3b	moveq	#0,d0

disk3c	move.w	#2,intreq+custom
	move.w	#16384,dsklen+custom
	tst.l	d0
	rts

disk3d	move.w	#1024,adkcon+custom
	moveq	#-1,d1

disk3e	move.b	d1,$bfd100
	move.w	-36(a6),d0
	addq.l	#3,d0
	bclr	d0,d1
	move.b	d1,$bfd100
	bset	d0,d1
	move.b	d1,$bfd100
	rts

disk3f	moveq	#-1,d1
	move.b	d1,$bfd100
	bclr	#7,d1
	bsr.s	disk3e
	move.l	#200,d0
	bsr	disk4f
	rts

disk40	movem.l	d2-d3,-(sp)
	move.l	d2,d3
	bsr	disk4c
	move.w	-36(a6),d0
	add.w	d0,d0
	lea	TAB.63684(pc),a0
	move.w	(a0,d0.w),d0
	bpl.s	disk41
	bsr	disk46
	bne.s	disk45

disk41	lsr.w	#1,d0
	lsr.w	#1,d2
	moveq	#1,d1
	sub.w	d0,d2
	beq.s	disk44
	bpl.s	disk42
	moveq	#-1,d1
	neg.w	d2

disk42	moveq	#6,d0

disk43	bsr	disk4a
	moveq	#6,d0
	subq.w	#1,d2
	bne.s	disk43

disk44	move.w	-36(a6),d0
	add.w	d0,d0
	lea	TAB.63684(pc),a0
	move.w	d3,(a0,d0.w)
	bsr	disk4c
	moveq	#0,d0

disk45	movem.l	(sp)+,d2-d3
	rts

disk46	movem.l	d2,-(sp)
	moveq	#85,d2

disk47	btst	#4,CIAA
	beq.s	disk48
	moveq	#6,d0
	moveq	#-1,d1
	bsr	disk4a
	dbra	d2,disk47
	moveq	#30,d0
	bra.s	disk49

disk48	move.w	-36(a6),d0
	add.w	d0,d0
	lea	TAB.63684(pc),a0
	clr.w	(a0,d0.w)
	moveq	#0,d0

disk49	movem.l	(sp)+,d2
	rts

disk4a	move.l	d0,-(sp)
	bsr	disk4d
	tst.b	d1
	bmi.s	disk4b
	bclr	#1,d0

disk4b	bclr	#0,d0
	move.b	d0,$bfd100
	bset	#0,d0
	move.b	d0,$bfd100
	move.l	(sp)+,d0
	bsr	disk4f
	rts

disk4c	bsr	disk4d
	move.b	d0,$bfd100
	rts

disk4d	movem.w	d1-d2,-(sp)
	move.w	-36(a6),d0
	move.b	$bfd100,d2
	ori.b	#127,d2
	addi.b	#3,d0
	bclr	d0,d2
	subi.b	#3,d0
	add.w	d0,d0
	move.w	TAB.63684(pc,d0.w),d1
	btst	#0,d1
	beq.s	disk4e
	bclr	#2,d2

disk4e	move.b	d2,d0
	movem.w	(sp)+,d1-d2
	rts

disk4f	bsr	disk52

disk50	btst	#0,$bfee01
	bne.s	disk50
	subq.l	#1,d0
	bne.s	disk4f
	rts

disk51	btst	#0,$bfee01
	bne.s	disk53
	subq.l	#1,d0
	beq.s	disk53

disk52	move.b	#8,$bfee01
	move.b	#204,$bfe401
	move.b	#2,$bfe501

disk53	rts


TAB.63684
	dc.w	0,-1,-1,-1


****************************************


save.random.values
	move.l	random.long,random.seed
	move.b	random.byte,random.seed+1
	rts


set.random.values
	move.l	random.seed,random.long
	move.b	random.seed+1,random.byte
	rts


random.seed	dc.l	$3b3b1e49,$3b3b3562


****************************************


* All of opponent.player.interaction (and subroutines) can be bypassed and replaced by the below
* this disables player to opponent collisions and fixes the opponent in the middle of the road
;opponent.player.interaction.bypass
;	move.b	#0,player.close.to.opponent
;	move.b	#128,opponents.road.x.position+1
;	rts

* Calculates opponent movement sideways and collision with player
opponent.player.interaction
	IFD	RECORD_OPPONENT_OPI
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opponents.ID,d7
	move.w	d7,(a0)+

	move.w	opponents.road.x.position,(a0)+
	move.b	rear.wheel.surface.x.position,d7
	move.w	d7,(a0)+
	move.w	smallest.distance.between.players,(a0)+

	move.b	opponent.behind.player,d7
	move.w	d7,(a0)+

	move.w	players.road.x.position,(a0)+
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+
	move.w	opponents.distance.into.section,(a0)+
	move.b	B.1bbbd,d7
	move.w	d7,(a0)+

	move.b	opp.touching.road,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.b	opponents.ID,d1
	move.b	#0,d2
	move.b	d2,player.close.to.opponent

	move.b	opponents.road.x.position+1,d0
	move.b	d0,opponents.suggested.road.x.position

	sub.b	rear.wheel.surface.x.position,d0
	bcc	.positive

	neg.b	d0
	subq.b	#1,d2		flag that player is to right of opponent

.positive
	move.b	d0,x.difference
	move.b	d2,player.to.right

	move.b	smallest.distance.between.players,d0
	beq	.close
	jmp	.far

* Player and opponent are within $100 of each other (ahead or behind)

.close	move.b	smallest.distance.between.players+1,d0
	cmpi.b	#64,d0
	bcc	.close.checked

	tst.b	opponent.behind.player
	bmi	.flag.close

	cmpi.b	#50,x.difference
	bcc	.close.checked

* Either:-
*  Opponent less than 64 behind player
*  OR Player less than 64 behind and less than 50 to the left or right of opponent

.flag.close
	subq.b	#1,player.close.to.opponent

.close.checked
	cmpi.b	#16,d0
	bcc	.label3

	tst.b	machine
	beq	.label1

	tst.b	opponents.road.x.position
	bne	.label3

.label1	move.b	x.difference,d0
	cmpi.b	#50,d0
	bcc	.label3

	move.b	players.road.x.position,d0
	cmpi.b	#1,d0
	bcs	.label2
	bne	.label3

	move.b	players.road.x.position+1,d0
	cmpi.b	#$80,d0
	bcc	.label3

.label2	jsr	car.to.car.collision.detection
	jmp	.label4

* Not within 16
.label3	move.b	#0,d0
	move.b	d0,B.1bbc3	clear collision values
	move.b	#0,B.1bbeb

	move.b	smallest.distance.between.players+1,d0
	cmpi.b	#24,d0
	bcc	.label6

.label4	move.l	#opponent.attributes,a1
	move.b	(a1,d1.w),d0
	andi.b	#DRIVES_NEAR_EDGE,d0
	beq	.label5

	tst.b	opponent.behind.player
	bmi	.label5

	move.b	smallest.distance.between.players+1,d0
	cmpi.b	#14,d0
	bcc	.far

.label5	jsr	move.opponent.to.one.side
	jmp	.labelf

.label6	tst.b	opponent.behind.player
	bmi	.label9

	cmpi.b	#50,d0
	bcc	.label7

	move.l	#opponent.attributes,a1
	move.b	(a1,d1.w),d0
	andi.b	#OBSTRUCTS_PLAYER,d0
	beq	.label8

	jsr	opponent.obstruct.player	put opponent at same position as player
	jmp	.labelc

.label7	cmpi.b	#200,d0
	bcc	.far

	move.l	#opponent.attributes,a1
	move.b	(a1,d1.w),d0
	andi.b	#PUSH_PLAYER,d0		opponent pushing player off track
	beq	.far

.label8	jsr	opponent.push.player
	jmp	.labelc

.label9	jsr	opponent.push.player
	jmp	.labelf

* Player and opponent atleast $100 from each other (ahead or behind)

.far	move.b	#64,d2
	move.l	#opponent.attributes,a1
	move.b	(a1,d1.w),d0
	andi.b	#DRIVES_NEAR_EDGE,d0
	beq	.labela
	move.b	#110,d2

.labela	move.b	d1,d0		opponents.ID
	andi.b	#1,d0
	beq	.labelb
	not.b	d2		to other side of road

.labelb	move.b	d2,opponents.suggested.road.x.position

.labelc	move.b	#2,d0
	move.b	d0,road.height+1

	move.b	opponents.road.section,d1
	move.b	d1,current.road.section

.labeld	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	move.b	d0,d2
	move.l	#sections.car.can.be.put.on,a2
	move.b	(a2,d2.w),d0
	bpl	.labele
	move.b	#$80,opponents.suggested.road.x.position

.labele	jsr	to.next.road.section
	subq.b	#1,road.height+1
	bne	.labeld

.labelf	move.b	B.1bbbd,d0
	bmi	.label10
	bne	.label11

	move.b	opponents.suggested.road.x.position,d0
	sub.b	opponents.road.x.position+1,d0
	beq	.label13
	bcc	.label11

.label10
	cmpi.b	#$f0,d0
	bcc	.label13

	move.b	#256-9,d0
	bne	.label12

.label11
	cmpi.b	#16,d0
	bcs	.label13
	move.b	#9,d0

.label12
	add.b	opponents.road.x.position+1,d0
	move.b	opp.touching.road,d2
	beq	.label13

	cmpi.b	#225,d0
	bcc	.label13

	cmpi.b	#32,d0
	bcs	.label13

	tst.b	machine
	bne	.label13

	move.b	d0,opponents.road.x.position+1
.label13
	IFD	RECORD_OPPONENT_OPI
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	x.difference,d7
	move.w	d7,(a0)+
	move.b	player.to.right,d7
	move.w	d7,(a0)+
	move.b	player.close.to.opponent,d7
	move.w	d7,(a0)+
	move.b	opponents.suggested.road.x.position,d7
	move.w	d7,(a0)+
	move.w	opponents.road.x.position,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC
	rts


* Position opponent on left or right
move.opponent.to.one.side
	IFD	RECORD_OPPONENT_MOTOS
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	x.difference,d7
	move.w	d7,(a0)+
	move.b	player.to.right,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.b	x.difference,d0
	cmpi.b	#56,d0
	bcc	opp4

	tst.b	player.to.right
****
	IFD	RECORD_OPPONENT_MOTOS
	bmi	opp3a
;	bpl	opp1a
opp1a	move.b	#256-32,d0
	move.b	d0,opponents.suggested.road.x.position
	bra.s	opp4a

opp3a	move.b	#32,d0
	move.b	d0,opponents.suggested.road.x.position

opp4a
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opponents.suggested.road.x.position,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
	rts
.done2
****
	ELSE
	bmi	opp3
	bpl	opp1
	ENDC

* Opponent pushing player off track
opponent.push.player
	move.b	x.difference,d0
	cmpi.b	#56,d0
	bcc	opp4

	move.b	rear.wheel.surface.x.position,d0
	tst.b	player.to.right
	bmi	opp2

	cmpi.b	#160,d0
	bcc	opp3

opp1	move.b	#256-32,d0
	move.b	d0,opponents.suggested.road.x.position
	rts

opp2	cmpi.b	#96,d0
	bcs	opp1

opp3	move.b	#32,d0
	move.b	d0,opponents.suggested.road.x.position
opp4	rts


* Put opponent at same position as player
opponent.obstruct.player
	move.b	rear.wheel.surface.x.position,d0
	move.b	d0,opponents.suggested.road.x.position
	rts


opponent.movement
	move.b	drop.start.done,d0
	beq	.done

	move.b	B.1bb74,d0		; always zero (except maybe for computer link)
	bne	.done

	move.b	opponents.road.section,d1
	jsr	fetch.near.section.stuff
	jsr	update.opponents.actual.wheel.heights
	jsr	randomize.opponents.steering	; optional
	jsr	get.opponents.engine.acceleration
	jsr	adjust.opponents.engine.acceleration

	IFD	RECORD_OPPONENT_AOEA
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	#0,d7
	move.b	opponents.required.z.speed.reached,d7
	move.w	d7,(a0)+
	move.w	opponents.engine.z.acceleration,(a0)+
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	jsr	update.opponents.z.speed

	IFD	RECORD_OPPONENT_OM
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	opponents.z.speed,(a0)+
	move.w	#0,d7
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+
	move.b	byte.count,d7
	move.w	d7,(a0)+
	move.w	opponents.distance.into.section,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC

	move.b	road.length.reduction,d0
	move.b	d0,factor1

	move.w	opponents.z.speed,d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	move.b	#REDUCTION,d2
	beq	.zero
	muls	d2,d0
	asr.l	#8,d0
.zero	ext.l	d0
	asl.l	#3,d0
	move.b	d0,d3
	asr.l	#8,d0
	add.b	d3,byte.count
	bcc	.add
	addq.w	#1,d0

.add	add.w	d0,opponents.distance.into.section

	move.b	opponents.distance.into.section,d0
	cmp.b	number.of.segments,d0
	bcs	.done.update

	sub.b	number.of.segments,d0
	move.b	d0,opponents.distance.into.section

	move.b	opponents.road.section,d1
	addq.b	#1,d1
	cmp.b	number.of.road.sections,d1
	bcs	.section.ok
	move.b	#0,d1

.section.ok
	move.b	d1,opponents.road.section

.done.update
	IFD	RECORD_OPPONENT_OM
	tst.b	recording
	beq.s	.done3
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+
	move.w	opponents.distance.into.section,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done3
	ENDC

.done	rts


initialise.opponent.data
	jsr	calculate.opponents.road.wheel.positions
	jsr	randomize.long
	andi.w	#$7f,d0
	addi.b	#$68,d0
	move.l	#opp.rear.left.road.height,a0
	move.l	#opp.rear.left.actual.height,a1
	move.b	#6,d1

.set	move.w	(a0,d1.w),d3
	add.w	d0,d3
	move.w	d3,(a1,d1.w)
	subq.b	#2,d1
	bpl	.set
	rts


srd1.sub4
	tst.b	multi.no.of.players
	beq	srd1s41

	tst.b	B.1ca35
	bne	srd1s43

srd1s41	move.w	#$ff,d4

srd1s42	jsr	randomize.long
	dbra	d4,srd1s42

	clr.w	d1
	move.b	road.ID,d1
	move.b	B.1ca2a,d2
	tst.b	league.offset
	beq	standard.league4

	addi.b	#32,d1
	move.b	B.1ca2b,d2

standard.league4
	move.b	d2,damaged.limit
	jsr	randomize.long

	move.l	#DAT.1fe2c,a0
	and.b	(a0,d1.w),d0
	add.b	8(a0,d1.w),d0
	move.b	d0,opponent.max.speed
	jsr	randomize.long

	and.b	16(a0,d1.w),d0
	add.b	24(a0,d1.w),d0
	move.b	d0,B.63ce1
srd1s43	rts


update.opponents.z.speed
	IFD	RECORD_OPPONENT_UOZS
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opp.touching.road,d7
	move.w	d7,(a0)+
	move.w	opponents.z.speed,(a0)+

	move.b	player.close.to.opponent,d7
	move.w	d7,(a0)+
	move.b	opponent.behind.player,d7
	move.w	d7,(a0)+

	move.w	opponents.engine.z.acceleration,(a0)+
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+

	move.w	opp.rear.left.road.height,(a0)+
	move.w	opp.rear.right.road.height,(a0)+
	move.w	opp.front.road.height,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.w	#0,acceleration.adjust

	move.b	opponents.z.speed+1,d0
	asl.b	#1,d0
	move.b	opponents.z.speed,d0
	bmi	.acceleration.ok

	roxl.b	#1,d0			gives d0.b = opponents.z.speed >> 7

	tst.b	player.close.to.opponent
	bpl	.got.speed

	tst.b	opponent.behind.player
	bpl	.got.speed

* Reduce speed value if opponent close behind player

	subi.b	#20,d0
	bcc	.got.speed
	move.b	#0,d0

.got.speed
	move.b	d0,factor1

* A fraction of the square of the speed is subtracted from acceleration
* This only has a small effect

	move.b	opponents.z.speed,d0
	jsr	byte.multiply
	asr.w	#6,d3
	move.w	d3,acceleration.adjust

	move.b	opp.touching.road,d0
	beq	.acceleration.ok

* Reduce the acceleration further when on the road

	move.w	opponents.engine.z.acceleration,d0
	bmi	.acceleration.ok

	move.w	#0,d3
	move.b	opponents.z.speed,d3
	sub.w	d3,d0			subtract fraction of speed from acceleration
	tst.b	near.section.byte1
	bpl	.store

	sub.w	d3,d0			subtract again when on a curve
	subi.w	#35,d0			then reduce further

.store	move.w	d0,opponents.engine.z.acceleration

.acceleration.ok
	move.w	opponents.engine.z.acceleration,d0
	sub.w	acceleration.adjust,d0
	tst.b	opp.touching.road
	beq	.update.speed

	move.w	opp.rear.left.road.height,d3
	add.w	opp.rear.right.road.height,d3
	lsr.w	#1,d3
	sub.w	opp.front.road.height,d3

* d3 is -'ve when opponent pitched backwards, +'ve when pitched forwards

	move.w	d3,d4
	bpl	.positive
	neg.w	d4

.positive
	cmpi.w	#512,d4
	bcs	.limited
	move.w	#510,d4

.limited
	lsr.w	#1,d4		pitch value / 2
	move.w	d4,d5
	asr.w	#2,d5		pitch value / 8
	add.w	d4,d5		(5 * pitch value) / 8
	tst.w	d3
	bpl	.adjust
	neg.w	d5

* Acceleration is reduced when opponent pitched backwards, increased when pitched forwards
* i.e. effect of gravity
.adjust	add.w	d5,d0

.update.speed
	move.b	#REDUCTION,d2
	beq	.update
	muls	d2,d0
	asr.l	#8,d0
.update	add.w	d0,opponents.z.speed
	bpl	.done

	move.w	#0,opponents.z.speed
.done
	IFD	RECORD_OPPONENT_UOZS
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	opponents.engine.z.acceleration,(a0)+
	move.w	opponents.z.speed,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC
	rts


get.opponents.engine.acceleration
	IFD	RECORD_OPPONENT_GOEA
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opponents.random.steering.count,d7
	move.w	d7,(a0)+
	move.b	opp.touching.road,d7
	move.w	d7,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.b	opponents.engine.power,d0
	move.b	opponents.engine.power+1,d2
	move.b	opponents.random.steering.count,d1
	beq	.power.set
	subi.b	#25,d0

.power.set
	move.b	opp.touching.road,d1
	bne	.set.acceleration
	move.b	#0,d0
	move.b	d0,d2

.set.acceleration
	move.b	d0,opponents.engine.z.acceleration+1
	move.b	d2,opponents.engine.z.acceleration

	IFD	RECORD_OPPONENT_GOEA
	tst.b	recording
	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	opponents.engine.z.acceleration,(a0)+
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC
	rts


adjust.opponents.engine.acceleration
	IFD	RECORD_OPPONENT_AOEA
	tst.b	recording
	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0

	move.w	#0,d7
	move.b	opp.touching.road,d7
	move.w	d7,(a0)+
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+
	move.b	opponent.max.speed,d7
	move.w	d7,(a0)+
	move.w	opponents.z.speed,(a0)+
	move.w	opponents.engine.z.acceleration,(a0)+

	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	tst.b	opp.touching.road
	bne	.on.road
	rts

.on.road
	move.b	opponents.road.section,d1
	move.l	#opponents.speed.values,a0
	move.b	(a0,d1.w),d0
	bmi	.got.speed

	cmp.b	opponent.max.speed,d0
	bcs	.got.speed
	move.b	opponent.max.speed,d0

.got.speed
	andi.b	#$7f,d0
	move.b	d0,opponents.required.z.speed

	move.b	opponents.z.speed,d0
	sub.b	opponents.required.z.speed,d0
	bcs	.sometimes.double.acceleration
	beq	.speed.reached

* Speed is greater than required speed

	move.b	#$80,opponents.required.z.speed.reached
	neg.w	opponents.engine.z.acceleration
	cmpi.b	#14,d0
	bcs	.done

.sometimes.double.acceleration
	move.l	#opponents.speed.values,a1
	tst.b	(a1,d1.w)
	bmi	.double.acceleration

	tst.b	d0
	bpl	.double.acceleration

	move.b	opponents.required.z.speed.reached,d2
	beq	.double.acceleration

	cmpi.b	#$fe,d0
	bcc	.done
	bclr	#7,opponents.required.z.speed.reached

.double.acceleration
	asl.w	opponents.engine.z.acceleration
.done	rts

.speed.reached
	move.b	#$80,opponents.required.z.speed.reached
	rts


opponent.max.speed	dc.b	0
B.63ce1	dc.b	0
damaged.limit	dc.b	0,0


car.to.car.collision.detection
	move.b	drop.start.done,d0
	bne	.label2
	rts

.label1	move.b	#3,B.1bbc3
	rts

.label2	move.b	opp.touching.road,d0
	beq	.label3

	move.b	touching.road,d0
	bne	.label6			if touching road

.label3	move.w	players.smaller.y,d0
	sub.w	opp.rear.left.actual.height,d0
	move.w	d0,d4
	addi.w	#40,d0
	bpl	.label4
	neg.w	d0

.label4	cmpi.w	#192,d0
	bge	.label1

	tst.b	B.1bbc3
	beq	.label6

	subq.b	#1,B.1bbc3
	move.w	#256,d3
	sub.w	d0,d3
	tst.w	d4
	bpl	.label5
	neg.w	d3

.label5	asl.w	#4,d3
	move.w	d3,car.to.car.y.acceleration

.label6	move.b	x.difference,d0
	cmpi.b	#45,d0
	bcc	.label8

	move.b	smallest.distance.between.players+1,d0
	cmpi.b	#8,d0
	bcc	.label8

	move.b	#8,d0
	tst.b	player.to.right
	bmi	.label7
	move.b	#248,d0

.label7	move.b	d0,car.to.car.x.acceleration

.label8	tst.b	B.1bbeb
	bmi	.labelb

	move.w	#3,d3
	move.w	#0,d0
	tst.b	B.1bb74
	bne	.label9
	move.w	opponents.z.speed,d0

.label9	sub.w	players.z.speed,d0
	bpl	.labela
	move.w	#-3,d3

.labela	asr.w	#1,d0
	add.w	d3,d0
	move.w	d0,car.to.car.z.acceleration

.labelb	move.b	#$80,cars.collided
	move.b	#$80,B.1bbeb
	move.w	#512,d3
	move.w	car.to.car.x.acceleration,d0
	bpl	.labelc
	neg.w	d0

.labelc	add.w	d0,d3
	move.w	car.to.car.y.acceleration,d0
	bpl	.labeld
	neg.w	d0

.labeld	add.w	d0,d3
	move.w	car.to.car.z.acceleration,d0
	bpl	.labele
	neg.w	d0

.labele	add.w	d0,d3
	lsr.w	#8,d3
	move.l	#front.left.damage,a0
	move.w	#2,d2

.labelf	move.b	(a0,d2.w),d0
	add.b	d3,d0
	bcc	.label10
	move.b	#$ff,d0

.label10
	move.b	d0,(a0,d2.w)
	subq.b	#1,d2
	bpl	.labelf

	move.b	#$80,damaged
	rts


car.to.car.collision
	tst.b	cars.collided.delay
	beq	ctcc1
	subq.b	#1,cars.collided.delay

ctcc1	tst.b	cars.collided
	beq	ctcc3

	move.b	#0,cars.collided

	move.w	opponents.z.speed,d0
	sub.w	car.to.car.z.acceleration,d0
	bpl	ctcc2
	move.w	#0,d0
ctcc2	move.w	d0,opponents.z.speed

	move.w	car.to.car.y.acceleration,d0
	asr.w	#4,d0
	sub.w	d0,opp.rear.left.y.speed
	sub.w	d0,opp.rear.right.y.speed
	sub.w	d0,opp.front.y.speed

	move.w	car.to.car.x.acceleration,d0
	add.w	d0,car.collision.x.acceleration

	move.w	car.to.car.y.acceleration,d0
	add.w	d0,car.collision.y.acceleration

	move.w	car.to.car.z.acceleration,d0
	add.w	d0,car.collision.z.acceleration

	move.w	#0,car.to.car.x.acceleration
	move.w	#0,car.to.car.y.acceleration
	move.w	#0,car.to.car.z.acceleration

******** Play collision sound if necessary ********

	tst.b	cars.collided.delay
	bne	ctcc3

	move.b	#2,d0			hit car
	jsr	sound.effect
	move.b	#5,cars.collided.delay
ctcc3	rts


opp.smallest.difference	dc.w	0
cars.collided.delay	dc.b	0,0


* Unlike the player's car, the opponent's car has one front wheel value and two rear wheel values

update.opponents.actual.wheel.heights
	move.w	#$8000,opp.smallest.difference

	move.w	#40,d0
	tst.b	near.section.byte1
	bpl	.label1
	move.w	#124,d0			increase collision when on a curve
.label1	move.w	d0,height.adjust

	IFD	RECORD_OPPONENT_AWH
;	tst.b	recording
;	beq.s	.done1
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	move.w	#0,d7
	move.b	opponents.ID,d7
	move.w	d7,(a0)+
	move.b	opponents.road.section,d7
	move.w	d7,(a0)+
	move.w	opp.rear.left.road.height,(a0)+
	move.w	opp.rear.right.road.height,(a0)+
	move.w	opp.front.road.height,(a0)+
	;
	move.w	opp.rear.left.actual.height,(a0)+
	move.w	opp.rear.right.actual.height,(a0)+
	move.w	opp.front.actual.height,(a0)+
	;
	move.w	opp.old.rear.left.difference,(a0)+
	move.w	opp.old.rear.right.difference,(a0)+
	move.w	opp.old.front.difference,(a0)+
	;
	move.w	d0,(a0)+		height.adjust
	;
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done1
	ENDC

	move.w	#0,d7

****************************************

	move.w	opp.rear.left.road.height,d0
	sub.w	opp.rear.left.actual.height,d0
	cmp.w	opp.smallest.difference,d0
	blt	.label2
	move.w	d0,opp.smallest.difference

.label2	add.w	height.adjust,d0
	bpl	.label3			if wheel below road

	cmpi.w	#-96,d0
	bcc	.label3
	move.w	#-96,d0			set to maximum amount above road

.label3	move.w	d0,d6
	sub.w	opp.old.rear.left.difference,d0
	jsr	calculate.difference
	bpl	.label4
	move.w	#0,d0

.label4	cmpi.w	#1024,d0
	blt	.label5
	move.w	#1023,d0

.label5	or.w	d0,d7
	sub.w	height.adjust,d0
	move.w	d0,opp.new.rear.left.difference
	move.w	d6,opp.old.rear.left.difference

****************************************

	move.w	opp.rear.right.road.height,d0
	sub.w	opp.rear.right.actual.height,d0
	cmp.w	opp.smallest.difference,d0
	blt	.label6
	move.w	d0,opp.smallest.difference

.label6	add.w	height.adjust,d0
	bpl	.label7

	cmpi.w	#-96,d0
	bcc	.label7
	move.w	#-96,d0

.label7	move.w	d0,d6
	sub.w	opp.old.rear.right.difference,d0
	jsr	calculate.difference
	bpl	.label8
	move.w	#0,d0

.label8	cmpi.w	#1024,d0
	blt	.label9
	move.w	#1023,d0

.label9	or.w	d0,d7
	sub.w	height.adjust,d0
	move.w	d0,opp.new.rear.right.difference
	move.w	d6,opp.old.rear.right.difference

****************************************

	move.w	opp.front.road.height,d0
	sub.w	opp.front.actual.height,d0
	cmp.w	opp.smallest.difference,d0
	blt	.labela
	move.w	d0,opp.smallest.difference

.labela	add.w	height.adjust,d0
	bpl	.labelb

	cmpi.w	#-96,d0
	bcc	.labelb
	move.w	#-96,d0

.labelb	move.w	d0,d6
	sub.w	opp.old.front.difference,d0
	jsr	calculate.difference
	bpl	.labelc
	move.w	#0,d0

.labelc	cmpi.w	#1024,d0
	blt	.labeld
	move.w	#1023,d0

.labeld	or.w	d0,d7
	sub.w	height.adjust,d0
	move.w	d0,opp.new.front.difference
	move.w	d6,opp.old.front.difference

****************************************

	move.w	d7,d0
	asr.w	#8,d0
	or.b	d7,d0
	move.b	d0,opp.touching.road

	IFD	RECORD_OPPONENT_AWH
;	tst.b	recording
;	beq.s	.done2
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	;
	move.w	opp.old.rear.left.difference,(a0)+
	move.w	opp.old.rear.right.difference,(a0)+
	move.w	opp.old.front.difference,(a0)+
	;
	move.w	opp.new.rear.left.difference,(a0)+
	move.w	opp.new.rear.right.difference,(a0)+
	move.w	opp.new.front.difference,(a0)+
	;
	move.w	d7,(a0)+		touching road value
	;
	clr.b	(a0)+
	move.b	d0,(a0)+		opp.touching.road
	;
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done2
	ENDC

****************************************

	move.w	opp.new.rear.left.difference,d4
	add.w	opp.new.rear.right.difference,d4
	add.w	opp.new.front.difference,d4

* Make accelerations from 6 parts wheel difference in question and 1 part
* of the other two wheels (only one central front wheel is considered).

	move.w	opp.new.rear.left.difference,d7
	asl.w	#2,d7
	move.w	d4,d0
	add.w	opp.new.rear.left.difference,d0
	add.w	d7,d0
	asr.w	#3,d0
	move.w	d0,opp.rear.left.y.acceleration

	move.w	opp.new.rear.right.difference,d7
	asl.w	#2,d7
	move.w	d4,d0
	add.w	opp.new.rear.right.difference,d0
	add.w	d7,d0
	asr.w	#3,d0
	move.w	d0,opp.rear.right.y.acceleration

	move.w	opp.new.front.difference,d7
	asl.w	#2,d7
	move.w	d4,d0
	add.w	opp.new.front.difference,d0
	add.w	d7,d0
	asr.w	#3,d0
	move.w	d0,opp.front.y.acceleration

****************************************

	move.b	opponents.ID,d1
	move.l	#opponent.attributes,a0
	move.b	(a0,d1.w),d0
	andi.b	#WHEELIE,d0
	beq	.labele

	move.w	opp.front.y.speed,d0
	or.w	opp.front.y.acceleration,d0
	andi.w	#$fffc,d0
	bne	.labele

	jsr	randomize.long
	andi.b	#$f,d0
	bne	.labele

* Make opponent do a wheelie

	move.w	#160,opp.front.y.speed

****************************************

.labele	move.w	opp.rear.left.y.acceleration,d0
	move.b	#REDUCTION,d2
	beq	.labelf
	muls	d2,d0
	asr.l	#8,d0
.labelf	add.w	opp.rear.left.y.speed,d0
	move.w	d0,opp.rear.left.y.speed

	move.b	#REDUCTION,d2
	beq	.label10
	muls	d2,d0
	asr.l	#8,d0
.label10
	asr.w	#1,d0
	add.w	d0,opp.rear.left.actual.height

****************************************

	move.w	opp.rear.right.y.acceleration,d0
	move.b	#REDUCTION,d2
	beq	.label11
	muls	d2,d0
	asr.l	#8,d0
.label11
	add.w	opp.rear.right.y.speed,d0
	move.w	d0,opp.rear.right.y.speed

	move.b	#REDUCTION,d2
	beq	.label12
	muls	d2,d0
	asr.l	#8,d0
.label12
	asr.w	#1,d0
	add.w	d0,opp.rear.right.actual.height

****************************************

	move.w	opp.front.y.acceleration,d0
	move.b	#REDUCTION,d2
	beq	.label13
	muls	d2,d0
	asr.l	#8,d0
.label13
	add.w	opp.front.y.speed,d0
	move.w	d0,opp.front.y.speed

	move.b	#REDUCTION,d2
	beq	.label14
	muls	d2,d0
	asr.l	#8,d0
.label14
	asr.w	#1,d0
	add.w	d0,opp.front.actual.height

****************************************

	move.w	#296,max.difference
	move.b	#0,d1			rear left wheel
	move.b	#2,d2			rear right wheel
	jsr	limit.opponent.wheels

	move.w	#368,max.difference
	move.b	#0,d1			rear left wheel
	tst.w	d4
	bpl	.label15
	addq.b	#2,d1			rear right wheel instead (because this is higher than rear left)

.label15
	move.b	#4,d2			front wheel
	jsr	limit.opponent.wheels

	IFD	RECORD_OPPONENT_AWH
;	tst.b	recording
;	beq.s	.done3
	move.l	a0,-(sp)
	move.l	recording.ptr,a0
	;
	move.w	opp.rear.left.y.acceleration,(a0)+
	move.w	opp.rear.right.y.acceleration,(a0)+
	move.w	opp.front.y.acceleration,(a0)+
	;
	move.w	opp.rear.left.y.speed,(a0)+
	move.w	opp.rear.right.y.speed,(a0)+
	move.w	opp.front.y.speed,(a0)+
	;
	move.w	opp.rear.left.actual.height,(a0)+
	move.w	opp.rear.right.actual.height,(a0)+
	move.w	opp.front.actual.height,(a0)+
	;
	move.l	a0,recording.ptr
	move.l	(sp)+,a0
.done3
	ENDC

****************************************

* Calculate Y co-ordinate of opponents rear left wheel

R.641b6	move.w	opp.rear.left.actual.height,coord.visible.values+OppRearLeftWheelY
	addi.w	#80,coord.visible.values+OppRearLeftWheelY

* Calculate Y co-ordinate of opponents rear right wheel

	move.w	opp.rear.right.actual.height,coord.visible.values+OppRearRightWheelY
	addi.w	#80,coord.visible.values+OppRearRightWheelY

* Calculate Y co-ordinate of opponents front wheels

	move.w	opp.front.actual.height,coord.visible.values+OppFrontLeftWheelY
	addi.w	#80,coord.visible.values+OppFrontLeftWheelY

	move.w	coord.visible.values+OppRearRightWheelY,d0
	sub.w	coord.visible.values+OppRearLeftWheelY,d0
	asr.w	#1,d0
	move.w	coord.visible.values+OppFrontLeftWheelY,d3
	add.w	d0,d3
	move.w	d3,coord.visible.values+OppFrontRightWheelY

	move.w	coord.visible.values+OppFrontLeftWheelY,d3
	sub.w	d0,d3
	move.w	d3,coord.visible.values+OppFrontLeftWheelY
	rts


calculate.difference.between.opponent.wheels
	move.l	#opp.rear.left.actual.height,a0
	move.w	(a0,d1.w),d0
	sub.w	(a0,d2.w),d0
	move.w	d0,d4
	tst.w	d0
	bpl	.done
	neg.w	d0
.done	rts


* Adjusts opponent wheel heights and y speeds to limit car's x and z angle
* Especially important when in the air on more extreme tracks (e.g. Roller Coaster)
limit.opponent.wheels
	move.l	#opp.rear.left.y.speed,a4
	move.b	d1,height.adjust+1

	jsr	calculate.difference.between.opponent.wheels
* d4 = result, d0 = abs(result)

	move.w	max.difference,d3
	sub.w	d0,d3
	bpl	.heights.ok

	tst.w	d4
	bpl	.got.highest
	move.b	d2,d1

* d1 = index of highest wheel
.got.highest
	move.l	#opp.rear.left.actual.height,a0
	add.w	d3,(a0,d1.w)			drop highest wheel

	cmpi.b	#4,d2
	beq	.average.all.wheel.y.speeds

* Following is reached on first call to this subroutine

	move.b	#0,d1
	jmp	average.two.values			average rear wheel y speeds, then return

.average.all.wheel.y.speeds
	move.b	#0,d1
	move.b	#2,d2
	jsr	average.two.values			average rear wheel y speeds

	move.b	#4,d1
	jsr	average.two.values			average front and rear wheels y speeds (both rear wheel values are currently the same)

	move.b	#0,d1
	jsr	average.two.values			average rear wheels y speeds again

	move.b	#4,d2
	move.b	height.adjust+1,d1

.heights.ok
	cmpi.b	#4,d2
	bne	.done						finish if first call to this subroutine

* Following is reached on second call to this subroutine

	move.b	opp.touching.road,d0
	bne	.done

* Adjust wheel y speeds when opponent in air, possibly to make the car pitch forwards
	tst.b	road.height
	bmi	.continue			does nothing

.continue
	move.w	(a4,d1.w),d0
	sub.w	4(a4),d0
	bmi	.adjust

	cmpi.w	#16,d0
	bge	.done

.adjust	move.b	#4,d1
	move.l	#y.speed.adjustments,a0

.loop	move.w	(a0,d1.w),d0
	add.w	d0,(a4,d1.w)
	subq.b	#2,d1
	bpl	.loop
.done	rts


y.speed.adjustments
	dc.w	4,4,-4


average.two.values
	move.w	(a4,d1.w),d0
	add.w	(a4,d2.w),d0
	asr.w	#1,d0
	move.w	d0,(a4,d1.w)
	move.w	d0,(a4,d2.w)
	rts


****************************************


make.road.under.map
	move.b	#$ff,d0
	move.l	#road.under.map,a0
	move.w	#0,d1

.set	move.b	d0,(a0,d1.w)
	subq.b	#1,d1
	bne	.set

	move.l	#road.section.xz.positions,a1

.make	move.b	(a1,d1.w),d2
	move.b	d1,(a0,d2.w)
	addq.b	#1,d1
	cmp.b	number.of.road.sections,d1
	bne	.make
	rts


****************************************


next.char
	jsr	print.character
	addq.b	#1,d1
print.league.text
	move.l	#league.text,a1
	move.b	(a1,d1.w),d0
	cmpi.b	#$ff,d0
	bne	next.char
	rts


league.text
 dc.b	31,15,9,'DIVISION ',255
 dc.b	31,14,13,'RACE  ',255
 dc.b	31,6,11,'Track:  ',255
 dc.b	'The ',255
 dc.b	' V ',255
 dc.b	31,3,24,'Broken by QUARTEX   Hit fire to continue',255
 dc.b	31,15,21,'The ',255
 dc.b	31,17,15,'RESULT',255
 dc.b	'Race Winner: ',255
 dc.b	'Fastest Lap: ',255
 dc.b	31,14,11,'RESULTS TABLE',31,6,14,'DRIVER     RACED WIN LAP  PTS',255
 dc.b	'Promotion for  ',255
 dc.b	'Relegation for ',255
 dc.b	' CHANGES',255
 dc.b	31,18,14,'NAME?',255
 dc.b	' 2pts',255
 dc.b	' 1pt',255
 dc.b	' of ',255
 dc.b	0


****************************************


fade.screen.out
	move.w	d0,st.colours
	move.b	#30,fade.frame.count
	move.l	#st.colours,a0
	move.w	#30,d4

set.dest.colours
	move.w	(a0),32(a0,d4.w)
	subq.w	#2,d4
	bpl	set.dest.colours

fade.screen.in
	move.l	#st.colours,a0
	move.w	#30,d4
	move.b	#0,d7

fade1	move.b	32(a0,d4.w),d0
	andi.b	#$f,d0
	move.b	(a0,d4.w),d3
	andi.b	#$f,d3
	cmp.b	d3,d0
	beq	fade3
	bgt	fade2
	subq.b	#2,d3

fade2	addq.b	#1,d3
	addq.b	#1,d7

fade3	move.b	d3,(a0,d4.w)
	move.b	33(a0,d4.w),d0
	lsr.b	#4,d0
	move.b	1(a0,d4.w),d3
	lsr.b	#4,d3
	cmp.b	d3,d0
	beq	fade5
	bgt	fade4
	subq.b	#2,d3

fade4	addq.b	#1,d3
	addq.b	#1,d7

fade5	move.b	1(a0,d4.w),d0
	andi.b	#$f,d0
	asl.b	#4,d3
	or.b	d3,d0
	move.b	d0,1(a0,d4.w)
	move.b	33(a0,d4.w),d0
	andi.b	#$f,d0
	move.b	1(a0,d4.w),d3
	andi.b	#$f,d3
	cmp.b	d3,d0
	beq	fade7
	bgt	fade6
	subq.b	#2,d3

fade6	addq.b	#1,d3
	addq.b	#1,d7

fade7	move.b	1(a0,d4.w),d0
	andi.b	#$f0,d0
	or.b	d3,d0
	move.b	d0,1(a0,d4.w)
	subq.w	#2,d4
	bpl	fade1

	tst.b	d7
	beq	fade9

	jsr	set.amiga.colours
	move.b	#2,frame.count

fade8	tst.b	frame.count
	bne	fade8
	bra	fade.screen.in

fade9	tst.b	fade.frame.count
	bne	fade9
	rts


B.64530	dc.b	0,0


****************************************


show.title.screen
	move.w	title.colours,d0
	jsr	fade.screen.out

	move.b	#$80,second.screen
	move.l	screen.mem,d0
	move.l	d0,screen2
	addi.l	#32000,d0
	move.l	d0,screen1
	jsr	set.current.scene

	move.l	#title.colours,a1
	jsr	copy.st.dest.colours

	move.l	#title.crunched,a1	in st format
	move.l	screen.mem,a0
	move.l	a0,a3
	add.l	#8000,a3
	move.l	screen1,a4
st.to.amiga
	move.w	(a1),(a4)+
	move.w	(a1)+,(a0)+

	move.w	(a1),7998(a4)
	move.w	(a1)+,7998(a0)

	move.w	(a1),15998(a4)
	move.w	(a1)+,15998(a0)

	move.w	(a1),23998(a4)
	move.w	(a1)+,23998(a0)

	cmp.l	a3,a0
	bne	st.to.amiga

	move.b	#65,B.5d724
	jsr	R.645c6
	jsr	copy.screen.part
	jmp	fade.screen.in


R.645c6	move.b	B.1c9ce,d0
	move.b	d0,B.1bb5f
	jsr	clear.menu

	move.b	#15,d0
	jsr	set.text.masks

	tst.b	B.64530
	bne	.label1
	tst.b	B.5eb75
	beq	.label2
.label1	rts

.label2	tst.b	multi.no.of.players
	bne	.label5

	move.b	#9,d2
	move.b	league.offset,d0
	beq	.label3
	move.b	d2,TEXT.5a69a+189
	move.b	#187,d1
	jsr	R.5a656
	jmp	.label4

.label3	move.b	d2,league.text+2	set Y position

	move.b	#0,d1
	jsr	print.league.text	'DIVISION '

.label4	move.b	#4,d0
	sub.b	B.1bb5f,d0
	jsr	print.dec.digit2
	move.b	#1,d0
	jsr	set.text.masks
	rts

.label5	move.b	#160,d1
	jmp	R.5a67c


R.6465c	move.b	#$80,d0
	bra	R.64668

R.64664	move.b	#0,d0

R.64668	move.b	d0,B.1bbaa
	jsr	R.645c6
	move.b	B.1bb5f,d0
	asl.b	#1,d0
	move.b	d0,value
	move.b	B.1ca35,d0
	tst.b	multi.no.of.players
	beq	.label1
	move.b	B.5eb77,d0
	eori.b	#1,d0

.label1	andi.b	#1,d0
	add.b	value,d0
	move.b	d0,d1
	jsr	R.5bcf0
	btst	#0,B.1bbb1
	bne	.label2
	jmp	R.58e7a

.label2	move.b	#11,d2
	jsr	R.5eae0
	jsr	R.5f074
	jmp	R.64828


R.646d6	jsr	R.645c6
	jsr	R.64916
	jmp	R.64828


R.646e8	jsr	R.5ab00
	move.b	fp.y+1,B.1bbe8
	tst.b	multi.no.of.players
	beq	.label1

	jsr	R.5e93e
	bra	R.64828

.label1	jsr	R.645c6
	jmp	R.58f44


R.64718	move.b	#0,d0
	jsr	set.text.masks
	move.b	B.1bbe8,d2
	move.l	#DAT.1ca0e,a2
	move.b	(a2,d2.w),d1
	move.b	d1,edge.x1.offset
	jsr	print.opponents.name
	jsr	R.5ef38
	move.b	edge.x1.offset,d1
	tst.b	B.1bbcb
	bpl	.label1
	jsr	R.5ed40
	jsr	R.5ef2e
	addi.b	#12,d1
	jsr	R.5ed40
	bra	.label2

.label1	move.l	#DAT.1c9f6,a1
	move.b	(a1,d1.w),d0
	jsr	R.5edd2
	move.l	#DAT.1c9de,a1
	move.b	(a1,d1.w),d0
	jsr	R.5edba
	move.l	#DAT.1c9ea,a1
	move.b	(a1,d1.w),d0
	jsr	R.5edba
	jsr	R.5ef24
	move.l	#DAT.1ca02,a1
	move.b	(a1,d1.w),d0
	jsr	R.5edd2

.label2	addq.b	#1,B.1bbe8
	move.b	B.1bbe8,d0
	cmp.b	fp.y2+1,d0
	rts


R.647c8	move.b	#7,d0
	jsr	R.648d2

	move.b	#96,d1			'RESULT'
	jsr	print.league.text

	jsr	fill.bar

	move.b	#106,d1			'Race Winner: '
	jsr	print.league.text

	move.b	B.1ca25,d1
	jsr	print.opponents.name

	move.b	#233,d1			' 2pts'
	jsr	print.league.text

	jsr	fill.bar

	move.b	#120,d1			'Fastest Lap: '
	jsr	print.league.text

	move.b	B.1ca26,d1
	jsr	print.opponents.name

	move.b	#239,d1			' 1pt'
	jsr	print.league.text

R.64828	jsr	copy.screen.part
	jsr	wait.for.fire

clear.print.fine.y
	move.b	#0,print.fine.y
	rts


copy.screen.part
	move.l	screen.mem,a0
	add.l	#73*40+4,a0
	add.l	#-8*40,a0
	move.l	a0,a3
	add.l	#32000,a3
	move.w	#127-1,d4

.nextl	move.w	#14-1,d3

.nextw	move.w	(a0)+,(a3)+
	move.w	7998(a0),7998(a3)
	move.w	15998(a0),15998(a3)
	move.w	23998(a0),23998(a3)
	dbra	d3,.nextw

	add.l	#12,a0
	add.l	#12,a3
	dbra	d4,.nextl
	rts


****************************************


wait.for.fire
	jsr	get.players.input
	andi.b	#$10,d0
	bne	wait.for.fire

	move.b	#5,d2
	jsr	delay

wait.for.fire2
	jsr	get.players.input
	andi.b	#$10,d0
	beq	wait.for.fire2
	rts


****************************************


R.648b2	tst.b	multi.no.of.players
	bne	R.646e8
	jmp	R.58888


TAB.648c2
 dc.b	$00,$02,$01,$03,$06,$07,$04,$05,$08,$05,$0c,$05,$05,$08,$0c,$08


R.648d2	move.b	d0,B.1bb16
	jsr	R.5ab46
	jsr	fill.bar
	move.b	B.1ca27,d1
	jsr	print.opponents.name

	move.b	#40,d1			' V '
	jsr	print.league.text

	move.b	B.1ca28,d1
	jsr	print.opponents.name
	move.b	#1,d0
	jsr	set.text.masks
	jmp	clear.print.fine.y


R.64916	move.b	#$80,B.593f6
	move.b	#11,d1
	move.l	#DAT.1c9c2,a0
	move.l	#DAT.1ca0e,a1

.label1	move.b	(a1,d1.w),(a0,d1.w)
	subq.b	#1,d1
	bpl	.label1

	jsr	R.5ab00

	move.b	#15,d1
	move.b	#12,d2
	jsr	set.print.column.row

	move.b	#215,d1			' CHANGES'
	jsr	print.league.text

	move.b	#1,d0
	move.b	d0,B.1bb16
	move.b	fp.y+1,d2
	bne	.label2

	move.b	DAT.1ca0e,d0
	cmp.b	B.5eb79,d0
	bne	.label4
	move.b	league.offset,d0
	beq	.label2

	jsr	fill.bar
	move.b	#206,d1
	jsr	R.5a656
	jmp	.label5

.label2	jsr	fill.bar

	move.b	#183,d1			'Promotion for  '
	jsr	print.league.text

	move.b	fp.y+1,d2
	move.l	#DAT.1ca0e,a2
	move.b	(a2,d2.w),d1
	cmp.b	B.5eb79,d1
	bne	.label3
	move.b	d1,B.593f6

.label3	jsr	print.opponents.name
	move.b	fp.y+1,d2
	bne	.label4
	jsr	fill.bar
	move.b	#167,d1
	jsr	R.5a656
	jmp	.label5

.label4	move.b	fp.y2+1,d2
	subq.b	#1,d2
	cmpi.b	#11,d2
	beq	.label5
	jsr	fill.bar

	move.b	#199,d1			'Relegation for'
	jsr	print.league.text

	move.b	fp.y2+1,d2
	subq.b	#1,d2
	move.l	#DAT.1ca0e,a2
	move.b	(a2,d2.w),d1
	jsr	print.opponents.name

.label5	move.b	#2,d0
	move.b	d0,B.1bb5f

.label6	jsr	R.5ab00
	move.b	fp.y+1,d2
	move.l	#DAT.1c9c2,a0
	move.b	(a0,d2.w),d1
	move.b	-1(a0,d2.w),(a0,d2.w)
	move.b	d1,-1(a0,d2.w)
	subq.b	#1,B.1bb5f
	bpl	.label6

	move.b	B.5eb79,d0
	cmp.b	DAT.1ca0e,d0
	bne	.label8
	move.b	league.offset,d1
	bne	.labela
	move.b	d0,league.offset
	move.l	#DAT.1c9c2,a0
	move.b	#11,d1

.label7	move.b	d1,(a0,d1.w)
	subq.b	#1,d1
	bpl	.label7
	move.b	#0,d0
	bra	.label9

.label8	jsr	R.64ad2
	move.l	#TAB.64ac6,a1
	move.b	(a1,d1.w),d0

.label9	move.b	d0,B.1c9ce
	beq	.labela
	rts

.labela	move.b	#6,d0
	asl.b	#1,d0
	subq.b	#2,d0
	move.b	d0,damage.hole.position
	rts


TAB.64ac6
	dc.b	$03,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00


R.64ad2	move.b	#11,d1

.label1	move.l	#DAT.1c9c2,a1
	cmp.b	(a1,d1.w),d0
	beq	.label2

	subq.b	#1,d1
	bpl	.label1

.label2	rts


special.long	dc.l	$9cedcd02


L.64af0	dc.l	$80060400


menu.bar.positions
	dc.b	13,16,19,22
	dc.b	16,19
	dc.b	16
	dc.b	15,20,23
	dc.b	10,14,18,22
	dc.b	14
	dc.b	11,17
	dc.b	12


R.64b06	move.b	#3,B.64c18

fill.bar
	move.b	#2,d0

R.64b12	subq.b	#2,d0
	move.b	d0,B.1bc54

	move.b	#31,d0
	jsr	print.character
	move.b	#5,d0			column
	jsr	print.character
	move.b	B.1bb16,d1
	move.l	#menu.bar.positions,a0
	move.b	(a0,d1.w),d0
	move.b	d0,B.1bb5e		row
	jsr	print.character

	clr.w	d4
	move.b	B.64c18,d4
	asl.w	#2,d4
	move.l	#title.crunched,a0
	sub.l	#32*40,a0
	move.l	#TAB.64c1a,a1
	add.l	(a1,d4.w),a0
	move.l	screen2,a3
	add.l	#-8*40,a3
	move.w	#40,d3
	andi.w	#$ff,d0
	mulu	d3,d0
	asl.l	#3,d0
	subi.l	#40,d0
	add.l	d0,a3
	add.l	#4,a3
	move.l	a0,a2
	add.l	#160,a2
	move.l	a3,a4
	add.l	#40,a4
	move.w	#17-1,d4
	cmpi.b	#3,B.64c18
	bne	.nextl
	move.w	#25-1,d4

.nextl	move.w	#14-1,d3

.nextw	move.w	(a0)+,(a3)+
	move.w	(a0)+,7998(a3)
	move.w	(a0)+,15998(a3)
	move.w	(a0)+,23998(a3)
	dbra	d3,.nextw

	add.l	#48,a0
	add.l	#12,a3
	dbra	d4,.nextl

	subq.b	#1,B.1bc54
	bmi	.done

	move.l	a2,a0
	add.l	#8*40,a4
	move.l	a4,a3
	move.w	#16-1,d4
	bra	.nextl

.done	move.b	#2,B.64c18

	move.b	#0,d0
	jsr	set.text.masks
	addq.b	#1,B.1bb16

four.print.fine.y
	move.b	#4,print.fine.y
	rts


B.64c18	dc.b	2,0


TAB.64c1a
	dc.l	$4070,$4f70,$5e70,$6d70,$3170


print.opponents.name
	move.l	#opponents.names,a0
	move.b	#13,d2
	jmp	print.name

print.track.name
	move.l	#track.names,a0
	move.b	#15,d2

print.name
	move.b	d2,value
	asl.b	#4,d1
	move.b	#0,d2

.loop	move.b	(a0,d1.w),d0
	jsr	print.character
	addq.b	#1,d1
	addq.b	#1,d2
	cmp.b	value,d2
	bne	.loop
	rts


clear.menu
	move.b	#1,d0
	jsr	set.text.masks
	move.b	#3,d0
	jsr	set.bground.masks

	move.b	#$80,or.with.screen
	move.l	screen2,a0
	add.l	#-8*40,a0
	add.l	#73*40+4,a0
	move.l	a0,a3
	add.l	#127*40,a3

	move.b	#3,d0
	jsr	make.masks
	move.w	d6,d1
	swap	d6
	move.w	d7,d2
	swap	d7
	move.w	#2-1,d4

.nextl	add.l	#4,a0
	move.w	#12-1,d3

.nextw	move.w	d6,(a0)+
	move.w	d1,7998(a0)
	move.w	d7,15998(a0)
	move.w	d2,23998(a0)
	dbra	d3,.nextw

	add.l	#12,a0
	dbra	d4,.nextl

.nextl2	move.w	#14-1,d3

.nextw2	move.w	d6,(a0)+
	move.w	d1,7998(a0)
	move.w	d7,15998(a0)
	move.w	d2,23998(a0)
	dbra	d3,.nextw2

	add.l	#12,a0
	cmp.l	a3,a0
	blt	.nextl2

	clr.w	d1
	clr.w	d2
	rts


****************************************


get.sin	move.w	#0,d5
	bra	get.sin.cos
get.cos	move.w	#$4000,d5
get.sin.cos
	move.l	#sin.table,a0
	move.w	d0,d3
	andi.w	#$3fff,d3
	move.w	d0,d6
	andi.w	#$4000,d6
	eor.w	d5,d6
	bne	gsc1
	eori.w	#$3fff,d3
	addq.w	#1,d3
gsc1	ror.w	#5,d3
	move.w	d3,d4
	andi.w	#$3fe,d4
	move.w	(a0,d4.w),d6
	sub.w	2(a0,d4.w),d6
	ror.w	#1,d3
	andi.w	#$fc00,d3
	mulu	d3,d6
	swap	d6
	move.w	(a0,d4.w),d7
	sub.w	d6,d7
	lsr.w	#1,d7
	move.w	d0,d3
	and.w	d5,d3
	asl.w	#1,d3
	eor.w	d3,d0
	bpl	gsc2
	neg.w	d7
gsc2	move.w	d7,d0
	rts


****************************************


calculate.perspective.coord
	move.l	#perspective.table,a0
	move.w	d0,d4
	bpl	cpc1
	neg.w	d0

cpc1	move.w	d3,d5
	bpl	cpc2
	neg.w	d3

cpc2	cmp.w	d0,d3
	bne	cpc3

	move.w	#$ffff,d7
	move.w	#$2000,d0
	bra	cpc7

cpc3	bgt	cpc6

	swap	d3
	clr.w	d3
	divu	d0,d3
	move.w	d3,d7
	lsr.w	#4,d3
	andi.b	#$fe,d3
	move.w	(a0,d3.w),d0
	move.w	d4,d3
	eor.w	d5,d3
	bmi	cpc4
	neg.w	d0

cpc4	move.w	#$4000,d3
	tst.w	d4
	bpl	cpc5
	move.w	#$c000,d3

cpc5	add.w	d3,d0
	rts

cpc6	swap	d0
	clr.w	d0
	divu	d3,d0
	move.w	d0,d7
	lsr.w	#4,d0
	andi.b	#$fe,d0
	move.w	(a0,d0.w),d0

cpc7	move.w	d4,d3
	eor.w	d5,d3
	bpl	cpc8
	neg.w	d0

cpc8	tst.w	d5
	bpl	cpc9
	addi.w	#$8000,d0
cpc9	rts


****************************************


calculate.perspective.value
	move.l	#perspective.table2,a0
	tst.w	d4
	bpl	cpv1
	neg.w	d4

cpv1	tst.w	d5
	bpl	cpv2
	neg.w	d5

cpv2	cmp.w	d4,d5
	bge	cpv3
	exg	d4,d5

cpv3	lsr.w	#4,d7
	andi.b	#$fe,d7
	move.w	(a0,d7.w),d0
	mulu	d4,d0
	swap	d0
	add.w	d5,d0
	rts


****************************************


draw.world.initialisation
	jsr	set.road.position.values

	move.b	#0,d0
	move.b	d0,dont.copy.coords
	move.b	d0,B.1bb5c
	move.b	d0,pits.are.black
	move.w	#-1,opponents.offset
	move.b	#0,B.1bbba

	jsr	initialise.edges
	rts


****************************************


draw.world
	jsr	draw.world.initialisation

	move.b	#0,d0
	move.b	d0,map.x.shift
	move.b	d0,map.z.shift

	jsr	get.valid.map.number
	bcs	off.map

	cmpi.b	#-1,d0
	bne	on.road

* If map square is empty

	move.b	players.fine.map.x,d0
	move.b	players.fine.map.z,d2
	jsr	to.closest.adjacent.map.square

	cmpi.b	#-1,d0
	bne	on.road

off.map	move.b	#$c0,off.map.status
	tst.b	machine
	beq	dw2
	jsr	R.571ce

dw2	tst.b	race.mode
	bpl	no.opponent4

	jsr	opponent.movement
	jsr	calculate.opponents.road.wheel.positions

no.opponent4
	move.b	B.1bb9f,players.distance.into.section.plus64
	move.w	W.1bc28,near.sections.done2
	move.b	B.1bb9e,near.sections.done
	bra	no.opponent5

	jsr	R.1b818
	jsr	draw.horizon
	jsr	draw.mountains
	jmp	dwca

on.road	move.b	d0,current.road.section

	jsr	calculate.players.road.position
	jsr	set.road.centre.values

	move.b	current.road.section,d0
	move.b	d0,players.road.section

	btst	#6,off.map.status
	bne	dw5
	move.b	d0,B.1bb9b

dw5	jsr	detail.near.road
	move.b	players.distance.into.section.plus64,B.1bb9f
	move.w	near.sections.done2,W.1bc28
	move.b	near.sections.done,B.1bb9e
	tst.b	machine
	beq	dw6

	jsr	R.571ce
	bra	no.opponent5

dw6	tst.b	race.mode
	bpl	no.opponent5

	jsr	opponent.movement
	jsr	calculate.distances.between.players
	jsr	opponent.player.interaction
	jsr	calculate.opponents.road.wheel.positions

no.opponent5
	move.b	#$80,d0
	move.b	d0,edge.x2.offset
	move.b	d0,B.1bc16
	move.b	players.road.section,current.road.section
	move.b	#0,coord.offset.zero.or.four

	move.b	players.distance.into.section.plus64,d0
	bpl	dw8
	jsr	to.next.road.section
	move.b	#0,players.distance.into.section.plus64

dw8	tst.b	players.distance.into.section.plus64
	bne	dwa

	jsr	to.previous.road.section
	cmp.b	opponents.road.section.m255,d1
	bne	dw9
	move.w	#0,opponents.offset

dw9	jsr	to.next.road.section

dwa	jsr	make.near.road.coords
	jsr	make.optional.side.edges
	jsr	make.optional.top.edges
	jsr	make.near.road.edges
	move.b	#0,coord.pair.to.start.at
	move.b	#0,offset.for.coord.pair.to.start.at
	move.b	#4,coord.offset.zero.or.four
	jsr	copy.coords.for.next.section
	jsr	to.next.road.section

	jsr	make.near.road.coords
	jsr	make.optional.side.edges
	jsr	make.near.road.edges2
	jsr	copy.coords.for.next.section
	move.b	#1,pits.are.black
	jsr	to.next.road.section

	jsr	make.near.road.coords
	jsr	make.optional.side.edges
	jsr	make.near.road.edges2
	jsr	copy.coords.for.next.section
	jsr	to.next.road.section

	move.w	road.section.offset,far.road.limit
	move.w	x.values+240,old.left.x
	move.w	x.values+242,old.right.x
	jsr	make.far.road.coords
	jsr	make.far.road.edges

	tst.b	race.mode
	bmi	dwb
	move.w	#-1,opponents.offset

dwb	tst.b	machine
	beq	dwc
	jsr	R.57440

dwc	move.w	road.section.offset,-(sp)
	jsr	draw.horizon
	jsr	draw.mountains
	move.w	(sp)+,road.section.offset

	jsr	set.opponent.draw.flag
	jsr	draw.far.road

	move.w	far.road.limit,road.section.offset
	jsr	draw.near.road

dwca	tst.b	car.on.chains.countdown
	bne	dwd

	tst.b	off.map.status
	bpl	dwd

	jsr	draw.dust.clouds

dwd	jsr	draw.sparks

	jsr	draw.chains

	move.b	#13,d0			left top corner
	jsr	copy.graphic

	move.b	#14,d0			right top corner
	jsr	copy.graphic

	jsr	update.wheel.positions
	move.b	wheel.frame.number,d0	right wheel
	jsr	copy.graphic

	move.b	#5,d0
	sub.b	wheel.frame.number,d0	left wheel
	jsr	copy.graphic

	move.b	#10,d0			engine block
	jsr	copy.graphic

	move.b	#11,d0			left exhaust covering wheel
	jsr	copy.graphic

	move.b	#12,d0			right exhaust covering wheel
	jsr	copy.graphic

	tst.b	boost.activated
	beq	dw11

	move.b	B.1bb69,d0
	addq.b	#1,d0
	cmpi.b	#3,d0
	blt	dwe
	move.b	#0,d0
dwe	move.b	d0,B.1bb69

	move.w	d0,-(sp)
	addi.b	#6,d0
	cmpi.b	#8,d0
	bne	dwf
	move.b	#49,d0			left flames
dwf	jsr	copy.graphic

	move.w	(sp)+,d0
	addi.b	#8,d0
	cmpi.b	#10,d0
	bne	dw10
	move.b	#50,d0			right flames
dw10	jsr	copy.graphic

dw11	jsr	race.prompts
	rts


****************************************


update.wheel.rotation
	move.b	wheel.rotation.speed,d0
	add.b	d0,wheel.frame.count
	bcc	uwr1
	jsr	set.wheel.frame.number

uwr1	move.b	wheel.frame.number,d0
	addi.b	#37,d0
	cmpi.w	#126,graphic.info+10
	bge	uwr2
	addi.b	#6,d0			use larger hardware sprites
uwr2	move.w	#0,d1
	jsr	set.sprite.pointers

	move.b	#5,d0
	sub.b	wheel.frame.number,d0
	addi.b	#37,d0
	cmpi.w	#126,graphic.info+3*16+10
	bge	uwr3
	addi.b	#6,d0			use larger hardware sprites
uwr3	move.w	#1,d1
	jsr	set.sprite.pointers
	rts


****************************************


make.near.road.coords
	move.l	#coord.visible.values,a6
	move.b	current.road.section,d1
	jsr	fetch.near.section.stuff

	move.b	current.road.section,d0
	jsr	fetch.xz.position

	move.b	rough.player.angle,d0
	sub.b	rough.piece.angle,d0
	move.b	d0,rough.difference.angle

	jsr	make.near.top.y.coords
	move.b	offset.for.coord.pair.to.start.at,d1
	beq	no.previous.y

	move.l	#coord.visible.values-4,a0
	move.w	(a0,d1.w),previous.left.top.y
	move.w	2(a0,d1.w),previous.right.top.y

no.previous.y
	tst.b	B.5d724
	bmi	mnrc4

	move.b	rough.difference.angle,d0
	move.b	plus.180.degrees,d3
	eor.b	d3,d0
	tst.b	B.1bb93
	bpl	mnrc1

	tst.b	near.section.byte1
	bmi	mnrc2

	btst	#6,near.section.byte1
	beq	mnrc2

mnrc1	tst.b	curve.to.left
	bpl	mnrc3

mnrc2	addi.b	#$40,d0

mnrc3	move.b	#0,B.1bbad
	bpl	mnrc4

******** Not used ********

	move.b	d0,dont.copy.coords
	move.b	#0,coord.offset.zero.or.four
	jsr	unused.sub1

	move.b	other.road.line.colour,d0
	add.b	number.of.coords.minus2,d0
	andi.b	#2,d0
	move.b	d0,other.road.line.colour

	tst.b	plus.180.degrees
	bne	start.with.first.coords2
	jmp	start.with.last.coords2

****************************************

mnrc4	tst.b	plus.180.degrees
	beq	start.with.first.coords2
	jmp	start.with.last.coords2

start.with.first.coords2
	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a0
	move.b	(a0),d0
	addq.b	#7,d0
	move.b	d0,piece.coords.offset

	move.b	coord.offset.zero.or.four,d1
	move.l	#coord.visible.values,a6

mnrc5	tst.w	(a6,d1.w)
	bmi	mnrc9

	move.w	#$8000,120(a6,d1.w)	if bottom co-ord not visible
	cmp.b	offset.for.coord.pair.to.start.at,d1
	bge	mnrc6

	move.w	#$8000,(a6,d1.w)	top visible value
	jmp	mnrc9

mnrc6	move.w	d1,d2
	asl.w	#1,d2
	add.b	piece.coords.offset,d2
	jsr	fetch.near.xz.coords
	jsr	calculate.screen.x	calculate top x co-ord
	jsr	calculate.screen.y	calculate top y co-ord
	btst	#6,off.map.status
	beq	mnrc7

	jsr	check.x.coord.magnitude
	bcs	mnrc8			if too large

mnrc7	jsr	make.near.bottom.coords

mnrc8	move.b	d1,d2
	andi.b	#2,d2
	move.l	#edge.x2.offset,a2
	move.b	d1,(a2,d2.w)

mnrc9	addq.b	#2,d1
	cmp.b	offset.for.after.last.coord,d1
	bne	mnrc5
	jmp	save.last.x.coords

start.with.last.coords2
	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a0
	move.b	(a0),d0
	addq.b	#7,d0
	move.b	number.of.coords,d3
	subq.b	#1,d3
	asl.b	#2,d3
	add.b	d3,d0
	move.b	d0,piece.coords.offset

	move.b	coord.offset.zero.or.four,d1
	move.l	#coord.visible.values,a6

mnrca	tst.w	(a6,d1.w)
	bmi	mnrce

	move.w	#$8000,120(a6,d1.w)	if bottom co-ord not visible
	cmp.b	offset.for.coord.pair.to.start.at,d1
	bge	mnrcb

	move.w	#$8000,(a6,d1.w)	top visible value
	jmp	mnrce

mnrcb	move.b	d1,d3
	asl.b	#1,d3
	move.b	piece.coords.offset,d2
	sub.b	d3,d2
	jsr	fetch.near.xz.coords
	jsr	calculate.screen.x	calculate top x co-ord
	jsr	calculate.screen.y	calculate top y co-ord
	btst	#6,off.map.status
	beq	mnrcc

	jsr	check.x.coord.magnitude
	bcs	mnrcd			if too large

mnrcc	jsr	make.near.bottom.coords

mnrcd	move.b	d1,d2
	andi.b	#2,d2
	move.l	#edge.x2.offset,a2
	move.b	d1,(a2,d2.w)

mnrce	addq.b	#2,d1
	cmp.b	offset.for.after.last.coord,d1
	bne	mnrca

save.last.x.coords
	move.l	#x.values,a1
	move.b	edge.x2.offset,d1
	move.w	(a1,d1.w),x.values+240

	move.b	B.1bc16,d1
	move.w	(a1,d1.w),x.values+242

	move.b	coord.offset.zero.or.four,d1

rotate.top.coords
	tst.w	(a6,d1.w)
	bmi	mnrcf
	jsr	z.rotate

mnrcf	addq.b	#2,d1
	cmp.b	offset.for.after.last.coord,d1
	bne	rotate.top.coords

	move.b	edge.x2.offset,offset.for.last.two.coords2
	rts


offset.for.last.two.coords2	dc.b	0,0


****************************************


make.near.bottom.coords
	move.l	#x.values,a4
	move.l	#y.values,a5
	move.b	d1,d2
	andi.b	#2,d2
	move.l	#edge.x2.offset,a2
	move.b	(a2,d2.w),d2
	bpl	mnbc1

	tst.b	unused.flag
	bmi	mnbc4

	move.b	clip.flag,d0
	beq	mnbc5

	eor.b	d1,d0
	andi.b	#2,d0
	beq	mnbc4
	bra	mnbc5

mnbc1	cmpi.b	#4,d2
	bge	mnbc2

	tst.b	unused.flag
	bmi	mnbc2
	addi.b	#$f0,d2

mnbc2	move.b	d1,d0
	andi.b	#2,d0
	bne	mnbc3

	move.w	(a4,d2.w),d0
	sub.w	(a4,d1.w),d0
	bmi	mnbc5
	jmp	mnbc4

mnbc3	move.w	(a4,d1.w),d0
	sub.w	(a4,d2.w),d0
	bmi	mnbc5

mnbc4	move.w	#512,120(a6,d1.w)	bottom visible value
	move.w	(a4,d1.w),120(a4,d1.w)	bottom x value
	addi.b	#120,d1
	jsr	calculate.screen.y	calculate bottom y co-ord
	jsr	z.rotate0		rotate bottom co-ord
	subi.b	#120,d1
mnbc5	rts


****************************************


copy.coords.for.next.section
	move.l	#x.values,a4
	move.l	#y.values,a5
	move.b	offset.for.after.last.coord,d1
	move.b	offset.for.last.two.coords2,d0
	bmi	ccfns1

	addq.b	#4,d0
	move.b	d0,d1

ccfns1	tst.b	dont.copy.coords
	bmi	ccfns3
	move.b	#2,d2

ccfns2	subq.b	#2,d1
	move.w	(a4,d1.w),(a4,d2.w)
	move.w	(a5,d1.w),(a5,d2.w)
	move.w	(a6,d1.w),(a6,d2.w)

	move.w	120(a4,d1.w),120(a4,d2.w)
	move.w	120(a5,d1.w),120(a5,d2.w)
	move.w	120(a6,d1.w),120(a6,d2.w)

	subq.b	#2,d2
	bpl	ccfns2

	move.b	#0,edge.x2.offset
	move.b	#2,d0
	move.b	d0,B.1bc16
	cmpi.w	#256,(a4,d1.w)
	rts

ccfns3	move.b	#0,coord.offset.zero.or.four	not used
	subq.b	#4,d1
	cmpi.w	#256,(a4,d1.w)
	rts


****************************************


make.optional.side.edges
	clr.w	d0
	move.b	current.road.section,d0
	move.l	#far.section.ptrs,a0
	asl.w	#2,d0
	move.l	(a0,d0.w),a0
	move.w	(a0),current.far.section.flag
	move.l	#near.section.flags,a3
	move.l	#coord.visible.values,a6
	move.b	offset.for.after.last.coord,d1
	jsr	mose0
	move.b	offset.for.after.last.coord,d1
	addq.b	#2,d1

mose0	subq.b	#4,d1
	tst.w	(a6,d1.w)
	bmi	mose3

	tst.w	120(a6,d1.w)
	bpl	mose5

	move.b	d1,d0
	bclr	#1,d0
	cmp.b	offset.for.coord.pair.to.start.at,d0
	beq	mose2

	btst	#1,d1
	bne	mose1

	btst	#7,current.far.section.flag
	bne	mose6
	bra	mose3

mose1	btst	#6,current.far.section.flag
	bne	mose6
	bra	mose3

mose2	tst.b	clip.flag
	beq	mose3

	move.w	players.x.offset.from.road.centre,d0
	rol.w	#2,d0
	eor.b	d1,d0
	andi.b	#2,d0
	beq	mose3
	bra	mose6

mose3	subq.b	#4,d1
	bmi	mose8

mose4	tst.w	(a6,d1.w)
	bmi	mose3

	tst.w	120(a6,d1.w)
	bmi	mose3

	move.w	d1,d3
	bclr	#1,d3
	ori.b	#$40,(a3,d3.w)

mose5	subq.b	#4,d1
	bmi	mose8

	tst.w	(a6,d1.w)
	bmi	mose5

	tst.w	120(a6,d1.w)
	bpl	mose5

	cmp.b	offset.for.coord.pair.to.start.at,d1
	blt	mose8

mose6	jsr	make.optional.side.coords

	move.w	d1,d3
	bclr	#1,d3
	ori.b	#$40,(a3,d3.w)
	subq.b	#4,d1
	bpl	mose4

	addq.b	#4,d1
	move.w	road.section.offset,d3
	cmpi.w	#32,d3
	beq	mose8

	move.w	d3,-(sp)
	subi.w	#16,d3
	tst.w	d1
	beq	mose7
	addq.w	#4,d3

mose7	move.w	d3,road.section.offset
	move.w	d1,d2
	addi.b	#120,d1
	jsr	clip.line.make.edge
	move.w	(sp)+,road.section.offset
mose8	rts


****************************************


make.optional.side.coords
	movem.l	d1-d7/a3-a6,-(sp)

	move.b	d1,edge.x1.offset
	move.w	#512,120(a6,d1.w)	bottom visible value
	move.w	d1,d0
	lsr.w	#2,d0
	jsr	fetch.segment.xz.coords

	move.b	edge.x1.offset,d1
	move.w	d1,d2
	andi.w	#2,d2
	addi.b	#120,d1
	jsr	make.optional.screen.coord

	movem.l	(sp)+,d1-d7/a3-a6
	rts


****************************************


make.near.top.y.coords
	move.w	left.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a4			address of left y co-ords

	move.w	right.y.coord.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a5			address of right y co-ords

	move.l	#near.section.flags,a3
	move.w	#46,d7
	sub.w	near.sections.done2,d7
	bpl	mntyc1
	move.b	#0,d7

mntyc1	clr.w	d0
	move.b	number.of.segments,d0
	add.w	d0,near.sections.done2

	move.b	#0,d0
	move.b	number.of.coords.minus2,d1
	asl.w	#1,d1
	move.b	current.road.section,d2
	cmp.b	near.start.line.section,d2
	bne	mntyc2
	move.b	#1,d0
mntyc2	move.b	d0,(a3,d1.w)		set start line flag

	move.b	#0,d2
	move.b	coord.offset.zero.or.four,d1
	bne	mntyc3

* For nearest section

	move.b	d2,current.y.coord	start with first co-ord

	tst.b	y.coords.stored.as.words
	bpl	y.coords.are.bytes

	move.b	current.y.coord,d2
	asl.b	#1,d2
	move.b	(a4,d2.w),d0
	bpl	make.top.y.coords2
	bra	remove.white.line2

y.coords.are.bytes
	move.b	(a4,d2.w),d0
	bmi	remove.white.line
	bra	make.top.y.coords

* For other near sections

mntyc3	move.b	#1,d2
	move.b	d2,current.y.coord	start with second co-ord

	tst.b	y.coords.stored.as.words
	bmi	save.next.two.y.coords2

save.next.two.y.coords
	move.b	(a4,d2.w),d0
	bmi	remove.white.line

	cmp.b	d7,d2
	bcs	make.top.y.coords

	move.w	#$8000,(a6,d1.w)	if top co-ords not visible
	move.w	#$8000,2(a6,d1.w)
	jmp	next.two.y.coords

remove.white.line
	move.b	#0,(a3,d1.w)

make.top.y.coords
	move.b	(a4,d2.w),d0		get current left y co-ord
	move.b	d0,d3
	asl.b	#1,d0
	andi.w	#$e0,d0
	andi.b	#$f,d3
	asl.w	#8,d3
	or.w	d3,d0
	add.w	overall.left.y.shift,d0
	move.w	d0,(a6,d1.w)		save left y co-ord

	tst.b	(a3,d1.w)
	bmi	save.right.y.coord

	move.w	-4(a6,d1.w),d3
	bpl	previous.left.y.positive

	tst.b	pits.are.black
	beq	save.right.y.coord

	cmpi.b	#4,d1
	blt	save.right.y.coord

	move.w	d0,-(sp)
	subq.b	#1,d2
	move.b	(a4,d2.w),d0		get previous left y co-ord
	move.b	d0,d3
	asl.b	#1,d0
	andi.w	#$e0,d0
	andi.b	#$f,d3
	asl.w	#8,d3
	or.w	d3,d0
	add.w	overall.left.y.shift,d0
	addq.b	#1,d2
	move.w	d0,d3
	move.w	(sp)+,d0

previous.left.y.positive
	sub.w	d3,d0			current y - previous y
	bpl	y.change.positive
	neg.w	d0

y.change.positive
	cmpi.w	#640,d0
	blt	save.right.y.coord	if y change isn't big enough

	cmpi.b	#4,d1
	blt	save.right.y.coord
	ori.b	#$20,(a3,d1.w)		store pit flag

save.right.y.coord
	move.b	(a5,d2.w),d0		get current right y co-ord
	move.b	d0,d3
	asl.b	#1,d0
	andi.w	#$e0,d0
	andi.b	#$f,d3
	asl.w	#8,d3
	or.w	d3,d0
	add.w	overall.right.y.shift,d0
	move.w	d0,2(a6,d1.w)		save right y co-ord

next.two.y.coords
	addq.b	#1,d2
	addq.b	#4,d1
	cmp.b	offset.for.last.two.coords,d1
	blt	save.next.two.y.coords

	beq	make.top.y.coords
	bra	mntyc4

save.next.two.y.coords2
	move.b	current.y.coord,d2
	asl.b	#1,d2
	tst.b	(a4,d2.w)
	bmi	remove.white.line2

	move.b	current.y.coord,d0
	cmp.b	d7,d0
	bcs	make.top.y.coords2

	move.w	#$8000,(a6,d1.w)
	move.w	#$8000,2(a6,d1.w)
	jmp	next.two.y.coords2

* Y co-ords are words

remove.white.line2
	move.b	#0,(a3,d1.w)

make.top.y.coords2
	move.b	1(a4,d2.w),d3		get current left y co-ord
	move.b	(a4,d2.w),d0
	andi.b	#$7f,d0
	asl.w	#8,d0
	or.b	d3,d0
	add.w	overall.left.y.shift,d0
	move.w	d0,(a6,d1.w)		save left y co-ord

	tst.b	(a3,d1.w)
	bmi	save.right.y.coord2

	move.w	-4(a6,d1.w),d3
	bpl	previous.left.y.positive2

	tst.b	pits.are.black
	beq	save.right.y.coord2

	cmpi.b	#4,d1
	blt	save.right.y.coord2

	move.w	d0,-(sp)
	subq.b	#2,d2
	move.b	1(a4,d2.w),d3		get previous left y co-ord
	move.b	(a4,d2.w),d0
	andi.b	#$7f,d0
	asl.w	#8,d0
	or.b	d3,d0
	add.w	overall.left.y.shift,d0
	addq.b	#2,d2
	move.w	d0,d3
	move.w	(sp)+,d0

previous.left.y.positive2
	sub.w	d3,d0			current y - previous y
	bpl	y.change.positive2
	neg.w	d0

y.change.positive2
	cmpi.w	#640,d0
	blt	save.right.y.coord2	if y change isn't big enough

	cmpi.b	#4,d1
	blt	save.right.y.coord2
	ori.b	#$20,(a3,d1.w)		store pit flag

save.right.y.coord2
	move.b	1(a5,d2.w),d3		get current right y co-ord
	move.b	(a5,d2.w),d0
	andi.b	#$7f,d0
	asl.w	#8,d0
	or.b	d3,d0
	add.w	overall.right.y.shift,d0
	move.w	d0,2(a6,d1.w)		save right y co-ord

next.two.y.coords2
	addq.b	#1,current.y.coord
	addq.b	#4,d1
	cmp.b	offset.for.last.two.coords,d1
	blt	save.next.two.y.coords2

	bne	mntyc5
	move.b	current.y.coord,d2
	asl.b	#1,d2
	jmp	make.top.y.coords2

mntyc4	subq.b	#1,d2

mntyc5	move.b	(a4,d2.w),d0
	bpl	mntyc6

	move.b	#$80,-4(a3,d1.w)
	move.b	number.of.segments,d2
	cmp.b	d7,d2
	bcs	mntyc6

	move.w	#$8000,-4(a6,d1.w)
	move.w	#$8000,-2(a6,d1.w)
mntyc6	rts


****************************************


make.optional.top.edges
	move.b	offset.for.coord.pair.to.start.at,d1
	bne	motes1
	rts

motes1	move.w	#8,d3
	jsr	make.optional.top.edge

	move.b	offset.for.coord.pair.to.start.at,d1
	addq.b	#2,d1
	move.w	#9,d3
	jsr	make.optional.top.edge

	move.b	offset.for.coord.pair.to.start.at,d1
	addi.b	#120,d1
	move.w	#10,d3
	jsr	make.optional.top.edge

	move.b	offset.for.coord.pair.to.start.at,d1
	addi.b	#122,d1
	move.w	#11,d3
	jsr	make.optional.top.edge

	move.w	#32,road.section.offset
	rts


****************************************


make.optional.top.edge
	asl.w	#2,d3
	move.w	d3,road.section.offset

	move.l	#x.values,a4
	move.l	#y.values,a5
	move.b	d1,edge.x1.offset
	cmpi.w	#120,d1
	blt	mote1

	tst.w	(a6,d1.w)
	bmi	mote2

mote1	move.w	(a4,d1.w),d0
	cmpi.w	#256,d0
	bcc	mote2

	move.w	(a5,d1.w),d0
	cmpi.w	#128,d0
	bcc	mote2

	jsr	make.optional.top.coord
	move.b	edge.x1.offset,d1
	move.w	d1,d2
	subq.b	#4,d2
	jsr	clip.line.make.edge
	rts

mote2	move.l	#section.data,a1
	move.w	road.section.offset,d3
	move.l	#$80000000,(a1,d3.w)
	rts


****************************************


make.optional.top.coord
	move.b	d1,edge.x1.offset
	move.b	d1,d0
	andi.b	#2,d0
	move.b	d0,B.1bbe8

	move.b	d0,d2
	cmpi.w	#120,d1
	blt	motc1

	move.w	#512,-4(a6,d1.w)
	bra	motc2

motc1	move.l	#previous.left.top.y,a2
	move.w	(a2,d2.w),-4(a6,d1.w)

motc2	move.b	players.distance.into.section.plus64,d0
	jsr	fetch.segment.xz.coords

	move.b	B.1bbe8,d1
	move.b	#8,d2
	move.b	players.distance.into.section.plus64+1,d0
	andi.w	#$ff,d0
	jsr	calculate.segment.xz

	move.b	edge.x1.offset,d1
	cmpi.w	#120,d1
	bge	motc3

	move.b	#0,d0
	move.b	players.distance.into.section.plus64+1,factor1
	move.w	(a6,d1.w),d0
	sub.w	-4(a6,d1.w),d0
	move.b	factor1,d3
	asl.w	#7,d3
	bclr	#15,d3
	muls	d3,d0
	asl.l	#1,d0
	swap	d0
	add.w	d0,-4(a6,d1.w)

motc3	subq.b	#4,d1
	move.b	#8,d2
	jsr	make.optional.screen.coord

	move.l	#x.values,a4
	move.l	#y.values,a5
	move.w	(a4,d1.w),d4
	move.w	(a5,d1.w),d5
	move.w	d4,d0
	cmpi.w	#256,d0
	bcc	motc6

	move.w	d5,d0
	cmpi.w	#128,d0
	bcc	motc6

	move.w	d4,d6
	sub.w	4(a4,d1.w),d6
	move.w	d5,d7
	sub.w	4(a5,d1.w),d7
	bne	motc5

	tst.w	d6
	bne	motc5

	move.w	#1,d7
	bra	motc5

motc4	move.w	d4,d0
	cmpi.w	#256,d0
	bcc	motc6

	move.w	d5,d0
	cmpi.w	#128,d0
	bcc	motc6

motc5	add.w	d6,d4
	add.w	d7,d5
	bra	motc4

motc6	move.w	d4,(a4,d1.w)
	move.w	d5,(a5,d1.w)
	rts


****************************************


set.road.data2
	jsr	srd2.sub1

	move.l	#far.section.coordinates,end.far.sections.ptr
	move.b	#0,coord.offset.zero.or.four
	move.l	#coord.visible.values,a6
	move.b	#0,d1

srd21	move.b	d1,current.road.section
	move.w	d1,d0
	move.l	#far.section.ptrs,a0
	asl.w	#2,d0
	move.l	end.far.sections.ptr,(a0,d0.w)

	move.w	#0,current.far.section.flag
	jsr	to.next.road.section
	jsr	fetch.near.section.stuff

	tst.b	near.section.byte1
	bpl	srd22
	move.b	#$40,current.far.section.flag
	move.b	curve.to.left,d3
	move.b	plus.180.degrees,d0
	eor.b	d0,d3
	bpl	srd22
	move.b	#$80,current.far.section.flag

srd22	jsr	to.previous.road.section
	jsr	fetch.near.section.stuff
	move.w	#0,near.sections.done2
	move.b	rough.piece.angle,rough.difference.angle
	neg.b	rough.difference.angle
	jsr	make.near.top.y.coords

	move.b	coord.offset.zero.or.four,d1
	move.l	#near.section.flags,a3
	move.l	end.far.sections.ptr,a4
	move.w	piece.data.offset,d0
	rol.w	#8,d0
	subi.w	#$b100,d0
	andi.l	#$ffff,d0
	addi.l	#piece.data.offsets,d0
	move.l	d0,a0

	move.b	(a0),d0
	addq.b	#7,d0
	tst.b	plus.180.degrees
	bpl	srd23

	move.b	number.of.coords,d3
	subq.b	#1,d3
	asl.b	#2,d3
	add.b	d3,d0

srd23	move.b	d0,piece.coords.offset

srd24	move.b	(a3,d1.w),d0
	bmi	srd2e
	move.b	#$80,(a3,d1.w)
	cmpi.b	#4,d1
	blt	srd2e

	cmp.b	offset.for.last.two.coords,d1
	bge	srd28

	clr.w	d3
	move.b	offset.for.last.two.coords,d3
	tst.b	(a3,d3.w)
	bpl	srd25

	subq.b	#4,d3
	cmp.b	d3,d1
	beq	srd28

srd25	tst.b	near.section.byte1
	bmi	srd28
	move.b	current.road.section,d3
	move.l	#left.y.coordinate.IDs,a2
	cmpi.b	#37,(a2,d3.w)
	bne	srd26
	cmpi.b	#24,d1
	beq	srd28

srd26	move.w	(a6,d1.w),d3
	lsr.w	#1,d3
	move.w	-4(a6,d1.w),d4
	add.w	4(a6,d1.w),d4
	lsr.w	#2,d4
	sub.w	d4,d3
	tst.w	d3
	bpl	srd27
	neg.w	d3

srd27	cmpi.w	#80,d3
	blt	srd2e

srd28	andi.b	#$3f,d0
	asl.w	#8,d0

	tst.b	near.section.byte1
	bmi	srd29
	or.w	current.far.section.flag,d0

srd29	move.b	current.road.section,d0
	move.w	d0,(a4)+

srd2a	tst.b	plus.180.degrees
	bpl	srd2b
	move.b	d1,d3
	asl.b	#1,d3
	move.b	piece.coords.offset,d2
	sub.b	d3,d2
	bra	srd2c

srd2b	move.b	d1,d2
	asl.b	#1,d2
	add.b	piece.coords.offset,d2

srd2c	jsr	fetch.near.xz.coords
	move.w	near.x.coord,(a4)+
	move.w	near.z.coord,(a4)+
	move.w	(a6,d1.w),(a4)+
	addq.b	#2,d1
	btst	#1,d1
	bne	srd2a

srd2d	cmp.b	offset.for.after.last.coord,d1
	bne	srd24
	move.l	a4,end.far.sections.ptr

	move.b	current.road.section,d1
	addq.b	#1,d1
	cmp.b	number.of.road.sections,d1
	blt	srd21
	rts

srd2e	addq.b	#4,d1
	bra	srd2d


srd2.sub1
	clr.w	d3
	move.l	#road.visible.range.table,a0
	move.b	number.of.road.sections,d3
	bra	srd2s12

srd2s11	move.b	#120,(a0,d3.w)
srd2s12	dbra	d3,srd2s11

	move.l	#TAB.65e30,a1
	clr.w	d3
	move.b	road.ID,d3
	asl.w	#3,d3
	move.w	#3,d4

srd2s13	move.b	(a1,d3.w),d1
	bmi	srd2s14

	move.b	1(a1,d3.w),(a0,d1.w)
	addq.b	#2,d3
	dbra	d4,srd2s13

srd2s14	rts


TAB.65e30
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$30,$18,$80,$00,$00,$00,$00,$00
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$1a,$18,$80,$00,$00,$00,$00,$00
	dc.b	$0f,$28,$1c,$28,$80,$00,$00,$00
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$3d,$30,$80,$00,$00,$00,$00,$00


road.visible.range.table
	ds.b	80

road.section.x.offset	dc.w	0
road.section.z.offset	dc.w	0


****************************************


make.far.road.coords
	clr.w	d0
	move.b	current.road.section,d0
	move.l	#far.section.ptrs,a0
	asl.w	#2,d0
	move.l	(a0,d0.w),a6
	move.w	#4,d1

mfrc1	move.w	(a6)+,d0
	move.l	#far.section.flags,a0
	move.w	d0,(a0,d1.w)
	move.w	d0,current.far.section.flag
	move.b	d0,current.road.section

	jsr	fetch.xz.position

	move.b	road.section.x.offset,d0
	ext.w	d0
	move.b	road.finer.x.offset,d4
	asl.w	#8,d4
	move.b	road.finest.x.offset,d4
	asr.w	#1,d4
	asl.w	#2,d0
	asl.w	#8,d0
	add.w	d0,d4
	move.w	d4,road.section.x.offset

	move.b	road.section.z.offset,d0
	ext.w	d0
	move.b	road.finer.z.offset,d4
	asl.w	#8,d4
	move.b	road.finest.z.offset,d4
	asr.w	#1,d4
	asl.w	#2,d0
	asl.w	#8,d0
	add.w	d0,d4
	move.w	d4,road.section.z.offset

mfrc2	tst.b	rough.player.angle
	bmi	mfrc4

	btst	#6,rough.player.angle
	bne	mfrc3

	move.w	(a6)+,d0
	move.w	(a6)+,d3
	bra	mfrc6

mfrc3	move.w	(a6)+,d3
	move.w	#$800,d0
	sub.w	(a6)+,d0
	bra	mfrc6

mfrc4	btst	#6,rough.player.angle
	bne	mfrc5

	move.w	#$800,d0
	sub.w	(a6)+,d0
	move.w	#$800,d3
	sub.w	(a6)+,d3
	bra	mfrc6

mfrc5	move.w	#$800,d3
	sub.w	(a6)+,d3
	move.w	(a6)+,d0

mfrc6	asr.w	#1,d0
	asr.w	#1,d3
	add.w	road.section.x.offset,d0
	add.w	road.section.z.offset,d3
	jsr	calculate.screen.x2	calculate top x co-ord

	move.w	(a6)+,d0
	move.l	a6,-(sp)
	move.l	#coord.visible.values,a6
	move.w	d0,(a6,d1.w)		top visible value

	sub.w	y.pers.shift,d0
	neg.w	d0
	asr.w	#3,d0
	move.w	perspective.z,d3
	jsr	calculate.screen.y2	calculate top y co-ord

	move.l	#x.values,a4
	move.w	(a4,d1.w),d0
	btst	#1,d1
	bne	mfrc8

	move.w	old.left.x,d3
	move.w	d0,old.left.x
	cmp.w	d3,d0
	blt	mfrca
	bne	mfrc7

	tst.b	clip.flag
	bne	mfrca

mfrc7	btst	#7,current.far.section.flag
	bne	mfrca
	bra	mfrcb

mfrc8	move.w	old.right.x,d3
	move.w	d0,old.right.x
	cmp.w	d3,d0
	bgt	mfrca
	bne	mfrc9

	tst.b	clip.flag
	bne	mfrca

mfrc9	btst	#6,current.far.section.flag
	beq	mfrcb

mfrca	move.w	#512,120(a6,d1.w)	bottom visible value

	move.w	(a4,d1.w),120(a4,d1.w)	bottom x value

	move.w	y.pers.shift,d0
	subi.w	#512,d0
	asr.w	#3,d0
	addi.b	#120,d1
	move.w	perspective.z,d3
	jsr	calculate.screen.y2	calculate bottom y co-ord

	jsr	z.rotate		rotate bottom co-ord
	subi.b	#120,d1
	bra	mfrcc

mfrcb	move.w	#$8000,120(a6,d1.w)	if bottom co-ord not visible

mfrcc	jsr	z.rotate		rotate top co-ord
	move.l	(sp)+,a6
	cmp.l	end.far.sections.ptr,a6
	blt	mfrcd
	move.l	#far.section.coordinates,a6

mfrcd	addq.b	#2,d1
	btst	#1,d1
	bne	mfrc2			if four co-ords not done

	move.b	current.road.section,d2
	move.l	#road.visible.range.table,a0
	cmp.b	(a0,d2.w),d1
	bge	mfrcf

	move.l	#x.values,a4
	cmpi.w	#256,-4(a4,d1.w)
	bcs	mfrc1

	cmpi.w	#256,-2(a4,d1.w)
	bcs	mfrc1

	move.l	#coord.visible.values,a0
	tst.w	120-4(a0,d1.w)
	bmi	mfrce

	cmpi.w	#256,120-4(a4,d1.w)
	bcs	mfrc1
	bra	mfrcf

mfrce	tst.w	120-2(a0,d1.w)
	bmi	mfrcf

	cmpi.w	#256,120-2(a4,d1.w)
	bcs	mfrc1

mfrcf	move.b	d1,max.far.coord
	rts


max.far.coord	dc.b	0,0
old.left.x	dc.w	0
old.right.x	dc.w	0
current.far.section.flag	dc.w	0
end.far.sections.ptr	dc.l	0


****************************************


damage.line
	move.b	new.damage,d0
	cmp.b	B.1bb55,d0
	beq	dl1
	bcc	dl2
dl1	rts

dl2	addq.b	#1,B.1bb55
	move.b	B.662aa,d2
	btst	#0,B.1bb55
	bne	dl6

	jsr	randomize.long
	lsr.b	#1,d0
	bcc	dl6

	lsr.b	#1,d0
	bcc	dl4

	cmpi.b	#5,d2
	bcs	dl3

	lsr.b	#1,d0
	bcc	dl4
	subq.b	#1,d2

dl3	addq.b	#1,d2
	jmp	dl6

dl4	cmpi.b	#3,d2
	bcc	dl5

	lsr.b	#1,d0
	bcc	dl3
	addq.b	#1,d2

dl5	subq.b	#1,d2

dl6	move.b	#11,B.662ab

	cmp.b	B.662aa,d2
	ble	dl7
	move.b	#12,B.662ab

dl7	move.b	d2,B.662aa

	move.b	B.1bb55,d0
	cmpi.b	#$f0,d0
	bcs	dl9
	subq.b	#1,B.1bb55

dl8	jmp	car.is.wrecked

dl9	move.l	screen.mem,a0
	add.l	#4,a0
	move.b	B.1bb55,d4
	andi.w	#$ff,d4
	addi.b	#8,d4
	move.w	d4,d0
	move.b	B.662aa,d5
	andi.w	#7,d5
	ext.l	d0
	ext.l	d5
	lsr.l	#3,d0
	andi.b	#$fe,d0
	add.l	d0,a0

	move.l	d5,d0
	asl.l	#2,d0
	add.l	d5,d0
	asl.l	#3,d0
	add.l	d0,a0

	jsr	test.if.pixel.clear
	beq	dla

	move.b	#0,d0
	jsr	set.pixel.colour
	jsr	plot.pixel

	add.l	#32000,a0
	jsr	plot.pixel

	sub.l	#40,a0
	sub.l	#32000,a0
	jsr	plot.pixel

	add.l	#32000,a0
	jsr	plot.pixel

	sub.l	#40,a0
	move.b	B.662ab,d0
	jsr	set.pixel.colour
	jsr	plot.pixel

	sub.l	#32000,a0
	jsr	plot.pixel
	jmp	damage.line

dla	addq.b	#1,new.damage
	beq	dl8

	jsr	dlb
	jmp	damage.line

dlb	move.b	#2,d2
dlc	move.b	new.damage,d0
	move.l	#front.left.damage,a2
	move.b	d0,(a2,d2.w)
	subq.b	#1,d2
	bpl	dlc
	rts


****************************************


test.if.pixel.clear
	move.w	d4,d3
	andi.w	#$f,d3
	asl.w	#2,d3
	move.l	#pixel.masks,a3

	move.w	(a0),d0
	or.w	16000(a0),d0
	swap	d0
	move.w	8000(a0),d0
	or.w	24000(a0),d0

	and.l	(a3,d3.w),d0
	rts


B.662aa	dc.b	4
B.662ab	dc.b	11


TAB.662ac
	dc.b	-4,-13,-49,63
	dc.b	3,12,48,-64


****************************************


draw.chains
	move.b	car.on.chains.countdown,d0
	bne	dch1

	move.b	B.1bbea,d0
	cmpi.b	#96,d0
	beq	dch3

	sub.b	B.1bbe9,d0
	move.b	d0,B.1bbea

	addi.b	#8,B.1bbe9

dch1	move.b	B.1bbea,d2

dch2	move.l	#graphic.info+19*16+10,a3
	move.w	d2,d3
	subi.w	#48,d3
	move.w	d3,(a3)			y position of chain tops
	move.w	d3,32(a3)

	addi.w	#8,d3
	move.w	d3,16(a3)		y position of chain bottoms
	move.w	d3,48(a3)

	cmpi.w	#16,16(a3)
	blt	dch3

	move.b	#20,d0			left chain bottom
	jsr	copy.graphic

	move.b	#22,d0			right chain bottom
	jsr	copy.graphic

	cmpi.w	#16,(a3)
	blt	dch3

	move.b	#19,d0			left chain top
	jsr	copy.graphic

	move.b	#21,d0			right chain top
	jsr	copy.graphic

	subi.b	#16,d2
	bra	dch2

dch3	rts


****************************************


set.pixel.colour
	lsr.b	#1,d0
	bcs	spc1
	bclr	#6,pp1+1
	bclr	#6,pp6+1
	bra	spc2
spc1	bset	#6,pp1+1
	bset	#6,pp6+1

spc2	lsr.b	#1,d0
	bcs	spc3
	bclr	#6,pp2+1
	bclr	#6,pp7+1
	bra	spc4
spc3	bset	#6,pp2+1
	bset	#6,pp7+1

spc4	lsr.b	#1,d0
	bcs	spc5
	bclr	#6,pp3+1
	bclr	#6,pp8+1
	bra	spc6
spc5	bset	#6,pp3+1
	bset	#6,pp8+1

spc6	lsr.b	#1,d0
	bcs	spc7
	bclr	#6,pp4+1
	bclr	#6,pp9+1
	bra	spc8
spc7	bset	#6,pp4+1
	bset	#6,pp9+1
spc8	rts


****************************************


plot.pixel
	move.b	d4,d0
	andi.w	#$f,d0
	eori.w	#$f,d0
	cmpi.w	#8,d0
	bge	pp5

pp1	bset	d0,1(a0)
pp2	bset	d0,8001(a0)
pp3	bset	d0,16001(a0)
pp4	bset	d0,24001(a0)
	rts

pp5	andi.w	#7,d0
pp6	bset	d0,(a0)
pp7	bset	d0,8000(a0)
pp8	bset	d0,16000(a0)
pp9	bset	d0,24000(a0)
	rts


****************************************


underline.text				* From d4 to d6, d5 = Y
	jsr	set.pixel.colour

	move.l	screen2,a0
	move.w	d4,d0
	ext.l	d0
	ext.l	d5
	lsr.l	#3,d0
	andi.b	#$fe,d0
	add.l	d0,a0

	move.l	d5,d0
	asl.l	#2,d0
	add.l	d5,d0
	asl.l	#3,d0
	add.l	d0,a0

underline.more
	jsr	plot.pixel
	addq.w	#1,d4
	move.b	d4,d0
	andi.b	#$f,d0
	bne	same.word
	add.l	#2,a0
same.word
	cmp.w	d4,d6
	bne	underline.more
	rts


****************************************


fill.word
	move.w	d4,d2
	not.w	d2
word.col
	bra	col0

col0	and.w	d2,(a4)+
	and.w	d2,7998(a4)
	and.w	d2,15998(a4)
	and.w	d2,23998(a4)
	rts

col1	or.w	d4,(a4)+
	and.w	d2,7998(a4)
	and.w	d2,15998(a4)
	and.w	d2,23998(a4)
	rts

col2	and.w	d2,(a4)+
	or.w	d4,7998(a4)
	and.w	d2,15998(a4)
	and.w	d2,23998(a4)
	rts

col3	or.w	d4,(a4)+
	or.w	d4,7998(a4)
	and.w	d2,15998(a4)
	and.w	d2,23998(a4)
	rts

col4	and.w	d2,(a4)+
	and.w	d2,7998(a4)
	or.w	d4,15998(a4)
	and.w	d2,23998(a4)
	rts

col5	or.w	d4,(a4)+
	and.w	d2,7998(a4)
	or.w	d4,15998(a4)
	and.w	d2,23998(a4)
	rts

col6	and.w	d2,(a4)+
	or.w	d4,7998(a4)
	or.w	d4,15998(a4)
	and.w	d2,23998(a4)
	rts

col7	or.w	d4,(a4)+
	or.w	d4,7998(a4)
	or.w	d4,15998(a4)
	and.w	d2,23998(a4)
	rts

col8	and.w	d2,(a4)+
	and.w	d2,7998(a4)
	and.w	d2,15998(a4)
	or.w	d4,23998(a4)
	rts

col9	or.w	d4,(a4)+
	and.w	d2,7998(a4)
	and.w	d2,15998(a4)
	or.w	d4,23998(a4)
	rts

col10	and.w	d2,(a4)+
	or.w	d4,7998(a4)
	and.w	d2,15998(a4)
	or.w	d4,23998(a4)
	rts

col11	or.w	d4,(a4)+
	or.w	d4,7998(a4)
	and.w	d2,15998(a4)
	or.w	d4,23998(a4)
	rts

col12	and.w	d2,(a4)+
	and.w	d2,7998(a4)
	or.w	d4,15998(a4)
	or.w	d4,23998(a4)
	rts

col13	or.w	d4,(a4)+
	and.w	d2,7998(a4)
	or.w	d4,15998(a4)
	or.w	d4,23998(a4)
	rts

col14	and.w	d2,(a4)+
	or.w	d4,7998(a4)
	or.w	d4,15998(a4)
	or.w	d4,23998(a4)
	rts

col15	or.w	d4,(a4)+
	or.w	d4,7998(a4)
	or.w	d4,15998(a4)
	or.w	d4,23998(a4)
	rts


****************************************


fill.horizontal.line			* From d4 to d5
	cmp.w	d4,d5
	bgt	fhl1
	beq	fhl6

	tst.b	daft.flag
	bpl	fhl6
	bra	fhl6

fhl1	move.w	d4,d1
	andi.w	#$f0,d1
	lsr.w	#3,d1
	lea	(a6,d1.w),a4
	move.w	d4,d3
	move.w	d5,d1
	lsr.w	#4,d3
	lsr.w	#4,d1
	sub.w	d3,d1
	bne	fhl2

	andi.w	#$f,d4
	asl.w	#2,d4
	move.w	(a5,d4.w),d4
	andi.w	#$f,d5
	asl.w	#2,d5
	move.w	64(a5,d5.w),d5
	and.w	d5,d4
	jsr	fill.word
	bra	fhl6

fhl2	subq.b	#1,d1
	andi.w	#$f,d4
	beq	fhl3

	asl.w	#2,d4
	move.w	(a5,d4.w),d4
	jsr	fill.word
	subq.w	#1,d1
	bmi	fhl5

fhl3	move.l	d6,d2
	move.l	d7,d3
	swap	d2
	swap	d3

fhl4	move.w	d2,(a4)+
	move.w	d6,7998(a4)
	move.w	d3,15998(a4)
	move.w	d7,23998(a4)
	dbra	d1,fhl4

fhl5	andi.w	#$f,d5
	beq	fhl6

	asl.w	#2,d5
	move.w	64(a5,d5.w),d4
	jsr	fill.word

fhl6	clr.l	d1
	clr.l	d2
	rts


****************************************


simple.poly.fill
	move.w	(a2),d2
	move.w	(a0),d0
	cmp.w	(a3),d0
	bne	spf2

	cmp.w	(a1),d2
	bne	spf4

	cmp.w	d2,d0
	bge	spf4

spf1	exg	a0,a2
	exg	a1,a3
	bra	spf4

spf2	blt	spf3

	cmp.w	(a1),d2
	beq	spf1

	exg	d0,a0
	move.l	a1,a0
	move.l	a2,a1
	move.l	a3,a2
	move.l	d0,a3
	bra	spf4

spf3	cmp.w	(a1),d2
	beq	spf1

	exg	d0,a3
	move.l	a2,a3
	move.l	a1,a2
	move.l	a0,a1
	move.l	d0,a0

spf4	move.b	#2,simple.poly.count
simple.poly.fill2
	move.l	#start.masks,a5
	move.w	(a0)+,d1
	move.w	(a3)+,d0
	cmp.w	d1,d0
	bne	spfe

	addq.l	#6,a0
	addq.l	#6,a3
	move.w	d1,fp.y
	subq.w	#1,d1
	bmi	spfe

	move.l	current.scene,a6
	clr.l	d0
	move.w	d1,d0
	asl.w	#2,d0
	add.w	d1,d0
	asl.w	#3,d0
	add.l	d0,a6

spf5	move.w	(a0)+,d4
	bpl	spf6

	subq.b	#1,simple.poly.count
	bmi	spfe

	move.l	a1,a0
	move.l	a2,a1
	move.w	(a0)+,d0
	cmp.w	fp.y,d0
	bne	spfe

	addq.l	#6,a0
	move.w	(a0)+,d4
	bpl	spf6

	subq.b	#1,simple.poly.count
	bmi	spfe

	move.l	a1,a0
	move.w	(a0)+,d0
	cmp.w	fp.y,d0
	bne	spfe

	addq.l	#6,a0
	move.w	(a0)+,d4
	bmi	spfe

spf6	move.w	(a3)+,d5
	bpl	spf7

	subq.b	#1,simple.poly.count
	bmi	spfe

	move.l	a2,a3
	move.l	a1,a2
	move.w	(a3)+,d0
	cmp.w	fp.y,d0
	bne	spfe

	addq.l	#6,a3
	move.w	(a3)+,d5
	bpl	spf7

	subq.b	#1,simple.poly.count
	bmi	spfe

	move.l	a2,a3
	move.w	(a3)+,d0
	cmp.w	fp.y,d0
	bne	spfe

	addq.l	#6,a3
	move.w	(a3)+,d5
	bmi	spfe

spf7	cmp.w	d4,d5
	bgt	spf8
	beq	spfd

	tst.b	daft.flag
	bpl	spfd
	bra	spfe

spf8	move.w	d4,d1
	andi.w	#$f0,d1
	lsr.w	#3,d1
	lea	(a6,d1.w),a4
	move.w	d4,d3
	move.w	d5,d1
	lsr.w	#4,d3
	lsr.w	#4,d1
	sub.w	d3,d1
	bne	spf9

	andi.w	#$f,d4
	asl.w	#2,d4
	move.w	(a5,d4.w),d4

	andi.w	#$f,d5
	asl.w	#2,d5
	move.w	64(a5,d5.w),d5
	and.w	d5,d4
	jsr	fill.word
	bra	spfd

spf9	subq.b	#1,d1
	andi.w	#$f,d4
	beq	spfa

	asl.w	#2,d4
	move.w	(a5,d4.w),d4
	jsr	fill.word
	subq.w	#1,d1
	bmi	spfc

spfa	move.l	d6,d2
	move.l	d7,d3
	swap	d2
	swap	d3

spfb	move.w	d2,(a4)+
	move.w	d6,7998(a4)
	move.w	d3,15998(a4)
	move.w	d7,23998(a4)
	dbra	d1,spfb

spfc	andi.w	#$f,d5
	beq	spfd

	asl.w	#2,d5
	move.w	64(a5,d5.w),d4
	jsr	fill.word

spfd	subq.w	#1,fp.y
	sub.l	#40,a6
	cmp.l	current.scene,a6
	bge	spf5

spfe	clr.l	d1
	clr.l	d2
	rts


start.masks
	dc.w	$ffff,$ffff,$7fff,$7fff,$3fff,$3fff,$1fff,$1fff
	dc.w	$0fff,$0fff,$07ff,$07ff,$03ff,$03ff,$01ff,$01ff
	dc.w	$00ff,$00ff,$007f,$007f,$003f,$003f,$001f,$001f
	dc.w	$000f,$000f,$0007,$0007,$0003,$0003,$0001,$0001

end.masks
	dc.w	$0000,$0000,$8000,$8000,$c000,$c000,$e000,$e000
	dc.w	$f000,$f000,$f800,$f800,$fc00,$fc00,$fe00,$fe00
	dc.w	$ff00,$ff00,$ff80,$ff80,$ffc0,$ffc0,$ffe0,$ffe0
	dc.w	$fff0,$fff0,$fff8,$fff8,$fffc,$fffc,$fffe,$fffe

pixel.masks
	dc.w	$8000,$8000,$4000,$4000,$2000,$2000,$1000,$1000
	dc.w	$0800,$0800,$0400,$0400,$0200,$0200,$0100,$0100
	dc.w	$0080,$0080,$0040,$0040,$0020,$0020,$0010,$0010
	dc.w	$0008,$0008,$0004,$0004,$0002,$0002,$0001,$0001


simple.poly.count	dc.b	0,0


****************************************


straight.edge.count	dc.w	0
straight.edge.value	dc.w	0
y.saved	dc.w	0

clip.line.make.edge
	move.l	#section.data,a1
	move.w	#0,y.saved
	move.w	#-1,straight.edge.count
	move.w	road.section.offset,d0
	move.l	edge.space.ptr,a0
	cmp.l	#end.edge.space,a0
	blt	clme1

	tst.b	standard.clip.flag
	bmi	clme1

	move.l	#$80000000,(a1,d0.w)
	clr.w	d1
	clr.w	d2
	rts

clme1	move.l	a0,(a1,d0.w)
	move.l	a0,a2
	add.l	#8,a0
	move.l	#x.values,a4
	move.l	#y.values,a5
	move.w	(a4,d1.w),d4
	move.w	(a4,d2.w),d6
	move.w	(a5,d1.w),d5
	move.w	(a5,d2.w),d7
	cmp.w	d7,d5
	bge	clme2

	exg	d7,d5
	exg	d6,d4
	ori.b	#$40,(a1,d0.w)

clme2	move.w	#0,d0
	move.w	d0,d3
	cmpi.w	#256,d4
	bcs	clme4
	tst.w	d4
	bpl	clme3
	bset	#3,d0
	bra	clme4

clme3	bset	#2,d0
clme4	cmpi.w	#256,d6
	bcs	clme6
	tst.w	d6
	bpl	clme5
	bset	#3,d3
	bra	clme6

clme5	bset	#2,d3
clme6	cmpi.w	#128,d5
	bcs	clme8
	tst.w	d5
	bpl	clme7
	bset	#1,d0
	bra	clme8

clme7	bset	#0,d0
clme8	cmpi.w	#128,d7
	bcs	clmea
	tst.w	d7
	bpl	clme9
	bset	#1,d3
	bra	clmea

clme9	bset	#0,d3
clmea	move.b	d0,d1
	move.b	d3,d2
	swap	d0
	move.b	d1,d0
	or.b	d2,d0
	andi.b	#$f,d0
	beq	clme55

	move.b	d1,d0
	and.b	d2,d0
	andi.b	#$f,d0
	beq	clmeb

	jsr	edge.off.screen
	clr.w	d1
	clr.w	d2
	rts

clmeb	swap	d0
	btst	#1,d1
	beq	clme12
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clmec
	bset	#7,d1
	neg.w	d0

clmec	move.w	d7,d3
	sub.w	d5,d3
	bpl	clmed
	bchg	#7,d1
	neg.w	d3

clmed	neg.w	d5
	cmp.w	d0,d3
	blt	clmee
	beq	clme10
	swap	d0
	clr.w	d0
	divu	d3,d0
	mulu	d0,d5
	swap	d5
	bra	clme10

clmee	cmp.w	d3,d5
	blt	clmef
	move.w	d0,d5
	bra	clme10

clmef	swap	d5
	clr.w	d5
	divu	d3,d5
	mulu	d0,d5
	swap	d5

clme10	tst.b	d1
	bpl	clme11
	neg.w	d5

clme11	add.w	d5,d4
	move.w	#0,d5
	bra	clme19

clme12	btst	#0,d1
	beq	clme1d
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme13
	bset	#7,d1
	neg.w	d0

clme13	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme14
	bchg	#7,d1
	neg.w	d3

clme14	subi.w	#128,d5
	cmp.w	d0,d3
	blt	clme15
	beq	clme17
	swap	d0
	clr.w	d0
	divu	d3,d0
	mulu	d0,d5
	swap	d5
	bra	clme17

clme15	cmp.w	d3,d5
	blt	clme16
	move.w	d0,d5
	bra	clme17

clme16	swap	d5
	clr.w	d5
	divu	d3,d5
	mulu	d0,d5
	swap	d5

clme17	tst.b	d1
	bmi	clme18
	neg.w	d5

clme18	add.w	d5,d4
	move.w	#128,d5

clme19	andi.b	#$f0,d1
	cmpi.w	#256,d4
	bcs	clme1b
	tst.w	d4
	bpl	clme1a
	bset	#3,d1
	bra	clme1b

clme1a	bset	#2,d1

clme1b	swap	d0
	move.b	d1,d0
	or.b	d2,d0
	andi.b	#$f,d0
	beq	clme55

	move.b	d1,d0
	and.b	d2,d0
	andi.b	#$f,d0
	beq	clme1c

	jsr	edge.off.screen
	clr.w	d1
	clr.w	d2
	rts

clme1c	swap	d0
clme1d	btst	#1,d2
	beq	clme24
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme1e
	bset	#7,d1
	neg.w	d0

clme1e	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme1f
	bchg	#7,d1
	neg.w	d3

clme1f	neg.w	d7
	cmp.w	d0,d3
	blt	clme20
	beq	clme22
	swap	d0
	clr.w	d0
	divu	d3,d0
	mulu	d0,d7
	swap	d7
	bra	clme22

clme20	cmp.w	d3,d7
	blt	clme21
	move.w	d0,d7
	bra	clme22

clme21	swap	d7
	clr.w	d7
	divu	d3,d7
	mulu	d0,d7
	swap	d7

clme22	tst.b	d1
	bpl	clme23
	neg.w	d7

clme23	add.w	d7,d6
	move.w	#0,d7
	bra	clme2b

clme24	btst	#0,d2
	beq	clme2f
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme25
	bset	#7,d1
	neg.w	d0

clme25	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme26
	bchg	#7,d1
	neg.w	d3

clme26	subi.w	#128,d7
	cmp.w	d0,d3
	blt	clme27
	beq	clme29
	swap	d0
	clr.w	d0
	divu	d3,d0
	mulu	d0,d7
	swap	d7
	bra	clme29

clme27	cmp.w	d3,d7
	blt	clme28
	move.w	d0,d7
	bra	clme29

clme28	swap	d7
	clr.w	d7
	divu	d3,d7
	mulu	d0,d7
	swap	d7

clme29	tst.b	d1
	bmi	clme2a
	neg.w	d7

clme2a	add.w	d7,d6
	move.w	#128,d7

clme2b	andi.b	#$f0,d2
	cmpi.w	#256,d6
	bcs	clme2d
	tst.w	d6
	bpl	clme2c
	bset	#3,d2
	bra	clme2d

clme2c	bset	#2,d2

clme2d	swap	d0
	move.b	d1,d0
	or.b	d2,d0
	andi.b	#$f,d0
	beq	clme55

	move.b	d1,d0
	and.b	d2,d0
	andi.b	#$f,d0
	beq	clme2e

	jsr	edge.off.screen
	clr.w	d1
	clr.w	d2
	rts

clme2e	swap	d0
clme2f	move.w	d5,(a2)
	move.w	d7,2(a2)
	subq.b	#1,y.saved
	btst	#3,d1
	beq	clme3a
	move.w	d5,-(sp)
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme30
	bset	#7,d1
	neg.w	d0

clme30	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme31
	bchg	#7,d1
	neg.w	d3

clme31	neg.w	d4
	cmp.w	d3,d0
	blt	clme32
	beq	clme34
	swap	d3
	clr.w	d3
	divu	d0,d3
	mulu	d3,d4
	swap	d4
	bra	clme34

clme32	cmp.w	d0,d4
	blt	clme33
	move.w	d3,d4
	bra	clme34

clme33	swap	d4
	clr.w	d4
	divu	d0,d4
	mulu	d3,d4
	swap	d4

clme34	tst.b	d1
	bpl	clme35
	neg.w	d4

clme35	add.w	d4,d5
	move.w	#0,d4
	move.w	(sp)+,d3
	tst.b	standard.clip.flag
	bpl	clme36
	move.w	d5,d3
	move.w	d5,(a2)

clme36	sub.w	d5,d3
	bmi	clme39
	bra	clme38

clme37	move.w	#0,(a0)+
clme38	dbra	d3,clme37
clme39	bra	clme44

clme3a	btst	#2,d1
	beq	clme44
	move.w	d5,-(sp)
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme3b
	bset	#7,d1
	neg.w	d0

clme3b	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme3c
	bchg	#7,d1
	neg.w	d3

clme3c	subi.w	#256,d4
	cmp.w	d3,d0
	blt	clme3d
	beq	clme3f
	swap	d3
	clr.w	d3
	divu	d0,d3
	mulu	d3,d4
	swap	d4
	bra	clme3f

clme3d	cmp.w	d0,d4
	blt	clme3e
	move.w	d3,d4
	bra	clme3f

clme3e	swap	d4
	clr.w	d4
	divu	d0,d4
	mulu	d3,d4
	swap	d4

clme3f	tst.b	d1
	bmi	clme40
	neg.w	d4

clme40	add.w	d4,d5
	move.w	#256,d4
	move.w	(sp)+,d3
	tst.b	standard.clip.flag
	bpl	clme41
	move.w	d5,d3
	move.w	d5,(a2)

clme41	sub.w	d5,d3
	bmi	clme44
	bra	clme43

clme42	move.w	#256,(a0)+
clme43	dbra	d3,clme42

clme44	btst	#3,d2
	beq	clme4d
	move.w	d7,-(sp)
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme45
	bset	#7,d1
	neg.w	d0

clme45	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme46
	bchg	#7,d1
	neg.w	d3

clme46	neg.w	d6
	cmp.w	d3,d0
	blt	clme47
	beq	clme49
	swap	d3
	clr.w	d3
	divu	d0,d3
	mulu	d3,d6
	swap	d6
	bra	clme49

clme47	cmp.w	d0,d6
	blt	clme48
	move.w	d3,d6
	bra	clme49

clme48	swap	d6
	clr.w	d6
	divu	d0,d6
	mulu	d3,d6
	swap	d6

clme49	tst.b	d1
	bpl	clme4a
	neg.w	d6

clme4a	add.w	d6,d7
	move.w	#0,d6
	move.w	d7,d3
	sub.w	(sp)+,d3
	subq.w	#1,d3
	tst.b	standard.clip.flag
	bpl	clme4b
	move.w	d7,2(a2)
	bra	clme4c

clme4b	move.w	d3,straight.edge.count
	move.w	#0,straight.edge.value
clme4c	bra	clme55

clme4d	btst	#2,d2
	beq	clme55
	move.w	d7,-(sp)
	bclr	#7,d1
	move.w	d6,d0
	sub.w	d4,d0
	bpl	clme4e
	bset	#7,d1
	neg.w	d0

clme4e	move.w	d7,d3
	sub.w	d5,d3
	bpl	clme4f
	bchg	#7,d1
	neg.w	d3

clme4f	subi.w	#256,d6
	cmp.w	d3,d0
	blt	clme50
	beq	clme52
	swap	d3
	clr.w	d3
	divu	d0,d3
	mulu	d3,d6
	swap	d6
	bra	clme52

clme50	cmp.w	d0,d6
	blt	clme51
	move.w	d3,d6
	bra	clme52

clme51	swap	d6
	clr.w	d6
	divu	d0,d6
	mulu	d3,d6
	swap	d6

clme52	tst.b	d1
	bmi	clme53
	neg.w	d6

clme53	add.w	d6,d7
	move.w	#256,d6
	move.w	d7,d3
	sub.w	(sp)+,d3
	subq.w	#1,d3
	tst.b	standard.clip.flag
	bpl	clme54
	move.w	d7,2(a2)
	bra	clme55

clme54	move.w	d3,straight.edge.count
	move.w	#256,straight.edge.value

clme55	move.w	d5,d2
	sub.w	d7,d2
	move.w	d4,d1
	sub.w	d6,d1
	bpl	clme61
	neg.w	d1
	cmp.w	d2,d1
	blt	clme5b
	tst.w	y.saved
	bmi	clme56
	move.w	d5,(a2)
	move.w	d7,2(a2)

clme56	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	d1,d3
	lsr.w	#1,d3
	not.w	d3
	bra	clme58

clme57	addq.w	#1,d4
	add.w	d2,d3
	bcc	clme58
	sub.w	d1,d3
	subq.w	#1,d5
	move.w	d4,(a0)+

clme58	cmp.w	d6,d4
	bne	clme57
	move.w	straight.edge.count,d0
	bmi	clme5a

clme59	move.w	straight.edge.value,(a0)+
	dbra	d0,clme59

clme5a	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	clr.w	d1
	clr.w	d2
	rts

clme5b	tst.w	y.saved
	bmi	clme5c
	move.w	d5,(a2)
	move.w	d7,2(a2)

clme5c	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	d2,d3
	lsr.w	#1,d3
	not.w	d3
	bra	clme5e

clme5d	subq.w	#1,d5
	move.w	d4,(a0)+
	add.w	d1,d3
	bcc	clme5e
	sub.w	d2,d3
	addq.w	#1,d4

clme5e	cmp.w	d7,d5
	bne	clme5d
	move.w	straight.edge.count,d0
	bmi	clme60

clme5f	move.w	straight.edge.value,(a0)+
	dbra	d0,clme5f

clme60	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	clr.w	d1
	clr.w	d2
	rts

clme61	cmp.w	d2,d1
	blt	clme67
	tst.w	y.saved
	bmi	clme62
	move.w	d5,(a2)
	move.w	d7,2(a2)

clme62	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	d1,d3
	lsr.w	#1,d3
	not.w	d3
	bra	clme64

clme63	subq.w	#1,d4
	add.w	d2,d3
	bcc	clme64
	sub.w	d1,d3
	subq.w	#1,d5
	move.w	d4,(a0)+

clme64	cmp.w	d6,d4
	bne	clme63
	move.w	straight.edge.count,d0
	bmi	clme66

clme65	move.w	straight.edge.value,(a0)+
	dbra	d0,clme65

clme66	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	clr.w	d1
	clr.w	d2
	rts

clme67	tst.w	y.saved
	bmi	clme68
	move.w	d5,(a2)
	move.w	d7,2(a2)

clme68	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	d2,d3
	lsr.w	#1,d3
	not.w	d3
	bra	clme6a

clme69	subq.w	#1,d5
	move.w	d4,(a0)+
	add.w	d1,d3
	bcc	clme6a
	sub.w	d2,d3
	subq.w	#1,d4

clme6a	cmp.w	d7,d5
	bne	clme69
	move.w	straight.edge.count,d0
	bmi	clme6c

clme6b	move.w	straight.edge.value,(a0)+
	dbra	d0,clme6b

clme6c	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	clr.w	d1
	clr.w	d2
	rts


****************************************


initialise.edges
	move.l	#edge.space,a0
	move.l	#section.data,a1
	move.l	a1,a3
	move.l	#$80000000,d0
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.b	#0,30(a1)
	move.l	a0,edge.space.ptr
	move.w	#32,road.section.offset
	rts


****************************************


set.opponents.offset
	move.b	#-1,opponents.coord
	move.w	road.section.offset,d0
set.opponents.offset1
	move.l	#section.data,a0
	subi.w	#32,d0
	cmpi.w	#$ff00,opp.smallest.difference
	blt	soo1

	btst	#5,30(a1,d0.w)
	bne	soo1
	subi.w	#32,d0

soo1	andi.w	#$ffe0,d0
	move.w	d0,opponents.offset
	rts


****************************************


make.near.road.edges			* For closest near section
	move.b	#-1,d4
	move.b	opponents.road.section.m255,d0
	cmp.b	current.road.section,d0
	bne	mnre1

	move.b	opponents.distance.into.section.minus255,d4
	asl.b	#2,d4
mnre1	move.b	d4,opponents.coord

	move.b	#0,edge.x2.offset
	move.w	#48,road.section.offset
	move.b	offset.for.coord.pair.to.start.at,d1
	beq	mnre9

	move.l	#near.section.flags,a3
	move.w	d1,d0
	bra	mnre3

mnre2	move.b	#$80,(a3,d0.w)
mnre3	subq.w	#4,d0
	bpl	mnre2

	move.b	d1,d0
	lsr.b	#2,d0
	subq.b	#1,d0
	add.b	d0,near.sections.done
	bra	mnre9

make.near.road.edges2			* For other near sections
	move.l	#near.section.flags,a3
	cmpi.w	#47*32,road.section.offset
	bcc	mnre1f

	move.b	#-1,d4
	move.b	opponents.road.section.m255,d0
	cmp.b	current.road.section,d0
	bne	mnre4

	move.b	opponents.distance.into.section.minus255,d4
	asl.b	#2,d4
mnre4	move.b	d4,opponents.coord

	tst.b	opponents.coord
	bne	mnre5
	jsr	set.opponents.offset

mnre5	move.b	#0,edge.x2.offset
	move.w	#4,d1

mnre6	tst.w	(a6,d1.w)
	bpl	mnre9

mnre7	move.b	#$80,(a3,d1.w)
	cmp.b	opponents.coord,d1
	bcs	mnre8
	jsr	set.opponents.offset

mnre8	addq.b	#4,d1
	addq.b	#1,near.sections.done
	cmp.b	offset.for.after.last.coord,d1
	blt	mnre6
	rts

mnre9	move.b	edge.x2.offset,d2
	move.b	d1,edge.x1.offset

	move.b	other.road.line.colour,d0
	asl.b	#1,d0
	eor.b	d1,d0
	andi.b	#4,d0
	move.b	d0,yellow.road.lines

	move.l	#near.section.flags,a3
	move.b	(a3,d1.w),pit.and.start.byte

	jsr	adjust.y.using.x
	cmpi.w	#48,road.section.offset
	beq	mnre12

	tst.w	(a6,d2.w)
	bmi	mnrea

	tst.w	(a6,d1.w)
	bmi	mnrea

	move.b	d2,d2
	addi.b	#0,d2
	addi.b	#0,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnreb

mnrea	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnreb	addi.w	#4,road.section.offset
	tst.w	2(a6,d2.w)
	bmi	mnrec

	tst.w	2(a6,d1.w)
	bmi	mnrec

	move.b	d2,d2
	addi.b	#2,d2
	addi.b	#2,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnred

mnrec	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnred	addi.w	#4,road.section.offset
	tst.w	120(a6,d2.w)
	bmi	mnree

	tst.w	120(a6,d1.w)
	bmi	mnree

	move.b	d2,d2
	addi.b	#120,d2
	addi.b	#120,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnref

mnree	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnref	addi.w	#4,road.section.offset
	tst.w	122(a6,d2.w)
	bmi	mnre10

	tst.w	122(a6,d1.w)
	bmi	mnre10

	move.b	d2,d2
	addi.b	#122,d2
	addi.b	#122,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnre11

mnre10	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnre11	addi.w	#4,road.section.offset

mnre12	tst.b	yellow.road.lines
	beq	mnre13

	tst.b	pit.and.start.byte
	bpl	mnre13

	btst	#6,pit.and.start.byte
	bne	mnre13

	move.w	road.section.offset,d3	if side edges not needed
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d3.w)
	move.l	#$80000000,4(a1,d3.w)
	addi.w	#8,road.section.offset
	bra	mnre18

mnre13	tst.w	120(a6,d1.w)
	bmi	mnre14

	tst.w	(a6,d1.w)
	bmi	mnre14

	move.b	d1,d2
	addi.b	#120,d2
	addi.b	#0,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnre15

mnre14	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnre15	addi.w	#4,road.section.offset
	tst.w	2(a6,d1.w)
	bmi	mnre16

	tst.w	122(a6,d1.w)
	bmi	mnre16

	move.b	d1,d2
	addi.b	#2,d2
	addi.b	#122,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnre17

mnre16	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnre17	addi.w	#4,road.section.offset

mnre18	tst.b	pit.and.start.byte
	bpl	mnre19

	move.w	road.section.offset,d3	if start edge not needed
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d3.w)
	addq.w	#4,road.section.offset
	bra	mnre1c

mnre19	tst.w	(a6,d1.w)
	bmi	mnre1a

	tst.w	2(a6,d1.w)
	bmi	mnre1a

	move.b	d1,d2
	addi.b	#0,d2
	addi.b	#2,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mnre1b

mnre1a	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mnre1b	addi.w	#4,road.section.offset

mnre1c	move.w	road.section.offset,d3
	move.b	current.road.section,(a1,d3.w)	copy colour flag
	move.b	near.section.byte1,3(a1,d3.w)	not needed

	move.b	#9,d0			darkest red
	cmpi.b	#38,near.sections.done
	blt	mnre1d

	move.b	#10,d0			brighter red
	cmpi.b	#42,near.sections.done
	blt	mnre1d

	move.b	#11,d0			brightest red
	cmpi.b	#44,near.sections.done
	blt	mnre1d

	ori.b	#$80,d0			no left or right lines
	bra	mnre1e

mnre1d	tst.b	yellow.road.lines
	beq	mnre1e
	move.b	#3,d0			yellow

mnre1e	move.b	d0,1(a1,d3.w)		set road line colour
	move.b	pit.and.start.byte,2(a1,d3.w)	copy pit / start line flag

	addq.w	#4,road.section.offset
	move.l	#near.section.flags,a3
	move.b	d1,edge.x2.offset
	cmpi.w	#47*32,road.section.offset
	bcs	mnre7
mnre1f	rts


****************************************


make.far.road.edges
	move.b	#0,opponent.reached
	move.l	#coord.visible.values,a6
	move.b	#0,d2
	move.b	#4,d1

mfre1	cmpi.w	#47*32,road.section.offset
	bcc	mfre11

	move.b	d1,edge.x1.offset
	move.b	d2,edge.x2.offset
	tst.w	(a6,d2.w)
	bmi	mfre2

	tst.w	(a6,d1.w)
	bmi	mfre2

	move.b	d2,d2
	addi.b	#0,d2
	addi.b	#0,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfre3

mfre2	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mfre3	addi.w	#4,road.section.offset
	tst.w	2(a6,d2.w)
	bmi	mfre4

	tst.w	2(a6,d1.w)
	bmi	mfre4

	move.b	d2,d2
	addi.b	#2,d2
	addi.b	#2,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfre5

mfre4	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mfre5	addi.w	#4,road.section.offset
	tst.w	120(a6,d2.w)
	bmi	mfre6

	tst.w	120(a6,d1.w)
	bmi	mfre6

	move.b	d2,d2
	addi.b	#120,d2
	addi.b	#120,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfre7

mfre6	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mfre7	addi.w	#4,road.section.offset
	tst.w	122(a6,d2.w)
	bmi	mfre8

	tst.w	122(a6,d1.w)
	bmi	mfre8

	move.b	d2,d2
	addi.b	#122,d2
	addi.b	#122,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfre9

mfre8	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mfre9	addi.w	#4,road.section.offset
	tst.w	120(a6,d1.w)
	bmi	mfrea

	tst.w	(a6,d1.w)
	bmi	mfrea

	move.b	d1,d2
	addi.b	#120,d2
	addi.b	#0,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfreb

mfrea	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,0(a1,d0.w)

mfreb	addi.w	#4,road.section.offset
	tst.w	2(a6,d1.w)
	bmi	mfrec

	tst.w	122(a6,d1.w)
	bmi	mfrec

	move.b	d1,d2
	addi.b	#2,d2
	addi.b	#122,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfred

mfrec	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mfred	addi.w	#4,road.section.offset
	tst.w	(a6,d1.w)
	bmi	mfree

	tst.w	2(a6,d1.w)
	bmi	mfree

	move.b	d1,d2
	addi.b	#0,d2
	addi.b	#2,d1
	jsr	clip.line.make.edge
	move.b	edge.x1.offset,d1
	move.b	edge.x2.offset,d2
	bra	mfref

mfree	move.w	road.section.offset,d0
	move.l	#section.data,a1
	move.l	#$80000000,(a1,d0.w)

mfref	addi.w	#4,road.section.offset
	move.l	#section.data,a0
	move.w	road.section.offset,d3
	move.l	#far.section.flags,a3
	move.w	(a3,d1.w),factor1
	move.b	value,d0
	move.b	d0,(a0,d3.w)		copy colour flag
	move.b	factor1,2(a0,d3.w)	copy pit / start line flag

	tst.b	opponent.reached
	bne	mfre10

	cmp.b	opponents.road.section.m255,d0
	bne	mfre10

	move.w	d3,d0
	addq.w	#4,d0
	jsr	set.opponents.offset1
	move.b	#$80,opponent.reached

mfre10	addq.w	#4,road.section.offset
	move.b	d1,d2
	addq.b	#4,d1
	cmp.b	max.far.coord,d1
	blt	mfre1
mfre11	rts


****************************************


make.masks
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set4
	not.w	d6
mask1.set4
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set4
	not.w	d6
mask2.set4
	lsr.b	#1,d0
	bcc	mask3.set4
	not.w	d7
mask3.set4
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set4
	not.w	d7
mask4.set4
	rts


****************************************


edge.off.screen
	move.w	road.section.offset,d3
	ori.b	#$80,d0
	or.b	d0,(a1,d3.w)
	tst.w	d4
	bpl	eos1
	move.w	#0,d4

eos1	cmpi.w	#256,d4
	blt	eos2
	move.w	#256,d4

eos2	tst.w	d6
	bpl	eos3
	move.w	#0,d6

eos3	cmpi.w	#256,d6
	blt	eos4
	move.w	#256,d6

eos4	lsr.b	#1,d0
	bcc	eos5
	move.w	#128,(a2)
	move.w	#128,2(a2)
	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	rts

eos5	lsr.b	#1,d0
	bcc	eos6
	move.l	#0,(a2)
	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	rts

eos6	cmp.w	d7,d5
	bge	eos7
	exg	d7,d5

eos7	lsr.b	#1,d0
	bcc	eosf
	tst.w	d5
	bpl	eos8
	move.w	#0,d5

eos8	cmpi.w	#128,d5
	bcs	eos9
	move.w	#128,d5

eos9	move.w	d5,(a2)
	tst.w	d7
	bpl	eosa
	move.w	#0,d7

eosa	cmpi.w	#128,d7
	bcs	eosb
	move.w	#128,d7

eosb	move.w	d7,2(a2)
	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	#256,d3
	sub.w	d7,d5
	bpl	eosd
	bra	eose

eosc	move.w	d3,(a0)+
eosd	dbra	d5,eosc
eose	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	rts

eosf	lsr.b	#1,d0
	bcc	eos17
	tst.w	d5
	bpl	eos10
	move.w	#0,d5

eos10	cmpi.w	#128,d5
	bcs	eos11
	move.w	#128,d5

eos11	move.w	d5,(a2)
	tst.w	d7
	bpl	eos12
	move.w	#0,d7

eos12	cmpi.w	#128,d7
	bcs	eos13
	move.w	#128,d7

eos13	move.w	d7,2(a2)
	move.w	d4,4(a2)
	move.w	d6,6(a2)
	move.w	#0,d3
	sub.w	d7,d5
	bpl	eos15
	bra	eos16

eos14	move.w	d3,(a0)+
eos15	dbra	d5,eos14
eos16	move.w	#$8000,(a0)+
	move.l	a0,edge.space.ptr
	rts
eos17	rts


****************************************


draw.horizon
	move.w	#$500,d0
	move.w	d0,x.values+6
	neg.w	d0
	move.w	d0,x.values+4
	move.w	y.shift,d0
	asr.w	#3,d0
	neg.w	d0
	tst.b	unused.flag
	bmi	dh1
	subq.w	#8,d0

dh1	move.w	d0,y.values+4
	move.w	d0,y.values+6

	move.w	#4,d1
	jsr	z.rotate
	move.w	#6,d1
	jsr	z.rotate

	move.w	#0,road.section.offset
	move.w	#4,d1
	move.w	#6,d2
	move.b	#$80,standard.clip.flag
	jsr	clip.line.make.edge

	move.b	#0,standard.clip.flag
	move.l	edge.space.ptr,a3
	move.l	a3,a4
	move.l	(a1),d0
	andi.l	#$ffffff,d0
	beq	dh9

	move.l	d0,a0
	move.l	a0,a2
	move.w	(a2)+,d0
	move.w	d0,(a4)+
	move.w	d0,fp.y
	cmpi.w	#129,d0
	bcc	dh9

	move.w	(a2)+,d3
	move.w	d3,fp.y2
	cmpi.w	#129,d3
	bcc	dh9

	move.w	d3,(a4)+
	move.w	#256,d6
	move.w	y.values+6,d7
	sub.w	y.values+4,d7
	bpl	dh2
	move.w	#0,d6
	exg	a0,a3

dh2	move.w	d6,(a4)+
	move.w	d6,(a4)+
	sub.w	d3,d0
	bmi	dh4

dh3	move.w	d6,(a4)+
	dbra	d0,dh3

dh4	move.w	#$8000,(a4)+
	movem.l	a0-a2,-(sp)
	move.l	current.scene,a4
	move.w	fp.y2,d0
	asl.w	#2,d0
	add.w	fp.y2,d0
	asl.w	#3,d0
	lea	(a4,d0.w),a4
	move.w	#127,d4
	sub.w	fp.y2,d4
	bmi	dh6
	move.b	#GROUND.COLOUR,d0
	jsr	make.masks
	jsr	convert.masks

dh5	lea	8000(a4),a0
	lea	16000(a4),a1
	lea	24000(a4),a2

	rept	8
	move.l	d6,(a4)+
	move.l	d1,(a0)+
	move.l	d7,(a1)+
	move.l	d2,(a2)+
	endr

	add.l	#8,a4
	dbra	d4,dh5

dh6	move.b	#SKY.COLOUR,d0
	jsr	make.masks
	jsr	convert.masks
	move.w	fp.y2,d4
	subq.b	#1,d4
	bmi	dh8
	move.l	current.scene,a4

dh7	lea	8000(a4),a0
	lea	16000(a4),a1
	lea	24000(a4),a2

	rept	8
	move.l	d6,(a4)+
	move.l	d1,(a0)+
	move.l	d7,(a1)+
	move.l	d2,(a2)+
	endr

	add.l	#8,a4
	dbra	d4,dh7

dh8	move.b	#0,simple.poly.count
	movem.l	(sp)+,a0-a2
	clr.w	d1
	clr.w	d2
	move.b	#SKY.COLOUR,d0
	jsr	make.masks
	jmp	simple.poly.fill2
dh9	rts


****************************************


convert.masks
	move.l	d6,d0
	move.l	d6,d1
	swap	d1
	move.w	d6,d1
	swap	d0
	move.w	d0,d6

	move.l	d7,d0
	move.l	d7,d2
	swap	d2
	move.w	d7,d2
	swap	d0
	move.w	d0,d7
	rts


****************************************


draw.opponent
	tst.b	opponent.behind.player
	bmi	end.draw.opponent

	move.w	smallest.distance.between.players,d0
	cmpi.w	#10,d0
	bcs	end.draw.opponent

	cmpi.w	#3200,d0
	bge	end.draw.opponent

	move.w	road.section.offset,-(sp)
	move.w	#47*32,road.section.offset
	jsr	make.opponent

	move.b	#$80,daft.flag
	move.w	#47*32,road.section.offset
	tst.b	B.1bbba
	bne	left.front.wheel

* Only draw shadow if it is fully on the track

	cmpi.w	#28,opponents.road.x.position
	blt	left.front.wheel

	cmpi.w	#228,opponents.road.x.position
	bgt	left.front.wheel

	addi.w	#128,road.section.offset

shadow	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.shadow

	move.l	d0,a0
	move.l	4(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.shadow

	move.l	d0,a1
	move.l	8(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.shadow

	move.l	d0,a2
	move.l	12(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.shadow

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	no.shadow

	move.b	#5,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set5
	not.w	d6
mask1.set5
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set5
	not.w	d6
mask2.set5
	lsr.b	#1,d0
	bcc	mask3.set5
	not.w	d7
mask3.set5
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set5
	not.w	d7
mask4.set5
	jsr	simple.poly.fill

no.shadow
	subi.w	#128,road.section.offset

left.front.wheel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	96(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.front.wheel

	move.l	d0,a0
	move.l	100(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.front.wheel

	move.l	d0,a1
	move.l	104(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.front.wheel

	move.l	d0,a2
	move.l	108(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.front.wheel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	right.front.wheel

	move.b	#0,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set6
	not.w	d6
mask1.set6
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set6
	not.w	d6
mask2.set6
	lsr.b	#1,d0
	bcc	mask3.set6
	not.w	d7
mask3.set6
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set6
	not.w	d7
mask4.set6
	jsr	simple.poly.fill

right.front.wheel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	112(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.body.panel

	move.l	d0,a0
	move.l	116(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.body.panel

	move.l	d0,a1
	move.l	120(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.body.panel

	move.l	d0,a2
	move.l	124(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.body.panel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	left.body.panel

	move.b	#0,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set7
	not.w	d6
mask1.set7
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set7
	not.w	d6
mask2.set7
	lsr.b	#1,d0
	bcc	mask3.set7
	not.w	d7
mask3.set7
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set7
	not.w	d7
mask4.set7
	jsr	simple.poly.fill

left.body.panel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	32(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.body.panel

	move.l	d0,a0
	move.l	56(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.body.panel

	move.l	d0,a1
	move.l	16(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.body.panel

	move.l	d0,a2
	move.l	48(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.body.panel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	right.body.panel

	move.b	#12,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set8
	not.w	d6
mask1.set8
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set8
	not.w	d6
mask2.set8
	lsr.b	#1,d0
	bcc	mask3.set8
	not.w	d7
mask3.set8
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set8
	not.w	d7
mask4.set8
	jsr	simple.poly.fill

right.body.panel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	24(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	rear.body.panel

	move.l	d0,a0
	move.l	60(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	rear.body.panel

	move.l	d0,a1
	move.l	40(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	rear.body.panel

	move.l	d0,a2
	move.l	52(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	rear.body.panel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	rear.body.panel

	move.b	#12,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set9
	not.w	d6
mask1.set9
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set9
	not.w	d6
mask2.set9
	lsr.b	#1,d0
	bcc	mask3.set9
	not.w	d7
mask3.set9
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set9
	not.w	d7
mask4.set9
	jsr	simple.poly.fill

rear.body.panel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	16(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	top.body.panel

	move.l	d0,a0
	move.l	20(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	top.body.panel

	move.l	d0,a1
	move.l	24(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	top.body.panel

	move.l	d0,a2
	move.l	28(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	top.body.panel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	top.body.panel

	move.b	#10,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.setA
	not.w	d6
mask1.setA
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.setA
	not.w	d6
mask2.setA
	lsr.b	#1,d0
	bcc	mask3.setA
	not.w	d7
mask3.setA
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.setA
	not.w	d7
mask4.setA
	jsr	simple.poly.fill

top.body.panel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	56(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	bottom.body.panel

	move.l	d0,a0
	move.l	36(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	bottom.body.panel

	move.l	d0,a1
	move.l	60(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	bottom.body.panel

	move.l	d0,a2
	move.l	20(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	bottom.body.panel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	bottom.body.panel

	move.b	#15,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.setB
	not.w	d6
mask1.setB
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.setB
	not.w	d6
mask2.setB
	lsr.b	#1,d0
	bcc	mask3.setB
	not.w	d7
mask3.setB
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.setB
	not.w	d7
mask4.setB
	jsr	simple.poly.fill

bottom.body.panel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	48(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.rear.wheel

	move.l	d0,a0
	move.l	28(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.rear.wheel

	move.l	d0,a1
	move.l	52(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.rear.wheel

	move.l	d0,a2
	move.l	44(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	left.rear.wheel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	left.rear.wheel

	move.b	#9,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.setC
	not.w	d6
mask1.setC
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.setC
	not.w	d6
mask2.setC
	lsr.b	#1,d0
	bcc	mask3.setC
	not.w	d7
mask3.setC
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.setC
	not.w	d7
mask4.setC
	jsr	simple.poly.fill

left.rear.wheel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	64(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.rear.wheel

	move.l	d0,a0
	move.l	68(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.rear.wheel

	move.l	d0,a1
	move.l	72(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.rear.wheel

	move.l	d0,a2
	move.l	76(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	right.rear.wheel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	right.rear.wheel

	move.b	#0,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.setD
	not.w	d6
mask1.setD
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.setD
	not.w	d6
mask2.setD
	lsr.b	#1,d0
	bcc	mask3.setD
	not.w	d7
mask3.setD
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.setD
	not.w	d7
mask4.setD
	jsr	simple.poly.fill

right.rear.wheel
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	80(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.right.rear.wheel

	move.l	d0,a0
	move.l	84(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.right.rear.wheel

	move.l	d0,a1
	move.l	88(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.right.rear.wheel

	move.l	d0,a2
	move.l	92(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.right.rear.wheel

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	no.right.rear.wheel

	move.b	#0,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.setE
	not.w	d6
mask1.setE
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.setE
	not.w	d6
mask2.setE
	lsr.b	#1,d0
	bcc	mask3.setE
	not.w	d7
mask3.setE
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.setE
	not.w	d7
mask4.setE
	jsr	simple.poly.fill

no.right.rear.wheel
	move.b	#0,daft.flag
	move.w	(sp)+,road.section.offset
end.draw.opponent
	rts


****************************************


edge.space.ptr	dc.l	0
road.section.offset	dc.w	0


drs.sub	cmp.w	d2,d1
	bge	drs.sub1
	exg	d1,d2

drs.sub1
	move.l	edge.space.ptr,a0
	cmp.l	#end.edge.space,a0
	bgt	drs.sub6

	cmpi.w	#129,d2
	bcc	drs.sub6

	cmpi.w	#129,d1
	bcc	drs.sub6

	move.w	d1,(a0)+
	move.w	d2,(a0)+
	move.w	d0,(a0)+
	move.w	d0,(a0)+
	sub.w	d2,d1
	bra	drs.sub3

drs.sub2
	move.w	d0,(a0)+
drs.sub3
	dbra	d1,drs.sub2

	move.w	#$8000,(a0)+
	tst.b	clip.flag1
	bmi	drs.sub4

	move.l	edge.space.ptr,(a1)+
	bra	drs.sub5

drs.sub4
	move.l	edge.space.ptr,-(a2)

drs.sub5
	move.l	a0,edge.space.ptr
	move.w	#0,d1
	move.w	d1,d2
	rts

drs.sub6
	move.w	#1,d1
	move.w	d1,d2
	rts


get.coord.pair
	btst	#6,d0
	beq	get.end.pair

	move.w	(a5),d7
	move.w	4(a5),d6
	rts

get.end.pair
	move.w	2(a5),d7
	move.w	6(a5),d6
	rts


clip.word	dc.w	0


clip.closest.section
	move.b	#0,closest.section.flag
	move.b	#0,clip.flag1
	jsr	clip.sub
	tst.b	clip.flag2
	bpl	ccs7

	tst.b	clip.flag4
	beq	ccs5

	move.b	clip.flag,d1
	beq	ccs6

	move.b	clip.flag4,d3
	eor.b	d3,d1
	bne	ccs6

	move.w	players.x.offset.from.road.centre,d3
	bpl	ccs1
	neg.w	d3

ccs1	cmpi.w	#197,d3
	blt	ccs6

	cmpi.w	#576,d3
	bge	ccs6

	tst.b	clip.flag4
	bmi	ccs3

	tst.w	d7
	beq	ccs2

	tst.w	d6
	bne	ccs6

	cmpi.w	#64,d7
	bge	ccs6

ccs2	cmp.w	d7,d5
	ble	ccs6
	bra	ccs7

ccs3	tst.w	d5
	beq	ccs4

	cmpi.w	#256,d0
	bne	ccs6

	cmpi.w	#64,d5
	bge	ccs6

ccs4	cmp.w	d5,d7
	ble	ccs6
	bra	ccs7

ccs5	tst.b	clip.flag
	beq	ccs7

ccs6	tst.b	clip.flag2
	bpl	ccs7

	exg	d0,d6
	exg	d5,d7
	move.b	#$80,clip.flag1
ccs7	bra	ccs8

ccs8	move.w	d0,clip.word
	move.b	#0,clip.flag3
	cmpi.w	#256,d0
	beq	ccsa

	cmpi.w	#0,d0
	beq	ccsc

	cmpi.w	#128,d5
	beq	ccsb

	cmpi.w	#0,d5
	beq	ccsd
	bra	end.clip

ccs9	addq.b	#1,clip.flag3
ccsa	jsr	clip.sub1
	bcc	end.clip2

ccsb	jsr	clip.sub3
	bcc	end.clip2

ccsc	jsr	clip.sub2
	bcc	end.clip2

ccsd	jsr	clip.sub4
	bcc	end.clip2

	cmpi.b	#2,clip.flag3
	blt	ccs9

end.clip
	move.b	#$80,closest.section.flag
end.clip2
	rts


clip.sub1
	cmpi.w	#256,d6
	beq	cs12

cs11	move.w	#256,d0
	move.w	d5,d1
	move.w	#128,d2
	jsr	drs.sub
	bne	end.clip

	move.w	#128,d5
	ori.b	#1,ccr
	rts

cs12	cmp.w	d7,d5
	bgt	cs11

	move.w	#256,d0
	move.w	d5,d1
	move.w	d7,d2
	jsr	drs.sub
	bne	end.clip

	andi.b	#%11110,ccr
	rts


clip.sub2
	cmpi.w	#0,d6
	beq	cs22

cs21	move.w	#0,d0
	move.w	d5,d1
	move.w	#0,d2
	jsr	drs.sub
	bne	end.clip

	move.w	#0,d5
	ori.b	#1,ccr
	rts

cs22	cmp.w	d7,d5
	blt	cs21

	move.w	#0,d0
	move.w	d5,d1
	move.w	d7,d2
	jsr	drs.sub
	bne	end.clip

	andi.b	#%11110,ccr
	rts


clip.sub3
	cmpi.w	#128,d7
	beq	cs32

cs31	move.w	#0,clip.word
	ori.b	#1,ccr
	rts

cs32	move.w	clip.word,d0
	cmp.w	d6,d0
	blt	cs31

	andi.b	#%11110,ccr
	rts


clip.sub4
	cmpi.w	#0,d7
	beq	cs42

cs41	move.w	#256,clip.word
	ori.b	#1,ccr
	rts

cs42	move.w	clip.word,d0
	cmp.w	d6,d0
	bgt	cs41

	andi.b	#%11110,ccr
	rts


clip.sub
	move.w	d0,d1
	move.w	d5,d2
	jsr	clip.sub5
	move.w	d3,-(sp)
	move.w	d6,d1
	move.w	d7,d2
	jsr	clip.sub5
	sub.w	(sp)+,d3
	bpl	cs1

	neg.w	d3
	cmpi.w	#384,d3			width of road ?
	blt	cs2
	bra	cs3

cs1	cmpi.w	#384,d3			width of road ?
	blt	cs3

cs2	move.b	#$80,clip.flag2
	rts

cs3	move.b	#0,clip.flag2
	rts


clip.sub5
	move.w	#0,d3
	cmpi.w	#0,d2
	bne	cs51

	move.w	d1,d3
	bra	cs54

cs51	addi.w	#256,d3
	cmpi.w	#256,d1
	bne	cs52

	add.w	d2,d3
	bra	cs54

cs52	addi.w	#128,d3
	cmpi.w	#128,d2
	bne	cs53

	addi.w	#256,d3
	sub.w	d1,d3
	bra	cs54

cs53	addi.w	#256,d3
	addi.w	#128,d3
	sub.w	d2,d3

cs54	clr.w	d1
	clr.w	d2
	rts


check.x.coord.magnitude
	move.l	#x.values,a0
	move.w	(a0,d1.w),d0
	bpl	cxcm1
	neg.w	d0

cxcm1	cmpi.w	#$c00,d0
	bge	cxcm2
	andi.b	#%11110,ccr
	rts

cxcm2	move.w	#$8000,(a6,d1.w)
	ori.b	#1,ccr
	rts


clip.flag1	dc.b	0
clip.flag2	dc.b	0
clip.flag3	dc.b	0
clip.flag4	dc.b	0


fp0	move.w	bottom.ptrs.offset,d2
	move.l	#bottom.ptrs,a4
fp1	move.w	(a4,d2.w),d0
	bpl	fp3

fp2	subi.w	#10,d2
	bpl	fp1

	move.w	#$8000,d0
	rts

fp3	cmp.l	a2,a1
	bgt	fp4

	cmp.l	2(a4,d2.w),a1
	bgt	fp2

	cmp.l	2(a4,d2.w),a2
	blt	fp2
	bra	fp5

fp4	cmp.l	2(a4,d2.w),a1
	blt	fp5

	cmp.l	2(a4,d2.w),a2
	blt	fp2

fp5	move.w	d2,d1
fp6	subi.w	#10,d2
	bmi	fp9

	cmp.w	(a4,d2.w),d0
	bge	fp6

	cmp.l	a2,a1
	bgt	fp7

	cmp.l	2(a4,d2.w),a1
	bgt	fp6

	cmp.l	2(a4,d2.w),a2
	blt	fp6
	bra	fp8

fp7	cmp.l	2(a4,d2.w),a1
	blt	fp8

	cmp.l	2(a4,d2.w),a2
	blt	fp6

fp8	move.w	d2,d1
	move.w	(a4,d1.w),d0
	bra	fp6

fp9	move.w	#$8000,(a4,d1.w)
	rts


****************************************


fill.polygon
	move.b	#0,fp.level
	move.l	a1,fp.end
	move.l	a2,fp.start
	sub.l	a2,a1
	move.l	a1,fp.diff
	beq	fp2b

	move.w	#0,d7
	move.b	start.line.flag,d6
	andi.b	#$40,d6
	eori.b	#$40,d6
	move.l	#bottom.ptrs,a4
	move.l	#section.side.ptrs,a0
	move.l	(a0)+,a5
	move.l	a0,a3
	bra	fpf

fpa	move.l	a0,a3
	move.l	(a0)+,a5
	move.w	(a5),d0
	cmp.w	2(a5),d0
	bne	fpb

	cmp.l	#section.side.ptrs,a3
	bne	fpf

	btst	#6,start.line.flag
	bne	fpc
	bra	fpf

fpb	cmp.w	d4,d0
	beq	fpc

	cmp.w	2(a5),d3
	bne	fpd

	move.b	#$40,d6
	bra	fpf

fpc	tst.b	d6
	bne	fpd

	move.b	#0,d6
	bra	fpf

fpd	eori.b	#$40,d6
	bne	fpf

	move.l	a3,6(a4,d7.w)
	move.l	a0,d2
	subq.l	#8,d2
	cmp.l	fp.start,d2
	bge	fpe

	add.l	fp.diff,d2

fpe	move.l	d2,2(a4,d7.w)
	move.w	d0,(a4,d7.w)
	addi.w	#10,d7

fpf	move.w	(a5),d3
	move.w	2(a5),d4
	cmp.l	fp.end,a0
	bne	fp10

	sub.l	fp.diff,a0

fp10	cmp.l	#section.side.ptrs,a3
	bne	fpa

	subi.w	#10,d7
	beq	fp14
	bmi	fp2c

	move.w	d7,bottom.ptrs.offset
	move.w	bottom.ptrs.offset,d2
	move.w	(a4,d2.w),d0
	move.w	d2,d1
	bra	fp12

fp11	cmp.w	(a4,d2.w),d0
	bge	fp12

	move.w	(a4,d2.w),d0
	move.w	d2,d1

fp12	subi.w	#10,d2
	bpl	fp11

	move.w	#$8000,(a4,d1.w)
	move.l	6(a4,d1.w),a1
	move.l	2(a4,d1.w),a2
	jsr	fp0
	move.w	d0,fp.y.flag
	bmi	fp13

	move.l	6(a4,d1.w),fp.ptr1
	move.l	2(a4,d1.w),fp.ptr2
fp13	bra	fp15

fp14	move.w	#$8000,fp.y.flag
	move.l	6(a4),a1
	move.l	2(a4),a2

fp15	move.l	(a1),a0
	move.l	(a2),a3

	move.b	fp.colour,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set
	not.w	d6
mask1.set
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set
	not.w	d6
mask2.set
	lsr.b	#1,d0
	bcc	mask3.set
	not.w	d7
mask3.set
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set
	not.w	d7
mask4.set
	move.l	#start.masks,a5

	move.w	(a0)+,d1
	move.w	(a3)+,d0
	cmp.w	d1,d0
	bne	fp2c

	addq.l	#6,a0
	addq.l	#6,a3
	move.w	d1,fp.y
	subq.w	#1,d1
	cmpi.w	#128,d1
	bcc	fp2c

	move.l	current.scene,a6
	clr.l	d0
	move.w	d1,d0
	asl.w	#2,d0
	add.w	d1,d0
	asl.w	#3,d0
	add.l	d0,a6

fp1a	move.w	fp.y,d0
	cmp.w	fp.y.flag,d0
	bne	fp1c

	move.w	fp.y,-(sp)
	move.l	a6,-(sp)
	move.l	a3,-(sp)
	move.l	a2,-(sp)
	move.l	fp.ptr1,-(sp)
	addq.b	#1,fp.level
	move.l	fp.ptr2,a2
	move.l	(a2),a3
	add.l	#8,a3
	jsr	fp0
	move.w	d0,fp.y.flag
	bmi	fp1b

	move.l	6(a4,d1.w),fp.ptr1
	move.l	2(a4,d1.w),fp.ptr2
fp1b	bra	fp1a

fp1c	move.w	(a0)+,d4
	bpl	fp1f

fp1d	addq.l	#4,a1
	cmp.l	fp.end,a1
	blt	fp1e

	sub.l	fp.diff,a1

fp1e	cmp.l	a2,a1
	beq	fp29

	move.l	(a1),a0
	move.w	(a0)+,d4
	cmp.w	fp.y,d4
	bne	fp2c

	addq.l	#6,a0
	move.w	(a0)+,d4
	bmi	fp1d

fp1f	move.w	(a3)+,d5
	bpl	fp22

fp20	cmp.l	fp.start,a2
	bne	fp21

	add.l	fp.diff,a2

fp21	move.l	-(a2),a3
	cmp.l	a1,a2
	beq	fp29

	move.w	(a3)+,d5
	cmp.w	fp.y,d5
	bne	fp2c

	addq.l	#6,a3
	move.w	(a3)+,d5
	bmi	fp20

fp22	cmp.w	d4,d5
	bgt	fp23
	beq	fp28

	tst.b	daft.flag
	bpl	fp28
	bra	fp28

fp23	move.w	d4,d1
	andi.w	#$f0,d1
	lsr.w	#3,d1
	lea	(a6,d1.w),a4
	move.w	d4,d3
	move.w	d5,d1
	lsr.w	#4,d3
	lsr.w	#4,d1
	sub.w	d3,d1
	bne	fp24

	andi.w	#$f,d4
	asl.w	#2,d4
	move.w	(a5,d4.w),d4

	andi.w	#$f,d5
	asl.w	#2,d5
	move.w	64(a5,d5.w),d5
	and.w	d5,d4
	jsr	fill.word
	bra	fp28

fp24	subq.b	#1,d1
	andi.w	#$f,d4
	beq	fp25

	asl.w	#2,d4
	move.w	(a5,d4.w),d4
	jsr	fill.word
	subq.w	#1,d1
	bmi	fp27

fp25	move.l	d6,d2
	move.l	d7,d3
	swap	d2
	swap	d3

fp26	move.w	d2,(a4)+
	move.w	d6,7998(a4)
	move.w	d3,15998(a4)
	move.w	d7,23998(a4)
	dbra	d1,fp26

fp27	andi.w	#$f,d5
	beq	fp28

	asl.w	#2,d5
	move.w	64(a5,d5.w),d4
	jsr	fill.word

fp28	subq.w	#1,fp.y
	sub.l	#40,a6
	cmp.l	current.scene,a6
	bge	fp1a

fp29	tst.b	fp.level
	beq	fp2b

	move.l	(sp)+,a1
	move.l	(sp)+,a2
	move.l	(sp)+,a3
	move.l	(sp)+,a6
	move.w	(sp)+,fp.y
	subq.b	#1,fp.level
	move.l	(a1),a0
	add.l	#8,a0
	jsr	fp0
	move.w	d0,fp.y.flag
	bmi	fp2a

	move.l	6(a4,d1.w),fp.ptr1
	move.l	2(a4,d1.w),fp.ptr2
fp2a	bra	fp1a

fp2b	clr.l	d1
	clr.l	d2
	rts

fp2c	tst.b	fp.level
	beq	fp2b

	move.l	(sp)+,a1
	move.l	(sp)+,a2
	move.l	(sp)+,a3
	move.l	(sp)+,a6
	move.w	(sp)+,fp.y
	subq.b	#1,fp.level
	move.l	(a1),a0
	add.l	#8,a0
	bra	fp2c


****************************************


draw.start.line
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.b	#START.LINE.COLOUR,d0
	jsr	set.pixel.colour
	move.l	24(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	done.start.line
	move.l	d0,a3
	jsr	plot.line
done.start.line
	rts


****************************************


draw.left.side.lines
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	bra	dlsl3

dlsl1	move.b	29(a4,d3.w),d0
	bmi	dlsl2

	cmpi.b	#3,d0
	beq	dlsl2

	move.b	side.lines.colour,d0
	jsr	set.pixel.colour
	move.l	16(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	dlsl2

	move.l	d0,a3
	jsr	plot.line
dlsl2	subi.w	#32,d3
dlsl3	cmp.w	next.road.section.offset,d3
	bne	dlsl1
	rts


****************************************


draw.right.side.lines
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	bra	drsl3

drsl1	move.b	29(a4,d3.w),d0
	bmi	drsl2

	cmpi.b	#3,d0
	beq	drsl2

	move.b	side.lines.colour,d0
	jsr	set.pixel.colour
	move.l	20(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	drsl2

	move.l	d0,a3
	jsr	plot.line
drsl2	subi.w	#32,d3
drsl3	cmp.w	next.road.section.offset,d3
	bne	drsl1
	rts


****************************************


draw.left.road.lines
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	bra	dlrl3

dlrl1	move.b	29(a4,d3.w),d0
	bmi	dlrl2

	jsr	set.pixel.colour
	move.l	(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	dlrl2

	move.l	d0,a3
	jsr	plot.line
dlrl2	subi.w	#32,d3
dlrl3	cmp.w	next.road.section.offset,d3
	bne	dlrl1
	rts


****************************************


draw.right.road.lines
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	bra	drrl3

drrl1	move.b	29(a4,d3.w),d0
	bmi	drrl2

	jsr	set.pixel.colour
	move.l	4(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	drrl2

	move.l	d0,a3
	jsr	plot.line
drrl2	subi.w	#32,d3
drrl3	cmp.w	next.road.section.offset,d3
	bne	drrl1
	rts


****************************************


draw.near.left.sides
	move.b	#$80,clip.flag4
	move.l	#section.data,a4
	move.w	road.section.offset,d3
dnls1	move.w	d3,copy.road.section.offset
	move.l	16(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	bne	dnls3

dnls2	subi.w	#32,d3
	cmp.w	next.road.section.offset,d3
	ble	dnlse

	move.l	16(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	dnls2
	bra	dnls1

dnls3	move.l	#section.side.ptrs,a1
	move.l	a1,a2
	move.b	#SIDES.COLOURA,d5
	btst	#0,28(a4,d3.w)
	beq	dnls4
	move.b	sides.colour,d5

dnls4	tst.b	use.lines.colour
	beq	dnls5
	move.b	side.lines.colour,d5

dnls5	move.b	d5,fp.colour
	move.l	d0,(a1)+
	move.b	16(a4,d3.w),d0
	move.b	d0,start.line.flag
	move.b	d0,left.side.flag
	eori.b	#$40,d0
	move.b	d0,right.side.flag
	cmpi.w	#32,copy.road.section.offset
	beq	dnlsa

dnls6	move.l	(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnls8

	move.b	(a4,d3.w),right.side.flag
	move.l	d0,(a1)+

	move.l	8(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnls7

	move.b	8(a4,d3.w),left.side.flag
	move.l	d0,-(a2)

	subi.w	#32,d3
	cmp.w	next.road.section.offset,d3
	beq	dnls9

	cmpi.w	#32,d3
	bne	dnls6
	bra	dnlsa

dnls7	subq.l	#4,a1

dnls8	cmp.w	road.section.offset,d3
	beq	dnlse

dnls9	move.l	16(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnlse

	move.b	16(a4,d3.w),right.side.flag
	move.l	d0,(a1)+
	bra	dnlsd


dnlsa	move.l	(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnlsb

	move.b	(a4,d3.w),right.side.flag
	move.l	d0,(a1)+

dnlsb	move.l	-4(a1),a5
	move.b	right.side.flag,d0
	jsr	get.coord.pair
	move.w	d6,-(sp)
	move.w	d7,d5

	move.l	8(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnlsc

	move.b	8(a4,d3.w),left.side.flag
	move.l	d0,-(a2)

dnlsc	move.l	(a2),a5
	move.b	left.side.flag,d0
	jsr	get.coord.pair
	move.w	(sp)+,d0

	jsr	clip.closest.section

	tst.b	closest.section.flag
	bmi	dnlse

dnlsd	andi.l	#$f000000,d4
	bne	dnlse

	jsr	fill.polygon
dnlse	rts


****************************************


draw.near.right.sides
	move.b	#2,clip.flag4
	move.l	#section.data,a4
	move.w	road.section.offset,d3
dnrsf	move.w	d3,copy.road.section.offset
	move.l	20(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	bne	dnrs11

dnrs10	subi.w	#32,d3
	cmp.w	next.road.section.offset,d3
	ble	dnrs1c

	move.l	20(a4,d3.w),d0
	andi.l	#$ffffff,d0
	beq	dnrs10
	bra	dnrsf

dnrs11	move.l	#section.side.ptrs,a1
	move.l	a1,a2
	move.b	#SIDES.COLOURA,d5
	btst	#0,28(a4,d3.w)
	beq	dnrs12
	move.b	sides.colour,d5

dnrs12	tst.b	use.lines.colour
	beq	dnrs13
	move.b	side.lines.colour,d5

dnrs13	move.b	d5,fp.colour
	move.l	d0,(a1)+
	move.b	20(a4,d3.w),d0
	move.b	d0,start.line.flag
	move.b	d0,left.side.flag
	eori.b	#$40,d0
	move.b	d0,right.side.flag
	cmpi.w	#32,copy.road.section.offset
	beq	dnrs18

dnrs14	move.l	12(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnrs16

	move.b	12(a4,d3.w),right.side.flag
	move.l	d0,(a1)+

	move.l	4(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnrs15

	move.b	4(a4,d3.w),left.side.flag
	move.l	d0,-(a2)

	subi.w	#32,d3
	cmp.w	next.road.section.offset,d3
	beq	dnrs17

	cmpi.w	#32,d3
	bne	dnrs14
	bra	dnrs18

dnrs15	subq.l	#4,a1

dnrs16	cmp.w	road.section.offset,d3
	beq	dnrs1c

dnrs17	move.l	20(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnrs1c

	move.b	20(a4,d3.w),right.side.flag
	move.l	d0,(a1)+
	bra	dnrs1b


dnrs18	move.l	12(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnrs19

	move.b	12(a4,d3.w),right.side.flag
	move.l	d0,(a1)+

dnrs19	move.l	-4(a1),a5
	move.b	right.side.flag,d0
	jsr	get.coord.pair
	move.w	d6,-(sp)
	move.w	d7,d5

	move.l	4(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dnrs1a

	move.b	4(a4,d3.w),left.side.flag
	move.l	d0,-(a2)

dnrs1a	move.l	(a2),a5
	move.b	left.side.flag,d0
	jsr	get.coord.pair
	move.w	(sp)+,d0

	jsr	clip.closest.section

	tst.b	closest.section.flag
	bmi	dnrs1c

dnrs1b	andi.l	#$f000000,d4
	bne	dnrs1c

	jsr	fill.polygon
dnrs1c	rts


****************************************


draw.road.surface
	move.b	#0,clip.flag4
	move.b	#0,section.flags2
	move.b	#$80,drs.flag
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.w	d3,copy.road.section.offset

	move.l	24(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	surface.done

	move.l	#section.side.ptrs,a1
	move.l	a1,a2
	move.b	#ROAD.COLOURA,d5
	btst	#0,28(a4,d3.w)
	beq	drs.col1
	move.b	#ROAD.COLOURB,d5

drs.col1
	move.b	30(a4,d3.w),section.flags2
	btst	#5,section.flags2
	beq	drs.col.set
	move.b	#ROAD.PIT.COLOUR,d5

drs.col.set
	move.b	d5,fp.colour

	move.l	d0,(a1)+

	move.b	24(a4,d3.w),d0
	move.b	d0,start.line.flag

	move.b	d0,left.side.flag
	eori.b	#$40,d0
	move.b	d0,right.side.flag

	cmpi.w	#32,copy.road.section.offset
	beq	closest.section

save.right.left.sides
	move.l	4(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.right.side

	move.b	4(a4,d3.w),right.side.flag
	move.l	d0,(a1)+

	move.l	(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.left.side

	move.b	(a4,d3.w),left.side.flag
	move.l	d0,-(a2)

	subi.w	#32,d3
	cmp.w	next.road.section.offset,d3
	beq	save.next.start.line

	cmpi.w	#32,d3
	bne	save.right.left.sides
	bra	closest.section

no.left.side
	subq.l	#4,a1

no.right.side
	cmp.w	road.section.offset,d3
	beq	surface.done

save.next.start.line
	move.l	24(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	surface.done

	move.b	24(a4,d3.w),right.side.flag
	move.l	d0,(a1)+
	bra	now.draw.surface


closest.section
	move.l	4(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.closest.right.side

	move.b	4(a4,d3.w),right.side.flag
	move.l	d0,(a1)+

no.closest.right.side
	move.l	-4(a1),a5
	move.b	right.side.flag,d0
	jsr	get.coord.pair
	move.w	d6,-(sp)
	move.w	d7,d5

	move.l	(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	no.closest.left.side

	move.b	(a4,d3.w),left.side.flag
	move.l	d0,-(a2)

no.closest.left.side
	move.l	(a2),a5
	move.b	left.side.flag,d0
	jsr	get.coord.pair
	move.w	(sp)+,d0

	jsr	clip.closest.section

	tst.b	closest.section.flag
	bmi	surface.done

now.draw.surface
	andi.l	#$f000000,d4
	bne	surface.done
	jsr	fill.polygon

surface.done
	move.b	#0,drs.flag
	btst	#0,section.flags2
	beq	start.line.done

	jsr	draw.start.line
start.line.done
	rts


****************************************


draw.near.road
	subi.w	#32,road.section.offset
	cmpi.w	#64,road.section.offset
	blt	dnr.end

dnr1	move.l	#section.data,a4
	move.w	road.section.offset,d3

dnr2	subi.w	#32,d3
	beq	dnr3

	tst.b	30(a4,d3.w)
	bmi	dnr2

dnr3	move.w	d3,next.road.section.offset
	cmp.w	dnr.value,d3
	blt	dnr.end

	tst.b	at.side.byte
	bne	dnr.left.side

	jsr	draw.near.left.sides
	jsr	draw.left.side.lines
	jsr	draw.near.right.sides
	jsr	draw.right.side.lines
	jsr	draw.opponent.test1
	jsr	draw.opponent.test2
	jsr	draw.road.surface
	jsr	draw.left.road.lines
	jsr	draw.right.road.lines
	jsr	draw.opponent.test3
	bra	dnr8

dnr.left.side
	tst.b	players.x.offset.from.road.centre
	bpl	dnr.right.side

	jsr	draw.opponent.test1
	jsr	draw.near.right.sides
	jsr	draw.right.side.lines
	jsr	draw.road.surface
	jsr	draw.right.road.lines
	jsr	draw.opponent.test3
	jsr	draw.near.left.sides
	jsr	draw.left.side.lines
	move.w	road.section.offset,d3
	cmp.w	copy.road.section.offset,d3
	beq	dnr4

	tst.b	car.on.chains.countdown
	bne	dnr4

	move.w	road.section.offset,-(sp)
	move.w	copy.road.section.offset,road.section.offset
	jsr	draw.left.road.lines
	move.w	(sp)+,road.section.offset
	bra	dnr5

dnr4	jsr	draw.left.road.lines
dnr5	jsr	draw.opponent.test2
	bra	dnr8

dnr.right.side
	jsr	draw.opponent.test2
	jsr	draw.near.left.sides
	jsr	draw.left.side.lines
	jsr	draw.road.surface
	jsr	draw.left.road.lines
	jsr	draw.opponent.test3
	jsr	draw.near.right.sides
	jsr	draw.right.side.lines
	move.w	road.section.offset,d3
	cmp.w	copy.road.section.offset,d3
	beq	dnr6

	tst.b	car.on.chains.countdown
	bne	dnr6

	move.w	road.section.offset,-(sp)
	move.w	copy.road.section.offset,road.section.offset
	jsr	draw.right.road.lines
	move.w	(sp)+,road.section.offset
	bra	dnr7

dnr6	jsr	draw.right.road.lines
dnr7	jsr	draw.opponent.test1

dnr8	move.w	next.road.section.offset,road.section.offset
	bne	dnr1
dnr.end	rts


****************************************


draw.far.road
	subi.w	#32,road.section.offset
	move.w	road.section.offset,d3
	cmp.w	far.road.limit,d3
	blt	dfr.end

	subi.w	#32,d3
	move.w	d3,next.road.section.offset
	tst.b	at.side.byte
	bne	dfr.left.side

	jsr	draw.far.left.sides
	jsr	draw.far.right.sides
	jsr	draw.opponent.test1
	jsr	draw.opponent.test2
	jsr	draw.road.surface
	jsr	draw.opponent.test3
	bra	dfr.next

dfr.left.side
	tst.b	players.x.offset.from.road.centre
	bpl	dfr.right.side

	jsr	draw.opponent.test1
	jsr	draw.far.right.sides
	jsr	draw.road.surface
	jsr	draw.opponent.test3
	jsr	draw.far.left.sides
	jsr	draw.opponent.test2
	bra	dfr.next

dfr.right.side
	jsr	draw.opponent.test2
	jsr	draw.far.left.sides
	jsr	draw.road.surface
	jsr	draw.opponent.test3
	jsr	draw.far.right.sides
	jsr	draw.opponent.test1
dfr.next
	bra	draw.far.road
dfr.end	rts


draw.opponent.test1
	tst.b	opponent.draw.flag
	beq	dot2
	bpl	dot1
	rts

draw.opponent.test2
	tst.b	opponent.draw.flag
	bmi	dot1
	rts

draw.opponent.test3
	tst.b	opponent.draw.flag
	bne	dot2

dot1	move.w	next.road.section.offset,d3
	cmp.w	opponents.offset,d3
	bgt	dot2

	jsr	draw.opponent
	move.w	#-1,opponents.offset
dot2	rts


sides.colour	dc.b	10
side.lines.colour	dc.b	9


****************************************


draw.far.right.sides
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.b	#SIDES.COLOURA,d7
	btst	#0,28(a4,d3.w)
	beq	dfrs.col.set
	move.b	sides.colour,d7

dfrs.col.set
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	12(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfrs

	move.l	d0,a0
	move.l	-12(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfrs

	move.l	d0,a1
	move.l	4(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfrs

	move.l	d0,a2
	move.l	20(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfrs

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	end.dfrs

	move.b	d7,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set2
	not.w	d6
mask1.set2
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set2
	not.w	d6
mask2.set2
	lsr.b	#1,d0
	bcc	mask3.set2
	not.w	d7
mask3.set2
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set2
	not.w	d7
mask4.set2
	jsr	simple.poly.fill
end.dfrs
	rts


****************************************


draw.far.left.sides
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.b	#SIDES.COLOURA,d7
	btst	#0,28(a4,d3.w)
	beq	dfls.col.set
	move.b	sides.colour,d7

dfls.col.set
	move.l	#section.data,a4
	move.w	road.section.offset,d3
	move.l	8(a4,d3.w),d0
	move.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfls

	move.l	d0,a0
	move.l	16(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfls

	move.l	d0,a1
	move.l	(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfls

	move.l	d0,a2
	move.l	-16(a4,d3.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	end.dfls

	move.l	d0,a3
	andi.l	#$f000000,d4
	bne	end.dfls

	move.b	d7,d0
	move.b	d0,d6
	asl.b	#4,d6
	addq.b	#2,d6
	move.b	d6,word.col+3

	clr.l	d6
	clr.l	d7
	lsr.b	#1,d0
	bcc	mask1.set3
	not.w	d6
mask1.set3
	swap	d6
	lsr.b	#1,d0
	bcc	mask2.set3
	not.w	d6
mask2.set3
	lsr.b	#1,d0
	bcc	mask3.set3
	not.w	d7
mask3.set3
	swap	d7
	lsr.b	#1,d0
	bcc	mask4.set3
	not.w	d7
mask4.set3
	jsr	simple.poly.fill
end.dfls
	rts


far.road.limit	dc.w	0


****************************************


plot.line
	cmpi.w	#128,2(a3)
	bcc	pl16

	move.l	a3,a2
	add.l	#8,a3
	move.w	(a2),d5
	subq.w	#1,d5
	move.w	4(a2),d4
	beq	pl5

	cmpi.w	#256,d4
	bge	pl1

	move.w	(a3)+,d6
	bpl	pl6

	move.w	6(a2),d6
	bra	pl6

pl1	bne	pl16

	subq.w	#1,d4
	bra	pl3

pl2	subq.w	#1,d5
pl3	move.w	(a3)+,d6
	cmpi.w	#256,d6
	beq	pl2

	tst.w	d6
	bpl	pl6

	move.w	6(a2),d6
	cmpi.w	#256,d6
	beq	pl16
	bra	pl6

pl4	subq.w	#1,d5
pl5	move.w	(a3)+,d6
	beq	pl4
	bpl	pl6

	move.w	6(a2),d6
	beq	pl16

pl6	cmpi.w	#128,d5
	bcc	pl16

	cmpi.w	#256,d4
	bcc	pl16

	sub.l	#2,a3
	move.w	4(a2),d0
	sub.w	6(a2),d0
	bmi	ple

	move.l	current.scene,a0
	move.w	d4,d0
	ext.l	d0
	ext.l	d5
	lsr.l	#3,d0
	andi.b	#$fe,d0
	add.l	d0,a0
	move.l	d5,d0
	asl.l	#2,d0
	add.l	d5,d0
	asl.l	#3,d0
	add.l	d0,a0
	move.b	#0,d2
	move.w	(a3)+,d6
	bpl	pl7

	tst.b	d2
	bmi	pld

	move.b	#$80,d2
	sub.l	#2,a3
	move.w	6(a2),d6
pl7	bne	pl8

	move.w	#$ffff,d6

pl8	jsr	plot.pixel

	cmp.w	d4,d6
	bne	plb

	move.w	(a3)+,d6
	bpl	pl9

	tst.b	d2
	bmi	pld

	move.b	#$80,d2
	sub.l	#2,a3
	move.w	6(a2),d6
pl9	bne	pla

	move.w	#$ffff,d6

pla	subq.w	#1,d5
	bmi	pl16

	sub.l	#40,a0
	cmp.w	d4,d6
	beq	pl8

plb	move.w	d4,d0
	subq.w	#1,d4
	andi.w	#$f,d0
	bne	plc

	tst.w	d4
	bmi	pl16

	sub.l	#2,a0
plc	bra	pl8
pld	rts

ple	move.l	current.scene,a0
	move.w	d4,d0
	ext.l	d0
	ext.l	d5
	lsr.l	#3,d0
	andi.b	#$fe,d0
	add.l	d0,a0
	move.l	d5,d0
	asl.l	#2,d0
	add.l	d5,d0
	asl.l	#3,d0
	add.l	d0,a0
	move.b	#0,d2
	move.w	(a3)+,d6
	bpl	plf

	tst.b	d2
	bmi	pl15

	move.b	#$80,d2
	sub.l	#2,a3
	move.w	6(a2),d6
plf	bne	pl10

	move.w	#$ffff,d6

pl10	jsr	plot.pixel

	cmp.w	d4,d6
	bne	pl13

	move.w	(a3)+,d6
	bpl	pl11

	tst.b	d2
	bmi	pl15

	move.b	#$80,d2
	sub.l	#2,a3
	move.w	6(a2),d6
pl11	bne	pl12

	move.w	#$ffff,d6

pl12	subq.w	#1,d5
	bmi	pl16

	sub.l	#40,a0
	cmp.w	d4,d6
	beq	pl10

pl13	addq.w	#1,d4
	move.w	d4,d0
	andi.w	#$f,d0
	bne	pl14

	cmp.w	#256,d4
	bge	pl16

	add.l	#2,a0
pl14	bra	pl10
pl15	rts
pl16	rts


****************************************


sort.three.edges
	move.w	(a0),d0
	cmp.w	(a2),d0
	beq	ste2

	cmp.w	(a1),d0
	beq	ste1

	move.l	a1,a3
	move.l	a0,a1
	exg	a0,a2
	bra	ste3

ste1	move.l	a0,a3
	move.l	a1,a0
	move.l	a2,a1
	bra	ste3

ste2	move.l	a2,a3
	move.l	a1,a2
ste3	move.b	#1,simple.poly.count
	bra	simple.poly.fill2


****************************************


draw.mountains
	move.w	y.shift,d0
	asr.w	#3,d0
	neg.w	d0
	move.w	d0,mountain.y.offset

	move.l	#mountain.positions,a0
	move.b	players.y.angle,d6
	subi.b	#28,d6
	move.b	#44,d7
	move.b	mountain.count,d1
	subq.b	#1,d1

dm1	move.b	(a0,d1.w),d0
	sub.b	d6,d0
	cmp.b	d7,d0
	bcc	dmA

	movem.l	d1/d6-a0,-(sp)
	subi.b	#28,d0
	asl.w	#8,d0
	clr.w	d3
	move.b	players.y.angle+1,d3
	andi.b	#$fe,d3
	sub.w	d3,d0
	asr.w	#3,d0
	move.w	d0,mountain.x.offset
	clr.w	d0
	move.l	#mountain.numbers,a0
	move.b	(a0,d1.w),d0
	asl.w	#3,d0
	move.l	#mountain.table,a0
	move.l	(a0,d0.w),a6
	move.l	4(a0,d0.w),a2
	move.w	(a6)+,d6
	subq.w	#1,d6
	move.b	d6,d1
	asl.b	#1,d1
	move.l	#x.values,a4
	move.l	#y.values,a5
	move.w	mountain.x.offset,d4
	move.w	mountain.y.offset,d5

dm2	move.w	(a6)+,d0
	bpl	dm3
	move.w	(a2)+,d0

dm3	add.w	d4,d0
	move.w	d0,(a4)+

	move.w	(a6)+,d0
	bpl	dm4
	move.w	(a2)+,d0

dm4	sub.w	d5,d0
	neg.w	d0
	move.w	d0,(a5)+
	dbra	d6,dm2

	move.l	a6,-(sp)
	move.l	#sin.cos.values,a3
	move.l	#x.values,a5
	move.l	#y.values,a4

dm5	jsr	z.rotate1
	subq.b	#2,d1
	bpl	dm5

	move.l	(sp)+,a6
	move.w	#0,road.section.offset
	move.b	(a6)+,mountain.total.edges

dm6	move.b	(a6)+,d1
	move.b	(a6)+,d2
	move.l	a6,-(sp)
	jsr	clip.line.make.edge
	move.l	(sp)+,a6
	addq.w	#4,road.section.offset
	subq.b	#1,mountain.total.edges
	bne	dm6

	move.b	(a6)+,mountain.poly.count

dm7	move.l	#section.data,a5
	move.b	(a6)+,d0
	jsr	make.masks
	move.b	(a6)+,mountain.poly.edges
	move.l	#$ffffffff,d4

	move.b	(a6)+,d2
	move.l	(a5,d2.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dm9
	move.l	d0,a0

	move.b	(a6)+,d2
	move.l	(a5,d2.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dm9
	move.l	d0,a1

	move.b	(a6)+,d2
	move.l	(a5,d2.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dm9
	move.l	d0,a2

	cmpi.b	#3,mountain.poly.edges
	bne	dm8

	andi.l	#$f000000,d4
	bne	dm9

	move.l	a6,-(sp)
	jsr	sort.three.edges
	move.l	(sp)+,a6
	bra	dm9

dm8	move.b	(a6)+,d2
	move.l	(a5,d2.w),d0
	and.l	d0,d4
	andi.l	#$ffffff,d0
	beq	dm9
	move.l	d0,a3

	andi.l	#$f000000,d4
	bne	dm9

	move.l	a6,-(sp)
	jsr	simple.poly.fill
	move.l	(sp)+,a6

dm9	subq.b	#1,mountain.poly.count
	bne	dm7

	movem.l	(sp)+,d1/d6-a0
dmA	subq.b	#1,d1
	bpl	dm1
	rts


****************************************


initialise.mountains
	move.b	road.ID,d1
	move.b	#0,d1
	move.l	#mountain.table2,a1
	asl.b	#2,d1
	move.l	(a1,d1.w),a2
	move.b	(a2)+,d3
	move.b	d3,mountain.count

	move.l	#mountain.positions,a0
	move.l	#mountain.numbers,a1
	move.w	#0,d1

.copy	move.b	(a2)+,(a0)+
	move.b	(a2)+,(a1)+
	subq.b	#1,d3
	bne	.copy
	rts


mountain.positions
	ds.b	48

mountain.numbers
	ds.b	48

mountain.poly.edges
	dc.b	0
mountain.total.edges
	dc.b	0
mountain.poly.count
	dc.b	0
mountain.count
	dc.b	0
mountain.x.offset
	dc.w	0
mountain.y.offset
	dc.w	0


standard
	dc.w	4
	dc.w	0,0,$80c8,0,$804b,$8019,$8078,$801e
	dc.b	4
	dc.b	0,2,0,4,4,6,2,6
	dc.b	1

	dc.b	5
	dc.b	4
	dc.b	0,4,8,12

taller	dc.w	4
	dc.w	0,0,$80c8,0,$80fa,0,$8050,$801e
	dc.b	5
	dc.b	0,2,2,4,0,6,2,6,4,6
	dc.b	2

	dc.b	4
	dc.b	3
	dc.b	0,8,12

	dc.b	5
	dc.b	3
	dc.b	4,12,16

snow.capped
	dc.w	7
	dc.w	0,0,$81f4,0,$8348,0,$84a6,0,$8302,$805c
	dc.w	$8230,$8069,$833e,$80e6
	dc.b	10
	dc.b	0,2,2,4,4,6,0,10,2,8,4,8,6,12,8,10,10,12,8,12
	dc.b	4

	dc.b	4
	dc.b	4
	dc.b	0,12,28,16

	dc.b	5
	dc.b	3
	dc.b	4,16,20

	dc.b	5
	dc.b	4
	dc.b	8,20,36,24

	dc.b	15
	dc.b	3
	dc.b	28,32,36

buildings
	dc.w	6
	dc.w	0,0,$805a,0,$808c,0,0,$8140,$805a,$8140,$808c,$8140
	dc.b	7
	dc.b	0,2,2,4,0,6,2,8,4,10,6,8,8,10
	dc.b	2

	dc.b	15
	dc.b	4
	dc.b	0,8,20,12

	dc.b	14
	dc.b	4
	dc.b	4,12,24,16

lake	dc.w	4
	dc.w	0,8,$32,0,$28a,0,$2bc,8
	dc.b	4
	dc.b	2,4,0,2,0,6,4,6
	dc.b	1

	dc.b	6
	dc.b	4
	dc.b	0,4,8,12

sm1	dc.w	$180,$4b,$1c,$104,$10
sm2	dc.w	$100,$7d,$12,$c0,$1e
sm3	dc.w	$180,$64,$14,$136,$25
sm4	dc.w	$100,$46,$18,$d8,$24
sm5	dc.w	$180,$c8,$27,$f0,$1f
sm6	dc.w	$100,$32,$c,$a8,$1a
sm7	dc.w	$172,$70,$19,$e6,$14
sm8	dc.w	$fa,$64,$c,$bb,$12
sm9	dc.w	$180,$c6,$1c,$13b,$18
smA	dc.w	$100,$23,$28,$6e,$37
smB	dc.w	$159,$5c,$2a,$f0,$1e
smC	dc.w	$fa,$2d,$f,$80,$b
smD	dc.w	$17c,$88,$2b,$d2,$23
smE	dc.w	$100,$4b,$29,$9b,$37

	dc.w	$64,$19a,$fa,$2d,$4b,$23f,$aa,$2d
	dc.w	$b9,$145,$7d,$46,$32,$12c,$a5,$15

scm1	dc.w	$fa,$1a4,$253,$181,$2e,$118,$34,$19f,$73
scm2	dc.w	$4b,$127,$1f4,$af,$32,$87,$3c,$ff,$48
scm3	dc.w	$87,$c5,$fa,$96,$46,$69,$50,$aa,$5f
scm4	dc.w	$87,$113,$1a9,$91,$2a,$3c,$32,$8c,$4d

bm1	dc.w	$10,$18,$50,$10,$50,$18,$50
bm2	dc.w	$10,$18,$3c,$10,$3c,$18,$3c
bm3	dc.w	$28,$3c,$39,$28,$39,$3c,$39
bm4	dc.w	$69,$7d,$2a,$69,$2a,$7d,$2a

lm	dc.w	0

mountain.table
	dc.l	standard,sm1
	dc.l	standard,sm2
	dc.l	standard,sm3
	dc.l	standard,sm4
	dc.l	standard,sm5
	dc.l	standard,sm6
	dc.l	standard,sm7
	dc.l	standard,sm8
	dc.l	standard,sm9
	dc.l	standard,smA
	dc.l	standard,smB
	dc.l	standard,smC
	dc.l	standard,smD
	dc.l	standard,smE
	dc.l	taller,smD
	dc.l	taller,smE
	dc.l	snow.capped,scm1
	dc.l	snow.capped,scm2
	dc.l	snow.capped,scm3
	dc.l	snow.capped,scm4
	dc.l	buildings,bm1
	dc.l	buildings,bm2
	dc.l	buildings,bm3
	dc.l	buildings,bm4
	dc.l	lake,lm

mountain.table2
	dc.l	positions.and.numbers,positions.and.numbers

positions.and.numbers
	dc.b	32
	dc.b	$05,0,$0f,13,$15,10,$1f,11,$25,12,$2f,5,$35,2,$3f,3
	dc.b	$45,0,$4f,1,$55,4,$5f,5,$65,2,$6f,1,$75,0,$7f,5
	dc.b	$85,2,$8f,3,$95,4,$9f,5,$a5,0,$af,9,$b5,6,$bf,7
	dc.b	$c5,8,$cf,5,$d5,0,$df,3,$e5,4,$ef,1,$f5,2,$ff,5
	dc.b	0

fp.level	dc.b	0,0
bottom.ptrs.offset	dc.w	0
fp.y.flag	dc.w	0
fp.ptr1	dc.l	0
fp.ptr2	dc.l	0
yellow.road.lines	dc.b	0,0
pit.and.start.byte	dc.b	0,0
closest.section.flag	dc.b	0,0
left.side.flag	dc.b	0,0
	dc.w	0
right.side.flag	dc.b	0,0
	dc.w	0
next.road.section.offset	dc.w	0
copy.road.section.offset	dc.w	0
start.line.flag	dc.b	0,0
fp.colour	dc.b	0,0
	dc.w	0
fp.start	dc.l	0
fp.end	dc.l	0
fp.diff	dc.l	0

	ds.l	32
section.side.ptrs
	ds.l	32

bottom.ptrs
	ds.l	64


R.69cfc	move.l	#cbits,a1
	move.w	#0,d4

.label1	jsr	R.69d4e
	addq.w	#1,d4
	cmpi.w	#10,d4
	bne	.label2
	move.w	#15,d4

.label2	cmpi.w	#52,d4
	bne	.label1

	move.l	a1,-(sp)
	move.l	#car.crunched,a0
	move.l	#screen1.space+34,a1
	jsr	R.59450
	move.l	(sp)+,a1
	move.w	#10,d4

.label3	jsr	R.69d4e
	addq.w	#1,d4
	cmpi.w	#15,d4
	bne	.label3
	rts


R.69d4e	clr.b	B.69f40
	cmpi.w	#37,d4
	blt	.label1
	cmpi.w	#48,d4
	bgt	.label1
	move.b	#$80,B.69f40

.label1	move.w	d4,d0
	asl.w	#2,d0
	move.l	#graphic.pointers,a5
	move.l	a1,(a5,d0.w)
	asl.w	#2,d0
	move.l	#graphic.info,a3
	lea	(a3,d0.w),a3
	move.w	(a3)+,d1
	move.w	(a3)+,d2
	move.l	#screen1.space+34,a4
	andi.l	#$ff,d1
	andi.l	#$ff,d2
	asl.l	#3,d1
	add.l	d1,a4
	move.l	d2,d1
	asl.l	#2,d1
	add.l	d1,d2
	asl.l	#5,d2
	add.l	d2,a4
	move.w	(a3)+,d1
	move.w	(a3)+,d2
	tst.b	B.69f40
	beq	.label2
	jmp	R.69e30

.label2	move.w	d1,d3
	move.l	a4,a2

.label3	move.l	(a4)+,d6
	move.l	(a4)+,d7
	clr.l	d5
	move.l	#15,d0

.label4	move.b	#0,d5
	btst	d0,d6
	beq	.label5
	bset	#1,d5

.label5	btst	d0,d7
	beq	.label6
	bset	#3,d5

.label6	bset	#4,d0
	btst	d0,d6
	beq	.label7
	bset	#0,d5

.label7	btst	d0,d7
	beq	.label8
	bset	#2,d5

.label8	cmpi.b	#1,d5
	bne	.label9
	bset	d0,d5

.label9	bclr	#4,d0
	dbra	d0,.label4

	move.l	d5,d0
	swap	d5
	move.w	d5,d0
	move.w	d0,(a1)+
	not.l	d0
	and.l	d0,d6
	move.l	d6,(a1)+
	and.l	d0,d7
	move.l	d7,(a1)+
	dbra	d3,.label3

	lea	160(a2),a4
	dbra	d2,.label2
	rts


R.69e30	move.w	d2,d6
	move.w	(a3),d0
	asl.w	#4,d0
	addi.w	#128,d0
	move.w	2(a3),d3
	add.w	hardware.start,d3
	add.w	d3,d6
	asl.l	#8,d3
	asl.l	#8,d6
	move.w	d0,d1
	lsr.w	#1,d1
	move.b	d1,d3
	move.w	d3,(a1)+
	move.w	d6,d1
	btst	#16,d3
	beq	.label1
	bset	#2,d1

.label1	btst	#16,d6
	beq	.label2
	bset	#1,d1

.label2	btst	#0,d0
	beq	.label3
	bset	#0,d1

.label3	move.w	d1,(a1)+

.label4	move.w	(a4),d0
	eori.w	#$ffff,d0
	move.w	d0,(a1)+
	move.w	4(a4),(a1)+
	lea	160(a4),a4
	dbra	d2,.label4

	move.l	#0,(a1)+
	clr.w	d1
	clr.w	d2
	rts


****************************************


set.sprite.colours
	move.l	#colour16+2,a0
	move.l	#sprite.colours,a1
	move.w	#8-1,d0
.set.cols
	move.w	(a1)+,(a0)+
	addq.l	#2,a0
	dbra	d0,.set.cols
	rts


sprite.colours
	dc.w	$000,$000,$fff,$c88,000,$000,$fff,$c88


hardware.start	dc.w	$3c


****************************************


set.blank.sprites
	move.w	#8-1,d3
.next	move.w	d3,d1
	move.l	#blank.sprite.data,d0
	jsr	set.sprite.copper
	dbra	d3,.next
	rts


sprite.DMA.value	dc.w	$0020


****************************************


set.sprite.pointers
	move.l	#graphic.pointers,a1
	andi.w	#$ff,d0
	asl.w	#2,d0
	move.l	(a1,d0.w),d0
set.sprite.copper
	move.l	#sprite0+2,a0
	asl.w	#3,d1
	move.w	d0,4(a0,d1.w)
	swap	d0
	move.w	d0,(a0,d1.w)
	rts


****************************************


update.sprites
	move.w	#37*4,d1

us1	move.l	#graphic.pointers,a0
	move.l	(a0,d1.w),a0

	move.w	d1,d0
	asl.w	#2,d0
	move.l	#graphic.info,a1
	move.w	10(a1,d0.w),d0		get y position

	add.w	hardware.start,d0
	move.b	2(a0),d3
	sub.b	(a0),d3
	move.b	d0,(a0)
	add.b	d3,d0
	move.b	d0,2(a0)

	addq.w	#4,d1
	cmpi.w	#49*4,d1
	bne	us1
	rts


B.69f40	dc.b	0
adjust.sprites	dc.b	0


****************************************


copy.graphic
	move.l	d5,-(sp)
	move.w	d1,-(sp)
	movem.l	a4-a6,-(sp)
	andi.w	#$ff,d0
	asl.w	#2,d0
	move.l	#graphic.pointers,a1
	move.l	(a1,d0.w),a1		get source pointer

	asl.w	#2,d0
	move.l	#graphic.info,a2
	lea	4(a2,d0.w),a2

	move.w	4(a2),d0		get x word position
	move.w	6(a2),d3		get y position
	move.l	screen2,a0
	andi.l	#$ff,d0
	andi.l	#$ff,d3
	asl.l	#1,d0
	add.l	d0,a0

	move.l	d3,d0
	asl.l	#2,d0
	add.l	d0,d3
	asl.l	#3,d3
	add.l	d3,a0

	lea	8000(a0),a4
	lea	16000(a0),a5
	lea	24000(a0),a6
	move.w	(a2),d1			get width count
	move.w	2(a2),d4		get height count
copy.line
	move.l	a0,a2
	move.w	d1,d3
copy.word
	move.w	(a1)+,d5		get mask word

	move.w	(a0),d0
	and.w	d5,d0
	or.w	(a1)+,d0
	move.w	d0,(a0)+

	move.w	(a4),d0
	and.w	d5,d0
	or.w	(a1)+,d0
	move.w	d0,(a4)+

	move.w	(a5),d0
	and.w	d5,d0
	or.w	(a1)+,d0
	move.w	d0,(a5)+

	move.w	(a6),d0
	and.w	d5,d0
	or.w	(a1)+,d0
	move.w	d0,(a6)+

	dbra	d3,copy.word

	lea	40(a2),a0
	lea	8040(a2),a4
	lea	16040(a2),a5
	lea	24040(a2),a6
	dbra	d4,copy.line

	movem.l	(sp)+,a4-a6
	move.w	(sp)+,d1
	move.l	(sp)+,d5
	rts


draw.spark.sub2.sub
	move.w	(a1)+,d0
	swap	d0
	move.w	#$ffff,d0
	ror.l	d3,d0
	move.l	d0,d6
	swap	d0
	move.w	d0,d6
	move.l	d0,d7
	swap	d0
	move.w	d0,d7
	move.l	d7,-(sp)

	move.l	(a1)+,d0
	move.l	d0,d7
	clr.w	d0
	swap	d7
	clr.w	d7
	lsr.l	d3,d0
	lsr.l	d3,d7
	move.l	d0,d4
	swap	d7
	move.w	d7,d4
	move.w	d0,d7
	swap	d7
	move.l	d7,-(sp)

	move.l	(a1)+,d0
	move.l	d0,d7
	clr.w	d0
	swap	d7
	clr.w	d7
	lsr.l	d3,d0
	lsr.l	d3,d7
	move.l	d0,d5
	swap	d7
	move.w	d7,d5
	move.w	d0,d7
	swap	d7
	cmpi.w	#16,W.6a168
	bcc	dspks2s1

	move.w	(a0),d0
	swap	d0
	move.w	8000(a0),d0
	and.l	d6,d0
	or.l	d4,d0
	move.w	d0,8000(a0)
	swap	d0
	move.w	d0,(a0)+

	move.w	15998(a0),d0
	swap	d0
	move.w	23998(a0),d0
	and.l	d6,d0
	or.l	d5,d0
	move.w	d0,23998(a0)
	swap	d0
	move.w	d0,15998(a0)
	bra	dspks2s2

dspks2s1
	add.l	#2,a0
dspks2s2
	move.l	(sp)+,d4
	move.l	(sp)+,d6
	addq.w	#1,W.6a168
	cmpi.w	#16,W.6a168
	bcc	dspks2s3

	move.w	(a0),d0
	swap	d0
	move.w	8000(a0),d0
	and.l	d6,d0
	or.l	d4,d0
	move.w	d0,8000(a0)
	swap	d0
	move.w	d0,(a0)

	move.w	16000(a0),d0
	swap	d0
	move.w	24000(a0),d0
	and.l	d6,d0
	or.l	d7,d0
	move.w	d0,24000(a0)
	swap	d0
	move.w	d0,16000(a0)

dspks2s3
	subq.w	#1,W.6a168
	rts


draw.spark.sub2
	move.w	d1,-(sp)
	move.w	d2,-(sp)
	andi.w	#$ff,d0
	asl.w	#2,d0
	move.l	#graphic.pointers,a1
	move.l	(a1,d0.w),a1

	asl.w	#2,d0
	move.l	#graphic.info,a2
	lea	4(a2,d0.w),a2

	move.l	screen2,a0
	move.w	d4,d0
	ext.l	d0
	ext.l	d5
	lsr.l	#3,d0
	andi.b	#$fe,d0
	add.l	d0,a0
	move.l	d5,d0
	asl.l	#2,d0
	add.l	d5,d0
	asl.l	#3,d0
	add.l	d0,a0
	move.w	(a2),a6
	move.w	2(a2),d2
	move.w	d4,d3
	andi.l	#$f,d3
	move.w	d4,d0
	asr.w	#4,d0
	subq.w	#2,d0
	move.w	d0,W.6a166
	move.w	d0,W.6a168
	move.w	d5,d0
	subi.w	#16,d0
	move.w	d0,W.6a16a

dspks21	move.l	a0,a2
	move.w	a6,d1
	cmpi.w	#128,W.6a16a
	bcc	dspks23

dspks22	jsr	draw.spark.sub2.sub
	addq.w	#1,W.6a168
	dbra	d1,dspks22

dspks23	move.w	W.6a166,W.6a168
	lea	40(a2),a0
	addq.w	#1,W.6a16a
	dbra	d2,dspks21

	move.w	(sp)+,d2
	move.w	(sp)+,d1
	rts


W.6a166	dc.w	0
W.6a168	dc.w	0
W.6a16a	dc.w	0


graphic.info

*	Word 1  --  not used
*	Word 2  --  not used
*	Word 3  --  number of words wide - 1
*	Word 4  --  number of lines high - 1
*	Word 5  --  x position in words
*	Word 6  --  y position
*	Word 7  --  not used
*	Word 8  --  not used

	dc.w	0,0,1,57,16,119,0,0	right wheels
	dc.w	2,0,1,57,16,119,0,0
	dc.w	4,0,1,57,16,119,0,0

	dc.w	8,0,1,57,2,119,0,0	left wheels
	dc.w	10,0,1,57,2,119,0,0
	dc.w	12,0,1,57,2,119,0,0

	dc.w	0,68,3,27,2,123,0,0	left flames
	dc.w	4,68,3,27,2,123,0,0

	dc.w	8,68,3,27,14,123,0,0	right flames
	dc.w	12,68,3,27,14,123,0,0

	dc.w	2,123,15,20,2,123,0,0	engine block

	dc.w	2,144,1,14,2,144,0,0	left / right exhaust covering wheel
	dc.w	16,144,1,14,16,144,0,0

	dc.w	2,16,0,5,2,16,0,0	left / right top corner
	dc.w	17,16,0,5,17,16,0,0

	dc.w	14,0,0,7,6,190,0,0	chequered flag bright / dull
	dc.w	14,8,0,7,6,190,0,0

	dc.w	14,16,0,7,13,190,0,0	stop watch bright / dull
	dc.w	14,24,0,7,13,190,0,0

	dc.w	15,0,0,7,4,16,0,0	left chain top / bottom
	dc.w	15,8,0,7,4,24,0,0

	dc.w	15,16,0,7,15,16,0,0	right chain top / bottom
	dc.w	15,24,0,7,15,24,0,0

	dc.w	16,0,1,7,4,0,0,0	hole position 1 / 2
	dc.w	16,8,1,7,4,0,0,0

	dc.w	16,16,1,7,4,0,0,0	smash position 1 / 2
	dc.w	16,24,1,7,4,0,0,0

	dc.w	16,32,1,7,4,0,0,0	damage bar clear position 1 / 2
	dc.w	16,40,1,7,4,0,0,0

	dc.w	0,96,3,33,0,0,0,0	dust clouds
	dc.w	5,96,3,30,0,0,0,0
	dc.w	9,96,3,37,0,0,0,0
	dc.w	13,96,4,35,0,0,0,0
	dc.w	0,134,2,27,0,0,0,0
	dc.w	3,134,3,33,0,0,0,0
	dc.w	7,134,3,33,0,0,0,0
	dc.w	11,134,3,35,0,0,0,0

	dc.w	1,176,0,15,17,119,0,0	sprites
	dc.w	3,176,0,15,17,119,0,0
	dc.w	5,176,0,15,17,119,0,0
	dc.w	8,176,0,15,2,119,0,0
	dc.w	10,176,0,15,2,119,0,0
	dc.w	12,176,0,15,2,119,0,0
	dc.w	0,176,0,15,17,119,0,0
	dc.w	2,176,0,15,17,119,0,0
	dc.w	4,176,0,15,17,119,0,0
	dc.w	7,176,0,15,2,119,0,0
	dc.w	9,176,0,15,2,119,0,0
	dc.w	11,176,0,15,2,119,0,0

	dc.w	16,68,3,27,2,123,0,0	left flame

	dc.w	16,172,3,27,14,123,0,0	right flame

	dc.w	16,134,3,27,8,27,0,0	message panel


graphic.pointers
	dc.l	cbits,cbits+1160,cbits+2320,cbits+3480
	dc.l	cbits+4640,cbits+5800,cbits+6960,cbits+8080
	dc.l	cbits+9200,cbits+10320,cbits+28184,cbits+31544
	dc.l	cbits+31844,cbits+32144,cbits+32204,cbits+11440
	dc.l	cbits+11520,cbits+11600,cbits+11680,cbits+11760
	dc.l	cbits+11840,cbits+11920,cbits+12000,cbits+12080
	dc.l	cbits+12240,cbits+12400,cbits+12560,cbits+12720
	dc.l	cbits+12880,cbits+13040,cbits+14400,cbits+15640
	dc.l	cbits+17160,cbits+18960,cbits+19800,cbits+21160
	dc.l	cbits+22520

	dc.l	cbits+23960,cbits+24032,cbits+24104,cbits+24176
	dc.l	cbits+24248,cbits+24320,cbits+24392,cbits+24464
	dc.l	cbits+24536,cbits+24608,cbits+24680,cbits+24752

	dc.l	cbits+24824,cbits+25944,cbits+27064
	dc.l	0,0


screen.mem	dc.l	screen1.space
screen1	dc.l	screen2.space
screen2	dc.l	screen1.space
current.scene	dc.l	screen1.space+16*40+4

screen1.space
	ds.l	8000
screen2.space
	ds.l	8000


	dc.w	$0000,$1fff,$f000,$0000,$0000,$0000,$0000,$1fff
	dc.w	$f000,$0000,$0003,$fff0,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$7fff,$f800,$0000
	dc.w	$0000,$0000,$0000,$7fff,$f800,$0000,$000f,$fff8
	dc.w	$7f00,$3fe1,$fffb,$ffc0,$0000,$0000,$0000,$0000
	dc.w	$0001,$ffff,$ffef,$c7ef,$c3f7,$fffc,$0003,$ffff
	dc.w	$fcff,$f000,$003f,$fffd,$ffc0,$fffb,$ffff,$fff0
	dc.w	$0000,$0000,$0000,$0000,$0003,$ffe0,$cfff,$efff
	dc.w	$e7ff,$ffff,$000f


TAB.7a01a
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0,0,0,0,0


TEXT.7a21a
	dc.b	'DOS',128,'DOS',129,'DOS',130,'DOS',131
	dc.b	'DOS',132,'DOS',133,'DOS',134,'DOS',135
	dc.b	'DOS',136,'DOS',137,'DOS',138,'DOS',139
	dc.b	'DOS',140,'DOS',141,'DOS',142,'DOS',143
	dc.b	'DOS',144,'DOS',145,'DOS',146,'DOS',147
	dc.b	'DOS',148,'DOS',149,'DOS',150,'DOS',151
	dc.b	'DOS',152,'DOS',153,'DOS',154,'DOS',155
	dc.b	'DOS',156,'DOS',157,'DOS',158,'DOS',159
	dc.b	'DOS',160,'DOS',161,'DOS',162,'DOS',163
	dc.b	'DOS',164,'DOS',165,'DOS',166,'DOS',167
	dc.b	'DOS',168,'DOS',169,'DOS',170,'DOS',171
	dc.b	'DOS',172,'DOS',173,'DOS',174,'DOS',175
	dc.b	'DOS',176,'DOS',177,'DOS',178,'DOS',179
	dc.b	'DOS',180,'DOS',181,'DOS',182,'DOS',183
	dc.b	'DOS',184,'DOS',185,'DOS',186,'DOS',187
	dc.b	'DOS',188,'DOS',189,'DOS',190,'DOS',191
	dc.b	'DOS',192,'DOS',193,'DOS',194,'DOS',195
	dc.b	'DOS',196,'DOS',197,'DOS',198,'DOS',199
	dc.b	'DOS',200,'DOS',201,'DOS',202,'DOS',203
	dc.b	'DOS',204,'DOS',205,'DOS',206,'DOS',207
	dc.b	'DOS',208,'DOS',209,'DOS',210,'DOS',211
	dc.b	'DOS',212,'DOS',213,'DOS',214,'DOS',215
	dc.b	'DOS',216,'DOS',217,'DOS',218,'DOS',219
	dc.b	'DOS',220,'DOS',221,'DOS',222,'DOS',223
	dc.b	'DOS',224,'DOS',225,'DOS',226,'DOS',227
	dc.b	'DOS',228,'DOS',229,'DOS',230,'DOS',231
	dc.b	'DOS',232,'DOS',233,'DOS',234,'DOS',235
	dc.b	'DOS',236,'DOS',237,'DOS',238,'DOS',239
	dc.b	'DOS',240,'DOS',241,'DOS',242,'DOS',243
	dc.b	'DOS',244,'DOS',245,'DOS',246,'DOS',247
	dc.b	'DOS',248,'DOS',249,'DOS',250,'DOS',251
	dc.b	'DOS',252,'DOS',253,'DOS',254,'DOS',255


DAT.7a41a
	ds.w	128


DAT.7a51a
	ds.w	128


TEXT.7a61a
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0


TEXT.7a71a
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0
	dc.b	'------------',9,0,0,0


DAT.7a81a
	ds.w	128


opponents.names.source
	dc.b	' Hot Rod      ',13,9
	dc.b	' Whizz Kid    ',9,'T'
	dc.b	' Bad Guy      ',9,'b'
	dc.b	' The Dodger   ',9,'b'
	dc.b	' Big Ed       ',9,'#'
	dc.b	' Max Boost    p1'
	dc.b	' Dare Devil   ',13,9
	dc.b	' High Flyer   .b'
	dc.b	' Bully Boy    ml'
	dc.b	' Jumping Jack ,d'
	dc.b	' Road Hog     b.'
	dc.b	'              ',9,13
	dc.b	9,13,9,13,'GTRACK',13,9,13,9,'mo'
	dc.b	've.b',9,'d1,d0',13,9,'asl.'
	dc.b	'" b >',4,'0',20,'J',16,8,0,'e.b',9
	dc.b	'd0,d2',13,9,'movea.l',9,'#'


far.section.ptrs
	ds.l	80

far.section.flags
	ds.w	64

far.section.coordinates
	ds.w	600


section.data
	ds.l	412

	IFD	RECORD
recording.buffer
	ds.l	1024*60
	ENDC


*""""""""""""""""""""""
*" HARDWARE REGISTERS "
*"		      "
*""""""""""""""""""""""

custom	equ	$dff000
dmaconr	equ	$002
vposr	equ	$004
vhposr	equ	$006
joy0dat	equ	$00a
joy1dat	equ	$00c
clxdat	equ	$00e
adkconr	equ	$010
pot0dat	equ	$012
pot1dat	equ	$014
potgor	equ	$016
serdatr	equ	$018
dskbytr	equ	$01a
intenar	equ	$01c
intreqr	equ	$01e
dskpth	equ	$020
dsklen	equ	$024
copcon	equ	$02e
serdat	equ	$030
serper	equ	$032
potgo	equ	$034
joytest	equ	$036
bltcon0	equ	$040
bltcon1	equ	$042
bltafwm	equ	$044
bltalwm	equ	$046
bltcpth	equ	$048
bltbpth	equ	$04c
bltapth	equ	$050
bltdpth	equ	$054
bltsize	equ	$058
bltcmod	equ	$060
bltbmod	equ	$062
bltamod	equ	$064
bltdmod	equ	$066
bltcdat	equ	$070
bltbdat	equ	$072
bltadat	equ	$074
dsksync	equ	$07e
cop1lch	equ	$080
cop2lch	equ	$084
copjmp1	equ	$088
copjmp2	equ	$08a
diwstrt	equ	$08e
diwstop	equ	$090
ddfstrt	equ	$092
ddfstop	equ	$094
dmacon	equ	$096
clxcon	equ	$098
intena	equ	$09a
intreq	equ	$09c
adkcon	equ	$09e
aud0lch	equ	$0a0
aud0len	equ	$0a4
aud0per	equ	$0a6
aud0vol	equ	$0a8
bpl1pth	equ	$0e0
bpl1ptl	equ	$0e2
bpl2pth	equ	$0e4
bpl2ptl	equ	$0e6
bpl3pth	equ	$0e8
bpl3ptl	equ	$0ea
bpl4pth	equ	$0ec
bpl4ptl	equ	$0ee
bpl5pth	equ	$0f0
bpl5ptl	equ	$0f2
bpl6pth	equ	$0f4
bpl6ptl	equ	$0f6
bplcon0	equ	$100
bplcon1	equ	$102
bplcon2	equ	$104
bpl1mod	equ	$108
bpl2mod	equ	$10a
spr0pth	equ	$120
spr0ptl	equ	$122
spr1pth	equ	$124
spr1ptl	equ	$126
spr2pth	equ	$128
spr2ptl	equ	$12a
spr3pth	equ	$12c
spr3ptl	equ	$12e
spr4pth	equ	$130
spr4ptl	equ	$132
spr5pth	equ	$134
spr5ptl	equ	$136
spr6pth	equ	$138
spr6ptl	equ	$13a
spr7pth	equ	$13c
spr7ptl	equ	$13e

CIAA	equ	$bfe001
CIAB	equ	$bfd000
TBLO	equ	$600			CIA equates
TBHI	equ	$700
KEY	equ	$c00
ICR	equ	$d00
CRA	equ	$e00
CRB	equ	$f00
