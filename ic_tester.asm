org 0h
mov dptr, #instruction
mov P0, #0
mov P3, #11110000b
RS BIT P3.0
init:			// Initialising LCD with set of commands
	clr a
	movc a, @a + dptr
	jz break	// Break the init block and move to jump at the end of command
	clr RS		// Enabling command mode
	acall write	// A subroutine used to write data / command to LCD
	acall delay
	inc dptr
	sjmp init
break:	 		// Changes to display content
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
write:			// Subroutine to write a data/command to LCD
	mov p2, a
	clr p3.1
	setb p3.2
	acall delay
	clr p3.2
	ret
delay:			// subroutine to provide delay
	mov r3, #255
here:
	mov r4, #50 
here2:
	djnz r4, here2
	djnz r3, here
	ret
keypad:		 	// Block that gets the number from keyapd and redirects to the specific IC
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
	setb RS
	acall write
	inc dptr
	sjmp nan
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
	clr RS	   
	mov a, #0C0h
	acall write

	acall delay

	mov dptr, #ic_7400_in

	ljmp testing
num_08:
	clr RS	   
	mov a, #0C0h
	acall write
	acall delay
	mov dptr, #ic_7408_in
	ljmp testing
num_32:
	clr RS	   
	mov a, #0C0h
	acall write
	acall delay
	mov dptr, #ic_7432_in
	ljmp testing
num_86:
	clr RS	   
	mov a, #0C0h
	acall write
	acall delay
	mov dptr, #ic_7486_in
	sjmp testing

// p1.1 - p1.4 is output pin
// p1.5 - p1.7 is  input pin
K1:				// Ensuring no key is pressed at first
	clr p1.1
	clr p1.2
	clr p1.3
	clr p1.4
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, K1

K2:				// Checking whether a key is pressed or not
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, OVER
	sjmp K2


OVER:			// Checking key closure
	mov a, p1
	anl a, #11100000b
	cjne a, #11100000b, OVER1
	sjmp K2
OVER1:			// Finding which row the key is pressed
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
find:	   		// Finding which colum the key is pressed
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
	mov r0, #5
pin_loc:
	dec r0
	cjne r0, #0, exit
	sjmp stay_here
exit:
	rlc a
	jnc pin_loc 
	SETB RS		
	cjne r0, #4, pin_3
	mov dptr, #error4
	acall loop
	sjmp pin_loc
pin_3:
	cjne r0, #3, pin_2	
	mov dptr, #error3
	acall loop
	sjmp pin_loc
pin_2:
	cjne r0, #2, pin_1
	mov dptr, #error2
	acall loop
	sjmp pin_loc
pin_1:
	mov dptr, #error1
	acall loop
	sjmp pin_loc
loop:
	mov b, a
	clr a
	movc a, @a+dptr
	inc dptr	   
	jz returning   
	setb RS		   
	acall write	   
	acall delay
	mov a, b   
	sjmp loop
returning:
	mov a, b
	ret
stay_here:
	sjmp stay_here

// All defined variables
KROW_0: db '1', '2', '3'
KROW_1: db '4', '5', '6'
KROW_2: db '7', '8', '9'
KROW_3: db '*', '0', '#'
instruction: db 38h, 0eh, 1h, 6h, 0
string: db "Enter the ic number: 74", 0
good:  db "Working good", 0
error1: db "3 F ", 0
error2: db "6 F ", 0
error3: db "10 F ", 0
error4: db "13 F ", 0
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
