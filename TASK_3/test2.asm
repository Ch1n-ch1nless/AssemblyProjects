.286
.model tiny

.code

org 100h

Start:     	xor bx, bx			;<\
	  	mov es, bx			;<-+- Get address of INT 09h in table of interrupts and rewrite it
            	mov bx, 4 * 09h			;</

           	cli				; Stop get any other INT
            	mov es:[bx], offset New09

            	push cs
            	pop ax

            	mov es:[bx + 2], ax
            	sti				; get INT

            	mov ax, 3100h			;<\
            	mov dx, offset EOP		;<-\
            	shr dx, 4			;<--+ Keep memory area after program working
            	inc dx				;</

            	int 21h

		mov ax, 4c00h
		int 21h

New09       	proc
            	push ax bx es
            	mov bx, 0b800h
           	mov es, bx
            	mov bx, (80d * 5d + 40d) * 2d
            	mov ah, 4eh

            	in al, 60h			; Get scan code
            	mov es:[bx], ax
            	in al, 61h			;<\
            	and al, not 80h			;<-\
            	out 61h, al			;<--+- ...
		or al, 80h			;<-/
		out 61h, al			;</

            	mov al, 20h			;<-+ 
            	out 20h, al			;</

            	pop es bx ax

            	iret
            	endp
EOP:

end Start
