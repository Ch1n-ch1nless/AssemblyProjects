.286
.model tiny

.code 
org 100h

Start:
    mov ax, 0fffh
    mov bx, 1111h
    mov cx, 2222h
    mov dx, 3333h
    mov bp, 4444h

    in al, 60h
    cmp al, 10h
    jne Start
    ret

end Start
