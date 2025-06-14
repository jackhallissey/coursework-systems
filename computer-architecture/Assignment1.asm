.globl main
.data
	inputStr: .space 65
	str2float: .word 0
	output1: .asciiz "Jack Hallissey is implementing the bonus assignment.\n"
	output2: .asciiz "Enter a real number: "
	
	intCompString: .space 45	#Integer component string
	intCompLength: .word 0
	fracCompString: .space 10	#Fraction component string
	fracCompLength: .word 0
	invalidCharOutput: .asciiz "\nThe number has an invalid character"
	numTooLargeOutput: .asciiz "\nThe number is too large"
	negativeNumber: .word 0
	
	
	hexOutput1: .asciiz "\nThe sign bit of your number is: "
	hexOutput2: .asciiz "\nThe exponent of your number is: "
	hexOutput3: .asciiz "\nThe fraction of your number is: "
	space: .asciiz " "
	hexDigits: .asciiz "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"
.text
main:
	#Print
	li $v0, 4
	la $a0, output1
	syscall
	li $v0, 4
	la $a0, output2
	syscall
	
	#Get string input from user
	li $v0, 8
  	la $a0, inputStr
	li $a1, 60
	syscall
	
	#Process number
	la $a0, inputStr
	jal processNumber
	
	#Convert string to float
  	jal convertToFloat
	
	#Print the hex representation of the float
	lw $a0, str2float
	jal printHex
	
	#Exit program
	li $v0, 10
	syscall



processNumber:
	move $t0, $a0			#Pointer for where to read next byte
	la $t1, intCompString		#Pointer for where to write next byte
	li $t2, 0			#Length of integer component
	
	lb $t3, ($t0)
	bne $t3, 45, checkDecimal	#Check if the first character is a minus sign (-)
	
	lb $t3, 1($t0)
	beq $t3, 00, invalidChar	#If the first and only character is a minus sign, the number is invalid
	beq $t3, 10, invalidChar
	
	li $t4, 1
	sw $t4, negativeNumber
	add $t0, $t0, 1
	
	checkDecimal:
	lb $t3, ($t0)
	beq $t3, 46, invalidChar	#If the first character is a decimal point, the number is invalid
	
	nextCharInt:
	lb $t3, ($t0)
	beq $t3, 00, noFracComp		#If the next byte is null, the number is finished
	beq $t3, 10, noFracComp		#If the next character is a line break, the number is finished
	beq $t3, 46, beginFracComp	#If the next character is a decimal point, the integer component is finished
	blt $t3, 48, invalidChar	#Invalid character - outside of range of numeric characters
	bgt $t3, 57, invalidChar	#Invalid character
	sb $t3, ($t1)
	add $t0, $t0, 1
	add $t1, $t1, 1
	add $t2, $t2, 1
	j nextCharInt
	
	beginFracComp:
	sw $t2, intCompLength
	add $t0, $t0, 1			#Skip the decimal point
	la $t1, fracCompString
	li $t2, 0			#Length of fraction component
	
	nextCharFrac:
	lb $t3, ($t0)
	beq $t3, 00, numFinished	#Null byte
	beq $t3, 10, numFinished	#Line break
	blt $t3, 48, invalidChar	#Invalid character
	bgt $t3, 57, invalidChar	#Invalid character
	sb $t3, ($t1)
	add $t0, $t0, 1
	add $t1, $t1, 1
	add $t2, $t2, 1
	j nextCharFrac
	
	numFinished:
	sw $t2, fracCompLength	
	jr $ra
	
	noFracComp:			#The number is finsihed, and there is an integer component, but no fraction
	sw $t2, intCompLength
	li $t0, 1
	sw $t0, fracCompLength
	la $t1, fracCompString
	li $t2, 48			#Character "0"
	sw $t2, ($t1)
	jr $ra

	invalidChar:
	la $a0, invalidCharOutput
	li $v0, 4
	syscall
	li $v0, 10
	syscall



convertToFloat:
	#Save addresses of input strings
	la $s0, intCompString 
	la $s1, fracCompString
	
	#Save return address in stack
	subu $sp, $sp, 4
	sw $ra, ($sp)
	
	#Convert fraction component to float
	move $a0, $s1
	lw $a1, fracCompLength
	jal convertFracComp
	
	#Save fraction component float
	move $s2, $v0

	#Convert the integer component of the number to an float
	move $a0, $s0		#Address of input string
	lw $a1, intCompLength	#Number of bytes to read
	jal convertIntComp
	
	#Save integer component float
	move $s3, $v0
		
	#Add the integer and fraction components
	mtc1 $s2, $f0  		#fraction component
	mtc1 $s3, $f1		#integer component
	add.s $f2, $f0, $f1
	
	#Check if the number is infinity (too large to represent)
	mfc1 $t0, $f2
	beq $t0, 0x7F800000, numTooLarge
	
	#Negative numbers
	
	move $t0, $zero
	lw $t0, negativeNumber
	beqz $t0, storeFloat
	li $t0, 0xBF800000	#-1 represented as a float
	mtc1 $t0, $f3
	mul.s $f2, $f2, $f3

	#Store the float
	storeFloat:
	swc1 $f2, str2float
	
	#Restore return address
	lw $ra, ($sp)
	addiu $sp, $sp, 4
	
	#Return
	jr $ra
	
	#Number is too large
	numTooLarge:
	la $a0, numTooLargeOutput
	li $v0, 4
	syscall
	li $v0, 10
	syscall



convertFracComp:
	#a0 contains address of string
	#a1 contains number of bytes to read
	mtc1 $zero, $f0		#Fraction component as float - stored in f0
	li $t0, 0x41200000	#10 as a float
	mtc1 $t0, $f1		#Constant number 10 - stored in f1
	mtc1 $t0, $f2		#Factor to divide by - starts at 10 - increased by a factor of 10 for each digit - stored in f2
	
	move $t0, $a0		#Address of byte to read
	move $t1, $a1		#Number of bytes to read			
	
	addDigitFrac:
	lb $t2, ($t0)
	sub $t2, $t2, 48
	beqz $t2, nextDigitFrac	#Skip the digit if it is 0
	mtc1 $t2, $f3		#Move the digit to f3
	cvt.s.w $f3, $f3	#Convert to float
	div.s $f3, $f3, $f2	#Divide by the factor
	add.s $f0, $f0, $f3	#Add to the fraction component
	
	nextDigitFrac:
	add $t0, $t0, 1		#Next digit
	sub $t1, $t1, 1		#Decrement counter
	mul.s $f2, $f2, $f1	#Multiply factor by 10
	bnez $t1, addDigitFrac	#If there are still digits remaining
	
	mfc1 $v0, $f0		#Store the result
	
	jr $ra



convertIntComp:
	#a0 contains address of string
	#a1 contains number of bytes to read
	
	mtc1 $zero, $f0		#The integer component as a float - stored in f0
	li $t0, 0x3F800000	#1 as a float
	mtc1 $t0, $f1		#Factor - increased by a factor of 10 for each digit - stored in f1
	li $t0, 0x41200000	#10 as a float
	mtc1 $t0, $f2		#10 - stored in f2
	
	add $t0, $a0, $a1	#Add the number of bytes being read to the address (to work backwards)
	sub $t0, $t0, 1		#Address to start at
	
	move $t1, $a1		#Counter - number of bytes to read
	
	addDigitInt:
	lb $t2, ($t0)
	sub $t2, $t2, 48
	beqz $t2, nextDigitInt	#Skip the digit if it is 0
	mtc1 $t2, $f3		#Move the digit to f3
	cvt.s.w	$f3, $f3	#Convert to float
	mul.s $f3, $f3, $f1	#Multiply by the factor
	add.s $f0, $f0, $f3	#Add to the integer component
	
	nextDigitInt:
	sub $t0, $t0, 1		#Next digit
	sub $t1, $t1, 1		#Decrement counter
	mul.s $f1, $f1, $f2	#Multiply factor by 10
	bnez $t1, addDigitInt	#If there are still digits remaining
	
	mfc1 $v0, $f0		#Store the result
	
	jr $ra




printHex:
	move $s0, $a0		#Float to print
	
	#Sign bit
	la $a0, hexOutput1
	li $v0, 4
	syscall
	
	li $t0, 0x80000000	#Mask for most significant bit
	and $t1, $t0, $s0
	bnez $t1, printOne
	li $a0, 0
	j endIf
	printOne:
	li $a0, 1
	endIf:
	li $v0, 1
	syscall
	
	#Save return address in stack
	subu $sp, $sp, 4
	sw $ra, ($sp)
	
	#Exponent
	la $a0, hexOutput2
	li $v0, 4
	syscall
	
	#First hex digit of exponent
	li $t0, 0x78000000	#Mask for 2-5 most significant bits
	and $t1, $t0, $s0
	srl $t2, $t1, 27
	move $a0, $t2
	jal printHexDigit
	
	#Second hex digit of exponent
	li $t0, 0x7800000	#Mask for 6-9 most significant bits
	and $t1, $t0, $s0
	srl $t2, $t1, 23
	move $a0, $t2
	jal printHexDigit
	
	#Fraction
	la $a0, hexOutput3
	li $v0, 4
	syscall
	
	#First hex digit of fraction
	li $t0, 0x700000	#Mask for 10-12 most significant bits
	and $t1, $t0, $s0
	srl $t2, $t1, 20
	move $a0, $t2
	jal printHexDigit
	
	#Remaining hex digits of fraction
	li $s1, 5		#Counter - number of digits
	li $s2, 0xF0000		#Mask (initially for 13-16 most significant bits)
	li $s3, 16		#Number of bits to shift the result of the and operation
	
	nextHexDigit:
	and $t0, $s0, $s2
	srlv $t0, $t0, $s3
	move $a0, $t0
	jal printHexDigit
	
	sub $s1, $s1, 1		#Decrement counter
	srl $s2, $s2, 4		#Shift mask
	sub $s3, $s3, 4		#Decrease number of bits to shift result
	bnez $s1, nextHexDigit
	
	#Restore return address
	lw $ra, ($sp)
	addiu $sp, $sp, 4
	
	jr $ra



printHexDigit:
	la $t0, hexDigits
	move $t1, $a0
	mul $t1, $t1, 2		#Multiply by 2 to account for null bytes
	add $t1, $t1, $t0	#Add to address of hexDigits
	
	move $a0, $t1
	li $v0, 4
	syscall
	
	la $a0, space
	li $v0, 4
	syscall
	
	jr $ra
