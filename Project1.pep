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

expNum:  .WORD   1           ;true or false for expecting next input to be number #2d
nextNeg: .WORD   0           ;mask for next decimal, can be 0x0000 or 0x1000 if negative #2h
skipNum: .WORD   0           ;the number of times to skip checking the input #2d

value:   .WORD   0           ;temporary storage for integer intake #2d
num1:    .BLOCK  2           ;variable for multidigit intake, num1 is the current digit/char #2d 
num2:    .BLOCK  2           ;variable for multidigit intake, num2 is used to look ahead for more digits #2d
num3:    .BLOCK  2           ;variable for multidigit intake, num3 is used to look ahead for certain long operators #2d 

errMsg:  .ASCII  "SYNTAX ERROR: Unexpected Operator: \x00"
errMsg2: .ASCII  "bad operator input index: \x00"

;MAIN

main:    LDBA    charIn,d       ;prep for first run by populating num2
         SUBA    0x30,i         ;convert to deci
         STWA    num2,d
         LDBA    charIn,d       ;prep for first run by populating num3
         SUBA    0x30,i         ;convert to deci
         STWA    num3,d
loop:    LDWA    num2,d         ;shift input chars num1 <- num2, num2 <- num3, num3 <- charIn
         STWA    num1,d
         LDWA    num3,d
         STWA    num2,d
         LDWA    0x0000,i       ;clear accumulator
         LDBA    charIn,d
         SUBA    0x30,i         ;convert to deci
         STWA    num3,d

         ;the skip check code is used to skip over unwanted/extra input characters
         ;for example, after reading in AND, reading the ND in the next loop should be avoided   
         LDWA    skipNum,d      ;if skipNum == 0, go on to analyze the input, else, skip analization
         CPWA    0,i
         BREQ    goOn
         SUBA    1,i            ;decrement skipNum by 1
         STWA    skipNum,d
         BR      loop             ;go back to start of loop without checking current input char
         
goOn:    LDWA    num1,d         ;if num1 is not deci, store as char, else add it to value
         CPWA    9,i            ;check for int by checking for range 0
         BRGT    notDec
         CPWA    0,i
         BRLT    notDec
         ADDA    value,d
         STWA    value,d
         LDWA    num2,d         ;if num2 is not deci, store current value, else multiply value by 10
         CPWA    9,i
         BRGT    decDone
         CPWA    0,i
         BRLT    decDone
         LDWA    10,i           ;Call the multiplication function to multiply 'value' by 10
         STWA    -4,s         
         LDWA    value,d
         STWA    -6,s
         SUBSP   6,i           ;push #retVal #mult1 #mult2 
         CALL    multiply    
         LDWA    4,s
         STWA    value,d
         ADDSP   6,i           ;pop #mult2 #mult1 #retVal 
         BR      loop             ;loop back to get next digit

;Check for character(s) type and convert to a singular operand for array storage.

notDec:  LDBA    1,i         ;set is char to true
         STBA    isChar,d
  
         LDWA    num1,d      ;load current operator to A
         ADDA    0x0030,i    ;convert back to ascii char
         
         CPWA    0x000A,i    ;check if input is finished by looking for LB, if so, move to postFix
         BREQ    addOps
         CPWA    0x0020,i    ;check for white space and skip over if found
         BREQ    loop

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

badOp:   STRO    errMsg,d    ;output a message explaining the error
         LDWA    num1,d
         ADDA    0x30,i
         STBA    charOut,d
         BR      end        
         
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
         LDWA nextNeg,d      ;if a negative sign was found, negate the value, else skip
         CPWA 0,i
         BREQ pos
         LDWA value,d
         NEGA
         STWA value,d 
         
pos:     LDWA value,d
         LDWX vecI,d         ;load inVec index
         STWA inVec,x        ;store in array
         LDWA vecI,d         ;increment index & length
         ADDA 2,i
         STWA vecI,d
         ASRA
         STWA inVecL,d
         LDWA 0,i            ;reset value
         STWA value,d 
         STWA expNum,d       ;expecting decimal is now false
         STWA nextNeg,d      ;any negative symbol have now been processed, set to false
         BR loop  

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

;*****OPERATOR FUNCTIONS******
;Operator functions can handle any shorts (-65535 to 65535)
;But cannot handle calculations above/below that
;*****************************

;LOCAL VARIABLES
retVal:  .EQUATE 12          ;returned value #2d
mult1:   .EQUATE 10          ;formal parameter #2d
mult2:   .EQUATE 8           ;formal parameter #2d
m1Sign:  .EQUATE 5           ;local variable #1d
m2Sign:  .EQUATE 4           ;local variable #1d
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
chckM1:  LDWA    mult1,s     ;TODO comments
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
endForM: LDBA    m1Sign,s    ;
         CPBA    m2Sign,s    ;
         BREQ    endForM2    ;
         LDWA    result,s    ;
         NOTA                ;
         ADDA    1,i         ;
         STWA    result,s    ;
endForM2:LDWA    result,s    ;
         STWA    retVal,s    ;
         LDWA    0,i         ;cleanup
         STWA    k,s
         STWA    result,s
         LDBA    0,i
         STBA    m1Sign,s
         STBA    m2Sign,s
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
endForD: LDBA    div1Sign,s  ;
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
         LDWA    0,i         ;cleanup
         STWA    dk,s
         STWA    dresult,s
         LDBA    0,i
         STBA    div1Sign,s
         STBA    div2Sign,s
         ADDSP   6,i         ;pop #dresult #dk #div2Sign #div1Sign 
         RET                 ;

;********* ADD **********
retAdd:  .EQUATE 6           ;returned value #2d 
add1:    .EQUATE 4           ;formal parameter #2d 
add2:    .EQUATE 2           ;formal parameter #2d
add:     LDWA    add1,s      
         ADDA    add2,s      
         STWA    retAdd,s    
         BR      endForA     
endForA: RET                 

retSub:  .EQUATE 6           ;returned value #2d
sub1:    .EQUATE 4           ;formal parameter #2d
sub2:    .EQUATE 2           ;formal parameter #2d
;Subtract function takes two input (sub1, sub2), subtracts sub2 from sub1,
;  and returns result in retSub.
sub:     LDWA    sub1,s      ;load first value to accumulator
         SUBA    sub2,s      ;subtract the second
         STWA    retSub,s    ;store result in retSub
         BR      endForS     ;move to the end!
endForS: RET                 ;

;********* XOR ********** TODO fix comments
retXor:  .EQUATE 10          ;returned value #2d 
xor1:    .EQUATE 8           ;formal parameter #2d 
xor2:    .EQUATE 6           ;formal parameter #2d
tempx1:  .EQUATE 2           ;local variable #2d
tempx2:  .EQUATE 0           ;local variable #2d
;Subtract function takes two input (sub1, sub2), subtracts sub2 from sub1,
;  and returns result in retSub.
xor:     SUBSP   4,i         ;push #tempx1 #tempx2
         LDWA    xor1,s      ;load first value to accumulator
         ANDA    xor2,s      ;and the second
         STWA    tempx1,s
         LDWA    xor1,s
         ORA     xor2,s
         STWA    tempx2,s
         SUBA    tempx1,s
         STWA    retXor,s    ;store result in retSub\
         BR      endForX     ;move to the end!
endForX: LDWA    0,i
         STWA    tempx1,s
         STWA    tempx2,s
         ADDSP   4,i         ;pop #tempx1 #tempx2
         RET                 ;
         
end:     .END
         