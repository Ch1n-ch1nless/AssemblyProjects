.286	
.model tiny

;+++++++++++++++++++++++++++++++++++++++++++++++
;		    CONSTANTS

VIDEOSEG	equ 0b800h		; address of video segment

SCREEN_WIDTH	equ 0050h		; width of DOS screen
SCREEN_HEIGHT	equ 0018h		; height of DOS screen

X_CNTR		equ SCREEN_WIDTH  / 2	; X-coordinate of frame center
Y_CNTR		equ SCREEN_HEIGHT / 2	; Y-coordinate of frame center

FRAME_WIDTH	equ 0018h		; final width of the frame
FRAME_HEIGHT	equ 0010h		; final height of the frame

FRAME_COLOR	equ 4eh			; color of the frame with registers	
SHADOW_COLOR	equ 18h			; color of frame shadow

LAUNCH_FRAME_SYMBOL	equ 02h		; scan-code of '1'
LAUNCH_CRINGE		equ 36h		; scan-code of 'Right Shift'

HEX_BASE	equ 10h			; 16 = Base of hexadecimal number system

REG_COUNT	equ 13d			; Count of registers, which will be printed

FLAG_OFF	equ 00h			

;+++++++++++++++++++++++++++++++++++++++++++++++

.code

org 100h

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

Start:  	call ChangeInt09
		call ChangeInt08

            	mov ax, 3100h		;<----
            	mov dx, offset EOP	;DX = number of paragraphs, which program will keep
            	shr dx, 4		;Call functions to save code
		inc dx			;---->

            	int 21h
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;===============================================
;		INTERRUPT_FUNCTIONS
;-----------------------------------------------
;Change address of INT09 in int table
;Entry:	none
;Exit:	none
;Dstr:	AX, BX, ES
;-----------------------------------------------
ChangeInt09	proc
		mov ax, 3509h			;<\
		int 21h				;<-+ ES:[BX] = address of INT09
		
		mov Old09Ofs, bx		; Save offset of INT09 to Old0fOfs
		mov bx, es
		mov Old09Seg, bx		; Save code segment of INT09 to Old09Seg

		xor bx, bx			; Get address of memory cell, which keeps address of INT09	
		mov es, bx			; ES = 0000h
            	mov bx, 4 * 09h			; BX = 0024h

		push cs
		pop  ax

		cli				; Prohibit interrupts
            	mov es:[bx], offset NewInt09	; Save new offset in int table
            	mov es:[bx + 2], ax		; Save new code segment in int table
            	sti				; Activate interrupts

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Change address of INT08 in int table
;Entry:	none
;Exit:	none
;Dstr:	AX, BX, ES
;-----------------------------------------------
ChangeInt08	proc
		mov ax, 3508h			;<\
		int 21h				;<-+ ES:[BX] = address of INT08
		
		mov Old08Ofs, bx		; Save offset of INT09 to Old08Ofs
		mov bx, es
		mov Old08Seg, bx		; Save code segment of INT08 to Old08Seg

		xor bx, bx			; Get address of memory cell, which keeps address of INT08	
		mov es, bx			; ES = 0000h
            	mov bx, 4 * 08h			; BX = 0020h

		push cs
		pop  ax

		cli				; Prohibit interrupts
            	mov es:[bx], offset NewInt08	; Save new offset in int table
            	mov es:[bx + 2], ax		; Save new code segment in int table
            	sti				; Activate interrupts

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Function-trampoline of INT09h, which will change flag of drawing the frame
;Entry:	none
;Exit:	none
;Dstr:	none
;-----------------------------------------------
NewInt09       	proc

            	push ax				; Keep value of AX
		
		in al, 60h
            	cmp al, LAUNCH_FRAME_SYMBOL
		jne DontChangeFrameFlag

		mov al, cs:[FrameFlag]		;<\
		not al				;<-+ Change flag of drawing the frame	
		mov cs:[FrameFlag], al		;</		

OutPut:		in al, 61h			;<\
		or al, 80h			;<-\
		out 61h, al			;<--+ Send to keyboard the signal
		and al, not 80h			;<-/
		out 61h, al			;</

		mov al, 20h			; Send to PPI end of interrupt
		out 20h, al			; Activate other interruptions
		
		pop ax 				; Return AX
		
		iret
		
DontChangeFrameFlag:	
		
		cmp al, LAUNCH_CRINGE
		jne GoToOld09
		mov al, cs:[TrashFlag]
		not al
		mov cs:[TrashFlag], al
		jmp OutPut 
		
GoToOld09:	pop ax 				; Return AX
		
		db 0EAh
Old09Ofs	dw 0h
Old09Seg	dw 0h

            	endp
;-----------------------------------------------

;-----------------------------------------------
;Function-trampoline of INT08, which draw of frame, if flag is on
;Entry:	none
;Exit:	none
;Dstr:	none
;-----------------------------------------------
NewInt08		proc
		
		cmp cs:FrameFlag, FLAG_OFF	; Check that flag is off
		je DontDrawFrame

		push ss es ds sp bp si di dx cx bx ax

		mov bp, sp

		push cs
		pop  ds		

		call DrawFrame
		call PrintRegs

		pop  ax bx cx dx di si bp sp ds es ss

DontDrawFrame:	cmp cs:TrashFlag, FLAG_OFF	; Check that flag is off
		je DontMakeCringe

		push ss es ds sp bp si di dx cx bx ax

		mov bp, sp
		add bp, REG_COUNT * 2d - 2
		
		mov ax, ss:[bp]

		call DrawCringeFrame

		pop  ax bx cx dx di si bp sp ds es ss

DontMakeCringe:	db 0EAh
Old08Ofs	dw 0h
Old08Seg	dw 0h

		endp
;-----------------------------------------------

;===============================================
;		MEMORY_FUNCTIONS
;-----------------------------------------------
;Calculate len of string
;Entry:	SI = address of the string
;Exit:	CX = len of string
;Dstr:	AL, SI
;-----------------------------------------------
StrLen		proc
		cld		; DF = 0
		push cs
		pop ds
		mov cx, -1d
CycleLen:	lodsb
		cmp al, '$'
		je FindEnd
		loop CycleLen
FindEnd:	neg cx
		dec cx				
		ret
		endp
;-----------------------------------------------
;===============================================

;===============================================
;		  FRAME SEGMENT
;-----------------------------------------------
;Calculate new position shift of the upper left corner 
;Entry:	none
;Exit: 	DI = new coordinates of upper left corner
;Dstr:	CX, DI
;-----------------------------------------------
CalculateShift	proc
		mov di, (X_CNTR + Y_CNTR * SCREEN_WIDTH) * 2
		mov cx, FRAME_HEIGHT / 2
		sal cx, 2			;<\
		add cx, FRAME_HEIGHT / 2	;<-+ CX = 160 * FRAME_HEIGHT/2
		sal cx, 5			;</
		sub di, cx			;<- DI -= CX
		mov cx, FRAME_WIDTH		; 
		sar cx, 1			;<- CX = FRAME_WIDTH
		sal cx, 1			;<- CX = CX - CX % 2
		sub di, cx			;<- DI -= CX
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw line by part of the frame template 
;Entry:	DI = adress on screen (ES = B800h)
;	SI = adress of frame template's part
;	CX = len of line 
;Exit:	none
;Dstr: 	CX, DI, SI, 
;-----------------------------------------------
DrawLine	proc
		cld 			; DF = 0

		push ds			;
		push cs			; keep old value of DS & DS = CS
		pop ds			;

		lodsb			;
		stosw			; Draw left symbol		

		sub cx, 2		;<------
		lodsb			; Draw CX-2 central symbols 
		rep stosw		;------>

		lodsb			;
		stosw			; Draw right symbol

		pop ds			; DS = old value

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw frame on the screen
;Entry:	none
;Exit:	none
;Dstr:	AX, CX, DX, DI, ES = B800h
;-----------------------------------------------
DrawFrame	proc
		mov ax, VIDEOSEG
		mov es, ax

		call CalculateShift		; DI = new coordinates of left upper corner

		mov ah, FRAME_COLOR		; AH = FRAME_COLOR
		xor dx, dx	 		; DX = NULL
		
		mov si, offset FrameTemplate
		mov cx, FRAME_WIDTH
		call DrawLine			; draw upper line of the frame

DrawVerLines:	cmp dx, FRAME_HEIGHT		;<-------- Cycle, which draws vertical lines
		je StopDrawVerLines
		sub di, FRAME_WIDTH * 2		;<-+ DI += (80 - FRAME_WIDTH) * 2
		add di, SCREEN_WIDTH * 2	;</
		mov cx, FRAME_WIDTH
		call DrawLine
		sub si, 3
		inc dx		
		jmp DrawVerLines		;---------->

StopDrawVerLines:
		add si, 3d			; go to adress of lower line
		
		sub di, FRAME_WIDTH * 2		;<-+ DI += (80 - FRAME_WIDTH) * 2
		add di, SCREEN_WIDTH * 2	;</
		mov cx, FRAME_WIDTH
		call DrawLine			; draw lower line of the frame

		call PrintTitle			; print title of frame
		call DrawHeadLine		; draw headline of frame

		call DrawShadow			; draw shadow of the frame

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw shadow of the frame
;Entry:	none	
;Exit:	none
;Dstr:	AL, CX, 
;-----------------------------------------------
DrawShadow	proc
		
		mov di, (X_CNTR - FRAME_WIDTH / 2 + (Y_CNTR + FRAME_HEIGHT / 2) * SCREEN_WIDTH) * 2d
		add di, SCREEN_WIDTH * 4 + 3d
		mov al, SHADOW_COLOR

		mov cx, FRAME_WIDTH
DrawDownShadow:	stosb				;<\
		inc di				;<-+- Draw down shadow 
		loop DrawDownShadow		;</

		mov cx, FRAME_HEIGHT + 2
		std				; DF = 1
		sub di, 2
DrawRightShadow:
		stosb				;<\
		sub di, SCREEN_WIDTH * 2 - 1	;<-+- Draw right shadow
		loop DrawRightShadow		;</				

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw headline after title
;Entry:	none
;Exit:	none
;Dstr: 	CX, DI, SI
;-----------------------------------------------
DrawHeadLine	proc
		mov si, offset FrameHeadLine
		mov di, (X_CNTR - FRAME_WIDTH / 2 + (Y_CNTR - FRAME_HEIGHt / 2 + 2) * SCREEN_WIDTH) * 2d
		mov cx, FRAME_WIDTH
		call DrawLine
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Print title on screen
;Entry:	none
;Exit:	none
;Dstr:	AX, CX, DI, SI, ES = VIDEOSEG
;-----------------------------------------------
PrintTitle	proc
		mov si, offset FrameTitle
		call StrLen		; CX = len of string
		sub si, cx
		dec si
		push cs
		pop  ds

		mov di, (X_CNTR + (Y_CNTR - FRAME_HEIGHT / 2 + 1) * SCREEN_WIDTH) * 2d
		sub di, cx
		mov ah, FRAME_COLOR	; AH = FrameColor
	
StrCycle:	lodsb
		stosw
		loop StrCycle

		ret	
		endp
;-----------------------------------------------
;===============================================

;===============================================
;		    REGISTERS
;-----------------------------------------------
;Print value of byte on screen
;Entry:	DI = address in video memory, where our word will be writen
;	AL = byte, which will be printed
;Exit:	none
;Dstr:	DI, DS = CS
;-----------------------------------------------
PrintByte	proc				
		
		push ax bx cx dx		; Keep values of registers

		push cs				;<\
		pop  ds				;<-+ DS = CS

		mov dl, HEX_BASE		; DL = 16d
		lea bx, HexAlphabet		; BX = address of hexadecimal alphabet	

		div dl				;<-+ AH = high 4 bites of AL, 
		mov cl, ah			;<-+ AL = low  4 bites of AL
		xor ah, ah			;
		xlat				;<-------
		mov ah, FRAME_COLOR		; Print high 4 bites of AL
		stosw				;------->

		mov al, cl			;-------->
		lea bx, HexAlphabet		;Print low 4 bites of AL
		xor ah, ah			;
		xlat				;
		mov ah, FRAME_COLOR		;
		stosw				;<--------
		
		pop  dx cx bx ax		; Return old values
	
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Print message before value
;Entry:	SI = address of the register message
;	CX = len of this message
;	DI = current address in video memory
;Exit:	none
;Dstr:	AX, CX, DI, SI
;-----------------------------------------------
PrintRegMsg	proc
		mov ah, FRAME_COLOR
		cld
Cycle:		lodsb
		stosw
		loop Cycle
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Print value of registers 
;Entry:	all regs need to be in stack
;Exit:	none
;Dstr:	AX, CX, DX, DI, SI, ES = VIDEOSEG
;-----------------------------------------------
PrintRegs	proc
		mov ax, VIDEOSEG
		mov es, ax
		mov di, (Y_CNTR - FRAME_HEIGHT / 2 + 3) * SCREEN_WIDTH
		add di, X_CNTR - FRAME_WIDTH / 2 + 1
		shl di, 1				; DI = address on screen
		mov si, offset RegistersMsg		; SI = address of register messages
		push ds					;<\
		push cs					;<-+ Remember old value of DS and make DS = CS
		pop ds					;</
		xor dx, dx

Print1reg:	cmp dx, REG_COUNT			;<-------------
		je StopPrintRegs			;
		call StrLen				; Calculate the length of the string we print	
		sub si, cx				; SI = begin of message
		dec si					;
		call PrintRegMsg			; Print this message
		inc si					; Go to next register
							;
		mov ax, ss:[bp]				; Get value of register
		mov ch, al				; <--+ Print 'AH' value
		shr ax, 8				; <-/
		call PrintByte				; </
		mov al, ch				; <--+ Print 'AL' value
		xor ah, ah				; <-/
		call PrintByte				; </
							;
		add di, (SCREEN_WIDTH - 10) * 2d	; Go to next line
		inc dx					; DX++
		inc bp					;
		inc bp
		jmp Print1reg				;------------->
		
StopPrintRegs:	pop ds					; Get old value
		
		ret
		endp
;-----------------------------------------------
;===============================================

;===============================================
;		CRINGE_FUNCTIONS
;-----------------------------------------------
;Take from random address data array and draw it!
;Entry:	AX = address of code segment cringe data array
;	BX = address of offset cringe data array
;Exit:	none
;Dstr: 	CX, DI, SI, ES, DS
;-----------------------------------------------
DrawCringeFrame	proc
			
		mov ds, ax	
		mov si, bx

		mov di, VIDEOSEG
		mov es, di
		xor di, di

		mov cx, 80d * 25d
		rep movsw 	

		ret
		endp
;-----------------------------------------------
;===============================================
 
;===============================================
;		        DATA

FrameFlag	db 00h

TrashFlag	db 00h

FrameTemplate 	db 'ÖÄ·'
		db 'º º'
		db 'ÓÄ½'

FrameTitle	db 'Values of registers $'

FrameHeadLine	db 'ÇÄ¶'

HexAlphabet	db '0123456789ABCDEF'

RegistersMsg	db 'AX := $'
		db 'BX := $'
		db 'CX := $'
		db 'DX := $'
		db 'DI := $'
		db 'SI := $'
		db 'BP := $'
		db 'SP := $'
		db 'DS := $'
		db 'ES := $'
		db 'SS := $'
		db 'IP := $'
		db 'CS := $'

;===============================================
EOP:

end Start
