// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

`define PATNUM  5400
`define SEED 5487
`define CYCLE_TIME 15.0

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;

integer  BASE_ADDR = 65536;

integer out_valid_cycle_cnt;

integer   i_pat;
integer   i;
integer   latency;
integer   total_latency;
integer   SEEDS = `SEED;
integer   TOTAL_PATNUM = `PATNUM;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box

reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

Action act_reg;
Formula_Type formula_reg;
Mode mode_reg;
Date date_reg;
Data_No data_no_reg;
Index index_reg;
Index index_ABCD_reg [0:3];
logic signed [11:0] index_ABCD_reg_signed [0:3];
Index G_reg[0:3];
Data_Dir data_dir_reg;
logic [11:0] dram_index[0:3];
logic signed[12:0] variation_result[0:3];
logic [11:0] golden_variation[0:3];

logic [7:0] data_write_to_dram[0:7];

logic [31:0] Index_check_task_cnt;


logic golden_complete;
Warn_Msg golden_warn_msg;
logic [63:0] golden_result;
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
//================================================================
// Initial Block
//================================================================
initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    inf.rst_n = 1;
    inf.sel_action_valid = 0;
    inf.formula_valid = 0;
    inf.mode_valid = 0;
    inf.date_valid = 0;
    inf.data_no_valid = 0;
    inf.index_valid = 0;

    inf.D = 'bx;
    //rst_n
    #(1.0);	inf.rst_n = 0 ;
	#(`CYCLE_TIME*2);
    inf.rst_n = 1 ;

    total_latency = 0;
    Index_check_task_cnt = 0;
    for(i_pat=0; i_pat<TOTAL_PATNUM; i_pat++) begin
        Act_task;
        // $display("1");
        case (act_reg)
            Index_Check: begin
                Index_check_task;
            end
            Update: begin
                Update_task;
            end
            Check_Valid_Date: begin
                Check_Valid_Date_task;
            end 
        endcase
        // $display("2");
        Cal_ans_task;
        // $display("3");
        Update_Dram_Task;
        // $display("4");
        Wait_outvalid_task;
        // $display("5");
        Check_ans_task;
        // $display("6");
        total_latency = total_latency + latency;
        $display("%0sPASS PATTERN NO.%4d %0sCycles: %3d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
        @(negedge clk);
    end
    YOU_PASS_task;
end



//================================================================
// Delay Task
//================================================================
    class delay_1_to_4;
        rand int delay;
        function new(int seed);
            this.srandom(seed);
        endfunction //new()
        constraint delay_c{
            delay inside{0};
        }
    endclass //delay_1_to_4
    delay_1_to_4 delay_1_to_4_obj = new(SEEDS);

    task delay_task;begin
        delay_1_to_4_obj.randomize();
        for(i=0; i<delay_1_to_4_obj.delay; i++) begin
            @(negedge clk);
        end
    end endtask //delay_task

    // class delay_for_index;
    //     rand int delay;
    //     function new(int seed);
    //         this.srandom(seed);
    //     endfunction //new()
    //     constraint delay_c{
    //         delay inside{0,1,2,3};
    //     }
    // endclass //delay_for_index
    // delay_for_index delay_for_index_obj = new(SEEDS);

    // task delay_for_index_task;begin
    //     delay_for_index_obj.randomize();
    //     for(i=0; i<delay_for_index_obj.delay; i++) begin
    //         @(negedge clk);
    //     end
    // end endtask //delay_for_index_task
//================================================================
// Act Task
//================================================================
    task Act_task;begin
        delay_task;
        if(i_pat < 2700)begin
            case (i_pat % 9)
                0: act_reg = Index_Check;//0
                1: act_reg = Update;//1
                2: act_reg = Update;//1
                3: act_reg = Index_Check;//0
                4: act_reg = Check_Valid_Date;//2
                5: act_reg = Check_Valid_Date;//2
                6: act_reg = Update;//1
                7: act_reg = Check_Valid_Date;//2
                8: act_reg = Index_Check;//0
            endcase
        end
        else 
            act_reg = Index_Check;
        if(act_reg == Index_Check)
            Index_check_task_cnt = Index_check_task_cnt + 1;
        inf.sel_action_valid = 1;
        inf.D = act_reg;
        @(negedge clk);
        inf.sel_action_valid = 0;
        inf.D = 'bx;
    end endtask //Act_task
//================================================================
// Formula Task
//================================================================
    task Formula_task;begin
        delay_task;
        case (Index_check_task_cnt / 450)
            0: formula_reg = Formula_A; 
            1: formula_reg = Formula_B;
            2: formula_reg = Formula_C;
            3: formula_reg = Formula_D;
            4: formula_reg = Formula_E;
            5: formula_reg = Formula_F;
            6: formula_reg = Formula_G;
            7: formula_reg = Formula_H;
            default: formula_reg = Formula_A;
        endcase
        inf.formula_valid = 1;
        inf.D = formula_reg;
        @(negedge clk);
        inf.formula_valid = 0;
        inf.D = 'bx;
    end endtask //Formula_task
//================================================================
// Mode Task
//================================================================
    task Mode_task;begin
        delay_task;
        case (Index_check_task_cnt % 3)
            1: mode_reg = Insensitive; 
            2: mode_reg = Normal;
            0: mode_reg = Sensitive;
            default: mode_reg = Insensitive;
        endcase
        inf.mode_valid = 1;
        inf.D = mode_reg;
        @(negedge clk);
        inf.mode_valid = 0;
        inf.D = 'bx;
    end endtask //Mode_task
//================================================================
// Date Task
//================================================================
    class rand_date;
        rand Month M;
        rand Day D;
        function new(int seed);
            this.srandom(seed);
        endfunction //new()
        constraint range{
            M inside{1,2,3,4,5,6,7,8,9,10,11,12};
            if(M == 1 || M == 3 || M == 5 || M == 7 || M == 8 || M == 10 || M == 12)
                D inside{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
            else if(M == 4 || M == 6 || M == 9 || M == 11)
                D inside{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30};
            else
                D inside{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28};
        }
    endclass //rand_date
    rand_date rand_date_obj = new(SEEDS);
    task Date_task;begin
        delay_task;
        inf.date_valid = 1;
        rand_date_obj.randomize();
        date_reg.M = rand_date_obj.M;
        date_reg.D = rand_date_obj.D;
        inf.D = {date_reg.M , date_reg.D};
        @(negedge clk);
        inf.date_valid = 0;
        inf.D = 'bx;
    end endtask //Date_task
//================================================================
// Data No Task
//================================================================
    class rand_data_no;
        rand Data_No data_no;
        function new(int seed);
            this.srandom(seed);
        endfunction //new()
        constraint range{
            data_no inside{[0:255]};
        }
    endclass //rand_data_no
    rand_data_no rand_data_no_obj = new(SEEDS);
    task Data_No_task;begin
        delay_task;
        inf.data_no_valid = 1;
        rand_data_no_obj.randomize();
        data_no_reg = rand_data_no_obj.data_no;
        inf.D = data_no_reg;
        @(negedge clk);
        inf.data_no_valid = 0;
        inf.D = 'bx;
    end endtask //Data_No_task
//================================================================
// Index Task
//================================================================
    class rand_index;
        rand Index index;
        function new(int seed);
            this.srandom(seed);
        endfunction //new()
        constraint range{
            index inside{[0:4095]};
        }
    endclass //rand_index
    rand_index rand_index_obj = new(SEEDS);
    task Index_task;begin
        delay_task;
        inf.index_valid = 1;
        rand_index_obj.randomize();
        index_reg = rand_index_obj.index;
        inf.D = index_reg;
        @(negedge clk);
        inf.index_valid = 0;
        inf.D = 'bx;
    end endtask //Index_task
//================================================================
// Index Check Task
//================================================================
    task Index_check_task;begin
        Formula_task;
        Mode_task;
        Date_task;
        Data_No_task;
        Get_Dram_data_task;
        Index_task;
        index_ABCD_reg[0] = index_reg;
        Index_task;
        index_ABCD_reg[1] = index_reg;
        Index_task;
        index_ABCD_reg[2] = index_reg;
        Index_task;
        index_ABCD_reg[3] = index_reg;
    end endtask //Index_check_task
//================================================================
// Update Task
//================================================================
    task Update_task;begin
        Date_task;
        Data_No_task;
        Get_Dram_data_task;
        Index_task;
        index_ABCD_reg[0] = index_reg;
        Index_task;
        index_ABCD_reg[1] = index_reg;
        Index_task;
        index_ABCD_reg[2] = index_reg;
        Index_task;
        index_ABCD_reg[3] = index_reg;
        index_ABCD_reg_signed[0] = index_ABCD_reg[0];
        index_ABCD_reg_signed[1] = index_ABCD_reg[1];
        index_ABCD_reg_signed[2] = index_ABCD_reg[2];
        index_ABCD_reg_signed[3] = index_ABCD_reg[3];
    end endtask //Update_task
//================================================================
// Check Valid Date Task
//================================================================
    task Check_Valid_Date_task;begin
        Date_task;
        Data_No_task;
        Get_Dram_data_task;
    end endtask //Check_Valid_Date_task 
//================================================================
// Get Dram Data Task
//================================================================
    task Get_Dram_data_task;begin
        data_dir_reg.Index_A[11:4]                               = golden_DRAM[BASE_ADDR + data_no_reg*8 + 7];
        {data_dir_reg.Index_A[3:0] , data_dir_reg.Index_B[11:8]} = golden_DRAM[BASE_ADDR + data_no_reg*8 + 6];
        data_dir_reg.Index_B[7:0]                                = golden_DRAM[BASE_ADDR + data_no_reg*8 + 5];
        data_dir_reg.M                                           = golden_DRAM[BASE_ADDR + data_no_reg*8 + 4];
        data_dir_reg.Index_C[11:4]                               = golden_DRAM[BASE_ADDR + data_no_reg*8 + 3];
        {data_dir_reg.Index_C[3:0] , data_dir_reg.Index_D[11:8]} = golden_DRAM[BASE_ADDR + data_no_reg*8 + 2];
        data_dir_reg.Index_D[7:0]                                = golden_DRAM[BASE_ADDR + data_no_reg*8 + 1];
        data_dir_reg.D                                           = golden_DRAM[BASE_ADDR + data_no_reg*8 + 0];

        dram_index[0] = data_dir_reg.Index_A;
        dram_index[1] = data_dir_reg.Index_B;
        dram_index[2] = data_dir_reg.Index_C;
        dram_index[3] = data_dir_reg.Index_D;
    end endtask //Get_Dram_data_task
//================================================================
// Update Dram Task
//================================================================ 
    task Update_Dram_Task;begin
        if(act_reg == Update)begin
            {golden_DRAM[BASE_ADDR + data_no_reg*8 + 7] , golden_DRAM[BASE_ADDR + data_no_reg*8 + 6][7:4]} = golden_variation[0]; 
            {golden_DRAM[BASE_ADDR + data_no_reg*8 + 6][3:0] , golden_DRAM[BASE_ADDR + data_no_reg*8 + 5]} = golden_variation[1]; 
            golden_DRAM[BASE_ADDR + data_no_reg*8 + 4] = date_reg.M;
            {golden_DRAM[BASE_ADDR + data_no_reg*8 + 3] , golden_DRAM[BASE_ADDR + data_no_reg*8 + 2][7:4]} = golden_variation[2]; 
            {golden_DRAM[BASE_ADDR + data_no_reg*8 + 2][3:0] , golden_DRAM[BASE_ADDR + data_no_reg*8 + 1]} = golden_variation[3];
            golden_DRAM[BASE_ADDR + data_no_reg*8 + 0] = date_reg.D;
        end 
    end endtask //Update_Dram_Task
//================================================================
// Cal Ans Task
//================================================================
    task Cal_ans_task;begin
        G_reg[0] = (index_ABCD_reg[0] > data_dir_reg.Index_A) ? (index_ABCD_reg[0] - data_dir_reg.Index_A) : (data_dir_reg.Index_A - index_ABCD_reg[0]); 
        G_reg[1] = (index_ABCD_reg[1] > data_dir_reg.Index_B) ? (index_ABCD_reg[1] - data_dir_reg.Index_B) : (data_dir_reg.Index_B - index_ABCD_reg[1]);
        G_reg[2] = (index_ABCD_reg[2] > data_dir_reg.Index_C) ? (index_ABCD_reg[2] - data_dir_reg.Index_C) : (data_dir_reg.Index_C - index_ABCD_reg[2]);
        G_reg[3] = (index_ABCD_reg[3] > data_dir_reg.Index_D) ? (index_ABCD_reg[3] - data_dir_reg.Index_D) : (data_dir_reg.Index_D - index_ABCD_reg[3]);
        variation_result[0] = {1'b0 , data_dir_reg.Index_A} + {index_ABCD_reg_signed[0][11] , index_ABCD_reg_signed[0]}; 
        variation_result[1] = {1'b0 , data_dir_reg.Index_B} + {index_ABCD_reg_signed[1][11] , index_ABCD_reg_signed[1]};
        variation_result[2] = {1'b0 , data_dir_reg.Index_C} + {index_ABCD_reg_signed[2][11] , index_ABCD_reg_signed[2]};
        variation_result[3] = {1'b0 , data_dir_reg.Index_D} + {index_ABCD_reg_signed[3][11] , index_ABCD_reg_signed[3]};
        golden_variation[0] = (variation_result[0][12] && index_ABCD_reg_signed[0][11]) ? 'd0 : (variation_result[0][12] && ~index_ABCD_reg_signed[0][11]) ? 'd4095 : variation_result[0][11:0];
        golden_variation[1] = (variation_result[1][12] && index_ABCD_reg_signed[1][11]) ? 'd0 : (variation_result[1][12] && ~index_ABCD_reg_signed[1][11]) ? 'd4095 : variation_result[1][11:0];
        golden_variation[2] = (variation_result[2][12] && index_ABCD_reg_signed[2][11]) ? 'd0 : (variation_result[2][12] && ~index_ABCD_reg_signed[2][11]) ? 'd4095 : variation_result[2][11:0];
        golden_variation[3] = (variation_result[3][12] && index_ABCD_reg_signed[3][11]) ? 'd0 : (variation_result[3][12] && ~index_ABCD_reg_signed[3][11]) ? 'd4095 : variation_result[3][11:0];
        dram_index.sort();
        G_reg.sort();
        case (act_reg)
            Index_Check:begin
                case (formula_reg)
                    Formula_A: golden_result = (data_dir_reg.Index_A + data_dir_reg.Index_B + data_dir_reg.Index_C + data_dir_reg.Index_D)/4;
                    Formula_B: golden_result = dram_index[3] - dram_index[0];
                    Formula_C: golden_result = dram_index[0];
                    Formula_D: golden_result = (data_dir_reg.Index_A >= 'd2047) + (data_dir_reg.Index_B >= 'd2047) + (data_dir_reg.Index_C >= 'd2047) + (data_dir_reg.Index_D >= 'd2047);
                    Formula_E: golden_result = (data_dir_reg.Index_A >= index_ABCD_reg[0]) + (data_dir_reg.Index_B >= index_ABCD_reg[1]) + (data_dir_reg.Index_C >= index_ABCD_reg[2]) + (data_dir_reg.Index_D >= index_ABCD_reg[3]); 
                    Formula_F: golden_result = (G_reg[0] + G_reg[1] + G_reg[2])/3;
                    Formula_G: golden_result = (G_reg[0]/2 + G_reg[1]/4 + G_reg[2]/4);
                    Formula_H: golden_result = (G_reg[0] + G_reg[1] + G_reg[2] + G_reg[3])/4;
                endcase
                if(date_reg.M < data_dir_reg.M)
                    golden_warn_msg = Date_Warn;
                else if(date_reg.M == data_dir_reg.M && date_reg.D < data_dir_reg.D)
                    golden_warn_msg = Date_Warn;
                else begin
                    case ({mode_reg , formula_reg})
                    {Insensitive, Formula_A} : golden_warn_msg = (golden_result >= 'd2047) ? Risk_Warn : No_Warn;
                    {Insensitive, Formula_B} : golden_warn_msg = (golden_result >= 'd800 ) ? Risk_Warn : No_Warn;
                    {Insensitive, Formula_C} : golden_warn_msg = (golden_result >= 'd2047) ? Risk_Warn : No_Warn;
                    {Insensitive, Formula_D} : golden_warn_msg = (golden_result >= 'd3   ) ? Risk_Warn : No_Warn;
                    {Insensitive, Formula_E} : golden_warn_msg = (golden_result >= 'd3   ) ? Risk_Warn : No_Warn;
                    {Insensitive, Formula_F} : golden_warn_msg = (golden_result >= 'd800 ) ? Risk_Warn : No_Warn; 
                    {Insensitive, Formula_G} : golden_warn_msg = (golden_result >= 'd800 ) ? Risk_Warn : No_Warn;
                    {Insensitive, Formula_H} : golden_warn_msg = (golden_result >= 'd800 ) ? Risk_Warn : No_Warn;
                    {Normal, Formula_A}      : golden_warn_msg = (golden_result >= 'd1023) ? Risk_Warn : No_Warn;
                    {Normal, Formula_B}      : golden_warn_msg = (golden_result >= 'd400 ) ? Risk_Warn : No_Warn;
                    {Normal, Formula_C}      : golden_warn_msg = (golden_result >= 'd1023) ? Risk_Warn : No_Warn;
                    {Normal, Formula_D}      : golden_warn_msg = (golden_result >= 'd2   ) ? Risk_Warn : No_Warn;
                    {Normal, Formula_E}      : golden_warn_msg = (golden_result >= 'd2   ) ? Risk_Warn : No_Warn;
                    {Normal, Formula_F}      : golden_warn_msg = (golden_result >= 'd400 ) ? Risk_Warn : No_Warn; 
                    {Normal, Formula_G}      : golden_warn_msg = (golden_result >= 'd400 ) ? Risk_Warn : No_Warn;
                    {Normal, Formula_H}      : golden_warn_msg = (golden_result >= 'd400 ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_A}   : golden_warn_msg = (golden_result >= 'd511 ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_B}   : golden_warn_msg = (golden_result >= 'd200 ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_C}   : golden_warn_msg = (golden_result >= 'd511 ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_D}   : golden_warn_msg = (golden_result >= 'd1   ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_E}   : golden_warn_msg = (golden_result >= 'd1   ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_F}   : golden_warn_msg = (golden_result >= 'd200 ) ? Risk_Warn : No_Warn; 
                    {Sensitive, Formula_G}   : golden_warn_msg = (golden_result >= 'd200 ) ? Risk_Warn : No_Warn;
                    {Sensitive, Formula_H}   : golden_warn_msg = (golden_result >= 'd200 ) ? Risk_Warn : No_Warn;
                endcase
                end
            end
            Update:begin
                if(variation_result[0] > 'd4095 || variation_result[1] > 'd4095 || variation_result[2] > 'd4095 || variation_result[3] > 'd4095)
                    golden_warn_msg = Data_Warn;
                else if(variation_result[0] < 'd0 || variation_result[1] < 'd0 || variation_result[2] < 'd0 || variation_result[3] < 'd0)
                    golden_warn_msg = Data_Warn;
                else
                    golden_warn_msg = No_Warn;
            end
            Check_Valid_Date:begin
                if(date_reg.M < data_dir_reg.M)
                    golden_warn_msg = Date_Warn;
                else if(date_reg.M == data_dir_reg.M && date_reg.D < data_dir_reg.D)
                    golden_warn_msg = Date_Warn;
                else
                    golden_warn_msg = No_Warn;
            end  
        endcase
        golden_complete = (golden_warn_msg == No_Warn);
    end endtask //Cal_ans_task
//================================================================
// Wait Outvalid Task
//================================================================
    task Wait_outvalid_task;begin
        latency = 0;
        while(inf.out_valid !== 1) begin
            @(negedge clk);
            latency = latency + 1;
            // if(latency > MAX_CYCLE) begin
            //     $display("The execution latency is over 1000 cycles  ");
            //     $finish;
            // end
        end
    end endtask //Wait_outvalid_task
//================================================================
// Check Answer Task
//================================================================
task Check_ans_task;begin
    if(inf.out_valid === 1)begin
        if(inf.warn_msg !== golden_warn_msg || inf.complete !== golden_complete)begin
            $display("---------------------------------------------------------------");
            $display("    Wrong Answer-----------------------------------------------");
            $display("    Golden complete  : %6d    your complete  : %6d ", golden_complete, inf.complete);
            $display("    Golden warn_msg  : %6d    your warn_msg  : %6d ", golden_warn_msg, inf.warn_msg);
            $display("    Action           : %6d    ", act_reg);
            $display("    Index_A          : %d     ", index_ABCD_reg[0]);
            $display("    Index_B          : %d     ", index_ABCD_reg[1]);
            $display("    Index_C          : %d     ", index_ABCD_reg[2]);
            $display("    Index_D          : %d     ", index_ABCD_reg[3]);
            $display("    Date_M           : %d     ", date_reg.M);
            $display("    Date_D           : %d     ", date_reg.D);
            $display("---------------------------------------------------------------");
            $display("    Data_No          : %d     ", data_no_reg);
            $display("    Dram_data_Index_A: %d     ", data_dir_reg.Index_A);
            $display("    Dram_data_Index_B: %d     ", data_dir_reg.Index_B);
            $display("    Dram_data_Index_C: %d     ", data_dir_reg.Index_C);
            $display("    Dram_data_Index_D: %d     ", data_dir_reg.Index_D);
            $display("    Dram_data_M      : %d     ", data_dir_reg.M);
            $display("    Dram_data_D      : %d     ", data_dir_reg.D);
            $display("---------------------------------------------------------------");

            $finish;
        end
    end
end endtask //Check_ans_task

task YOU_PASS_task;begin
    $display("---------------------------------------------------------------");
    $display("    Congratulations--------------------------------------------");
    $display("    YOU PASS THE PATTERN  -------------------------------------");
    $display("    Total Latency : %6d ", total_latency);
    $display("---------------------------------------------------------------");
    $display("\033[37m                                  .$&X.      x$$x              \033[32m      :BBQvi.");
    $display("\033[37m                                .&&;.X&$  :&&$+X&&x            \033[32m     BBBBBBBBQi");
    $display("\033[37m                               +&&    &&.:&$    .&&            \033[32m    :BBBP :7BBBB.");
    $display("\033[37m                              :&&     &&X&&      $&;           \033[32m    BBBB     BBBB");
    $display("\033[37m                              &&;..   &&&&+.     +&+           \033[32m   iBBBv     BBBB       vBr");
    $display("\033[37m                             ;&&...   X&&&...    +&.           \033[32m   BBBBBKrirBBBB.     :BBBBBB:");
    $display("\033[37m                             x&$..    $&&X...    +&            \033[32m  rBBBBBBBBBBBR.    .BBBM:BBB");
    $display("\033[37m                             X&;...   &&&....    &&            \033[32m  BBBB   .::.      EBBBi :BBU");
    $display("\033[37m                             $&...    &&&....    &&            \033[32m MBBBr           vBBBu   BBB.");
    $display("\033[37m                             $&....   &&&...     &$            \033[32m i7PB          iBBBBB.  iBBB");
    $display("\033[37m                             $&....   &&& ..    .&x                        \033[32m  vBBBBPBBBBPBBB7       .7QBB5i");
    $display("\033[37m                             $&....   &&& ..    x&+                        \033[32m :RBBB.  .rBBBBB.      rBBBBBBBB7");
    $display("\033[37m                             X&;...   x&&....   &&;                        \033[32m    .       BBBB       BBBB  :BBBB");
    $display("\033[37m                             x&X...    &&....   &&:                        \033[32m           rBBBr       BBBB    BBBU");
    $display("\033[37m                             :&$...    &&+...   &&:                        \033[32m           vBBB        .BBBB   :7i.");
    $display("\033[37m                              &&;...   &&$...   &&:                        \033[32m             .7  BBB7   iBBBg");
    $display("\033[37m                               && ...  X&&...   &&;                                         \033[32mdBBB.   5BBBr");
    $display("\033[37m                               .&&;..  ;&&x.    $&;.$&$x;                                   \033[32m ZBBBr  EBBBv     YBBBBQi");
    $display("\033[37m                               ;&&&+   .+xx;    ..  :+x&&&&&&&x                             \033[32m  iBBBBBBBBD     BBBBBBBBB.");
    $display("\033[37m                        +&&&&&&X;..             .          .X&&&&&x                         \033[32m    :LBBBr      vBBBi  5BBB");
    $display("\033[37m                    $&&&+..                                    .:$&&&&.                     \033[32m          ...   :BBB:   BBBu");
    $display("\033[37m                 $&&$.                                             .X&&&&.                  \033[32m         .BBBi   BBBB   iMBu");
    $display("\033[37m              ;&&&:                                               .   .$&&&                x\033[32m          BBBX   :BBBr");
    $display("\033[37m            x&&x.      .+&&&&&.                .x&$x+:                  .$&&X         $+  &x  ;&X   \033[32m  .BBBv  :BBBQ");
    $display("\033[37m          .&&;       .&&&:                      .:x$&&&&X                 .&&&        ;&     +&.    \033[32m   .BBBBBBBBB:");
    $display("\033[37m         $&&       .&&$.                             ..&&&$                 x&& x&&&X+.          X&x\033[32m     rBBBBB1.");
    $display("\033[37m        &&X       ;&&:                                   $&&x                $&x   .;x&&&&:                       ");
    $display("\033[37m      .&&;       ;&x                                      .&&&                &&:       .$&&$    ;&&.             ");
    $display("\033[37m      &&;       .&X                                         &&&.              :&$          $&&x                   ");
    $display("\033[37m     x&X       .X& .                                         &&&.              .            ;&&&  &&:             ");
    $display("\033[37m     &&         $x                                            &&.                            .&&&                 ");
    $display("\033[37m    :&&                                                       ;:                              :&&X                ");
    $display("\033[37m    x&X                 :&&&&&;                ;$&&X:                                          :&&.               ");
    $display("\033[37m    X&x .              :&&&  $&X              &&&  X&$                                          X&&               ");
    $display("\033[37m    x&X                x&&&&&&&$             :&&&&$&&&                                          .&&.              ");
    $display("\033[37m    .&&    \033[38;2;255;192;203m      ....\033[37m  .&&X:;&&+              &&&++;&&                                          .&&               ");
    $display("\033[37m     &&    \033[38;2;255;192;203m  .$&.x+..:\033[37m  ..+Xx.                 :&&&&+\033[38;2;255;192;203m  .;......    \033[37m                             .&&");
    $display("\033[37m     x&x   \033[38;2;255;192;203m .x&:;&x:&X&&.\033[37m              .             \033[38;2;255;192;203m .&X:&&.&&.:&.\033[37m                             :&&");
    $display("\033[37m     .&&:  \033[38;2;255;192;203m  x;.+X..+.;:.\033[37m         ..  &&.            \033[38;2;255;192;203m &X.;&:+&$ &&.\033[37m                             x&;");
    $display("\033[37m      :&&. \033[38;2;255;192;203m    .......   \033[37m         x&&&&&$++&$        \033[38;2;255;192;203m .... ......: \033[37m                             && ");
    $display("\033[37m       ;&&                          X&  .x.              \033[38;2;255;192;203m .... \033[37m                               .&&;                ");
    $display("\033[37m        .&&x                        .&&$X                                          ..         .x&&&               ");
    $display("\033[37m          x&&x..                                                                 :&&&&&+         +&X              ");
    $display("\033[37m            ;&&&:                                                                     x&&$XX;::x&&X               ");
    $display("\033[37m               &&&&&:.                                                              .X&x    +xx:                  ");
    $display("\033[37m                  ;&&&&&&&&$+.                                  :+x&$$X$&&&&&&&&&&&&&$                            ");
    $display("\033[37m                       .+X$&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&$X+xXXXxxxx+;.                                   ");

    $finish;

end endtask //YOU_PASS_task


endprogram
