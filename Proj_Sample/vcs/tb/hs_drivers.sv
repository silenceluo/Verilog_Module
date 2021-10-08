// Copyright 2019 ETH Zurich, Lukas Cavigelli and Georg Rutishauser
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// `timescale 1ps/1fs

package hs_drv_pkg;

class HandshakeDrv #(
   parameter int unsigned DATA_W    = 8,
   parameter int unsigned NUM_BYTE  = 8,
   parameter time         TA        = 0ns,
   parameter time         TT        = 0ns,
   parameter int unsigned MIN_WAIT  = 0,
   parameter int unsigned MAX_WAIT  = 2,
   parameter logic        HAS_LAST  = 1'b0,
   parameter string       NAME      = ""
);
   parameter int DATA_SIZE = DATA_W * NUM_BYTE;

   virtual HandshakeIf_t #(
      .DATA_W(DATA_SIZE)
   ) vif;

   function new( virtual HandshakeIf_t #( .DATA_W(DATA_SIZE) ) vif );
      this.vif = vif;
   endfunction // new

   // Only for number of words in decoding
   task automatic feed_inputs_wordnum(input string file);
      automatic int                    cycles_to_wait;
      automatic logic [DATA_SIZE-1:0]  dat;
      automatic int                    fh;
      automatic logic                  last;
      automatic logic signed [8:0]     testchar;

      fh = $fopen(file, "r");
      if (fh == 0) begin
         $display("fh: %d", fh);
         $info("File %s does not exist - aborting read_outputs task.", file);
         return;
      end
      testchar = $fgetc(fh);
      if (testchar < 1) begin
         $info("File %s is empty - aborting feed_inputs task.", file);
         return;
      end else begin
         $rewind(fh);
      end

      while (!$feof(fh)) begin
         cycles_to_wait = $urandom_range(MIN_WAIT, MAX_WAIT);
         if (HAS_LAST) begin
            $fscanf(fh, "%b %b", dat, last);
         end else begin
            $fscanf(fh, "%b", dat);
            last = 1'b0;
         end
         write_output(cycles_to_wait, dat, last);
      end
      $fclose(fh);
   endtask // feed_inputs


   task automatic feed_inputs(input string file);
      automatic int                    cycles_to_wait;

      automatic logic [DATA_W-1 : 0]   dat_array  [0 : NUM_BYTE-1];
      automatic logic [DATA_SIZE-1:0]  dat;
      automatic int                    fh;
      automatic logic                  last;
      automatic logic signed [8:0]     testchar;

      automatic int i=0;   // Index to accumulate the number of words

      fh = $fopen(file, "r");
      if (fh == 0) begin
         $display("fh: %d", fh);
         $info("File %s does not exist - aborting read_outputs task.", file);
         return;
      end
      testchar = $fgetc(fh);
      if (testchar < 1) begin
         $info("File %s is empty - aborting feed_inputs task.", file);
         return;
      end else begin
         $rewind(fh);
      end

      while (!$feof(fh)) begin
         // For NNA simulation, set this to 4 
         // cycles_to_wait = $urandom_range(MIN_WAIT, MAX_WAIT);
         cycles_to_wait = 0;//$urandom_range(0, 1);;

         if (HAS_LAST) begin
            $fscanf(fh, "%b %b", dat , last);
         end else begin
            $fscanf(fh, "%b", dat);
            last = 1'b0;
         end

         dat_array[i] = dat;
         i = i+1; // Update index

         if(i == NUM_BYTE) begin
            /*
            if(NUM_BYTE == 128) begin
               dat = { 
                        dat_array[127], dat_array[126], dat_array[125], dat_array[124],
                        dat_array[123], dat_array[122], dat_array[121], dat_array[120],
                        dat_array[119], dat_array[118], dat_array[117], dat_array[116],
                        dat_array[115], dat_array[114], dat_array[113], dat_array[112],
                        dat_array[111], dat_array[110], dat_array[109], dat_array[108],
                        dat_array[107], dat_array[106], dat_array[105], dat_array[104],
                        dat_array[103], dat_array[102], dat_array[101], dat_array[100],
                        dat_array[99], dat_array[98], dat_array[97], dat_array[96],
                        dat_array[95], dat_array[94], dat_array[93], dat_array[92],
                        dat_array[91], dat_array[90], dat_array[89], dat_array[88],
                        dat_array[87], dat_array[86], dat_array[85], dat_array[84],
                        dat_array[83], dat_array[82], dat_array[81], dat_array[80],
                        dat_array[79], dat_array[78], dat_array[77], dat_array[76],
                        dat_array[75], dat_array[74], dat_array[73], dat_array[72],
                        dat_array[71], dat_array[70], dat_array[69], dat_array[68],
                        dat_array[67], dat_array[66], dat_array[65], dat_array[64],
                        dat_array[63], dat_array[62], dat_array[61], dat_array[60],
                        dat_array[59], dat_array[58], dat_array[57], dat_array[56],
                        dat_array[55], dat_array[54], dat_array[53], dat_array[52],
                        dat_array[51], dat_array[50], dat_array[49], dat_array[48],
                        dat_array[47], dat_array[46], dat_array[45], dat_array[44],
                        dat_array[43], dat_array[42], dat_array[41], dat_array[40],
                        dat_array[39], dat_array[38], dat_array[37], dat_array[36],
                        dat_array[35], dat_array[34], dat_array[33], dat_array[32],                        
                        dat_array[31], dat_array[30], dat_array[29], dat_array[28], 
                        dat_array[27], dat_array[26], dat_array[25], dat_array[24], 
                        dat_array[23], dat_array[22], dat_array[21], dat_array[20], 
                        dat_array[19], dat_array[18], dat_array[17], dat_array[16], 
                        dat_array[15], dat_array[14], dat_array[13], dat_array[12], 
                        dat_array[11], dat_array[10], dat_array[9],  dat_array[8],
                        dat_array[7],  dat_array[6],  dat_array[5],  dat_array[4], 
                        dat_array[3],  dat_array[2],  dat_array[1],  dat_array[0] 
                     };
            end else if(NUM_BYTE == 64) begin
               dat = { 
                        dat_array[63], dat_array[62], dat_array[61], dat_array[60],
                        dat_array[59], dat_array[58], dat_array[57], dat_array[56],
                        dat_array[55], dat_array[54], dat_array[53], dat_array[52],
                        dat_array[51], dat_array[50], dat_array[49], dat_array[48],
                        dat_array[47], dat_array[46], dat_array[45], dat_array[44],
                        dat_array[43], dat_array[42], dat_array[41], dat_array[40],
                        dat_array[39], dat_array[38], dat_array[37], dat_array[36],
                        dat_array[35], dat_array[34], dat_array[33], dat_array[32],                        
                        dat_array[31], dat_array[30], dat_array[29], dat_array[28], 
                        dat_array[27], dat_array[26], dat_array[25], dat_array[24], 
                        dat_array[23], dat_array[22], dat_array[21], dat_array[20], 
                        dat_array[19], dat_array[18], dat_array[17], dat_array[16], 
                        dat_array[15], dat_array[14], dat_array[13], dat_array[12], 
                        dat_array[11], dat_array[10], dat_array[9],  dat_array[8],
                        dat_array[7],  dat_array[6],  dat_array[5],  dat_array[4], 
                        dat_array[3],  dat_array[2],  dat_array[1],  dat_array[0] 
                  };
            end else if(NUM_BYTE == 32) begin
               dat = { dat_array[31], dat_array[30], dat_array[29], dat_array[28], 
                        dat_array[27], dat_array[26], dat_array[25], dat_array[24], 
                        dat_array[23], dat_array[22], dat_array[21], dat_array[20], 
                        dat_array[19], dat_array[18], dat_array[17], dat_array[16], 
                        dat_array[15], dat_array[14], dat_array[13], dat_array[12], 
                        dat_array[11], dat_array[10], dat_array[9],  dat_array[8],
                        dat_array[7],  dat_array[6],  dat_array[5],  dat_array[4], 
                        dat_array[3],  dat_array[2],  dat_array[1],  dat_array[0] 
                  };
            end else if(NUM_BYTE == 16) begin
               dat = { dat_array[15], dat_array[14], dat_array[13], dat_array[12], 
                        dat_array[11], dat_array[10], dat_array[9],  dat_array[8],
                        dat_array[7],  dat_array[6],  dat_array[5],  dat_array[4], 
                        dat_array[3],  dat_array[2],  dat_array[1],  dat_array[0] 
                  };
            end else if(NUM_BYTE == 8) begin
               dat = { dat_array[7],  dat_array[6],  dat_array[5],  dat_array[4], 
                        dat_array[3],  dat_array[2],  dat_array[1],  dat_array[0] 
                  };
            end else if(NUM_BYTE == 4) begin
               dat = { dat_array[3],  dat_array[2],  dat_array[1],  dat_array[0] };    
            end else if(NUM_BYTE == 3) begin  
               dat = { dat_array[2],  dat_array[1],  dat_array[0] };                                       
            end else if(NUM_BYTE == 2) begin
               dat = { dat_array[1], dat_array[0]};
            end else if(NUM_BYTE == 1) begin
               dat = { dat_array[0] };
            end
            */

            for(int i=0; i<NUM_BYTE; i++) begin
               dat[ DATA_W*i +: DATA_W] = dat_array[i];
            end

            //  $display("dat=%b",dat);
            write_output(cycles_to_wait, dat, last);
            i = 0;  // Reset index
         end          
      end

      //  Attentation: This function is added to clear the last signal and data input
      clear_output( 0 );

      $fclose(fh);
   endtask // feed_inputs



   task automatic read_outputs(input string file);
      automatic int cycles_to_wait;

      //  Modify to 16-bit output verification
      //automatic logic [DATA_W-1:0] dat_expected, dat_actual;
      automatic logic [DATA_W-1 : 0]  dat_expected_array  [0 : NUM_BYTE-1];
      automatic logic [DATA_SIZE-1:0] dat_expected,   dat_actual;   //dat_expected

      automatic int fh;
      automatic logic last_expected, last_actual;
      automatic logic signed [8:0] testchar;
      fh = $fopen(file, "r");
      if (fh == 0) begin
         $display("fh: %d", fh);
         $info("File %s does not exist - aborting read_outputs task.", file);
         return;
      end
      testchar = $fgetc(fh);
      if (testchar < 0) begin
         $info("File %s is empty - aborting read_outputs task.", file);
         return;
      end else begin
         $rewind(fh);
      end

      while (!$feof(fh)) begin
         cycles_to_wait = 0; //$urandom_range(MIN_WAIT, MAX_WAIT);
         if (HAS_LAST) begin
            //  Clear dat_expected_array in case the last the block will be contaminated
            //  as the length is not times of NUM_BYTE
            dat_expected_array   = '{default:'0};

            for(int i=0; i<NUM_BYTE; i++) begin
               $fscanf(fh, "%b %b", dat_expected_array[i], last_expected);
               //$fscanf(fh, "%b %b", dat_expected[ DATA_W-i*8-1 : DATA_W-(i+1)*8 ] , last_expected);
            end

            for(int i=0; i<NUM_BYTE; i++) begin
               dat_expected[ DATA_W*i +: DATA_W] = dat_expected_array[i];
            end
            /*
            if(NUM_BYTE == 128) begin
               dat_expected = {  dat_expected_array[127], dat_expected_array[126], dat_expected_array[125], dat_expected_array[124],
                                 dat_expected_array[123], dat_expected_array[122], dat_expected_array[121], dat_expected_array[120],
                                 dat_expected_array[119], dat_expected_array[118], dat_expected_array[117], dat_expected_array[116],
                                 dat_expected_array[115], dat_expected_array[114], dat_expected_array[113], dat_expected_array[112],
                                 dat_expected_array[111], dat_expected_array[110], dat_expected_array[109], dat_expected_array[108],
                                 dat_expected_array[107], dat_expected_array[106], dat_expected_array[105], dat_expected_array[104],
                                 dat_expected_array[103], dat_expected_array[102], dat_expected_array[101], dat_expected_array[100],
                                 dat_expected_array[99], dat_expected_array[98], dat_expected_array[97], dat_expected_array[96],
                                 dat_expected_array[95], dat_expected_array[94], dat_expected_array[93], dat_expected_array[92],
                                 dat_expected_array[91], dat_expected_array[90], dat_expected_array[89], dat_expected_array[88],
                                 dat_expected_array[87], dat_expected_array[86], dat_expected_array[85], dat_expected_array[84],
                                 dat_expected_array[83], dat_expected_array[82], dat_expected_array[81], dat_expected_array[80],
                                 dat_expected_array[79], dat_expected_array[78], dat_expected_array[77], dat_expected_array[76],
                                 dat_expected_array[75], dat_expected_array[74], dat_expected_array[73], dat_expected_array[72],
                                 dat_expected_array[71], dat_expected_array[70], dat_expected_array[69], dat_expected_array[68],
                                 dat_expected_array[67], dat_expected_array[66], dat_expected_array[65], dat_expected_array[64],
                                 dat_expected_array[63], dat_expected_array[62], dat_expected_array[61], dat_expected_array[60],
                                 dat_expected_array[59], dat_expected_array[58], dat_expected_array[57], dat_expected_array[56],
                                 dat_expected_array[55], dat_expected_array[54], dat_expected_array[53], dat_expected_array[52],
                                 dat_expected_array[51], dat_expected_array[50], dat_expected_array[49], dat_expected_array[48],
                                 dat_expected_array[47], dat_expected_array[46], dat_expected_array[45], dat_expected_array[44],
                                 dat_expected_array[43], dat_expected_array[42], dat_expected_array[41], dat_expected_array[40],
                                 dat_expected_array[39], dat_expected_array[38], dat_expected_array[37], dat_expected_array[36],
                                 dat_expected_array[35], dat_expected_array[34], dat_expected_array[33], dat_expected_array[32], 
                                 dat_expected_array[31], dat_expected_array[30], dat_expected_array[29], dat_expected_array[28], 
                                 dat_expected_array[27], dat_expected_array[26], dat_expected_array[25], dat_expected_array[24], 
                                 dat_expected_array[23], dat_expected_array[22], dat_expected_array[21], dat_expected_array[20], 
                                 dat_expected_array[19], dat_expected_array[18], dat_expected_array[17], dat_expected_array[16], 
                                 dat_expected_array[15], dat_expected_array[14], dat_expected_array[13], dat_expected_array[12], 
                                 dat_expected_array[11], dat_expected_array[10], dat_expected_array[9],  dat_expected_array[8],
                                 dat_expected_array[7],  dat_expected_array[6],  dat_expected_array[5],  dat_expected_array[4], 
                                 dat_expected_array[3],  dat_expected_array[2],  dat_expected_array[1],  dat_expected_array[0] 
                              };
            end else if(NUM_BYTE == 64) begin
               dat_expected = {  dat_expected_array[63], dat_expected_array[62], dat_expected_array[61], dat_expected_array[60],
                                 dat_expected_array[59], dat_expected_array[58], dat_expected_array[57], dat_expected_array[56],
                                 dat_expected_array[55], dat_expected_array[54], dat_expected_array[53], dat_expected_array[52],
                                 dat_expected_array[51], dat_expected_array[50], dat_expected_array[49], dat_expected_array[48],
                                 dat_expected_array[47], dat_expected_array[46], dat_expected_array[45], dat_expected_array[44],
                                 dat_expected_array[43], dat_expected_array[42], dat_expected_array[41], dat_expected_array[40],
                                 dat_expected_array[39], dat_expected_array[38], dat_expected_array[37], dat_expected_array[36],
                                 dat_expected_array[35], dat_expected_array[34], dat_expected_array[33], dat_expected_array[32], 
                                 dat_expected_array[31], dat_expected_array[30], dat_expected_array[29], dat_expected_array[28], 
                                 dat_expected_array[27], dat_expected_array[26], dat_expected_array[25], dat_expected_array[24], 
                                 dat_expected_array[23], dat_expected_array[22], dat_expected_array[21], dat_expected_array[20], 
                                 dat_expected_array[19], dat_expected_array[18], dat_expected_array[17], dat_expected_array[16], 
                                 dat_expected_array[15], dat_expected_array[14], dat_expected_array[13], dat_expected_array[12], 
                                 dat_expected_array[11], dat_expected_array[10], dat_expected_array[9],  dat_expected_array[8],
                                 dat_expected_array[7],  dat_expected_array[6],  dat_expected_array[5],  dat_expected_array[4], 
                                 dat_expected_array[3],  dat_expected_array[2],  dat_expected_array[1],  dat_expected_array[0] 
                              };
            end else if(NUM_BYTE == 32) begin
               dat_expected = {  dat_expected_array[31], dat_expected_array[30], dat_expected_array[29], dat_expected_array[28],
                                 dat_expected_array[27], dat_expected_array[26], dat_expected_array[25], dat_expected_array[24], 
                                 dat_expected_array[23], dat_expected_array[22], dat_expected_array[21], dat_expected_array[20], 
                                 dat_expected_array[19], dat_expected_array[18], dat_expected_array[17], dat_expected_array[16],
                                 dat_expected_array[15], dat_expected_array[14], dat_expected_array[13], dat_expected_array[12],
                                 dat_expected_array[11], dat_expected_array[10], dat_expected_array[9], dat_expected_array[8],
                                 dat_expected_array[7], dat_expected_array[6], dat_expected_array[5], dat_expected_array[4],
                                 dat_expected_array[3], dat_expected_array[2], dat_expected_array[1], dat_expected_array[0]
                              };
            end else if(NUM_BYTE == 16) begin
               dat_expected = {  dat_expected_array[15], dat_expected_array[14], dat_expected_array[13], dat_expected_array[12],
                                 dat_expected_array[11], dat_expected_array[10], dat_expected_array[9], dat_expected_array[8],
                                 dat_expected_array[7], dat_expected_array[6], dat_expected_array[5], dat_expected_array[4],
                                 dat_expected_array[3], dat_expected_array[2], dat_expected_array[1], dat_expected_array[0]
                              };
            end else if(NUM_BYTE == 8) begin
               dat_expected = {  dat_expected_array[7], dat_expected_array[6], dat_expected_array[5], dat_expected_array[4],
                                 dat_expected_array[3], dat_expected_array[2], dat_expected_array[1], dat_expected_array[0]
                              };
            end else if(NUM_BYTE == 4) begin
               dat_expected = {  dat_expected_array[3], dat_expected_array[2], dat_expected_array[1], dat_expected_array[0] };                    
            end else if(NUM_BYTE == 2) begin
               dat_expected = {  dat_expected_array[1], dat_expected_array[0]};
            end else if(NUM_BYTE == 1) begin
               dat_expected = {  dat_expected_array[0] };
            end
            */
         end else begin
            $fscanf(fh, "%b", dat_expected);
            last_expected = 1'b0;
         end

         read_input(cycles_to_wait, dat_actual, last_actual);

         if (dat_actual != dat_expected) begin
            $error("Output data mismatch on interface %s - expected: %b    actual: %b", NAME, dat_expected, dat_actual);
            $error("Output data mismatch on interface %s - expected: %h    actual: %h", NAME, dat_expected, dat_actual);
         end

         if ((last_expected != last_actual) && HAS_LAST) begin
            $error("Output last mismatch on interface %s - expected: %b    actual %b", NAME, last_expected, last_actual);
         end
      end
      $fclose(fh);
   endtask // read_outputs

   // to be called at clock edge
   task automatic write_output(
      input int                   wait_cycles, 
      input logic [DATA_SIZE-1:0] dat, 
      input logic                 last_in
   );
      vif.vld  <= #TA 1'b0;
      for (int i=0; i<wait_cycles; i++)
         @(posedge vif.clk_i) ;
      vif.vld  <= #TA 1'b1;
      vif.data <= #TA dat;
      vif.last <= #TA last_in;
      #TT ;
      while (vif.rdy != 1) begin
         @(posedge vif.clk_i) ;
         #TT ;
      end
      @(posedge vif.clk_i) ;
      vif.vld  <= #TA 1'b0;
   endtask // write_input

   // To clear the output
   task automatic clear_output(
      input int wait_cycles
   );
      vif.vld <= #TA 1'b0;
      for (int i=0; i<wait_cycles; i++)
         @(posedge vif.clk_i) ;
      vif.vld  <= #TA 1'b0;
      vif.data <= #TA '0;
      vif.last <= #TA 1'b0;
      #TT ;
   endtask // write_input


   task automatic read_input(
      input int                       wait_cycles, 
      output logic [DATA_SIZE-1:0]    dat, 
      output logic                    last_o
   );
      vif.rdy <= #TA 1'b0;
      for (int i=0; i<wait_cycles; i++)
         @(posedge vif.clk_i) ;
      vif.rdy <= #TA 1'b1;
      #TT ;
      while (vif.vld != 1) begin
         @(posedge vif.clk_i) ;
         #TT ;
      end
      dat = vif.data;
      last_o = vif.last;
      @(posedge vif.clk_i) ;
      vif.rdy <= #TA 1'b0;
   endtask // read_output

   task automatic reset_out();
      vif.vld  <= 1'b0;
      vif.data <= 'd0;
      vif.last <= 1'b0;
   endtask // reset_out

   task automatic reset_in();
      vif.rdy <= 1'b0;
   endtask // reset_in

endclass // HandshakeWrDrv

endpackage
