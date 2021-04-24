org 0h
mov dptr, #instruction
mov P0, #0
mov P3, #11110000b
RS BIT P3.0
init:
	clr a
	movc a, @a + dptr
	jz break
	clr RS
	acall write
	acall delay
	inc dptr
	sjmp init
break:
	mov dptr, #string
display:
	clr a
	movc a, @a + dptr
	jnz conda
	sjmp keypad
conda: 
	inc dptr
	setb RS					   
	acall write
	acall delay
	sjmp display
write:
	mov p2, a
	clr p3.1
	setb p3.2
	acall delay
	clr p3.2
	ret
delay:
	mov r3, #255
here:
	mov r4, #50 
here2:
	djnz r4, here2
	djnz r3, here
	ret
keypad:
	mov p1, #11100000b
	acall K1
	mov r2, a
	subb a, #'0'
	jz num_0
	mov a, r2
	subb a, #'3'
	jz num_3
	mov a, r2
	subb a, #'8'
	jz num_8
notvalid:
	clr RS
	mov a, #0C0h
	acall write 
	setb RS
	mov dptr, #invalid
nan:
	clr a
	movc a, @a+dptr
	jnz cont
inf_loop:
	sjmp inf_loop
cont:
	acall write
	inc dptr
	sjmp nan
; p1.1 - p1.4 is output pin
; p1.5 - p1.7 is  input pin
;Ensuring no key is pressed at first
num_0:

	acall K1

	mov r2, a

	subb a, #'0'

	jz num_00

	add a, #'0'

	subb a, #'8'

	jz num_08

	sjmp notvalid
num_3:
	acall K1
	mov r2, a
	subb a, #'2'
	jz num_32
	sjmp notvalid
num_8:
	acall K1
	mov r2, a
	subb a, #'6'
	jz num_86
	sjmp notvalid
num_00:

	acall delay

	mov dptr, #ic_7400_in

	ljmp testing
num_08:
	acall delay
	mov dptr, #ic_7408_in
	ljmp testing
num_32:
	acall delay
	mov dptr, #ic_7432_in
	ljmp testing
num_86:
	acall delay
	mov dptr, #ic_7486_in
	sjmp testing

K1:
	clr p1.1
	clr p1.2
	clr p1.3
	clr p1.4
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, K1
;Checking whether a key is pressed or not
K2:
	;acall delay
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, OVER
	sjmp K2
;Checking key closure
OVER:
	;acall delay
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, OVER1
	sjmp K2
OVER1:
	acall sett
	clr p1.4
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, row_0
	
	acall sett
	clr p1.3
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, row_1

	acall sett
	clr p1.2
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, row_2

	acall sett
	clr p1.1
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, row_3
sett:
	setb p1.4
	setb p1.3
	setb p1.2
	setb p1.1
	ret	
row_0:
	mov dptr, #KROW_0
	sjmp find
row_1:
	mov dptr, #KROW_1
	sjmp find
row_2:
	mov dptr, #KROW_2
	sjmp find
row_3:
	mov dptr, #KROW_3
find:
	rlc a
	JNC match
	inc dptr
	sjmp find
match:
	clr a
	movc a, @a+dptr
	setb p3.0
	acall write
	acall delay
	ret

testing:
	acall repeat
	acall loop
	sjmp stay_here
repeat:
	clr a
	movc a, @a+dptr
	mov r7,a
	mov a,#5
	movc a,@a+dptr	
	mov b, a
	mov a,r7	
	cjne a, #'$', normal
	clr RS
	mov a, #0C0h
	acall write 
	setb RS
	mov dptr, #good
	ret
normal:	
	inc dptr	
	mov P0, a
	acall delay
	acall delay
	mov A, P3	
	anl a, #11110000b
	acall delay	
	cjne a, b, fault
	sjmp repeat
fault:
	xrl a, b
	mov r0, #-4
pin_loc:
	inc r0
	rrc a
	jnc pin_loc
	clr RS	   
	mov a, #0C0h
	acall write 
	setb RS		
	cjne r0, #4, pin_3
	mov dptr, #error4
	ret
pin_3:
	cjne r0, #3, pin_2	
	mov dptr, #error3
	ret
pin_2:
	cjne r0, #2, pin_1
	mov dptr, #error2
	ret
pin_1:
	mov dptr, #error1
	ret
loop:
	clr a
	movc a, @a+dptr
	inc dptr	   
	jz returning   
	setb RS		   
	acall write	   
	acall delay	   
	sjmp loop
returning:
	ret
stay_here:
	sjmp stay_here
KROW_0: db '1', '2', '3'
KROW_1: db '4', '5', '6'
KROW_2: db '7', '8', '9'
KROW_3: db '*', '0', '#'
instruction: db 38h, 0eh, 1h, 6h, 0
string: db "Enter the ic number: 74", 0
good:  db "Working good", 0
error1: db "Pin 1 is Faulty", 0
error2: db "Pin 2 is Faulty", 0
error3: db "Pin 3 is Faulty", 0
error4: db "Pin 4 is Faulty", 0
invalid: db "Invalid number", 0
ic_7408_in: db 00000000b, 01010101b, 10101010b, 11111111b, '$'		;AND GATE

ic_7408_ot: db 00000000b, 00000000b, 00000000b, 11110000b, '$'

ic_7432_in: db 00000000b, 01010101b, 10101010b, 11111111b, '$'		;OR GATE

ic_7432_ot: db 00000000b, 11110000b, 11110000b, 11110000b, '$'

ic_7486_in: db 00000000b, 01010101b, 10101010b, 11111111b, '$'		;XOR GATE

ic_7486_ot: db 00000000b, 11110000b, 11110000b, 00000000b, '$'

ic_7400_in: db 00000000b, 01010101b, 10101010b, 11111111b, '$' 		;NAND GATE

ic_7400_ot: db 11110000b, 11110000b, 11110000b, 00000000b, '$'
end