module Program(input clk, INF.Program_inf inf);
import usertype::*;

//==============================================================================
// Variables
//==============================================================================
Action       act_reg;
Formula_Type formula_reg;
Mode         mode_reg;
Month        month_reg;
Day          day_reg;
Data_No      data_no_reg;
Index        pattern_index_reg [0:3];
Data_Dir     data_dir_reg;
Index        Index_A_1, Index_B_1, Index_C_1, Index_D_1;
logic [11:0] G_reg[0:3];

state cs, ns;
dram_state cs_dram, ns_dram;
logic wait_done, task_done;
logic cal_variation_done;
logic start_send_write_addr;
logic [1:0] cnt_4_index, cnt_4_index_ns;
logic [3:0] cnt_task;

logic get_dram_data;
logic get_pattern_data;

Warn_Msg warn_msg_result;

logic [11:0] result_w;
logic [13:0] result_reg;
logic [11:0] div_reg;

// logic upper_limit_check [0:3]; 
// logic lower_limit_check [0:3];
logic [11:0] variation_result;
logic limit_check;
logic limit_check_reg;
// logic upper_limit_reg [0:3];
// logic lower_limit_reg [0:3];
//==============================================================================
// Adder
//==============================================================================
logic [13:0] add_in1, add_in2, add_out;

assign add_out = add_in1 + add_in2;
//==============================================================================
// Sorting
//==============================================================================
logic [11:0] sort_in1, sort_in2, sort_in3, sort_in4;
logic [11:0] sort_out1, sort_out2, sort_out3, sort_out4;
logic [11:0] sort_reg[0:3];
sorting u_sorting(sort_in1, sort_in2, sort_in3, sort_in4, sort_out1, sort_out2, sort_out3, sort_out4);
always_comb begin 
    sort_in1 = 0;sort_in2 = 0;sort_in3 = 0;sort_in4 = 0;
    case (formula_reg)
        Formula_B, Formula_C:begin
            sort_in1 = data_dir_reg.Index_A;
            sort_in2 = data_dir_reg.Index_B;
            sort_in3 = data_dir_reg.Index_C;
            sort_in4 = data_dir_reg.Index_D;
        end
        Formula_F, Formula_G, Formula_H:begin
            sort_in1 = G_reg[0];
            sort_in2 = G_reg[1];
            sort_in3 = G_reg[2];
            sort_in4 = G_reg[3];
        end
    endcase
end
always_ff @( posedge clk ) begin
    if(cs == Index_check_task && (formula_reg == Formula_F || formula_reg == Formula_G || formula_reg == Formula_H))begin
        if(cnt_task > 'd4)begin
            sort_reg[0] <= sort_reg[0];
            sort_reg[1] <= sort_reg[0];
            sort_reg[2] <= sort_reg[1];
            sort_reg[3] <= sort_reg[2];
        end
        else begin
            sort_reg[0] <= sort_out1;//max
            sort_reg[1] <= sort_out2;
            sort_reg[2] <= sort_out3;
            sort_reg[3] <= sort_out4;//min
        end
    end
    else begin
        sort_reg[0] <= sort_out1;//max
        sort_reg[1] <= sort_out2;
        sort_reg[2] <= sort_out3;
        sort_reg[3] <= sort_out4;//min
    end     
end
//==============================================================================
// Compare for threshold
//==============================================================================
logic [11:0] cmp_in1, cmp_in2;
logic cmp_out;
logic cmp_reg;

always_comb begin
    cmp_in1 = 0;
    cmp_in2 = 0;
    case (cs)
        Index_check_task:begin
            case (formula_reg)
                Formula_A:begin
                    cmp_in1 = result_reg >> 2;
                    case (mode_reg)
                        Insensitive: cmp_in2 = 'd2047;
                        Normal: cmp_in2 = 'd1023;
                        Sensitive: cmp_in2 = 'd511;
                    endcase
                end
                Formula_B:begin
                    cmp_in1 = result_reg;
                    case (mode_reg)
                        Insensitive: cmp_in2 = 'd800;
                        Normal: cmp_in2 = 'd400;
                        Sensitive: cmp_in2 = 'd200;
                    endcase
                end
                Formula_C:begin
                    cmp_in1 = result_reg;
                    case (mode_reg)
                        Insensitive: cmp_in2 = 'd2047;
                        Normal: cmp_in2 = 'd1023;
                        Sensitive: cmp_in2 = 'd511;
                    endcase
                end
                Formula_D:begin
                    cmp_in1 = data_dir_reg.Index_A;
                    cmp_in2 = 'd2047;
                    if(cnt_task == 'd5)begin
                        cmp_in1 = result_reg;
                        case (mode_reg)
                            Insensitive: cmp_in2 = 'd3;
                            Normal: cmp_in2 = 'd2;
                            Sensitive: cmp_in2 = 'd1;
                        endcase
                    end
                end 
                Formula_E:begin
                    cmp_in1 = data_dir_reg.Index_A;
                    cmp_in2 = pattern_index_reg[0];
                    if(cnt_task == 'd5)begin
                        cmp_in1 = result_reg;
                        case (mode_reg)
                            Insensitive: cmp_in2 = 'd3;
                            Normal: cmp_in2 = 'd2;
                            Sensitive: cmp_in2 = 'd1;
                        endcase
                    end
                end 
                Formula_F:begin
                    cmp_in1 = div_reg;
                    case (mode_reg)
                        Insensitive: cmp_in2 = 'd800;
                        Normal: cmp_in2 = 'd400;
                        Sensitive: cmp_in2 = 'd200;
                    endcase
                end
                Formula_G:begin
                    cmp_in1 = result_reg;
                    case (mode_reg)
                        Insensitive: cmp_in2 = 'd800;
                        Normal: cmp_in2 = 'd400;
                        Sensitive: cmp_in2 = 'd200;
                    endcase
                end
                Formula_H:begin
                    cmp_in1 = result_reg >> 2;
                    case (mode_reg)
                        Insensitive: cmp_in2 = 'd800;
                        Normal: cmp_in2 = 'd400;
                        Sensitive: cmp_in2 = 'd200;
                    endcase
                end
            endcase
        end 
    endcase
end
assign cmp_out = cmp_in1 >= cmp_in2;
always_ff @( posedge clk ) begin 
    cmp_reg <= cmp_out;
end
//==============================================================================
// FSM
//==============================================================================
always_ff @( posedge clk, negedge inf.rst_n ) begin : state_seq
    if(~inf.rst_n) cs <= IDLE;
    else cs <= ns;
end
always_comb begin : state_comb
    ns = cs;
    case (cs)
        IDLE:begin
            if(inf.sel_action_valid)begin
                ns = WAIT;
            end
        end 
        WAIT:begin
            if(wait_done)begin
                case (act_reg)
                    Index_Check     : ns = Index_check_task;
                    Update          : ns = Update_task;
                    Check_Valid_Date: ns = Check_Valid_Date_task;
                endcase
            end
        end
        Index_check_task:begin
            if(task_done) ns = OUT;
        end
        Update_task:begin
            if(task_done) ns = OUT;
        end
        Check_Valid_Date_task:begin
            if(task_done) ns = OUT;
        end
        OUT:begin
            ns = IDLE;
        end
    endcase
end
always_ff @( posedge clk or negedge inf.rst_n ) begin : cnt_4_index_seq
    if(~inf.rst_n)
        cnt_4_index <= 'd0;
    else
        cnt_4_index <= cnt_4_index_ns;
end
always_comb begin : cnt_4_index_comb
    cnt_4_index_ns = cnt_4_index;
    if(cs == IDLE)
        cnt_4_index_ns = 'd0;
    else if(inf.index_valid) 
        cnt_4_index_ns = cnt_4_index + 'd1;
    else if(cs == Index_check_task)
        cnt_4_index_ns = cnt_4_index + 'd1;
end
always_ff @( posedge clk or negedge inf.rst_n ) begin : blockName
    if(~inf.rst_n)
        cnt_task <= 'd0;
    else if(cs == IDLE)
        cnt_task <= 'd0;
    else if(cs == Index_check_task)
        cnt_task <= cnt_task + 'd1;
    else if(cs == Update_task && cnt_task < 'd4) 
        cnt_task <= cnt_task + 'd1;
end
always_comb begin : wait_done_comb
    case (act_reg)
        Index_Check     : wait_done = (get_dram_data) && ((cnt_4_index == 'd3 && cnt_4_index_ns == 'd0) || get_pattern_data);
        Update          : wait_done = (get_dram_data) && ((cnt_4_index == 'd3 && cnt_4_index_ns == 'd0) || get_pattern_data);
        Check_Valid_Date: wait_done = inf.R_VALID;
        default         : wait_done = 0;
    endcase
end
always_comb begin : task_done_comb
    task_done = 0;
    case (act_reg)
        Index_Check     : begin
            if(month_reg < data_dir_reg.M)
                task_done = 1;
            else if(month_reg == data_dir_reg.M && day_reg < data_dir_reg.D)
                task_done = 1;
            else begin
                case (formula_reg)
                    Formula_A: task_done = cnt_task == 'd4;
                    Formula_B: task_done = cnt_task == 'd2;
                    Formula_C: task_done = cnt_task == 'd2;
                    Formula_D: task_done = cnt_task == 'd5;
                    Formula_E: task_done = cnt_task == 'd5;
                    Formula_F: task_done = cnt_task == 'd9;
                    Formula_G: task_done = cnt_task == 'd8;
                    Formula_H: task_done = cnt_task == 'd9;
                endcase
            end 
        end
        Update          : task_done = inf.B_VALID; 
        Check_Valid_Date: task_done = 1;  
    endcase
end
always_ff @( posedge clk ) begin 
    if(cs == IDLE)
        get_pattern_data <= 0;
    else if((cnt_4_index == 'd3) && (cnt_4_index_ns == 'd0))
        get_pattern_data <= 1;
end
always_ff @( posedge clk ) begin
    if(cs == IDLE)
        get_dram_data <= 0;
    else if(inf.R_VALID)
        get_dram_data <= 1;
end
//==============================================================================
// DRAM FSM
//==============================================================================
assign cal_variation_done = (cs == Update_task && cnt_task == 'd3);
assign start_send_write_addr = (cal_variation_done);
// assign start_send_write_addr = (cs == Update_task);
always_ff @( posedge clk, negedge inf.rst_n ) begin : dram_state_seq
    if(~inf.rst_n) cs_dram <= DRAM_IDLE;
    else cs_dram <= ns_dram;
end
always_comb begin : dram_state_comb
    ns_dram = cs_dram;
    case (cs_dram)
        DRAM_IDLE:begin
            if(inf.data_no_valid) ns_dram = R_ADDR;
            else if(start_send_write_addr) ns_dram = W_ADDR;
        end
        R_ADDR:begin
            if(inf.AR_READY) ns_dram = R_DATA;
        end
        R_DATA:begin
            if(inf.R_VALID) ns_dram = DRAM_IDLE;
        end
        W_ADDR:begin
            if(inf.AW_READY) ns_dram = W_DATA;
        end
        W_DATA:begin
            if(inf.W_READY) ns_dram = WAIT_RESP;
        end
        WAIT_RESP:begin
            if(inf.B_VALID) ns_dram = DRAM_IDLE;
        end
    endcase
end
//==============================================================================
// Limit Check
//==============================================================================
    always_ff @( posedge clk ) begin : limit_check_seq
        if(cs == IDLE)
            limit_check_reg <= 0;
        else if(cs == Update_task && cnt_task < 'd4)begin
            limit_check_reg <= limit_check ? 1 : limit_check_reg;
        end
    end
//==============================================================================
// Input Reg
//==============================================================================
    always_ff @( posedge clk ) begin : act_reg_seq
        if(inf.sel_action_valid) 
            act_reg <= inf.D.d_act[0];
    end
    always_ff @( posedge clk ) begin : formula_reg_seq
        if(inf.formula_valid) 
            formula_reg <= inf.D.d_formula[0];
    end
    always_ff @( posedge clk ) begin : mode_reg_seq
        if(inf.mode_valid) 
            mode_reg <= inf.D.d_mode[0];
    end
    always_ff @( posedge clk ) begin : month_reg_seq
        if(inf.date_valid) 
            {month_reg , day_reg} <= {inf.D.d_date[0].M, inf.D.d_date[0].D};
    end
    always_ff @( posedge clk ) begin : data_no_reg_seq
        if(inf.data_no_valid) 
            data_no_reg <= inf.D.d_data_no[0];
    end
//pattern_index_reg
    always_ff @( posedge clk ) begin : index_reg_0_seq
        if(inf.index_valid)begin
            pattern_index_reg[0] <= pattern_index_reg[1];
        end
        else if(cs == Index_check_task)
            pattern_index_reg[0] <= pattern_index_reg[1];
        else if(cs == Update_task && cnt_task < 'd4)begin
            pattern_index_reg[0] <= pattern_index_reg[1];
        end
    end
    always_ff @( posedge clk ) begin : index_reg_1_seq
        if(inf.index_valid)begin
            pattern_index_reg[1] <= pattern_index_reg[2];
        end
        else if(cs == Index_check_task)
            pattern_index_reg[1] <= pattern_index_reg[2];
        else if(cs == Update_task && cnt_task < 'd4)begin
            pattern_index_reg[1] <= pattern_index_reg[2];
        end
        
    end
    always_ff @( posedge clk ) begin : index_reg_2_seq
        if(inf.index_valid)begin
            pattern_index_reg[2] <= pattern_index_reg[3];
        end
        else if(cs == Index_check_task)
            pattern_index_reg[2] <= pattern_index_reg[3];
        else if(cs == Update_task && cnt_task < 'd4)begin
            pattern_index_reg[2] <= pattern_index_reg[3];
        end
    end
    always_ff @( posedge clk ) begin : index_reg_3_seq
        if(inf.index_valid)begin
            pattern_index_reg[3] <= inf.D.d_index[0];
        end
        else if(cs == Index_check_task)
            pattern_index_reg[3] <= 0;
        else if(cs == Update_task && cnt_task < 'd4)begin
            pattern_index_reg[3] <= variation_result;
        end
    end
//==============================================================================
// DRAM Control
//==============================================================================
always_comb begin : dram_control_comb
    inf.AR_VALID = 0;
    inf.AR_ADDR = 0;
    inf.R_READY = 0;
    inf.AW_VALID = 0;
    inf.AW_ADDR = 0;
    inf.W_VALID = 0;
    inf.W_DATA = 0;
    inf.B_READY = 0;
    case (cs_dram)
        R_ADDR:begin
            inf.AR_VALID = 1;
            inf.AR_ADDR = 32'h10000 + (data_no_reg << 3);
        end
        R_DATA:begin
            inf.R_READY = 1;
        end
        W_ADDR:begin
            inf.AW_VALID = 1;
            inf.AW_ADDR = 32'h10000 + (data_no_reg << 3);
        end
        W_DATA:begin
            inf.W_VALID = 1;
            inf.W_DATA[63:52] = pattern_index_reg[0];
            inf.W_DATA[51:40] = pattern_index_reg[1];
            inf.W_DATA[39:32] = month_reg;
            inf.W_DATA[31:20] = pattern_index_reg[2];
            inf.W_DATA[19:8]  = pattern_index_reg[3];
            inf.W_DATA[7:0]   = day_reg;
            inf.B_READY = 1;
        end
        WAIT_RESP:begin
            inf.B_READY = 1;
        end    
    endcase
end
//==============================================================================
// DRAM Data
//==============================================================================
    always_ff @( posedge clk ) begin : dram_data_seq
        if(inf.R_VALID)begin
            data_dir_reg.Index_A <= inf.R_DATA[63:52];
            data_dir_reg.Index_B <= inf.R_DATA[51:40];
            data_dir_reg.M       <= inf.R_DATA[39:32];
            data_dir_reg.Index_C <= inf.R_DATA[31:20];
            data_dir_reg.Index_D <= inf.R_DATA[19:8];
            data_dir_reg.D       <= inf.R_DATA[7:0];
        end
        else if(cs == Index_check_task || cs == Update_task)begin
            // case (formula_reg)
            //     Formula_A, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H:begin
                    data_dir_reg.Index_A <= data_dir_reg.Index_B;
                    data_dir_reg.Index_B <= data_dir_reg.Index_C;
                    data_dir_reg.M       <= data_dir_reg.M;
                    data_dir_reg.Index_C <= data_dir_reg.Index_D;
                    data_dir_reg.Index_D <= data_dir_reg.Index_D;
                    data_dir_reg.D       <= data_dir_reg.D;
                // end 
            // endcase
        end
        // else if(cs == )begin
        //     data_dir_reg.Index_A <= data_dir_reg.Index_B;
        //     data_dir_reg.Index_B <= data_dir_reg.Index_C;
        //     data_dir_reg.M       <= data_dir_reg.M;
        //     data_dir_reg.Index_C <= data_dir_reg.Index_D;
        //     data_dir_reg.Index_D <= data_dir_reg.Index_D;
        //     data_dir_reg.D       <= data_dir_reg.D;
        // end
    end
    // assign Index_A_1 = data_dir_reg.Index_A + 1'b1;
    // assign Index_B_1 = data_dir_reg.Index_B + 1'b1;
    // assign Index_C_1 = data_dir_reg.Index_C + 1'b1;
    // assign Index_D_1 = data_dir_reg.Index_D + 1'b1;
//==============================================================================
// Formula
//==============================================================================
    always_comb begin : add_input_contorl
        add_in1 = 0;add_in2 = 0;
        case (cs)
            Index_check_task:begin
                case (formula_reg)
                    Formula_A: begin
                        add_in1 = data_dir_reg.Index_A;
                        add_in2 = result_reg;
                    end
                    Formula_B:begin
                        add_in1 = sort_reg[0];
                        add_in2 = ~sort_reg[3] + 1'b1;
                    end
                    Formula_C:begin
                        add_in1 = sort_reg[3];
                        add_in2 = 0;
                    end
                    Formula_D:begin
                        if(cnt_task < 'd5 && cnt_task > 'd0)
                            add_in1 = cmp_reg;
                        else
                            add_in1 = 0;
                        add_in2 = result_reg;
                    end
                    Formula_E:begin
                        if(cnt_task < 'd5 && cnt_task > 'd0)
                            add_in1 = cmp_reg;
                        else
                            add_in1 = 0;
                        add_in2 = result_reg;
                    end
                    Formula_F:begin
                        if(cnt_task < 'd4)begin
                            add_in1 = data_dir_reg.Index_A;
                            add_in2 = ~pattern_index_reg[0] + 1'b1;
                        end
                        else if(cnt_task == 'd4)begin
                            add_in1 = 0;
                            add_in2 = 0;
                        end
                        else begin
                            add_in1 = sort_reg[3];
                            add_in2 = result_reg;
                        end
                    end
                    Formula_G: begin
                        if(cnt_task < 'd4)begin
                            add_in1 = data_dir_reg.Index_A;
                            add_in2 = ~pattern_index_reg[0] + 1'b1;
                        end
                        else if(cnt_task == 'd4)begin
                            add_in1 = 0;
                            add_in2 = 0;
                        end
                        else begin
                            case (cnt_task)
                                'd5: add_in1 = sort_reg[3] >> 1;
                                'd6: add_in1 = sort_reg[3] >> 2;
                                'd7: add_in1 = sort_reg[3] >> 2;
                            endcase
                            add_in2 = result_reg;
                        end
                    end
                    Formula_H: begin
                        if(cnt_task < 'd4)begin
                            add_in1 = data_dir_reg.Index_A;
                            add_in2 = ~pattern_index_reg[0] + 1'b1;
                        end
                        else if(cnt_task == 'd4)begin
                            add_in1 = 0;
                            add_in2 = 0;
                        end
                        else begin
                            add_in1 = sort_reg[3];
                            add_in2 = result_reg;
                        end
                    end
                endcase
            end  
            Update_task:begin
                add_in1 = data_dir_reg.Index_A;
                add_in2 = $signed(pattern_index_reg[0]);
            end
        endcase
    end
    always_comb begin 
        if(add_out[12])begin
            limit_check = 1;
            if(add_in2[12])
                variation_result = 'd0;//lower limit
            else
                variation_result = 'd4095;//upper limit
        end
        else begin
            limit_check = 0;
            variation_result = add_out;
        end
    end
    always_ff @( posedge clk ) begin : G_reg_seq
        G_reg[0] <= G_reg[1];
        G_reg[1] <= G_reg[2];
        G_reg[2] <= G_reg[3];
        G_reg[3] <= add_out[12] ? ~add_out + 1'b1 : add_out;
    end
    always_ff @( posedge clk ) begin : result_reg_seq
        if(cs == Index_check_task)
            result_reg <= add_out;
        else
            result_reg <= 0;
    end
    always_ff @( posedge clk ) begin
        div_reg <= result_reg / 3;
    end
    always_comb begin : result_reg_comb
        result_w = 0;
        case (formula_reg)
            Formula_A: result_w = result_reg >> 2;
            Formula_B: result_w = result_reg ;
            Formula_C: result_w = result_reg ;
            Formula_D: result_w = result_reg ;
            Formula_E: result_w = result_reg ;
            Formula_F: result_w = result_reg / 3;
            Formula_G: result_w = result_reg ;
            Formula_H: result_w = result_reg >> 2; 
        endcase
        
    end
//==============================================================================
// warn_msg_result
//==============================================================================
always_comb begin : warn_msg_result_comb
    warn_msg_result = No_Warn;
    case (act_reg)
        Index_Check:begin
            if(month_reg < data_dir_reg.M)
                warn_msg_result = Date_Warn;
            else if(month_reg == data_dir_reg.M && day_reg < data_dir_reg.D)
                warn_msg_result = Date_Warn;
            else begin
                warn_msg_result = (cmp_reg) ? Risk_Warn : No_Warn;
            end
        end 
        Update:begin
            if(limit_check_reg)
                warn_msg_result = Data_Warn;
        end
        Check_Valid_Date:begin
            if(month_reg < data_dir_reg.M)
                warn_msg_result = Date_Warn;
            else if(month_reg == data_dir_reg.M && day_reg < data_dir_reg.D)
                warn_msg_result = Date_Warn;
        end 
    endcase
end
//==============================================================================
// Output
//==============================================================================
always_comb begin : out_comb
    inf.out_valid = 0;
    inf.warn_msg = No_Warn;
    inf.complete = 0;
    case (cs)
        OUT:begin
            inf.out_valid = 1;
            inf.warn_msg = warn_msg_result;
            inf.complete = warn_msg_result == No_Warn;
        end
    endcase
end


endmodule

module sorting(
    in1, in2, in3, in4,
    out1, out2, out3, out4
);
    input  [11:0] in1, in2, in3, in4;
    output [11:0] out1, out2, out3, out4;
    logic [11:0] temp1, temp2, temp3, temp4;
    assign temp1 = in1 > in2 ? in1 : in2;
    assign temp2 = in1 > in2 ? in2 : in1;
    assign temp3 = in3 > in4 ? in3 : in4;
    assign temp4 = in3 > in4 ? in4 : in3;

    assign out1 = temp1 > temp3 ? temp1 : temp3;//max
    assign out2 = temp1 > temp3 ? temp3 : temp1;
    assign out3 = temp2 > temp4 ? temp2 : temp4;
    assign out4 = temp2 > temp4 ? temp4 : temp2;//min
endmodule
