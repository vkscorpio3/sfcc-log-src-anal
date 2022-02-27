BEGIN {
#     print f >"/dev/stderr"
#     print s_val >"/dev/stderr"
     flag=0
 }
#($0 ~ /^\[2022-01-26.*GMT\]/) { 
($0 ~ f) { 
    #pat = "/|" s_val "|/"
    if ($0 ~ s_val) { flag=1 } else { flag=0 }     
 }                                                            
flag 
