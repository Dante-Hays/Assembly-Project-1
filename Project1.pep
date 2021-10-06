;********************************************************************
; Names:   Charles Kinser
;          Drew Dorris
;          Dante Hays
;          Matthew Lockard
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

;*****************************
;DISPLAY
;*****************************
;MAIN
main:    STRO    menu,d      ;display the starting menu
askPr:   STRO    prompt,d    ;display the user prompt
         BR      start

;*****************************
;INPUT TO ARRAY
;*****************************

;LOCAL VARIABLES

expNum:  .WORD   1           ;true or false for expecting next input to be number #2d
nextNeg: .WORD   0           ;mask for next decimal, can be 0x0000 or 0x1000 if negative #2h
skipNum: .WORD   0           ;the number of times to skip checking the input #2d
stopFlg: .WORD   0           ;boolean for stoping char intake #2d

value:   .WORD   0           ;temporary storage for integer intake #2d
num1:    .BLOCK  2           ;variable for multidigit intake, num1 is the current digit/char #2d
num2:    .BLOCK  2           ;variable for multidigit intake, num2 is used to look ahead for more digits #2d
num3:    .BLOCK  2           ;variable for multidigit intake, num3 is used to look ahead for certain long operators #2d
operand: .WORD   0           ;variable for storing operand #2c
opTemp:  .WORD   0           ;temp var for storing operand while swapping #2c




start:   LDWA    0,i         ;clear the array if needed
         LDWX    inVecL,d    ;starting at the highest index, zero all values
         STWA    inVec,x
         SUBX    1,i
         STWX    inVecL,d
         CPWX    0,i
         BRGT    start

         LDWX    63,i 
opClr:   STWA    opArray,x
         STWA    prcArray,x
         SUBX    1,i
         CPWX    0,i
         BRGT    opClr
         
         STWA    vecI,d 
         STWA    stopFlg,d
         STWA    value,d
         STWA    num1,d
         STWA    num2,d
         STWA    num3,d
         STWA    opIndex,d 
         STWA    operand,d
         STWA    opTemp,d 
         STWA    swapTrue,d
         STWA    addTrue,d
         STWA    newPrc,d
         STWA    prevPrc,d
         
         LDWA     2,i
         STWA     prcIndex,d
         
         LDBA    charIn,d    ;prep for first run by populating num2

         CPWA    0x0051,i    ;check if the user wants to quit by looking for Q, if so, goto goodbye
         BREQ    goodbye 

         SUBA    0x30,i      ;convert to deci
         STWA    num2,d
         LDWA    0x0000,i    ;clear accumulator
         LDBA    charIn,d    ;prep for first run by populating num3
         SUBA    0x30,i      ;convert to deci
         STWA    num3,d
loop:    LDWA    num2,d      ;shift input chars num1 <- num2, num2 <- num3, num3 <- charIn
         STWA    num1,d
         LDWA    num3,d
         STWA    num2,d
         LDWA    0x0000,i    ;clear accumulator
         LDWA    stopFlg,d   ;check if input should be taken in
         CPWA    1,i
         BREQ    skipChk
input:   LDBA    charIn,d         
         SUBA    0x30,i      ;convert to deci
         STWA    num3,d

         ADDA    0x30,i      ;Check if line break was found, if so, stop accepting new input
         CPWA    0x0A,i
         BRNE    skipChk
         LDWA    1,i
         STWA    stopFlg,d
         

         ;the skip check code is used to skip over unwanted/extra input characters
         ;for example, after reading in AND, reading the ND in the next loop should be avoided   
skipChk: LDWA    skipNum,d   ;if skipNum == 0, go on to analyze the input, else, skip analization
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
notDec:  LDWA    num1,d      ;load current operator to A
         ADDA    0x0030,i    ;convert back to ascii char
   
         CPWA    0x000A,i    ;check if input is finished by looking for LB, if so, move to postFix
         BREQ    addOps      
         CPWA    0x0020,i    ;check for white space and skip over if found
         BREQ    loop        
         CPWA    '-',i       ;go to negChk to determine if the - is a minus sign or a negative sign
         BREQ    negChk 

         LDWA    expNum,d    ;error out if expecting number
         CPWA    1,i
         BREQ    noNum
         
         LDWA    num1,d
         ADDA    0x30,i
         CPWA    '+',i       ;If the current character matches a simple op. assign precedence and store accordingly
         BREQ    setAdd      
         CPWA    '*',i       
         BREQ    setMult     
         CPWA    '/',i       
         BREQ    setDiv      
         CPWA    '%',i       
         BREQ    setMod      
         CPWA    '\|',i      
         BREQ    setOr       
         CPWA    '&',i       
         BREQ    setAnd      
         CPWA    '^',i       
         BREQ    setXor      

andChk:  CPWA    'A',i       ;Check for the AND characters in series
         BRNE    xorChk       
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'N',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator
         LDWA    num3,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'D',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator
         LDWA    2,i         ;load value into skipNum to skip over excess character(s) (N and D)
         STWA    skipNum,d   
         LDWA    '&',i       
         STWA    operand,d   
         BR      prc3        

xorChk:  LDWA    num1,d      ;Check for the XOR characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'X',i       
         BRNE    orChk       
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'O',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator
         LDWA    num3,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'R',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator
         LDWA    2,i         ;load value into skipNum to skip over excess character(s) (N and D)
         STWA    skipNum,d   
         LDWA    '^',i       
         STWA    operand,d   
         BR      prc2        

orChk:   LDWA    num1,d      ;Check for the OR characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'O',i       
         BRNE    lShftChk    
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    'R',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator
         LDWA    1,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '\|',i      
         STWA    operand,d   
         BR      prc1        

lShftChk:LDWA    num1,d      ;Check for the << characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '<',i       
         BRNE    rShftChk    
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '<',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator
         LDWA    1,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '<',i       
         STWA    operand,d   
         BR      prc4        ;assign precedence for operator and store

rShftChk:LDWA    num1,d      ;Check for the >> or >>> characters in series
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '>',i       
         BRNE    badOp       ;ERROR, incomplete/invalid operator 
         LDWA    num2,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '>',i       
         BRNE    rLog
         LDWA    num3,d      
         ADDA    0x0030,i    ;convert back to ascii char
         CPWA    '>',i       
         BREQ    rLog        
         LDWA    1,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '}',i       
         STWA    operand,d   
         BR      prc4        ;assign precedence for operator and store
rLog:    LDWA    2,i         ;load value into skipNum to skip over excess character(s)
         STWA    skipNum,d   
         LDWA    '>',i       
         STWA    operand,d   
         BR      prc4        ;assign precedence for operator and store

negChk:  LDWA    expNum,d    ;if expecting an int, set next integer to be negative, else, store a minus sign into array
         CPWA    0x0001,i    
         BREQ    negT        
         LDWA    '-',i       
         BR      setSub      ;assign precedence for operator and store
negT:    LDWA    1,i         ;set next integer to be negative
         STWA    nextNeg,d   
         BR      loop

badOp:   STRO    errMsg,d    ;output a message explaining the error
         LDWA    num1,d      ;display bad operator
         ADDA    0x30,i
         STBA    charOut,d
         BR      askPr

noNum:   STRO    errMsg2,d    ;output a message explaining the error
         LDWA    num1,d      ;display bad operator
         ADDA    0x30,i
         STBA    charOut,d
         BR      askPr           

;set operand and its precedence
setAdd:  STWA    operand,d   ;store operand and set precedence
         BR      prc5        

setSub:  STWA    operand,d   ;store operand and set precedence
         BR      prc5        

setMult: STWA    operand,d   ;store operand and set precedence
         BR      prc6        

setDiv:  STWA    operand,d   ;store operand and set precedence
         BR      prc6        

setMod:  STWA    operand,d   ;store operand and set precedence
         BR      prc6        

setAnd:  STWA    operand,d   ;store operand and set precedence
         BR      prc3        

setOr:   STWA    operand,d   ;store operand and set precedence
         BR      prc1        

setXor:  STWA    operand,d   ;store operand and set precedence
         BR      prc2        

;add current accumulator word to the array and prints it to the output
arayStor:STBA    charOut,d   ;print the operator to the output
         LDWA    0x0020,i    ;add a whitespace
         STBA    charOut,d   
         LDWA    operand,d   ;reload operator to A
         LDWX    vecI,d      ;load inVec index
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

;store the value of the current int after combining digit characters into one int and
;prints to output
decDone: LDWA    nextNeg,d   ;if a negative sign was found, negate the value, else skip
         CPWA    0,i         
         BREQ    pos         
         LDWA    value,d     
         NEGA                
         STWA    value,d     

pos:     DECO    value,d     ;print the decimal value to the output
         LDWA    0x0020,i    ;add a whitespace
         STBA    charOut,d   
         LDWA    value,d     
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
         STWA    nextNeg,d   ;any negative symbol have now been processed, set to false
         BR      loop        

;*****************************
;POSTFIX CONVERSION
;*****************************
;This postfix conversion is a branch of the input function and will sort the input as
;it is read in in order to store it to proper postfix notation

;LOCAL VARIABLES
opArray: .BLOCK  64          ;array of operators to be stored into final array
opIndex: .WORD   0           ;stores index of operators in op array
prcArray:.BLOCK  64          ;array of operator precedence
prcIndex:.WORD   2           ;stores indec of operator precedence in prc array
swapTrue:.BYTE   0           ;stores if a swap has occured
addTrue: .BYTE   0           ;stores if add has been called
newPrc:  .WORD   0           ;stores new opertor precedence
prevPrc: .WORD   0           ;stores previous operator precedence

;Assigns precedence of 1 and stores that precedence
prc1:    LDBA    1,i         ;load 1 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d  ;store new index
         BR      chkPrc      ;branch to precedence check

;Assigns precedence of 2 and stores that precedence
prc2:    LDBA    2,i         ;load 2 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d  ;store new index
         BR      chkPrc      ;branch to precedence check

;Assigns precedence of 3 and stores that precedence
prc3:    LDBA    3,i         ;load 3 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d  ;store new index
         BR      chkPrc      ;branch to precedence check

;Assigns precedence of 4 and stores that precedence
prc4:    LDBA    4,i         ;load 4 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d  ;store new index
         BR      chkPrc      ;branch to precedence check

;Assigns precedence of 5 and stores that precedence
prc5:    LDBA    5,i         ;load 5 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d  ;store new index
         BR      chkPrc      ;branch to precedence check

;Assigns precedence of 6 and stores that precedence
prc6:    LDBA    6,i         ;load 6 into A
         LDWX    prcIndex,d  ;load precedence array index
         STWA    prcArray,x  ;store precedence in array
         LDWA    prcIndex,d  ;increment prc index
         ADDA    2,i         
         STWA    prcIndex,d  ;store new index
         BR      chkPrc      ;branch to precedence check

;Compares the new operator precedence to the previous operator precedence
;and decides where to store the new operator
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

;Stores the current operator to the operator array
opAryStr:LDWA    operand,d   ;load operand to A
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

;Swaps the new operator and previous operator then inserts the
;previous operator to the output stack
swapOp:  LDBA    1,i         ;set swap to true
         STBA    swapTrue,d  
         LDWA    operand,d   ;load current operand to A
         STWA    opTemp,d    ;store it to a temp var
         LDWX    opIndex,d   ;load operator array index
         SUBX    2,i         ;decrement to previously stored operator
         STWX    opIndex,d   ;store the new operator index
         LDWA    opArray,x   ;store the op to A
         STWA    operand,d   ;store the operand
         BR      arayStor    ;store the operator in the output array
swapped: LDWA    opTemp,d    ;load the temp var for the operand that was swapped
         STWA    operand,d   ;store it back as the current operand
         LDWX    prcIndex,d  ;load precedence array index
         SUBX    2,i         ;decrement by one operator
         STWX    prcIndex,d  ;store new index
         SUBX    2,i         ;overwrite previous top op precedence
         LDWA    newPrc,d    ;load new operator precedence
         STWA    prcArray,x  ;store it in the new top index
         BR      chkPrc      ;recheck precedence with two top ops
swapDone:LDBA    0,i         ;set swap to false
         STBA    swapTrue,d  
         BR      opAryStr    ;store the new operator in the op array

;Loops through the operator array and stores all operators to the output
addOps:  LDBA    1,i         ;set add to true
         STBA    addTrue,d   
         LDWX    opIndex,d   ;load the top operator index
         CPWX    0,i         ;if the array still has elements continue
         BREQ    postCalc    ;else branch to solve


         SUBX    2,i         ;move to the top operator
         STWX    opIndex,d   ;store the new index
         LDWA    opArray,x   ;load the op to A
         STWA    operand,d   ;store the operand
         BR      arayStor    ;store the value to the output array

;*****************************
;*****PostFix Calculations****
;*****************************
stopati: .BLOCK  2           ;Loop ends at end of array inVecL #2d
stackin: .EQUATE 0           ;local variable #2d

postCalc:LDWA    vecI,d      ;Resets vecI to parse through array
         STWA    stopati,d   ;Saves index as new paramater for if statement #2d
         LDWA    0,i         ;Resets index and length of array
         STWA    vecI,d      
         BR      ifLoops     

ifLoops: LDWX    vecI,d      ;load inVec index
         LDWA    inVec,x     ;load [vecI]array (index of)
         STWA    value,d     
         CPWA    0,i         
         BREQ    output      ;Outputs answer
         LDWA    vecI,d      ;increment index and length
         ADDA    2,i         
         STWA    vecI,d      ;update new index location
         ASRA                
         STWA    inVecL,d    ;update new index length
;If value == decimal, add to stack
         LDWA    value,d     ;Checking to see if array value is opperand
         CPWA    '+',i       
         BREQ    addfunc     ;If operator then branch to addfunc
         CPWA    '-',i       
         BREQ    subfunc     ;If operator then branch to subfunc
;ADD MULT
         CPWA    '*',i       
         BREQ    multfunc    ;If operator then branch to multfunc

         CPWA    '/',i       
         BREQ    divfunc     ;if operator then branch to div func

         CPWA    '%',i
         BREQ    modfunc

         CPWA    '&',i
         BREQ    andfunc

         CPWA    '\|',i
         BREQ    orfunc

         CPWA    '^',i
         BREQ    xorfunc

         LDWA    value,d     
         STWA    stackin,d   
         SUBSP   2,i         ;push #stackin onto stack
         STWA    stackin,s   
         LDWA    0,i         ;reset value
         STWA    value,d     

endifi:  LDWA    stopati,d   ;end loop if i <= vecI (index of array)
         CPWA    vecI,d      
         BRLT    output      ;I dont think we need this here, but i left for now ************************************
         BR      ifLoops     

output:  LDWA    stackin,s   
         STRO    outputs,d   
         DECO    stackin,s   
         BR      askPr

;**************************************
;*********PostFix Calculations*********
;Opperand Decisions and stack managment
;**************************************
RHop:    .BLOCK  2           ;Temperary storage for int intake #2d
LHop:    .BLOCK  2           ;Temperary Storage for int intake #2d
retAdd:  .EQUATE 0           ;returned value #2d
retSub:  .EQUATE 0           ;returned value #2d


;;TODO Finish adding multiplication and Division
;;mulfunc: Call    mul         ;Multiplication Method
;;divfunc: Call    div         ;Division Method


addfunc: LDWA    stackin,s   ;pop
         STWA    RHop,d      ;Saves right hand operator #2d
         ADDSP   2,i         ;pop #stackin
         LDWA    stackin,s   ;pop next item off stack #stackin
         STWA    LHop,d      ;takes item off the stack and stores as Lhop
         ADDSP   2,i         ;pop #stackin
         LDWA    LHop,d      ;load first value to accumulator
         ADDA    RHop,d      ;add second value to it
         STWA    retAdd,d    ;store in the result
         SUBSP   2,i         ;make room for calculation on stack #stackin
         STWA    stackin,s   
         BR      ifLoops     



subfunc: LDWA    stackin,s   ;pop
         STWA    RHop,d      ;Saves right hand operator #2d
         ADDSP   2,i         ;pop #stackin
         LDWA    stackin,s   ;pop next item off stack #stackin
         STWA    LHop,d      ;takes item off the stack and stores as Lhop
         ADDSP   2,i         ;pop #stackin
         LDWA    LHop,d      ;load first value to accumulator
         SUBA    RHop,d      ;add second value to it
         STWA    retSub,d    ;store in the result
         SUBSP   2,i         ;make room for calculation on stack #stackin
         STWA    stackin,s   
         BR      ifLoops     

multfunc:CALL    multiply
         LDWA    4,s
         STWA    retSub,d    ;store in the result
         ADDSP   4,i         ;pop #retVal #stackin ; leave the calculation on the stack for next loop
         STWA    stackin,s   
         BR      ifLoops      

divfunc: CALL    divide
         LDWA    4,s
         STWA    retSub,d    ;store in the result
         ADDSP   4,i         ;pop #retVal #stackin ; leave the calculation on the stack for next loop
         STWA    stackin,s   
         BR      ifLoops          

modfunc: CALL    divide
         LDWA    6,s
         STWA    retSub,d    ;store in the result
         ADDSP   4,i         ;pop #retVal #stackin ; leave the calculation on the stack for next loop
         STWA    stackin,s   
         BR      ifLoops     

andfunc: CALL    and
         LDWA    4,s
         STWA    retSub,d    ;store in the result
         ADDSP   4,i         ;pop #retVal #stackin ; leave the calculation on the stack for next loop
         STWA    stackin,s   
         BR      ifLoops    

orfunc:  CALL    or 
         LDWA    4,s
         STWA    retSub,d    ;store in the result
         ADDSP   4,i         ;pop #retVal #stackin ; leave the calculation on the stack for next loop
         STWA    stackin,s   
         BR      ifLoops    

xorfunc: CALL    xor 
         LDWA    4,s
         STWA    retSub,d    ;store in the result
         ADDSP   4,i         ;pop #retVal #stackin ; leave the calculation on the stack for next loop
         STWA    stackin,s   
         BR      ifLoops     

;*****OPERATOR FUNCTIONS******
;Operator functions can handle any shorts (-65535 to 65535)
;But cannot handle calculations above/below that
;*****************************

;********* MULTIPLY **********
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
         BREQ    endForD2    ;
         LDWA    dresult,s   ;
         NOTA                ;
         ADDA    1,i         ;
         STWA    dresult,s   ;
         LDWA    remaind,s   ;
         NOTA                ;
         ADDA    1,i         ;
         STWA    remaind,s   ;
endForD2:LDWA    dresult,s   ;
         STWA    retDiv,s    ;
         LDWA    0,i         ;cleanup
         STWA    dk,s        
         STWA    dresult,s   
         LDBA    0,i         
         STBA    div1Sign,s  
         STBA    div2Sign,s  
         ADDSP   6,i         ;pop #dresult #dk #div2Sign #div1Sign
         RET                 ;


;********* XOR ********** TODO fix comments
retXor:  .EQUATE 10          ;returned value #2d
xor1:    .EQUATE 8           ;formal parameter #2d
xor2:    .EQUATE 6           ;formal parameter #2d
tempx1:  .EQUATE 2           ;local variable #2d
tempx2:  .EQUATE 0           ;local variable #2d

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

;********* AND **********
;does a bitwise and of two parameters
retAnd:  .EQUATE 6          ;returned value from bitwise #2d
and1:    .EQUATE 4           ;formal parameter #2d
and2:    .EQUATE 2           ;formal parameter #2d
and:     LDWA    and1,s      ;load first param to A
         ANDA    and2,s      ;bitwise and with second param
         STWA    retAnd,s    ;store result in retAnd
         RET                 

;********* OR ***********
;does a bitwise or of two parameters
retOr:   .EQUATE 6           ;returned value from bitwise #2d
or1:     .EQUATE 4           ;formal parameter #2d
or2:     .EQUATE 2           ;formal parameter #2d

or:      LDWA    or1,s       ;load first param to A
         ORA     or2,s       ;bitwise or with second param
         STWA    retOr,s     ;store result in retOr
         RET                 

;********* ARITHMETIC RIGHT SHIFT ***********
retArs:  .WORD   0           ;returned value from bitwise arith right shift #2d
ars1:    .WORD   0           ;formal parameter #2d
ars2:    .WORD   0           ;formal parameter #2d
arsTemp: .WORD   0           ;temp for right shift loop

ars:     LDWA    ars1,d      ;load first param to A

arsLoop: LDWA    ars1,d      ;load the value in ars1
         ASRA                ;aritmetic right shift
         STWA    ars1,d      ;store to ars1
         LDWA    ars2,d      ;load num of shifts to perform
         SUBA    1,i         ;loop until desired shifts are done
         STWA    ars2,d      
         CPWA    0,i         
         BRGT    arsLoop     
         LDWA    ars1,d      ;load the value in ars1
         STWA    retArs,d    ;store result in retArs
         RET                 

;********* LOGICAL RIGHT SHIFT ***********
retLrs:  .WORD   0           ;returned value from bitwise logical right shift #2d
lrs1:    .WORD   0           ;formal parameter #2d
lrs2:    .WORD   0           ;formal parameter #2d
lrsTemp: .WORD   0           ;temp for logical right loop

lrs:     LDWA    lrs1,d      ;load first param to A
         CPWA    0,i         ;see if it is negative
         BRGT    isPos       ;if not branch to perform the shift normally
         NEGA                ;else negate it to positive
isPos:   STWA    lrs1,d      ;store to lrs1

lrsLoop: LDWA    lrs1,d      ;load the value in lrs1
         ASRA                ;aritmetic right shift
         STWA    lrs1,d      ;store to lrs1
         LDWA    lrs2,d      ;load num of shifts to perform
         SUBA    1,i         ;loop until desired shifts are done
         STWA    lrs2,d      
         CPWA    0,i         
         BRGT    lrsLoop     
         LDWA    lrs1,d      ;load the value in the lrs1
         STWA    retLrs,d    ;store result in retLrs
         RET                 

;********* LEFT SHIFT ***********
retAls:  .WORD   0           ;returned value from bitwise left shift #2d
als1:    .WORD   0           ;formal parameter #2d
als2:    .WORD   0           ;formal parameter #2d
alsTemp: .WORD   0           ;temp for left shift loop

als:     LDWA    als1,d      ;load first param to A

alsLoop: LDWA    als1,d      ;load the value in als1
         ASLA                ;aritmetic left shift with second param
         STWA    als1,d      ;store to als1
         LDWA    als2,d      ;load num of shifts to perform
         SUBA    1,i         ;loop until desired shifts are done
         STWA    als2,d      
         CPWA    0,i         
         BRGT    alsLoop     
         LDWA    als1,d      ;load the value in als1
         STWA    retAls,d    ;store result in retAls
         RET   

         BR      askPr  

goodbye: STRO    byeMsg,d    ;say goodbye and end
         BR      end

;*****************************
;STRINGS
;*****************************
menu:    .ASCII  "Welcome to the CDDM Calculator!\n-------------------------------\nThis calculator is capable of processing:\n- multi-digit integers up to 32767\n- addition/subtraction\n- multiplication/division\n- AND, OR, XOR\n- and bit shifts\n-------------------------------\nTo exit the program, enter 'Q'\x00"

prompt:  .ASCII  "\n-------------------------------\nPlease enter an expression:\n\x00"

errMsg:  .ASCII  "\nSYNTAX ERROR: Unexpected Operator At: \x00"
errMsg2: .ASCII  "\nSYNTAX ERROR: Expected Integer At: \x00"              
         
outputs: .ASCII  "= \x00"    ;Still need to add the postfix expressiong back to char

byeMsg:  .ASCII  "Goodbye! Shutting Down..."

end:     .END                 
