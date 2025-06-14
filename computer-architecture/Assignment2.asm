###############################################################################
# Learn about exceptions and interrupts handling in Mips. 
# First version by Karl Marklund <karl.marklund@it.uu.se>
###############################################################################
	.globl main
	.data
	loop_output: .asciiz "\nThe processor is doing useful work until it is interrupted - iteration "
	

###############################################################################
# USER TEXT SEGMENT
# MARS start to execute at label main in the user .text segment.
###############################################################################

	.text
main:
	#li $s0, 0x7fffffff  	# The largest 32 bit positive two's complement number.
	#addi $s1, $s0, 1  	# Trigger an arithmetic overflow exception. 
	#nop
	#lw $s0, 4($zero) 	# Trigger a bad data address (on load) exception.
	#nop 			# note that this is a user application trying to load a kernel memory
	#teqi $zero, 0   	# Trigger a trap exception. 
	
	#######################################################
	# >>>>>>>>>>>>>>> ASSIGNMENT PART 2 <<<<<<<<<<<<<<<<#
	#######################################################
        # DONE - ASSIGNMENT TODO 2:  Enable simulator keyboard interrupts. 	
	# Hint: Get the value of the keyboard ""control"" register and 
	# set the interrupt enable bit WITHOUT changing other bits
 	
 	lw $t0, 0xffff0000
	ori $t0, $t0, 0x2
	sw $t0, 0xffff0000

	#######################################################
	# >>>>>>>>>>>>>>> ASSIGNMENT PART 1 <<<<<<<<<<<<<<<<#
	#######################################################
	# DONE - ASSIGNMENT TODO 1: 
	# This infinite loop simulates the CPU doing something useful
	# write down the code that would print 
	# a line of your choice every 500 iterations
	li $s0, 0
	li $s1, 500
	la $s2, loop_output
infinite_loop:
	addi $s0, $s0, 1
	div $s0, $s1
	mfhi $t0
	bnez $t0, infinite_loop
	#Every 500 iterations
	move $a0, $s2
	li $v0, 4
	syscall
	move $a0, $s0
	li $v0, 1
	syscall
	j infinite_loop
###############################################################################
# KERNEL DATA SEGMENT
###############################################################################
	.kdata
	UNHANDLED_EXCEPTION:	.asciiz "\n===>      Unhandled exception       <===\n\n"
	UNHANDLED_INTERRUPT: 	.asciiz "\n===>      Unhandled interrupt       <===\n\n"
	OVERFLOW_EXCEPTION: 	.asciiz "\n===>      Arithmetic overflow       <===\n\n" 
	TRAP_EXCEPTION: 	.asciiz "\n===>         Trap exception         <===\n\n"
	BAD_ADRS_EXCEPTION: 	.asciiz "\n===>   Bad data address exception   <===\n\n"
	fired_output:		.asciiz "\nFired: Interrupt "
	inactive_output:	.asciiz "\nInactive: Interrupt "
	new_line:		.asciiz "\n"
# Variables for save/restore of registers used in the handler
	save_v0:    .word   0
	save_a0:    .word   0
	save_at:    .word   0
	save_t0:    .word   0
	save_t1:    .word   0

###############################################################################
# KERNEL TEXT SEGMENT 
###############################################################################
# The kernel handles all exceptions and interrupts.
# 
# The registers $k0 and $k1 should never be used by user level programs and 
# can be used exclusively by the kernel. 
#
# In a real system the kernel must make sure not to alter any registers
# in usr by any of the user level programs. For all such registers, the kernel
# must make sure to save the register valued to memory before use. Later, before 
# resuming execution of a user level program the kernel must restore the 
# register values from memory. 
# 
# Note, that if the kernel uses any pseudo instruction that translates 
# to instructions using $at, this may interfere with  user level programs 
# using $at. In a real system, the kernel must  also save and restore the 
# value of $at. 
###############################################################################

   		# The exception vector address for MIPS32.
   		.ktext 0x80000180  # store this code starting at this address in kernel  part				
   		# Save ALL registers modified in this handler, except $k0 and $k1
		#  we can save registers to static variables.
		
		#.set    noat     		# do not use $at from here 
		#sw      $at, save_at  	# save $at
		#.set    at       		# $at can now be used  
		
		move 	$k0, $at		# store value of $at before it is corrupted
		sw   	$k0, save_at 		# save $at
				
		sw      $v0, save_v0		# save $v0
		sw      $a0, save_a0  		# save $a0
		sw      $t0, save_t0  		# save $t0
		sw      $t1, save_t1  		# save $t1
		# starting processing the exception
		mfc0 $k0, $13   		# Get value in CAUSE register
		andi $k1, $k0, 0x00007c  	# Mask all but the exception code (bits 2 - 6) to zero.
		srl  $k1, $k1, 2	  	# Shift two bits to the right to get the exception code in $k1
		beqz $k1, __interrupt		# if exception code is zero --> it is  an interrupt
__exception:			# exceptions are processed here 
	# DONE - replace OVERFLOW_CAUSE_VALUE by the corresponding number 
	beq $k1, 12, __overflow_exception

	# DONE - Add needed code below to branch to label __bad_address_exception. 	
	beq $k1, 4, __bad_address_exception
	beq $k1, 5, __bad_address_exception
		
	# DONE - Add code to branch to label __trap_exception 
	beq $k1, 13, __trap_exception
	
__unhandled_exception: 
		# It's not really proper doing syscalls in an exception handler,
		# but this handler is just for demonstration and this keeps it short	
	li $v0, 4	  	#  Use the MARS built-in system call 4 (print string) to print error messsage.
	la $a0, UNHANDLED_EXCEPTION
	syscall 
 	j __resume_from_exception
__overflow_exception:

  	#  Use the MARS built-in system call 4 (print string) to print error messsage.	
	li $v0, 4
	la $a0, OVERFLOW_EXCEPTION
	syscall 
 	j __resume_from_exception
 	
 __bad_address_exception:
  	#  Use the MARS built-in system call 4 (print string) to print error messsage.
	li $v0, 4
	la $a0, BAD_ADRS_EXCEPTION
	syscall
 	j __resume_from_exception	
 
__trap_exception: 
  	#  Use the MARS built-in system call 4 (print string) to print error messsage.
	li $v0, 4
	la $a0, TRAP_EXCEPTION
	syscall
 	j __resume_from_exception

__interrupt: 
	#######################################################
	# >>>>>>>>>>>>>>> ASSIGNMENT PART 3 <<<<<<<<<<<<<<<#
	#######################################################
	# DONE - ASSIGNMENT TODO 3: 
	# Value of cause register should already be in $k0. 	
	# Check the pending interrupt bits 
	# for every bit  print "Interrupt x is fired", where x is the 
	# bit number 
	# If the fired interrupt is a keyboard interrupt, 
	# execute the code @ __keyboard_interrupt 
	
	andi $k0, $k0, 0xFF00	#Mask for interrupt bits
	srl $k0, $k0, 8		#Interrupt bits
	li $k1, 0x80		#Mask - for most significant bit at first
	li $t0, 15		#Counter
__process_interrupt_bits:
	and $t1, $k0, $k1
	bnez $t1, __interrupt_fired
#Interrupt inactive
	la $a0, inactive_output
	li $v0, 4
	syscall				#Print "Inactive: Interrupt "
	
	move $a0, $t0
	li $v0, 1
	syscall				#Print interrupt number
	
	sub $t0, $t0, 1			#Decrement counter
	srl $k1, $k1, 1			#Shift mask
	bgt $t0, 7, __process_interrupt_bits		#Continue loop unless all pending interrupt bits have been checked

__unhandled_interrupt:    
  	#  Use the MARS built-in system call 4 (print string) to print error messsage.	
	li $v0, 4
	la $a0, UNHANDLED_INTERRUPT
	syscall 
 	j __resume

__interrupt_fired:
	la $a0, fired_output
	li $v0, 4
	syscall				#Print "Fired: Interrupt "
	
	move $a0, $t0
	li $v0, 1
	syscall				#Print interrupt number
	
	beq $t0, 8, __keyboard_interrupt
	j __resume
 	
 	#######################################################
	# >>>>>>>>>>>>>>> ASSIGNMENT PART 4 <<<<<<<<<<<<<<<#
	#######################################################
	# DONE - ASSIGNMENT TODO 4: 
 	# Get the ASCII value of pressed key from the memory mapped receiver 
 	# data register. (MMIO tool). Print char to the STDIO using a proper syscall. 
 	# Make any unecessary changes in ktext and kdata  to perform this task
__keyboard_interrupt:
	la $a0, new_line
	li $v0, 4
	syscall
	
 	lb $a0, 0xffff0004
 	li $v0, 11
 	syscall				#Print the character entered by the user

	j __resume
	

__resume_from_exception:
	# When an exception or interrupt occurs, the value of the program counter 
	# ($pc) of the user level program is automatically stored in the exception 
	# program counter (ECP), the $14 in Coprocessor 0. 
       	# Get value of EPC (Address of instruction causing the exception).   
        mfc0 $k0, $14
        
	# DONE - Uncomment the following two instructions to avoid
	# executing  the same instruction causing the current exception again.        
	addi $k0, $k0, 4   # Skip offending instruction by adding 4 to the value stored in EPC    
	mtc0 $k0, $14      # Update EPC in coprocessor 0.
__resume:
	# Restore registers and reset processor state
	lw      $v0, save_v0   # Restore $v0 before returning
	lw      $a0, save_a0   # Restore $a0 before returning	
	lw      $t0, save_t0   # Restore $a0 before returning	
	lw      $t1, save_t1   # Restore $a0 before returning	
	
	#.set    noat          # Prevent assembler from modifying $at
	#lw      $at, save_at  # Restore $at before returning
	#.set    at
	
	lw	$k0, save_at	# Store save_at in $k0 to ensure it will not be corrupted
	move	$at, $k0	# Restore $at before returning	
	
	eret			# Use the eret (Exception RETurn) instruction to set $PC to $EPC@C0 
	
