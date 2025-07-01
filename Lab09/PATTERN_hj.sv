
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
`define cycle_time 15.0
`define SEEDS 3000
`define PAT_NUM_define 5400

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
integer SEED = `SEEDS;
parameter PAT_NUM = `PAT_NUM_define;
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;
parameter BASE_Addr = 65536 ;
int total_latency, latency;
int i_pat;

real CYCLE = `cycle_time;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box

//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Index_Check, Update, Check_Valid_Date};
    }
endclass

random_act act_PATTERN = new(); 

class random_data_number;
    randc Data_No data_number_id;
    constraint data_number_constraint {
        data_number_id inside{[0:255]};
    }
endclass

random_data_number data_number_PATTERN = new(); 

class random_index;
    randc Index index_id;
    constraint index_constraint {
        index_id inside{[0:4095]};
    }
endclass

random_index index_A_PATTERN = new();
random_index index_B_PATTERN = new();
random_index index_C_PATTERN = new();
random_index index_D_PATTERN = new();

class random_formula;
    randc Formula_Type formula_id;
    constraint formula_constraint {
        formula_id inside{Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
    }
endclass

random_formula formula_PATTERN = new(); 


class random_mode;
    randc Mode mode_id;
    constraint mode_constraint {
        mode_id inside{Insensitive, Normal, Sensitive};
    }
endclass

random_mode mode_PATTERN = new(); 


class random_date;
	rand Month month_id;
    rand Day day_id;
	function new (int seed);
		this.srandom(seed);
	endfunction

	constraint limit {
        month_id inside {[1:12]};
        if (month_id == 1 || month_id == 3 || month_id == 5 || month_id == 7 || month_id == 8 || month_id == 10 || month_id == 12)
            day_id inside {[1:31]};
        else if (month_id == 4 || month_id == 6 || month_id == 9 || month_id == 11)
            day_id inside {[1:30]};
        else if (month_id == 2)
            day_id inside {[1:28]};
    }
endclass
random_date date_PATTERN = new(SEED) ;


class random_dalay;
	rand int delay;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { delay inside {[0:3]}; }
endclass
random_dalay delay_PATTERN = new(SEED) ;


//================================================================
//  initial
//================================================================

initial begin
	$readmemh(DRAM_p_r, golden_DRAM);
	reset_signal_task;
	
    i_pat = 0;
    total_latency = 0;
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        act_PATTERN.randomize();
		case(act_PATTERN.act_id)
			Index_Check:
            begin
				index_check_task;
			end
			Update:
            begin
				update_task;
			end
			Check_Valid_Date:
            begin
				check_valid_date_task;
			end
		endcase

        wait_out_valid_task;
		check_output_task;

        $display("PASS PATTERN NO.%d", i_pat);
    end                                                       
    YOU_PASS_task;
end

task reset_signal_task; begin 
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.formula_valid = 1'b0;
    inf.mode_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.data_no_valid = 1'b0;
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    total_latency = 0;

    #CYCLE; inf.rst_n = 0; 
    #CYCLE; inf.rst_n = 1;

    if(inf.out_valid !== 'b0 || inf.warn_msg !=='b0 || inf.complete !=='b0) begin //out!==0
		// $display ("Wrong Answer");
        $display ("output isn't reset");
        repeat(2) #CYCLE;
        // $finish;
    end
	#CYCLE;

end endtask

integer j;
int delay_now;
task wait_1_4_cycle_task;
begin
	delay_PATTERN.randomize();
    delay_now = delay_PATTERN.delay;
	for( j=0 ; j<delay_PATTERN.delay ; j++ )
    begin
        @(negedge clk);
    end
end
endtask


//==============================================//
//                 Get_Dram_Data                //
//==============================================//

logic [12:0] index_A_DRAM, index_B_DRAM, month_DRAM, index_C_DRAM, index_D_DRAM, day_DRAM;

task get_dram_data_task; begin
    index_A_DRAM = {golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 7]     ,golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id*8 + 6][7:4]};
    index_B_DRAM = {golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 6][3:0],golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id*8 + 5]};
    month_DRAM   =  golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 4];
    index_C_DRAM = {golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 3]     ,golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id*8 + 2][7:4]};
    index_D_DRAM = {golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 2][3:0],golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id*8 + 1]};
    day_DRAM     =  golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 0];
end endtask



//==============================================//
//                  INDEX CHECK                 //
//==============================================//
Index max_AB, min_AB, max_CD, min_CD, max_I, min_I;
logic [12:0] I_sub_TI [0:3];
Index G_A, G_B, G_C, G_D;
Index max_G_AB, min_G_AB, max_G_CD, min_G_CD, max_G, second_G, third_G, min_G;
logic [12:0] result;
logic [11:0] formula_threshold;


task index_check_task; begin
    //give action
    @(negedge clk);
    inf.sel_action_valid = 1'b1;
    inf.D = {70'bX,act_PATTERN.act_id};
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give formula
    formula_PATTERN.randomize();
    inf.formula_valid = 1'b1;
    inf.D = {69'bX,formula_PATTERN.formula_id};
    @(negedge clk);
    inf.formula_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give mode
    mode_PATTERN.randomize();
    inf.mode_valid = 1'b1;
    inf.D = {70'bX,mode_PATTERN.mode_id};
    @(negedge clk);
    inf.mode_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give today's date
    date_PATTERN.randomize();
    inf.date_valid = 1'b1;
    inf.D = {63'bX,date_PATTERN.month_id, date_PATTERN.day_id};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give data_no
    data_number_PATTERN.randomize();
    inf.data_no_valid = 1'b1;
    inf.D = {64'bX,data_number_PATTERN.data_number_id};
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index A
    index_A_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_A_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index B
    index_B_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_B_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index C
    index_C_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_C_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index D
    index_D_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_D_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
 
    //start to calculate golden answer

    get_dram_data_task;

    max_AB = (index_A_DRAM > index_B_DRAM) ? index_A_DRAM : index_B_DRAM;
    min_AB = (index_A_DRAM > index_B_DRAM) ? index_B_DRAM : index_A_DRAM;
    max_CD = (index_C_DRAM > index_D_DRAM) ? index_C_DRAM : index_D_DRAM;
    min_CD = (index_C_DRAM > index_D_DRAM) ? index_D_DRAM : index_C_DRAM;
    max_I = (max_AB > max_CD) ? max_AB : max_CD;
    min_I = (min_AB > min_CD) ? min_CD : min_AB;

    I_sub_TI[0] = index_A_DRAM - index_A_PATTERN.index_id;
    I_sub_TI[1] = index_B_DRAM - index_B_PATTERN.index_id;
    I_sub_TI[2] = index_C_DRAM - index_C_PATTERN.index_id;
    I_sub_TI[3] = index_D_DRAM - index_D_PATTERN.index_id;

    G_A = (I_sub_TI[0][12]) ? ~I_sub_TI[0] + 1'b1 : I_sub_TI[0];
    G_B = (I_sub_TI[1][12]) ? ~I_sub_TI[1] + 1'b1 : I_sub_TI[1];
    G_C = (I_sub_TI[2][12]) ? ~I_sub_TI[2] + 1'b1 : I_sub_TI[2];
    G_D = (I_sub_TI[3][12]) ? ~I_sub_TI[3] + 1'b1 : I_sub_TI[3];

    max_G_AB = (G_A > G_B) ? G_A : G_B;
    min_G_AB = (G_A > G_B) ? G_B : G_A;
    max_G_CD = (G_C > G_D) ? G_C : G_D;
    min_G_CD = (G_C > G_D) ? G_D : G_C;
    max_G = (max_G_AB > max_G_CD) ? max_G_AB : max_G_CD;
    second_G = (max_G_AB > max_G_CD) ? max_G_CD : max_G_AB;
    third_G = (min_G_AB > min_G_CD) ? min_G_AB : min_G_CD;
    min_G = (min_G_AB > min_G_CD) ? min_G_CD : min_G_AB;

    //calc formula threshold
    case (formula_PATTERN.formula_id)
        Formula_A: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 2047;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 1023;
            end
            else begin
                formula_threshold = 511;
            end
        end
        Formula_B: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 800;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 400;
            end
            else begin
                formula_threshold = 200;
            end
        end
        Formula_C: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 2047;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 1023;
            end
            else begin
                formula_threshold = 511;
            end
        end
        Formula_D: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 3;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 2;
            end
            else begin
                formula_threshold = 1;
            end
        end
        Formula_E: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 3;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 2;
            end
            else begin
                formula_threshold = 1;
            end
        end
        Formula_F: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 800;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 400;
            end
            else begin
                formula_threshold = 200;
            end
        end
        Formula_G: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 800;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 400;
            end
            else begin
                formula_threshold = 200;
            end
        end
        Formula_H: begin
            if (mode_PATTERN.mode_id == Insensitive) begin
                formula_threshold = 800;
            end
            else if (mode_PATTERN.mode_id == Normal) begin
                formula_threshold = 400;
            end
            else begin
                formula_threshold = 200;
            end
        end
        default: formula_threshold = 0;
    endcase

    //calc result
    case (formula_PATTERN.formula_id) 
        Formula_A: begin
            result = (index_A_DRAM + index_B_DRAM + index_C_DRAM + index_D_DRAM) /4;
        end
        Formula_B: begin
            result = max_I - min_I;
        end
        Formula_C: begin
            result = min_I;
        end
        Formula_D: begin
            result = (index_A_DRAM >= 2047) + (index_B_DRAM >= 2047) + (index_C_DRAM >= 2047) + (index_D_DRAM >= 2047);
        end
        Formula_E: begin
            result = (index_A_DRAM >= index_A_PATTERN.index_id) + (index_B_DRAM >= index_B_PATTERN.index_id) + (index_C_DRAM >= index_C_PATTERN.index_id) + (index_D_DRAM >= index_D_PATTERN.index_id);
        end
        Formula_F: begin
            result = (min_G + second_G + third_G) /3;
        end
        Formula_G: begin
            result = (min_G >> 1) + (second_G >> 2) + (third_G >> 2);
        end
        Formula_H: begin
            result = (G_A + G_B + G_C + G_D) / 4;
        end
    endcase
end endtask

//==============================================//
//                    UPDATE                    //
//==============================================//
logic [11:0] update_dram_index_A, update_dram_index_B, update_dram_index_C, update_dram_index_D;
logic [12:0] variation_index_A_PATTERN, variation_index_B_PATTERN, variation_index_C_PATTERN, variation_index_D_PATTERN;
logic [12:0] signed_index_A_PATTERN, signed_index_B_PATTERN, signed_index_C_PATTERN, signed_index_D_PATTERN;
logic overflow_A, overflow_B, overflow_C, overflow_D;


task update_task; begin
    //give action
    @(negedge clk);
    inf.sel_action_valid = 1'b1;
    inf.D = {70'bX,act_PATTERN.act_id};
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give today's date
    date_PATTERN.randomize();
    inf.date_valid = 1'b1;
    inf.D = {63'bX,date_PATTERN.month_id, date_PATTERN.day_id};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give data_no
    data_number_PATTERN.randomize();
    inf.data_no_valid = 1'b1;
    inf.D = {64'bX,data_number_PATTERN.data_number_id};
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index A
    index_A_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_A_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index B
    index_B_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_B_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index C
    index_C_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_C_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give index D
    index_D_PATTERN.randomize();
    inf.index_valid = 1'b1;
    inf.D = {60'bX,index_D_PATTERN.index_id};
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //start to calculate golden answer
    get_dram_data_task;

    signed_index_A_PATTERN = $signed(index_A_PATTERN.index_id);
    signed_index_B_PATTERN = $signed(index_B_PATTERN.index_id);
    signed_index_C_PATTERN = $signed(index_C_PATTERN.index_id);
    signed_index_D_PATTERN = $signed(index_D_PATTERN.index_id);

    variation_index_A_PATTERN = index_A_DRAM + signed_index_A_PATTERN;
    variation_index_B_PATTERN = index_B_DRAM + signed_index_B_PATTERN;
    variation_index_C_PATTERN = index_C_DRAM + signed_index_C_PATTERN;
    variation_index_D_PATTERN = index_D_DRAM + signed_index_D_PATTERN;

    if (variation_index_A_PATTERN[12]) begin
        overflow_A = 1'b1;
    end
    else begin
        overflow_A = 1'b0;
    end

    if (variation_index_B_PATTERN[12]) begin
        overflow_B = 1'b1;
    end
    else begin
        overflow_B = 1'b0;
    end

    if (variation_index_C_PATTERN[12]) begin
        overflow_C = 1'b1;
    end
    else begin
        overflow_C = 1'b0;
    end

    if (variation_index_D_PATTERN[12]) begin
        overflow_D = 1'b1;
    end
    else begin
        overflow_D = 1'b0;
    end

    if (overflow_A == 1) begin
        if (index_A_PATTERN.index_id[11]) begin
            update_dram_index_A = 0;
        end
        else begin
            update_dram_index_A = 4095;
        end
    end
    else begin
        update_dram_index_A = variation_index_A_PATTERN;
    end

    if (overflow_B == 1) begin
        if (index_B_PATTERN.index_id[11]) begin
            update_dram_index_B = 0;
        end
        else begin
            update_dram_index_B = 4095;
        end
    end
    else begin
        update_dram_index_B = variation_index_B_PATTERN;
    end

    if (overflow_C == 1) begin
        if (index_C_PATTERN.index_id[11]) begin
            update_dram_index_C = 0;
        end
        else begin
            update_dram_index_C = 4095;
        end
    end
    else begin
        update_dram_index_C = variation_index_C_PATTERN;
    end

    if (overflow_D == 1) begin
        if (index_D_PATTERN.index_id[11]) begin
            update_dram_index_D = 0;
        end
        else begin
            update_dram_index_D = 4095;
        end
    end
    else begin
        update_dram_index_D = variation_index_D_PATTERN;
    end

    write_back_dram_task;
end endtask

//==============================================//
//                 Write_Dram_Data              //
//==============================================//

task write_back_dram_task; begin
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 7] = update_dram_index_A[11:4];
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 6] = {update_dram_index_A[3:0], update_dram_index_B[11:8]};
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 5] = update_dram_index_B[7:0];
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 4] = {4'b0,date_PATTERN.month_id};
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 3] = update_dram_index_C[11:4];
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 2] = {update_dram_index_C[3:0], update_dram_index_D[11:8]};
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 1] = update_dram_index_D[7:0];
    golden_DRAM[BASE_Addr + data_number_PATTERN.data_number_id *8 + 0] = {3'b0,date_PATTERN.day_id};
end endtask


//==============================================//
//              CHECK VALID DATE                //
//==============================================//

task check_valid_date_task; begin
    //give action
    @(negedge clk);
    inf.sel_action_valid = 1'b1;
    inf.D = {70'bX,act_PATTERN.act_id};
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give today's date
    date_PATTERN.randomize();
    inf.date_valid = 1'b1;
    inf.D = {63'bX,date_PATTERN.month_id, date_PATTERN.day_id};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //give data_no
    data_number_PATTERN.randomize();
    inf.data_no_valid = 1'b1;
    inf.D = {64'bX,data_number_PATTERN.data_number_id};
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
    wait_1_4_cycle_task;

    //start to calculate golden answer
    get_dram_data_task;
end endtask





task wait_out_valid_task; begin
    latency = 1;
    while(inf.out_valid !== 1'b1) begin
	    latency = latency + 1;
        if( latency == MAX_CYCLE) begin
            // $display ("Wrong Answer");
			$display (" exceed MAX_CYCLE");
	        repeat(2)@(negedge clk);
	        // $finish;
        end
		@(negedge clk);
	end
	total_latency = total_latency + latency;
end endtask

Warn_Msg error_msg;
logic complete;

task check_output_task; begin
	case(act_PATTERN.act_id)
			Index_Check: begin
				if((date_PATTERN.month_id < month_DRAM) ||(date_PATTERN.month_id == month_DRAM && date_PATTERN.day_id < day_DRAM)) begin
                    complete = 1'b0;
                    error_msg  = Date_Warn;
                end
                else if (result >= formula_threshold) begin
                    complete = 1'b0;
                    error_msg  = Risk_Warn;
                end
                else begin
                    complete = 1'b1;
                    error_msg  = No_Warn;
                end 
			end
			Update: begin
                if (overflow_A || overflow_B || overflow_C || overflow_D) begin
                    complete = 1'b0;
                    error_msg  = Data_Warn;
                end
                else begin
                    complete = 1'b1;
                    error_msg  = No_Warn;
                end 
			end
			Check_Valid_Date: begin
                if((date_PATTERN.month_id < month_DRAM) ||(date_PATTERN.month_id == month_DRAM && date_PATTERN.day_id < day_DRAM)) begin
                    complete = 1'b0;
                    error_msg  = Date_Warn;
                end
                else begin
                    complete = 1'b1;
                    error_msg  = No_Warn;
                end 
			end
	endcase
    if (inf.warn_msg !== error_msg || inf.complete !== complete) begin
        $display ("Wrong Answer");
        // $display ("output isn't correct");
        repeat(2)@(negedge clk);
        $finish;
    end

    wait_1_4_cycle_task;

end endtask


task YOU_PASS_task; begin
	$display("Congratulations");
	$display("execution cycles = %7d", total_latency);
	$display("clock period = %4fns", CYCLE);
    $finish;
end endtask

endprogram
