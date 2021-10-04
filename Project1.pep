;********************************************************************
; Names:   Charles Kinser
;          Drew Dorris
;          Dante Hays
;          ADD YOUR NAME
; Lab:     Project
; Date:    9/26/2021
; Purpose:
;********************************************************************

;*****************************
;GLOBAL VARIABLES
;*****************************

skip:    BR      main        

inVec:   .BLOCK  128         ;array of characters and values from input, global array #2d64a
;the input is convereted into an array to allow access multiple times
;and to simplify expressions for other methods
vecI:    .WORD   0           ;store current index of inVec array when register is in use #2d
inVecL:  .WORD   1           ;length of inVec, global variable #2d   
isChar:  .BYTE   0           ;stores if the given value stored to array is a char
isDeci:  .BYTE   0           ;stores if the given value stored to array is a deci

;*****************************
;INPUT TO ARRAY
;*****************************

;LOCAL VARIABLES

expNum:  .WORD   0           ;true or false for expecting next input to be number #2d
nextNeg: .WORD   0           ;mask for next decimal, can be 0x0000 or 0x1000 if negative #2h
skipNum: .WORD   0           ;the number of times to skip checking the input #2d

value:   .WORD   0           ;temporary storage for integer intake #2d
num1:    .BLOCK  2           ;variable for multidigit intake, num1 is the current digit/char #2d
num2:    .BLOCK  2           ;variable for multidigit intake, num2 is used to look ahead for more digits #2d
num3:    .BLOCK  2           ;variable for multidigit intake, num3 is used to look ahead for certain long operators #2d

;MAIN

main:    LDBA    charIn,d    ;prep for first run by populating num2
         SUBA    0x0030,i    ;convert to deci
         STWA    num2,d      
         LDBA    charIn,d    ;prep for first run by populating num3
         SUBA    0x0030,i    ;convert to deci
         STWA    num3,d      
loop:    LDWA    num2,d      ;shift input chars num1 <- num2, num2 <- num3, num3 <- charIn
         STWA    num1,d      
         LDWA    num3,d      
         STWA    num2,d      
         LDWA    0x0000,i    ;clear accumulator
         LDBA    charIn,d    
         SUBA    0x0030,i    ;convert to deci
         STWA    num3,d      

;the skip check code is used to skip over unwanted/extra input characters
;for example, after reading in AND, reading the ND in the next loop should be avoided

         LDWA    skipNum,d   ;if skipNum == 0, go on to analyze the input, else, skip analization
         CPWA    0,i         
         BREQ    goOn        
         SUBA    1,i         ;decrement skipNum by 1
         STWA    skipNum,d   
         BR      loop        ;go back to start of loop without checking current input char

goOn:    LDWA    num1,d      ;if num1 is not deci, store as char, else add it to value
         CPWA    9,i         ;check for int by checking for range 0
         BRGT    notDec      
         CPWA    0,i         
         BRLT    notDec      
         ADDA    value,d     
         STWA    value,d     


         LDWA    num2,d      ;if num2 is not deci, store current value, else multiply value by 10
         CPWA    9,i         
         BRGT    decDone     
         CPWA    0,i         
         BRLT    decDone     
         LDWA    10,i        ;Call the multiplication function to multiply 'value' by 10
         STWA    -4,s        
         LDWA    value,d     
         STWA    -6,s        
         SUBSP   6,i         ;push #retVal #mult1 #mult2
         CALL    multiply    
         LDWA    4,s         
         STWA    value,d     
         ADDSP   6,i         ;pop #mult2 #mult1 #retVal
         BR      loop        ;loop back to get next digit

;Check for character(s) type and convert to a singular operand for array storage.

notDec:  LDBA    1,i         ;set is char to true
         STBA    isChar,d
         
         LDWA    num1,d      ;load current operator to A
         ADDA    0x0030,i    ;convert back to ascii char
         
         CPWA    0x000A,i    ;check if input is finished by looking for LB, if so, move to postFix
         BREQ    addOps               

         CPWA    '-',i       ;go to negChk to determine if the - is a minus sign or a negative sign
         BREQ    negChk      
         CPWA    '+',i       ;If the current character matches a simple op. assign precedence and store accordingly
         BREQ    prc5        
         CPWA    '*',i       
         BREQ    prc6        
         CPWA    '/',i       
         BREQ    prc6        
         CPWA    '%',i       
         BREQ    prc6        
         CPWA    '\|',i      
         BREQ    prc1        
         CPWA    '&',i       
         BREQ    prc3        
         CPWA    '^',i       
         BREQ    prc2        

andChk:  CPWA    'A',i       ;Check for the AND characters in series
         BRNE    orChk       
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'N',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    num3,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'D',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    2,i         ;load value into skipNum to skip over excess character(s) (N and D)
         STWA    skipNum,d   
         LDWA    '&',i       
         BR      prc3        

xorChk:  LDWA    num1,d      ;Check for the XOR characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'X',i       
         BRNE    orChk       
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'O',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    num3,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'R',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    2,i         ;load value into skipNum to skip over excess character(s) (N and D)
         STWA    skipNum,d   
         LDWA    '^',i       
         BR      prc2        

orChk:   LDWA    num1,d      ;Check for the OR characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'O',i       
         BRNE    lShftChk    
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'R',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    1,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '\|',i      
         BR      prc1        

lShftChk:LDWA    num1,d      ;Check for the << characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '<',i       
         BRNE    rShftChk    
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '<',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    1,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '<',i       
         BR      prc4        ;assign precedence for operator and store

rShftChk:LDWA    num1,d      ;Check for the >> or >>> characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '>',i       
         BRNE    rLog        
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '>',i       
         BRNE    end         ;ERROR, incomplete/invalid operator
         LDWA    num3,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '>',i       
         BREQ    rLog        
         LDWA    1,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '}',i       
         BR      prc4        ;assign precedence for operator and store
rLog:    LDWA    2,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '>',i       
         BR      prc4        ;assign precedence for operator and store

negChk:  LDWA    expNum,d    ;if expecting an int, set next integer to be negative, else, store a minus sign into array
         CPWA    0x0001,i    
         BREQ    negT        
         LDWA    '-',i       
         BR      prc5        ;assign precedence for operator and store
negT:    LDWA    1,i         ;set next integer to be negative
         STWA    nextNeg,d   
         BR      loop        

;add current accumulator word to the array

arayStor:LDWX    vecI,d      ;load inVec index
         STWA    inVec,x     ;store in array
         LDWA    vecI,d      ;increment index & length
         ADDA    2,i         
         STWA    vecI,d      
         ASRA                ;set length of array
         STWA    inVecL,d    
         LDBA    swapTrue,d  ;check to see if a swap occured
         CPBA    1,i         ;if so branch to end the swap
         BREQ    swapped    
         LDBA    addTrue,d   ;check to see if an add has occured
         CPBA    1,i         ;if so branch back to continue adding
         BREQ    addOps      
         LDWA    0,i         ;reset value
         STWA    value,d     
         LDWA    1,i         ;expecting decimal is now true
         STWA    expNum,d    
         BR      loop   
     
;store the value of the current int after combining digit characters into one int

decDone: LDBA    1,i         ;set is deci to true
         STBA    isDeci,d
         LDWA    value,d     ;load decimal value to be stored to A
         ORA     nextNeg,d   ;apply negative mask
         LDWX    vecI,d      ;load inVec index
         STWA    inVec,x     ;store in array
         LDWA    vecI,d      ;increment index & length
         ADDA    2,i         
         STWA    vecI,d      
         ASRA                
         STWA    inVecL,d    
         LDWA    0,i         ;reset value
         STWA    value,d     
         STWA    expNum,d    ;expecting decimal is now false
         BR      loop        

;*****************************
;POSTFIX CONVERSION
;*****************************

;LOCAL VARIABLES

opArray: .BLOCK  32          ;array of operators to be stored into final array
opIndex: .WORD   0           ;stores index of operators in op array
prcArray:.BLOCK  32          ;array of operator precedence
prcIndex:.WORD   2           ;stores indec of operator precedence in prc array
swapTrue:.BYTE   0           ;stores if a swap has occured
addTrue: .BYTE   0           ;stores if add has been called
newPrc:  .WORD   0           ;stores new opertor precedence
prevPrc: .WORD   0           ;stores previous operator precedence


prc1:    LDBA    1,i         ;load 1 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d   ;store new index
         BR      chkPrc      ;branch to precedence check

prc2:    LDBA    2,i         ;load 2 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d   ;store new index
         BR      chkPrc      ;branch to precedence check

prc3:    LDBA    3,i         ;load 3 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d   ;store new index
         BR      chkPrc      ;branch to precedence check

prc4:    LDBA    4,i         ;load 4 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d   ;store new index
         BR      chkPrc      ;branch to precedence check

prc5:    LDBA    5,i         ;load 5 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d   ;store new index
         BR      chkPrc      ;branch to precedence check

prc6:    LDBA    6,i         ;load 6 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d   ;store new index
         BR      chkPrc      ;branch to precedence check

chkPrc:  LDWX    prcIndex,d  ;load precedence array index
         SUBX    2,i         ;decrement to top precedence index
         LDWA    prcArray,x  ;load the precedence to A
         STWA    newPrc,d    ;store the current precedence to var
         LDWX    prcIndex,d  ;load precedence array index
         SUBX    4,i         ;decrement to previous index
         LDWA    prcArray,x  ;load the precedence to A
         STWA    prevPrc,d   ;store the previous precedence to var 
         CPWA    newPrc,d    ;compare to new op precedence
         BRLT    swapDone    ;if the new op is higher precedence store it
         BR      swapOp      ;else swap the operators

opAryStr:LDWA    num1,d      ;load current op
         ADDA    0x0030,i    ;convert to ascii char
         LDWX    opIndex,d   ;load operator array index
         STWA    opArray,x   ;store op in array
         LDWA    opIndex,d   ;increment op index
         ADDA    2,i         
         STWA    opIndex,d   ;store new index  
         LDWA    0,i         ;reset value
         STWA    value,d     
         LDWA    1,i         ;expecting decimal is now true
         STWA    expNum,d    
         BR      loop        

swapOp:  LDBA    1,i         ;set swap to true
         STBA    swapTrue,d  
         LDWX    opIndex,d   ;load operator array index
         SUBX    2,i         ;decrement to previously stored operator
         STWX    opIndex,d   ;store the new operator index
         LDWA    opArray,x   ;store the op to A
         BR      arayStor    ;store the operator in the output array
swapped: LDWX    prcIndex,d  ;load precedence array index
         SUBX    2,i         ;decrement by one operator
         STWX    prcIndex,d  ;store new index
         SUBX    2,i         ;overwrite previous top op precedence
         LDWA    newPrc,d    ;load new operator precedence
         STWA    prcArray,x  ;store it in the new top index
         BR      chkPrc      ;recheck precedence with two top ops
swapDone:LDBA    0,i         ;set swap to false
         STBA    swapTrue,d     
         BR      opAryStr    ;store the new operator in the op array

addOps:  LDBA    1,i         ;set add to true
         STBA    addTrue,d   
         LDWX    opIndex,d   ;load the top operator index
         CPWX    0,i         ;if the array still has elements continue
         BREQ    end         ;else branch to solve 
                             ;******************************************This is the end of the postfix********************************************
                             ;******************************************will need to branch to solve**********************************************
         SUBX    2,i         ;move to the top operator
         STWX    opIndex,d   ;store the new index
         LDWA    opArray,x   ;store the op to A
         BR      arayStor    ;store the value to the output array

;*****************************
;MULTIPLICATION/DIVISION
;*****************************

;LOCAL VARIABLES
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
         LDBA    ' ',i       ;printf(" ")
         STBA    charOut,d   
         LDBA    '*',i       ;printf(" ")
         STBA    charOut,d   
         LDBA    ' ',i       ;printf(" ")
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
forD:    CPWA    div1,s      ;dk >= div1
         BRGE    checkRmd    
         LDWA    dk,s        
         ADDA    div2,s      
         STWA    dk,s        
         LDWA    dresult,s   ;k++)
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
         LDBA    ' ',i       ;printf(" ")
         STBA    charOut,d   
         LDBA    '/',i       ;printf(" ")
         STBA    charOut,d   
         LDBA    ' ',i       ;printf(" ")
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
add1:    .EQUATE 4           ;formal parameter #2d
add2:    .EQUATE 2           ;formal parameter #2d
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

end:     .END                  
