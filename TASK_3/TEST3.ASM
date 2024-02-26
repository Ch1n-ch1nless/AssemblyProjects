.286
.model tiny

.code

org 100h

Start:  	mov ax, 3509h			;<-+ Save old address of INT 09h
		int 21h				;</
		
		mov Old090fs, bx		; Old090fs = BX
		mov bx, es			;	
		mov Old09Seg, bx		; Old09Seg = ES

		xor bx, bx		
		mov es, bx
            	mov bx, 4 * 09h

            	cli
            	mov es:[bx], offset New09	; Create new address of INT 09h

            	push cs
            	pop ax

            	mov es:[bx + 2], ax
            	sti

            	mov ax, 3100h
            	mov dx, offset EOP
            	shr dx, 4
            	inc dx

            	int 21h

		mov ax, 4c00h
		int 21h

;================================================
;New09 -- function 'trumplin' 
;
New09       	proc
            	push ax bx es
            	mov bx, 0b800h
		mov es, bx
            	mov di, offset Shift
	    	mov bx, cs:[di]
            	mov ah, 4eh

            	in al, 60h
            	mov es:[bx], ax
	    	add bx, 2
		and bx, 0fffh
	    	mov cs:[di], bx
		
		jmp GoOld09
		 
           	in al, 61h
            	or al, 80h
            	out 61h, al
            	and al, not 80h
            	out 61h, al

            	mov al, 20h
            	out 20h, al

GoOld09:       	pop es bx ax

		db 0EAh			;<\
Old090fs	dw 0h			;<-+ This truck named self-modifying code
Old09Seg	dw 0h			;</

            	iret
            	endp
EOP:
;================================================

Shift	    	dw (40d + 80d * 5d) * 2d

end Start
