TITLE Program 6

; Author: Steinar Jennings
; Last Modified:6/9/2020
; OSU email address: jenninst@oregonstate.edu
; Course number/section: 400
; Project Number: 6                Due Date: 6/7/2020
; Description: Takes string input from the users and converts and validates the input 
; and adds it to an array of integers. The program then calculates the sum of the entered
; nums and then returns the average. In  the case of both negative and positive numbers, the 
; average will be rounded down, meaning -21.3 rounds down to -22 and 41.7 rounds down to 41

INCLUDE Irvine32.inc

ARRAY_SIZE = 10
MAX_POS = 2147483648
MAX_NEG = 2147483647

;Macro Definitions
displayString MACRO string
	push    edx
	mov     edx, string
	call    WriteString
	pop     edx
ENDM

getString MACRO varName, string, size_max, len
	push	ecx
	push    edx
	push    eax
	displayString string
	mov     edx, varName
	mov     ecx, size_max			;the largest signed 32 bit integers has at most 10 characters
	call    ReadString
	mov     len, eax		    ;from page
	pop     eax
	pop     edx
	pop     ecx
ENDM

.data

; numerical inputs/data for the program
sumNums    DWORD 0
averageNum DWORD 0
inputArr   DWORD ARRAY_SIZE DUP(?)
inputStr   BYTE  21 DUP(0)
strLen     DWORD ?
negCheck   DWORD 0




; string for the program
progTitle	BYTE "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",0
author      BYTE "Written by: Steinar Jennings",0
req1        BYTE "Please provide 10 signed decimal integers.",0
req2        BYTE "Each number needs to be small enough to fit inside a 32 bit register.",0
req3        BYTE "After you have finished inputting the raw numbers I will display a list",0
req4        BYTE "of the integers, their sum and their average value.",0
prompt1     BYTE "Please enter a signed number: ",0
error       BYTE "ERROR: You did not enter a signed number or your number was too big.",0
prompt2     BYTE "Please try again: ",0
yourNums    BYTE "You entered the following numbers:",0
commaSpace  BYTE ", ",0
sumString   BYTE "The sum of these numbers is: ",0
roundString BYTE "The rounded average is: ",0
signOff     BYTE "Thanks for playing!",0

.code
main PROC
	push	OFFSET req4					;28 (need to print and extra blank line after 28)
	push    OFFSET req3					;24
	push    OFFSET req2					;20
	push    OFFSET req1                 ;16
	push    OFFSET author               ;12 (need to print and extra blank line after 12)
	push    OFFSET progTitle			;8
	call	Intro_Rules

	push    OFFSET MAX_POS				;48
	push    OFFSET MAX_NEG				;44
	push    negCheck                    ;40
	push    OFFSET ARRAY_SIZE			;36
	push    OFFSET prompt2				;32
	push    OFFSET error				;28
	push    OFFSET prompt1				;24
	push    OFFSET inputArr				;20
	push    OFFSET inputStr				;16
	push    SIZEOF inputStr				;12
	push    OFFSET strLen    			;8
	call    ReadVal
	
	push    OFFSET commaSpace			;20
	push    OFFSET yourNums				;16
	push    OFFSET ARRAY_SIZE			;12
	push    OFFSET inputArr				;8
	call    PrintNums
	
	push	OFFSET sumstring			;20
	push    OFFSET sumNums			    ;16
	push    OFFSET inputArr				;12
	push    OFFSET ARRAY_SIZE           ;8
	call    SumOfNums
	
	push    OFFSET averageNum			;20
	push	OFFSET roundstring			;16
	push    OFFSET sumNums			    ;12
	push    OFFSET ARRAY_SIZE           ;8
	call    AverageOfNums

	push    OFFSET signOff				;8
	call    Farewell

	exit	; exit to operating system
main ENDP

; ***************************************************************
; Uses the display macro to print out our introduction and the
; rules of the program.
; returns: prints out the introduction to the program
; preconditions: none
; registers changed: ebp, edx (by macro)
; ***************************************************************

Intro_Rules PROC
	push	ebp
	mov		ebp, esp
	pushad

	displayString [ebp+8]				;progTitle
	call	CrLf
	displayString [ebp+12]				;author
	call	CrLf
	call    CrLf			
	displayString [ebp+16]				;req1
	call    CrLf
	displayString [ebp+20]				;req2
	call    CrLf  
	displayString [ebp+24]				;req3
	call    CrLf  
	displayString [ebp+28]				;req4
	call    CrLf  
	call    CrLf

	popad
	pop		ebp		
	ret		24
Intro_Rules ENDP

; ***************************************************************
; This procedure uses the getString macro to prompt the user to
; enter 10 integers in string form. It will also validate them
; and store them in an array in their integer form.
; returns: creates an array of string converted integers
; preconditions: none, string input has requirements
; registers changed: ebp,ebx,eax,ecx,edx(macro),edi,esp,al,
; ***************************************************************

ReadVal PROC
	push ebp
	mov  ebp, esp	
	pushad
	mov  ecx, [ebp+36]                 ;pushes 10, or the offset of the array size to be our loop counter, since we need 10 ints
	mov  edi, [ebp+20]				   ;moves the start of the string array


	get_data:
		push          ecx
		getString     [ebp+16],[ebp+24],[ebp+12],[ebp+8]     ;passes the input string and the input prompt and max input size as params
		mov           ecx,[ebp+8]   				         ; should be storing the length of the input by the user
		mov           esi,[ebp+16]
		cld
		jmp           length_check
	
	get_data_error:
		displayString [ebp+28]
		call          CrLf
		getString	  [ebp+16],[ebp+32],[ebp+12],[ebp+8]    ;passes the input string and the alt input prompt and max input size as params
		mov           ecx, [ebp+8]
		mov           esi, [ebp+16]						    ;moves the user string into the index register
		cld

	length_check:
		cmp           ecx, 11						;largest signed integer is 10 characters long, so 12 long with sign is too large
		jg			  get_data_error				
		cmp           ecx, 11						;if the input is 11 long we need to check validate that it has a sign
		je			  check_first_signed
		cmp           ecx, 10						;if the input has a sign, its okay, if not we need to validate
		je            check_first_unsign
		jmp           convert_nums1
	check_first_signed:
		push		  eax							
		push		  esi
		mov           eax, 0
		mov           esi, [ebp+16]					;check the input strings first element
		lodsb
		cmp           eax, '1'						;if its not a sign and it's 11 characters long, which would be too big
		jge           invalid_input
		cmp			  eax, '-'						;if it has either sign, we need to check the next string byte
		je            check_next
		cmp			  eax, '+'
		je            check_next
		jmp           input_ok
	check_next:
		lodsb
		cmp			  eax, '2'						;if its greater than 2, and we have a 10 digit num, its too big
		jg            invalid_input
		jmp           input_ok
	check_first_unsign:
		push		  eax							
		push		  esi
		mov           eax,0
		mov           esi, [ebp+16]					;check the input strings first element
		lodsb
		cmp			  eax, '-'						;if it has either sign, we need to check the next string byte
		je            input_ok
		cmp			  eax, '+'
		je            input_ok
		cmp           eax, '2'						;if its not a sign and it's 11 characters long, the word is too long
		jg            invalid_input
	input_ok:
		pop			  esi
		pop			  eax
		cld

	convert_nums1:
		mov           eax, [edi]					;this section is borrowing the concept/pseudocode from Lect 23
		mov           ebx, 10                       ;we are multiplying by 10 to convert each byte to decimal
		mul           ebx
		mov           [edi], eax					;after converting the number we restore it in the arr
		mov           eax, 0
		lodsb
		cmp           ecx, [ebp+8]					;if we are checking the first element we need to look for "-" or "+"
		je			  plus_minus_check	
	convert_nums2:	
		cmp			  al, 48						
		jb            invalid_input					;if its below the range, or a LEADING + or -, it's invalid
		cmp           al, 58	
		jg            invalid_input					;if its above the range, or a LEADING + or -, it's invalid
		sub           al, 48						;concept/pseudocode from Lect 23
		mov           ebx, 0
		add           bl, al
		mov           eax, [edi]
		add           eax, ebx
		mov           [edi], eax				    ;store the current value in the array to be modified
		loop          convert_nums1						;check out the next part of the string
		jmp           neg_check						;if we finished the string we need to check if it's negative or not

	plus_minus_check:
		cmp           al, 43						;43 is equal to "+" in the ASCII table
		je            plus
		cmp           al, 45						;45 is equal to "-" in the ASCII table
		je            minus
		jmp           convert_nums2						;if there is no leading "+" or "-", we resume normal validation
	plus:
		loop		  convert_nums1					;since we are treating it as positive, we only need to go to the next str element
	minus:
		push          eax
		mov           eax, [ebp+40]					;we will change the varaible to be 1, which represents a "-" at the front of str
		mov           eax, 1
		mov           [ebp+40], eax
		pop           eax
		loop		  convert_nums1					;since it is not a number, we will check the next str element w/o touching the array
	
	invalid_input:
		push          eax									
		mov           eax, 0						
		mov           [edi], eax					;we want to "zero" out the current array element and reprompt for input
		pop           eax
		jmp           get_data_error				;we will jump to the prompt that shows the error message\
	neg_check: 
		mov           eax,[ebp+40]
		cmp           eax,1
		je			  neg_size_check
	pos_size_check:
		mov           eax, [edi]
		mov           ebx, [ebp+48]					;if its positive we compare against the signed pos upper bound
		cmp           eax, ebx
		ja			  invalid_input
		jmp           next_input
	neg_size_check:
		mov           eax, [edi]
		mov           ebx, [ebp+44]					;if negative, we compare with the signed neg lower bound
		cmp           eax, ebx      
		ja            invalid_input
	make_neg:
		mov           eax, [edi]
		neg           eax							;if we determined a negative sign, make it negative
		mov           [edi], eax			
	next_input:
		pop           ecx
		mov			  eax, [edi]
		add           edi, 4					    ;now we are pointing to the next element in the array
		mov           eax, [ebp+40]
		mov           eax, 0
		mov           [ebp+40],eax					;we are resetting the negative checker
		dec           ecx
		cmp           ecx, 0						;manual loop using dec and jumps (too far of a distance)
		jne           get_data

	popad
	pop   ebp
	ret   44
ReadVal ENDP

; ***************************************************************
; This procedure prints out the list of the values entered.
; returns: prints out statement, nothing returned
; preconditions: requires that you have finished you entry
; registers changed: ebp,esp,ecx,eax,edi,edx(macro)
; ***************************************************************

PrintNums PROC
	push		  ebp
	mov		      ebp, esp	
	pushad
	mov			  ecx, [ebp+12]						;10, or the size of the array
	mov			  edi, [ebp+8]						;moves the start of the array to edi

	call          CrLf
	displayString [ebp+16]
	call		  CrLf

	print_nums:
		mov			  eax, [edi]
		call		  WriteInt
		cmp           ecx, 1						;if we are at the end, we do not need a comma
		je            end_num
		displayString [ebp+20]						;prints out the comma after the letter
	end_num:
		add           edi, 4						;points to the next element in the array
		loop          print_nums
		call		  CrLf

	popad
	pop	ebp
	ret 16
PrintNums ENDP


; ***************************************************************
; Calculates the sum of the numbers in our array.
; returns: prints out a statement showing the sum of the array vals
; preconditions: the array needs to be filled before this proc
; is called.
; registers changed: ebp, esp, ecx, edi, eax, ebx, edx(macro)
; ***************************************************************

SumOfNums PROC
	push		  ebp
	mov		      ebp, esp	
	pushad
	mov			  ecx, [ebp+8]						;10, or the size of the array
	mov			  edi, [ebp+12]						;moves the start of the array to edi

	displayString [ebp+20]							;prints out our statement before providing the sum

	print_nums:
		mov			  eax, [edi]
		push		  esi
		mov			  esi, [ebp+16]					
		add			  [esi], eax					;adding our input nums 1 by 1 to a variable to be stored
		pop			  esi
	end_num:
		add           edi, 4						;points to the next num
		loop          print_nums
		push          esi
		mov           esi, [ebp+16]					
		mov           eax, [esi]					;we need to put our running total in back eax to print it
		pop           esi
		call          WriteInt
		call		  CrLf

	popad
	pop	ebp
	ret 16
SumOfNums ENDP


; ***************************************************************
; Takes the sum of the numbers, calculated above and returns the
; average by dividing by ten and performing any rounding
; returns: average num
; preconditions: we must have the sum calculated.
; registers changed: ebp,esp,ecx,eax,esi,edx
; ***************************************************************

AverageOfNums PROC
	push		  ebp
	mov		      ebp, esp
	pushad
	mov			  ecx, [ebp+8]						;10, or the size of the array
	push		  esi
	mov			  esi, [ebp+12]						;the address sum of the nums
	mov			  eax, [esi]						;stores the actual value of the num sum
	pop           esi
	cdq
	idiv          ecx								;div by 10
	push		  esi
	mov			  esi, [ebp+20]						;we want to store the divided value in the divided variable
	mov			  [esi], eax							
	pop			  esi

	cmp           edx,0								;if there is no remainder, then we don't need to round
	je            end_ave
	cmp           eax,0
	jl            minus_one							;if the dividend is negative then we need to round down
	jmp           end_ave

	minus_one:
	push		  esi
	mov			  esi, [ebp+20]						
	mov			  eax, [esi]
	sub           eax, 1							;to be consistent, if its negative remainder we are also rounding down
	mov           [esi], eax
	pop			  esi


	end_ave:
	displayString [ebp+16]
	push          esi
	mov           esi, [ebp+20]						;moving the rounded dividend into eax to be written
	mov           eax, [esi]
	pop           esi
	call		  WriteInt
	call          CrLf
	call          CrLf

	popad
	pop	ebp
	ret 16
AverageOfNums ENDP


; ***************************************************************
; This procedure will print a farewell to the user of the program.
; returns: none, prints the farewell statement
; preconditions: The program should be fully run by this point
; registers changed: ebp, esp, edx(macro)
; ***************************************************************

Farewell PROC
	push			ebp
	mov				ebp, esp
	pushad
	displayString	[ebp+8]					;contains the farewell string
	
	popad
	pop ebp
	ret 8
Farewell ENDP

END main
