# .data
# password: .string "computer"
# dummy: .string "aaaaaaaa"
# sentence: .string "The cracked password obtained is : "
# .text

# main:

# la a0 password
# la a1 dummy
# jal ra attack
# #to show you that it works check the command window ...
# li a7 4
# la a0 sentence
# ecall
# mv a0 a1 #since the address of dummy(result of attack funtion) is inside a1 when calling the attack function, we will print dummy to see if it has cracked the passowrd correctly!
# ecall
# li a7 10
# ecall

attack:
#this function is meant to simulate the act of a side channel attack, through the analysis of cycle counting used by the processor when comparing two strings, using string_compare function
#the inputs are the password of length 8 whose starting address is known (this is not realistic though) together with the starting address of another initially empty string called dummy
#password address is in a0
#dummy address is in a1
#the goal is to guess the password by iterating 8 times over the 27 possible characters in a single spot. This reduces the inneficient brute force 28^8 attempts of guessing, down to only 28*8 (only 224 in worst case!)
#Once we have guessed the i-th character, we will try with the same 27 characters for the i+1-th character and so for, reaching the end goal; getting the password. 
#Note that in each iteration (from i=1:8) we look for the cycles taken after calling string_compare with a string character ("a"-....-"z") & password[i:8) since we are looking for the i-th character
#At a fixed iteration, the target character is the one that takes more cycles and the reason why is the following:
#When comparing single characters strings with the password string, the control flow is the following always: check character by character, discarding equality if theres any different one at same spot
#Example1: string_compare("a","he") will quickly see that a!=h so it will know from first character that the strings are not equal 
#Example2: string_compare("h","he") will not as quickly see that they are different(more cycles than Example1) because opposite to Example1, it sees that h=h, and so it takes another step, to compare the second spot as well. Here, it sees that they are not the same since 0!=h so
#On this way, we will take this approach and see which is the character that when compared with password from specific spot, has the highest cycle number
addi sp sp -16 #make 2 word os space in the stack for later(for ra and iteration counter t0)
sw a1 12(sp) 
sw a0 12(sp) 

li t0 0 #iteration counter

#get the length of the string password to crack
li t1 0 #length register(later will be the for loop limit)
lb t3 0(a0)
length: beqz t3 end
    addi t1 t1 1
    addi a0 a0 1
    lb t3 0(a0)
    j length
end:
#Exception : Password has 0 length ie: null password
bne t1 zero exception_handled
#this means that password is null
sb zero 0(a1)
jr ra
exception_handled:

lw a0 12(sp) #reset address to be the first character of password string

sw ra 8(sp) #to return to the instruction right after the call of attack function
FOR: beq t0 t1 END1
    #store the length of password (for limit) in the stack
    sw t1 0(sp)
    add t2 a1 t0
    #everytime, we will start by getting the cycles for the character "a" at the current position
    li t3 'a'
    sb t3 0(t2) #store it inside dummy string to call string compare with it
    #before calling string_comapre, make sure we dont lose the values of t0 and the before cycles in  t3 using the stack 
    sw t0 4(sp)
    rdcycle t5 #before cycles..
    jal ra string_compare
    rdcycle t4  #get the cycles after calling it
    sub t5 t4 t5  #great!Now t4 contains the cycles needed to compoute the string_compare function with password and dummy with last character an "a" on current index(t0)
    lw t0 4(sp) #now, recover the value of t0
    lw a0 12(sp) #reset it
    add t2 a1 t0 #recover the current index for the character guesses
    li t3 'a' #get character "a" and sum it 1 to get "b"
    addi t3 t3 1 #t3 = "b"
    sb t3 0(t2) #store it at dummy[t0]
    #now obtain the cycles on the same way for the new dummy with character "b" instead of "a"
    sw t0 4(sp)
    rdcycle t6
    jal ra string_compare
    rdcycle t4
    sub t6 t4 t6 #great!We have the amount of cycles of the dummy string and password where dummy[t0] ="b" here
    lw t0 4(sp) #recover t0 value
    lw a0 12(sp) #reset it
    add t2 a1 t0 
    WHILE: bne t5 t6 STOP #repeat the process above for next characters until the cycles t4 and t5 differ, then we know we have the solution at the one with the greatest cycle value
          #test with next character
          lb t3 0(t2)
          addi t3 t3 1 
          sb t3 0(t2)
          #store the current iteration at t0 inside stack
          sw t0 4(sp)
          rdcycle t6 #before call cycles
          jal ra string_compare
          rdcycle t3
          sub t6 t3 t6 #great!we have the cycles for this character
          #recover t0 and a0
          lw a0 12(sp)
          lw t0 4(sp)
          add t2 a1 t0
          j WHILE
    STOP:
    #now, until here we know that t4 and t5 are different, so we find the solution on the biggest one as explained initially. Therefore, we first see if t4 is the biggest because in that case, we have the correct charactyer already stored
    bgt t6 t5 E1
    #this means that the correct character at dummy[t0] = password[t0] = "a" so we store it at t0 
    li t3 'a'
    sb t3 0(t2)
    E1:
    #now, we increment the counter of the for loop and jump back to the for
    addi t0 t0 1
    #recover the length of password(for loop limit)
    lw t1 0(sp)
    j FOR
END1:
#load from the stack the value of ra to be able to return to the nexty instruction after attack function was called
lw ra 8(sp)
addi sp sp 16
jr ra

##################################################################
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
