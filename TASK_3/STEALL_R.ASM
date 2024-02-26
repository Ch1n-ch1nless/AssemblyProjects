.286
.model tiny

.code 
org 100h

Start:	mov bx, 01h
	mov cx, 01h
	mov dx, 01h
	
	mov ax, 4c00h
	int 21h

end Start