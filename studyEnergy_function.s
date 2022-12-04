# .data
# 	password: .string "ddd" #user defined password
# .text
# main:  
# la a0 password
# jal ra study_energy #now, ra <- pc and pc <-study_energy
# li a7 10
# ecall

study_energy:
#this function will receive as input the address of a string called password(inside a0) and print in the screen the number of cpu cycles that it takes to call the function string_compare with password and each of the strings of the form "a",..."z"
#Four Words will be needed from the Stack Memory Segment and so we subtract 4*4 = 16 from the stack pointer
#The way on how we will use these 4 Words is the following (counting from below)
#Word1 for the storage of the string "a"
#Word2 for the storage of ra (value of pc when we call the study_energy function)
#Word3 for the storage of t1 (for loop limit value)
#Word4 for the storage of t0 (iteration counter value)
addi sp sp -20
sw a0 16(sp)
li t4 'a'
sb t4 12(sp) #storing "a" inside the stack (1 Word above bottom of the stack)
sb x0 13(sp)

#first, as we said in the beginning, store inside the stack, the word that encodes the instruction address of the instruction right after the call of sudy_energy which after jal ra study_energy is encoded inside the register ra
sw ra 8(sp)
#Step 1: We want to count the number of cycles used in the function call string_compare by fixing the first input to be a string representing the password and the other one, string 2, varying from {"a",..."z2}
#By the parameter convention used, the inputs of both strings must be inside a0 and a1, where these are registers holding the address of the first byte/character of the respective string.
#Using the "a" we have stored inside the stack , we can easily modify the string just by adding a 1 (ascii, to get the next character) in the character byte, stored at "12(sp)" and input that as the address for the string 2 in the string_copare function
#On this way, we make sure we are inputing password together with "a","b",...,"z" in each respective iteration by summing 1 by 1 25 times
li t0 0 #for the loop(there are 26 letters-> 26 calls=iterations)
li t1 25
addi a1 sp 12 #move the address of string to a1 as input for string compare...
loop: bgt t0 t1 end_loop
  #before calling string_compare function, to not mess up the registers used, since it uses registers t0 t1 and t4 , first store their current values in the stack to later retrieve them
  sw t0 0(sp)
  sw t1 4(sp)
  rdcycle t2 #cycles before calling the string_compare function
  jal ra string_compare
  rdcycle t3
  sub t3 t3 t2
  #PRINT CHARACTER AND CYCLES:::

  lb a0 0(a1)
  li a7 11
  ecall
 
  li a0 58
  li a7 11
  ecall
 
  li a0 32
  li a7 11
  ecall
 
  mv a0 t3
  li a7 1
  ecall
 
  li a0 10
  li a7 11
  ecall
           
  #now, recover the register values
  lw t0 0(sp)
  lw t1 4(sp)
  lb t4 12(sp) #Load to t4 the only byte/character of the string to get the next one by adding one to it
  addi t4 t4 1 #to get the next character string example: from t4 = 'a' then t4+=1-> t4 = 'b' through ASCII
  
  lw a0 16(sp) #reset the a0 to have the address of password again for next call
  sb t4 12(sp) #update the character of the 1-character string stored in the stack
  addi t0 t0 1 #increment the iteration count
  j loop #jump back to for loop
end_loop:
#now that the task is done, we retrieve the pc value to get back to the next instruction after study_energy call, which had been stored inside the stack
lw ra 8(sp)
addi sp sp 20 #reset the stack pointer to its original address (bottom of the stack)
jr ra #so that pc = ra, which is the address of the instruction after jal ra study_energy

string_compare:
# FUNCTION: String Compare
# INPUT -> String1 address || String2 address(both in a0 and a1)
# OUTPUT: Stored in a2
# Return -1: Error (If A or B address is NULL)
# Return 1: Same string
# Return 0: Different string

#For convinience, we move the string addresses to temporary registers t0,t1
mv t0 a0
mv t1 a1
#load the first byte of content of each string inside t3 and t4 
lb t3 0(t0)
lb t4 0(t1)
     
# PHASE 1 : Error Handling 
# If either the address of string1 or string2 is null then return -1:
bnez t3 continue1
li a0 -1
jr ra
continue1:
bnez t4 continue2
li a0 -1
jr ra
continue2:

#As explained in pseudocode of exercise1, check each character one by one
#We set the value of a0 to be 1 so that if no characters are different the value of a0 will stay as 1
li a0 1
while1: beqz t3 end1 #keep making the iterative character comparisons while the string1 has still characters to check with
  beq t3 t4 continue #dont do anything whenever the respective characters are the same.Otherwise, characters are different and so the strings are different;load a 0 in a0
  li a0 0
  jr ra
  continue:
  #sum by one the addresses of each of the strings in t0 and t1 to obtain the addresses of the next characters respectively
  addi t0 t0 1 
  addi t1 t1 1
  #load the next characters for the next comparison iteration 
  lbu t3 0(t0)
  lbu t4 0(t1)
  j while1 #jump back to the while to keep on comparing  
end1:
#make sure both strings are same length by verifying that t3 and t4 are both equal (both null character ie: end of string indicator)
beq t3 t4 end3 #if it doesnt branch, then they share the same characters but length(string1) < length(string2)
li a0 0
jr ra
end3:
jr ra
