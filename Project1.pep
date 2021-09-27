;********************************************************************
; Names:   Charles Kinser
;          ADD YOUR NAME
;          ADD YOUR NAME
;          ADD YOUR NAME
; Lab:     Project
; Date:    9/26/2021
; Purpose:
;********************************************************************

skip:    BR main

inVec:   .BLOCK  128         ;array of characters from input, global array #2d64a
vecI:    .WORD   0           ;current index of inVec array #2d
inVecL:  .WORD   0           ;length of inVec, global variable #2d

num1:    .BLOCK  2           ;variable for multidigit intake #2d
num2:    .BLOCK  2           ;variable for multidigit intake #2d
value:   .WORD   1           ;temporary storage for integer intake #2d

main:    LDBA charIn,d       ;prep for first run by populating num2
         SUBA 30,i           ;convert to deci
         STBA num2,d
loop:    LDBA num2,d         ;shift input chars
         STBA num1,d
         LDBA charIn,d
         SUBA 30,i           ;convert to deci
         STBA num2,d
         
         LDBA num1,d         ;if num1 is not deci, store as char, else add to value
         CPBA 9,i            ;check for int by checking for range 0
         BRGT notDec
         CPBA 0,i
         BRLT notDec
         ADDA value,d
         STWA value,d
         
         LDBA num2,d         ;if num2 is not deci, leave, else multiply value by 10
         CPBA 9,i
         BRGT decDone
         CPBA 0,i
         BRLT decDone
         LDWA value,d
         ;TODO multiply by 10
         STWA value,d
         BR loop

notDec:  ADDA 30,i           ;convert back to ascii char
         
decDone: .end
         
         