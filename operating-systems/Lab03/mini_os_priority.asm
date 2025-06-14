.data
pre_txt:	.asciiz "(process id="
post_txt:	.asciiz "): "
newline: 	.asciiz "\n"

.text
main:				# main, a bit like init/boot loader
	li $v0, 100		# syscall 100 to register a new process with the scheduler
	la $a0, p1		# $a0 contains the process start address
	la $a1, 0		# Priority of 0		
	syscall			# register process1 with scheduler
	la $a0, p2				
	la $a1, 1
	syscall			# register process2 with scheduler
	la $a0, p2				
	la $a1, 3
	syscall			# register process2 again (running this one twice)	
	li $v0, 101		# syscall 101 starts the scheduler
	syscall
	li $v0, 10		# system exit, we should never reach here
	syscall

p1:	
	li $v0, 102		# get process id and store in $t1
	syscall
	add $t1, $zero, $v0
	li $t0, 0		# $t0 as loop counter, start at 0
p1_loop:	
	la $a0, pre_txt		# print preamble text
	li $v0, 4
	syscall	
	add $a0,$zero,$t1	# print process id
	li $v0, 1
	syscall
	la $a0, post_txt	# print closing bracket 
	li $v0, 4
	syscall	
	add $a0,$zero,$t0	# print counter
	li $v0, 1
	syscall
	la $a0, newline		# print a newline
	li $v0, 4
	syscall
	addi $t0, $t0, 1	# increment counter 
	b p1_loop		# run again

p2:	
	li $v0, 102		# get process id and store in $t1
	syscall
	add $t1, $zero, $v0
	li $t0, 1000		# $t0 as loop counter, start at 0
p2_loop:	
	la $a0, pre_txt		# print preamble text
	li $v0, 4
	syscall	
	add $a0,$zero,$t1	# print process id
	li $v0, 1
	syscall
	la $a0, post_txt	# print closing bracket 
	li $v0, 4
	syscall	
	add $a0,$zero,$t0	# print counter
	li $v0, 1
	syscall
	la $a0, newline		# print a newline
	li $v0, 4
	syscall
	addi $t0, $t0, 5	# increment counter 
	b p2_loop		# run again

	
.kdata
pcb:	.word  0 : 35 		# each Process Control Block (PCB) has PC, a0, v0, t0, t1, Priority, Number of Quanta Already Ran
                      		# we assume we can have room for 5 processes                      
curpcb:	.word 0			# offset to the current PCB (multiple of 28)
				# can be used as process_id too
temp: .word 0			# temporary storage

.ktext	0x80000180
	mfc0 $k0, $13           # move cause from coproc0 reg $13 to $k0
	srl $k0, $k0, 2         # shift right by 2
	andi $k0, $k0, 0x1f	# cause is encoded in 5 bit
	beqz $k0, int_hdlr	# cause is hardware interrupt (encoded as 0)
	beq  $k0, 8, sys_hdlr	# cause is a syscall (encoded as 8)
	li $v0, 10		# if it is anything else we terminate (should not happen)
	syscall
	
# Here is the system call handler
sys_hdlr:
	beq $v0, 100, sys_100	# syscall 100 (register a process)
	beq $v0, 101, sys_101	# syscall 101 (start processes)
	beq $v0, 102, sys_102	# syscall 102 (return process id)
	li $v0, 10		# if it is another syscall we terminate (should not happen)
	syscall
	
sys_100: #register a new process with the OS
	li    $k0, 0	  	# loop counter for pcb
s100_next:	
	lw    $k1, pcb + 0($k0) # get PC stored in pcb
	beqz  $k1, s100_alloc   # if pcb entry free, use it
	addiu $k0,$k0,28        # if not free, try next pcb
	bne   $k0,140, s100_next# we can have up to 5 pcb (5 times 28byte)
	li    $v0, 10		# if it is no free pcb we terminate
	syscall
s100_alloc:
	sw    $a0, pcb + 0($k0)	# store PC in pcb (initially, start of process)
	sw    $a1, pcb + 20($k0)	# store priority in pcb
	mfc0  $k0, $14    	# move EPC to $k0
	addiu $k0, $k0, 4 	# skip one instruction, avoid same syscall again
	mtc0  $k0, $14    	# write it back to EPC
	eret			# return to process registering this new process
	
sys_101: #start scheduling of OS processes 
	lw    $k1, pcb 		# load address of first process in pcb
	bnez  $k1, s101_valid	# check if the first one is valid (we need at least one!)
	li    $v0, 10		# if it is no valid pcb we terminate
	syscall
s101_valid: #we have a valid pcb
	mtc0  $k1, $14		# copy start PC of process into EPC
	la    $k0, 0xFFFF0013	# enable clock of Digial Lab Sim
	li    $k1, 1
	sb    $k1, ($k0)
	eret			# switch to the process now in EPC
	 	
sys_102: #return process id
	lw    $k0, curpcb 	# load current pcb offset
	add   $v0, $zero, $k0   # copy current pcb (process id) to $v0
	mfc0  $k0, $14    	# move EPC to $k0
	addiu $k0, $k0, 4 	# skip one instruction, avoid same syscall again
	mtc0  $k0, $14    	# write it back to EPC
	eret			# return to process registering this new process

int_hdlr: #clock used to switch to next process (we do not check exact interrupt)
        #save the current process state in pcb
	lw    $k1, curpcb   	# load the offest to current pcb (in multiples of 28)
	la    $k0, pcb	 	# load start address of the pcb array
	add   $k0, $k0, $k1 	# get address of the current active pcb
	sw    $k0, temp		# store address of the current active pcb in temp
	
	lw    $k1, 24($k0)	# load the quanta number of the current process (this number has not yet been incremented, so it is actually 1 less than the number of quanta already ran)
	lw    $k0, 20($k0)	# load the priority of the current process
	beq   $k1, $k0, int_switch	#if the current process has ran for its allocated number of quanta, switch to a new process
	addi  $k1, $k1, 1	# increment the quanta number of the current process
	lw    $k0, temp		# load address of the current active pcb again
	sw    $k1, 24($k0)	# update the quanta number of the current process
	eret			# return to the current process as it can run again
		
int_switch:	#switch to a new process as the current process has ran for its allocated number of quanta
	lw    $k0, temp		# load address of the current active pcb again
	sw    $zero, 24($k0)	# reset the quanta number of the current process

	mfc0  $k1, $14     	# get the current program counter
	sw    $k1, 0($k0)  	# save program counter so process can resume later
	sw    $a0, 4($k0)  	# save all other relevant process state in pcb
	sw    $v0, 8($k0)
	sw    $t0, 12($k0)
	sw    $t1, 16($k0)	
	#load the next process state from pcb
	lw    $k0, curpcb 	# load current pcb offset
int_next:
	addiu $k0, $k0, 28	# add 28 to get to next pcb
	blt   $k0, 140, int_skip# go to 0 if we wrap around the pcb array
	addu  $k0, $zero, $zero
int_skip:
	lw    $k1, pcb + 0($k0) # get the stored PC from the next pcb
	bnez  $k1, int_restore  # if that PC is not 0 we can switch to this process
	b     int_next 		# go back and fetch the next pcb, this one was invalid
int_restore:
        sw    $k0, curpcb	# save the offset for the pcb we switch to
        lw    $k1, pcb + 0($k0) # load PC from that pcb
        mtc0  $k1, $14		# put PC in EPC
        lw    $a0, pcb + 4($k0) # restore all registers (restore process state)
        lw    $v0, pcb + 8($k0)
        lw    $t0, pcb + 12($k0)
        lw    $t1, pcb + 16($k0)
	eret			# continue execution of the stored process

