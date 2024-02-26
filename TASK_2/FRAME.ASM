.286
.model tiny

;+++++++++++++++++++++++++++++++++++++++++++++++
;			CONSTANTS
VIDEOSEG	equ 0b800h		; adress of video segment

SHADOW_COLOR	equ 08h			; color of shadow

SCREEN_WIDTH	equ 80d			; width of the screen
SCREEN_HEIGHT	equ 24d			; height of the screen

X_CNTR		equ 40d			; X-coordinate of frame center
Y_CNTR		equ 16d			; Y-coordinate of frame center

ENTER_SYMBOL	equ 0dh			; symbol enter in ASC
SPACE_SYMBOL	equ ' '			; symbol space in ASC

TIMEOUT		equ 38ffh		; timeout between drawing next frame 

;+++++++++++++++++++++++++++++++++++++++++++++++

.code

org 100h

Start:		call ReadArguments

		mov si, offset AddressTemplate	; <-- SI = address of template
		mov si, [si]			; <-/
		call AnimateFrame

		mov si, offset AddressMessage	; <-- SI = address of message
		mov si, [si]			; <-/
		call PrintTitle
		inc si
		call PrintMessage

		mov ax, 4c00h
		int 21h		; return 0 

;===============================================
;		MEMORY FUNCTIONS
;-----------------------------------------------
;Copies word and fill the first CX words in ES:[DI]  
;Entry:	DI = adress of videoseg, 
;	AX = fill word, 
;	CX = count of words,
;Exit: 	none
;Dstr:	CX, DI, 
;-----------------------------------------------
MemSet		proc
		cld		; DF = 0
		rep stosw	; while(CX--) {ES:[DI++] = AX}
		ret
		endp
;-----------------------------------------------

;------------------------------------------------
;Copies characters from the "source" array and 
; inserts them into the "dest" array, 
; but with the color from register AH
;Entry:	DS:[SI]	= adress of source, 
;	ES:[DI] = adress of dest, 
;	CX 	= len of array
;	AH	= color 
;Exit:	none
;Dstr: AX, CX, DI, SI
;-----------------------------------------------
MemCpy		proc
		cld		; DF = 0
		cmp cx, 0	; if (CX == 0)
		je NotCpy	;	don't copy arrays!
Cycle:		lodsb		; while (CX--) {AL = DS:[SI++]
		stosw		; 	ES:[DI++] = AX
		loop Cycle	; } 
NotCpy:		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Calculate len of string
;Entry: SI = adress of string
;Exit:	CX = len of string
;Dstr:	AL, SI
;-----------------------------------------------
StrLen		proc
		cld		; DF = 0
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
;		Command Line

;-----------------------------------------------
;Skip space symbol in command line
;Entry:	SI - current symbol in command line
;Exit:	none
;Dstr:	SI
;-----------------------------------------------
SkipSpaces	proc

CmpSpace:	cmp byte ptr [si], SPACE_SYMBOL
		jne StopSkip
		inc si
		jmp CmpSpace

StopSkip:	ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Read the number and record it
;Entry:	SI - current address in command line
;	DI - memory address where the number will be recorded
;Exit:	SI - adress of end the number 
;Dstr:	SI, AX, 
;-----------------------------------------------
ReadNumber	proc
		call SkipSpaces
		xor ax, ax
NumberCycle:	cmp byte ptr [si], '0'
		jl StopReadNumber
		cmp byte ptr [si], '9'
		jg StopReadNumber
		mov ah, 10d
		mul ah
		add al, [si]
		sub al, '0'
		inc si
		jmp NumberCycle
StopReadNumber:	mov [di], ax
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Read color of the frame from command line
;Entry: SI = adress of the begin
;	DI = adress of the memory cell where color will be recorded 
;Exit:	in the memory cell will be recorded color
;Dstr:	SI, AX
;-----------------------------------------------
ReadColor	proc
		call SkipSpaces
		xor al, al

ColorCycle:	;and [si], not 20h	; Big letters -> small letters

		cmp byte ptr [si], '0'
		jb StopReadColor
		cmp byte ptr [si], '9'
		ja ReadLetter		
		mov ah, '0'
		jmp CalcValue

ReadLetter:	and [si], not 20h
		cmp byte ptr [si], 'A'
		jb StopReadColor
		cmp byte ptr [si], 'F'
		ja StopReadColor
		mov ah, 'A' - 10d		

CalcValue:	sal al, 4		; AL *= 16
		add al, [si]
		sub al, ah
		inc si
		jmp ColorCycle

StopReadColor:	mov [di], al		
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Read template of the frame
;Entry:	SI = current address in command line 
;Exit:	DI = address of the template
;Dstr:	SI, AL
;-----------------------------------------------
ReadTemplate	proc
		call SkipSpaces
		cmp byte ptr [si], '0'
		je ReadNewTemplate
		mov al, [si]		;<------ 
		sub al, '1'		;
		mov ah, 9d		; Here user writes number x  from 1 to 4 	
		mul ah			; and we set to 'AddressTemplate' 
		add [di], ax		; address of the template by number x
		inc si			;
		jmp StopReadTemplate	;------>
ReadNewTemplate:
		inc si			;<------
		call SkipSpaces		; Here user writes his template
		mov [di], si		; and we set to 'AddressTemplate' 
		add si, 10d		; address of his template
					;------>
StopReadTemplate:
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Read message and set its address to 'AddressMessage'
;Entry:	SI = current address in command line
;Exit:	DI = address of the message
;Dstr:	DI, SI 
;-----------------------------------------------
ReadMessage	proc
		call SkipSpaces

		mov [di], si		; Set address of the message begin
SearchEnter:	cmp byte ptr [si], ENTER_SYMBOL
		je FoundEnter
		cmp byte ptr [si], ':'
		je ChangePosition
		inc si
		jmp SearchEnter

ChangePosition:	mov byte ptr [si], '$'
		inc si
		jmp SearchEnter

FoundEnter:	mov byte ptr [si], '$'
		inc si
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Read command arguments
;Entry:	none
;Exit:	(var) FrameWidth  	= resulting width of the frame
;	(var) FrameHeight 	= resulting height of the frame
;	(var) FrameColor  	= color of frame	
;	(var) AddressTemplate	= address of the frame template
; 	(var) AddressMessage	= address of the message begin
;Dstr:	AX, DI, SI
;-----------------------------------------------
ReadArguments	proc
		mov si, 0081h		; go to begin of command line
		xor al, al

		mov di, offset FrameWidth
		call ReadNumber		; Read value of width and set to 'FrameWidth'
		mov di, offset FrameHeight
		call ReadNumber		; Read value of height and set to 'FrameHeight'
		mov di, offset FrameColor
		call ReadColor		; Read color of frame and set to 'FrameColor'
		mov di, offset AddressTemplate
		call ReadTemplate	; Read template of frame and set its address to 'AddressTemplate'
		mov di, offset AddressMessage
		call ReadMessage 	; Read message and set its address to 'AddressMessage'
		
		ret
		endp
;-----------------------------------------------
;===============================================

;-----------------------------------------------
;Set time delay
;Entry:	none
;Exit:	none
;Dstr:	none
;-----------------------------------------------
TimeDelay	proc
		push ax
		push cx
		push dx
		mov ax, 8600h
		xor cx, cx
		mov dx, TIMEOUT
		int 15h
		pop dx
		pop cx
		pop ax
		ret
		endp
;-----------------------------------------------

;===============================================
;		Draw on screen

;----------------------------------------------
;Calculate new position shift of the upper left corner 
;Entry:	DX = X-coordinate shift
;	BX = Y-coordinate shift
;	DI = old coordinates of upper left corner
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

;-----------------------------------------------
;Draw shadow of the frame
;Entry:	DX = width of the frame	
;	BX = height of the frame
;Exit:	none
;Dstr:	AL, CX, 
;-----------------------------------------------
DrawShadow	proc
		neg dx
		call CalculateShift
		neg dx
		add di, 3
		mov al, SHADOW_COLOR

		mov cx, dx
DrawDownShadow:	stosb			;<\
		inc di			;<-+- Draw down shadow 
		loop DrawDownShadow	;</

		mov cx, bx
		std			; DF = 1
		sub di, 2
DrawRightShadow:
		stosb			;<\
		sub di, 160-1		;<-+- Draw right shadow
		loop DrawRightShadow	;</				

		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Animate frame
;Entry:	SI = adress of the frame template
;Exit:	none
;Dstr:	AX, BX, CX, DX, DI, BP, ES = B800h
;-----------------------------------------------
AnimateFrame	proc
		mov ax, VIDEOSEG		; 
		mov es, ax			; ES = VIDEOSEG
		mov bp, offset FrameColor	;<\
		mov ah, ds:[bp]			;<+ AH = FrameColor
		mov bp, offset FrameHeight	;<\
		mov bx, ds:[bp]			;<+ BX = FrameHeight
		mov bp, offset FrameWidth	; BP = FrameWidth
		mov dx, 2d			; DX = 2
		
IncreaseWidth:	cmp dx, ds:[bp]
		jg StopIncrease
		call DrawFrame			; Draw frame
		call DrawShadow			; Draw shadow
		add dx, 2
		call TimeDelay
		jmp IncreaseWidth

StopIncrease:	
		ret
		endp
;-----------------------------------------------

;-----------------------------------------------
;Print title on screen
;Entry:	SI = adress of string
;Exit:	none
;Dstr:	AX, BX, CX, DI, DX, SI, ES
;-----------------------------------------------
PrintTitle	proc
		call StrLen		; CX = len of string
		sub si, cx
		dec si

		mov ax, VIDEOSEG
		mov es, ax		; ES = B800h
		mov dx, cx		;<\
		neg dx			; DX = -CX
		mov bp, offset FrameHeight
		mov bx, ds:[bp]		; 
		neg bx			; BX = -FrameHeight
		call CalculateShift	; DI = adress of string begin

		mov bp, offset FrameColor
		mov ah, ds:[bp]		; AH = FrameColor
		neg dx
		mov cx, dx
		call MemCpy		; print string on screen

		ret	
		endp
;-----------------------------------------------

;-----------------------------------------------
;Print title on screen
;Entry:	SI = adress of string
;Exit:	none
;Dstr:	AX, BX, CX, DI, DX, SI, ES
;-----------------------------------------------
PrintMessage	proc
		call StrLen		; CX = len of string
		sub si, cx
		dec si

		mov ax, VIDEOSEG
		mov es, ax		; ES = B800h
		mov dx, cx		;<\
		neg dx			; DX = -CX
		xor bx, bx
		call CalculateShift	; DI = adress of string begin

		mov bp, offset FrameColor
		mov ah, ds:[bp]		; AH = FrameColor
		neg dx
		mov cx, dx
		call MemCpy		; print string on screen

		ret	
		endp
;-----------------------------------------------
;===============================================

;===============================================
;			DATA																									 																																							
.data

FrameTemplate 	db '÷ƒ∑'	;---->
	      	db '∫∞∫'	; Frame v.1
	      	db '”ƒΩ'	;<----

	      	db '’Õ∏'  	;---->
		db '≥±≥' 	; Frame v.2
		db '‘Õæ'	;<----

		db ''	;---->
		db ' '	; Frame v.3
		db ''	;<----

		db '€ﬂ€' 	;---->
		db '›ﬁ'	; Frame v.4
		db '€‹€'	;<----	

FrameWidth	dw 0028h
FrameHeight	dw 000Ah
FrameColor	db 4eh	

AddressMessage	dw Message

AddressTemplate	dw FrameTemplate

Message 	db '<BibaBoba>$'
;===============================================

end Start
