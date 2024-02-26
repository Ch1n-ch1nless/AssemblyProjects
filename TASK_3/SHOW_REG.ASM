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
FRAME_HEIGHT	equ 000eh		; final height of the frame

FRAME_COLOR	equ 4eh			
SHADOW_COLOR	equ 18h

;+++++++++++++++++++++++++++++++++++++++++++++++

.code

org 100h

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

Start:  	call ChangeIRQ1
		call ChangeIRQ0

            	mov ax, 3100h
            	mov dx, offset EOP
            	shr dx, 4
		inc dx

            	int 21h
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;-----------------------------------------------

ChangeIRQ1	proc
		mov ax, 3509h
		int 21h
		
		mov Old090fs, bx
		mov bx, es
		mov Old09Seg, bx

		xor bx, bx		
		mov es, bx
            	mov bx, 4 * 09h

		push cs
		pop  ax

		cli
            	mov es:[bx], offset New09
            	mov es:[bx + 2], ax
            	sti

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------

ChangeIRQ0	proc

		mov ax, 3508h
		int 21h
		
		mov Old080fs, bx
		mov bx, es
		mov Old08Seg, bx

		xor bx, bx		
		mov es, bx
            	mov bx, 4 * 08h

		push cs
		pop  ax

		cli
            	mov es:[bx], offset New08
            	mov es:[bx + 2], ax
            	sti
		
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
New09       	proc

            	push ss es ds sp bp si di dx cx bx ax
		
		in al, 60h
            	cmp al, 02h		; v constanty!
		jne DontShowFrame
		
		in al, 61h
		or al, 80h
		out 61h, al
		and al, not 80h
		out 61h, al

		mov al, 20h
		out 20h, al
		
		pop ax bx cx dx di si bp sp ds es ss 
		
		iret
		
DontShowFrame:	pop ax bx cx dx di si bp sp ds es ss 
		
GoToOld09:	db 0EAh
Old090fs	dw 0h
Old09Seg	dw 0h

            	endp
;-----------------------------------------------

;-----------------------------------------------
New08		proc

		endp
;-----------------------------------------------

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

		call CalculateShift	; DI = new coordinates of left upper corner

		mov ah, FRAME_COLOR	; AH = FRAME_COLOR
		xor dx, dx	 	; DX = NULL
		
		mov si, offset FrameTemplate
		mov cx, FRAME_WIDTH
		call DrawLine		; draw upper line of the frame

DrawVerLines:	cmp dx, FRAME_HEIGHT	;<-------- Cycle, which draws vertical lines
		je StopDrawVerLines
		sub di, FRAME_WIDTH * 2	;<-+ DI += (80 - FRAME_WIDTH) * 2
		add di, SCREEN_WIDTH * 2;</
		mov cx, FRAME_WIDTH
		call DrawLine
		sub si, 3
		inc dx		
		jmp DrawVerLines	;---------->

StopDrawVerLines:
		add si, 3d		; go to adress of lower line
		
		sub di, FRAME_WIDTH * 2	;<-+ DI += (80 - FRAME_WIDTH) * 2
		add di, SCREEN_WIDTH * 2;</
		mov cx, FRAME_WIDTH
		call DrawLine		; draw lower line of the frame

		call PrintTitle		; print title of frame
		call DrawHeadLine	; draw headline of frame

		call DrawShadow		; draw shadow of the frame

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
;Print value of word on screen
;Entry:	DI = address in video memory, where our word will be writen
;	AL = byte, which will be printed
;Exit:	none
;Dstr:	DI
;-----------------------------------------------
PrintWord	proc				; Remake to itoa_16
		
		push ax bx cx

		xor ah, ah			;------>
		mov cl, al			;Get first 4 bites of register AL
		and al, 0f0h			;Masky v bity! Translate the number to hex-symbol
		shr ax, 4			;Print it
		mov bx, offset HexAlphabet	;
		add bx, ax			;
		mov ah, 4eh			;
		mov al, cs:[bx]			;
		stosw				;<-------

		mov al, cl			;------->
		and al, 00fh			;Get last 4 bites of register AL
		xor ah, ah			;Translate the number to hex-symbol	
		mov bx, offset HexAlphabet	;Print it
		add bx, ax			;
		mov ah, 4eh			;
		mov al, cs:[bx]			;
		stosw				;<------
		
		pop  cx bx ax

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
		mov di, (X_CNTR - FRAME_WIDTH / 2 + 1 + (Y_CNTR - FRAME_HEIGHT / 2 + 3) * SCREEN_WIDTH ) * 2d
		mov si, offset RegistersMsg		; SI = address of register messages
		push ds					;<\
		push cs					;<-+ Remember old value of DS and make DS = CS
		pop ds					;</
		xor dx, dx

Print1reg:	cmp dx, 11d				;<-------------
		je StopPrintRegs			;
		call StrLen				; Calculate the length of the string we print	
		sub si, cx				; SI = begin of message
		dec si					;
		call PrintRegMsg			; Print this message
		inc si					; Go to next register
							;
		mov ax, ss:[bp]				; Get value of register
		mov ch, al				; <--+ Print 'AH' value
		mov al, ah				; <-/
		call PrintWord				; </
		mov al, ch				; <-+ Print 'AL' value
		call PrintWord				; </
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
;		        DATA

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

SIXTEEN		db 10h

;===============================================
EOP:

end Start
