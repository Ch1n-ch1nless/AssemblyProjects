.286
.model tiny

;++++++++++++++++Constants++++++++++++++++++++++

X		equ 80/2-4			; X-coordinate of message's begin
Y		equ 5				; Y-coordinate of message's begin
VIDEOSEG	equ 0b800h			; adress of video segment

RED		equ 04h				; red color on black fon
ORANGE		equ 0ch				; orange color on black fon
YELLOW		equ 0eh				; yellow color on black fon
GREEN		equ 02h				; green color on black fon
BLUE		equ 0bh				; blue color on black fon
INDIGO		equ 01h				; indigo color on black fon
VIOLET		equ 05h				; violet color on black fon
WHITE		equ 0fh				; white color on black fon

;+++++++++++++++++++++++++++++++++++++++++++++++

.code

org 100h

Start:
		mov si, offset Message		; SI = adress of message
		mov ax, 0b800h			; AX = adress of video segment
		mov es, ax
		mov di, (X + Y * 80) * 2	; DI = coordinates on screen

		call PrintString

		mov ax, 4c00h
		int 21h				; return 0 

;-----------------------------------------------
;Print string on screen
;Entry:	SI = address of source, DI = address of dest
;Exit:	none
;Dstr:	AX
;-----------------------------------------------
PrintString 	proc
		mov ah, RED			; 
Next:		lodsb				; mov al, [si]; inc si	

		cmp al, '$'
		je Stop			

		cmp al, '@'			; command to switch color		
		je ChangeColor
		stosw				; mov es:[di], ax; inc di
		jmp Next

ChangeColor:	lodsb
		mov ah, al
		jmp Next
		
Stop:		ret
		endp
;-----------------------------------------------

.data
Message:	db 'R@', ORANGE, 'A@', YELLOW,  'I@', GREEN, 'N@', BLUE, 'B@', INDIGO, 'O@', VIOLET, 'W@', WHITE, '!$'
		
end Start

;-----------------------------------------------