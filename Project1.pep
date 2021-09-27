;********************************************************************
; Names:   Charles Kinser
;          ADD YOUR NAME
;          ADD YOUR NAME
;          ADD YOUR NAME
; Lab:     Project
; Date:    9/26/2021
; Purpose:
;********************************************************************

;********************************************************************
; Names:   Charles Kinser
;          ADD YOUR NAME
;          ADD YOUR NAME
;          ADD YOUR NAME
; Lab:     Project
; Date:    9/26/2021
; Purpose:
;********************************************************************

;*****************************
;VARIABLES
;*****************************

skip:    BR main

inVec:   .BLOCK  128         ;array of characters and values from input, global array #2c64a
                             ;the input is convereted into an array to allow access multiple times 
vecI:    .WORD   0           ;store current index of inVec array when register is in use #2d
inVecL:  .WORD   1           ;length of inVec, global variable #2d

num1:    .BLOCK  2           ;variable for multidigit intake #2d 
num2:    .BLOCK  2           ;variable for multidigit intake #2d 
value:   .WORD   0           ;temporary storage for integer intake #2d

;*****************************
;INPUT TO ARRAY
;*****************************

main:    LDBA charIn,d       ;prep for first run by populating num2
         SUBA 0x30,i         ;convert to deci
         STWA num2,d
loop:    LDWA num2,d         ;shift input chars
         STWA num1,d
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
         ;TODO multiply value by 10
         STWA value,d
         BR loop

notDec:  ADDA 0x30,i         ;convert back to ascii char
         LDWX vecI,d         ;load inVec index
         STWA inVec,x        ;store in array
         LDWA vecI,d         ;increment index & length
         ADDA 1,i
         STWA vecI,d
         STWA inVecL,d 
         LDWA 0,i            ;reset value 
         STWA value,d  
         BR loop           
             
decDone: LDWA value,d
         LDWX vecI,d         ;load inVec index
         STWA inVec,x        ;store in array
         LDWA vecI,d         ;increment index & length
         ADDA 1,i
         STWA vecI,d
         ADDA 1,i
         STWA inVecL,d
         LDWA 0,i            ;reset value
         STWA value,d
         LDWA num2,d         ;check if input is finished, if so, move to postFix  
         CPWA '\n',d
         BREQ postFix
         BR loop           

postFix:  .end ;TODO
                  
retVal:  .EQUATE 12          ;returned value #2d
mult1:   .EQUATE 10          ;formal parameter #2d
mult2:   .EQUATE 8           ;formal parameter #2d
m1Sign:  .EQUATE 5           ;local variable #1d
m2Sign:  .EQUATE 4           ;local variable #1d
k:       .EQUATE 2           ;local variable #2d
result:  .EQUATE 0           ;local variable #2d
multiply:SUBSP   6,i         ;push #m1Sign #m2Sign #k #result 
         LDWA    0,i
         STWA    result,s
         LDBA    0,i
         STBA    m1Sign,s
         STBA    m2Sign,s
         LDWA    mult1,s
         CPWA    0,i
         BRGT    multp1
abs1:    NOTA
         ADDA    1,i
         STWA    mult1,s
         LDBA    1,i
         STBA    m1Sign,s 
multp1:  LDWA    mult2,s
         CPWA    0,i
         BRGT    multp2
abs2:    NOTA
         ADDA    1,i
         STWA    mult2,s
         LDBA    1,i
         STBA    m2Sign,s 
multp2:  LDWA    1,i         ;for (k = 1
         STWA    k,s         
forM:    CPWA    mult2,s     ;k <= mult2 
         BRGT    endForM     
         LDWA    result,s
         ADDA    mult1,s
         STWA    result,s
         LDWA    k,s         ;k++)
         ADDA    1,i         
         STWA    k,s         
         BR      forM        
endForM: LDBA    '\n',i      ;printf("\n")
         STBA    charOut,d
         LDBA    m1Sign,s 
         CPBA    1,i
         BRNE    endForM2
         LDBA    '-',i
         STBA    charOut,d
endForM2:DECO    mult1,s
         LDBA    ' ',i      ;printf(" ")
         STBA    charOut,d
         LDBA    '*',i      ;printf(" ")
         STBA    charOut,d
         LDBA    ' ',i      ;printf(" ")
         STBA    charOut,d
         LDBA    m2Sign,s 
         CPBA    1,i
         BRNE    endForM3
         LDBA    '-',i
         STBA    charOut,d
endForM3:DECO    mult2,s
         LDBA    '\n',i
         STBA    charOut,d
         LDBA    m1Sign,s
         CPBA    m2Sign,s
         BREQ    endForM4
         LDWA    result,s
         NOTA
         ADDA    1,i
         STWA    result,s
endForM4:LDWA    result,s
         STWA    retVal,s
         ADDSP   6,i         ;pop #result #k #m1Sign #m2Sign 
         RET                  

remaind: .EQUATE 14          ;returned value #2d
retDiv:  .EQUATE 12          ;returned value #2d 
div1:    .EQUATE 10          ;formal parameter #2d
div2:    .EQUATE 8           ;formal parameter #2d
div1Sign:.EQUATE 5           ;local variable #1d
div2Sign:.EQUATE 4           ;local variable #1d
dk:      .EQUATE 2           ;local variable #2d
dresult: .EQUATE 0           ;local variable #2d
divide:  SUBSP   6,i         ;push #div1Sign #div2Sign #dk #dresult 
         LDWA    0,i
         STWA    dresult,s
         STWA    dk,s         
         STWA    remaind,s
         LDBA    0,i
         STBA    div1Sign,s
         STBA    div2Sign,s
         LDWA    div1,s 
         CPWA    0,i
         BRGT    divp1
absD1:   NOTA    
         ADDA    1,i
         STWA    div1,s
         LDBA    1,i
         STBA    div1Sign,s
divp1:   LDWA    div2,s
         CPWA    0,i
         BREQ    divZero
         BRGT    divp2
absD2:   NOTA
         ADDA    1,i
         STWA    div2,s
         LDBA    1,i
         STBA    div2Sign,s
divp2:   LDWA    0,i         ;for (k = 1
         STWA    dk,s         
         LDWA    dk,s
forD:    CPWA    div1,s     ;dk >= div1
         BRGE    checkRmd   
         LDWA    dk,s
         ADDA    div2,s 
         STWA    dk,s
         LDWA    dresult,s         ;k++)
         ADDA    1,i         
         STWA    dresult,s
         LDWA    dk,s         
         BR      forD       
checkRmd:LDWA    dk,s
         CPWA    div1,s
         BREQ    endForD
         LDWA    dresult,s
         SUBA    1,i
         STWA    dresult,s
         LDWA    dk,s
         SUBA    div2,s
         STWA    dk,s
         LDWA    div1,s
         SUBA    dk,s
         STWA    remaind,s
         BR      endForD
divZero: LDWA    -1,i
         STWA    dresult,s
endForD: LDBA    '\n',i      ;printf("\n")
         STBA    charOut,d
         LDBA    div1Sign,s 
         CPBA    1,i
         BRNE    endForD2
         LDBA    '-',i
         STBA    charOut,d
endForD2:DECO    div1,s
         LDBA    ' ',i      ;printf(" ")
         STBA    charOut,d
         LDBA    '/',i      ;printf(" ")
         STBA    charOut,d
         LDBA    ' ',i      ;printf(" ")
         STBA    charOut,d
         LDBA    div2Sign,s 
         CPBA    1,i
         BRNE    endForD3
         LDBA    '-',i
         STBA    charOut,d
endForD3:DECO    div2,s
         LDBA    '\n',i
         STBA    charOut,d
         LDBA    div1Sign,s 
         CPBA    div2Sign,s 
         BREQ    endForD4
         LDWA    dresult,s
         NOTA
         ADDA    1,i
         STWA    dresult,s
         LDWA    remaind,s
         NOTA
         ADDA    1,i
         STWA    remaind,s
endForD4:LDWA    dresult,s
         STWA    retDiv,s
         ADDSP   6,i         ;pop #result #k #div2Sign #div1Sign 
         RET

;******* void printBar(int n)
retAdd:  .EQUATE 6           ;returned value #2d 
add1:   .EQUATE 4           ;formal parameter #2d 
add2:   .EQUATE 2           ;formal parameter #2d
add:     LDWA    add1,s
         ADDA    add2,s
         STWA    retAdd,s
         BR      endForA
endForA: LDBA    '\n',i      ;printf("\n")
         STBA    charOut,d
         DECO    add1,s
         LDBA    ' ',i       ;printf(" ")
         STBA    charOut,d
         LDBA    '+',i       ;printf(" ")
         STBA    charOut,d
         LDBA    ' ',i       ;printf(" ")
         STBA    charOut,d
         DECO    add2,s
         LDBA    '\n',i
         STBA    charOut,d
         RET   

retSub:  .EQUATE 6           ;returned value #2d 
sub1:    .EQUATE 4           ;formal parameter #2d 
sub2:    .EQUATE 2           ;formal parameter #2d
sub:     LDWA    sub1,s
         SUBA    sub2,s
         STWA    retSub,s
         BR      endForS
endForS: LDBA    '\n',i      ;printf("\n")
         STBA    charOut,d
         DECO    sub1,s
         LDBA    ' ',i       ;printf(" ")
         STBA    charOut,d
         LDBA    '-',i       ;printf(" ")
         STBA    charOut,d
         LDBA    ' ',i       ;printf(" ")
         STBA    charOut,d
         DECO    sub2,s
         LDBA    '\n',i
         STBA    charOut,d
         RET  
         
         