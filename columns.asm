################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Qingyi Jiang, 1011554854
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data    
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
WIDTH:  .word 256
HEIGHT: .word 256
CELL:   .word 8

WIDTH_U:  .word 32
HEIGHT_U:  .word 32

COLS:  .word 16
ROWS:  .word 30

# .eqv WIDTH_U 32
# .eqv HEIGHT_U 32


colors:
    .word 0xff0000 # red
    .word 0xffa500 # orange
    .word 0xffff00 # yellow
    .word 0x008000 # green
    .word 0x0000ff # blue
    .word 0x800080 # purple
    
GREY:  .word 0x00333333

EMPTY:  .word -1  # Special value for "empty cell" in the grid.

##############################################################################
# Dynamic State (runtime-updated)
##############################################################################
# Grid position(in cell, not ixel) for the top block of the falling column
cur_x:  .word 8
cur_y: .word 2
cur_colors:
    .word 0
    .word 0
    .word 0

grid:   .space 4096

# Match flags: same size as grid.
#   0 = not part of any match
#   1 = part of some >=3-in-a-row match
match_grid:
    .space 4096
    
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the grid
    init_grid:
            la   $t0, grid        # pointer
            li   $t1, -1          # value
            li   $t2, 1024        # 4096 bytes / 4 = 1024 words

    init_loop:
            sw   $t1, 0($t0)      # store -1
            addi $t0, $t0, 4      # next word
            addi $t2, $t2, -1     # count--
            bgtz $t2, init_loop   # loop if > 0


    # Initialize the game
    
    # get the random colors for the falling column
    # test random_color
    # get the first color
    jal random_color  
    la $t0, cur_colors
    sw $v0, 0($t0)
    # get the second color
    jal random_color  
    la $t0, cur_colors
    sw $v0, 4($t0)
    # get the third color
    jal random_color  
    la $t0, cur_colors
    sw $v0, 8($t0)
    
    # Draw initial frame
    jal redraw_everything
    
    
    main_loop:
            # 1) poll keyboard
            jal  poll_key
            move $t0, $v0             # t0 = returned key (0 if none)
        
            beq  $t0, $zero, no_key_this_frame
        
            # 2) handle key if present
            move $a0, $t0             # a0 = ASCII
            jal  handle_key

    no_key_this_frame:
            # 3) redraw whole scene
            jal  redraw_everything
        
            # 4) sleep ~16 ms for ~60 FPS
            li   $a0, 16              # 16 ms
            jal  sleep_ms
        
            j    main_loop
        
    # # sleep for 5 seconds
    # li $v0, 32
    # li $a0, 5000
    # syscall
    
    # exit
    li $v0, 10
    syscall
    
    
    
##############################################################################
# draw_pixel(x=$a0, y=$a1, color=$a2)
##############################################################################
draw_pixel:
      # calculate offset
      lw $t0, WIDTH_U  # t0 = WIDTH
      mul $t0, $a1, $t0  # t0 = y * WIDTH
      addu $t0, $t0, $a0  # t0 = y * WIDTH + X
      sll $t0, $t0, 2  # t0 = 4 * (y * WIDTH + x)
      
      # calculate address
      lw $t1, ADDR_DSPL  # t1 = base
      addu $t1, $t1, $t0  # t1 = base + offset
      
      # draw the pixel with given color
      sw $a2, 0($t1)
      
      # return address
      jr $ra
  
  

##############################################################################
# clear_screen()
##############################################################################
clear_screen:
        lw $t0, ADDR_DSPL  # t0 = base
        li $t1, 0  # t1 = black
        lw $t2, WIDTH_U  # t2 = WIDTH_U
        lw $t3, HEIGHT_U  # t3 = HEIGHT_U
        mul $t2, $t2, $t3  # t2 = WIDTH_U * HEIGHT_U
        
        clear_loop:
                sw $t1, 0($t0)  
                addiu $t0, $t0, 4 
                addiu $t2, $t2, -1
                bgtz $t2, clear_loop
                nop
                jr $ra


##############################################################################
# draw_grid()
# using color deep grey (0x00333333)
##############################################################################
# draw_grid:
        # la $t7, GREY  # color
        # li $t0, 0  # x
        # li $t1, 0x1  # y
        # li $t2, 0x10  # counter
        
        # yzero_loop:
                # lw $a2, 0($t7)
                # move $a0, $t0
                # move $a1, $t1
                # jal draw_pixel
                # addiu $t0, $t0, 1
                # addiu $t2, $t2, -1
                # bgtz $t2, yzero_loop
                # nop
                # jr $ra 
                
draw_grid:
        li $t1, 0x00333333
        lw $t0, ADDR_DSPL
        addiu $t0, $t0, 128
        
        addi $t2, $t0, 64
        start_loop:
                beq $t2, $t0, loop_end
                sw $t1, 0($t0)
                addi $t0, $t0, 4
                j start_loop
        loop_end:
        
        li $t1, 0x00333333
        lw $t0, ADDR_DSPL
        addiu $t0, $t0, 3840
        
        addi $t2, $t0, 64
        second_loop:
                beq $t2, $t0, second_end
                sw $t1, 0($t0)
                addi $t0, $t0, 4
                j second_loop
        second_end:
        
        li $t1, 0x00333333
        lw $t0, ADDR_DSPL
        addiu $t0, $t0, 128
        
        addi $t2, $t0, 3840
        third_loop:
                beq $t2, $t0, third_end
                sw $t1, 0($t0)
                addi $t0, $t0, 128
                j third_loop
        third_end:
        
        
        li $t1, 0x00333333
        lw $t0, ADDR_DSPL
        addiu $t0, $t0, 192
        
        addi $t2, $t0, 3840
        fourth_loop:
                beq $t2, $t0, fourth_end
                sw $t1, 0($t0)
                addi $t0, $t0, 128
                j fourth_loop
        fourth_end:
        


##############################################################################
# random_color() → v0
##############################################################################
random_color:
        # generate random value
        li $v0, 42
        li $a0, 0
        li $a1, 6
        syscall
        move $t0, $a0  # t0 = random number
        
        # get the offset
        sll $t0, $t0, 2  # t0 = 4 * random
        
        # get the color address
        la $t1, colors  # t1 = colors[0]
        addu $t1, $t1, $t0  # t1 = colors[0] + 4 * random      
        
        # store the color address to $v0
        lw $v0, 0($t1)
        
        # return address
        jr $ra
        
        
##############################################################################
# draw_falling_column(x=$a0, y=$a1, color=$a2)
##############################################################################
# Uses the current state:
#   cur_x   : top block x position (in CELLS)
#   cur_y   : top block y position (in CELLS)
#   cur_colors[] : 3 colors (already 0x00RRGGBB), from TOP to BOTTOM
#
# Each block is drawn as a single pixel at:
#   x_px = cur_x_cell
#   y_px = (cur_y_cell + i)   for i = 0..2
#
# Relies on:
#   CELL        : word, size of one cell in pixels
#   cur_x  : word
#   cur_y  : word
#   cur_colors  : 3 * word
#
# Calls:
#   draw_pixel(x=$a0, y=$a1, color=$a2)
#
# Uses: $t0-$t9, $a0-$a2, preserves $ra
##############################################################################
draw_falling_column:
        # Prologue: save $ra since we will jal draw_pixel
        addiu $sp, $sp, -4
        sw $ra, 0($sp)
        
        # # load CELL size
        # lw $t5, CELL  # t5 = CELL
        
        # # load current coordinates (top block)
        # lw $t0, cur_x  # t0 = cur_x
        # lw $t1, cur_y  # t1 = cur_y (top)
        
        # # base address of colors[0]
        # la    $t4, cur_colors        # t4 = &cur_colors[0]
        
        # loop index of i = 0..2
        li $t6, 0 # t6 = i
        
draw_col_loop:
        bge $t6, 3, draw_col_done  # if i >= 3, exit loop
        
        # load coordinates
        lw $t0, cur_x
        lw $t1, cur_y
        addu $t1, $t1, $t6
        
        # load color = colors[i]
        la $t2, cur_colors
        sll $t3, $t6, 2
        addu $t3, $t3, $t2
        lw $t3, 0($t3)

        # draw the pixel
        move $a0, $t0
        move $a1, $t1
        move $a2, $t3
        jal draw_pixel
        
        # i++ and repeat
        addiu $t6, $t6, 1
        j draw_col_loop
        
        
draw_col_done:
        # Epilogue: restore return address and return
        lw $ra, 0($sp)
        addiu $sp, $sp, 4
        jr $ra

# =========================================
# poll_key
#   Check MMIO keyboard for a pending key.
#   RETURNS:
#       v0 = 0       if no key
#       v0 = ASCII   if there is a key
# =========================================
poll_key:
    # Load keyboard base address from .data
    lw   $t0, ADDR_KBRD      # t0 = 0xffff0000

    # Read status word: 1 means a key is available
    lw   $t1, 0($t0)         # status = MEM[0xffff0000]

    beq  $t1, $zero, no_key  # if status == 0, no key

    # There is a key: read ASCII code
    lw   $t2, 4($t0)         # data  = MEM[0xffff0004]
    move $v0, $t2            # return ASCII in v0
    jr   $ra

no_key:
    move $v0, $zero          # return 0
    jr   $ra


# =========================================
# handle_key
#   INPUT:
#       a0 = ASCII code of key
#
#   EFFECT:
#       'a' : move column left  (cur_x--)
#       'd' : move column right (cur_x++)
#       's' : move column down  (cur_y++)
#       'w' : rotate colors (top,mid,bot) -> (bot,top,mid)
#       'q' : exit program (syscall 10)
#
#   NOTE:
#       Uses .data variables:
#         cur_x, cur_y, cur_colors[3], COLS, ROWS
# =========================================
handle_key:
    move $t0, $a0          # t0 = key

    # --- Check for 'q' (quit) ---
    li   $t1, 'q'
    beq  $t0, $t1, hk_quit

    # --- Check for 'a' (move left) ---
    li   $t1, 'a'
    beq  $t0, $t1, hk_left

    # --- Check for 'd' (move right) ---
    li   $t1, 'd'
    beq  $t0, $t1, hk_right

    # --- Check for 's' (move down) ---
    li   $t1, 's'
    beq  $t0, $t1, hk_down

    # --- Check for 'w' (rotate colors) ---
    li   $t1, 'w'
    beq  $t0, $t1, hk_rotate

    # Any other key: ignore
    jr   $ra


# ---- case: 'q' ----
hk_quit:
    li   $v0, 10        # exit
    syscall              # does not return
    jr   $ra             # (never reached)


# ---- case: 'a' ----
# hk_left:
    # lw   $t2, cur_x    # t2 = cur_x
    # addi $t2, $t2, -1       # t2--

    # # # Clamp: if t2 < 0, set to 0
    # # bltz $t2, hk_left_fix
    
    # # Clamp: if t2 < 1, set to 1
    # li   $t3, 1          # t3 = 1

    # # if t2 < t3 then clamp
    # # Use: slt t4, t2, t3   -> t4=1 if t2 < t3
    # slt  $t4, $t2, $t3
    # bnez $t4, hk_left_fix
    
    # sw   $t2, cur_x
    # jr   $ra

# hk_left_fix:
    # li   $t2, 1
    # sw   $t2, cur_x
    # jr   $ra
    
hk_left:
    # Prologue: save $ra since we will jal draw_pixel
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Ask if we can move left
    jal  can_move_left
    beq  $v0, $zero, hk_left_ret   # if cannot, just return

    # can move: x_cell--
    lw   $t2, cur_x
    addi $t2, $t2, -1
    sw   $t2, cur_x
    
    # Epilogue: restore return address and return
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

hk_left_ret:
    # Epilogue: restore return address and return
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra


# ---- case: 'd' ----
# hk_right:
    # lw   $t2, cur_x    # t2 = cur_x
    # addi $t2, $t2, 1        # t2++

    # # Clamp: if t2 >= COLS, set to COLS-1
    # lw   $t3, COLS          # t3 = COLS
    # addi $t3, $t3, -1       # t3 = COLS-1

    # # if t2 > t3 then clamp
    # # Use: slt t4, t3, t2   -> t4=1 if t3 < t2
    # slt  $t4, $t3, $t2
    # bnez $t4, hk_right_fix

    # sw   $t2, cur_x
    # jr   $ra

# hk_right_fix:
    # sw   $t3, cur_x
    # jr   $ra
    
hk_right:
    # Prologue: save $ra since we will jal draw_pixel
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Ask if we can move right
    jal  can_move_right
    beq  $v0, $zero, hk_right_ret  # if cannot, just return

    # can move: x_cell++
    lw   $t2, cur_x
    addi $t2, $t2, 1
    sw   $t2, cur_x
    
    # Epilogue: restore return address and return
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

hk_right_ret:
    # Epilogue: restore return address and return
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra


# ---- case: 's' ----
# hk_down:
    # lw   $t2, cur_y    # t2 = cur_y_cell
    # addi $t2, $t2, 1        # t2++

    # # Clamp: y <= ROWS-3 (since column has height 3)
    # lw   $t3, ROWS          # t3 = ROWS
    # addi $t3, $t3, -3       # t3 = ROWS-3

    # # if t2 > t3 then clamp
    # slt  $t4, $t3, $t2      # t4=1 if t3 < t2
    # bnez $t4, hk_down_fix

    # sw   $t2, cur_y
    # jr   $ra

# hk_down_fix:
    # sw   $t3, cur_y
    # jr   $ra
    
hk_down:
    # Prologue: save $ra since we will jal draw_pixel
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Ask can_move_down() if we can move the column down by 1 cell.
    jal  can_move_down

    beq  $v0, $zero, hk_down_cannot
    # v0 != 0 -> can move down

    # Load cur_y, increment by 1, and store back.
    lw   $t2, cur_y      # t2 = cur_y
    addi $t2, $t2, 1          # t2++
    sw   $t2, cur_y
 
    # Epilogue: restore return address and return
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra
    

hk_down_cannot:
    # # For now: do nothing if we cannot move down.
    # # In Milestone 3, this is exactly where we will:
    # #   1) "lock" the current column into the grid
    # #   2) run match + clear + gravity
    # #   3) spawn a new falling column
    # # Epilogue: restore return address and return
    # lw $ra, 0($sp)
    # addiu $sp, $sp, 4
    # jr $ra
    
    # Cannot move down any further:
    # # 1) lock the current column into the grid
    # # 2) spawn a new falling column at the top
    # jal  lock_column_into_grid
    # jal  spawn_new_column
    
    # # 1) lock the current column into the grid
    # jal  lock_column_into_grid

    # # 2) run one round of match+clear+gravity
    # jal  resolve_matches_once

    # # 3) spawn a new falling column at the top
    # jal  spawn_new_column

    # # Epilogue: restore return address and return
    # lw $ra, 0($sp)
    # addiu $sp, $sp, 4
    # jr $ra

    # 1) Lock current falling column into the grid
    jal  lock_column_into_grid

    # 2) Resolve all matches with chain reactions
    jal  resolve_all_matches
    # (v0 is not strictly needed here,除非以后想根据消除情况加分数)

    # 3) Check for game over after gravity
    jal  check_game_over
    beq  $v0, $zero, hk_spawn_new   # v0 == 0 -> safe, go spawn new column

    # v0 != 0 -> game over: you can print something or just exit
hk_game_over:
    # (optional) print "Game Over" here using syscall 4
    li   $v0, 10                   # exit
    syscall                        # does not return

hk_spawn_new:
    # 4) If still safe, spawn a new falling column at the top
    jal  spawn_new_column
    
    # Epilogue: restore return address and return
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra


# ---- case: 'w' ----
hk_rotate:
    # Rotate (top, mid, bot) -> (bot, top, mid)
    la   $t5, cur_colors    # t5 = &cur_colors[0]
    lw   $t6, 0($t5)        # t6 = top
    lw   $t7, 4($t5)        # t7 = mid
    lw   $t8, 8($t5)        # t8 = bot

    # new_top    = old_bot
    # new_middle = old_top
    # new_bottom = old_middle
    sw   $t8, 0($t5)        # top    <- bot
    sw   $t6, 4($t5)        # middle <- top
    sw   $t7, 8($t5)        # bottom <- mid

    jr   $ra
    
    
# =========================================
# redraw_everything
#   Repaint the whole scene for this frame:
#     1) background (playfield frame, black interior)
#     2) current falling 3-block column
# =========================================
redraw_everything:
    addiu $sp, $sp, -4       # save ra
    sw    $ra, 0($sp)

    # 1) draw static background (replace with your own routine(s))
    jal   clear_screen    # e.g., clear_screen + frame
    jal   draw_grid
    
    jal draw_grid_blocks

    # 2) draw the current falling column
    jal   draw_falling_column

    # restore ra and return
    lw    $ra, 0($sp)
    addiu $sp, $sp, 4
    jr    $ra
    
    
# =========================================
# sleep_ms
#   INPUT:
#       a0 = number of milliseconds to sleep
#   EFFECT:
#       Calls syscall 32 (MARS) to sleep.
# =========================================
sleep_ms:
    li   $v0, 32      # 32 = sleep in milliseconds
    syscall
    jr   $ra
    

# =========================================
# can_move_left
#   RETURNS:
#       v0 = 1  if the column can move left
#       v0 = 0  if it would collide with wall or blocks
# =========================================
can_move_left:
    # Load current x_cell and y_cell
    lw   $t0, cur_x      # t0 = x
    lw   $t1, cur_y      # t1 = y (top block)

    # 1) Check left wall: if x_cell == 0, cannot move
    # beq  $t0, $zero, cml_no   # x == 0 -> cannot
    

    # Load 2 to compute left boundary
    li   $t2, 1            # t2 = 1

    # 1) Check left wall: if x_cell <= 1, cannot move
    # Use: if (x_cell < 1) or (x_cell == 1)
    blt  $t0, $t2, cmr_no     # if x < 1
    beq  $t0, $t2, cmr_no     # if x == 1

    # x_left = x_cell - 1
    addi $t2, $t0, -1         # t2 = x_left

    # Prepare constants/base addresses
    lw   $t3, COLS            # t3 = COLS
    la   $t4, grid            # t4 = &grid[0]
    lw   $t5, EMPTY           # t5 = EMPTY value (-1)

    # i = 0
    li   $t6, 0               # t6 = i

cml_loop:
    bge  $t6, 3, cml_ok       # while (i < 3)

    # y_i = y_cell + i
    addu $t7, $t1, $t6        # t7 = y_cell + i

    # index = y_i * COLS + x_left
    mul  $t8, $t7, $t3        # t8 = y_i * COLS
    addu $t8, $t8, $t2        # t8 = index

    # byte offset = index * 4
    sll  $t8, $t8, 2          # t8 = index * 4

    # addr = &grid[0] + offset
    addu $t9, $t4, $t8        # t9 = &grid[y_i][x_left]

    # load grid[y_i][x_left]
    lw   $s0, 0($t9)

    # if this cell is not EMPTY -> collision
    bne  $s0, $t5, cml_no

    # i++
    addi $t6, $t6, 1
    j    cml_loop

# All three cells are EMPTY -> can move left
cml_ok:
    li   $v0, 1
    jr   $ra

# Collision (wall or block)
cml_no:
    li   $v0, 0
    jr   $ra
    
    
# =========================================
# can_move_right
#   RETURNS:
#       v0 = 1  if the column can move right
#       v0 = 0  if it would collide with wall or blocks
# =========================================
can_move_right:
    # Load current x_cell and y_cell
    lw   $t0, cur_x      # t0 = x_cell
    lw   $t1, cur_y      # t1 = y_cell (top block)

    # Load COLS to compute right boundary
    lw   $t2, COLS            # t2 = COLS
    addi $t2, $t2, -1         # t2 = COLS - 1

    # 1) Check right wall: if x_cell >= COLS-1, cannot move
    # Use: if (x_cell > COLS-1) or (x_cell == COLS-1)
    bgt  $t0, $t2, cmr_no     # if x > COLS-1
    beq  $t0, $t2, cmr_no     # if x == COLS-1

    # x_right = x_cell + 1
    addi $t3, $t0, 1          # t3 = x_right

    # Prepare constants/base addresses
    lw   $t4, COLS            # t4 = COLS
    la   $t5, grid            # t5 = &grid[0]
    lw   $t6, EMPTY           # t6 = EMPTY value (-1)

    # i = 0
    li   $t7, 0               # t7 = i

cmr_loop:
    bge  $t7, 3, cmr_ok       # while (i < 3)

    # y_i = y_cell + i
    addu $t8, $t1, $t7        # t8 = y_cell + i

    # index = y_i * COLS + x_right
    mul  $t9, $t8, $t4        # t9 = y_i * COLS
    addu $t9, $t9, $t3        # t9 = index

    # byte offset = index * 4
    sll  $t9, $t9, 2          # t9 = index * 4

    # addr = &grid[0] + offset
    addu $s0, $t5, $t9        # s0 = &grid[y_i][x_right]

    # load grid[y_i][x_right]
    lw   $s1, 0($s0)

    # if this cell is not EMPTY -> collision
    bne  $s1, $t6, cmr_no

    # i++
    addi $t7, $t7, 1
    j    cmr_loop

# All three cells are EMPTY -> can move right
cmr_ok:
    li   $v0, 1
    jr   $ra

# Collision (wall or block)
cmr_no:
    li   $v0, 0
    jr   $ra


# =========================================
# can_move_down
#   Check if the falling column can move
#   one cell DOWN without collision.
#
#   RETURNS:
#       v0 = 1  if can move down
#       v0 = 0  if would collide (bottom or grid cell)
#
#   Uses:
#       cur_x, cur_y, ROWS, COLS, grid, EMPTY
# =========================================
can_move_down:
    # Load current x and y
    lw   $t0, cur_x      # t0 = x
    lw   $t1, cur_y      # t1 = y (top block)

    # Compute y_below = y + 3 (cell just below the bottom block)
    addi $t2, $t1, 3          # t2 = y_below

    # Load ROWS and check bottom collision:
    lw   $t3, ROWS            # t3 = ROWS

    # if (y_below >= ROWS) -> cannot move down
    # Use slt: t4 = (t2 < t3) ? 1 : 0
    slt  $t4, $t2, $t3        # t4 = 1 if y_below < ROWS
    beq  $t4, $zero, cmd_no   # if not (y_below < ROWS), then cannot move

    # Now we know y_below is inside the grid. Check grid[y_below][x_cell].

    # index = y_below * COLS + x_cell
    lw   $t5, COLS            # t5 = COLS
    mul  $t6, $t2, $t5        # t6 = y_below * COLS
    addu $t6, $t6, $t0        # t6 = index = y_below*COLS + x_cell

    # Byte offset = index * 4 (word array)
    sll  $t6, $t6, 2          # t6 = index * 4

    # address = &grid[0] + offset
    la   $t7, grid
    addu $t7, $t7, $t6        # t7 = &grid[y_below][x_cell]

    # Load cell value
    lw   $t8, 0($t7)          # t8 = grid[y_below][x_cell]

    # Load EMPTY constant
    lw   $t9, EMPTY

    # If cell != EMPTY, cannot move down
    bne  $t8, $t9, cmd_no

    # Otherwise: no collision, can move
    li   $v0, 1               # return 1 (true)
    jr   $ra

cmd_no:
    li   $v0, 0               # return 0 (false)
    jr   $ra
    
    
# =========================================
# lock_column_into_grid
#   Take the current falling column and
#   "lock" it into the grid as static gems.
#
#   Uses:
#       cur_x, cur_y, cur_colors[3],
#       grid, COLS
#
#   Each block i (0..2) is written to:
#       (x, y + i)
# =========================================
lock_column_into_grid:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    # Load x, y
    lw   $t0, cur_x      # t0 = x
    lw   $t1, cur_y      # t1 = y (top)

    lw   $t2, COLS            # t2 = COLS
    la   $t3, grid            # t3 = &grid[0]
    la   $t4, cur_colors      # t4 = &cur_colors[0]

    li   $t5, 0               # i = 0

lcg_loop:
    bge  $t5, 3, lcg_done     # while (i < 3)

    # y_i = y + i
    addu $t6, $t1, $t5        # t6 = y + i

    # index = y_i * COLS + x
    mul  $t7, $t6, $t2        # t7 = y_i * COLS
    addu $t7, $t7, $t0        # t7 = index

    # byte offset = index * 4
    sll  $t7, $t7, 2          # t7 = index * 4

    # addr_grid = &grid[0] + offset
    addu $t8, $t3, $t7        # t8 = &grid[y_i][x_cell]

    # load cur_colors[i] 
    sll  $t9, $t5, 2          # t9 = i * 4
    addu $t9, $t4, $t9
    lw   $t9, 0($t9)          # t9 = cur_colors[i]

    # store into grid[y_i][x_cell]
    sw   $t9, 0($t8)

    # i++
    addi $t5, $t5, 1
    j    lcg_loop

lcg_done:
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra
    
    
# =========================================
# spawn_new_column
#   Create a new falling column at the top:
#     - x = COLS / 2
#     - y = 0
#     - cur_colors[0..2] = random palette indices 0..5
# =========================================
spawn_new_column:
    addiu $sp, $sp, -8
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)     # save s0 (used as loop counter / temp)

    # 1) x = COLS / 2
    lw   $t0, COLS
    srl  $t0, $t0, 1      # t0 = COLS / 2
    sw   $t0, cur_x

    # 2) y = 0
    li   $t1, 2
    sw   $t1, cur_y

    # 3) cur_colors[i] = random_color  ()
    la   $t2, cur_colors  # t2 = &cur_colors[0]
    li   $s0, 0           # i = 0

spc_loop:
    bge  $s0, 3, spc_done

    # call random_index_0_to_5
    jal  random_color
    # v0 now is the random color

    # store into cur_colors[i]
    sll  $t3, $s0, 2      # t3 = i * 4
    addu $t4, $t2, $t3    # t4 = &cur_colors[i]
    sw   $v0, 0($t4)

    addi $s0, $s0, 1
    j    spc_loop

spc_done:
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 8
    jr   $ra
    
    
# =========================================
# draw_grid_blocks
#   Draw all STATIC blocks stored in grid.
#
#   For each cell (x_cell, y_cell):
#       if grid[y][x] != EMPTY:
#           color = grid[y][x]
#           draw_pixel(x, y, color)
# =========================================
draw_grid_blocks:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    # Load constants and base addresses
    lw   $t0, COLS            # t0 = COLS
    lw   $t1, ROWS            # t1 = ROWS
    lw   $t2, CELL            # t2 = CELL (cell size in pixels)

    la   $t3, grid            # t3 = &grid[0]
    la   $t4, colors          # t4 = &colors[0]
    lw   $t5, EMPTY           # t5 = EMPTY value (-1)

    li   $t6, 1               # y_cell = 1

dgb_outer_y:
    lw   $t0, COLS            # t0 = COLS
    lw   $t1, ROWS            # t1 = ROWS
    bge  $t6, $t1, dgb_done   # while (y_cell < ROWS)

    li   $t7, 2               # x_cell = 2

dgb_outer_x:
    lw   $t0, COLS            # t0 = COLS
    lw   $t1, ROWS            # t1 = ROWS
    bge  $t7, $t0, dgb_next_y # while (x_cell < COLS)

    # index = y_cell * COLS + x_cell
    mul  $t8, $t6, $t0        # t8 = y * COLS
    addu $t8, $t8, $t7        # t8 = index

    # byte offset = index * 4
    sll  $t8, $t8, 2          # t8 = index * 4

    # addr_grid = &grid[0] + offset
    addu $t9, $t3, $t8        # t9 = &grid[y][x]

    # load grid[y][x]
    lw   $s0, 0($t9)          # s0 = value in grid[y][x]

    # if value == EMPTY, skip
    beq  $s0, $t5, dgb_next_x

    move   $a2, $s0          # a2 = color (0x00RRGGBB)

    # Compute pixel coordinates:
    move  $a0, $t7       # a0 = x
    move  $a1, $t6        # a1 = y

    # Draw a pixel at (x, y)
    jal  draw_pixel

dgb_next_x:
    addi $t7, $t7, 1          # x_cell++
    j    dgb_outer_x

dgb_next_y:
    addi $t6, $t6, 1          # y_cell++
    j    dgb_outer_y

dgb_done:
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra


# =========================================
# clear_match_grid
#   Set all entries of match_grid to 0.
# =========================================
clear_match_grid:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    lw   $t0, COLS            # t0 = COLS
    lw   $t1, ROWS            # t1 = ROWS
    la   $t2, match_grid      # t2 = &match_grid[0]

    mul  $t3, $t0, $t1        # t3 = COLS * ROWS = num_cells
    li   $t4, 0               # value 0

    li   $t5, 0               # i = 0

cmg_loop:
    bge  $t5, $t3, cmg_done   # while i < num_cells

    sll  $t6, $t5, 2          # t6 = i * 4
    addu $t7, $t2, $t6        # t7 = &match_grid[i]
    sw   $t4, 0($t7)          # match_grid[i] = 0

    addi $t5, $t5, 1
    j    cmg_loop

cmg_done:
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra



# =========================================
# clear_marked_cells
#   For every cell where match_grid == 1,
#   set grid cell to EMPTY and clear the flag.
# =========================================
clear_marked_cells:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    lw   $t0, COLS          # t0 = COLS
    lw   $t1, ROWS          # t1 = ROWS
    la   $t2, grid          # t2 = &grid[0]
    la   $t3, match_grid    # t3 = &match_grid[0]
    lw   $t4, EMPTY         # t4 = EMPTY

    mul  $t5, $t0, $t1      # t5 = total cells
    li   $t6, 0             # i = 0

cmc_loop:
    bge  $t6, $t5, cmc_done

    sll  $t7, $t6, 2        # offset = i*4

    addu $t8, $t3, $t7      # &match_grid[i]
    lw   $t9, 0($t8)        # t9 = flag

    beq  $t9, $zero, cmc_next   # if flag==0 -> skip

    # flag == 1: clear grid cell and flag
    addu $t8, $t2, $t7      # &grid[i]
    sw   $t4, 0($t8)        # grid[i] = EMPTY

    li   $t9, 0
    la   $t8, match_grid
    addu $t8, $t8, $t7
    sw   $t9, 0($t8)        # match_grid[i] = 0

cmc_next:
    addi $t6, $t6, 1
    j    cmc_loop

cmc_done:
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra
    
    
    
# =========================================
# apply_gravity
#   For each column x, make all non-empty
#   cells fall to the bottom (higher y).
# =========================================
apply_gravity:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    lw   $t0, COLS          # t0 = COLS
    lw   $t1, ROWS          # t1 = ROWS
    la   $t2, grid          # t2 = &grid[0]
    lw   $t3, EMPTY         # t3 = EMPTY

    li   $t4, 0             # x = 0

ag_col_loop:
    bge  $t4, $t0, ag_done  # while x < COLS

    # write_y = ROWS - 1
    addi $t5, $t1, -1       # t5 = write_y

    # y from bottom to top
    addi $t6, $t1, -1       # t6 = y = ROWS-1

ag_scan_up:
    bltz $t6, ag_fill_empties    # while y >= 0

    # index = y*COLS + x
    mul  $t7, $t6, $t0
    addu $t7, $t7, $t4
    sll  $t7, $t7, 2

    addu $t8, $t2, $t7      # &grid[y][x]
    lw   $t9, 0($t8)        # cell value

    beq  $t9, $t3, ag_next_y    # if EMPTY -> y--

    # non-empty: move down to write_y if needed
    # target index = write_y*COLS + x
    mul  $s0, $t5, $t0
    addu $s0, $s0, $t4
    sll  $s0, $s0, 2
    addu $s1, $t2, $s0          # &grid[write_y][x]

    sw   $t9, 0($s1)            # grid[write_y][x] = cell

    # if write_y != y, clear old position
    bne  $t5, $t6, ag_clear_old
    j    ag_after_move

ag_clear_old:
    sw   $t3, 0($t8)            # old cell = EMPTY

ag_after_move:
    addi $t5, $t5, -1           # write_y--

ag_next_y:
    addi $t6, $t6, -1           # y--
    j    ag_scan_up

ag_fill_empties:
    # After moving all non-empty cells, fill 0..write_y with EMPTY
    bltz $t5, ag_next_col       # if write_y < 0 -> nothing

ag_fill_loop:
    bltz $t5, ag_next_col

    mul  $t7, $t5, $t0
    addu $t7, $t7, $t4
    sll  $t7, $t7, 2
    addu $t8, $t2, $t7

    sw   $t3, 0($t8)            # grid[write_y][x] = EMPTY

    addi $t5, $t5, -1
    j    ag_fill_loop

ag_next_col:
    addi $t4, $t4, 1            # x++
    j    ag_col_loop

ag_done:
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra


# =========================================
# mark_horizontal_matches
#   Scan each row left-to-right and mark
#   all horizontal runs of length >= 3
#   in match_grid.
#
# RETURNS:
#   v0 = number of newly marked cells
# =========================================
mark_horizontal_matches:
    addiu $sp, $sp, -20
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)      # s0 = marked_count
    sw    $s1, 8($sp)      # s1 = run_color
    sw    $s2, 12($sp)     # s2 = run_len
    sw    $s3, 16($sp)     # s3 = row_base_index (y*COLS)

    li   $s0, 0            # marked_count = 0

    lw   $t0, COLS         # t0 = COLS
    lw   $t1, ROWS         # t1 = ROWS
    la   $t2, grid         # t2 = &grid[0]
    la   $t3, match_grid   # t3 = &match_grid[0]
    lw   $t4, EMPTY        # t4 = EMPTY

    li   $t5, 0            # t5 = y

mh_y_loop:
    bge  $t5, $t1, mh_done     # while y < ROWS

    # row_base_index = y * COLS
    mul  $s3, $t5, $t0         # s3 = y*COLS

    li   $t6, 0                # t6 = x

mh_x_loop:
    bge  $t6, $t0, mh_next_y   # while x < COLS

    # idx = row_base + x
    addu $t7, $s3, $t6
    sll  $t7, $t7, 2           # offset in bytes
    addu $t8, $t2, $t7         # t8 = &grid[y][x]
    lw   $t9, 0($t8)           # t9 = grid[y][x]

    # If cell is EMPTY, skip
    beq  $t9, $t4, mh_x_skip

    # Start a run from (y, x)
    move $s1, $t9              # s1 = run_color
    li   $s2, 1                # s2 = run_len = 1

    addi $t7, $t6, 1           # t7 = x2 = x + 1

mh_run_loop:
    bge  $t7, $t0, mh_run_end  # if x2 >= COLS, break

    # grid[y][x2]
    addu $t8, $s3, $t7
    sll  $t8, $t8, 2
    addu $t8, $t2, $t8
    lw   $t9, 0($t8)
    bne  $t9, $s1, mh_run_end  # color changed

    addi $s2, $s2, 1           # len++
    addi $t7, $t7, 1           # x2++
    j    mh_run_loop

mh_run_end:
    # If len < 3, nothing to mark
    blt  $s2, 3, mh_after_run

    # Mark all cells from (y, x) to (y, x+len-1)
    li   $a0, 0                # a0 = i = 0

mh_mark_loop:
    bge  $a0, $s2, mh_after_run    # i >= len ?

    # mark_x = x + i
    addu $t9, $t6, $a0

    # idx = row_base + mark_x
    addu $t9, $s3, $t9
    sll  $t9, $t9, 2
    addu $t9, $t3, $t9         # t9 = &match_grid[y][mark_x]

    lw   $t8, 0($t9)           # old flag
    bne  $t8, $zero, mh_mark_next

    li   $t8, 1
    sw   $t8, 0($t9)           # set flag = 1
    addi $s0, $s0, 1           # marked_count++

mh_mark_next:
    addi $a0, $a0, 1           # i++
    j    mh_mark_loop

mh_after_run:
    addi $t6, $t6, 1           # x++
    j    mh_x_loop

mh_x_skip:
    addi $t6, $t6, 1           # x++
    j    mh_x_loop

mh_next_y:
    addi $t5, $t5, 1           # y++
    j    mh_y_loop

mh_done:
    move $v0, $s0              # return marked_count

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 20
    jr   $ra


# =========================================
# mark_vertical_matches
#   Scan each column top-to-bottom and mark
#   all vertical runs of length >= 3
#   in match_grid.
#
# RETURNS:
#   v0 = number of newly marked cells
# =========================================
mark_vertical_matches:
    addiu $sp, $sp, -20
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)      # s0 = marked_count
    sw    $s1, 8($sp)      # s1 = run_color
    sw    $s2, 12($sp)     # s2 = run_len
    sw    $s3, 16($sp)     # (unused here, just kept for symmetry)

    li   $s0, 0            # marked_count = 0

    lw   $t0, COLS         # t0 = COLS
    lw   $t1, ROWS         # t1 = ROWS
    la   $t2, grid         # t2 = &grid[0]
    la   $t3, match_grid   # t3 = &match_grid[0]
    lw   $t4, EMPTY        # t4 = EMPTY

    li   $t5, 0            # t5 = x

mv_x_loop:
    bge  $t5, $t0, mv_done     # while x < COLS

    li   $t6, 0                # t6 = y

mv_y_loop:
    bge  $t6, $t1, mv_next_x   # while y < ROWS

    # idx = y*COLS + x
    mul  $t7, $t6, $t0
    addu $t7, $t7, $t5
    sll  $t7, $t7, 2
    addu $t8, $t2, $t7         # t8 = &grid[y][x]
    lw   $t9, 0($t8)           # t9 = grid[y][x]

    beq  $t9, $t4, mv_y_skip   # if EMPTY -> y++

    # Start a vertical run from (y,x)
    move $s1, $t9              # s1 = run_color
    li   $s2, 1                # s2 = run_len = 1
    addi $t7, $t6, 1           # t7 = y2 = y+1

mv_run_loop:
    bge  $t7, $t1, mv_run_end  # if y2 >= ROWS -> break

    # cell at (y2, x)
    mul  $t8, $t7, $t0
    addu $t8, $t8, $t5
    sll  $t8, $t8, 2
    addu $t8, $t2, $t8
    lw   $t9, 0($t8)
    bne  $t9, $s1, mv_run_end

    addi $s2, $s2, 1           # len++
    addi $t7, $t7, 1           # y2++
    j    mv_run_loop

mv_run_end:
    blt  $s2, 3, mv_after_run  # len < 3 -> ignore

    # Mark all cells from (y, x) to (y+len-1, x)
    li   $a0, 0                # i = 0

mv_mark_loop:
    bge  $a0, $s2, mv_after_run

    # mark_y = y + i
    addu $t8, $t6, $a0
    # idx = mark_y*COLS + x
    mul  $t9, $t8, $t0
    addu $t9, $t9, $t5
    sll  $t9, $t9, 2
    addu $t9, $t3, $t9         # &match_grid[mark_y][x]

    lw   $t7, 0($t9)           # old flag
    bne  $t7, $zero, mv_mark_next

    li   $t7, 1
    sw   $t7, 0($t9)
    addi $s0, $s0, 1           # marked_count++

mv_mark_next:
    addi $a0, $a0, 1           # i++
    j    mv_mark_loop

mv_after_run:
    addi $t6, $t6, 1           # y++
    j    mv_y_loop

mv_y_skip:
    addi $t6, $t6, 1           # y++
    j    mv_y_loop

mv_next_x:
    addi $t5, $t5, 1           # x++
    j    mv_x_loop

mv_done:
    move $v0, $s0

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 20
    jr   $ra

# =========================================
# mark_diag_down_right_matches
#   Scan all ↘ diagonals and mark runs
#   of length >= 3 in match_grid.
#
# RETURNS:
#   v0 = number of newly marked cells
# =========================================
mark_diag_down_right_matches:
    addiu $sp, $sp, -20
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)      # s0 = marked_count
    sw    $s1, 8($sp)      # s1 = run_color
    sw    $s2, 12($sp)     # s2 = run_len
    sw    $s3, 16($sp)     # (unused here)

    li   $s0, 0            # marked_count = 0

    lw   $t0, COLS         # t0 = COLS
    lw   $t1, ROWS         # t1 = ROWS
    la   $t2, grid         # t2 = &grid[0]
    la   $t3, match_grid   # t3 = &match_grid[0]
    lw   $t4, EMPTY        # t4 = EMPTY

    li   $t5, 0            # t5 = y

mdr_y_loop:
    bge  $t5, $t1, mdr_done    # while y < ROWS

    li   $t6, 0                # t6 = x

mdr_x_loop:
    bge  $t6, $t0, mdr_next_y  # while x < COLS

    # cell = grid[y][x]
    mul  $t7, $t5, $t0
    addu $t7, $t7, $t6
    sll  $t7, $t7, 2
    addu $t8, $t2, $t7         # &grid[y][x]
    lw   $t9, 0($t8)           # t9 = grid[y][x]

    beq  $t9, $t4, mdr_x_skip  # if EMPTY -> x++

    # start run from (x,y)
    move $s1, $t9              # run_color
    li   $s2, 1                # len = 1

    addi $t7, $t6, 1           # nx = x + 1
    addi $t8, $t5, 1           # ny = y + 1

mdr_run_loop:
    bge  $t7, $t0, mdr_run_end # if nx >= COLS -> break
    bge  $t8, $t1, mdr_run_end # if ny >= ROWS -> break

    # cell at (ny, nx)
    mul  $t9, $t8, $t0
    addu $t9, $t9, $t7
    sll  $t9, $t9, 2
    addu $t9, $t2, $t9
    lw   $a0, 0($t9)           # reuse a0 for cell
    bne  $a0, $s1, mdr_run_end

    addi $s2, $s2, 1           # len++
    addi $t7, $t7, 1           # nx++
    addi $t8, $t8, 1           # ny++
    j    mdr_run_loop

mdr_run_end:
    blt  $s2, 3, mdr_after_run # len < 3 -> ignore

    # mark i = 0 .. len-1:
    li   $a0, 0                # i = 0

mdr_mark_loop:
    bge  $a0, $s2, mdr_after_run

    # mark_x = x + i
    addu $t7, $t6, $a0
    # mark_y = y + i
    addu $t8, $t5, $a0

    # idx = mark_y * COLS + mark_x
    mul  $t9, $t8, $t0
    addu $t9, $t9, $t7
    sll  $t9, $t9, 2
    addu $t9, $t3, $t9         # &match_grid[mark_y][mark_x]

    lw   $t7, 0($t9)           # old flag
    bne  $t7, $zero, mdr_mark_next

    li   $t7, 1
    sw   $t7, 0($t9)
    addi $s0, $s0, 1           # marked_count++

mdr_mark_next:
    addi $a0, $a0, 1
    j    mdr_mark_loop

mdr_after_run:
    addi $t6, $t6, 1           # x++
    j    mdr_x_loop

mdr_x_skip:
    addi $t6, $t6, 1           # x++
    j    mdr_x_loop

mdr_next_y:
    addi $t5, $t5, 1           # y++
    j    mdr_y_loop

mdr_done:
    move $v0, $s0

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 20
    jr   $ra
    
    
# =========================================
# mark_diag_down_left_matches
#   Scan all ↙ diagonals and mark runs
#   of length >= 3 in match_grid.
#
# RETURNS:
#   v0 = number of newly marked cells
# =========================================
mark_diag_down_left_matches:
    addiu $sp, $sp, -20
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)      # s0 = marked_count
    sw    $s1, 8($sp)      # s1 = run_color
    sw    $s2, 12($sp)     # s2 = run_len
    sw    $s3, 16($sp)     # (unused)

    li   $s0, 0            # marked_count = 0

    lw   $t0, COLS         # t0 = COLS
    lw   $t1, ROWS         # t1 = ROWS
    la   $t2, grid         # t2 = &grid[0]
    la   $t3, match_grid   # t3 = &match_grid[0]
    lw   $t4, EMPTY        # t4 = EMPTY

    li   $t5, 0            # t5 = y

mdl_y_loop:
    bge  $t5, $t1, mdl_done    # while y < ROWS

    li   $t6, 0                # t6 = x

mdl_x_loop:
    bge  $t6, $t0, mdl_next_y  # while x < COLS

    # cell = grid[y][x]
    mul  $t7, $t5, $t0
    addu $t7, $t7, $t6
    sll  $t7, $t7, 2
    addu $t8, $t2, $t7         # &grid[y][x]
    lw   $t9, 0($t8)           # t9 = grid[y][x]

    beq  $t9, $t4, mdl_x_skip  # if EMPTY -> x++

    # start run from (x,y)
    move $s1, $t9              # run_color
    li   $s2, 1                # len = 1

    addi $t7, $t6, -1          # nx = x - 1
    addi $t8, $t5, 1           # ny = y + 1

mdl_run_loop:
    bltz $t7, mdl_run_end      # nx < 0 -> break
    bge  $t7, $t0, mdl_run_end # nx >= COLS -> break
    bge  $t8, $t1, mdl_run_end # ny >= ROWS -> break

    # cell at (ny, nx)
    mul  $t9, $t8, $t0
    addu $t9, $t9, $t7
    sll  $t9, $t9, 2
    addu $t9, $t2, $t9
    lw   $a0, 0($t9)           # reuse a0
    bne  $a0, $s1, mdl_run_end

    addi $s2, $s2, 1           # len++
    addi $t7, $t7, -1          # nx--
    addi $t8, $t8, 1           # ny++
    j    mdl_run_loop

mdl_run_end:
    blt  $s2, 3, mdl_after_run # len < 3 -> ignore

    # mark i = 0 .. len-1:
    li   $a0, 0                # i = 0

mdl_mark_loop:
    bge  $a0, $s2, mdl_after_run

    # mark_x = x - i
    subu $t7, $t6, $a0
    # mark_y = y + i
    addu $t8, $t5, $a0

    # idx = mark_y * COLS + mark_x
    mul  $t9, $t8, $t0
    addu $t9, $t9, $t7
    sll  $t9, $t9, 2
    addu $t9, $t3, $t9         # &match_grid[mark_y][mark_x]

    lw   $t7, 0($t9)           # old flag
    bne  $t7, $zero, mdl_mark_next

    li   $t7, 1
    sw   $t7, 0($t9)
    addi $s0, $s0, 1           # marked_count++

mdl_mark_next:
    addi $a0, $a0, 1
    j    mdl_mark_loop

mdl_after_run:
    addi $t6, $t6, 1           # x++
    j    mdl_x_loop

mdl_x_skip:
    addi $t6, $t6, 1           # x++
    j    mdl_x_loop

mdl_next_y:
    addi $t5, $t5, 1           # y++
    j    mdl_y_loop

mdl_done:
    move $v0, $s0

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 20
    jr   $ra






# =========================================
# mark_all_matches
#   Clear match_grid, then mark all
#   runs (>=3) in 4 directions:
#     - horizontal
#     - vertical
#     - diag down-right (↘)
#     - diag down-left  (↙)
#
# RETURNS:
#   v0 = total number of cells marked
# =========================================
mark_all_matches:
    addiu $sp, $sp, -8
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)

    li   $s0, 0           # total_marked = 0

    # 1) clear match_grid first
    jal  clear_match_grid

    # 2) horizontal
    jal  mark_horizontal_matches
    addu $s0, $s0, $v0

    # 3) vertical
    jal  mark_vertical_matches
    addu $s0, $s0, $v0

    # 4) diag down-right (↘)
    jal  mark_diag_down_right_matches
    addu $s0, $s0, $v0

    # 5) diag down-left (↙)
    jal  mark_diag_down_left_matches
    addu $s0, $s0, $v0

    move $v0, $s0          # return total_marked

    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 8
    jr    $ra



# =========================================
# resolve_matches_once
#   1) mark_all_matches()
#   2) if no matches, return 0
#   3) clear_marked_cells()
#   4) apply_gravity()
#
#   RETURNS:
#       v0 = 1 if at least one cell was removed
#       v0 = 0 if nothing matched
#
#   NOTE:
#       Currently only horizontal+vertical.
#       You can extend mark_hv_matches()
#       to add diagonals as well.
# =========================================
resolve_matches_once:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    jal  mark_all_matches
    move $t0, $v0          # t0 = marked_count

    beq  $t0, $zero, rmo_none

    # We have some matches
    jal  clear_marked_cells
    jal  apply_gravity

    li   $v0, 1            # did something
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra

rmo_none:
    li   $v0, 0            # nothing matched
    lw   $ra, 0($sp)
    addiu $sp, $sp, 4
    jr   $ra
    

# =========================================
# resolve_all_matches
#   Repeatedly call resolve_matches_once
#   until it returns 0 (no more matches).
#
# RETURNS:
#   v0 = 1  if at least one match happened
#   v0 = 0  if no matches at all
# =========================================
resolve_all_matches:
    addiu $sp, $sp, -8
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)      # s0 = any_removed (0/1)

    li   $s0, 0            # any_removed = 0

ram_loop:
    jal  resolve_matches_once
    beq  $v0, $zero, ram_done   # if this round did nothing -> stop

    li   $s0, 1            # at least one round removed something
    j    ram_loop

ram_done:
    move $v0, $s0          # return any_removed (0 or 1)

    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addiu $sp, $sp, 8
    jr    $ra


# =========================================
# check_game_over
#   Check if top row (y = 0) contains
#   any non-EMPTY cell in grid.
#
# RETURNS:
#   v0 = 1  if game over (top row not empty)
#   v0 = 0  if still safe
# =========================================
check_game_over:
    # addiu $sp, $sp, -4
    # sw    $ra, 0($sp)

    lw   $t0, COLS          # t0 = COLS
    la   $t1, grid          # t1 = &grid[0]  (row 0)
    addi $t1, $t1, 256             # t1 = &grid[2]  (row 2)
    lw   $t2, EMPTY         # t2 = EMPTY

    li   $t3, 0             # x = 0

cgo_loop_x:
    bge  $t3, $t0, cgo_safe     # while x < COLS

    sll  $t4, $t3, 2            # offset = x * 4  
    addu $t5, $t1, $t4          # &grid[0][x]
    lw   $t6, 0($t5)            # value = grid[0][x]

    bne  $t6, $t2, cgo_over     # if value != EMPTY -> game over

    addi $t3, $t3, 1            # x++
    j    cgo_loop_x

cgo_over:
    li   $v0, 1                 # game over
    # lw   $ra, 0($sp)
    # addiu $sp, $sp, 4
    jr    $ra

cgo_safe:
    move $v0, $zero             # safe
    # lw   $ra, 0($sp)
    # addiu $sp, $sp, 4
    jr    $ra




