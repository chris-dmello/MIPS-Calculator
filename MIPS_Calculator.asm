# File Name: pgm5.asm
# Author - Christopher D'Mello
# Modificatiion History:
#	November 15th, 2019 - This file and the code contained were created by Christopher D'Mello on November 2nd, 2019.
#	November 16th, 2019 - A procedure in this file was modified to include a user prompt to recieve file name accordind to program requirements.
#	November 19th, 2019 - Calculation functionality was added.
#	November 25th, 2019 - Order of operation support was added 
#	November 26th, 2019 - Paranthesis support was added 
# Procedures:
#	main - Asks user for file name, then output the contents of the file to the console.
#	read - reads characters one by one. Converts and caculates the values.

.data						#data to be used in the program
	prompt1:		.asciiz 	"Enter the name of the file: "	# first promt string
	errorFileOpen:	.asciiz 	"Error - The file could not be opened"		# error promt string
	errorUnknown:	.asciiz 	"An Unknown Character was detected in the file."
	sInput:		.asciiz 	"Input: "
	sResult:		.asciiz 	"Performing Operation: "
	sFinal:		.asciiz 	"Result: "
	sSaved:		.asciiz 	"Saved to Memory: "
	sClrMem:		.asciiz 	"Cleared Memory"
	sRecall:		.asciiz 	"Recalled from Memory: "
	tempFileName:	.asciiz	"c.txt"
	filename:		.space 	64			# reserve 64 bytes to save the file name
	buffer: 		.byte	1			# buffer for storing input byte
	operandStack:	.space	400			# hold up to 100 operands
	operatorStack:	.space	100			# hold up to 100 operators
	
.text

	# Procedure Name: main
	# Author - Christopher D'Mello
	# Modificatiion History:
	#	November 2nd, 2019 -  This procedure was created by Christopher D'Mello
	# Description: Prompts for the user to enter a file name. Contains a loop "remove" to remove the new line character at the end.
	#	Arguments: none

	main:
	# |Prompt For File Name|
		li $v0 4			#Load 4 into $v0, 4 is system call for print_string service
		la $a0 prompt1		#Load the value stored in prompt1 into $a0, to be used as the prompt
		syscall			#System call, prints prompt1

		li $v0, 8			#Load 8 into $v0, 8 is system call for read_string service
		la $a0, filename		#Load the value stored in userInpu into $a0, to save String from system call to read_string
		li $a1, 64			#Load 64 into $a1, to set the string length for system call for read_string
		syscall 			#System call, Reads Input string up to 64 characters, saves String to userInput

		li $s2,0        		# Set index to 0


	# |Remove The newline character at the end of the raw filename input|
	
	remove:
   		lb $a3,filename($s0)    	# Load character at index
    		addi $s0,$s0,1     		# Increment index
    		bnez $a3,remove     		# Loop until the end of string is reached
    		beq $a1,$s0,skip    		# Do not remove \n when string = maxlength
    		subiu $s0,$s0,2     		# If above not true, Backtrack index to '\n'
    		sb $0, filename($s0)    	# Add the terminating character in its place

	# |Load The File|
	
	skip:
		li $v0 13			# Load 13 into $v0, 13 is system call for load file service
		#la $a0, filename		# Load address of filename into $a0
		la $a0, filename		# Load address of filename into $a0
		li $a1, 0			# Load 0 of filename into $a1
		li $a2, 0			# Load 0 of filename into $a2
		syscall			# system call, loads file


	# |Convert from Hex to decimal|
		
		# REGISTER ASSIGNMENTS:
		#	$t0 - 
		#	$t1 - Memory
		#	$t2 - Last Operator
		#	$t3 - Last Operand
		#	$t4 - General Temporary
		#	$t5 - Converted value
		#	$t6 - Compare value
		#	$t7 - Contains new line character for comparison
		#	$t8 - Contains the single character input
		#	$t9 - Accumulator for Hexadecimal to Decimal Conversion.
		#	$s0 - File descriptor
		#	$s1 - 
		#	$s2 - Input type descriptor (1-operand 2-operator, 3-equals, 4-recall)
		#	$s3 - 
		#	$s4 - operandStack Pointer
		#	$s5 - operatorStack Pointer
		#	$s6 - Popped number 1
		#	$s7 - Popped number 2
		
		move $s0, $v0		# copy contents of $v0 to $s0. $s0 now contains the file descriptor from $v0
		move $t1, $0		# clear memory 
		move $t2, $0		# set Last Operand to 0, signifying no operation before this
		move $t3, $0		# clear last operand
		move $t4, $0		# clear general temporary
		blt $v0, $0, fileerror		# error if 
		li $t7, 10			# store new line character for return
		li $s2, 1			
		la $s4, operandStack		# initialize stack pointer for operandStack
		la $s5, operatorStack		# initialize stack pointer for operatorStack
		li $a0, '&'			# start the start of the operand stack to '&' to be used - 
		sb $a0, ($s5)		# 	- as an endpoint for the stack
		
# Procedure Name: read
	# Author - Christopher D'Mello
	# Modificatiion History:
	#	November 16th, 2019 -  This procedure was created by Christopher D'Mello
	#	November 25th, 2019 - Order of operation support was added to this function
	#	November 26th, 2019 - Paranthesis support was added to this function
	#	precedence and paranthesis
	# Description: read characters one by one. Converts and calculates the values. Supports order of
	#	precedence and paranthesis
	#	Arguments: none
		
	read:	li $t9, 0			# clear accumulator
		li $s2, 0			# clear input type descriptor
	loopDigit:	move $a0, $s0		# Restore file descriptor
		li $v0, 14			# read_file syscall code = 14
		la $a1, buffer  		# Load address of the space that holds the string containing the contents of the file
		li $a2, 1			# The maximum number of Characters hardcoded
		syscall			# system call, reads contents of file
		
		beq $s2, 2, eolop		# go to end of line function for operator
		beq $s2, 3, read		# read in a new number after equals function
		beq $s2, 4, eolr		# go to end of line for recall
		beq $v0, $0, eof		# if the file has ended, go to end of file function
		lb $t8, buffer		# load digit from the buffer
		beq $t8, $t7, eol

		# The next lines simply allow the program to jump to the Operator section if detected.
		li $t6, 37			# 37 is the ASCII value of =
		beq $t6, $t8, ifOperator
		
		li $t6, 40			# 42 is the ASCII value of *
		beq $t6, $t8, ifOperator
		
		li $t6, 41			# 42 is the ASCII value of *
		beq $t6, $t8, ifOperator
		
		li $t6, 42			# 42 is the ASCII value of *
		beq $t6, $t8, ifOperator
		
		li $t6, 43			# 43 is the ASCII value of +
		beq $t6, $t8, ifOperator	
		
		li $t6, 45			# 45 is the ASCII value of -
		beq $t6, $t8, ifOperator
		
		li $t6, 47			# 47 is the ASCII value of /
		beq $t6, $t8, ifOperator
		
		li $t6, 61			# 61 is the ASCII value of %
		beq $t6, $t8, ifOperator
		
		li $t6, 114			# 114 is the ASCII value of r
		beq $t6, $t8, ifOperator
		
		li $t6, 115			# 115 is the ASCII value of s
		beq $t6, $t8, ifOperator
		
		li $t6, 122			# 122 is the ASCII value of z
		beq $t6, $t8, ifOperator
		
		sll $t9, $t9, 4		# shift the accumulator

		bgt $t8, 59, alphabet1		# set lower limit for alphabet
	ret:	bgt $t8, 47, number1		# set lower limit for number
		j ukChar
	number2:	addi $t5, $t8, -48		# if number, convert it by subtracting 48
		j next			# skip over alphabet section since it is a number

	alphabet2:	addi $t5, $t8, -55		# if alphabet, convert it by subtracting 55

	next:	add $t9, $t9, $t5		# add the value to the accumulator
		j loopDigit			# jump back and convert the next digit

	alphabet1:	blt $t8, 70, alphabet2		# set upper range for alphabet
		j ret			# return
		
	number1:	blt $t8, 58, number2		# set upper range for number
		j ret			# return
		
	# end of line if number
	eol:	move $a0, $t9		# move number to $a0 to be used as pushNum argument
		move $t3, $t9
		jal pushNum			# invoke pushNum
		
		li $v0, 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0 sInput		# Load the value stored in sInput into $a0, to be used as the prompt
		syscall			# System call, prints sInput
	
		move $a0, $t9		# Move number 
		li $v0, 1			#
		syscall			# System call, prints the value of the number 


	# end of line if recall
	eolr:	li $s2, 1			# set input type descriptor
		li $v0, 11			# Load 11 into $v0, 11 is syscall code for print_string service
		li $a0, 10			# Load 10 into $a0, to be used as the new line
		syscall			# System call, prints nlPrompt
		
		j read
		
	# end of line if operator
	eolop:	li $s2, 1			# Set input type descriptor to 2 (operator)
		beq $t2, '(', openP		# jump to openP if '(' if found
		beq $t2, ')', closeP		# jump to closeP if ')' if found
		lb $a0, ($s5)		# peek at the stack
		beq $a0, '(', firstOp		# see if peeked item is '(', then skip operation
		beq $a0, '&', firstOp		# see if peeked item is '(', then skip operation
		jal precedence		# get precedence of item in $a0
		move $a1, $v0		# move the precedence of the itme into $a1
		move $a0, $t2		# move the current operator into $a0
		jal precedence		# get precedence of item in $a0
		bgt $v0, $a1, firstOp		# if top of operator stack has greater precedence, skip operation
		jal doOp			# else, do the operation at the top of the stack
		j eolop			# return to the top of the loop
		
		
	firstOp:	move $a0, $t2		# move the current operator into $a0  
		jal pushOp			# push $a0 to operator stack
		
		j read			# jump back to to the outer loop

	# end of file
    	eof:	li $v0, 16         		# Load 16 into $v0, 16 is system call for close_file service
    		move $a0,$s0      		# copy contents of $s0 to $a0. $a0 now contains the file descriptor from $s0
    		syscall			# system call, close file
		
		j exit			# jump to exit file

	equals:	jal finalEval		# if equals sign is detected, commemce final evaluation
		move $t2, $0		#clear last opertor
		j read			# return to read, proceed to next line
		
		
	openP:	move $a0, $t2		# if open paranthesis is detected, push it to stack
		jal pushOp			# push '(' to operator stack
		j read			# return to read, proceed to next line
		
	closeP:	lb $a0, ($s5)		# peek at the stack
		beq $a0, '(', endCloseP		# if operning parantheis is found in peek, stop operation loop
		jal doOp			# do the top operations on the stack
		j closeP			# loop to back and keep doing operations until opening paranthesis
	endCloseP:	jal popOp			# pop the opening paranthesis from the stack
		j read			# return to read, proceed to next line
	
	pushOp:	addi $s5, $s5, 1		# push operator to operand stack
		sb $a0, ($s5)
		jr $ra
	
	pushNum:	addi $s4, $s4, 4		# push number to number stack
		sw $a0, ($s4)
		jr $ra
	
	popOp:	lb $v0, ($s5)		# pop operator from operator stack
		addi $s5, $s5, -1
		jr $ra
		
	popNum:	lw $v0, ($s4)		# pop number from number stack
		addi $s4, $s4, -4
		jr $ra
	
	finalEval:	move $a2, $ra		# funtion to complete final evaluation
	beginEval:	lb $a0, ($s5)		# peek at operator stack
		beq $a0, '&', endEval		# 
		jal doOp			# do the top operations on the stack
		j beginEval
		
	endEval:	li $v0, 4			
		la $a0, sFinal		
		syscall			# Print "Result: " to console
		
		jal popNum			
		move $a0, $v0		
		li $v0, 1			#
		syscall
		
		li $s2, 1			# 
		li $v0, 11			# Load 11 into $v0, 11 is syscall code for print_string service
		li $a0, 10			# Load 10 into $a0, to be used as the new line
		syscall			# System call, prints nlPrompt
		
		jr $a2
		
		
	# precedence function to get precidence
	
	precedence:	beq $a0, '+', pOne		# + has precedence one
		beq $a0, '-', pOne		# - has precedence one
		beq $a0, '*', pTwo		# * has precedence two
		beq $a0, '/', pTwo		# / has precedence two
		beq $a0, '%', pTwo		# % has precedence two
		beq $a0, '(', pThree		# ( has precedence three
		beq $a0, ')', pThree		# ) has precedence three
		move $v0, $0		# if none of the above, return zero precedence
		jr $ra
	pOne:	li $v0, 1			# return precedence of one
		jr $ra
	pTwo:	li $v0, 2			# return precedence of two
		jr $ra
	pThree:	li $v0, 3			# return precedence of three
		jr $ra
		
		
	ifOperator:	li $v0, 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0, sInput		# load string
		syscall			# Print "Input: " to console
		li $v0, 11			
		move $a0, $t6		# move operator to $a0, for syscall
		move $t2, $t6		# set last operator
		syscall			# Print the operator to console
		li $s2, 2			# Set operator flag
		
		li $v0 11			# Load 11 into $v0, 11 is syscall code for print_string service
		li $a0 10			# Load 10 into $a0, to be used as the new line
		syscall			# System call, prints nlPrompt
		
		beq $t8, 61, equals
		beq $t8, 's', savemem		# jump to savemem if 's' is detected
		beq $t8, 'z', clrmem		# jump to clrmem if 'c' is detected
		beq $t8, 'r', recmem		# jump to recmem if 'r' is detected
		j loopDigit			# go back to loopDigit
		
	# Operation Funtions
	
	# equals
		
	doOp:	move $a3, $ra		# save return address in order to call other linked functions.
		jal popNum			# pop number from top of operand stack
		move $s6, $v0		# save the popped number to $t6
		jal popNum			# pop number from top of operand stack
		move $s7, $v0		# save the popped number to $t7
		jal popOp			# pop operator from top of operator stack
		move $t4, $v0		# save the popped operator to $t4
		beq $v0, 43, doOpAdd		# jump to complete addition operation
		beq $v0, 45, doOpSub		# jump to complete subtraction operation
		beq $v0, 42, doOpMul		# jump to complete multiplication operation
		beq $v0, 47, doOpDiv		# jump to complete division operation
		beq $v0, 61, doOpMod 		# jump to complete modulud operation
		
		jr $a3
	doOpReturn:	jal pushNum			# push the result to the operand stack
		move $t6, $a0		# save result for later printing
		li $v0, 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0, sResult		
		syscall			# Print "Performing Operation: " to console
		li $v0, 1			
		move $a0, $s7		
		syscall			# print first operand
		li $v0, 11
		move $a0, $t4
		syscall			# print the operator
		li $v0, 1
		move $a0, $s6
		syscall			#print the second operand
		li $v0, 11
		li $a0, '='
		syscall			# print the equals sign
		li $v0, 1
		move $a0, $t6
		syscall			# print the result
		li $s2, 1			# set input type flag
		li $v0, 11			# Load 11 into $v0, 11 is syscall code for print_string service
		li $a0, 10			# Load 10 into $a0, to be used as the new line
		syscall			# System call, prints nlPrompt
		jr $a3
		
	doOpAdd:	add $a0, $s7, $s6		# perform addition operation
		j doOpReturn
	doOpSub:	sub $a0, $s7, $s6		# perform subtraction operation
		j doOpReturn
	doOpMul:	mul $a0, $s7, $s6		# perform multiplication operation
		j doOpReturn
	doOpDiv:	div $a0, $s7, $s6		# perform division operation
		j doOpReturn
	doOpMod:	div $v0, $s7, $s6		# perform modulus operation
		mfhi $a0
		j doOpReturn
		
	# memory save function		
	savemem:	move $t1, $t3		# save the number to memory
		li $v0, 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0, sSaved		
		syscall			# print "Saved: " 
		move $a0, $t3
		li $v0, 1
		syscall			# print the saved number
		
		li $v0, 11			#Load 11 into $v0, 11 is syscall code for print_string service
		li $a0, 10			#Load 10 into $a0, to be used as the new line
		syscall			#System call, prints nlPrompt
		j loopDigit
		
	# memory clear function	
	clrmem:	move $t1, $0
		li $v0, 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0, sClrMem		
		syscall			# system call, prints "Cleared Memory"
		
		
		li $v0, 11			#Load 11 into $v0, 11 is syscall code for print_string service
		li $a0, 10			#Load 10 into $a0, to be used as the new line
		syscall			#System call, prints nlPrompt
		j loopDigit
		
	#memory recall function	
	recmem:	move $a0, $t1		# move from memory register to $a0
		jal pushNum			# push $a0 to stack
		li $s2, 4			# set input type descriptor to 4
		li $v0, 4			# Load 4 into $v0, 4 is system call for print_string service			
		la $a0, sRecall		
		syscall			# system call, prints "Recalled from Memory: "
		move $a0, $t1		# move from memory register to $a0
		li $v0, 1			# 
		syscall			# system call, print the recalled number
		
		j loopDigit	
	
			
	#unknown character error
	ukChar:	li $v0 11			# Load 11 into $v0, 11 is syscall code for print_string service
		li $a0 10			# Load 10 into $a0, to be used as the new line
		syscall			# System call, prints new line
	
		li $v0 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0 errorFileOpen		# Load the value stored in errorPromt into $a0, to be used as the prompt
		syscall			# System call, prints errorPromt

		j exit
		
	fileerror:	li $v0 11			# Load 11 into $v0, 11 is syscall code for print_string service
		li $a0 10			# Load 10 into $a0, to be used as the new line
		syscall			# System call, prints new line
	
		li $v0 4			# Load 4 into $v0, 4 is system call for print_string service
		la $a0 errorUnknown		# Load the value stored in errorPromt into $a0, to be used as the prompt
		syscall			# System call, prints errorPromt

	exit:	li $v0, 10 			# Load 10 into $v0, 10 is system call for exit
		syscall			# system call, exits
