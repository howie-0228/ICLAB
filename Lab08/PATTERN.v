/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define PATNUM 500
`endif
`ifdef GATE
    `define PATNUM 100
`endif

`define SEED 564

module PATTERN(
    // Output signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    // Input signals
    out_valid,
    out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [3:0] T;
output reg signed [7:0] in_data;
output reg signed [7:0] w_Q;
output reg signed [7:0] w_K;
output reg signed [7:0] w_V;

input out_valid;
input signed [63:0] out_data;

//================================================================
// Clock
//================================================================
real CYCLE = 50.0; 
initial clk = 0;
always #(CYCLE/2) clk = ~clk;

parameter PATNUM = `PATNUM;
parameter PRE_SHOWDATA = 1; // turned on to show the input info WHETHER the answer is o/x
integer SEED = `SEED;
integer latency;
integer total_latency;
integer patcount;
integer x;
integer i,j,k, idx, jdx, kdx;
integer t ;
integer file;
integer op,po;
//================================================================
// Wire & Reg Declaration
//================================================================
reg signed [7:0] Q[0:7][0:7],K[0:7][0:7],V[0:7][0:7];
reg signed [7:0] in[0:7][0:7];
reg signed [63:0] result_K[0:7][0:7],result_Q[0:7][0:7],result_V[0:7][0:7];
reg signed [63:0] result_A[0:7][0:7],S[0:7][0:7],scaled_value,P[0:7][0:7];


always @(*) begin
    if(in_valid && out_valid)begin
        $display("========================================================================");
        $display("                           FAIL!                                  ");
        $display("            in_valid and out_valid overlap at %t    ",$time);
        $display("========================================================================");
    end
end

always @(negedge clk) begin
	if(out_valid === 0)begin
		if(out_data !== 0)begin
			$display("********************************************************");     
			$display("                          FAIL!                           ");
			$display("  The out_valid is 0, but your out_data is not 0  ");
			$display("********************************************************");
			$finish;
		end
	end
end

initial begin
	patcount = 0;
	cg_en = 1'b0;
	rst_n = 1'b1;
	in_valid = 1'b0;
    
	
	w_Q = 'bx;
    w_K = 'bx;
    w_V = 'bx;
    in_data = 'bx;

	force clk = 0;

	total_latency = 0;
	reset_signal_task;
	repeat(4) @(negedge clk);
	file = $fopen("../00_TESTBED/debug.txt", "w");
	for(patcount = 0; patcount < PATNUM; patcount = patcount+1)begin
		gen_data;
		input_task;
		calculate_ans;
		if(PRE_SHOWDATA) print_data;
		wait_OUT_VALID;
		check_ans;
		repeat(($random(SEED)%'d3) + 2) @(negedge clk);
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mExecution Cycle: %3d \033[0m", patcount + 1, latency);
	end
	YOU_PASS_task;

end

task reset_signal_task; begin 
  #(0.5);  rst_n=0;
  #(CYCLE/2);
  if((out_valid !== 0)||(out_data !== 0)) begin
    $display("========================================================================");
    $display("                           FAIL!                                  ");
    $display("   Output signal should be 0 after initial RESET at %t    ",$time);
    $display("========================================================================");
    $finish;
  end
  #(3*CYCLE);  rst_n=1;
  #(CYCLE/2);  release clk;
end endtask

task gen_data; begin
		for(idx = 0; idx < 8; idx = idx+1)begin
			for(jdx = 0; jdx < 8; jdx = jdx+1)begin
				Q[idx][jdx] = $random(SEED) % 256;
				K[idx][jdx] = $random(SEED) % 256;
                V[idx][jdx] = $random(SEED) % 256;
                in[idx][jdx] = $random(SEED) % 256;
				// Q[idx][jdx] = -128;
				// K[idx][jdx] = 127;
				// V[idx][jdx] = -128;
				// in[idx][jdx] = -128;
			end
		end
end endtask

task input_task; begin
    
	in_valid = 1;
    t = $random(SEED) % 'd3;
	// t = 2;
    if(t == 0)   t = 1;
    else if(t==1)t = 4;
    else         t = 8;
	for(i = 0; i < 64; i = i+1)begin
        T = (i == 0) ? t : 'bx;
		w_Q = Q[i/8][i%8];
        in_data = (i<8*t) ? in[i/8][i%8]:'bx;
		

		@(negedge clk);
	end
    w_Q = 'bx;
	in_data = 'bx;
	for(i = 0; i < 64; i = i+1)begin
		w_K = K[i/8][i%8];
		@(negedge clk);
	end
    w_K = 'bx;
    for(i = 0; i < 64; i = i+1)begin
		w_V = V[i/8][i%8];
		@(negedge clk);
	end
    w_V = 'bx;


	in_valid = 1'b0;
	
end endtask
task calculate_ans; begin
	for(i=0;i<8;i=i+1)begin
		for(j=0;j<8;j=j+1)begin
			result_Q[i][j] = 0;
			result_K[i][j] = 0;
			result_V[i][j] = 0;
			result_A[i][j] = 0;
			S[i][j] = 0;
		end
	end
	case (t)
	1: begin 
        for (j = 0; j < 8; j = j + 1) begin
            for (k = 0; k < 8; k = k + 1) begin
                result_Q[0][j] = result_Q[0][j] + in[0][k] * Q[k][j];
				result_K[0][j] = result_K[0][j] + in[0][k] * K[k][j];
				result_V[0][j] = result_V[0][j] + in[0][k] * V[k][j];
            end
        end
    end

    4: begin 
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k = k + 1) begin
                    result_Q[i][j] = result_Q[i][j] + in[i][k] * Q[k][j];
					result_K[i][j] = result_K[i][j] + in[i][k] * K[k][j];
					result_V[i][j] = result_V[i][j] + in[i][k] * V[k][j];
                end
            end
        end
    end

    8: begin 
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k = k + 1) begin
                    result_Q[i][j] = result_Q[i][j] + in[i][k] * Q[k][j];
					result_K[i][j] = result_K[i][j] + in[i][k] * K[k][j];
					result_V[i][j] = result_V[i][j] + in[i][k] * V[k][j];
                end
            end
        end
    end
    endcase
	case (t)
    1: begin 
        for (j = 0; j < 8; j = j + 1) begin 
            for (k = 0; k < 8; k = k + 1) begin
                result_A[0][j] = result_A[0][j] + result_Q[0][k] * result_K[j][k]; 
            end
        end
    end
    4: begin 
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k = k + 1) begin
                    result_A[i][j] = result_A[i][j] + result_Q[i][k] * result_K[j][k]; 
                end
            end
        end
    end

    8: begin 
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k = k + 1) begin
                    result_A[i][j] = result_A[i][j] + result_Q[i][k] * result_K[j][k]; 
                end
            end
        end
    end
	endcase
	for (i = 0; i < 8; i = i + 1) begin
		for (j = 0; j < 8; j = j + 1) begin
			scaled_value = result_A[i][j] / 3;
			if (scaled_value < 0) begin
				S[i][j] = 0;
			end else begin
				S[i][j] = scaled_value;
			end
		end
	end


	for (i = 0; i < t; i = i + 1) begin
		for (j = 0; j < 8; j = j + 1) begin
			P[i][j] = 0; 
			for (k = 0; k < t; k = k + 1) begin
				P[i][j] = P[i][j] + S[i][k] * result_V[k][j];
			end
		end
	end
end endtask
task print_data;begin
		$fwrite(file, "===========  PATTERN NO.%4d  ==============\n", patcount+1);
    
        $fwrite(file, "==========  in data  ==============\n");
        for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", in[i][j]);
            end
            $fwrite(file, "\n");
         end
        $fwrite(file, "===========    Q     ============\n");
        for(integer i = 0; i < 8; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", Q[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "===========    K     ============\n");
        for(integer i = 0; i < 8; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", K[i][j]);
            end
            $fwrite(file, "\n");
        end
		$fwrite(file, "===========    V     ============\n");
        for(integer i = 0; i < 8; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", V[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
		$fwrite(file, "===========  result Q  ==============\n");
		for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", result_Q[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
		$fwrite(file, "===========  result K  ==============\n");
		for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", result_K[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
		$fwrite(file, "===========  result V  ==============\n");
		for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%10d ", result_V[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
		$fwrite(file, "===========  result A  ==============\n");
		for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < t; j = j + 1) begin
                $fwrite(file, "%10d ", result_A[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
		$fwrite(file, "===========  result RELU  ==============\n");
		for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < t; j = j + 1) begin
                $fwrite(file, "%10d ", S[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
		$fwrite(file, "===========  result OUT  ==============\n");
		for(integer i = 0; i < t; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                $fwrite(file, "%20d ", P[i][j]);
            end
            $fwrite(file, "\n");
        end
        $fwrite(file, "\n");
end endtask
task wait_OUT_VALID; begin
  latency = 0;
  while(out_valid !== 1) begin
	latency = latency + 1;
	if(latency == 2000) begin//wait limit
    	$display ("========================================================================");
    	$display("                       FAIL!                 ");
		$display("         The execution latency are over 2000 cycles.         ");
    	$display ("========================================================================");
		repeat(5)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  total_latency = total_latency + latency;
end endtask
task check_ans; begin
	case(t)
	1:begin
		for(i=0;i<8;i=i+1)begin
			if(out_data !== P[i/8][i%8])begin
				$display("********************************************************");     
				$display("                          FAIL!                           ");
				$display("  The golden_out_data is %d, but your out_data is %d  ", P[i/8][i%8], out_data);
				$display("********************************************************");
				repeat (2) @(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	end
	4:begin
		for(i=0;i<32;i=i+1)begin
			if(out_data !== P[i/8][i%8])begin
				$display("********************************************************");     
				$display("                          FAIL!                           ");
				$display("  The golden_out_data is %d, but your out_data is %d  ", P[i/8][i%8], out_data);
				$display("********************************************************");
				repeat (2) @(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	end
	8:begin
		for(i=0;i<64;i=i+1)begin
			if(out_data !== P[i/8][i%8])begin
				$display("********************************************************");     
				$display("                          FAIL!                           ");
				$display("  The golden_out_data is %d, but your out_data is %d  ", P[i/8][i%8], out_data);
				$display("********************************************************");
				repeat (2) @(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	end
	endcase

    
end endtask
task YOU_PASS_task; begin
    $display ("========================================================================");
    $display ("                           Congratulations!                           ");
    $display ("                    You have PASSED all %8d patterns!                     " ,PATNUM);
	$display ("                    The total execution latency is %8d cycles!                     ", total_latency);
    $display ("========================================================================");      
    
    #(500);
    $finish;
end endtask


endmodule
