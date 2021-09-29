;********************************************************************
; Names:   Charles Kinser
;          Dante Hays
;          ADD YOUR NAME
;          ADD YOUR NAME
; Lab:     Project
; Date:    9/26/2021
; Purpose:
;********************************************************************

;*****************************
;VARIABLES
;*****************************

skip:    BR      main        

inVec:   .BLOCK  128         ;array of characters and values from input, global array #2c64a
;the input is convereted into an array to allow access multiple times

vecI:    .WORD   0           ;store current index of inVec array when register is in use #2d
inVecL:  .WORD   1           ;length of inVec, global variable #2d

num1:    .BLOCK  2           ;variable for multidigit intake, num1 is the current digit/char #2d
num2:    .BLOCK  2           ;variable for multidigit intake, num2 is used to look ahead for more digits #2d
value:   .WORD   0           ;temporary storage for integer intake #2d


;opBlock:  .BLOCK  16          ;block for storing operators
;opNum:    .WORD   0           ;# of operators stored
newOp:   .WORD   0           ;stores current operator
prevOp:  .WORD   0           ;stores lowest prec op
newPrc:  .BYTE   0           ;stores new op precedence
prevPrc: .BYTE   0           ;stores prev op precedence

;*****************************
;INPUT TO ARRAY
;*****************************

main:    LDBA    charIn,d    ;prep for first run by populating num2
         SUBA    0x0030,i    ;convert to deci
         STWA    num2,d      
loop:    LDWA    num2,d      ;shift input chars num1 <- num2, num2 <- charIn
         STWA    num1,d      
         LDWA    0x0000,i    ;clear accumulator
         LDBA    charIn,d    
         SUBA    0x0030,i    ;convert to deci
         STWA    num2,d      

         LDWA    num1,d      ;if num1 is not deci, store as char, else add to value
         CPWA    9,i         ;check for int by checking for range 0
         BRGT    notDec      
         CPWA    0,i         
         BRLT    notDec      
         ADDA    value,d     
         STWA    value,d     


         LDWA    num2,d      ;if num2 is not deci, handle the char, else multiply value by 10
         CPWA    9,i         
         BRGT    decDone     
         CPWA    0,i         
         BRLT    decDone     
         LDWA    value,d     
         LDWA    10,i        ;move value
         STWA    -4,s        
         LDWA    value,d     
         STWA    -6,s        
         SUBSP   6,i         ;push #retVal #mult1 #mult2
         CALL    multiply    
         LDWA    4,s         
         STWA    value,d     
         ADDSP   6,i         ;pop #mult2 #mult1 #retVal
         BR      loop        

decDone: LDWA    value,d     
         LDWX    vecI,d      ;load inVec index
         STWA    inVec,x     ;store in array
         LDWA    vecI,d      ;increment index & length
         ADDA    2,i         
         STWA    vecI,d      
         ASRA                
         STWA    inVecL,d    
         LDWA    0,i         ;reset value
         STWA    value,d     
         BR      loop        

notDec:  ADDA    0x0030,i    ;convert back to ascii char
         CPWA    0x000A,i    ;check if input is finished, if so, end execution
         BREQ    addOps      
         BR      prcSet      ;else branch to set precedence

;Postfix Conversion Stuff

prcSet:  CPWA    0x002B,i    ;compare to addition symbol
         BREQ    prc1        ;if addition symbol is found branch to set precedence
         CPWA    0x002D,i    ;compare to subtraction symbol
         BREQ    prc1        ;if subtraction symbol is found branch to set precedence
         CPWA    0x002A,i    ;compare to multiplication symbol
         BREQ    prc2        ;if multiplication symbol is found branch to set precedence
         CPWA    0x002F,i    ;compare to division symbol
         BREQ    prc2        ;if division symbol is found branch to set precedence
         BR      loop        

prc1:    LDBA    1,i         ;load 1 into A
         STBA    newPrc,d    ;store precedence of 1 to newPrc
         BR      chkPrc      ;branch to precedence check

prc2:    LDBA    2,i         ;load 2 into A
         STBA    newPrc,d    ;store precedence of 2 to newPrc
         BR      chkPrc      ;branch to precedence check

chkPrc:  LDBA    prevPrc,d   ;load previous precedence to A
         CPBA    0,i         ;compare to 0 to see if there is a previous operand
         BREQ    storeOp     ;branch to store if previous precedence is 0
         CPBA    newPrc,d    ;compare to new op precedence
         BREQ    swapOp      ;if they are equal swap them
         BR      storeOp     ;else store the operator

;I have tried a few different ways of storing operands and all have failed miserably
;Deleted spaghetti mess of code

swapOp:  BR      end         

storeOp: LDWA    newOp,d     ;load new operator to A
         STBA    prevOp,d    ;store new op to topOp
         LDWA    newPrc,d    ;load newOp precedence
         STBA    prevPrc,d   ;store as previous precedence
         LDWA    num1,d      ;load current op to A
         ADDA    0x0030,i    ;convert to ascii
         STWA    newOp,d     ;store current op


         BR      end         

addOps:  BR      end         



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
