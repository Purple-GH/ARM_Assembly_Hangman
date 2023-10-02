
.global randNum

/*
 * Library subroutine: randNum
 * 
 * randNum generates a "random" number using the ms value of a gettimeofday syscall
 *
 * INPUT: No input is required for this subroutine
 * OUTPUT: This subroutine will return the number in R6
 *
 * The full ms value is returned so that any number of words can be used
 * And the number of offsets can be adjusted as needed in the main code
 *
 * Registers used:
 * R0: Used to store the current time into the desired variable
 * R1: Used to set the timezone for the getimeofday syscall, always set to NULL
 * R6: Used to store the ms value resulting from the gettimeofday syscall
 * R7: Set to #78 to specify a gettimeofday syscall when calling SWI
*/

randNum:

		MOV		R7, #78		@ Putting 78 into R7 for a gettimeofday syscall
		LDR		R0, =time	@ Putting the address in which time_t is to be stored 
		MOV		R1, #0		@ Setting NULL as the timezone, since it's not needed
		SWI		0			@ Getting the time

		LDR		R0, =time
		LDRB	R6, [R0, #4]	@ Loading the 5th byte in time into R4 (for the ms)
		
		MOV		PC, LR		@ Return to the calling environment

.data
time:		.space 8
