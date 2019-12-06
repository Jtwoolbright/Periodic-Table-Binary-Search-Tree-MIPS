 #
 # 	Code By: 	Josh Woolbright
 # 	Date: 		11/27/2019
 #
 # 	Description:
 # 			This file contains a program to read the periodic
 #			table from a file, create a binary search tree, and
 #			print the table in alphabetical order.
 #

	.data
 title:	.asciiz	"Periodic Table by Josh Woolbright\n"
 ele:	.asciiz " Elements\n"
 line:	.asciiz	"\n"
 file:	.asciiz	""			# insert full file path in ""
 buff:	.space	1
 name:	.space	64
 root:	.word	0
 atno:	.word	0
 count:	.word	0

	.text
 main:
	la	$a0, title		# print title
	li	$v0, 4
	syscall

	la	$a0, line		# print new line
	syscall

	la	$a0, file		# open file
	jal 	open
	move	$s0, $v0		# file handle = $s0
 loop:
	move	$a0, $s0		# a0 = file handle
	li	$a3, 10
	jal	nextint			# read integer from file

	beq	$v1, 1, continue	# if end of file reached, close file
	
	sw	$v0, atno		# store read int into atno
	
	move	$a0, $s0		# a0 = file handle
	la	$a3, name		# a3 = name buffer
	jal 	nextstring		# read string from file

	lw	$a0, atno		# a0 = read int
	la	$a1, name		# a1 = read string
	move	$a2, $v0		# a2 = string length
	jal	create_element		# create an element node

	lw	$a0, root 		# a0 = first node in tree
	move	$a1, $v0		# a1 = element pointer
	jal	insert			# inserts new node into tree

	beq	$v1, 1, continue	# if end of file reached, close file
	addi	$s1, 1			# s1 = number of elements created

	b	loop
 continue:
	move	$a0, $s1		# print number of elements
	li	$v0, 1
	syscall

	la	$a0, ele		# print " Elements"
	li	$v0, 4
	syscall

	la	$a0, line		# print new line
	syscall

	lw	$a0, root		# a0 = first node in tree
	la	$a1, print_element	# a1 = function to print an element
	jal	inorder_traversal	# prints elements in alphabetical order

	move	$a0, $s0		
	b	close			# close file



 	# a0 = atno, a1 = name, a2 = name length
 create_element:
	addi	$sp, -8			# push ra and atno onto stack
	sw	$ra, ($sp)		
	sw	$a0, 4($sp)

	move	$a0, $a1		# a1 = name
	move	$a1, $a2		# a2 = name length
	jal	strdup			# store name on heap
	move	$t0, $v0		# store name pointer in $t0

	li	$a0, 8			# allocate space on heap
	li	$v0, 9
	syscall	

	lw	$a0, 4($sp)		# restore atno
	sw	$a0, ($v0)		# store atno on heap
	sw	$t0, 4($v0)		# store name* on heap
	lw	$ra, ($sp)		# restore ra
	addi	$sp, 8
	jr	$ra			# returns $v0 -> atno address



	# a0 = element ptr
 create_binarynode:
	move	$t0, $a0		# copy element pointer to $t0

	li	$a0, 12			# allocate space on heap
	li	$v0, 9
	syscall

	sw	$t0, ($v0)		# data = element pointer
	sw	$zero, 4($v0)		# left child = 0
	sw	$zero, 8($v0)		# right child = 0
	jr	$ra			# return $v0 -> data



	# a0 = root, a1 = element ptr
 insert:
	addi	$sp, -4
	sw	$ra, ($sp)
	beqz	$s1, setroot		# if firstcall, branch
	lw	$t0, ($a0)		# check if node = 0
	beqz	$t0, setchild		# if yes, branch
	jal	checknode		# check if a0 is a child
	move	$a0, $v0		# a0 = node.element ptr
	jal	strcmp			# check if a1 < a0
	beq	$v0, 1, left		# if yes, branch left
	addi	$a0, 8			# a0 = node.right
	addi	$sp, -4	
	sw	$a0, ($sp)		# push node.right to stack
	jal	insert
	lw	$ra, ($sp)
	addi	$sp, 8
	jr	$ra
 left:
	addi	$a0, 4
	addi	$sp, -4
	sw	$a0, ($sp)		# push node.left to stack
	jal	insert
	lw	$ra, ($sp)
	addi	$sp, 8
	jr	$ra
 setroot:
	move	$a0, $a1		# a0 = element pointer
	jal	create_binarynode	# create a new node
	sw	$v0, root		# store new node into root
	lw	$ra, ($sp)
	addi	$sp, 4
	jr	$ra
 setchild:
	move	$a0, $a1		# a0 = element pointer
	jal	create_binarynode	# create a new node
	lw	$a0, 4($sp)		# pop node address from stack
	sw	$v0, ($a0)		# push new node address to stack
	lw	$ra, ($sp)
	jr	$ra

	# a0 = node
 checknode:
	lw	$t0, ($a0)		# checking if node contains
	lw	$t0, ($t0)		# address to another node
	move	$t1, $t0		# or atno
	addi	$t1, -118
	bltz	$t1, data		# node.data - 118 < 0, atno
	lw	$v0, ($a0)		# else load node element ptr
	jr	$ra			# into $v0 and return
 data:
	move	$v0, $a0		# return node data address
	jr	$ra



	# a0 = node, a1 = print element
 inorder_traversal:
	beqz	$a0, return		# if node is empty, break
	addi	$sp, -8
	sw	$a0, ($sp)		# push node to stack
	sw	$ra, 4($sp)
	lw	$a0, 4($a0)		# a0 = node.left
	jal	inorder_traversal
	lw	$a0, ($sp)		# pop node from stack into a0
	sw	$a0, ($sp)		# push node to stack
	jalr	$a1			# print a0
	lw	$a0, ($sp)		# pop node from stack into a0
	lw	$a0, 8($a0)		# a0 = node.right
	jal	inorder_traversal
	lw	$ra, 4($sp)		
	addi	$sp, 8
 return:
	jr	$ra



	# a0 = node to print
 print_element:	 
	lw	$a0, ($a0)		# a0 = node.element pointer
	lw	$t0, ($a0)		# t0 = atno
	lw	$a0, 4($a0)		# a0 = name
	li	$v0, 4			# print name
	syscall

	li	$a0, ':'		# print ':'
	li	$v0, 11
	syscall

	move	$a0, $t0		# print atno
	li	$v0, 1
	syscall	

	la	$a0, line		# print line
	li	$v0, 4
	syscall

	jr	$ra



	# a0 = name, a1 = name length
 strdup:
	move	$t0, $a0
	addi	$a1, 1
	move	$a0, $a1		# allocate space on heap
	li	$v0, 9
	syscall
	
	move	$t3, $v0		# copy pointer to $t3
 read:
	lb	$t1, ($t0)		# load first character from name
	sb	$t1, ($v0)		# store character into heap
	addi	$t0, 1			# increment name address
	addi	$v0, 1			# increment heap address
	addi	$a1, -1			# decrement length
	bne	$a1, 1, read		# if length != 0, loop read
	move	$v0, $t3
	jr	$ra			# returns starting address in $v0



	# a0 = root, a1 = element ptr
 strcmp: 
	lw	$t0, ($a0)		# t0 = root.atno
	addi	$t0, 4			# t0 = root.name pointer
	lw	$t0, ($t0)		# t0 = root.name
	move	$t1, $a1		# t1 = element.atno
	addi	$t1, 4			# t1 = element.name pointer
	lw	$t1, ($t1)		# t1 = element.name
 while:
	lb	$t2, ($t0)		# load first char of root.name
	beqz	$t2, setzero		# if char = 0, break
	lb	$t3, ($t1)		# load first char of element.name
	beqz	$t3, setone		# if char = 0, break
	sub	$t4, $t2, $t3		# sub char asciiz
	bgtz	$t4, setone		# if sub > 0, root > elem, break
	bltz	$t4, setzero		# if sub < 0, root < elem, break
	addi	$t0, 1			# increment addresses
	addi	$t1, 1
	b	while
 setone:
	li	$v0, 1			# returns 1 if root > elem
	jr	$ra
 setzero:
	li	$v0, 0			# returns 0, if root < elem
	jr	$ra



 open:
	li	$a1, 0			# open file
	li	$a2, 0
	li	$v0, 13
	syscall

	jr	$ra



	# a0 = file handle,  a3 = 10
 nextint:
	li	$t1, 0
 do:
	la	$a1, buff		# read one character from file
	li	$a2, 1
	li	$v0, 14
	syscall

	beqz	$v0, eof		# if no characters read, branch
	lb	$t0, ($a1)		# load read character
	beq	$t0, 10, done		# if character is linefeed, branch
	addi	$t0, -48		# convert character from asciiz
	mul	$t1, $t1, $a3		# into an integer
	add	$t1, $t1, $t0		# store result into $t1
	b 	do
 eof:
	li	$v1, 1			# $v1 = 1 -> end of file error
 done:
	move	$v0, $t1		# move read integer into $v0
	jr	$ra



	# a0 = file handle, a3 = name
 nextstring:
	li	$t1, 0
 next:
	la	$a1, buff		# read one character from file
	li	$a2, 1
	li	$v0, 14
	syscall

	beqz	$v0, eof		# if no characters read, branch
	lb	$t0, ($a1)		# load read character
	beq	$t0, '\n', finish	# if character is new line, branch
	sb	$t0, ($a3)		# store character into strbuf
	addi	$a3, 1			# increment strbuf address
	addi	$t1, 1			# $t1 keeps track of string length
	b 	next
 endof:
	li	$v1, 1			# $v1 = 1 -> end of file error
 finish:
	move	$v0, $t1		# move string length into $v0
	jr	$ra



 close:
	li	$v0, 16			# close file
	syscall

	li	$v0, 10			# end program
	syscall
