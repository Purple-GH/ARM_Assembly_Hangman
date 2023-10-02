
.global _start

_start:

	LDR		R1, =intro		@ Loading the introduction to print it
	BL		strprint		@ Printing out the introduction
	
	LDR		R1, =rules		@ Loading the rules to print them out
	BL		strprint		@ Printing out the rules
	
	restartGame:			@ Label to restart the cycle once a game is done
	
	BL		playPrompt		@ Asking the user if they would like to play a game
	
	BL		gameSetup		@ Setting up the variables for the game
	
	BL		enterWord		@ Ask the user if they would like to play with a custom word
	
	BL		randNum			@ Generating a random number for a random word
	BL		selectWord		@ Selecting a random word based on the random number
	
	customSkip:				@ Used to skip random word generation if a custom word was used
	
	MOV		R0, #6			@ Setting the remaining mistakes into R0
	LDR		R7, =guessList	@ Loading the guess list into R7, which is updated as the code runs
	
	gameLoop:				@ Main loop to run the game
	
		PUSH	{R0}		@ Putting R0 onto the stack, because R0 will be modified
		PUSH	{R7}		@ Pushing the current R7 value onto the stack, as R7 will be modified	
			
		BL	printScreen		@ Prints out the screen after any changes to the game
			
		BL	selectLetter	@ Getting the user to input a letter
		
		POP		{R7}		@ Restoring the original R7 value, as letterCheck will use it
		BL	letterCheck		@ Checking the input letter for a hit or a miss
		
		CMP		R4, #0		@ Checks to see if the guess was a miss
		POPEQ	{R0}		@ If the guess was a miss, pop R0 off the stack to decrement it
		SUBEQ	R0, R0, #1	@ Decrement remaining guesses by 1 if the guess was a miss
		PUSHEQ	{R0}		@ Push R0 back onto the stack if it was updated
		
		BLEQ	remainingUpdate		@ Updates the remaining number of guesses if the guess was a miss
		BLEQ	drawHangman	@ Draws the next part of the hangman if the guess was a miss
		
		PUSH	{R7}		@ Putting the new R7 value back onto the stack
		
		CMP		R5, #1		@ Checks to see if any letters still have to be guessed
		BLNE	gameWin		@ Prints out the game win message if there are no letters to be guessed
		
		POP		{R7}		@ Popping R7 back off the stack
		POP		{R0}		@ Restoring the value of R0
		
		CMP		R0, #0		@ Checks to see of the remaining guesses are at 0
		
		BNE		gameLoop	@ Restart the loop for the next round if any guesses remain
		
		BL		gameLoss	@ Print out the loss message if the game was lost
		
		

/*
 * _end Subroutine
 *
 * This subroutine is used to exit the program when certain conditions are met
 *
 * R7 is used to indicate that we want an EXIT syscall
 */

_end:		

	MOV		R7, #1			@ Putting 1 into R7 for an EXIT syscall
	SWI		0				@ Exiting the program


/*
 * playPrompt Subroutine
 *
 * This subroutine is used to ask the user if they would like to play a new game of hangman
 * If the user answers yes, the game starts. If the user enters no, _end is called
 *
 * R0: Used to compare the first input character to a "Y" or a "N"
 * R1: Used to print out prompts, and get user input
 * R2: Used to limit the size of the user input
 */

playPrompt:	

	LDR		R1, =playQstn	@ Loads the new game prompt into R1 to print it
	PUSH	{LR}			@ Saving the LR, because strprint and strinput will change it
	BL		strprint		@ Printing out the prompt
	LDR		R1, =inputLttr	@ Loading the address at which the input letter is to be stored
	MOV		R2, #2			@ Limiting the input to 2 characters (letter and newline)
	BL		strinput		@ Getting the user input
	BL		strupr			@ Making the input letter uppercase, if not already
	POP		{LR}			@ Restoring LR

	LDR		R1, =inputLttr	@ Reloading the address into R1 for byte analysis
	LDRB	R0, [R1]		@ Loading the byte value into R0 for a CMP
	
	CMP		R0, #78			@ Checking to see if the user input an "N"
	BEQ		_end			@ If the user doesn't want to play another game, end the program
	CMP		R0, #89			@ Checking to see if the user entered a "Y"
	MOVEQ	PC, LR			@ If "Y" was entered, return to _start
	
	LDR		R1, =exitMsg	@ Loads the exit message if an invalid input is given
	BL		strprint		@ Printing out the message
	LDR		R1, =newline	@ Loading a newline to print it out
	BL		strprint		@ Printing out the newline
	B		_end			@ Exiting the program

/*
 * selectWord Subroutine
 *
 * This subroutine retreives a word from the data structure based on the random number
 * The word is then stored into memory to be used throughout the game
 *
 * R0: Used to store 10, and multiply the value in R6 to obtain the offset to use in the data structure
 * R4: Used To load the word array, and locate the "randomly" selected word
 * R6: Used to store the random number, and adjust it so that it's within the size of the word data structure
 * R8: Used to store the final offset result after calculating it
 */

@ This label is used to load in the randomly selected word
selectWord:	

	PUSH	{LR}			@ Pushing the LR onto the stack, because it will be modified

	modLooper:				@ This is a loop to essentially calculate a modulo

		CMP		R6, #25			@ Checks to see if the current number is larger than 25
		SUBGT	R6, R6, #25		@ Removes 25 if the number is greater than 25
		BGT		modLooper		@ Restart the loop if the number was greater than 25
	
	MOV		R0, #10			@ Putting 10 into R0 for the MUL below
	
	MUL		R8, R6, R0		@ Setting up the offset for the random word
	
	LDR		R4, =words		@ Loading the initial address of words
	ADD		R4, R4, R8		@ Obtaining the offset for the random word
	
	LDR		R5, =rndWord	@ Loading the destination address for a strcpy
	
	BL		strcpy			@ Copying the random word into its own variable
	
	BL		wordHider		@ Creates the string for the hidden word
	
	POP		{PC}			
	
/*
 * wordHider Subroutine
 *
 * This subroutine generates the hidden word (where the letters are replaced with _)
 *
 * R1: Used to store the ascii value of a space, to space out the underscores in the string
 * R2: Used to store the ascii value of an underscore, to place one for every character in the random word
 * R3: Used to store the address of the randomly selected word
 * R4: Used to store the address of the hidden word
 */

wordHider:

	MOV		R1, #32			@ Putting 32 into R1 for space ASCII
	MOV		R2, #95			@ Putting 95 into R2 for underscore ascii
	LDR		R3, =rndWord	@ Loading the randonmly selected word
	LDR		R4, =hdnWord	@ Loading the address of the hidden word into R3
	
	hideLooper:				@ Loop to go through the string and hide the characters
	
		LDRB	R0, [R3]		@ Loading the current character into R0, to copy it
	
		CMP		R0, #0			@ Checking to see if the current character is NULL
		MOVEQ	PC, LR			@ Returning to start if NULL is reached
		
		STRB	R2, [R4], #1	@ Store underscore into the hidden string, and increment by 1
		STRB	R1, [R4], #1	@ Store a space into the hidden string, and increment by 1
		
		ADD		R3, R3, #1		@ Increment the random word address by 1
		
		B		hideLooper

/*
 * printScreen Subroutine
 *
 * This subroutine prints out the ASCII art for every round in the game
 *
 * R1: Used to print the different components to the screen
 */

printScreen:		

	PUSH	{LR}			@ Pushing the LR onto the stack to bhe able to return to _start

	LDR		R1, =newline	@ Loading the newline to print it out and clean the prompt
	BL		strprint		@ Printing out the newline
	LDR		R1, =gameTitle	@ Loading the game title to print it
	BL		strprint		@ Print out a newline
	LDR		R1, =gallows	@ Loading the gallows into R1 to print them
	BL		strprint		@ Printing out the gallows
	LDR		R1, =newline	@ Loading the newline to print it out and clean the prompt
	BL		strprint		@ Printing out the newline
			
	LDR		R1, =wordPrompt	@ Loading the word prompt into R1 to print it out
	BL		strprint		@ Printing out the word prompt
	LDR		R1, =hdnWord	@ Loading the hidden word to print it
	BL		strprint		@ Printing out the hidden word	
	LDR		R1, =newline	@ Loading the newline to print it out and clean the prompt
	BL		strprint		@ Printing out the newline
	
	LDR		R1, =guessPrompt	@ Loading the guess prompt into R1 to print it
	BL		strprint		@ Printing out the guess prompt
	LDR		R1, =guessList	@ Loading the list of guesses into R1, to print it out
	BL		strprint		@ Printing out the list of guesses
	LDR		R1, =guessRemain	@ Loading the remaining guess string to print it out
	BL		strprint		@ Printing out the remaining number of guesses
	LDR		R1, =newline	@ Loading the newline to print it out and clean the prompt
	BL		strprint		@ Printing out the newline
	
	POP		{PC}			@ Retuning to _start

/*
 * selectLetter Subroutine
 *
 * This suproutine gets the user input during the game
 * The input can be a character, "HELP", or "QUIT"
 *
 * R1: Used to print out prompts, and receive user input
 * R2: Used to limit the maximum input size
 * R4: Used to load in the input for a string comparison
 * R5: Used to load in "HELP" or "QUIT" for a string comparison
 */

selectLetter:

	PUSH	{LR}		@ Pushing the LR onto the stack because it will be changed

	LDR		R1, =charSelect	@ Loading the char selection prompt into R1 to print it out
	BL		strprint		@ Printing out the character selection prompt
	
	LDR		R1, =inputLttr	@ Loading the inputLttr address for a call to strinput
	MOV		R2, #5			@ Limiting the input to five characters (to account for "HELP" or "QUIT")
	BL		strinput		@ Getting the input from the user
	BL		strupr			@ Converting the input to uppercase
	
	LDR		R4, =inputLttr	@ Loading the input into R4 for a strcmp
	LDR		R5, =help		@ Loading "QUIT" into R5 for a strcmp
	BL		strcmp			@ Checking to see if the input is "HELP"
			
	LDREQ	R1, =rules		@ Loading the rules to print them out of the user asked for them
	BLEQ	strprint		@ Printing out the rules if the user asked for them
	BEQ		selectLetter	@ If the reules were printed, ask the user to choose their letter

	LDR		R4, =inputLttr	@ Loads the input into R4 for a strcmp
	LDR		R5, =quit		@ Loads "QUIT" into R5 for a strcmp
	BL		strcmp			@ Checking to see if the input was "QUIT"
	BEQ		_end			@ Ending the game if the user enters "QUIT"

	POP		{PC}		@ Returning to _start

/*
 * letterCheck Subroutine
 *
 * This subroutine checks to see if a correct guess was made
 * The subroutine sets flags and branches based on whether the guess was correct or not
 *
 * R0: Used to store the ASCII value of the character inputted by the user
 * R1: Used to store the ASCII value of characters in the hidden word, to CMP with R0
 * R2: Used to load the address of the string containing the character input
 * R3: Used to load the address of the string containing the hidden word
 * R4: Used to store a flag indicating if the character was a valid guess
 * R5: Used to indicate if there are any remaining letters to be guessed
 * R6: Used to store the ASCII of a character from the hidden word, to see if any underscores aren't replaced
 */

letterCheck:
	
	LDR		R2, =inputLttr	@ Loading the input letter address, to get the character's ASCII
	LDRB	R0, [R2]		@ Loading the character's ASCII value into R0
	
	LDR		R2, =rndWord	@ Loading the random word into R2 to compare characters
	LDR		R3, =hdnWord	@ Loading the address off the hidden word into R3
	
	MOV		R4, #0			@ To be used as a flag indicating whether the guess was a match
	MOV		R5, #0			@ Used as a flag to indicate if there are remaining letters to guess
	
	checkLoop:				@ Loop to check each character in the word to the input character
		
		LDRB	R1, [R2], #1	@ Loading the current letter in the word for a comparison, and increment
		
		CMP		R1, R0		@ Check to see if the characters are the same
		MOVEQ	R4, #1		@ If the letter was correct, set the flag to 1
		STREQB	R0, [R3]	@ Replace the underscore with the correct letter
		
		LDRB	R6, [R3]	@ Loads the current character in the hidden word into R6
		CMP		R6, #95		@ Checks to see if an underscore remains unreplaced		
		MOVEQ	R5, #1		@ Sets 1 into R5 if there is at least 1 letter that remains to be guessed
		
		ADD		R3, R3, #2	@ Increment R3 by 2 to account for spaces
		CMP		R1, #0		@ Check to see if the current character is NULL

		BNE		checkLoop	@ Restart the loop if the current character isn't NULL
	
	CMP		R4, #0			@ Checks to see if the character was a match
	
	PUSH	{LR}			@ Pushing the LR onto the stack in case the BL on the next line is used
	BLEQ	addGuess		@ If it was not a match, add it to the list of guesses
	POP		{PC}			@ Returning to _start

/*
 * addGuess Subroutine
 *
 * This subroutine adds a character to the list of previous guesses if it was a wrong guess
 *
 * R0: Contains the ASCII value of the current character guess, and is used to store the guess into the guess string
 * R1: Contains the ASCII for a comma, and is added in the string after the guess (for formatting purposes)
 * R7: Contains the address of the hidden word string, to replace underscores with the correct character
 */
 
addGuess:

	MOV		R1, #44			@ Loading the ascii value for a comma into R1
	STRB	R0, [R7], #1	@ Storing the character guess into the guess list, and incrementing by 1
	STRB	R1, [R7], #1	@ Storing the comma into the guess list, and incrementing by 1	
	MOV		PC, LR			@ Returning to letterCheck

/*
 * gameWin Subroutine
 *
 * This subroutine prints out the last ascii art screen, and the win message
 * After printing out the screen, it branches to the restartGame label in _start:
 *
 * R1: Used to print out different strings out to the screen
 */
 
gameWin:

	BL		printScreen	@ Print the final screen out
	LDR		R1, =winMsg	@ Loads the win message if all letters were guessed
	BL		strprint	@ Prints out the win message if all letters were guessed
	B		restartGame	@ Checks to see if the player wants to play again		

/*
 * gameLoss Subroutine
 *
 * This subroutine prints out the last ascii art screen, and the loss message
 * After printing out the screen, it branches to the restartGame label in _start:
 *
 * R1: Used to print out different strings out to the screen
 */
 
gameLoss:

	BL		printScreen		@ Prints out the final screen
	LDR		R1, =lossMsg	@ If guesses ran out, load the loss message to print it
	BL		strprint		@ Print out the loss message
	LDR		R1, =rndWord	@ Load the random word into R1 to print it out
	BL		strprint		@ Prints out the word
	LDR		R1, =newline	@ Loading a newline into R1 to print it and clean up the window
	BL		strprint		@ print out the newline
	
	B		restartGame		@ Prints the prompt to restart the game

/*
 * gameSetup Subroutine
 *
 * This subroutine is used to perform cleanup/reset strings in case a previous game was played
 *
 * R0: Used to reset the remaining guess counter to 0 (uses the ASCII for 0, instead of the number 0)
 * R1: Used to load the remaining guesses string and change the value to 0
 * R4: Used to load strings for a string copy
 * R5: Used to load strings for a string copy
 */

gameSetup:

	PUSH	{LR}			@ Pushing the LR onto the stack because it will be changed

	LDR		R4, =gallowsTmp	@ Loading the gallows template into R4 for a strcpy
	LDR		R5, =gallows	@ Loading the address off gallows for a strcpy
	BL		strcpy			@ Copying the gallows themplate into the gallows
	
	LDR		R4, =guessBlank	@ Loading the blank guess list for a strcpy
	LDR		R5, =guessList	@ Loading the guess list for a strcpy
	BL		strcpy			@ Resetting the guessList to be empty
	
	LDR		R4, =rndWipe	@ Loading a blank to reset the random word
	LDR		R5, =rndWord	@ Loading the random word variable to clear it
	BL		strcpy			@ Resetting the variable
	
	LDR		R4, =hdnWipe	@ Loading a blank to reset the hidden word
	LDR		R5, =hdnWord	@ Loading the hidden word variable to clear it
	BL		strcpy			@ Resetting the variable
	
	MOV		R0, #54			@ Loading the ascii value for 0 into R0
	LDR		R1, =guessRemain	@ Loading remaining guess string to reset the value
	STRB	R0, [R1, #11]	@ Resetting the remaining guesses to 6 
	
	POP		{PC}			@ Returning to _start

/*
 * remainingUpdate Subroutine
 *
 * This subroutine updates the number of remaining guesses after every incorrect character guess
 *
 * R8: Used to load the string containing the remaining guesses
 * R9: Used to store the ASCII value of the remaining number of guesses, and store it in the remaining guesses string
 */
 
remainingUpdate:

		LDR		R8, =guessRemain	@ Loading the address of the remaining guesses message to update it
		MOV		R9, R0		@ Moving the remaining guess number into R9 to conver it to ascii
		ADD		R9, R9, #48	@ Convert the number to ascii
		STRB	R9, [R8, #11]		@ Updating the remaining number of guesses
		MOV		PC, LR

/*
 * drawHangman Subroutine
 *
 * This subroutine adds the different hangman parts to the gallows, based on the number of remaining guesses
 *
 * R1: Used to store the gallows string
 * R2: Used to store the ascii of the characters to add into the gallows string
 */
 
drawHangman:

	LDR		R1, =gallows	@ Loading the gallows ascii artinto R1 to modify it
	
	CMP		R0, #5			@ Check to see if one bad guess has been made
	
	MOVEQ	R2, #40			@ Loading the ascii for "(" to draw the head
	STREQB	R2, [R1, #349]	@ Adding the head to the gallows 
	MOVEQ	R2, #120		@ Loading the ascii for "x" to draw an eye
	STREQB	R2, [R1, #350]	@ Adding the left eye to the gallows 
	STREQB	R2, [R1, #352]	@ Adding the right eye to the gallows 
	MOVEQ	R2, #46			@ Loading the ascii for "." to draw the nose
	STREQB	R2, [R1, #351]	@ Adding the nose to the gallows 
	MOVEQ	R2, #41			@ Loading the ascii for ")" to draw the head
	STREQB	R2, [R1, #353]	@ Adding the head to the gallows 
	MOVEQ	PC, LR			@ If an addition was made, return to the main code

	CMP		R0, #4			@ Check to see if two bad guesses were made
	MOVEQ	R2, #124		@ Loading the ascii for "|" to draw the body
	STREQB	R2, [R1, #432]	@ Adding the body to the gallows 
	STREQB	R2, [R1, #513]	@ Adding the body to the gallows
	MOVEQ	PC, LR			@ If an addition was made, return to the main code
	
	CMP		R0, #3			@ Check to see if three bad guesses were made
	MOVEQ	R2, #47			@ Loading the ascii for "/" to draw the left arm
	STREQB	R2, [R1, #431]	@ Adding the left leg to the gallows 
	MOVEQ	PC, LR			@ If an addition was made, return to the main code
	
	CMP		R0, #2			@ Check to see if three bad guesses were made
	MOVEQ	R2, #92			@ Loading the ascii for "\" to draw the right arm
	STREQB	R2, [R1, #433]	@ Adding the left leg to the gallows 
	MOVEQ	PC, LR			@ If an addition was made, return to the main code
	
	CMP		R0, #1			@ Check to see if three bad guesses were made
	MOVEQ	R2, #100			@ Loading the ascii for "d" to draw the left leg
	STREQB	R2, [R1, #592]	@ Adding the left leg to the gallows 
	MOVEQ	PC, LR			@ If an addition was made, return to the main code
	
	CMP		R0, #0			@ Check to see if three bad guesses were made
	MOVEQ	R2, #98			@ Loading the ascii for "b" to draw the right leg
	STREQB	R2, [R1, #594]	@ Adding the left leg to the gallows 
	MOVEQ	PC, LR			@ If an addition was made, return to the main code
	
	MOV		PC, LR			@ Just here as a backup in case there are any weird values

/*
 * enterWord Subroutine
 *
 * This subroutine allows the user to enter a custom word to use for the game
 *
 * R0: Used to store the user's answer to the question asking if they would like to use a custom word (for a CMP)
 * R1: Used to print out the prompt to the user, and get the user's input
 * R2: Used to limit the number of characters than the user can enter in the inputs
 */
 
enterWord:

	PUSH	{LR}			@ Pushing the LR onto
	LDR		R1, =cstWrdQstn	@ Loading a message into R1 to ask the user if they want a custom word
	BL		strprint		@ Printing out the message
	
	LDR		R1, =inputLttr	@ Loading the address at which the input letter is to be stored
	MOV		R2, #2			@ Limiting the input to 2 characters (letter and newline)
	BL		strinput		@ Getting the user input
	BL		strupr			@ Making the input letter uppercase, if not already

	LDR		R1, =inputLttr	@ Reloading the address into R1 for byte analysis
	LDRB	R0, [R1]		@ Loading the byte value into R0 for a CMP
	
	CMP		R0, #78			@ Checking to see if the user input an "N"
	POPEQ	{PC}			@ Return, and generate a random word if no custom word is desired
	
	CMP		R0, #89			@ Checking to see if the user entered a "Y"
	POPNE	{PC}			@ If an invalid input was given, ignore it and use a random word
	
	
	LDR		R1, =custWrd	@ Asking the user for their custom word
	BL		strprint		@ Printing out the message
	LDR		R1, =rndWord	@ Loading the address of the random word to take user input
	MOV		R2, #10			@ Setting 10 into R2 to limit the user's input to 10 characters (9 + newline)
	BL		strinput		@ Getting the user to enter their word
	BL		strupr			@ COnverting the input to uppercase

	BL		wordHider		@ Generating the hidden word
	
	B		customSkip		@ If a custom word was entered, skip random word generation
	
	POP		{PC}			@ Returning to the main loop

.data

@ newline is used to print out newlines and clean up the prompt
newline:	.asciz	"\n"

@ intro is used to print out a general introduction for the game
intro:		.ascii	"\n"
			.ascii	"Welcome to Alex's Hangman game!\n"
			.asciz	"This game was made for the NET2009 course.\n"

@ rules is used to print out the rules at the start of a game, or during the game
rules:		.ascii	"\nThe rules of the game are as follows:\n"
			.ascii	"  1-A word will be randomly selected from a word bank\n"
			.ascii	"  2-The word will be hidden, and shown using underscores (_)\n"
			.ascii	"  3-Each word in the word bank is 5 to 9 characters long\n"
			.ascii  "  4-As the player, you guess one letter at a time to try and guess the word\n"
			.ascii	"  5-The first character is used as input, and is not case-sensitive\n"
			.ascii	"  6-Be careful, there are a limited amount of guesses!\n"
			.ascii	"  7-A new body part will be added to the Hangman for every incorrect guess\n"
			.ascii  "  8-After 6 incorrect guesses, the player loses\n"
			.ascii  "  9-After each game, the player will be asked if they would like to play again\n"
			.ascii	"  10-Type 'help' (case insensitive) to view the rules during the game\n"
			.asciz	"  11-Type 'quit' (case insensitive) during the game to exit\n\n"

@ playQstn is used to ask the user if they would like to play a new game
playQstn:	.asciz	"Would you like to play a new game? (Y/N) : "

@ Used to store the letter that was guessed by the user
@ 11 bytes are used in case the user enters "HELP" or "QUIT", with backup badding
inputLttr:	.space	11

@ help is used for a strcmp to check for a "HELP" input
help:		.asciz	"HELP"

@ quit is used for a strcmp to check for a "QUIT" input
quit:		.asciz	"QUIT"

@ exitMsg is used to deal with any inappropriate inputs
exitMsg:	.asciz	"An invalid input was entered, exiting the program."

@ custWrd is used to prompt the user to enter a custom word
custWrd:	.asciz	"Please enter a word (Max 9 characters): "

@ cstWrdQstn is used to ask the user if they would like to use a custom word
cstWrdQstn:	.asciz	"Would you like to use a custom word? (Y/N): "

@ gameTitle is used to print out the title, as well as some ascii art
gameTitle:	.ascii	"                ________________________________________________\n"
			.ascii	"          #     |  _   _  ___  _   _ ________  ___ ___  _   _  |\n"
			.ascii	"        _#_     | | | | |/ _ \\| \\ | |  __ \\  \\/  |/ _ \\| \\ | | |\n"
			.ascii	"________|_|_____| | |_| / /_\\ \\  \\| | |  \\/ .  . / /_\\ \\  \\| | |    ____________\n"
			.ascii	"               /| |  _  |  _  | . ` | | __| |\\/| |  _  | . ` | |   /\n"
			.ascii	"              /*| | | | | | | | |\\  | |_\\ \\ |  | | | | | |\\  | |  /\n"
			.asciz	"             /**| \\_| |_|_| |_|_| \\_/\\____|_|  |_|_| |_|_| \\_/ | /\n"

@ gallowsTmp acts as the gallows template, and is used to reset the ascii art at the start of every game
gallowsTmp:	.ascii	"            /***|______________________________________________|/\n"
			.ascii	"___________/***'     ____          O=======o             ____  /________________\n"
			.ascii	"   //  \\\\ | _____   //  \\\\   _____ ||      |   _____    //  \\\\ | _____   //  \\\\\n"
			.ascii	"  ||    ||| |_|_|  ||    ||  |_|_| ||      |   |_|_|   ||    ||| |_|_|  ||    ||\n"
			.ascii	"  ||   o||| |_|_|  ||   o||  |_|_| ||          |_|_|   ||   o||| |_|_|  ||   o||\n"
			.ascii	"__||____|||________||____||________||__________________||____|||________||____||\n"
			.ascii	"  /_____/ |        /_____/   ______||________________  /_____/ |        /_____/\n"
			.ascii	"____________________________/      ||               /|__________________________\n"
			.ascii	"|p'''''q||||||||||p'''''q||/       ||              / ||p'''''q||||||||||p'''''q|\n"
			.ascii	"|_______||||||||||_______|/                       / /||_______||||||||||_______|\n"
			.ascii	"#########################/_______________________/ /############################\n"
			.ascii	"#########################|                      | /#############################\n"
			.asciz	"#########################|______________________|/##############################\n"

@ gallows is to store the running version of the game, including any body parts added to the hangman
gallows:	.space	1500	@ a bit bigger than needed, but i would rather be safe than sorry (and I'm not counting the characters in my ascii art)

@ rndWord is used to store the rancomly selected word, instead of juggling around the registers
rndWord:	.space	11

@ hdnWord is used to store and display the word, with the letters replaced by underscores		
hdnWord:    .space	22

@ rndWipe is used to reset the contents of rndWord at the start of a new game 		
rndWipe:	.asciz	"          "

@ hdnWipe is used to reset the contents of the hidden word at the start of every new game
hdnWipe:	.asciz	"                     "

@ wordPrompt is used to make the game output a bit nicer
wordPrompt: .asciz	"                         WORD: "

@ guessPrompt is used to make the game output a bit nicer
guessPrompt:	.asciz	"                      GUESSES: "

@ charSelect is used to prompt the user to enter a character
charSelect:	.asciz	"     Please guess a character: "

@ Used to reset the list if guesses every game
guessBlank:	.asciz  "                  "

@ guessList is used to store the previous wrong guesses
guessList:	.space	29

@ guessRemain is used to tell the user how many incorrect guesses they have remaining
guessRemain:	.asciz	"REMAINING:  "

@ winMsg is used to tell the user they won
winMsg:		.asciz	"                                You win!\n"

@ lossMsg is used to tell the user they lost
lossMsg:	.asciz	"                  You lose! The word was "

@ The words variable contains the list of possible words that the game can use
@ The .byte is used to pad each word, so that the code can use an offset of 10 bytes to get the words
words:		.ascii	"SQUIRREL"
			.byte	0x00, 0x00
			.ascii	"SQUIRRELS"
			.byte	0x00
			.ascii	"CHIPMUNK"
			.byte	0x00, 0x00
			.ascii	"ASSEMBLY"
			.byte	0x00, 0x00
			.ascii	"ALGONQUIN"
			.byte 	0x00
			.ascii	"CARLETON"
			.byte	0x00, 0x00
			.ascii	"COMPUTER"
			.byte	0x00, 0x00
			.ascii	"TELEPHONE"
			.byte	0x00
			.ascii	"BURRITO"
			.byte	0x00, 0x00, 0x00
			.ascii	"BITSY"
			.byte	0x00, 0x00, 0x00, 0x00, 0x00
			.ascii	"COFFEE"
			.byte	0x00, 0x00, 0x00, 0x00
			.ascii	"BAMBOOZLE"
			.byte	0x00
			.ascii	"QUARTZ"
			.byte	0x00, 0x00, 0x00, 0x00
			.ascii	"WARNING"
			.byte	0x00, 0x00, 0x00
			.ascii	"CAMERA"
			.byte	0x00, 0x00, 0x00, 0x00
			.ascii	"MONITOR"
			.byte	0x00, 0x00, 0x00
			.ascii	"DISCORD"
			.byte	0x00, 0x00, 0x00
			.ascii	"PISTACHIO"
			.byte	0x00
			.ascii	"COASTER"
			.byte	0x00, 0x00, 0x00
			.ascii	"KEYBOARD"
			.byte	0x00, 0x00
			.ascii	"TRANSFER"
			.byte	0x00, 0x00
			.ascii	"RASPBERRY"
			.byte	0x00
			.ascii	"LOBSTER"
			.byte	0x00, 0x00, 0x00
			.ascii	"CARDBOARD"
			.byte	0x00
			.ascii	"SHELVES"
			.byte	0x00, 0x00, 0x00
			
				
