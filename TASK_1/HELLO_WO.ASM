.286
.model tiny
.code
org 100h

Start:
		mov ah, 09h		; ah = 09h
		mov dx, offset MyStr	; 
		int 21h			; system call

		mov ax, 4c00h		; ax = 4c00h
		int 21h			; system call

MyStr		db '<<Hello World!', 0dh, 0ah, '>>$'

end 		Start  