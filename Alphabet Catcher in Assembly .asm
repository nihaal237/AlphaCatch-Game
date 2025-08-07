[org 0x0100]

jmp StartGame

minspeed: dw 10
rand: dw 0
randnum: dw 0
counter: dw 0
speeds: dw 3, 4, 2, 1, 1
characters: dw 0, 0, 0, 0, 0
locations: dw 0,0,0,0,0
locationBox1: dw 3918 
locationBox2: dw 3916
oldkeyisr:dd 0
oldtimerisr:dd 0
terminateFlag: db 0
score: dw 0
missed: dw 0
second: dw 0
minutes:dw 0
tickCounter:dw 0
gameClock:dw 0
keysPressed: db 0, 0, 0, 0 ;left, right, a, d
shiftPressed: db 0 ; flag to see if pressed , 1 otherwise 0
message1: db 'Press S for Single Player and M for Multiplayer!',0
message7: db 'Press R to Play Again and Q to Quit !',0
message8:db 'Timer: 00:00',0
message2: db 'Score: 0',0
message5: db 'Missed: 0',0
message3: db 'You win!', 0
message4: db'You Loose!',0 



 ClearScreen:    push ax 
                 push es 
                 push di
                 push cx 

                 mov ax,0xb800
                 mov es,ax 
                 mov di,0
                 mov cx,2000

                 mov ax,0x0720
                 rep stosw

                 pop cx 
                 pop di 
                 pop es 
                 pop ax 

                 ret
				 
				 
 beepsoundcatch:
    
               mov al, 0xB6    ; control word for the Programmable Interval Timer
               out 0x43, al     
    
               mov ax, 994      ; frequency divisor for 1200 hz sound 
               out 0x42, al      ;  lower byte of the divisor to the PIT port 0x42
               mov al, ah        
               out 0x42, al      ; Upper byte of the divisor to PIT port 0x42
    
	           ;enable speaker 
               in al, 0x61     
               or al, 0x03      ; Set the bit 0 (speaker enable) and bit 1 (timer interrupt enable)
               out 0x61, al     
    
               call delay         
    
   
              in al, 0x61      
              and al, 0xFC      ; disable speaker
              out 0x61, al      
    
              ret                   

 beepsoundmiss:

             mov al, 0xB6      ; control word for the Programmable Interval Timer
             out 0x43, al     
    
             mov ax, 1491      ; frequency divisor for 800 hz sound 
             out 0x42, al      ;  lower byte of the divisor to the PIT port 0x42
             mov al, ah        
             out 0x42, al      ; Upper byte of the divisor to PIT port 0x42
    
	        ;enable speaker 
             in al, 0x61      
             or al, 0x03      ; Set the bit 0 (speaker enable) and bit 1 (timer interrupt enable)
             out 0x61, al      
    
             call delay         
    
            ;disable speaker 
            in al, 0x61     
            and al, 0xFC      ; disable speaker
            out 0x61, al     
	
	        ret 

 randG:          push bp
                 mov bp, sp
                 pusha
				 
                 cmp word [rand], 0
                 jne next

                 MOV     AH, 00h   ; interrupt to get system timer in CX:DX 
                 INT     1AH
                 inc word [rand]
                 mov  [randnum], dx
                 jmp next1

                 next:
                 mov  ax, 25173          ; LCG Multiplier
                 mul  word  [randnum]     ; DX:AX = LCG multiplier * seed
                 add  ax, 13849          ; Add LCG increment value
                 ; Modulo 65536, AX = (multiplier*seed+increment) mod 65536
                 mov [randnum], ax          ; Update seed = return value

                 next1:
                 xor dx, dx
                 mov ax, [randnum]
                 mov cx, [bp+4]
                 inc cx
                 div cx
                 mov [bp+6], dx
				 
                 popa
                 pop bp
                 ret 2
   
 
GenerateNewAplhabet:  push bp
                      mov bp, sp
                      pusha
 
                      mov bx, [bp+4] ;index of array 
   
                      ;;generate random character 
                      sub sp, 2 
                      push 25                ; We want a number between 0 and 25
                      call randG
                      pop ax            ; Random character now in ax (0 to 25)
	   
                      add al, 65    	; Convert 0-25 to ASCII 'A'-'Z' (65-90)
		
                      mov [characters+bx], ax ;place character in the array 
					  
	                   ;;generate random speed 
                      sub sp, 2 
                      push word [minspeed]          ; We want a number between 0 and 10
                      call randG
                      pop ax            ;;Random speed now in ax (0 to 10) 
                      add ax, 3 
   
                      mov [speeds+bx], ax ;place the speed in the array 
	 
	                  ;;generate random position
                      sub sp,2  
                      push 66 ; We want a number between 0 and 66
                      call randG 
                      pop ax 
                      shl ax,1 ;turn into byte
                      mov [locations+bx], ax  ;;place the location in the array 
	 
                      popa
                      pop bp
                      ret 2
   
   
 increaseSpeeds:      pusha
                      push si
 
                      mov si, speeds ;point si to speed array
                      mov bx, 0
                      mov cx , 5
 
                      Incloop:
                      sub word [si+bx], 2 ;increase speed  by 2 of each character 
                      add bx, 2  
                      loop Incloop
 
                      mov ax, [minspeed]
                      sub ax, 4
                      mov [minspeed], ax
 
                      pop si
                      popa
                      ret

  ;;for single player game
  myTimer1:           push bp
                      mov bp, sp
                      pusha
                      push di
                      push si
                      push es
                      push 0xb800
                      pop es
  
                      mov ax, [minspeed]
                      inc word [counter]
                      cmp word [counter], ax
                      jne safemytimer1
  
                      mov word [counter], 0;restart counter if max reached
  
  
                      safemytimer1:
                      mov bx, 0
                      mov si, [bp+8] 
 
 
                      checkAllSpeedsmytimer1:
                      mov ax, [counter]
                      mov cl, [si+bx]
                      div cl
                      cmp ah, 0
                      jne skipmytimer1
 
                      push si

                      mov si, [bp+6] ;character array
                      mov al, [si+bx] ;character
 
                      sub sp,2  ;generate attribute so it has a different color on screen in every row
                      push 5 
                      call randG
                      pop dx  ;dl has the attribute
                      add dl,1 ;add 1 to avoid black color in case of 0
 
                      mov ah, dl ;attribute
                      mov si, [bp+4] ; location
                      mov di, [si+bx] ;location of the character under consideration 
 

                     moveDownmytimer1:
                     mov word [es:di], ax  
                     mov word [es:di],0x0720 
                     add di, 160
                     cmp di, [locationBox1]
                     je Addscoremytimer1 ; collector collects it and then generation of new character happens
  
  
                     mov [si+bx], di ;update location 
                     mov [es:di], ax
 
                     cmp di,3840;if last row has been reached 
                     jge NewCharactermytimer1
               
                     pop si 
 
                     jmp skipmytimer1
 
                     Addscoremytimer1:   
					 
					 inc word [score] 
					 
					 call beepsoundcatch
					 
					 ;;print the score 
                     push 154 ;location of score being printed 
				     push word [score]
				     call printNumber
				
				     cmp word [score], 8 ;if 8  then increase all speed
			 	     jl Collectmytimer1
				
				    ; increase all speeds
				     call increaseSpeeds
                     jmp Collectmytimer1  ;just print space there and generate new alpha
				
  
                 
                     NewCharactermytimer1:
					 
                     inc word [missed] 
					 
					 call beepsoundmiss
   
                    ;;print missed 
                     push 316  ;location of the missed characters being printed 
                     push word [missed] 
                     call printNumber
  
  
                     mov word [es:di],ax  ;;show the character for a few seconds before it disappears
                     call delay 
                     call delay 
                     mov word [es:di],0x0720
  
                     Collectmytimer1:;handles the character collection
 
                     push bx ; index
                     call GenerateNewAplhabet
 
                     push word [si+bx] ;location
                     push si
                     mov si, [bp+6] ; si now points to character array
                     mov al, [si+bx]
                     mov ah, 0x07
                     pop si ; si back to location array
                     push ax
                     call PrintInitialPos
 
                     pop si ; si pointing to speeds array
 
                     skipmytimer1:
                     add bx, 2
                     cmp bx, [bp+10] ; bp+10 has 10 so when ALL characters checked, exit 
                     je exitmytimer1
 
                     jmp checkAllSpeedsmytimer1

                     exitmytimer1:
					 
                     pop es
                     pop si
                     pop di
                     popa
                     pop bp
                     ret 
   
  ;;for multiplayer game  
  myTimer2:         push bp
                    mov bp, sp
                    pusha
                    push di
                    push si
                    push es
                    push 0xb800
                    pop es
  
                    mov ax, [minspeed]
                    inc word [counter]
                    cmp word [counter], ax
                    jne safemytimer2
  
                    mov word [counter], 0;restart counter if max reached
  
  
                    safemytimer2:
                    mov bx, 0
                    mov si, [bp+8] ;
 
 
                    checkAllSpeedsmytimer2:
                    mov ax, [counter]
                    mov cl, [si+bx]
                    div cl
                    cmp ah, 0
                    jne skipmytimer2
 
                    push si

                    mov si, [bp+6] ;character array
                    mov al, [si+bx] ;character
 
                    sub sp,2  ;generate attribute 
                    push 5 
                    call randG
                    pop dx  ;dl has the attribute
                    add dl,1 ;add 1 to avoid black color in case of 0
 
                    mov ah, dl ;attribute
                    mov si, [bp+4] ; location
                    mov di, [si+bx] ;location of the character under consideration 
 

                   moveDownmytimer2:
                   mov word [es:di], ax  
                   mov word [es:di],0x0720 
                   add di, 160
                   cmp di, [locationBox1]
                   je AddScoremytimer2 ; check if box 1 has collected it 
                   cmp di,[locationBox2]
                   je AddScoremytimer2;check if box 2 has collected it 
  
                   mov [si+bx], di ;update location 
                   mov [es:di], ax
 
                   cmp di,3840;if last row has reached 
                   jge NewCharactermytimer2
 
                   pop si 
 
                   jmp skipmytimer2 
 
                   AddScoremytimer2:    
				   inc word [score] 
				   
				   call beepsoundcatch
				   
				   ;printing the score 
                   push 154 
				   push word [score]
				   call printNumber
				
				   cmp word [score], 8 ;if 8  then increase all speed
				   jne Collectmytimer2
				
				   ; increase all speeds
				   call increaseSpeeds
                   jmp Collectmytimer2  ;just print space there and generate new alpha
				
  
                 
                   NewCharactermytimer2:
                   inc word [missed] ; new character because lost 
				   
				   call beepsoundmiss 
   
                   ;;print new count of missed character 
                   push 316  ;location 
                   push word [missed] 
                   call printNumber
  
  
                   mov word [es:di],ax 
                   call delay 
                   call delay 
                   mov word [es:di],0x0720
  
                  Collectmytimer2:;handles the character collection
 
                  push bx ; index
                  call GenerateNewAplhabet
 
                  push word [si+bx] ;location
                  push si
                  mov si, [bp+6] ; si now points to character array
                  mov al, [si+bx]
                  mov ah, 0x07
                  pop si ; si back to location array
                  push ax
                  call PrintInitialPos
 
                  pop si ; si pointing to speeds array
 
                  skipmytimer2:
                  add bx, 2
                  cmp bx, [bp+10] ; bp+10 has 10 so when ALL characters checked, exit 
                  je exitmytimer2
 
                  jmp checkAllSpeedsmytimer2
 
                  exitmytimer2:
				  
                  pop es
                  pop si
                  pop di
                  popa
                  pop bp
                  ret 

   
  delay:           pusha
	               pushf

	               mov cx,600
	               mydelay:
	               mov bx,300    ;; increase this number if you want to add more delay, and decrease this number if you want to reduce delay.
	               mydelay1:
	               dec bx
	               jnz mydelay1
	               loop mydelay

	               popf
	               popa
                   ret	



 PrintInitialPos:  push bp
                   mov bp, sp
                   pusha
                   push di
                   push es
   
                   mov di, [bp+6] ;;location
                   mov ax, [bp+4] ;;character 
                   push 0xb800
                   pop es
                   stosw
   
                   pop es
                   pop di
                   popa
                   pop bp
                   ret 4
    

  strlen:         push bp
                  mov bp, sp
                  push es
                  push di
                  push cx


                  push ds
                  pop es   ; es no wpointing to ds
                  mov al, 0
                  mov di, [bp+4]
                  mov cx, 0xffff

                  repne scasb
                  mov ax, 0xffff
                  sub ax, cx
                  dec ax;ax will have the length 

                  pop cx
                  pop di
                  pop es
                  pop bp
                  ret 2

 printstr:       push bp
		         mov bp, sp
		         push es
		         push ax
		         push cx
		         push si
		         push di

                 push word [bp+4] ; string to print
		         call strlen
		         mov cx, ax ; cx has length//ax has length 
		         mov ax, 0xb800
		         mov es, ax
		         mov di, [bp+6] ;position for printing 
		         mov si, [bp+4] ; offset for start of printing

		         mov ah,[bp+8]; attribute

		         cld
		         nextchar:
		         lodsb
		         stosw
		         loop nextchar

	             exitfromprint:
				 
	           	 pop di
		         pop si
		         pop cx
		         pop ax
		         pop es
		         pop bp
		         ret 6


 printNumber:    push bp
                 mov bp, sp 
                 push es 
                 push ax 
                 push bx 
                 push cx 
                 push dx 
                 push di 

                 mov ax, 0xb800
                 mov es, ax 
                 mov ax, [bp + 4]  ; Get the number to print
	
	             cmp ax,60 
	             jne continue

	
	            continue:
                mov bx, 10        ; Base 10
                mov cx, 0         ; Digit counter

                nextdigit:
                xor dx, dx        ; Clear DX before division
                div bx             ; Divide AX by 10
                add dl, 0x30      ; Convert remainder to ASCII
                push dx           ; Push the character onto the stack
                inc cx            ; Increment digit counter
                cmp ax, 0         ; Check if there are more digits
                jnz nextdigit     ; If not zero, continue

                mov di, [bp+6]    ; location to print 

                nextpos:  
                pop dx            ; Get character from the stack
                mov dh, 0x07      ; Set attribute (white on black)
                mov [es:di], dx   ; Write character to video memory
                add di, 2         ; Move to the next character position
                loop nextpos      ; Loop for all digits

               ; Cleanup
                pop di 
                pop dx 
                pop cx 
                pop bx 
                pop ax 
                pop es 
                pop bp 
                ret 4
	 

StartScreenInterface: push ax 
                      push cx 
                      push es 
                      push di 

                      mov ax,0xb800
                      mov es,ax 

                      mov al,'-'
                      mov ah,0x47 ;red foreground color

                      mov di,164
                      mov cx,76
  
                      TopHorizontalLine:
                      rep stosw

                      mov di,3684
                      mov cx,76

                      BottomHorizontalLine:
                      rep stosw 
   
  
                      mov al,'|'
                      mov ah,0x47 ;red foreground color 
 
                      mov di,324
                      mov cx,21

                      LeftVerticalLine:
                      stosw 
                      add di,158
                      loop LeftVerticalLine
 
                      mov di,474
                      mov cx,21 
  
                      RightVerticalLine:
                      stosw 
                      add di,158
                      loop RightVerticalLine
  
     PrintingAlpha:
                      mov ax,0xE0DC  ;box ascii and color 

                      ;;;printing A 
					  
                      mov di,828 ; printing left straight line of A 
                      stosw 
                      add di,158 
                      stosw 
                      add di,158
                      stosw
                      add di,158
                      stosw
                      add di,158
                      stosw 
                      mov di,830 ;printing ooper wali line
                      stosw 
                      stosw 
                      stosw 
                      add di,158 ;printing right straight line of A 
                      stosw 
                      add di,158
                      stosw 
                      add di,158 
                      stosw 
                      add di,158
                      stosw  
                      mov di,1150 ;printing A ke beech wali line 
                      stosw
                      stosw 
                      stosw 

                     ;;;Printing L

                     mov di,838 ;printing L ki vertical line 
                     stosw 
                     add di,158 
                     stosw 
                     add di,158 
                     stosw 
                     add di,158 
                     stosw 
                     add di,158  
                     stosw ;;printing L ki neeche wali 
                     stosw 
                     stosw 

                     ;;Printing P 
					 
                     mov di,846 ;printing P ki left vertical line
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     mov di,848 ;printing P ki ooper wali horizontal line
                     stosw 
                     stosw 
                     stosw 
                     add di,158 ;printing P ki right horizontal line
                     stosw 
                     add di,158
                     stosw 
                     sub di,4 ;printing P ki beech wali line 
                     stosw 
                     sub di,4
                     stosw 

                     ;;printing H 
					 
                     mov di ,856 ;;printing H ki left vertical line
                     stosw
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw
                     add di,158
                     stosw
                     mov di,1178 ;printing H ki beech wali line
                     stosw 
                     stosw 
                     stosw 
                     mov di,862 ;Printing H ki right vertical line
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw
                     add di,158
                     stosw 

                     ;;printing A 
                     mov di,866 ; printing left straight line of A 
                     mov cx,10
                     stosw 
                     add di,158 
                     stosw 
                     add di,158
                     stosw
                     add di,158
                     stosw
                     add di,158
                     stosw 
                     mov di,868 ;printing ooper wali line
                     stosw 
                     stosw 
                     stosw
                     add di,158 ;printing right straight line of A 
                     stosw 
                     add di,158
                     stosw 
                     add di,158 
                     stosw 
                     add di,158
                     stosw  
                     mov di,1188 ;printing A ke beech wali line 
                     stosw
                     stosw 
                     stosw 
					 
		PrintingCatch:

                     mov ax,0xC0DC

                     ;;printing C 
					 
                     mov di, 882 ;;C ki vertical line 
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     add di,158
                     stosw 
                     add di,158 ;Bottom line of c 
                     stosw 
                     stosw 
                     stosw 
                     mov di,884 ;TopLine of C
                     stosw 
                     stosw 

                    ;;printing A 
					
                    mov di,890 ; printing left straight line of A 
                    stosw 
                    add di,158 
                    stosw 
                    add di,158
                    stosw
                    add di,158
                    stosw
                    add di,158
                    stosw 
                    mov di,892 ;printing ooper wali line
                    stosw 
                    stosw 
                    stosw
                    add di,158 ;printing right straight line of A 
                    stosw 
                    add di,158
                    stosw 
                    add di,158 
                    stosw 
                    add di,158
                    stosw  
                    mov di,1212 ;printing A ke beech wali line 
                    stosw
                    stosw 
                    stosw

                    ;;Printing T 
					
                    mov di,900 ;T ki ooper wali horizontal line 
                    stosw 
                    stosw 
                    stosw 
                    stosw 
                    stosw 
                    mov di,1064
                    stosw 
                    add di,158
                    stosw 
                    add di,158
                    stosw 
                    add di,158 
                    stosw 

                    ;;printing C 
				   
                    mov di, 912;;C ki vertical line 
                    stosw 
                    add di,158
                    stosw 
                    add di,158
                    stosw 
                    add di,158
                    stosw 
                    add di,158 ;Bottom line of c 
                    stosw 
                    stosw 
                    stosw 
                    mov di,914 ;TopLine of C
                    stosw 
                    stosw 

                    ;;printing H
					
                    mov di ,920 ;;printing H ki left vertical line ;;908
                    stosw
                    add di,158
                    stosw 
                    add di,158
                    stosw 
                    add di,158
                    stosw
                    add di,158
                    stosw
                    mov di,1242 ;printing H ki beech wali line
                    stosw 
                    stosw 
                    stosw 
                    mov di,926 ;Printing H ki right vertical line
                    stosw 
                    add di,158
                    stosw 
                    add di,158
                    stosw 
                    add di,158
                    stosw
                    add di,158
                    stosw 


   DisplaySingleorMultiplayerGameMessage:
   
                   push 0x81 ;;atribute
                   push 2270 ;location 
                   push message1 
                   call printstr 

                   pop di 
                   pop es 
                   pop cx 
                   pop ax 
                   ret

EndScreenInterface:
                    pusha 
					push di 
                    push es
 
                    mov ax,0xb800
                    mov es,ax 
 
                    mov al,0xDC 
                    mov ah,0XE0 ;;orange color attribute 
  PrintingGame:
                   ;;printing G 
				   
                   mov di,686
                   stosw ;G ki ooper wali line 
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   mov di,686 ;G ki left vertical line 
                   add di,160
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw ;G ki neeche wali line 
                   stosw 
                   stosw
                   stosw 
                   stosw 
                   stosw 
                   sub di,162 ;right vertical line and center line 
                   stosw 
                   sub di,162
                   stosw 
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
 
                   ;;printing A 
 
                   mov di,702
                   stosw ;;ooper wali line 
                   stosw
                   stosw 
                   stosw 
                   stosw 
                   add di,158 ;;right vertical line 
                   stosw
                   add di,158
                   stosw 
                   push di 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   pop di 
                   sub di,4;;beech wali line 
                   stosw
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
                   mov di,702 ;left vertical line 
                   add di,160
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw
                   add di,158
                   stosw 
 
                   ;;printing M 
				   
                   mov di,716 ;;M ki left vertical line 
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   mov di,716;beech wali line 
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   push di 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   pop di ;M ki right vertical line 
                   stosw 
                   stosw 
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158 
                   stosw 
                   add di,158
                   stosw 
 
                   ;;printing E 
				  
                   mov di,734;
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   mov di,734
                   add di,160
                   stosw 
                   add di,158
                   stosw 
                   push di 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   pop di 
                   stosw 
                   stosw 
                   stosw 
                   mov di,1374;beech wali line 
                   stosw 
                   stosw 
                   stosw 
                   stosw 
 
 PrintingOver:
                   ;;printing O
				   
                   mov di,1806
                   stosw ;ooper wali line 
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   add di,158;left vertical line 
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   sub di,4 ;bottom line 
                   stosw
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
 
                   sub di,162 ;right vertical line 
                   stosw 
                   sub di,162
                   stosw 
                   sub di,162
                   stosw 
                   sub di,162
                   stosw 
 
                   ;;printing V 
				   
                   mov di,1820
                   stosw 
                   add di,160 ;left diagnol line 
                   stosw 
                   add di,160
                   stosw 
                   add di,160
                   stosw 
                   add di,160
                   stosw 
                   sub di,160 ;right diagnol line 
                   stosw 
                   sub di,160
                   stosw 
                   sub di,160
                   stosw 
                   sub di,160
                   stosw 
 
                   ;;printing E 
				   
                   mov di,1840
                   stosw 
                   push di
                   stosw 
                   stosw 
                   stosw 
                   pop di 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   push di 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   stosw 
                   stosw
                   stosw  
                   pop di 
                   stosw 
                   stosw 
                   stosw 
 
                   ;;printing R 
				   
                   mov di,1852
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   stosw 
                   add di,158
                   stosw
                   add di,158
                   stosw 
                   push di 
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
                   sub di,4
                   stosw 
                   pop di 
                   add di,158
                   stosw
                   add di,158
                   stosw 
 
                   mov di,2012
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
                   add di,158
                   stosw 
 
                   pop es
				   pop di 
                   popa 
 
                   ret 

	
;;keyboard interupt for single player game 

  kbisr1:            pusha
                     push es
                     push si
                     push di 
                     mov bx, 0xb800
                     mov es, bx

                     in al, 0x60 ;read a char from keyboard
	                 cmp al, 0x4B ;cmpare for left key
	                 jne nextCmp
	
	                 ; if leftkey
	                 mov di, [locationBox1]
	                 mov si, di
					 cmp byte [shiftPressed], 0 ; not pressed, normal speed, 
	                 je NormalLeftSpeed
	
	                sub di, 4 ; double box speed
	                jmp PrintLeft
	
	                 NormalLeftSpeed:
	                 sub di, 2
	
	                 PrintLeft:
	                 cmp di, 3838 ; is it on the prev row
	                 jbe done1
	                 mov word [es:si], 0x0720 ; clear it
	                 mov word [es:di], 0x07DC ; move box to left
	                 mov [locationBox1], di ; new di
	
        nextCmp:     cmp al, 0x4D ;is it right key
                     jne nextCmp2_S
			   
			         mov di, [locationBox1]
			         mov si, di
			         cmp byte [shiftPressed], 0 ; not pressed
			         je NormalSpeed
			  
			         DoubleSpeed:
			         add di, 4
			         jmp PrintRight
			   
			         NormalSpeed:
			         add di, 2 ; 
			   
			         PrintRight:
			         cmp di, 4000
			         jge done1 ;out of screen
			         mov word [es:si], 0x0720 ;clear it 
			         mov word [es:di], 0x07DC
			         mov [locationBox1], di ; new location to the right
					 
		nextCmp2_S:  cmp al, 0x36 ; is it right shift being pressed
                     jne nextCmp3_S
			 
			 
			         mov byte [shiftPressed], 1 ; shift is pressed
					 jmp done1
			 
		
	    nextCmp3_S:  cmp al, 0xb6 ; is shift being released
				     jne checkEsc1
				     
				 
				     mov byte [shiftPressed], 0 ; shift released
				 
        checkEsc1:
                     cmp al, 1      ; Is it the Esc key?
                     jne done1
                     mov byte [cs:terminateFlag], 1 ; Signal to terminate
			    
			         done1:
				
			         pop di
			         pop si
			         pop es
			         popa
			         jmp far [cs:oldkeyisr] ; will iret  and Send EOI to PIC on its own 	
				
;;keyboard interrupt for multiplayer game 
;;along with its subfunctions

LeftKeyPress:
                   pusha
                   push es
                   push 0xb800
                   pop es
  
                    
	               mov di, [locationBox1]
	               mov dx,[locationBox2]
	               mov si, di
				   cmp byte [shiftPressed], 0 ; not pressed, so normal speed
				   je normal_speed
				   
				   mov cx, 4
				   sub di, cx
				   
				   normal_speed:
				   mov cx, 2
	               sub di, cx
				   
				   Print_box1:
	               cmp di, 3838 ; is it on the prev row
	               jbe doneleftkeypress
	               sub dx, cx
	               cmp dx,di  ;;for overlap of both boxes dont print space 
	               je skip11 
	               mov word [es:si], 0x0720 ; clear it
			  
	               skip11:
	               mov word [es:di], 0x07DC ; move box to left
	               mov [locationBox1], di ; new di


                   doneleftkeypress:
				  
				   pop es
				   popa
				   
				   
                   ret 


RightKeyPress:
                   pusha
                   push es
                   push 0xb800
                   pop es
				   
                   mov di, [locationBox1]
			       mov dx,[locationBox2]
			       mov si, di
				   cmp byte [shiftPressed], 0 ; if not pressed, notmal speed
				   je normal_speed2
				   
				   mov cx, 4
				   add di, cx
				   jmp print_box2
				   
				   normal_speed2:
				   mov cx, 2 
			       add di, cx
				   
				   print_box2:
			       cmp di, 4000
			       jge donerightkeypress ;out of screen
			       add dx, cx
			       cmp dx,di  ;;for overlap of both boxes dont print space 
			       je skip2
			       mov word [es:si], 0x0720 ;clear it 
			   
			       skip2:
			       mov word [es:di], 0x07DC
			       mov [locationBox1], di ; new location to the right
				   
				   donerightkeypress:
				   
				   pop es
				   popa 
				   ret 



AKeyPress:

                   pusha
                   push es
                   push 0xb800
                   pop es
				   
                   mov di, [locationBox2]
			       mov dx,[locationBox1]
  
	               mov si, di
				   cmp byte [shiftPressed], 0 ; is shift not pressed, then move with normal speed
				   je normal_speed3
				   
				   mov cx, 4
				   sub di ,cx ; double speed
				   jmp Print_box2
				   
				   normal_speed3:
				   mov cx, 2
	               sub di, cx
				   
				   Print_box2:
	               cmp di, 3838 ; is it on the prev row
	               jle   doneAkeyPress
	               sub dx, cx
	               cmp dx,di  ;;incase of overlap of both boxes dont print space 
	               je skip3 
	               mov word [es:si], 0x0720 ; clear it
			  
	               skip3:
	               mov word [es:di], 0x07DC ; move box to left
	               mov [locationBox2], di ; new di
				   
				   doneAkeyPress:
				   pop es
				   popa
				   
				   ret 



DKeyPress:
                   pusha
                   push es
                   push 0xb800
                   pop es
				   
                   mov di, [locationBox2]
			       mov dx,[locationBox1]
			    
			       mov si, di
				   cmp byte [shiftPressed], 0 
				   je normal_speed4
				   
				   mov cx, 4
				   add di, cx
				   jmp print_left
				   
				   normal_speed4:
				   mov cx, 2
			       add di, cx
				   
				   print_left:
			       cmp di, 4000
			       jge doneDkeyPress;out of screen
			       add dx, cx
			       cmp dx,di  ;;in case of overlap of both boxes do not print space 
			       je skip4 
			       mov word [es:si], 0x0720 ;clear it 
				   
			       skip4:
			       mov word [es:di], 0x07DC
				   
			       mov [locationBox2], di ; new location to the right
				   
				   doneDkeyPress:
				   pop es
				   popa
				   ret
				   

kbisr2:	
pusha
push es



    in al, 0x60 ;read a char from keyboard, should trigger 9h
	
	cmp al, 0x4B ;cmpare for left key
	je left_pressed
	cmp al, 0xCB ; is the left key released 
	je left_released
	
	; Process Right Arrow
    cmp al, 0x4D
    je right_pressed
    cmp al, 0xCD
    je right_released

    ; Process A key
    cmp al, 0x1E
    je a_pressed
    cmp al, 0x9E
    je a_released

    ; Process D key
    cmp al, 0x20
    je d_pressed
    cmp al, 0xA0
    je d_released
	
	jmp nextCmp_S
	
	
	
 left_pressed:
       mov byte [keysPressed], 1
       jmp check_combination

 left_released:
      mov byte [keysPressed], 0
      jmp check_combination


 right_pressed:
      mov byte [keysPressed + 1], 1
      jmp check_combination
 

 right_released:
     mov byte [keysPressed + 1], 0
     jmp check_combination

 a_pressed:
     mov byte [keysPressed + 2], 1
     jmp check_combination


 a_released:
     mov byte [keysPressed + 2], 0
     jmp check_combination


 d_pressed:
     mov byte [keysPressed + 3], 1
     jmp check_combination


 d_released:
     mov byte [keysPressed + 3], 0
     jmp check_combination

	
	
	
 check_combination:
      ; Check for Left + a Arrow keys
       mov al, [keysPressed]
       test al, 1                  ; Is Left Arrow pressed?
       jz check_right_d
       mov al, [keysPressed + 2]
       test al, 1                  ; Is A pressed?
       jz check_right_d
      ; Move both boxes
	  
	  
	   call LeftKeyPress
	   call AKeyPress
	  
	
      jmp done_key
       	   
check_right_d:
     mov al, [keysPressed+1]
     test al, 1                  ; Is Right Arrow pressed?
     jz check_right_a
     mov al, [keysPressed + 3]
     test al, 1                  ; Is D pressed?
	 jz check_right_a
	
	
	; move both to the right
	
	call RightKeyPress
	call DKeyPress
				   
				   
	jmp done_key
	

check_right_a:
     mov al, [keysPressed+1]
     test al, 1  ; Is Right Arrow pressed?
	 jz check_left_d

    mov al, [keysPressed + 2]
    test al, 1     ; Is A pressed?
    jz check_left_d 	

    call RightKeyPress
	call AKeyPress
				   
	jmp done_key


check_left_d:

     mov al, [keysPressed]
     test al, 1  ; Is Left Arrow pressed?
	 jz check_left_only

    mov al, [keysPressed + 3]
    test al, 1     ; Is D pressed?
    jz check_left_only	

    call LeftKeyPress
	call DKeyPress
				   
	jmp done_key
	
	
check_left_only:
	
	 mov al, [keysPressed]
     test al, 1  ; Is Left Arrow pressed?
	 jz check_right_only
	 
	 call LeftKeyPress
	 jmp done_key
	 
check_right_only:
	 mov al, [keysPressed+1]
     test al, 1  ; Is Right Arrow pressed?
	 jz check_A_only
	 
	 call RightKeyPress
	 jmp done_key
	 
check_A_only:
    mov al,[keysPressed+2]
    test al, 1
    jz check_D_only
  
  
   call AKeyPress
   jmp done_key
  
check_D_only:
   mov al, [keysPressed+3]
   test al, 1
   jz nextCmp_S
   
   call DKeyPress
   jmp done_key
   
nextCmp_S:          cmp al, 0x36 ; is it right shift being pressed
                    jne nextCmp__S
			 
			 
			        mov byte [shiftPressed], 1 ; shift is pressed
					jmp done_key
					 
					 
					 
nextCmp__S:         cmp al, 0xb6 ; is shift being released
				    jne checkEsc
					 
					 mov byte [shiftPressed], 0 ; shift released
					 jmp done_key
				     
	
checkEsc:
    cmp al, 1      ; Is it the Esc key?
    jne done_key
    mov byte [cs:terminateFlag], 1 ; Signal to terminate
			   
		
			   done_key:
			   pop es
			   popa
			   jmp far [cs:oldkeyisr] ; will iret  and Send EOI to PIC on its own 
			   
			   
  timer: ;;int 8h timer for clock 

              push ax

              inc word [cs:tickCounter]

              cmp word [cs:tickCounter], 10  ; Wait for 10 ticks 
              jl no_increment                  

              xor ax, ax
              mov word [cs:tickCounter], ax     ; Reset tick counter
              inc word [cs:gameClock]           ; Increment the game clock by 1 second

              no_increment:
    
              mov al, 0x20
              out 0x20, al
	 
              pop ax
              jmp far [cs:oldtimerisr]          ; Return to the original timer ISR
   
  GameBegin:

              call ClearScreen;first clear the screen  
	
	          mov si,0
	          mov cx,5 ;5 alphabets 
	          push 0xb800
	          pop es
	
	         GenerateAndPrintInitial:
	         push si ;index
	         call GenerateNewAplhabet
	
	         mov ah, 0x07 ;attribyte added HERE
             mov al, [characters+si]
	
              ; Print character in DL to screen using BIOS interrupt
	         mov di, [locations+si]
	
	         push di
	         push ax
	         call PrintInitialPos
	
	         add si, 2
	         loop GenerateAndPrintInitial
	
	         ; Print Score Msg
	         push 0x07 ;;attrbute 
	         push 140 ;coordinate to print
	         push message2 ;;message 
	         call printstr
	
	
	         ;;print missed msg 
	         push 0x07 ;;attribute 
	         push 300 ;;coordinate 
	         push message5 ;;message 
	         call printstr 
	
	         ;;print timer message
	         push 0x07
	         push 456
	         push message8
	         call printstr
	
             ret 
	
PrintClock:
            push ax 
            push es 

           PrintMinutes:;;print min 
           push 472
           push word [minutes]
           call printNumber

           mov ax,[gameClock]
           cmp ax,60 
           jge IncrementMinutes
           cmp ax,10
           jge Twodigitssecond

           push 478
           push word [gameClock]
           call printNumber
           jmp exitprintclock

           IncrementMinutes:
           inc word [minutes]
           mov word [gameClock],0 ;;seconds to zero 
           push 478
           push word [gameClock]
           call printNumber
		   
           push 0xb800
           pop es 
           mov ah,0x07 
           mov al,0
           add al,0x30 
           mov word [es:476],ax  ;;print 0 in place of 10s digit 
           jmp exitprintclock
  
           Twodigitssecond:
           push 476
           push word [gameClock]
           call printNumber
 
           exitprintclock:

           pop es 
           pop ax 
           ret 
	
GameBeginSinglePlayer:

    call GameBegin

   
	
    PrintBoxInitially:
    mov di, [locationBox1]
    push 0xb800
	pop es
    mov word [es:di], 0x07DC ; box with white fill

    push 10 ; total characters on screen 5 , so 2*5= 10 bytes is the point to check 
	mov ax , speeds
	push ax
	mov ax, characters
	push ax
	mov ax, locations
	push ax

    xor ax, ax
    mov es, ax ;;hook the keyboard 
    mov ax, [es:9*4]
    mov [oldkeyisr], ax
    mov ax, [es:9*4+2]
    mov [oldkeyisr+2], ax
 
    cli
    mov word [es:9*4], kbisr1
    mov word [es:9*4+2], cs 
    sti
	
	xor ax, ax
    mov es, ax ;;hook the timer
	mov ax,[es:8*4]
	mov [oldtimerisr],ax 
	mov ax,[es:8*4+2]
	mov [oldtimerisr+2],ax 
	
	cli 
	mov word [es:8*4],timer
	mov word [es:8*4+2],cs 
	sti 
	

    Repeats1:
	
	call myTimer1

	cmp byte [terminateFlag], 1 ; end if esc has been pressed
    je EndGame
	
	cmp word [score], 10 ;End if score is 10 or greater 
	jge EndGame

	cmp word [missed], 10 ;;end if missed is 10 or greater 
	jge EndGame
	
	call PrintClock
	call delay 

    jmp Repeats1
	
GameBeginDoublePlayer:

    call GameBegin

   
    PrintBoxesInitially:
	mov di,3920 
	mov word [locationBox1],di ;;change location of box1 to a bit right
    
    push 0xb800
	pop es
    mov word [es:di], 0x07DC ; box with white fill
	
	mov di, [locationBox2] ;;location of box 2
    push 0xb800
	pop es
    mov word [es:di], 0x07DC ; box with white fill

    push 10 ; total characters on screen 5 , so 2*5= 10 bytes is the point to check 
	mov ax , speeds
	push ax
	mov ax, characters
	push ax
	mov ax, locations
	push ax

    xor ax, ax
    mov es, ax ;;hook the keyboard 
    mov ax, [es:9*4]
    mov [oldkeyisr], ax
    mov ax, [es:9*4+2]
    mov [oldkeyisr+2], ax
 
    cli
    mov word [es:9*4], kbisr2
    mov word [es:9*4+2], cs 
    sti
	
	xor ax, ax
    mov es, ax ;;hook the timer
	mov ax,[es:8*4]  
	mov [oldtimerisr],ax 
	mov ax,[es:8*4+2]
	mov [oldtimerisr+2],ax 
	
	cli 
	mov word [es:8*4],timer
	mov word [es:8*4+2],cs 
	sti 

    Repeats2:
	
	call myTimer2

	cmp byte [terminateFlag], 1 ; end if esc has been pressed
    je EndGame
	
	cmp word [score], 20 ;End if score is 20 or greater 
	jge EndGame

	cmp word [missed], 10 ;;end if missed is 10 or greater 
	jge EndGame
	
	
	call PrintClock
	call delay 
    jmp Repeats2
	

ReInitializeVariables:

   push bx 

   mov word [minspeed],10
   mov word [rand],0
   mov word [randnum],0
   mov word [counter],0
   mov word [speeds+bx],3
   add bx,2
   mov word [speeds+bx],4
   add bx,2
   mov word [speeds+bx],2
   add bx,2
   mov word [speeds+bx],1
   add bx,2
   mov word [speeds+bx],1
   mov bx,0
   mov word [locations+bx],0
   add bx,2
   mov word [locations+bx],0
   add bx,2
   mov word [locations+bx],0
   add bx,2
   mov word [locations+bx],0
   add bx,2
   mov word [locations+bx],0
   mov bx,0
   mov word [characters+bx],0
   add bx,2
   mov word [characters+bx],0
   add bx,2
   mov word [characters+bx],0
   add bx,2
   mov word [characters+bx],0
   add bx,2
   mov word [characters+bx],0

   mov byte [terminateFlag],0
   mov byte [shiftPressed], 0
   mov byte [keysPressed], 0
   mov byte [keysPressed+1], 0
   mov byte [keysPressed+2], 0
   mov byte [keysPressed+3], 0

   mov word [locationBox1],3918
   mov word [locationBox2],3916
   mov word [score],0
   mov word [missed],0
   mov word [second],0
   mov word [minutes],0
   mov word [tickCounter],0
   mov word [gameClock],0

   pop bx 

   ret 

RestartGame:

    call ReInitializeVariables
    jmp StartGame

StartGame:

     xor ah,ah 

     call ClearScreen
     call StartScreenInterface


     WaitForSorMKey:
     int 16h
     cmp ah,0x1F ;;'S' key 
     je GameBeginSinglePlayer ;clear the screen and start game
     cmp ah,0x32 ;;'M' key 
     je GameBeginDoublePlayer
     xor ah,ah 
     jmp WaitForSorMKey 
 

   EndGame:
	
   call ClearScreen

   call delay

   call EndScreenInterface
   
   add sp,8 ;;pop everything we pushed into the stack such as speeds,number of chars,etc 
   
   ;Restore old keyboard ISR
   
    xor ax,ax 
	
    mov ax, [oldkeyisr]
    mov bx, [oldkeyisr+2]
    cli
    mov [es:9*4], ax
    mov [es:9*4+2], bx
    sti
	
	;;restore old timer ISR
	
	xor ax,ax 
	
	mov ax,[oldtimerisr]
	mov bx,[oldtimerisr+2]
	cli 
	mov [es:8*4],ax 
	mov [es:8*4+2],bx 
	sti 


   cmp byte [terminateFlag], 1 ;;incase escape has pressed you lost the game 
   je PrintLostMessage
   
   cmp word [missed],10  ;;if missed is 10 in either case then you lost the game otherwise you won the game
   jge PrintLostMessage
   
   ;;else you definitely one the game 

PrintWinMessage:

    push 0x0A ;;light  green attribute 
    push 2946
    push message3 ;;win msg 
    call printstr
	
    jmp PrintPlayAgainMessage


PrintLostMessage:

    push 0x04; red attribute 
    push 2944 ;push location
    push message4 ;lost msg 
    call printstr
	
    jmp PrintPlayAgainMessage

PrintPlayAgainMessage:

    push 0x8E ;;push attribute yellow
    push 3242 ;;push location 
    push message7  ;;push message 
    call printstr 
	
	WaitForInput:
	
	mov ax,0x00
	int 16h
	
	cmp al,'r' ;R for restart 
	je RestartGame
	
	cmp al,'q' ;Q for quit 
	je endProg
	
	jmp WaitForInput ;;;wait for valid input 
	
  
endProg:

call ClearScreen ;;clear the screen and wait for valid input 

mov ax,0x4c00
int 21h