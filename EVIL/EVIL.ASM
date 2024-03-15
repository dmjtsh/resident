
.model tiny
.386
.code
org 100h
locals @@

;.data
;array[1000000]
;0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

;.bss
;array[1000000]
;выдели пожалуйста 1000000 байт и заполни нулями

SYMBOLS_IN_ONE_LINE_COUNT equ 00A0h
BORDER_HORIZONTAL_OFFSET  equ 0060h
BORDER_VERTICAL_OFFSET    equ 0006h
REGS_OFFSET               equ 0006h
REGS_NUM			      equ 000Dh
BORDER_WIDTH              equ 000Ah
BORDER_HEIGHT             equ 000Fh
BORDER_COLOR              equ 004Eh

.CountLineStart macro
		nop	

		imul di, SYMBOLS_IN_ONE_LINE_COUNT
		add  di, BORDER_HORIZONTAL_OFFSET
			
		nop
		endm

.ColorBorder	macro
		nop

	    mov byte ptr ah, [bp+6] ; border color
		mov byte ptr bh, [bp+6] ; border color
		mov byte ptr ch, [bp+6] ; border color

		nop
		endm

.GetBorder		macro
		nop
		
		mov byte ptr al, [si]
		inc si
		mov byte ptr bl, [si]
		inc si
		mov byte ptr cl, [si]
		inc si
		
		nop
		endm

.WriteRegNum	macro
		nop
		
		mov si, offset HexDigitsArr
		mov cl, al
		add si, cx
		mov byte ptr dl, [si]
		mov byte ptr ES:[di], dl
		add di, 2
		
		nop
		endm

Start:
		;call Dimas08
		
		mov ax, 3508h			; GET INTERRUPT VECTOR
		int 21h
		mov old08offs, bx
		mov bx, es
	        mov old08seg,  bx
		
		mov ax, 3509h			; GET INTERRUPT VECTOR
		int 21h
		mov old09offs, bx
		mov bx, es
		mov old09seg,  bx
		
		push 0
		pop es
		mov bx, 4*08h
		
		cli
		mov ES:[bx], offset Dimas08
		push cs
		pop ax
		mov ES:[bx+2], ax
		sti
		
		push 0
		pop es
		mov bx, 4*09h
		
		cli
		mov ES:[bx], offset Dimas09
		push cs
		pop ax
		mov ES:[bx+2], ax
		sti
		
		mov ax, 3100h
		mov dx, offset ProgEnd
		shr dx, 4
		inc dx
		int 21h
		
		ret

;------------------------------------
; Dimas08: MY OWN FUNC OF 08 INT
;------------------------------------
Dimas08	 proc
		
		cmp cs:ButtonPressed, 1
		jne @@End
		
        push ss ds es sp bp si di dx cx bx ax
		
		push 0b800h
		pop  es
		
		push cs
		pop  ds
		
		push BORDER_WIDTH BORDER_HEIGHT BORDER_COLOR offset BorderStyle
		call DrawBorder
		add sp, 8
		
		call DrawRegs
		
        pop ax bx cx dx di si bp sp es ds
		add sp, 2
		
		@@End:
		
		db 0EAh					; jmp FAR old08seg:[old08offs] 
		old08offs dw 0			
		old08seg  dw 0
		
		endp
		
;------------------------------------
; Dimas09: MY OWN FUNC OF 09 INT
;------------------------------------
Dimas09	proc
		
        push ax

		in al, 60h				; Read From data port of kybd center
		cmp al, 2h
		jne @@End 
		
		in al, 61h
		or al, 80h
		out 61h, al				
		and al, not 80h			; 0111 1111b
		out 61h, al
		mov al, 20h				; Send EOI to intr cntrl
		out 20h, al
		
		mov cs:ButtonPressed, 1
		
		@@End:
		
        pop ax

		db 0EAh					; jmp FAR old09seg:[old09offs] 
		old09offs dw 0			
		old09seg  dw 0
		
		endp

;------------------------------------
; DrawRegs: Draws Regs in the centre of screen
; Entry   : Push All Regs in Stack Frame from last to first
; Assumes : ES = 0b800h
; Destr   : ax, bx, cx, dx, di, si
;------------------------------------
DrawRegs	proc
		push bp
		mov bp, sp
		
		mov ax, 0							; NEXT SYMB IND
		mov bx, 0							; BORDER_VERTICAL_OFFSET COUNT
		mov dx, REGS_NUM					; REGS_NUM
		
		add bp, 4
		@@Cycle:
		cmp dx, 0
		je @@CycleEnd
		
		mov di, BORDER_VERTICAL_OFFSET + 1
		add di, bx
		.CountLineStart
		add di, REGS_OFFSET
		
		mov si, offset RegsArr
		add si, ax
		
		mov cx, 3
		
		push ax bx cx dx
		
		push [bp]
		call DrawRegText
		add sp, 2
		add bp, 2
		
		pop dx cx bx ax
		
		inc bx
		add ax, 3
		dec dx
		
		jmp @@Cycle
		
		@@CycleEnd:
		
		pop bp
		ret
		endp

RegsArr db 'AX:'
		db 'BX:'
		db 'CX:'
		db 'DX:'
		db 'SI:'
		db 'DI:'
		db 'BP:'
		db 'SP:'
		db 'ES:'
		db 'DS:'
		db 'SS:'
		db 'IP:'
		db 'CS:'

ButtonPressed db 0

;---------------------------------
;Draws Regs Text in some place
;Assumes: ES = 06800h
;Entry: di - where to copy , si - copying source, cx - count of symbs to copy
;Destr: ax, di, cx, si
;---------------------------------

DrawRegText	proc
		push bp
		mov bp, sp
		
		cld
		
		; Making sure we writing letters
		mov ax, di
		and ax, 1
		add di, ax
		
		@@Cycle:
		
		cmp cx, 0
		je @@CycleEnd
		
		movsb
		inc di
		
		dec cx
		jmp @@Cycle
		
		@@CycleEnd:	
		
		mov ax, [bp+4]
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
		
		pop bp
		ret
		endp

;------------------------------------
; DrawsBorder in the centre of screen
; Entry: none; Assumes: ES = 0b800h
; Destr:   ax, bx, cx, dx, di, si
;------------------------------------
DrawBorder	proc
		push bp
		mov bp, sp
		
		dec [bp+8]
		
		.ColorBorder		
		mov si, [bp+4]
		.GetBorder
		
		mov di, BORDER_VERTICAL_OFFSET			; line num
		push di									; PUSH DI
		.CountLineStart
		
		push [bp+10]							; border height
		call DrawLine
		add sp, 2
		pop di									; POP DI
		
		.GetBorder
		
		@@Cycle:
		inc di
		dec [bp+8]
		
		cmp [bp+8], 0h
		je @@CycleEnd
		
		push di
		.CountLineStart
		
		push [bp+10]							; border height
		call DrawLine
		add sp, 2
		pop di
		
		jmp @@Cycle
		
		@@CycleEnd:
		
		.GetBorder
		push di
		.CountLineStart
		
		push [bp+10]							; border height
		call DrawLine
		add sp, 2
		pop di
		
		pop bp
		ret
		endp

;---------------------------------
;Draws Line in some place
;Entry: ax - left symb, bx - center symb, cx- right symb, di - line start, [bp+4] - border length
;Assumes: ES = 06800h
;Destr: di, dx
;---------------------------------
DrawLine	proc
		push bp
		mov bp, sp
		
		mov ES:[di], ax		
		add di, 2
		
		mov dx, 0h
		@@Cycle:
			cmp dx, [bp+4]
			je @@CycleEnd
			
			mov ES:[di], bx		
		
			add di, 2
			
			inc dx
			jmp @@Cycle
		@@CycleEnd:			
		
		mov ES:[di], cx
		add di, 2
		
		pop bp
		ret
		endp

BorderStyle  db 'DED| |PDR'
HexDigitsArr db '0123456789ABCDEF'

ProgEnd:
end Start