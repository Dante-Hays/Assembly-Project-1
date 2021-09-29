;********************************************************************
; Program: Infix2Postfix Calculator
; Class:   CSCI 2160-001
; Names:   Charles Kinser
;          Drew Dorris
;          ADD YOUR NAME
;          ADD YOUR NAME
; Date:    9/26/2021
; Purpose: TODO
;********************************************************************

;*****************************
;VARIABLES
;*****************************

skip:    BR main

inVec:   .BLOCK  128         ;array of characters and values from input, global array #2c64a
                             ;the input is convereted into an array to allow access multiple times 
vecI:    .WORD   0           ;store current index of inVec array when register is in use #2d
inVecL:  .WORD   1           ;length of inVec, global variable #2d

num1:    .BLOCK  2           ;variable for multidigit intake, num1 is the current digit/char #2d 
num2:    .BLOCK  2           ;variable for multidigit intake, num2 is used to look ahead for more digits #2d 
value:   .WORD   0           ;temporary storage for integer intake #2d

;*****************************
;INPUT TO ARRAY
;*****************************

main:    LDBA charIn,d       ;prep for first run by populating num2
         SUBA 0x30,i         ;convert to deci
         STWA num2,d
loop:    LDWA num2,d         ;shift input chars num1 <- num2, num2 <- charIn
         STWA num1,d
         LDWA 0x0000,i       ;clear accumulator
         LDBA charIn,d
         SUBA 0x30,i         ;convert to deci
         STWA num2,d
         
         LDWA num1,d         ;if num1 is not deci, store as char, else add to value
         CPWA 9,i            ;check for int by checking for range 0
         BRGT notDec
         CPWA 0,i
         BRLT notDec
         ADDA value,d
         STWA value,d

         
         LDWA num2,d         ;if num2 is not deci, handle the char, else multiply value by 10
         CPWA 9,i
         BRGT decDone
         CPWA 0,i
         BRLT decDone
         LDWA value,d
         LDWA 10,i       ;move value
         STWA -4,s         
         LDWA value,d
         STWA -6,s
         SUBSP 6,i         ;push #retVal #mult1 #mult2 
         CALL  multiply    
         LDWA 4,s
         STWA value,d
         ADDSP 6,i         ;pop #mult2 #mult1 #retVal 
         BR loop

notDec:  ADDA 0x30,i         ;convert back to ascii char
         CPWA 0x000A,i       ;check if input is finished, if so, move to postFix
         BREQ postFix 
         LDWX vecI,d         ;load inVec index
         STWA inVec,x        ;store in array
         LDWA vecI,d         ;increment index & length
         ADDA 2,i
         STWA vecI,d
         ASRA
         STWA inVecL,d 
         LDWA 0,i            ;reset value 
         STWA value,d  
         BR loop           
             
decDone: LDWA value,d
         LDWX vecI,d         ;load inVec index
         STWA inVec,x        ;store in array
         LDWA vecI,d         ;increment index & length
         ADDA 2,i
         STWA vecI,d
         ASRA
         STWA inVecL,d
         LDWA 0,i            ;reset value
         STWA value,d 
         BR loop           

postFix:  BR end ;TODO



;*****************************
;*****OPERATOR FUNCTIONS******
;*****************************
                  
;********* MULTIPLY **********
retVal:  .EQUATE 12          ;returned value #2d
mult1:   .EQUATE 10          ;formal parameter; first multiple #2d
mult2:   .EQUATE 8           ;formal parameter; second multiple #2d
m1Sign:  .EQUATE 5           ;local variable; sign of the first multiple #1d
m2Sign:  .EQUATE 4           ;local variable; sign of the 2nd multiple #1d
k:       .EQUATE 2           ;local variable #2d
                             ;keeps track of how many times to loop and add mult1 by mult2 times
result:  .EQUATE 0           ;local variable; calculated result #2d
                             ;many changes made to this variable in function; end result placed into retVal
;Multiply function takes two number (word) parameters, multiplies them,
;  and returns the result in retVal.
;This function works by adding mult1 to itself mult2 times.
;Ex. if mult1 is 60 and mult2 is 3, the function does 60 + 60 + 60 and returns the value
multiply:SUBSP   6,i         ;push #m1Sign #m2Sign #k #result 
         LDWA    0,i         ;reset possible lingering values in the stack before doing operations
         STWA    result,s    ;TODO comments
         LDBA    0,i         ;
         STBA    m1Sign,s    ;
         STBA    m2Sign,s    ;
         LDWA    1,i         ;
         STWA    k,s         ;
;from this point on, do absolute value operations on mult1 and mult2
;and store their original signs in the m1Sign and m2Sign bytes
;so we can restore the sign later on
chckM2:  LDWA    mult1,s     ;TODO comments
         CPWA    0,i         ;
         BRGT    chckM2      ;
abs1:    NOTA                ;
         ADDA    1,i         ;
         STWA    mult1,s     ;
         LDBA    1,i         ;
         STBA    m1Sign,s    ;
chckM2:  LDWA    mult2,s     ;
         CPWA    0,i         ;
         BRGT    forM        ;
abs2:    NOTA                ;
         ADDA    1,i         ;
         STWA    mult2,s     ;
         LDBA    1,i         ;
         STBA    m2Sign,s    ;
;loop section
;adds 1 to k and adds mult1 to itself repeatedly until k > mult2
forM:    LDWA    k,s         ;load k for comparison if not loaded already, to see if we are done looping yet
         CPWA    mult2,s     ;see if k <= mult2, which means we have added mult1 to itself mult2 times
         BRGT    endForM     ;if so, we're done! branch to endForM
         LDWA    result,s    ;if not, we'll keep going! load the current added result to keep adding
         ADDA    mult1,s     ;add mult1 again
         STWA    result,s    ;store it to result
         LDWA    k,s         ;load k to add one to it
         ADDA    1,i         ;add one to it so we can see when we reach mult2 and stop adding
         STWA    k,s         ;store it to k
         BR      forM        ;do the loop again!
;The end function which prints the equation
;  and returns the result
endForM: LDBA    '\n',i      ;print out newline
         STBA    charOut,d   ;print out newline
         LDBA    m1Sign,s    ;TODO comments
         CPBA    1,i         ;
         BRNE    endForM2    ;
         LDBA    '-',i       ;
         STBA    charOut,d   ;
endForM2:DECO    mult1,s     ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         LDBA    '*',i       ;
         STBA    charOut,d   ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         LDBA    m2Sign,s    ;
         CPBA    1,i         ;
         BRNE    endForM3    ;
         LDBA    '-',i       ;
         STBA    charOut,d   ;
endForM3:DECO    mult2,s     ;
         LDBA    '\n',i      ;
         STBA    charOut,d   ;
         LDBA    m1Sign,s    ;
         CPBA    m2Sign,s    ;
         BREQ    endForM4    ;
         LDWA    result,s    ;
         NOTA                ;
         ADDA    1,i         ;
         STWA    result,s    ;
endForM4:LDWA    result,s    ;
         STWA    retVal,s    ;
         ADDSP   6,i         ;pop #result #k #m1Sign #m2Sign 
         RET                 ;

;********* DIVIDE/MODULO **********
remaind: .EQUATE 14          ;returned value; remainder/modulo #2d
retDiv:  .EQUATE 12          ;returned value; the return value/quotient #2d 
div1:    .EQUATE 10          ;formal parameter; dividend #2d
div2:    .EQUATE 8           ;formal parameter; divisor #2d
div1Sign:.EQUATE 5           ;local variable #1d
div2Sign:.EQUATE 4           ;local variable #1d
dk:      .EQUATE 2           ;local variable #2d
dresult: .EQUATE 0           ;local variable #2d
;Divide function takes two number (word) parameters, divides them,
;  and returns the quotient in retDiv as well as the remainder/modulo in remaind.
;This function works by adding div2 to itself until it is greater than div1.
;The amount of times div2 was added to itself is the result.
;Ex. if div1 is 60 and div2 is 3, the function does 3 + 3 + .... until it reaches 60
;  and counts how many times it added it
divide:  SUBSP   6,i         ;push #div1Sign #div2Sign #dk #dresult 
         LDWA    0,i         ;TODO comments
         STWA    dresult,s   ;
         STWA    dk,s        ;
         STWA    remaind,s   ;
         LDBA    0,i         ;
         STBA    div1Sign,s  ;
         STBA    div2Sign,s  ;
;from this point on, do absolute value operations on div1 and div2
;and store their original signs in the div1Sign and div2Sign bytes
;so we can restore the sign later on
chckD1:  LDWA    div1,s      ;TODO comments
         CPWA    0,i         ;
         BRGT    chckD2      ;
absD1:   NOTA                ;
         ADDA    1,i         ;
         STWA    div1,s      ;
         LDBA    1,i         ;
         STBA    div1Sign,s  ;
chckD2:  LDWA    div2,s      ;
         CPWA    0,i         ;
         BREQ    divZero     ;
         BRGT    forD        ;
absD2:   NOTA                ;
         ADDA    1,i         ;
         STWA    div2,s      ;
         LDBA    1,i         ;
         STBA    div2Sign,s  ;
;loop section
;adds div2 to itself until it is greater than div1
;The amount of times div2 was added to itself is the result.
forD:    LDWA    dk,s        ;TODO comments
         CPWA    div1,s      ;
         BRGE    checkRmd    ;
         LDWA    dk,s        ;
         ADDA    div2,s      ;
         STWA    dk,s        ;
         LDWA    dresult,s   ;
         ADDA    1,i         ;
         STWA    dresult,s   ;
         LDWA    dk,s        ;
         BR      forD        ;
;After finding the result, this function 
;  checks what the remainder/modulo value is
checkRmd:LDWA    dk,s        ;TODO comments
         CPWA    div1,s      ;
         BREQ    endForD     ;
         LDWA    dresult,s   ;
         SUBA    1,i         ;
         STWA    dresult,s   ;
         LDWA    dk,s        ;
         SUBA    div2,s      ;
         STWA    dk,s        ;
         LDWA    div1,s      ;
         SUBA    dk,s        ;
         STWA    remaind,s   ;
         BR      endForD     ;
;If dividing by zero, this function is called
;  and sets the result to -1
divZero: LDWA    -1,i        ;TODO comments
         STWA    dresult,s   ;
;The end function that prints out the equation
;  and stores the result
endForD: LDBA    '\n',i      ;TODO comments
         STBA    charOut,d   ;
         LDBA    div1Sign,s  ;
         CPBA    1,i         ;
         BRNE    endForD2    ;
         LDBA    '-',i       ;
         STBA    charOut,d   ;
endForD2:DECO    div1,s      ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         LDBA    '/',i       ;
         STBA    charOut,d   ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         LDBA    div2Sign,s  ;
         CPBA    1,i         ;
         BRNE    endForD3    ;
         LDBA    '-',i       ;
         STBA    charOut,d   ;
endForD3:DECO    div2,s      ;
         LDBA    '\n',i      ;
         STBA    charOut,d   ;
         LDBA    div1Sign,s  ;
         CPBA    div2Sign,s  ;
         BREQ    endForD4    ;
         LDWA    dresult,s   ;
         NOTA                ;
         ADDA    1,i         ;
         STWA    dresult,s   ;
         LDWA    remaind,s   ;
         NOTA                ;
         ADDA    1,i         ;
         STWA    remaind,s   ;
endForD4:LDWA    dresult,s   ;
         STWA    retDiv,s    ;
         ADDSP   6,i         ;pop #result #k #div2Sign #div1Sign 
         RET                 ;

;********* ADD **********
retAdd:  .EQUATE 6           ;returned value #2d 
add1:    .EQUATE 4           ;formal parameter #2d 
add2:    .EQUATE 2           ;formal parameter #2d
;Add function takes two input (add1, add2), adds them together,
;  and returns result in retAdd.
add:     LDWA    add1,s      ;load first value to accumulator
         ADDA    add2,s      ;add second value to it
         STWA    retAdd,s    ;store in the result
         BR      endForA     ;move to the end!
endForA: LDBA    '\n',i      ;TODO comments
         STBA    charOut,d   ;
         DECO    add1,s      ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         LDBA    '+',i       ;
         STBA    charOut,d   ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         DECO    add2,s      ;
         LDBA    '\n',i      ;
         STBA    charOut,d   ;
         RET                 ;

;********* SUBTRACT **********
retSub:  .EQUATE 6           ;returned value #2d 
sub1:    .EQUATE 4           ;formal parameter #2d 
sub2:    .EQUATE 2           ;formal parameter #2d
;Subtract function takes two input (sub1, sub2), subtracts sub2 from sub1,
;  and returns result in retSub.
sub:     LDWA    sub1,s      ;load first value to accumulator
         SUBA    sub2,s      ;subtract the second
         STWA    retSub,s    ;store result in retSub
         BR      endForS     ;move to the end!
endForS: LDBA    '\n',i      ;TODO comments
         STBA    charOut,d   ;
         DECO    sub1,s      ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         LDBA    '-',i       ;
         STBA    charOut,d   ;
         LDBA    ' ',i       ;
         STBA    charOut,d   ;
         DECO    sub2,s      ;
         LDBA    '\n',i      ;
         STBA    charOut,d   ;
         RET                 ;
         
end:     .END
         