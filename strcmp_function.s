

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