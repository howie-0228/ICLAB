/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */
logic [2:0] cnt_4_index;
logic [2:0] cnt_4_index_w;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(~inf.rst_n) 
        cnt_4_index <= 0;
    else if(inf.out_valid) 
        cnt_4_index <= 0;
    else 
        cnt_4_index <= cnt_4_index_w;
end
always_comb begin 
    if(inf.index_valid)
        cnt_4_index_w = cnt_4_index + 1;
    else
        cnt_4_index_w = cnt_4_index;
end
class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();

always_ff @(posedge clk) begin
    if(inf.formula_valid) begin
        fm_info.f_type = inf.D.d_formula[0];
    end
end
always_ff @(posedge clk) begin
    if(inf.mode_valid) begin
        fm_info.f_mode = inf.D.d_mode[0];
    end
end
Action act_info;
always_ff @(posedge clk) begin
    if(inf.sel_action_valid) begin
        act_info = inf.D.d_act[0];
    end
end
//Each case of Formula_Type should be at least 150 times
covergroup cg1 @(posedge clk iff(inf.formula_valid));
    option.at_least = 150;
    option.per_instance = 1;
    coverpoint fm_info.f_type{
        bins f_counts[] = {[Formula_A : Formula_H]};
    }
endgroup

//Each case of Formula_Type should be at least 150 times
covergroup cg2 @(posedge clk iff(inf.mode_valid));
    option.at_least = 150;
    option.per_instance = 1;
    coverpoint fm_info.f_mode{
        bins m_counts[] = {[Insensitive : Sensitive]};
    }
endgroup

//Each formula and mode combination should be selected at least 150 times
covergroup cg3 @(posedge clk iff(inf.date_valid));
    option.at_least = 150;
    option.per_instance = 1;
    cross fm_info.f_type, fm_info.f_mode;
endgroup

//Output signal inf.warn_msg should be “No_Warn”, “Date_Warn”, “Data_Warn“,”Risk_Warn,each at least 50 times
covergroup cg4 @(negedge clk iff(inf.out_valid));
    option.at_least = 50;
    option.per_instance = 1;
    coverpoint inf.warn_msg{
        bins w_counts[] = {[No_Warn : Data_Warn]};
    }
endgroup

//Each Action transition should be hit at least 300 times
covergroup cg5 @(posedge clk iff(inf.sel_action_valid));
    option.at_least = 300;
    option.per_instance = 1;
    coverpoint inf.D.d_act[0]{
        bins a_counts[] = ([Index_Check : Check_Valid_Date] => [Index_Check : Check_Valid_Date]);
    }
endgroup

//Create a covergroup for variation of Update action with auto_bin_max = 32, and each bin have to hit at least one time
covergroup cg6 @(posedge clk iff(inf.index_valid && act_info == Update));
    option.at_least = 1 ;
    option.per_instance = 1;
    variation_check: coverpoint inf.D.d_index[0] {
        option.auto_bin_max = 32;
    }
endgroup

cg1 cg1_inst = new();
cg2 cg2_inst = new();
cg3 cg3_inst = new();
cg4 cg4_inst = new();
cg5 cg5_inst = new();
cg6 cg6_inst = new();
//================================================================================================
// Assertion
//================================================================================================
// Assertion 1: All outputs signals (Program.sv) should be zero after reset
// reset_check: assert property(reset) else $fatal(0,"Assertion 1 is violated");
always @(negedge inf.rst_n)begin
    #2;
    rst_check: assert ((inf.out_valid === 0)&&(inf.warn_msg === No_Warn)&&(inf.complete === 0)&&
    (inf.AR_VALID === 0)&&(inf.AR_ADDR === 0)&&(inf.R_READY === 0)&&(inf.AW_VALID === 0)&&(inf.AW_ADDR === 0)&&
    (inf.W_VALID === 0)&&(inf.W_DATA === 0)&&(inf.B_READY === 0)) 
    else $fatal(0,"Assertion 1 is violated"); 
end
// Latency should be less than 1000 cycles for each operation
latency_check_1: assert property(latency_check_for_index_and_update) else $fatal(0,"Assertion 2 is violated");
latency_check_2: assert property(latency_check_for_valid_date) else $fatal(0,"Assertion 2 is violated");
//If action is completed (complete=1), warn_msg should be 2’b0 (No_Warn)
complete_check: assert  property (warn_msg_check) else $fatal(0,"Assertion 3 is violated");
//Next input valid will be valid 1-4 cycles after previous input valid fall
input_valid_check_1: assert property(act_to_formula_cycle) else $fatal(0,"Assertion 4 is violated");
input_valid_check_2: assert property(formula_to_mode_cycle) else $fatal(0,"Assertion 4 is violated");
input_valid_check_3: assert property(mode_to_date_cycle) else $fatal(0,"Assertion 4 is violated");
input_valid_check_4: assert property(date_to_data_no_cycle) else $fatal(0,"Assertion 4 is violated");
input_valid_check_5: assert property(data_no_to_index_cycle) else $fatal(0,"Assertion 4 is violated");
input_valid_check_6: assert property(index_to_index_cycle) else $fatal(0,"Assertion 4 is violated");
input_valid_check_7: assert property(act_to_date_cycle) else $fatal(0,"Assertion 4 is violated");
//All input valid signals won’t overlap with each other
overlap_check: assert property(input_overlap_check) else $fatal(0,"Assertion 5 is violated");
//Out_valid can only be high for exactly one cycle
out_valid_one_check: assert property (out_valid_check) else $fatal(0,"Assertion 6 is violated");
//Next operation will be valid 1-4 cycles after out_valid fall
next_operation_lat_check: assert property (next_operation_check) else $fatal(0,"Assertion 7 is violated");
//The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
month_day_check_1: assert property(big_month_day_check) else $fatal(0,"Assertion 8 is violated");
month_day_check_2: assert property(small_month_day_check) else $fatal(0,"Assertion 8 is violated");
spec_feburary_check: assert property(feburary_check) else $fatal(0,"Assertion 8 is violated");
total_month_check: assert property(month_check) else $fatal(0,"Assertion 8 is violated");
//The AR_VALID signal should not overlap with the AW_VALID signal
AR_AW_VALID_overlap_check: assert property(AR_VALID_AW_VALID_check) else $fatal(0,"Assertion 9 is violated");
//================================================================================================
// Property
//================================================================================================
//assertion 1
property reset;
    @(posedge inf.rst_n iff(inf.rst_n === 0)) 
    (inf.out_valid === 0)&&(inf.warn_msg === No_Warn)&&(inf.complete === 0)&&
    (inf.AR_VALID === 0)&&(inf.AR_ADDR === 0)&&(inf.R_READY === 0)&&(inf.AW_VALID === 0)&&(inf.AW_ADDR === 0)&&
    (inf.W_VALID === 0)&&(inf.W_DATA === 0)&&(inf.B_READY === 0);
endproperty
//assertion 2
property latency_check_for_index_and_update;
    @(posedge clk) ((act_info === Index_Check) || (act_info === Update) && (cnt_4_index_w === 4) |-> ( ##[1:1000] inf.out_valid===1 ));
endproperty
//assertion 2
property latency_check_for_valid_date;
    @(posedge clk) ((act_info === Check_Valid_Date) && (inf.data_no_valid)) |-> ( ##[1:1000] inf.out_valid===1 );
endproperty
//assertion 3
property warn_msg_check;
    @(negedge clk) (inf.complete) |-> (inf.warn_msg === No_Warn);
endproperty
//assertion 4
    //act_to_formula
    property act_to_formula_cycle;
        @(posedge clk) ((inf.D.d_act[0] == Index_Check) && (inf.sel_action_valid)) |-> ( ##[1:4] inf.formula_valid === 1 );
    endproperty
    //formula_to_mode
    property formula_to_mode_cycle;
        @(posedge clk) ((act_info == Index_Check) && (inf.formula_valid)) |-> ( ##[1:4] inf.mode_valid === 1 );
    endproperty
    //mode_to_date
    property mode_to_date_cycle;
        @(posedge clk) ((act_info == Index_Check) && (inf.mode_valid)) |-> ( ##[1:4] inf.date_valid === 1 );
    endproperty
    //date_to_data_no
    property date_to_data_no_cycle;
        @(posedge clk) (inf.date_valid) |-> ( ##[1:4] inf.data_no_valid === 1 );
    endproperty
    //data_no_to_index
    property data_no_to_index_cycle;
        @(posedge clk) (((act_info == Index_Check) || (act_info == Update)) && (inf.data_no_valid)) |-> ( ##[1:4] inf.index_valid === 1 );
    endproperty
    //index_to_index
    property index_to_index_cycle;
        @(posedge clk) (((act_info == Index_Check) || (act_info == Update)) && (inf.index_valid) && (cnt_4_index_w !== 4)) |-> ( ##[1:4] inf.index_valid === 1 );
    endproperty
    //act_to_date
    property act_to_date_cycle;
        @(posedge clk) (((inf.D.d_act[0] == Check_Valid_Date) || (inf.D.d_act[0] == Update)) && (inf.sel_action_valid)) |-> ( ##[1:4] inf.date_valid === 1 );
    endproperty
//assertion 5
logic no_invalid;
assign no_invalid = !(inf.sel_action_valid || inf.formula_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.index_valid);
property input_overlap_check;
    @(posedge clk) $onehot({inf.sel_action_valid, inf.formula_valid, inf.mode_valid, inf.date_valid, inf.data_no_valid, inf.index_valid, no_invalid});
endproperty
//assertion 6
property out_valid_check;
    @(posedge clk) (inf.out_valid === 1) |=> ( inf.out_valid === 0);
endproperty
//assertion 7
property next_operation_check;
    @(posedge clk) (inf.out_valid === 1) |-> ( ##[1:4] inf.sel_action_valid === 1 );
endproperty
//assertion 8
property big_month_day_check;
    @(posedge clk) (inf.date_valid && (inf.D.d_date[0].M === 1 || inf.D.d_date[0].M === 3 || inf.D.d_date[0].M === 5 || inf.D.d_date[0].M === 7 || inf.D.d_date[0].M === 8 || inf.D.d_date[0].M === 10 || inf.D.d_date[0].M === 12)) |-> (inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31);
endproperty
property small_month_day_check;
    @(posedge clk) (inf.date_valid && (inf.D.d_date[0].M === 4 || inf.D.d_date[0].M === 6 || inf.D.d_date[0].M === 9 || inf.D.d_date[0].M === 11)) |-> (inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 30);
endproperty
property feburary_check;
    @(posedge clk) (inf.date_valid && (inf.D.d_date[0].M === 2)) |-> (inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 28);
endproperty
property month_check;
    @(posedge clk) (inf.date_valid) |-> (inf.D.d_date[0].M >= 1 && inf.D.d_date[0].M <= 12);   
endproperty
//assertion 9
logic ar_aw_no_valid;
assign ar_aw_no_valid = !(inf.AR_VALID || inf.AW_VALID);
property AR_VALID_AW_VALID_check;
    @(posedge clk) $onehot({inf.AR_VALID, inf.AW_VALID, ar_aw_no_valid});
endproperty
endmodule