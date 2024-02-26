.286
.model tiny

;++++++++++++++++Constants++++++++++++++++++++++

X		equ 80/2			; X-coordinate of symbol
Y		equ 5				; Y-coordinate of symbol
VIDEOSEG	equ 0b800h			; adress of video segment
COLOR		equ 8eh				; yellow color on red fon
SYMBOL		equ 'A'				; SYMBOL = A

;+++++++++++++++++++++++++++++++++++++++++++++++

.code

org 100h

Start:
		mov ax, 1083h
		mov bl, 01h 
		int 10h
		 
		call PrintChar

		mov ax, 4c00h
		int 21h				; return 0

;-----------------------------------------------
;Print char on screen
;Entry: none
;Exit:	none
;Destr:	AX, BX, ES = 0b800h
;-----------------------------------------------
PrintChar	proc
		mov ax, VIDEOSEG
		mov es, ax			; ES = Adress of video segment
		
		mov bx, (X + Y * 80) * 2	; Coordinate of letter

		mov byte ptr es:[bx], SYMBOL	; Put symbol
		mov byte ptr es:[bx+1], COLOR	; Put color

		ret
		endp
;----------------------------------------------- 

end Start