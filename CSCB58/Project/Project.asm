#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Name, Kevin Zhang, zhan9820, kwei.zhang@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health/score
# 2. Fail condition
# 3. Win condition
# 4. Moving objects
# 5. Different levels
# 6. Shoot enemies(Eat enemies)
# 7. Gimmicks and features(Potion shop)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - https://youtu.be/X7AKf808e0Q
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################
.eqv	DISPLAY_FIRST_ADDRESS	0x10008000
.eqv	DISPLAY_LAST_ADDRESS	0x1000FFFC
.eqv	CHARA_SPAWN_ADDRESS	0x1000DE00
.eqv	FLOOR_ADDRESS_1		0x1000A860
.eqv	FLOOR_ADDRESS_2		0x1000D040
.eqv	FLOOR_ADDRESS_3		0x1000F800

.eqv	CHARA_IN_1_LEVEL	0x10008E00
.eqv	CHARA_IN_2_LEVEL	0x1000B600
.eqv	CHARA_IN_3_LEVEL	0x1000DE00
.eqv	CHARA_IN_3_LEVEL_END	0x1000DFC0

.eqv	ITEM_IN_1_LEVEL		0x100099E8
.eqv	ITEM_IN_2_LEVEL		0x1000C1E8
.eqv	ITEM_IN_3_LEVEL		0x1000E9E8

.eqv	ITEM_CLEAR_IN_1_LEVEL	0x10009800
.eqv	ITEM_CLEAR_IN_2_LEVEL	0x1000C000
.eqv	ITEM_CLEAR_IN_3_LEVEL	0x1000E800
.eqv	HEART_1			0x10008200
.eqv	HEART_2			0x10008224
.eqv	HEART_3			0x10008248
.eqv	HEART_END_ADDRESS	0x10008E00
.eqv 	POTION_ADDRESS		0x100080C8

.eqv	SHIFT_NEXT_ROW		512

.eqv	ITEM_WEIGTH		6
.eqv	ITEM_HEIGHT		8
.eqv	CHAR_LEN		13


.eqv	COLOUR_BACKGROUND	0x00C0C0C0
.eqv	COLOUR_CHAR_1		0x00000000
.eqv	COLOUR_CHAR_2		0x00FFFF00
.eqv	COLOUR_CHAR_3		0x00FFFFFF
.eqv	COLOUR_FLOOR		0x00336600
.eqv	COLOUR_MONSTER_1	0x00990099
.eqv	COLOUR_MONSTER_2	0x003333FF
.eqv	COLOUR_HEALTH		0x00FF0000
.eqv 	COLOUR_POTION		0x10006600

.data

coins:		.space			44					# 10 * 4 coin address + 4 current generated coin
monsters:	.space			44					# 10 * 4 monster address + 4 current generated monster
health:		.space			24					# 5 * 4 health address + 4 current generated health


.text

#---------------------
# $s2: char_point
# $s3: char_address
# $s4: char_health
# $a3: stage_number
# $t7: char_mouse
.globl main
main:
	jal	Clear				# Clear all pixels
	li	$a3, 1
	jal	Draw_stage			# Draw current stage number
	
	li	$t0, COLOUR_FLOOR
	li	$a0, FLOOR_ADDRESS_1
	addi	$a1, $a0, 200
	jal	Draw_Floor
	li	$a0, FLOOR_ADDRESS_2
	addi	$a1, $a0, 360
	jal	Draw_Floor
	li	$a0, FLOOR_ADDRESS_3
	addi	$a1, $a0, 2044
	jal	Draw_Floor
	jal	Draw_shop
	li	$a0, POTION_ADDRESS
	addi	$a0, $a0, 48
	jal	Draw_coins			# Initialize floors and shop
	
	li	$a0, HEART_1
	jal	Draw_heart
	li	$a0, HEART_2
	jal	Draw_heart
	li	$a0, HEART_3
	jal	Draw_heart
	jal	Clear_heart
	jal	Draw_all_heart			# Initialize heart
	
	la 	$s5, coins
	la 	$s6, monsters
	la 	$s7, health
	li 	$t0, 0
	sw 	$t0, 40($s5)
	sw 	$t0, 40($s6)
	sw 	$t0, 20($s7)			# Initialize number of coins, monsters and health
	
	li	$s3, CHARA_SPAWN_ADDRESS
	li	$s2, 0
	li	$s4, 3
	li	$t7, 1				# Initialize points, lifes, character status
	
	
	addi	$s3, $s3, 20
	move	$a0, $s3
	li	$a1, 0
	jal	Draw_char			# Initialize Character
	
	li	$s0, 0
	li	$s1, 400
main_loop:
	beq	$s0, $s1, Win			# Check winning condition
	
	beq	$a3, 1, generate_1		# First stage, generate item
	beq	$a3, 2, generate_2		# Second stage, generate item
	beq	$a3, 3, generate_3		# Third stage, generate item
	
generate_1:
	rem 	$t0, $s0, 30			# Generate item if iteration number is divisible by 30
	bne 	$t0, $zero, continue_loop	# Otherwise, continue
	jal	Generate_item
	j	continue_loop
	
generate_2:
	rem 	$t0, $s0, 15			# Generate item if iteration number is divisible by 15
	bne 	$t0, $zero, continue_loop	# Otherwise, continue
	jal	Generate_item
	j	continue_loop
	
generate_3:
	rem 	$t0, $s0, 10			# Generate item if iteration number is divisible by 10
	bne 	$t0, $zero, continue_loop	# Otherwise, continue
	jal	Generate_item
	j	continue_loop
	
continue_loop:
	# Move all items
	jal	Move_all_coins			# Move all coins 1 pixel
	jal	Move_all_monsters		# Move all monsters 1 pixel
	jal	Move_all_health			# Move all health 1 pixel
	
	jal	Clear_char
	jal	Check_player_fall
	add	$s3, $s3, $t0
	# Move player
	#addi	$s3, $s3, -512
	
	li	$a1, 0xffff0000
	lw	$t9, 0($a1)
	jal	Create_link
Create_link:
	beq	$t9, 1, Key_press		# If keypress happened, jump to key_press
	move	$a0, $s3			# Renew Character address
	jal	Draw_char			# Redraw the character
	
	
	# Check collide, between character and item
	li	$a1, 0xffff0000
	lw	$t9, 0($a1)
	addi	$t8, $s3, 2560
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	addi	$t8, $t8, 4
	jal	Check_collide
	
	
	# Renew heart
	jal	Clear_heart
	jal	Draw_all_heart
	
	#Check lose condition
	beq	$s4, 0, Lose
	
	li 	$v0, 32		 # syscall code for sleep function
	li 	$a0, 200	 # sleep for 0.2 seconds
	syscall			 # call the sleep function
	
	
	#li 	$v0, 1
	#move	$a0, $s0
	#syscall
	
	addi	$s0, $s0, 1
	
	# Check stage and change stage
	beq	$s2, 3, Change_Stage
	beq	$s2, 9, Change_Stage
	beq	$s2, 19, Win	# If player collect all coins
	
	j	main_loop

	
Change_Stage:
	# Clear and print stage
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	Clear
	addi	$a3, $a3, 1
	jal	Draw_stage
	# Redraw the floors and shop
	li	$t0, COLOUR_FLOOR
	li	$a0, FLOOR_ADDRESS_1
	addi	$a1, $a0, 200
	jal	Draw_Floor
	li	$a0, FLOOR_ADDRESS_2
	addi	$a1, $a0, 360
	jal	Draw_Floor
	li	$a0, FLOOR_ADDRESS_3
	addi	$a1, $a0, 2044
	jal	Draw_Floor
	jal	Draw_shop
	li	$a0, POTION_ADDRESS
	addi	$a0, $a0, 48
	jal	Draw_coins
	
	# Clear all items
	la 	$s5, coins
	la 	$s6, monsters
	la 	$s7, health
	li 	$t0, 0
	sw 	$t0, 40($s5)
	sw 	$t0, 40($s6)
	sw 	$t0, 20($s7)
	
	# add 1 to stage number
	addi	$s2, $s2, 1
	j	main_loop
	
main_end:
	li	$v0, 10		# $v0 = 10 terminate the program
	syscall
	


#--------------------------------------------------------------------------------------------------------
Check_player_fall:
	div	$t0, $s3, 512
	mflo 	$t0
	beq	$t0, 524399, Not_falling
	mfhi 	$t0
	
	bgt	$s3, CHARA_IN_2_LEVEL, Second_check
	# 1st level check
	blt	$t0, 60, Falling
	bgt	$t0, 280, Falling
	j	Not_falling
	
Second_check:
	blt	$t0, 32, Falling
	bgt	$t0, 420, Falling
	j	Not_falling

Falling:
	li	$t0, 1024
	j	Check_fall_done
Not_falling:
	li	$t0, 0
	j	Check_fall_done
Check_fall_done:
	jr	$ra

Lose:
	# Clear and Draw lose
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW
	jal	Clear
	jal	Draw_you
	jal	Draw_lose
	j	main_end
	
Win:	
	# Clear and Draw win
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW
	jal	Clear
	jal	Draw_you
	jal	Draw_win
	j	main_end
	
#--------------------------------------------------------------------------------------------------------
# Check_collide($t8: check point)
# used register: $t0, $t4, $t5, $t6
Check_collide:
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)		# Store current $ra to jump back
	jal	Check_collide_coins	# Check collide with coins
	jal	Check_collide_monsters	# Check collide with monsters
	jal	Check_collide_health	# Check collide with health
	j	Check_collide_end	# Finish checking
	
Check_collide_coins:
	li 	$t4, 0			# t4 = 0
	lw	$t5, 40($s5)		# t5 = coin number
	la	$t6, 0($s5)		# t6 = coin address
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)		# Store current $ra to jump back
Check_collide_coins_loop:
	# loop through all coins
	beq	$t4, $t5, Check_collide_coins_end
	lw	$t0, 0($t6)
	beq	$t0, $t8, Collide_coins	# if address are same, go collide
	
	addi 	$t4, $t4, 1 		# Increment the counter
   	addi	$t6, $t6, 4		# Increment the memory location by 4 bytes
   	j	Check_collide_coins_loop
	
Collide_coins:
	lw	$a0, 0($t6)
	jal	Clear_item
	li	$t0, ITEM_CLEAR_IN_1_LEVEL		# Clear item and stop from reprint
	addi	$t0, $t0, 4
	sw	$t0, 0($t6)
	addi 	$t4, $t4, 1 				# Increment the counter
   	addi	$t6, $t6, 4 				# Increment the memory location by 4 bytes
   	beq	$t7, 0, Check_collide_coins_loop	# if character is close mouth
   	addi	$s2, $s2, 1
   	j	Check_collide_coins_loop
Check_collide_coins_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra			# Load $ra and jump back

	
Check_collide_monsters:
	li 	$t4, 0			# t4 = 0
	lw	$t5, 40($s6)		# t5 = monster number
	la	$t6, 0($s6)		# t6 = monster address
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)		# Store current $ra to jump back
Check_collide_monsters_loop:
	# loop through all monsters
	beq	$t4, $t5, Check_collide_monsters_end
	lw	$t0, 0($t6)
	beq	$t0, $t8, Collide_monsters
	
	addi 	$t4, $t4, 1 		# Increment the counter
   	addi	$t6, $t6, 4 		# Increment the memory location by 4 bytes
   	j	Check_collide_monsters_loop
	
Collide_monsters:
	lw	$a0, 0($t6)
	jal	Clear_item
	li	$t0, ITEM_CLEAR_IN_1_LEVEL		# Clear item and stop from reprint
	addi	$t0, $t0, 4
	sw	$t0, 0($t6)
	addi 	$t4, $t4, 1 				# Increment the counter
   	addi	$t6, $t6, 4 				# Increment the memory location by 4 bytes
   	beq	$t7, 0, Check_collide_monsters_loop	# if character is close mouth
   	addi	$s4, $s4, -1
   	
   	j	Check_collide_monsters_loop
Check_collide_monsters_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra			# Load $ra and jump back
			
				
Check_collide_health:
	li 	$t4, 0
	lw	$t5, 20($s7)
	la	$t6, 0($s7)
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)
Check_collide_health_loop:
	beq	$t4, $t5, Check_collide_health_end
	lw	$t0, 0($t6)
	beq	$t0, $t8, Collide_health
	
	addi 	$t4, $t4, 1
   	addi	$t6, $t6, 4
   	j	Check_collide_health_loop
	
Collide_health:
	lw	$a0, 0($t6)
	jal	Clear_item
	li	$t0, ITEM_CLEAR_IN_1_LEVEL
	addi	$t0, $t0, 4
	sw	$t0, 0($t6)
	addi 	$t4, $t4, 1
   	addi	$t6, $t6, 4
   	
   	bgt	$s4, 2, Check_collide_health_loop
   	addi	$s4, $s4, 1
   	j	Check_collide_health_loop
Check_collide_health_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra	
	
Check_collide_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra
#--------------------------------------------------------------------------------------------------------								
# $a0: 0xffff0000, $t9: variable
Key_press:
	li	$t4, CHARA_IN_1_LEVEL
	li	$t5, CHARA_IN_2_LEVEL
	li	$t6, CHARA_IN_3_LEVEL
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	lw	$t9, 4($a1)
	bne	$t0, 0, Key_press_done

	beq	$t9, 0x61, key_a			# ASCII code of 'a' is 0x61
	beq	$t9, 0x77, key_w			# ASCII code of 'w' is 0x77
	beq	$t9, 0x64, key_d			# ASCII code of 'd' is 0x64
	#beq	$t9, 0x73, key_s			# ASCII code of 's' is 0x73
	beq	$t9, 0x65, key_e			# ASCII code of 'e' is 0x65
	beq	$t9, 0x72, key_r			# ASCII code of 'r' is 0x72
	beq	$t9, 0x70, key_p			# ASCII code of 'p' is 0x70
key_a:
	# If character is at edge of map
	beq	$s3, $t4, Key_press_done		
	beq	$s3, $t5, Key_press_done
	beq	$s3, $t6, Key_press_done
	# Else move character
	addi	$s3, $s3, -20
	j	Key_press_done
key_d:	
	bgt	$s3, CHARA_IN_3_LEVEL_END, Key_press_done
	addi	$s3, $s3, 20
	j	Key_press_done
key_w:
	# If character is at edge of map
	li	$t9, CHARA_IN_2_LEVEL
	blt	$s3, $t9, Key_press_done
	# Else move character
	addi	$s3, $s3, -10240
	j	Key_press_done
#key_s:
	# If character is at edge of map
	#li	$t9, CHARA_IN_3_LEVEL
	#bgt	$s3, $t9, Key_press_done
	# Else move character
	#addi	$s3, $s3, 10240
	#j	Key_press_done
key_e:	
	# Open/Close move for character
	beq	$t7, 1, close_mouth
	addi	$t7, $t7, 1
	j	Key_press_done
	close_mouth:
		addi	$t7, $t7, -1
		j	Key_press_done
key_r:
	# Use shop to clear monster
	bgt	$s2, 2, Clear_monsters
	j	Key_press_done
key_p:		
	# Restart the game	
	la	$ra, main
	jr	$ra
Key_press_done:
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr 	$ra		# Load $ra and jump back

						
Clear_monsters:
	# Similar to collide, but remove all monsters
	li 	$t4, 0
	lw	$t5, 40($s6)
	la	$t6, 0($s6)
Clear_monsters_loop:
	beq	$t4, $t5, Clear_monsters_end
	
	lw 	$t0, 0($t6)
	addi 	$t0, $t0, -8
	sw 	$t0, 0($t6)
	
    	lw 	$a0, ($t6)
    	jal	Clear_item
    	li	$t0, ITEM_CLEAR_IN_1_LEVEL
    	addi	$t0, $t0, 4
	sw	$t0, 0($t6)

	addi 	$t4, $t4, 1
   	addi	$t6, $t6, 4
    	j 	Clear_monsters_loop
Clear_monsters_end:
	j	Key_press_done

#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
# GENERATING FUNCTIONS
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
# Generate_item()
# used register: t0, t2, t3
Generate_item:	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li	$t3, 0
Generate_item_loop:
	beq	$t3, 3, Generate_item_done
	
	# Ramdomly choose from 1 t0 4
	li 	$v0, 42
	li 	$a0, 1          
	li 	$a1, 4         
	syscall
	
	# Level to generate
	move	$t0, $a0
	li	$a0, ITEM_IN_1_LEVEL
	mul	$t2, $t3, 10240
	add	$a0, $a0, $t2
	
	#li	$t0, 0
	
	#If randomly choose 0, do generate coin
	beq	$t0, 0, Generate_coin
	#If randomly choose 1, do generate monster
	beq	$t0, 1, Generate_monster
	#If randomly choose 2, do generate health
	beq	$t0, 2, Generate_health
	#If randomly choose 3, do not generate
	beq	$t0, 3, Generate_nothing
	
Generate_coin:
	# If generate too many coin, generate monster instead
	lw 	$t0, 40($s5)
	beq	$t0, 9, Generate_monster
	# Create a address space for the new coin
	mul	$t0, $t0, 4
	add 	$t0, $s5, $t0
	sw 	$a0, 0($t0)
	lw 	$t0, 40($s5)
	addi 	$t0, $t0, 1
	sw 	$t0, 40($s5)
	# Draw the coin
	jal	Draw_coins
	addi	$t3, $t3, 1
	j	Generate_item_loop
Generate_monster:
	# If generate too many monster, generate health instead
	lw 	$t0, 40($s6)
	beq	$t0, 9, Generate_health
	# Create a address space for the new monster
	mul	$t0, $t0, 4
	add 	$t0, $s6, $t0
	sw 	$a0, 0($t0)
	lw 	$t0, 40($s6)
	addi 	$t0, $t0, 1
	sw 	$t0, 40($s6)
	# Draw the monster
	jal	Draw_monsters
	addi	$t3, $t3, 1
	j	Generate_item_loop
Generate_health:
	# If generate too many health, generate nothing instead
	lw 	$t0, 20($s7)
	beq	$t0, 4, Generate_item_done
	# Create a address space for the new health
	mul	$t0, $t0, 4
	add 	$t0, $s7, $t0
	sw 	$a0, 0($t0)
	lw 	$t0, 20($s7)
	addi 	$t0, $t0, 1
	sw 	$t0, 20($s7)
	# Draw the health
	jal	Draw_health
	addi	$t3, $t3, 1
	j	Generate_item_loop
Generate_nothing:
	addi	$t3, $t3, 1
	j	Generate_item_loop

Generate_item_done:
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra		# Load $ra and jump back


#--------------------------------------------------------------------------------------------------------
# Move_Item($a0: Address of item)
#

Move_coins:
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)	# Save $ra
	sw	$a0, 4($sp)	# Save $a0

	addi	$a0, $a0, 4
	jal 	Clear_item	# Clear the item first
	
	lw 	$a0, 4($sp)
	addi 	$a0, $a0, -8	# Move the address so that item will move forward
	sw	$a0, 4($sp)
	
	jal	Draw_coins	# Draw the item after movement
	
	lw 	$ra, 0($sp)
	lw	$a0, 4($sp)
	addi 	$sp, $sp, 8
	jr	$ra		# Load $ra and jump back

Move_monsters:
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)	# Save $ra
	sw	$a0, 4($sp)	# Save $a0
	
	addi	$a0, $a0, 4
	jal 	Clear_item	# Clear the item first
	
	lw 	$a0, 4($sp)
	addi 	$a0, $a0, -8	# Move the address so that item will move forward
	sw	$a0, 4($sp)
	
	jal	Draw_monsters	# Draw the item after movement
	
	lw 	$ra, 0($sp)
	lw	$a0, 4($sp)
	addi 	$sp, $sp, 8
	jr	$ra		# Load $ra and jump back
	
Move_health:
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)	# Save $ra
	sw	$a0, 4($sp)	# Save $a0
	
	addi	$a0, $a0, 4
	jal 	Clear_item	# Clear the item first
	
	lw 	$a0, 4($sp)
	addi 	$a0, $a0, -8	# Move the address so that item will move forward
	sw	$a0, 4($sp)
	
	jal	Draw_health	# Draw the item after movement
	
	lw 	$ra, 0($sp)
	lw	$a0, 4($sp)
	addi 	$sp, $sp, 8
	jr	$ra		# Load $ra and jump back
	
#--------------------------------------------------------------------------------------------------------
#

Move_all_coins:
	li 	$t4, 0
	lw	$t5, 40($s5)
	la	$t6, 0($s5)
	#	Load coin data to $t4, $t5, $t6
	
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)

Move_all_coins_loop:
	# Loop through all existing coins
	beq	$t4, $t5, Move_all_coins_end
	
	# Renew and laod new address to $a0
	lw 	$t0, 0($t6)
	addi 	$t0, $t0, -4
	sw 	$t0, 0($t6)
    	lw 	$a0, ($t6)
    	
    	# if the item is in garbage address
    	li	$t0, ITEM_CLEAR_IN_1_LEVEL
    	beq	$a0, $t0, Move_coins_clear
    	li	$t0, ITEM_CLEAR_IN_2_LEVEL
    	beq	$a0, $t0, Move_coins_clear
    	li	$t0, ITEM_CLEAR_IN_3_LEVEL
    	beq	$a0, $t0, Move_coins_clear
    	
    	# Draw new coin
    	jal	Move_coins
	addi 	$t4, $t4, 1 # Increment the counter
   	addi	$t6, $t6, 4 # Increment the memory location by 4 bytes
    	j 	Move_all_coins_loop

Move_coins_clear:
	lw 	$t0, 0($t6)
	addi 	$t0, $t0, 4
	sw 	$t0, 0($t6)
	jal	Clear_item
	addi 	$t4, $t4, 1 # Increment the counter
   	addi	$t6, $t6, 4 # Increment the memory location by 4 bytes
    	j 	Move_all_coins_loop


Move_all_coins_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra	# Load $ra and jump back
	
#--------------------------------------------------------------------------------------------------------
	
Move_all_monsters:
	li 	$t4, 0
	lw	$t5, 40($s6)
	la	$t6, 0($s6)
	#	Load monster data to $t4, $t5, $t6
	
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)

Move_all_monsters_loop:
	# Loop through all existing monsters
	beq	$t4, $t5, Move_all_monsters_end
	
	# Renew and laod new address to $a0
	lw $t0, 0($t6)
	addi $t0, $t0, -4
	sw $t0, 0($t6)
    	lw 	$a0, ($t6)
    	
    	# if the item is in garbage address
    	li	$t0, ITEM_CLEAR_IN_1_LEVEL
    	beq	$a0, $t0, Move_monsters_clear
    	li	$t0, ITEM_CLEAR_IN_2_LEVEL
    	beq	$a0, $t0, Move_monsters_clear
    	li	$t0, ITEM_CLEAR_IN_3_LEVEL
    	beq	$a0, $t0, Move_monsters_clear
    	
    	# Draw new monster
    	jal	Move_monsters
	addi 	$t4, $t4, 1 # Increment the counter
   	addi	$t6, $t6, 4 # Increment the memory location by 4 bytes
    	j 	Move_all_monsters_loop
    	
    	
Move_monsters_clear:
	lw 	$t0, 0($t6)   # Load the value from the memory location specified by $t6 into $t0
	addi 	$t0, $t0, 4  # Subtract 4 from the value in $t0
	sw 	$t0, 0($t6)   # Store the result back into the memory location specified by $t6
	jal	Clear_item
	addi 	$t4, $t4, 1 # Increment the counter
   	addi	$t6, $t6, 4 # Increment the memory location by 4 bytes
    	j 	Move_all_monsters_loop

Move_all_monsters_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra	# Load $ra and jump back
#--------------------------------------------------------------------------------------------------------
Move_all_health:
	li 	$t4, 0
	lw	$t5, 20($s7)
	la	$t6, 0($s7)
	#	Load monster data to $t4, $t5, $t6
	
	addi 	$sp, $sp, -4
	sw	$ra, 0($sp)

Move_all_health_loop:
	# Loop through all existing coins
	beq	$t4, $t5, Move_all_health_end
	
	# Renew and laod new address to $a0
	lw $t0, 0($t6)
	addi $t0, $t0, -4
	sw $t0, 0($t6)
    	lw 	$a0, ($t6)
    	
    	# if the item is in garbage address
    	li	$t0, ITEM_CLEAR_IN_1_LEVEL
    	beq	$a0, $t0, Move_health_clear
    	li	$t0, ITEM_CLEAR_IN_2_LEVEL
    	beq	$a0, $t0, Move_health_clear
    	li	$t0, ITEM_CLEAR_IN_3_LEVEL
    	beq	$a0, $t0, Move_health_clear
    	
    	# Draw new monster
    	jal	Move_health
	addi 	$t4, $t4, 1 # Increment the counter
   	addi	$t6, $t6, 4 # Increment the memory location by 4 bytes
    	j 	Move_all_health_loop
    	
Move_health_clear:
	lw 	$t0, 0($t6)   # Load the value from the memory location specified by $t6 into $t0
	addi 	$t0, $t0, 4  # Subtract 4 from the value in $t0
	sw 	$t0, 0($t6)   # Store the result back into the memory location specified by $t6
	jal	Clear_item
	addi 	$t4, $t4, 1 # Increment the counter
   	addi	$t6, $t6, 4 # Increment the memory location by 4 bytes
    	j 	Move_all_health_loop

Move_all_health_end:
	lw	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr	$ra	# Load $ra and jump back
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
# CLEANING FUNCTIONS
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------



#--------------------------------------------------------------------------------------------------------
# Clear(a0: start address, a1: end address, a2: next row distance)
#	used register: t0, t1
Clear:
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, DISPLAY_LAST_ADDRESS
	li	$a2, -SHIFT_NEXT_ROW
	li	$t0, COLOUR_BACKGROUND
	li	$t1, 0
	
Clear_loop:
	bgt	$a0, $a1, Clear_loop_done
	beq	$t1, $a2, Clear_loop_next_row
	# Set color to background and load $a0 to next pixel address
	sw	$t0, 0($a0)
	addi	$a0, $a0, 4
	addi	$t1, $t1, -4
	j	Clear_loop
Clear_loop_next_row:
	# Reach end of current line, jump to next
	add	$a0, $a0, $t1
	addi	$a0, $a0, SHIFT_NEXT_ROW
	li	$t1, 0	
	j 	Clear_loop
Clear_loop_done:
	jr	$ra	# jump back
		

		
#--------------------------------------------------------------------------------------------------------
# Clear Item(a0: start address)
#	used register: t0, t1, t2
Clear_item:
	li	$t0, COLOUR_BACKGROUND
	li	$t1, ITEM_HEIGHT
	li	$t2, ITEM_WEIGTH
Clear_item_loop:
	blez	$t1, Clear_item_loop_done
	blez	$t2, Clear_item_loop_next_row
	# Set color to background and load $a0 to next pixel address
	sw	$t0, 0($a0)
	addi	$a0, $a0, 4
	addi	$t2, $t2, -1
	j	Clear_item_loop
		
Clear_item_loop_next_row:
	# Reach end of current item, jump to next line
	addi	$a0, $a0, -24
	addi	$a0, $a0, 512
	addi	$t1, $t1, -1
	li	$t2, ITEM_WEIGTH
	j	Clear_item_loop
Clear_item_loop_done:	
	jr	$ra
		
#--------------------------------------------------------------------------------------------------------
# Clear char($s3: start address)
Clear_char:
	li	$t0, COLOUR_BACKGROUND
	li	$t1, CHAR_LEN
	li	$t2, CHAR_LEN
	addi	$sp, $sp, -4
	sw	$s3, 0($sp)
Clear_char_loop:
	blez	$t1, Clear_char_loop_done
	blez	$t2, Clear_char_loop_next_row
	# Set color to background and load $a0 to next pixel address
	sw	$t0, 0($s3)
	addi	$s3, $s3, 4
	addi	$t2, $t2, -1
	j	Clear_char_loop
	
Clear_char_loop_next_row:
	# Reach end of character, jump to next line
	addi	$s3, $s3, -52
	addi	$s3, $s3, 512
	addi	$t1, $t1, -1
	li	$t2, CHAR_LEN
	j	Clear_char_loop
Clear_char_loop_done:	
	lw	$s3, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
#--------------------------------------------------------------------------------------------------------	
# Clear(a0: start address, a1: end address, a2: next row distance)
#	used register: t0, t1
Clear_heart:
	li	$a0, DISPLAY_FIRST_ADDRESS
	li	$a1, HEART_END_ADDRESS
	li	$a2, -120
	li	$t0, COLOUR_BACKGROUND
	li	$t1, 0
Clear_heart_loop:
	bgt	$a0, $a1, Clear_heart_loop_done
	beq	$t1, $a2, Clear_heart_loop_next_row
	sw	$t0, 0($a0)						# clear $a0 colour
	addi	$a0, $a0, 4						# $a0 = $a0 + 4
	addi	$t1, $t1, -4						# $t1 = $t1 - 4
	j	Clear_heart_loop						# jump to clear_loop
Clear_heart_loop_next_row:
	add	$a0, $a0, $t1						# $a0 = $a0 - width*4
	addi	$a0, $a0, SHIFT_NEXT_ROW				# set $a0 to next row
	li	$t1, 0							# reset increment $t1 = 0
	j 	Clear_heart_loop
Clear_heart_loop_done:
	jr	$ra							# jump to $ra
	

#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
# DRAWING FUNCTIONS
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

Draw_all_heart:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	blt	$s4, 1, Draw_heart_done
	li	$a0, HEART_1
	jal	Draw_heart
	blt	$s4, 2, Draw_heart_done
	li	$a0, HEART_2
	jal	Draw_heart
	blt	$s4, 3, Draw_heart_done
	li	$a0, HEART_3
	jal	Draw_heart
Draw_heart_done:
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
#--------------------------------------------------------------------------------------------------------
# Draw_Floor($a0: level of floor)
#	
Draw_Floor:
	bgt	$a0, $a1, Draw_Floor_done
	sw	$t0, 0($a0)
	addi	$a0, $a0, 4
	j	Draw_Floor
Draw_Floor_done:
	jr	$ra

Draw_Floor_2:
	bgt	$a0, $a1, Draw_Floor_done

#--------------------------------------------------------------------------------------------------------
# Draw_monster($a0: start address)
#
#	used register: t0, t1, t2
Draw_monsters:
	li	$t0, COLOUR_MONSTER_1
	li	$t1, COLOUR_MONSTER_2
	li	$t2, COLOUR_CHAR_3
	
	
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t2, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t2, 16($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 20($a0)
	
	jr	$ra

	
#--------------------------------------------------------------------------------------------------------
# Draw_health($a0: start address)
#	
#	used register: t0, t1	
Draw_health:
	li	$t0, COLOUR_HEALTH
	li	$t1, COLOUR_CHAR_1
	
	
	sw	$t1, 0($a0)
	sw	$t1, 4($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	jr	$ra		
#--------------------------------------------------------------------------------------------------------
# Draw_coin($a0: start address)
#
#	used register: t0, t1, t2

Draw_coins:
	li	$t0, COLOUR_CHAR_1
	li	$t1, COLOUR_CHAR_2
	li	$t2, COLOUR_CHAR_3
	
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 16($a0)
	sw	$t1, 12($a0)
	sw	$t2, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 20($a0)
	sw	$t2, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 20($a0)
	sw	$t2, 4($a0)
	sw	$t1, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 20($a0)
	sw	$t2, 4($a0)
	sw	$t1, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 20($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 16($a0)
	sw	$t1, 12($a0)
	sw	$t1, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	
	jr	$ra
#--------------------------------------------------------------------------------------------------------
Draw_heart:
	li	$t0, COLOUR_HEALTH
	sw	$t0, 4($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 12($a0)
	
	jr	$ra
#--------------------------------------------------------------------------------------------------------
# Draw_char($a0: start address, $t7: chara_status) --$t7 = 0 means close mouth
#                                                  --$t7 = 1 means open mouth
#	used register: t0, t1, t2
Draw_char:
	li	$t0, COLOUR_CHAR_1
	li	$t1, COLOUR_CHAR_2
	li	$t2, COLOUR_CHAR_3
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	jal	Draw_char_top
	
	sw	$t0, 4($a0)
	sw	$t0, 24($a0)
	sw	$t0, 44($a0)
	sw	$t2, 28($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 40($a0)
	
	addi	$a0, $a0, 512
	
	sw	$t0, 4($a0)
	sw	$t0, 24($a0)
	sw	$t0, 28($a0)
	sw	$t0, 44($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 40($a0)
	
	addi	$a0, $a0, 512
	
	beq	$t7, 0, Char_status_0
	

	#Status 1
	sw	$t0, 0($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	
	addi	$a0, $a0, 512
	
	sw	$t0, 0($a0)
	sw	$t0, 28($a0)
	sw	$t0, 32($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	
	addi	$a0, $a0, 512
	
	sw	$t0, 0($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	
	addi	$a0, $a0, 512
	
	j	Draw_char_end
	
Char_status_0:
	#Status 0
	sw	$t0, 0($a0)
	sw	$t0, 48($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 40($a0)
	sw	$t1, 44($a0)
	
	addi	$a0, $a0, 512
	
	sw	$t0, 0($a0)
	sw	$t0, 36($a0)
	sw	$t0, 44($a0)
	sw	$t0, 48($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 40($a0)
	
	addi	$a0, $a0, 512
	
	sw	$t0, 0($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 36($a0)
	sw	$t1, 44($a0)
	
	addi	$a0, $a0, 512
	j	Draw_char_end

Draw_char_top:
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 28($a0)
	addi	$a0, $a0, 512
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	jr	$ra
	
Draw_char_bot:
	sw	$t0, 4($a0)
	sw	$t0, 44($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 44($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	sw	$t1, 20($a0)
	sw	$t1, 24($a0)
	sw	$t1, 28($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	addi	$a0, $a0, 512
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 28($a0)
	addi	$a0, $a0, 512
	jr	$ra

Draw_char_end:
	jal	Draw_char_bot
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

#--------------------------------------------------------------------------------------------------------
Draw_stage:
	li	$a0, 0x10008000
	li	$t0, 0x00000000
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 52($a0)
	sw	$t0, 56($a0)
	sw	$t0, 64($a0)
	sw	$t0, 68($a0)
	sw	$t0, 72($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 20($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 64($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 20($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 56($a0)
	sw	$t0, 64($a0)
	sw	$t0, 68($a0)
	sw	$t0, 72($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 20($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 56($a0)
	sw	$t0, 64($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 20($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 52($a0)
	sw	$t0, 56($a0)
	sw	$t0, 64($a0)
	sw	$t0, 68($a0)
	sw	$t0, 72($a0)
	
	li	$a0, 0x10008000
	addi	$a0, $a0, 80
	beq	$a3, 1, Draw_stage_1
	beq	$a3, 2, Draw_stage_2
	beq	$a3, 3, Draw_stage_3
	
Draw_stage_1:
	
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	j	Draw_stage_end
	
Draw_stage_2:
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	j	Draw_stage_end

Draw_stage_3:
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 16($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)
	j	Draw_stage_end


Draw_stage_end:
	# Sleep for 2 seconds
	li 	$v0, 32
	li 	$a0, 2000
	syscall
	jr	$ra
#--------------------------------------------------------------------------------------------------------
Draw_you:
	li	$a0, 0x10008000
	li	$t0, 0x00000000
	sw	$t0, 0($a0)	
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)	
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 16($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	jr	$ra
	
Draw_lose:
	li	$a0, 0x10008E00
	li	$t0, 0x00000000
	sw	$t0, 0($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 52($a0)
	sw	$t0, 56($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 16($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 48($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 16($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 52($a0)
	sw	$t0, 56($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 16($a0)
	sw	$t0, 24($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	sw	$t0, 52($a0)
	sw	$t0, 56($a0)
	
	jr	$ra
	
Draw_win:
	li	$a0, 0x10008E00
	li	$t0, 0x00000000
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	sw	$t0, 20($a0)
	sw	$t0, 32($a0)
	sw	$t0, 48($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 20($a0)
	sw	$t0, 32($a0)
	sw	$t0, 36($a0)
	sw	$t0, 40($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 20($a0)
	sw	$t0, 40($a0)
	sw	$t0, 48($a0)
	addi	$a0, $a0, 512
	sw	$t0, 4($a0)
	sw	$t0, 16($a0)
	sw	$t0, 20($a0)
	sw	$t0, 24($a0)
	sw	$t0, 32($a0)
	sw	$t0, 40($a0)
	bgt	$s2, 9, Draw_point_1
	j	Draw_point_2
	
Draw_point_1:
	li	$a0, 0x10008E00
	li	$t0, 0x00000000
	addi	$a0, $a0, 52
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	
	addi	$s2, $s2, -10
	j	Draw_point_2
	
Draw_point_2:
	li	$a0, 0x10008E00
	li	$t0, 0x00000000
	addi	$a0, $a0, 68
	
	beq	$s2, 0, Draw_0
	beq	$s2, 1, Draw_1
	beq	$s2, 2, Draw_2
	beq	$s2, 3, Draw_3
	beq	$s2, 4, Draw_4
	beq	$s2, 5, Draw_5
	beq	$s2, 6, Draw_6
	beq	$s2, 7, Draw_7
	beq	$s2, 8, Draw_8
	beq	$s2, 9, Draw_9
	
Draw_0:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_1:
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_2:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_3:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_4:
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_5:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_6:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_7:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_8:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
Draw_9:
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 8($a0)
	addi	$a0, $a0, 512
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	j	Draw_point_end
	
	
Draw_point_end:
	jr	$ra
	
#--------------------------------------------------------------------------------------------------------
Draw_shop:
	li	$a0, POTION_ADDRESS
	li	$t0, COLOUR_POTION
	li	$t1, COLOUR_CHAR_1
	
	
	sw	$t1, 0($a0)
	sw	$t1, 4($a0)
	sw	$t1, 16($a0)
	sw	$t1, 20($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 92($a0)
	sw	$t1, 96($a0)
	sw	$t1, 100($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 76($a0)
	sw	$t1, 84($a0)
	sw	$t1, 100($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 80($a0)
	sw	$t1, 92($a0)
	sw	$t1, 96($a0)
	sw	$t1, 100($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 28($a0)
	sw	$t1, 32($a0)
	sw	$t1, 36($a0)
	sw	$t1, 76($a0)
	sw	$t1, 84($a0)
	sw	$t1, 100($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t1, 16($a0)
	sw	$t1, 92($a0)
	sw	$t1, 96($a0)
	sw	$t1, 100($a0)
	addi	$a0, $a0, 512
	sw	$t1, 4($a0)
	sw	$t1, 8($a0)
	sw	$t1, 12($a0)
	sw	$t1, 16($a0)
	jr	$ra	
	
