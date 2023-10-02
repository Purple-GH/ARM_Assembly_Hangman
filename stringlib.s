
.global strfix
.global strcat
.global strcmp
.global strcpy
.global strlen
.global strlwr
.global strupr
.global strim
.global strprint
.global strinput


@ strnull is a subroutine that replaces the "\n" character at the end of a string with NULL

@ Registers used: R1, R3
@ R1: Used to store the address of the string, and iterate through the characters
@ R3: Used to compare the current character to check if it's newline

@ INPUT: R1 should contain the address of the string to modify

strfix:

	LDRB	R3, [r1]		@ Loads the first character pointerd to by R1 into R3
	CMP 	R3, #'\n'		@ Checks to see if the current character is newline
	
	ADDNE	R1, R1, #1		@ Moves to the address of the next character in the string if no newline
	
	BNE		strfix			@ If the newline was not found, check the next character
	
	MOV		R4, #0 
	STRB	R4, [R1]

	MOV		PC, LR			@ Used to return to the next instruction after running the subroutine

@ strcat is a subroutine that concatenates 2 strings together

@ Registers used: R1, R3, R4, R5
@ R1: Used to store the address of the final concatenated string
@ R3: Used to inspect individual characters (mostly to find NULL characters)
@ R4: Used to store the address of the first string to concatenate
@ R5: Used to store the address of the second string to concatenate

@ INPUT: R4, R5 should contain the addresses to the strings to concatenate
@ OUTPUT: R1 will contain the address of the concatenated string

strcat:

	LDR		R1, =catbuff	@ Loading the buffer addres sinto R1 to store the concatenated strings
	PUSH	{R1, LR}		@ To make sure we can return to _start when done, and with the right R1 address
	
	str1loop:					@ Loop to iterate through the first string to concatenate

		LDRB	R3, [R4]		@ Load the byte stored at R4 into R3 to check the character
		CMP		R3, #0			@ Checks to see if the character is NULL
	
		STRNEB	R3, [R1]		@ If the current character isn't NULL, store it in the new string
		ADDNE	R1, #1			@ If the current character isn't NULL, increment the concatenated string address by 1
		ADDNE	R4, #1			@ If the current character isn't NULL, increment the string1 address by 1
	
		BNE	str1loop		@ If the string 1 NULL isn't found, check the next character

	@ str2loop causes segmentation faults

	str2loop:					@ Loop to iterate through the second string to concatenate

		LDRB	R3, [R5]		@ Load the byte stored at R4 into R3 to check the character
		CMP		R3, #0			@ Checks to see if the character is NULL
	
		STRNEB	R3, [R1]		@ If the current character isn't NULL, store it in the new string
		ADDNE	R1, #1			@ If the current character isn't NULL, increment the concatenated string address by 1
		ADDNE	R5, #1			@ If the current character isn't NULL, increment the string2 address by 1
	
		BNE	str2loop		@ If the string 2 NULL isn't found, check the next character

	POP		{R1, LR}		@ To return to the right address for _start, and return the correct string
	MOV		PC, LR			@ Returning to _start

@ strcmp is a subroutine that compares the characters in 2 given strings

@ Registers used: R2, R3, R4, R5, R6
@ R2: Used to store and compare string 1's character
@ R3: Used to store and compare string 2's character
@ R4: Used to store the first string for the comparison
@ R5: Used to store the second string for comparison
@ R6: Used as a flag to indicate the results of the comparison (1 if identical, 0 if not)

@ INPUT: R4, R5 should contain the strings to compare
@ OUTPUT: The equal flag will be set if the strings are equal

strcmp:
	
	MOV		R0, #0			@ Setting the strings as different by default
	
	cmpLoop:
	
	LDRB	R2, [R4]		@ Load the current character from R4 into R2
	LDRB	R3, [R5]		@ Load the current character from R5 into R3
	
	CMP 	R2, R3			@ Checks to see if both characters are identical
	MOVNE	PC, LR			@ Returning to the calling environment if both characters are different
	
	CMP		R2, #0			@ Checks for a NULL if both characters are the same
	MOVEQ	R0, #1			@ Sets the flag to true if the strings are identical
	MOVEQ	PC, LR			@ If one of the characters are NULL, return to calling environment
	
	ADD		R4, R4, #1		@ If the character is not NULL, increment the R4 address
	ADD		R5, R5, #1		@ If the character is not NULL, increment the R5 address
	
	B		cmpLoop			@ Start the next iteration
	
@ strcpy is a subroutine that takes a string, and copies it to another address

@ Registers used: R3, R4, R5
@ R3: Used to transfer every character from one address to another
@ R4: Address of the string to copy (the source)
@ R5: Address of the destination for the copied string

@INPUT: R4 should have the source address, and R5 should have the destination address


strcpy:	

	LDRB	R3, [R4]		@ Loading the current character to be copied into R3
	STRB	R3, [R5]		@ Copying the current character into the destination
	
	CMP		R3, #0			@ Checking to see if the current character is NULL
	
	ADDNE	R4, R4, #1		@ If the current character isn't NULL, increment the source by 1
	ADDNE	R5, R5, #1		@ If the current character isn't NULL, increment the destination by 1
	
	BNE		strcpy			@ If NULL wasn't reached, copy the next character
	
	MOV		PC, LR			@ Return once done

@ strlen is a subroutine that counts the number of characters in a string

@ Registers used: R1, R2, R3
@ R1: Used to store the address of the string, and iterate through the characters
@ R2: Used to keep track of the number of characters in the string
@ R3: used to compare the current character to check if it is NULL

@ INPUT: R1 should contain the address of the string to measure
@ OUTPUT: R2 will contain the length of the string recieved in the INPUT

strlen:
	
	MOV		R2, #0			@ Starts the counter stored in R2 at 0

	@ Label used to loop through the string
	@ Strlen is not used because the counter in R2 would be reset to 0 every loop
	
counterloop:

	LDRB	R3, [r1]		@ Loads the first character of the string into R3
	CMP		R3, #0			@ Checks to see if the current character is NULL
	
	ADDNE	R2, R2, #1		@ Increments the counter by 1 if the current character is not NULL
	ADDNE	R1, R1, #1		@ Increments the address to the next character in the string if the character is not NULL
	
	BNE		counterloop		@ Restarts the loop if the NULL character was not found
	
	MOV		PC, LR			@ Used to return to the next instruction after running the subroutine

@ strlwr is a subroutine that converts all uppercase characters in a string to lowercase

@ Registers used: R1, R3
@ R1: Used to store the address of the string, and to iterate through the characters
@ R3: Used to check if a character is lowercase or uppercase, and to modify it

@ INPUT: R1 should contain the address of the string to convert

strlwr:
	
	LDRB	R3, [r1]		@ Loads the first character of the string into R3
	CMP 	R3, #97			@ Checks to see if the current character is uppercase ("a" = 97)
	
	ADDGE	R1, R1, #1		@ Moves to the address of the next character in the string if it's lowercase
	
	BGE		strlwr			@ Restarts the loop if the character is a lowercase
	
	@ For the sake of this lab, I am assuming that any character where 64 < character < 97 is a letter
	@ I set 64 as the lower bound to account for the possibility of spaces
	
	CMP		R3, #65			@ Checks to make sure the character is an uppercase character (this is an approximation)
	
	ADDGE	R3, R3, #32		@ Changes the letter's ASCII value to its lowercase equivalent
	STRB	R3, [R1]		@ Puts the lowercase ASCII value in the current character's location (if converted)
	
	CMP		R3, #0			@ Checks to see if the current character is NULL

	ADDNE	R1, R1, #1		@ Moves to the address of the next character in the string if it's not NULL

	BNE		strlwr			@ If NULL was not found, check the next character
	
	MOV		PC, LR			@ Used to return to the next instruction after running the subroutine

@ strupper is a subroutine that converts all lowercase characters in a string to uppercase

@ Registers used: R1, R3
@ R1: Used to store the address of the string, and to iterate through the characters
@ R2: Used to check if a character is lowercase or uppercase, and to modify it

@ INPUT: R1 should contain the address of the string to convert

strupr:

	LDRB	R3, [r1]		@ Loads the first character of the string into R3	
	
	CMP		R3, #0			@ Checks to see if the current character is NULL
	MOVEQ	PC, LR			@ If the current character is NULL, stop the subroutine
	
	CMP 	R3, #97			@ Checks to see if the current character is a lowercase ("a" = 97)
	ADDLT	R1, R1, #1		@ Increment the address by 1 if the current character isn't a lowercase
	BLT		strupr			@ If the character is less than 'a' in the ASCII table, restart the loop
	
	CMP		R3, #122		@ Checks to see if the character is within the bounds of 'a' to 'z'
	ADDGT	R1, R1, #1		@ Increment the address by 1 if the current character is past the range of lowercase
	BGT		strupr			@ If the character isn't NULL, or lowercase, restart the loop
	
	SUB		R3, R3, #32		@ Subtract 32 from the ASCII value to convert to uppercase
	STRB	R3, [R1]		@ Store the converted value back into the string
	
	B		strupr			@ Restart the loop

@ strim is a subroutine that takes in a string, and removes any leading/trailing spaces

@ Registers used: R0, R1, R2, R3, R4, R5, R6

@ R0: Used as a flag to remove leading spaces (1 means remove them, 0 means leave them)
@ R1: Used as a flag to remove trailing spaces (1 means remove them, 0 means leave them)
@ R2: Used as a flag to remove leading and trailing spaces (1 means remove them, 0 means leave them)
@ R3: Used to check to see if a given character is a space
@ R4: Used to point to the desired start of the string, to strcpy the modified string
@ R5: Used to point to the original address of the string, used to strcpy the modified string
@ R6: Used as a flag to check for trailing spaces (1 means the previous character was a space)

@ INPUT: R0-R2 should have the flags set to indicate removal type, R5 should have the address of the string to trim
@ OUTPUT: The string provided in R5 will be automatically modified and updated, no specific register output

strim:

	CMP		R2, #1			@ Used to set R0 and R1 to 1 if leading/trailing spaces are to be removed
	MOVEQ	R0, #1			@ If R2 is true, set 1 into R0 to simplify logic later in the code
	MOVEQ	R1, #1			@ If R2 is true, set 1 into R1 to simplify logic later in the code
	MOV		R4, R5			@ The default desired start for the string includes the leading spaces
	MOV		R6, #0			@ Setting R6 as zero by default, will be changed in strimTail as needed

	PUSH	{LR}			@ Pushing the LR onto the stack to be able to return tp the calling environment later
	PUSH	{R5}			@ Saving the start address for the string, for a strcpy call later
	
	CMP		R0, #1			@ Check to see if the leading spaces are to be removed
	BLEQ	strimHead		@ If leading spaces are to be removed, find the first non-space character 
	
	CMP		R1, #1			@ Check to see if trailing spaces are to be removed
	BLEQ	strimTail		@ If trailing spaces are to be removed, check for 2 consecutive spaces, or a space then NULL
	STRB	R3, [R5], #-1	@ Removing the last leftover space 
	
	
	POP		{R5}			@ Restoring the original value in R5, as the destination for a strcpy
	BL		strcpy			@ Shifting over the string after removing leading spaces
	POP		{LR}			@ Popping the link address back to the calling environment off the stack
	
	MOV		PC, LR			@ Returning to the calling environment
	
	@ Strimhead works properly, fix strimtail
	strimHead:				@ Loop to find the first non-space character if leading spaces are to be removed
	
		LDRB	R3, [R5]		@ Loading the current character to check it (if leading spaces are to be removed)
		CMP		R3, #32			@ Checking to see if the character is a space
		ADDEQ	R5, R5, #1		@ If a space was found, check the next character
		MOVNE	R4, R5			@ If a non-space is found, set the start of the desired string to that character
		BEQ		strimHead		@ If the desired start wasn't found, check the next character
		MOV		PC, LR			@ Return to strim if the desired start was found
	
	strimTail:				@ Loop to find 2 consecutive spaces, or a space then NULL, to remove trailing spaces
		
		LDRB	R3, [R5]		@ Loading the current character to check it
		
		CMP		R6, #1			@ Checks to see if the previous character was a space (1 means true, 0 means false)
		CMPEQ	R3, #0			@ If the previous character was a space, check to see if the current one is NULL
		STREQB	R3, [R5], #-1	@ If the previous character was a space, and the current is NULL, replace the space with NULL
		MOVEQ	PC, LR			@ Return to strim the the space was replaced
		
		CMP		R6, #1			@ Checks to see if the previous character was a space (1 means true, 0 means false)
		CMPEQ	R3, #32			@ If the previous character was a space, check to see if the current one is a space
		MOVEQ	R3, #0			@ If there are 2 spaces in a row, load NULL into R3 to replace the first space
		STREQB	R3, [R5], #-1	@ If there are 2 spaces in a row, replace the first one with a NULL
		MOVEQ	PC, LR			@ Return to strim the the space was replaced
		
		CMP		R3, #0			@ If [space][space] or [space][NULL] wasn't found, check for [character][NULL]
		MOVEQ	PC, LR			@ If [character][NULL] was found, return to strim
		
		CMP		R3, #32			@ If the previous character wasn't a space, check to see if the current one is
		MOVEQ	R6, #1			@ If the current character is a space, set R6 to true for the next loop
		MOVNE	R6, #0			@ If the current character is not a space, set R6 to false for the next loop
		
		ADD		R5, R5, #1		@ Increment the address by 1
		B		strimTail		@ Restart the loop
		
@ strprint is a subroutine that prints a string out to the screen

@ Registers used: R0, R1, R2, R7
@ R0: Used to tell the write syscall where to write the string (set to 1 for stdout)
@ R1: Used to store the address of the string to print
@ R2: Used to store the length of the string. strlen is used to obtain this
@ R7: Used to indicate that we're doing a WRITE syscall

@ INPUT: R1 should contain the address of the string to print

strprint:

	@STMIA	SP!, {R1, LR}	@ Pushing R1 and the LR onto the stack, to restore them after the call to strlen
	PUSH	{R1, LR}
	BL strlen				@ Using strlen to fill R2 with the string length
	POP		{R1, LR}
	@LDMDB	SP!, {R1, LR}	@ Restoring the address in R1 and LR after the call to strlen

	MOV		R0, #1			@ Setting 1 in R0 to use stdout in the write syscall
	MOV		R7, #4			@ Setting 4 in R7 for a WRITE syscall
	SWI		0				@ Writing to the screen

	MOV		PC, LR			@ Used to return to the next instruction after running the subroutine

@ strinput takes user input from stdin, and stores it in the address provided in R1

@ Registers used: R0, R1, R2, R7
@ R0: Used to tell the read syscall to use stdin as the input source
@ R1: Used to store the location to store the input string
@ R2: Used to limit the length of the input string
@ R7: Used to indicate that we're doing a READ syscall

@ INPUT: R1 should contain the address of the desired location to store the string

strinput:

	MOV		R0, #0			@ Setting 0 in R0 to tell the read syscall to take input from stdin
	@MOV		R2, #21			@ Setting 20 as the max input length (21 to include the NULL)
	
	MOV		R7, #3			@ Setting 3 in R7 for a READ syscall
	SWI		0				@ Reading from the screen

	PUSH	{R1, LR}	@ Pushing R1 and LR onto the stack before a call to strfix
	BL		strfix			@ Removing the newline from the input, and replacing it with NULL
	POP		{R1, LR}	@ Popping R1 and LR back off the stack

	MOV		PC, LR			@ Used to return to the next instruction after running the subroutine

.data
catbuff:	.space 100		@ Used to store concatenated strings
