;-----------------------------------------------
;                   DATA
section .data

RetAddress:     dq 0

Buffer:         db 3 dup(0)
BufSize         equ $ - Buffer

HexAlphabet:    db "0123456789ABCDEF"

NumberBuffer:   db 32 dup(0)

;-----------------------------------------------

global MyPrint    

;+++++++++++++++++++++++++++++++++++++++++++++++
;                   CONSTANTS

STDOUT          equ 1
CHAR_SIZE       equ 1
NEGATIVE_MASK   equ 0x80000000
BIT_MASK        equ 0x0f
MAX_LOG2_BASE   equ 4
WRITE_FUNCTION  equ 0x01

;+++++++++++++++++++++++++++++++++++++++++++++++


section .text
;===============================================
;My realization of 'printf'
;Entry: RDI = address of string_format,
;       RSI, RDX, RCX, R8, R9 - arguments of print
;Exit:  none
;Dstr:  RDI, RSI, RAX, ...
;===============================================
MyPrint:   
            pop qword [RetAddress]

            push r9
            push r8
            push rcx
            push rdx
            push rsi
            push rdi

            mov rsi, rdi            ; RSI = address of format line
            mov rdi, Buffer         ; RDI = address of buffer            

            call FillBuffer

            call PrintBuffer

            pop rdi
            pop rsi
            pop rdx
            pop rcx
            pop r8
            pop r9

            push qword [RetAddress]

            ret
;===============================================

;===============================================
;Fill buffer with values
;Entry: RSI = address of format line    
;       RDI = address of buffer begin
;Exit:  RDI = address of buffer end
;Dstr:  RAX, RBX, RDI, 
;===============================================
FillBuffer: 
            push rbp                ; Save old value of rbp
            lea rbp, [rsp + 8*3]    ; Get 1-st argument

            cld

Cycle:      xor rax, rax

            call CheckBuffer

            lodsb
            cmp al, 0
            je EndFill
            cmp al, '%'
            je LoadArgument
            stosb
            jmp Cycle

LoadArgument:
            lodsb
            cmp al, '%'
            jne LoadSwitch
            stosb
            jmp Cycle

LoadSwitch:
            jmp [jmp_table + (rax - 'b') * 8]

PrintBinNumber:
            mov rbx, 1
            call ItoaTwoPower
            jmp _Default

PrintChar:  
            mov rax, [rbp]
            stosb   
            jmp _Default

PrintDecNumber:
            mov rbx, 10
            call PrintNumber
            jmp _Default

PrintOctNumber:
            mov rbx, 3
            call ItoaTwoPower
            jmp _Default

PrintString:
            mov rax, [rbp]
            call StrCat
            jmp _Default

PrintHexNumber:
            mov rbx, 4
            call ItoaTwoPower
            jmp _Default

_Default:
            add rbp, 8
            jmp Cycle

EndFill:
            pop rbp 

            ret 
;===============================================

;-----------------------------------------------
section .rodata
    jmp_table   dq PrintBinNumber               ; = "%b"
                dq PrintChar                    ; = "%c"
                dq PrintDecNumber               ; = "%d"
                dq 'o' - 'd' - 1 dup(PrintChar)
                dq PrintOctNumber               ; = "%o"
                dq 's' - 'o' - 1 dup(PrintChar)
                dq PrintString                  ; = "%s"
                dq 'x' - 's' - 1 dup(PrintChar)
                dq PrintHexNumber               ; = "%x"

;-----------------------------------------------

section .text
;===============================================
;Print on screen string 
;Entry: RDI = end of buffer
;Exit:  none
;Dstr:  none
;===============================================
PrintBuffer:
            mov rdx, rdi    ;<-+ Get len of buffer
            sub rdx, Buffer ;</

            mov rax, WRITE_FUNCTION
            mov rdi, STDOUT
            mov rsi, Buffer

            syscall

            ret
;===============================================

;===============================================
;Print number from stack to buffer
;Entry: RBX - base of number system
;       RBP - current pointer to number
;       RDI - current address of number begins
;Exit:  none
;Dstr:  RAX, RCX, RDX, RDI, R8
;===============================================
PrintNumber:    
            xor rax, rax

            mov eax, [rbp]

            mov r8d, eax
            and r8d, NEGATIVE_MASK

            ;Check that number is negative!
            cmp r8d, 0
            je DontMulOnNegOne
            neg eax

DontMulOnNegOne:
            xor rdx, rdx
            mov rcx, NumberBuffer

DivLoop:    div rbx                 ; RDX = RAX % RBX, RAX /= RBX

            add rdx, HexAlphabet    ;<-+ Translate number to symbol
            mov dl, [rdx]           ;</
            mov [rcx], dl           ;<\.
            inc rcx                 ;<-+ Insert symbol to number buffer

            cmp rax, 0
            je EndOfLoop
            xor rdx, rdx

            jmp DivLoop
            
EndOfLoop:
            ;Check that number was negative
            cmp r8d, 0
            je SkipMinus
            mov byte [rcx], '-'
            inc rcx

SkipMinus:
            call InsertNumberToBuffer

            ret

;===============================================

;===============================================
;Print number in base, which is power of 2
;Entry: RBX = log2(base of number system)
;Exit:  none
;Dstr:  RAX, RCX, RDX, RDI, R8
;===============================================
ItoaTwoPower:

            xchg rbx, rcx           ; swap values 

            ;Prepare bit mask 

            xor r8, r8
            mov r8, BIT_MASK

            sub rcx, MAX_LOG2_BASE  ;<-+ Count len on which we need to decrease mask!
            neg rcx                 ;</

            shr r8, cl

            sub rcx, MAX_LOG2_BASE  ;<\.
            neg rcx                 ;<-+ return old value of shift

            ;Prepare number & buffer

            xor rax, rax
            mov eax, [rbp]

            xor rdx, rdx
            mov rbx, NumberBuffer

GetNumberCycle:
            ; Get RAX % base
            mov rdx, rax
            and rdx, r8

            ; Translate to alphabet symbol
            add rdx, HexAlphabet
            mov dl, [rdx]
            mov [rbx], dl
            inc rbx

            shr rax, cl
            cmp rax, 0
            je StopGetNumber

            jmp GetNumberCycle

StopGetNumber:
            xchg rbx, rcx           ; return old values

            call InsertNumberToBuffer

            ret

;===============================================

;===============================================
;Copy from NumberBuffer to Buffer
;Entry: RCX - address of the number end
;       RDI - address of the buffer
;Exit:  none
;Dstr:  RCX, RDI
;===============================================
InsertNumberToBuffer:

            push rsi                    ; Save old value of rsi
            
            xor rax, rax                ; RAX = 0
            mov rsi, rcx                ; 
            dec rsi                     ; RSI = address of reverse number begin
            sub rcx, NumberBuffer       ; RCX = len of number
            
            cld
CopyNumberLoop:
            push rcx                    ; Keep size of number buffer
            call CheckBuffer
            pop rcx                     ; Return old value
            mov al, [rsi]
            stosb
            dec rsi
            loop CopyNumberLoop

            pop rsi
            ret
;===============================================

;===============================================
;Calculate len of string
;Entry: RSI = address of string
;Exit:  RCX = len of string
;Dstr:  RCX
;===============================================
StrLen      push rax
            cld 
            xor rax, rax
            mov rcx, -1

CycleLen:   lodsb
            cmp al, 0
            je FindEndOfString
            loop CycleLen

FindEndOfString:
            add rsi, rcx
            neg rcx
            dec rcx

            pop rax
            ret
;===============================================

;===============================================
;Insert string to end of buffer
;Entry: RAX = address of string
;       RDI = address of buffer end
;Exit:  none
;Dstr:  RCX
;===============================================
StrCat:     push rsi
            push rax

            mov rsi, rax
            xor rax, rax

            call StrLen

CopyCycle:  push rcx
            call CheckBuffer
            pop rcx
            lodsb
            stosb
            loop CopyCycle

            pop rax
            pop rsi

            ret
;===============================================

;===============================================
;Check that buffer is not full, and if it is full, clear it
;Entry: RDI - current address of buffer
;Exit:  RDI - begin of buffer, if it was full
;Dstr:  none
;===============================================
CheckBuffer:    
            push rax
            mov rax, Buffer
            add rax, BufSize

            cmp rdi, rax
            js DontClearBuffer

            call ClearBuffer

DontClearBuffer:
            pop rax
            ret
;===============================================

;===============================================
;Print buffer & return RDI to start address
;Entry: RDI - address of buffer
;Exit:  RDI - begin of buffer
;Dstr:  RDI
;===============================================
ClearBuffer:
            push rdx        ;<-+ Keep values of registers
            push rsi        ;</

            call PrintBuffer
            mov rdi, Buffer

            pop rsi
            pop rdx

            ret
;===============================================