.286
.model tiny

;+++++++++++++++++++++++++++++++++++++++++++++++
;		CONSTANTS

;+++++++++++++++++++++++++++++++++++++++++++++++

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

Start:		
		mov ax, 3509h
		int 21h

		cli

		mov [Old09Ofs], bx
		mov es, bx
		mov [Old09Seg], bx

		xor bx, bx
		mov es, bx
		mov bx, 4 * 09h

		mov es:[bx], offset New09
		push cs
		pop  ax
		mov es:[bx+2], ax

		sti

		call Main

		cli

		xor bx, bx
		mov es, bx
		mov bx, 4 * 09h

		mov ax, [Old09Ofs]
		mov es:[bx], ax
		mov ax, [Old09Seg]
		mov es:[bx+2], ax

		sti
		
		mov ax, 4c00h
		int 21h
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;===============================================
;		INT - functions!
;-----------------------------------------------
;New interupt 09h
;Entry:	SI = address of Password buffer
;	BX = current coordinates on frame	(ES = VIDEOSEG)
;Exit:	None	
;Dstr:	Al, BX, SI, 
;-----------------------------------------------

New09		proc

		in al, 60h
		mov byte ptr es:[bx], '*'
		inc bx
		mov byte ptr es:[bx], FRAME_COLOR
		inc bx

		mov byte ptr ds:[si], al
		inc si

		in al, 61h
		or al, 80h
		out 61h, al
		and al, not 80h
		out 61h

		mov al, 20h
		out 20h, al		

		iret
		endp
;-----------------------------------------------
;===============================================

;===============================================
;		MAIN_FUNCTION
;-----------------------------------------------
; Main function :) 
;Entry:	none
;Exit:	none
;Dstr:	AX, BX, CX, DX, DI, SI, ES, DS
;-----------------------------------------------

Main		proc
		
		call DrawIntFrame		; Function, which will draw the frame to insert password

		xor cx, cx			; CX = count of letters
		mov ax, VIDEOSEG
		mov es, ax			; ES = address of video segment
		mov si, offset PasswordBuffer	; SI = address of password buffer
		inc si				;<\
		inc si				;<-+ Skip len of buffer
		xor ax, ax
		mov ah, FRAME_COLOR		; AH = color of the frame
		; This function in bx will write coordinates of place to write password
		call CalculatePlaceToEnterPassword

		xor al, al
LoopPassword	cmp al, ENTER_SYMBOL
		je StopEnterSymbols
		mov ah, 01h
		int 21h
		jmp LoopPassword

StopEnterSymbols:
		;Check correctness of password:
		


WrongPassword:	call DrawBadEndingFrame
		ret

CorrectPassword:
		call DrawGoodEndingFrame
		ret
		endp
;-----------------------------------------------

;===============================================

;===============================================
;	        FRAME_TRAMPOLINE

;-----------------------------------------------
;Draw initial frame, where will be written password
;Entry:	none
;Exit:	none
;Dstr:	...
;-----------------------------------------------
DrawIntFrame	proc
		mov dx, FRAME_WIDTH
		mov bx, FRAME_HEIGHT
		mov ah, FRAME_COLOR
		call DrawFrame

		mov di, (X_CNTR - 9d + Y_CNTR * 80d) * 2d
		mov si, offset PasswordString
		call PrintString
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw frame, that says that the user has entered a valid password
;Entry:	none
;Exit:	none
;Dstr:	...
;-----------------------------------------------
DrawGoodEndingFrame	
		proc
		mov dx, FRAME_WIDTH
		mov bx, FRAME_HEIGHT
		mov ah, FRAME_COLOR
		call DrawFrame

		mov di, (X_CNTR - 13d + Y_CNTR * 80d) * 2d
		mov si, offset SuccessString
		call PrintString
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw frame, that says that the user has entered a valid password
;Entry:	none
;Exit:	none
;Dstr:	...
;-----------------------------------------------
DrawBadEndingFrame	
		proc
		mov dx, FRAME_WIDTH
		mov bx, FRAME_HEIGHT
		mov ah, FRAME_COLOR
		call DrawFrame

		mov di, (X_CNTR - 10d + Y_CNTR * 80d) * 2d
		mov si, offset LoseString
		call PrintString
		ret
		endp
;-----------------------------------------------

;===============================================

;===============================================

;===============================================

;===============================================
;		   FRAME_LIB

;----------------------------------------------
;Calculate new position shift of the upper left corner 
;Entry:	DX = X-coordinate shift
;	BX = Y-coordinate shift
;Exit: 	DI = new coordinates of upper left corner
;Dstr:	CX
;----------------------------------------------
CalculateShift	proc
		mov di, (X_CNTR + Y_CNTR * 80) * 2
		mov cx, bx
		sal cx, 2	;
		add cx, bx	; SI *= 80
		sal cx, 4	;
		add di, cx	; DI += (80*BX/2)*2
		mov cx, dx	; 
		sar cx, 1	;<\
		sal cx, 1	; CX = CX - CX % 2
		add di, cx	; DI += (DX/2)*2
		ret
		endp
;----------------------------------------------

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

		lodsb			;
		stosw			; Draw left symbol		

		sub cx, 2		;<------
		lodsb			; Draw DX-2 central symbols 
		rep stosw		;------>

		lodsb			;
		stosw			; Draw right symbol

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Draw frame on the screen
;Entry:	SI = adress of the frame template
;	DX = width of the frame	
;	BX = height of the frame
;	AH = color of the frame
;Exit:	none
;Dstr:	AX, CX, DI, ES = B800h
;-----------------------------------------------
DrawFrame	proc
		neg bx			; 
		neg dx			; 
		call CalculateShift	; DI = (X_CNTR - DX/2 + (Y_CNTR - BX/2) * 80) * 2
		neg bx
		neg dx
		sub bx, 2		; BX -= 2
		
		push si			; keep adress of frame
		mov cx, dx
		call DrawLine		; draw upper line of the frame

		push bx			; keep value of height

DrawVerLines:	cmp bx, 0	;<-------- Cycle, which draws vertical lines
		je StopDrawVerLines
		sub di, dx	;<\
		sub di, dx	; DI += (80 - DX) * 2
		add di, 80*2	;</
		mov cx, dx
		call DrawLine
		sub si, 3
		dec bx		
		jmp DrawVerLines;---------->

StopDrawVerLines:
		pop bx		; 
		add bx, 2d	; BX <- height of the frame
		add si, 3d	; go to adress of lower line
		
		sub di, dx	;<\
		sub di, dx	; DI += (80 - DX) * 2
		add di, 80 * 2	;</
		mov cx, dx
		call DrawLine	; draw lower line of the frame

		pop si		; return adress to string

		ret
		endp
;-----------------------------------------------

;===============================================

;===============================================
;		      DATA

Old09Ofs	dw 0000h
Old09Seg	dw 0000h

CanaryLeft	db 'AmongUs2'
PasswordBuffer	db 8, dup(?)
CanaryRight	db 'BibaBoba'
		db 'HihiHaha'
		db 'What?What?'
		db 'Jump out the house'
		db 'Jump out the house'
		db 'Jump out the house'
CorrectPassword db 'Jump out the house'
		db 'Jump out the house'
		db 'Jump out the house'
		db 'Jump out the house'
		db 'Jump out that bitch(What?)'
		db 'Jump out that bitch(What?)'
		db 'Jump out that bitch(What?)'
		db 'Jump out that bitch(What?)'
		db 'Jump out that bitch(What?)'
		db 'Jump out that bitch(What?)'
		db 'Jump out that bitch(What?)'

PasswordString	db 'Password: $'
SuccessString 	db 'You enter correct password!'
LoseString	db 01h, 01h, ' Haha! You lose! ', 01h, 01h

;===============================================

EOP:

end		Start