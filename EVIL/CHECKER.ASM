
.model tiny
.386
.code
org 100h
locals @@

.WriteRegNum	macro
		nop
		
		mov si, offset HexDigitsArr
		mov cl, al
		add si, cx
		mov byte ptr dl, [si]
		mov byte ptr [di], dl
		add di, 1
		
		nop
		endm

Start:
		mov di, offset CSSegStr 
		
		mov ax, cs
		mov bx, ax
		
		xor cx, cx
		
		mov al, bh
		
		shr al, 4
		
		.WriteRegNum
		
		mov al, bh
		shl al, 4
		shr al, 4
		
		.WriteRegNum
		
		mov al, bl
		shr al, 4
		
		.WriteRegNum
		
		mov al, bl
		shl al, 4
		shr al, 4
		
		.WriteRegNum
		
		mov ah, 9h
		mov dx, offset CSSegStr 
		int 21h
		
		@@Cycle:
		
		mov ax, 1111h
		mov bx, 2222h
		mov cx, 3333h
		mov dx, 4444h
		mov di, 5555h
		mov si, 6666h
		
		in al, 60h				; Read From data port of kybd center
		cmp al, 1h
		je @@End

		jmp @@Cycle
		
		@@End:

		ret

CSSegStr     db '0000$'
HexDigitsArr db '0123456789ABCDEF'

end Start