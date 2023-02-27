################################################################################
##  20210902: This model is updated according to the mew emory mapping 
################################################################################

import numpy as np
import random 

random.seed(10)

def write_int2hexFile(data, filename, width=8):
    with open(filename, 'w') as fh:
        index = 0
        hex_str = ''
        for i in range( len(data )):
            item_hex    = '{0:0{width}x}'.format(data[i], width=2) ##hex(int(data[i], 2)).zfill(2)[2:]
            hex_str     = item_hex + hex_str
            index       = index + 1
            if(index == width): ## Each line has width-Byte data
                fh.write(hex_str + '\n')
                hex_str = ''
                index   = 0


def write_sim_file(data, filename, length):
    with open(filename, 'w') as fh:
        for idx, line in enumerate(data):
            str = ''
            for val in line:
                str += (val + ' ')
            str = str[:-1]
            if (idx != length-1):
                str += '\n'
            fh.write(str)


################################################################################
##  M=N=8, each act byte will consume 8 bit of znz data
################################################################################
def conv2d( R=1, S=1, C=32, K=8, H=1, W=1, M=8, group_size=16, group_nz=8, path="./"):
    if (group_size==16):
        if(group_nz==8):
            group_znz   = [0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1]
    elif (group_size==32):
        if(group_nz==8):
            group_znz   = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1]
        elif(group_nz==16):
            group_znz   = [0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1, 0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1]
    
    ################################################################################
    ##  0. Check the assertions
    ################################################################################
    comp_ratio  = int(group_size/group_nz)

    assert(K%M == 0)
    num_kernel_group = int(K/M)

    assert(C%M == 0)
    chunk_per_channel = int(C/M)
    assert(chunk_per_channel%comp_ratio == 0)
    nz_chunk_per_channel = int(chunk_per_channel/comp_ratio)
    
    assert(C%group_size == 0)
    group_per_channel = int(C/group_size)

    ################################################################################
    ##  1. generate the activation data
    ################################################################################
    act = []
    for h in range(H):
        layer_act = []
        for w in range(W):
            channel_act = []
            for c in range(C):
                channel_act.append( random.randint(1,255) )
            layer_act.append(channel_act)
        act.append(layer_act)

    mem_act = []
    for h in range(H):
        for w in range(W):
            for c in range(C):
                mem_act.append( act[h][w][c] )

    ################################################################################
    ##  2. Write Act data into mem in act.txt
    ################################################################################
    bin_file    = path + "act.txt"
    hex1_file   = path + "act.txt.hex1"
    hex8_file   = path + "act.txt.hex8"
    hex16_file  = path + "act.txt.hex16"

    bin_vals    = []
    for item in mem_act:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_act) )   

    write_int2hexFile(mem_act, hex1_file, 1)
    write_int2hexFile(mem_act, hex8_file, 8)
    write_int2hexFile(mem_act, hex16_file, 16)

    ################################################################################
    ## 3. generate the structured sparsity pruned weight data
    ################################################################################
    weight  = []
    cmap    = []
    nz      = []
    for k in range(K):
        kernel_weight   = []
        kernel_cmap     = []
        kernel_nz       = []        
        for r in range(R):
            layer_weight    = []
            layer_cmap      = []
            layer_nz        = []
            for s in range(S):
                channel_weight  = []
                channel_cmap    = []
                channel_nz      = []
                for cnt_group in range(group_per_channel):
                    group_data  = []
                    group_nz    = []
                    group_cmap  = []

                    random.shuffle( group_znz )
                    for i in range(group_size):
                        if(group_znz[i] == 1):
                            group_cmap.append( 1 )
                            # Generate random data if the ZNZ is 1
                            gen_random_data = random.randint(1,255)
                            group_data.append( gen_random_data )
                            group_nz.append( gen_random_data )
                        else:
                            group_cmap.append( 0 )
                            group_data.append( 0 )
                    
                    channel_weight.extend( group_data )
                    channel_cmap.extend( group_cmap )
                    channel_nz.extend( group_nz )

                layer_weight.append( channel_weight )
                layer_cmap.append( channel_cmap )
                layer_nz.append( channel_nz )

            kernel_weight.append( layer_weight )
            kernel_cmap.append( layer_cmap )
            kernel_nz.append( layer_nz )

        weight.append( kernel_weight )
        cmap.append( kernel_cmap )
        nz.append( kernel_nz )

    '''
    print( weight )
    print( cmap )
    print( nz )
    '''
 
    print( "Shape of weight_array:", np.array( weight  ).shape )
    print( "Shape of cmap_array:",   np.array( cmap    ).shape )
    print( "Shape of nz_array:",     np.array( nz      ).shape )
    
    ################################################################################
    ##  4. Reshape the mem weight/znz data according to the mem layout
    ################################################################################
    mem_weight  = []
    mem_cmap    = []
    mem_nz      = []
    for cnt_kernel_group in range(num_kernel_group):
        for r in range(R):
            for s in range(S):
                for cnt_chunk in range(chunk_per_channel):
                    for k_idx in range(M):                            
                        for chunk_idx in range(M):
                            mem_weight.append(  weight[cnt_kernel_group*M + k_idx][r][s][cnt_chunk*M + chunk_idx] )
                            mem_cmap.append(      cmap[cnt_kernel_group*M + k_idx][r][s][cnt_chunk*M + chunk_idx] )

    for cnt_kernel_group in range(num_kernel_group):
        for r in range(R):
            for s in range(S):
                for cnt_chunk in range(nz_chunk_per_channel):
                    for k_idx in range(M):
                        for chunk_idx in range(M):
                            mem_nz.append(  nz[cnt_kernel_group*M + k_idx][r][s][cnt_chunk*M + chunk_idx] )

    # print( mem_weight )
    # print( mem_cmap )
    # print( mem_nz )

    ################################################################################
    ##  5. Write the compressed weight into mem
    ################################################################################
    bin_file    = path + "weight_skip.txt"
    hex1_file   = path + "weight_skip.txt.hex1"
    hex8_file   = path + "weight_skip.txt.hex8"
    hex16_file  = path + "weight_skip.txt.hex16"

    bin_vals    = []
    for item in mem_nz:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_nz) )   

    write_int2hexFile(mem_nz, hex1_file, 1)
    write_int2hexFile(mem_nz, hex8_file, 8)
    write_int2hexFile(mem_nz, hex16_file, 16)


    ################################################################################
    ##  6. Write the uncompressed weight into mem
    ################################################################################
    bin_file    = path + "weight.txt"
    hex1_file   = path + "weight.txt.hex1"
    hex8_file   = path + "weight.txt.hex8"
    hex16_file  = path + "weight.txt.hex16"

    bin_vals    = []
    for item in mem_weight:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_weight) )   

    write_int2hexFile(mem_weight, hex1_file, 1)
    write_int2hexFile(mem_weight, hex8_file, 8)
    write_int2hexFile(mem_weight, hex16_file, 16)

    ################################################################################
    ##  7. Write the cmap data into mem
    ################################################################################
    bin_file    = path + "znz.txt"
    znz_fp      = open( bin_file , "w")

    num_line = int( len(mem_cmap)/8 )
    for line in range(num_line):
        znz_data = mem_cmap[line*8 : (line+1)*8]
        znz_data_reverse = znz_data[::-1]

        znz_str = ''
        for elem in znz_data_reverse:
            znz_str =  znz_str + str(elem)
        znz_fp.write(znz_str + " 0\n")
    

    ################################################################################
    ##  8. Zero skip part
    ################################################################################
    act_skip = []
    for k in range(K):      # Inside each ochan group
        kernel_act_skip = []
        for h in range(H):      # act Y/H
            layer_act_skip = []
            for w in range(W):  # act X/W
                channel_act_skip = []
                for c in range(C):
                    if( cmap[k][h][w][c] == 1 ):
                        channel_act_skip.append( act[h][w][c] )
                layer_act_skip.append( channel_act_skip )
            kernel_act_skip.append( layer_act_skip )
        act_skip.append( kernel_act_skip )

    print( "Shape of act: ",        np.array( act ).shape )
    print( "Shape of act_skip:",    np.array( act_skip ).shape )
    #print( act_skip)

    ################################################################################
    ##  9. Re-org the compressed act data
    ################################################################################
    mem_act_skip = []
    for cnt_kernel_group in range(num_kernel_group):
        for h in range(H):      # act Y/H
            for w in range(W):  # act X/W
                for cnt_chunk in range(nz_chunk_per_channel):
                    for k_idx in range(M):
                        for chunk_idx in range(M):
                            mem_act_skip.append(  act_skip[cnt_kernel_group*M + k_idx][r][s][cnt_chunk*M + chunk_idx] )

    ################################################################################
    ##  10. Write the act skipped into mem
    ################################################################################
    bin_file    = path + "act_skip.txt"
    hex1_file   = path + "act_skip.txt.hex1"
    hex8_file   = path + "act_skip.txt.hex8"
    hex16_file  = path + "act_skip.txt.hex16"

    bin_vals    = []
    for item in mem_act_skip:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_act_skip) )   

    write_int2hexFile(mem_act_skip, hex1_file, 1)
    write_int2hexFile(mem_act_skip, hex8_file, 8)
    write_int2hexFile(mem_act_skip, hex16_file, 16)



################################################################################
##  M=N=8, each act byte will consume 8 bit of znz data
################################################################################
def percept( M=8, group_size=16, group_nz=8, percept_size=16, iteration=1, path="./"):
    if (group_size==16):
        if(group_nz==8):
            group_znz   = [0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1]
        elif(group_nz==4):
            group_znz   = [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,1,1,1]
    elif (group_size==32):
        if(group_nz==8):
            group_znz   = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1]
        elif(group_nz==16):
            group_znz   = [0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1, 0,0,0,0, 0,0,0,0, 1,1,1,1, 1,1,1,1]
    

    ################################################################################
    ##  0. Check the assertions
    ################################################################################
    assert( group_size%group_nz == 0 )
    comp_ratio  = int( group_size/group_nz )

    assert( percept_size%comp_ratio == 0 )
    percept_size_zs = int( percept_size/comp_ratio )

    # How many groups per channal direction
    assert ( (percept_size*M)%group_size == 0 )
    group_per_channel   = int( (percept_size*M)/group_size )

    C = percept_size*M  # Channel size, which is the real percept depth
    assert(C%M == 0)
    chunk_per_channel = int(percept_size*M/M)
    nz_chunk_per_channel = int(chunk_per_channel/comp_ratio)


    ################################################################################
    ##  1. generate the activation data
    ################################################################################
    act = []
    for c in range( C ):
        act.append( random.randint(1,255) )

    mem_act = []
    for c in range(percept_size*M):
        mem_act.append( act[c] )

    print( "Shape of act_array:",   np.array( act ).shape )

    ################################################################################
    ##  2. Write Act data into mem in act.txt
    ################################################################################
    bin_file    = path + "act.txt"
    hex1_file   = path + "act.txt.hex1"
    hex8_file   = path + "act.txt.hex8"
    hex16_file  = path + "act.txt.hex16"

    bin_vals    = []
    for item in mem_act:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_act) )   

    write_int2hexFile(mem_act, hex1_file, 1)
    write_int2hexFile(mem_act, hex8_file, 8)
    write_int2hexFile(mem_act, hex16_file, 16)    

    ################################################################################
    ##  3. Generate the cmap, weight, zs_weight data
    ################################################################################
    cmap = []
    weight = []
    zs_weight = []
    for m in range(M):  # same as for k in range(K): but we have only M kernel in percept
        channel_cmap        = []
        channel_weight      = []
        channel_zs_weight   = []
        for g in range(group_per_channel):  # Every 2/4 entry can be compressed into one 16/32 znz group
            group_cmap      = []
            group_weight    = []
            group_zs_weight = []

            random.shuffle( group_znz )
            for i in range(group_size):
                if(group_znz[i] == 1):
                    group_cmap.append( 1 )
                    # Generate random data if the ZNZ is 1
                    gen_random_data = random.randint(1,255)
                    group_weight.append( gen_random_data )
                    group_zs_weight.append( gen_random_data )
                else:
                    group_cmap.append( 0 )
                    group_weight.append( 0 )

            channel_cmap.extend( group_cmap )
            channel_weight.extend( group_weight )
            channel_zs_weight.extend( group_zs_weight )

        cmap.append( channel_cmap )
        weight.append( channel_weight )
        zs_weight.append( channel_zs_weight )

    print( "Shape of cmap_array:",   np.array( cmap ).shape )
    print( "Shape of weight_array:", np.array( weight ).shape )
    print( "Shape of nz_array:",     np.array( zs_weight ).shape )
    

    ################################################################################
    ##  4. Reshape the mem weight/znz data according to the mem layout
    ################################################################################
    mem_weight  = []
    mem_cmap    = []
    mem_nz      = []

    for cnt_chunk in range(chunk_per_channel):
        for m in range(M):
            for chunk_idx in range(M):
                mem_weight.append(  weight[m][cnt_chunk*M + chunk_idx] )
                mem_cmap.append(      cmap[m][cnt_chunk*M + chunk_idx] )

    for m in range(M):
        for cnt_chunk in range(nz_chunk_per_channel):
            for chunk_idx in range(M):
                mem_nz.append(  zs_weight[m][cnt_chunk*M + chunk_idx] )

    ################################################################################
    ##  5. Write the compressed weight into mem
    ################################################################################
    bin_file    = path + "weight_skip.txt"
    hex1_file   = path + "weight_skip.txt.hex1"
    hex8_file   = path + "weight_skip.txt.hex8"
    hex16_file  = path + "weight_skip.txt.hex16"

    bin_vals    = []
    for item in mem_nz:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_nz) )   

    write_int2hexFile(mem_nz, hex1_file, 1)
    write_int2hexFile(mem_nz, hex8_file, 8)
    write_int2hexFile(mem_nz, hex16_file, 16)

    ################################################################################
    ##  6. Write the uncompressed weight into mem
    ################################################################################
    bin_file    = path + "weight.txt"
    hex1_file   = path + "weight.txt.hex1"
    hex8_file   = path + "weight.txt.hex8"
    hex16_file  = path + "weight.txt.hex16"

    bin_vals    = []
    for item in mem_weight:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_weight) )   

    write_int2hexFile(mem_weight, hex1_file, 1)
    write_int2hexFile(mem_weight, hex8_file, 8)
    write_int2hexFile(mem_weight, hex16_file, 16)

    ################################################################################
    ##  7. Write the cmap data into mem
    ################################################################################
    bin_file    = path + "znz.txt"
    znz_fp      = open( bin_file , "w")

    num_line = int( len(mem_cmap)/8 )
    for line in range(num_line):
        znz_data = mem_cmap[line*8 : (line+1)*8]
        znz_data_reverse = znz_data[::-1]

        znz_str = ''
        for elem in znz_data_reverse:
            znz_str =  znz_str + str(elem)
        znz_fp.write(znz_str + " 0\n")
    

    ################################################################################
    ##  8. Zero skip part
    ################################################################################
    act_skip = []
    for m in range(M):      # Inside each ochan group
        channel_act_skip = []
        for c in range( C ):
            if( cmap[m][c] == 1 ):
                channel_act_skip.append( act[c] )
        act_skip.append( channel_act_skip )

    print( "Shape of act: ",        np.array( act ).shape )
    print( "Shape of act_skip:",    np.array( act_skip ).shape )

    ################################################################################
    ##  9. Re-org the compressed act data
    ################################################################################
    mem_act_skip = []
    for cnt_chunk in range(nz_chunk_per_channel):
        for m_idx in range(M):
            for chunk_idx in range(M):
                mem_act_skip.append(  act_skip[m_idx][cnt_chunk*M + chunk_idx] )

    ################################################################################
    ##  10. Write the act skipped into mem
    ################################################################################
    bin_file    = path + "act_skip.txt"
    hex1_file   = path + "act_skip.txt.hex1"
    hex8_file   = path + "act_skip.txt.hex8"
    hex16_file  = path + "act_skip.txt.hex16"

    bin_vals    = []
    for item in mem_act_skip:
        bin_vals.append( bin( item )[2:].zfill( 8 ) )
    inp_last = ['0']*(len(bin_vals)-1) + ['1']
    write_sim_file( zip(bin_vals, inp_last), bin_file, len(mem_act_skip) )   

    write_int2hexFile(mem_act_skip, hex1_file, 1)
    write_int2hexFile(mem_act_skip, hex8_file, 8)
    write_int2hexFile(mem_act_skip, hex16_file, 16)


if __name__ == "__main__":
    # NNA and SS, Path to store the data

    # NNA64 25%
    '''
    M           = 8
    group_size  = 32 
    group_nz    = 8
    path        = "./0.25/nna64/"
    '''

    
    # NNA64 50%
    M           = 8
    group_size  = 16 
    group_nz    = 8
    path        = "./0.50/nna64/"
    

    '''    
    # NNA256 25%
    M           = 16
    group_size  = 32 
    group_nz    = 8
    path        = "./0.25/nna256/"
    '''

    '''
    # NNA256 50%
    M           = 16
    group_size  = 32 
    group_nz    = 16
    path        = "./0.50/nna256/"
    '''
    
    '''
    # NNA1K 25%
    M           = 32
    group_size  = 32
    group_nz    = 8
    path        = "./0.25/nna1k/"
    '''
    
    '''
    # NNA1K 50%
    M           = 32
    group_size  = 32 
    group_nz    = 16
    path        = "./0.50/nna1k/"
    '''

    # You have store multiple copy of Act if K>1*M
    # Pamameters of Conv2D 
    R = 1   #3
    S = 1   #3
    C = 32
    K = M*4   #16 #Simplify to one group

    # Make a Act the same size as kernel 
    H = R 
    W = S 
    
    # conv2d( R, S, C, K, H, W, M, group_size, group_nz, path)
    
    M           = 32
    #path        = "./0.25/nna1k/"
    path        = "./0.50/nna1k/"

    # iteration=1, disable the iteration for now
    percept( M=M, group_size=16, group_nz=8, percept_size=400, path=path)
    