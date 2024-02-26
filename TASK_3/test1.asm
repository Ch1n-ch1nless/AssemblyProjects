.286
.model tiny

.code

org 100h

Start:		mov ax, 0b800h
		mov es, ax

		mov bx, (80d * 5d + 40d) * 2
		mov ah, 4eh

@@Next:		in al, 60h			; read scan code from kybrd
		mov es:[bx], ax			; Write on screen the value of AX

		cmp al, 1h			;<-+ if (put 'ESC') exit
		jne @@Next			;</

		mov ax, 4c00h
		int 21h

end		Start