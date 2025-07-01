module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 'd0, RED = 'd4, GREEN = 'd5, BLUE = 'd6, ACT_sort = 'd7;
parameter CC_OUT = 'd8;

parameter MAX_POOL = 'd1, MIN_POOL = 'd2, IMAGE_FILTER = 'd3, ACT_standby = 'd10;

integer i,j;
//==================================================================
// reg & wire
//==================================================================
reg [3:0] cs,ns;
reg [7:0] r_temp, g_temp, b_temp;
reg [7:0] g0_element_temp;

reg [7:0] g0_element, g1_element, g2_element;
reg [7:0] g0_element_p1;
reg [7:0] g1_element_p1,g1_element_p2;
reg [7:0] g2_element_p1,g2_element_p2;

reg [8:0] g0_address, g1_address, g2_address;
reg [8:0] g0_address_ns, g1_address_ns, g2_address_ns;

reg round_check, round_check_ns;
reg wait_first_round;

reg [1:0] sort_ACT[0:5], sort_ACT_ns[0:5];
reg [2:0] pointer,pointer_ns;

reg neagtive_flag, neagtive_flag_ns;
reg horizontal_flag, horizontal_flag_ns;

reg [1:0] gray_scale_select, gray_scale_select_ns;
reg [1:0] image_size_reg;
reg [1:0] original_image_size;

reg pool_done, filter_done, out_done;
reg sort_done;

reg [7:0] sram_big_out_1, sram_big_out_2;
reg [8:0] address_read_sel;
reg [7:0] sram_small_out_1, sram_small_out_2;
reg [6:0] address_write_sel;
reg [8:0] address_big_base;


reg [7:0] max_min_in1, max_min_in2, max_min_in3, max_min_in4;
reg pool_flag;
reg [7:0] max_min_out;
reg [5:0] cnt_mp_sfm, cnt_mp_sfm_ns;
reg [7:0] cnt_sfm_for16x16, cnt_sfm_for16x16_ns;
reg [1:0] cnt_wait_2cycle, cnt_wait_2cycle_ns;
reg [7:0] max_min_reg [0:3];
reg [7:0] max_min_out_reg;

reg [7:0] sfm_in1,sfm_in2,sfm_in3,sfm_in4,sfm_in5,sfm_in6;
reg [7:0] sfm_in7,sfm_in8,sfm_in9,sfm_in10,sfm_in11,sfm_in12;
reg [7:0] sfm_out1,sfm_out2;

reg [7:0] sfm_reg [0:2][0:15];
reg [7:0] sram_out_to_sfm_1, sram_out_to_sfm_2;

reg [7:0] template_reg [0:2][0:2];
reg [3:0] cnt_template;

reg [4:0] cnt_cc;
reg [4:0] cnt_cc_20;
reg [19:0] cc_out;
reg [19:0] output_shift_reg;
reg [19:0] output_result_temp;
reg [3:0] cnt_row_cc_check;
reg cc_first_row_done;
reg [3:0] cnt_which_row;

reg [4:0] cnt_cc_sel;

reg use_gray_scale_check;
//==================================================================
// SRAM
//==================================================================
reg [8:0] address_big;
reg [6:0] address_small;
reg [15:0] data_big_in, data_big_out;
reg [15:0] data_small_in, data_small_out;
reg write_en_big, write_en_small;
reg wen_big_sel, wen_small_sel;
always @(*) begin
    if(cs == ACT_standby)
        wen_big_sel = 1;
    else
        wen_big_sel = write_en_big;
end
always @(*) begin
    if(cs == ACT_standby)
        wen_small_sel = 1;
    else
        wen_small_sel = write_en_small;
end
MEM512X16 U_big(.A0(address_big[0]), .A1(address_big[1]), .A2(address_big[2]), .A3(address_big[3]), .A4(address_big[4]), .A5(address_big[5]), .A6(address_big[6]), .A7(address_big[7]), .A8(address_big[8]), 
                .DO0(data_big_out[0]), .DO1(data_big_out[1]), .DO2(data_big_out[2]), .DO3(data_big_out[3]), .DO4(data_big_out[4]), .DO5(data_big_out[5]), .DO6(data_big_out[6]), .DO7(data_big_out[7]), .DO8(data_big_out[8]), .DO9(data_big_out[9]), .DO10(data_big_out[10]), .DO11(data_big_out[11]), .DO12(data_big_out[12]), .DO13(data_big_out[13]), .DO14(data_big_out[14]), .DO15(data_big_out[15]), 
                .DI0(data_big_in[0]), .DI1(data_big_in[1]), .DI2(data_big_in[2]), .DI3(data_big_in[3]), .DI4(data_big_in[4]), .DI5(data_big_in[5]), .DI6(data_big_in[6]), .DI7(data_big_in[7]), .DI8(data_big_in[8]), .DI9(data_big_in[9]), .DI10(data_big_in[10]), .DI11(data_big_in[11]), .DI12(data_big_in[12]), .DI13(data_big_in[13]), .DI14(data_big_in[14]), .DI15(data_big_in[15]),
                .CK(clk), .WEB(wen_big_sel), .OE(1'b1), .CS(1'b1));
                

MEM128X16 U_small(.A0(address_small[0]), .A1(address_small[1]), .A2(address_small[2]), .A3(address_small[3]), .A4(address_small[4]), .A5(address_small[5]), .A6(address_small[6]), 
                .DO0(data_small_out[0]), .DO1(data_small_out[1]), .DO2(data_small_out[2]), .DO3(data_small_out[3]), .DO4(data_small_out[4]), .DO5(data_small_out[5]), .DO6(data_small_out[6]), .DO7(data_small_out[7]), .DO8(data_small_out[8]), .DO9(data_small_out[9]), .DO10(data_small_out[10]), .DO11(data_small_out[11]), .DO12(data_small_out[12]), .DO13(data_small_out[13]), .DO14(data_small_out[14]), .DO15(data_small_out[15]), 
                .DI0(data_small_in[0]), .DI1(data_small_in[1]), .DI2(data_small_in[2]), .DI3(data_small_in[3]), .DI4(data_small_in[4]), .DI5(data_small_in[5]), .DI6(data_small_in[6]), .DI7(data_small_in[7]), .DI8(data_small_in[8]), .DI9(data_small_in[9]), .DI10(data_small_in[10]), .DI11(data_small_in[11]), .DI12(data_small_in[12]), .DI13(data_small_in[13]), .DI14(data_small_in[14]), .DI15(data_small_in[15]),
                .CK(clk), .WEB(wen_small_sel), .OE(1'b1), .CS(1'b1));
//==================================================================
// design
//==================================================================
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
        cs <= IDLE;
    else 
        cs <= ns;
end
always @(*) begin
    case(cs)
        IDLE        : ns = in_valid  ? RED : in_valid2 ? ACT_sort : IDLE;
        RED         : ns = in_valid2 ? ACT_sort : GREEN;
        GREEN       : ns = in_valid2 ? ACT_sort : BLUE;
        BLUE        : ns = in_valid2 ? ACT_sort : RED;
        ACT_sort    : 
        begin
            if(in_valid2) ns = ACT_sort;
            else  begin
                if(sort_ACT[0] == 0) 
                    ns = CC_OUT;
                else if(image_size_reg == 0 && (sort_ACT[0] == 1 || sort_ACT[0] == 2))
                    ns = ACT_standby;
                else
                    ns = sort_ACT[0];
            end
        end
        MAX_POOL    :  
        begin
            if(pool_done) ns = ACT_standby;
            else  ns = MAX_POOL;
        end 
        MIN_POOL    :  
        begin
            if(pool_done) ns = ACT_standby;
            else  ns = MIN_POOL;
        end
        IMAGE_FILTER:
        begin
            if(filter_done) ns = ACT_standby;
            else  ns = IMAGE_FILTER;
        end
        ACT_standby :
        begin 
            if(sort_done)
                ns = sort_ACT[0] == 0 ? CC_OUT : sort_ACT[0];
            else
                ns = ACT_standby;
        end
        CC_OUT      : ns = out_done ? IDLE : CC_OUT;
        // OUT    : ns = out_done ? IDLE : OUT;
        // OUT         : ns = IDLE;
        default     : ns = IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        wait_first_round <= 0;
    else if(cs == IDLE)
        wait_first_round <= 0;
    else if(cs == GREEN)
        wait_first_round <= 1;
    else 
        wait_first_round <= wait_first_round;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
        round_check <= 0;
    else
        round_check <= round_check_ns;
end
always @(*) begin
    round_check_ns = round_check;
    case (cs)
        IDLE    :round_check_ns = 0;
        GREEN   :round_check_ns = wait_first_round ? ~round_check : round_check; 
        ACT_sort:round_check_ns = wait_first_round ? ~round_check : round_check;
    endcase
end
//==================================================================
// Store RGB
//==================================================================
always @(posedge clk) begin
    if(ns == RED)
        r_temp <= image;
    else
        r_temp <= r_temp;
end
always @(posedge clk) begin
    if(ns == GREEN)
        g_temp <= image;
    else
        g_temp <= g_temp;
end
always @(posedge clk) begin
    if(ns == BLUE)
        b_temp <= image;
    else
        b_temp <= b_temp;
end
//==================================
// CALC grayscale
//==================================
cmp_2 u_cmp(r_temp, g_temp, b_temp, g0_element_temp);
always @(*) begin
    g0_element = 0;
    g1_element = 0;
    g2_element = 0;
    case (cs)
        BLUE:begin
            g0_element = g0_element_temp;
            g1_element = (r_temp + g_temp + b_temp)/3;
            g2_element = (r_temp >> 2) + (g_temp >> 1) + (b_temp >> 2);
        end 
    endcase
end
always @(posedge clk ) begin
    if(ns == RED)begin
        if(round_check)begin
            // g0_element_p2 <= g0_element;
            g1_element_p2 <= g1_element;
            g2_element_p2 <= g2_element;
        end
        else begin
            g0_element_p1 <= g0_element;
            g1_element_p1 <= g1_element;
            g2_element_p1 <= g2_element; 
        end
    end
end
//==================================================================
// Write_enable Control
//==================================================================
always @(posedge clk ) begin
    case (ns)
        IDLE         :write_en_big <= 1; 
        RED          :write_en_big <= round_check_ns   ? 0 : 1;
        GREEN        :write_en_big <= round_check_ns   ? 0 : 1;
        BLUE         :write_en_big <= round_check_ns   ? 0 : 1;
        ACT_sort     :write_en_big <= 1;
        MAX_POOL     :write_en_big <= pool_done     ? ~write_en_big : write_en_big; 
        MIN_POOL     :write_en_big <= pool_done     ? ~write_en_big : write_en_big;
        ACT_standby  :write_en_big <= sort_done     ? ~write_en_big : write_en_big;
        IMAGE_FILTER :write_en_big <= filter_done   ? ~write_en_big : write_en_big;
        default      :write_en_big <= write_en_big;
    endcase
end
always @(*) begin
    write_en_small = ~write_en_big;
end
//==================================================================
// Read/Write to 512X16SRAM
//==================================================================
always @(*) begin;
    address_big  = 0;
    data_big_in  = 0;
    sram_big_out_1 = 0;
    sram_big_out_2 = 0;
    case (cs)
        BLUE:begin
            if(round_check)begin
                address_big  = g0_address;
                data_big_in  = {g0_element_p1, g0_element};
            end
            
        end 
        RED:begin
            if(round_check)begin
                address_big  = g1_address;
                data_big_in  = {g1_element_p1, g1_element_p2};
            end
        end
        GREEN:begin
            if(round_check)begin
                address_big  = g2_address;
                data_big_in  = {g2_element_p1, g2_element_p2};
            end
        end
        MAX_POOL, MIN_POOL:begin
            address_big = write_en_big ? address_read_sel : {2'b00 , address_write_sel};
            {sram_big_out_1, sram_big_out_2} = data_big_out;
            if(cnt_wait_2cycle == 2 && cnt_mp_sfm[1:0] == 'b01)
                data_big_in = {max_min_out_reg,max_min_out};
        end
        IMAGE_FILTER:begin
            address_big = write_en_big ? address_read_sel : {2'b00 , address_write_sel};
            {sram_big_out_1, sram_big_out_2} = data_big_out;
            data_big_in = {sfm_out1,sfm_out2};
        end
        CC_OUT:begin
            address_big = write_en_big ? address_read_sel : {2'b00 , address_write_sel};
            {sram_big_out_1, sram_big_out_2} = data_big_out;
        end
        ACT_standby:begin
            address_big = write_en_big ? address_read_sel : {2'b00 , address_write_sel};
        end
    endcase
end
//==================================================================
// Read/Write to 128X16SRAM
//==================================================================
always @(*) begin
    address_small = 0;
    data_small_in = 0;
    sram_small_out_1 = 0;
    sram_small_out_2 = 0;
    case (cs)
        MAX_POOL, MIN_POOL:begin
            address_small = write_en_small ? address_read_sel[6:0] : address_write_sel;
            {sram_small_out_1, sram_small_out_2} = data_small_out;
            if(cnt_wait_2cycle == 2 && cnt_mp_sfm[1:0] == 'b01)
                data_small_in = {max_min_out_reg,max_min_out};
        end
        IMAGE_FILTER:begin
            address_small = write_en_small ? address_read_sel[6:0] : address_write_sel;
            {sram_small_out_1, sram_small_out_2} = data_small_out;
            data_small_in = {sfm_out1,sfm_out2};
        end
        CC_OUT:begin
            address_small = write_en_small ? address_read_sel[6:0] : address_write_sel;
            {sram_small_out_1, sram_small_out_2} = data_small_out;
        end
    endcase   
end
//==================================
// Gray Scale Address Control
//==================================
    always @(*) begin
        g0_address_ns = g0_address;
        g1_address_ns = g1_address;
        g2_address_ns = g2_address;
        case (cs)
            IDLE:begin
                g0_address_ns = 128;
                g1_address_ns = 256;
                g2_address_ns = 384;
            end 
            RED:begin
                if(round_check)
                    g1_address_ns = g1_address + 1;
            end 
            GREEN:begin
                if(round_check)
                    g2_address_ns = g2_address + 1;
            end
            BLUE:begin
                if(round_check)
                    g0_address_ns = g0_address + 1;
            end
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            g0_address <= 0;
            g1_address <= 0;
            g2_address <= 0;
        end
        else begin
            g0_address <= g0_address_ns;
            g1_address <= g1_address_ns;
            g2_address <= g2_address_ns;
        end
    end
//==================================================================
// MAX_MIN_Address_Control
//==================================================================
always @(posedge clk) begin
    if(ns == IDLE)
        use_gray_scale_check <= 0;
    else if(ns == MAX_POOL || ns == MIN_POOL || ns == IMAGE_FILTER)
        use_gray_scale_check <= 1;
    else
        use_gray_scale_check <= use_gray_scale_check;
end
//address_read
always @(posedge clk) begin
    if(ns == IDLE)
        address_read_sel <= 0;
    // else if(cs == ACT_standby && (ns == MAX_POOL || ns == MIN_POOL || ns == IMAGE_FILTER))
    //     address_read_sel <= 0;
    else begin
        if(cs == ACT_sort && (ns == MAX_POOL || ns == MIN_POOL || ns == IMAGE_FILTER || ns == CC_OUT))
            address_read_sel <= address_big_base;
        else if(cs == ACT_sort && ns == ACT_standby)
            address_read_sel <= address_big_base;
        else if(cs == ACT_standby && ns == IMAGE_FILTER && use_gray_scale_check)
            address_read_sel <= 0;
        else if(cs == ACT_standby && (ns == MAX_POOL || ns == MIN_POOL) && use_gray_scale_check)
            address_read_sel <= 0;
        else begin
            case (ns)
                ACT_standby: address_read_sel <= use_gray_scale_check ? 0 : address_read_sel;
                MAX_POOL,MIN_POOL:begin
                    case (image_size_reg)
                        'd1:begin
                            if(cnt_mp_sfm == 0)
                                address_read_sel <= address_read_sel + 4;
                            else if(cnt_mp_sfm == 1)
                                address_read_sel <= address_read_sel - 3;
                            else begin
                                if(cnt_mp_sfm[2:0] == 'b111)
                                    address_read_sel <= address_read_sel + 1;
                                else if(cnt_mp_sfm[0])
                                    address_read_sel <= address_read_sel - 3;
                                else
                                    address_read_sel <= address_read_sel + 4;
                            end
                        end
                        'd2:begin
                            if(cnt_mp_sfm == 0)
                                address_read_sel <= address_read_sel + 8;
                            else if(cnt_mp_sfm == 1)
                                address_read_sel <= address_read_sel - 7;
                            else begin
                                if(cnt_mp_sfm[3:0] == 'b1111)
                                    address_read_sel <= address_read_sel + 1;
                                else if(cnt_mp_sfm[0])
                                    address_read_sel <= address_read_sel - 7;
                                else
                                    address_read_sel <= address_read_sel + 8;
                            end      
                        end 
                        default: address_read_sel <= 0;
                    endcase
                end 
                IMAGE_FILTER:begin
                    if(use_gray_scale_check)
                        address_read_sel <= address_read_sel + 1;
                    else
                        address_read_sel <= address_big_base;
                end
                CC_OUT:begin   
                    case (image_size_reg)
                        'd0:begin
                            if(horizontal_flag)begin
                                // if(cnt_cc == 0)
                                //     address_read_sel <= address_read_sel + 1;
                                // else begin
                                    case (cnt_cc)
                                        'd0: address_read_sel <= address_read_sel + 1;//1
                                        'd1: address_read_sel <= address_read_sel + 2;//3
                                        'd2: address_read_sel <= address_read_sel - 3;//0
                                        'd3: address_read_sel <= address_read_sel + 2;//2
                                        'd4: address_read_sel <= address_read_sel + 3;//5
                                        'd5: address_read_sel <= address_read_sel - 1;//4
                                        'd6: address_read_sel <= address_read_sel + 3;//7
                                        'd7: address_read_sel <= address_read_sel - 1;//6
                                        default: address_read_sel <= address_read_sel;
                                    endcase
                                // end
                            end
                            else begin
                                case (cnt_cc)
                                    'd0: address_read_sel <= address_read_sel + 2;//2
                                    'd1: address_read_sel <= address_read_sel - 1;//1
                                    'd2: address_read_sel <= address_read_sel + 2;//3
                                    'd3: address_read_sel <= address_read_sel + 1;//4
                                    'd4: address_read_sel <= address_read_sel + 1;//5
                                    'd5: address_read_sel <= address_read_sel + 1;//6
                                    'd6: address_read_sel <= address_read_sel + 1;//7
                                    'd7: address_read_sel <= address_read_sel + 1;//0
                                    default: address_read_sel <= address_read_sel;
                                endcase
                            end
                        end
                        'd1:begin
                            if(horizontal_flag)begin
                                if(cnt_cc == 0)
                                    address_read_sel <= address_read_sel + 3;
                                else begin
                                    if(cnt_cc < 8)begin
                                        if(cnt_cc[0])
                                            address_read_sel <= address_read_sel + 4;
                                        else
                                            address_read_sel <= address_read_sel - 5;
                                    end
                                    else if(cnt_row_cc_check == 7)begin
                                        case (cnt_cc_20)
                                            'd0: address_read_sel <= address_read_sel + 7;
                                            'd1: address_read_sel <= address_read_sel - 1;
                                            'd2: address_read_sel <= address_read_sel - 1;
                                            'd3: address_read_sel <= address_read_sel - 1;
                                        endcase
                                    end
                                    else
                                        address_read_sel <= address_read_sel;
                                end
                            end
                            else begin
                                if(cnt_cc < 7)begin
                                    if(cnt_cc[0])
                                        address_read_sel <= address_read_sel - 3;
                                    else
                                        address_read_sel <= address_read_sel + 4;
                                end
                                else if(cnt_row_cc_check == 7)begin
                                    case (cnt_cc_20)
                                        'd0: address_read_sel <= address_read_sel + 1;
                                        'd1: address_read_sel <= address_read_sel + 1;
                                        'd2: address_read_sel <= address_read_sel + 1;
                                        'd3: address_read_sel <= address_read_sel + 1;
                                    endcase
                                end
                                else
                                    address_read_sel <= address_read_sel;
                            end
                        end
                        'd2:begin
                            if(horizontal_flag)begin
                                if(cnt_cc == 0)
                                    address_read_sel <= address_read_sel + 7;
                                else begin
                                    if(cnt_cc < 16)begin
                                        if(cnt_cc[0])
                                            address_read_sel <= address_read_sel + 8;
                                        else
                                            address_read_sel <= address_read_sel - 9;
                                    end
                                    else if(cnt_row_cc_check == 15)begin
                                        case (cnt_cc_20)
                                            'd0: address_read_sel <= address_read_sel + 15;
                                            'd1: address_read_sel <= address_read_sel - 1;
                                            'd2: address_read_sel <= address_read_sel - 1;
                                            'd3: address_read_sel <= address_read_sel - 1;
                                            'd4: address_read_sel <= address_read_sel - 1;
                                            'd5: address_read_sel <= address_read_sel - 1;
                                            'd6: address_read_sel <= address_read_sel - 1;
                                            'd7: address_read_sel <= address_read_sel - 1;
                                        endcase
                                    end
                                    else
                                        address_read_sel <= address_read_sel;
                                end
                            end
                            else begin
                                if(cnt_cc < 15)begin
                                    if(cnt_cc[0])
                                        address_read_sel <= address_read_sel - 7;
                                    else
                                        address_read_sel <= address_read_sel + 8;
                                end
                                else if(cnt_row_cc_check == 15)begin
                                    case (cnt_cc_20)
                                        'd0: address_read_sel <= address_read_sel + 1;
                                        'd1: address_read_sel <= address_read_sel + 1;
                                        'd2: address_read_sel <= address_read_sel + 1;
                                        'd3: address_read_sel <= address_read_sel + 1;
                                        'd4: address_read_sel <= address_read_sel + 1;
                                        'd5: address_read_sel <= address_read_sel + 1;
                                        'd6: address_read_sel <= address_read_sel + 1;
                                        'd7: address_read_sel <= address_read_sel + 1;
                                    endcase
                                end
                                else
                                    address_read_sel <= address_read_sel;
                            end
                        end 
                        default: address_read_sel <= address_read_sel;
                    endcase
                    end
                default: address_read_sel <= 0; 
            endcase
            
        end
    end
end
//address_write
always @(posedge clk) begin
    if(ns == IDLE || ns == ACT_standby)
        address_write_sel <= 0;
    else if(cs == ACT_standby && (ns == MAX_POOL || ns == MIN_POOL || ns == IMAGE_FILTER))
        address_write_sel <= 0;
    //maybe can delete
    else begin
        case (ns)
            MAX_POOL,MIN_POOL:begin
                if(cnt_wait_2cycle == 2 && cnt_mp_sfm[1:0] == 'b01)
                    address_write_sel <= address_write_sel + 1;
                else
                    address_write_sel <= address_write_sel;
            end
            IMAGE_FILTER:begin
                case (image_size_reg)
                    'd0:begin
                        if(cnt_mp_sfm > 4)
                            address_write_sel <= address_write_sel + 1;
                        else
                            address_write_sel <= 0;
                    end
                    'd1:begin
                        if(cnt_mp_sfm > 6)
                            address_write_sel <= address_write_sel + 1;
                        else
                            address_write_sel <= 0;
                    end
                    'd2:begin
                        if(cnt_sfm_for16x16 > 10)
                            address_write_sel <= address_write_sel + 1;
                        else
                            address_write_sel <= 0;
                    end
                endcase
            end  
        endcase
    end
end
//==================================================================
// ACT_done
//==================================================================
always @(*) begin
    case (image_size_reg)
        'd2:pool_done = (address_write_sel == 31 && cnt_mp_sfm[1:0] == 1 ) ? 1 : 0;
        'd1:pool_done = (address_write_sel == 7  && cnt_mp_sfm[1:0] == 1 ) ? 1 : 0;
        default: pool_done = 0;
    endcase
end
always @(*) begin
    case (image_size_reg)
        'd2:filter_done = (address_write_sel == 127) ? 1 : 0;// && cnt_mp_sfm == 1
        'd1:filter_done = (address_write_sel == 31) ? 1 : 0;// && cnt_mp_sfm == 1 
        'd0:filter_done = (address_write_sel == 7 ) ? 1 : 0;// && cnt_mp_sfm == 1
        default: filter_done = 0;
    endcase
end
always @(*) begin
    case (image_size_reg)
        'd0:out_done = (cnt_which_row == 3  && cnt_row_cc_check == 3  && cnt_cc_20 == 19)  ? 1 : 0;
        'd1:out_done = (cnt_which_row == 7  && cnt_row_cc_check == 7  && cnt_cc_20 == 19)  ? 1 : 0;
        'd2:out_done = (cnt_which_row == 15 && cnt_row_cc_check == 15 && cnt_cc_20 == 19)  ? 1 : 0; 
        default: out_done = 0;
    endcase
end
//==================================================================
// ACT_Sorting
//==================================================================
always @(posedge clk ) begin
    pointer <= pointer_ns;
end
always @(posedge clk ) begin
    for(i = 0; i < 6; i = i + 1)
        sort_ACT[i] <= sort_ACT_ns[i];
end
always @(*) begin
    pointer_ns = pointer;
    for(i = 0; i < 6; i = i + 1)
        sort_ACT_ns[i] = sort_ACT[i];
    case(ns)//be careful
        IDLE:begin
            pointer_ns = 0;
            for(i = 0; i < 6; i = i + 1)
                sort_ACT_ns[i] = 0;
        end
        ACT_sort:begin
            if(action == 'd3)begin
                if (neagtive_flag) begin
                    sort_ACT_ns[pointer] = MIN_POOL;
                    pointer_ns = pointer + 1;
                end
                else begin
                    sort_ACT_ns[pointer] = MAX_POOL;
                    pointer_ns = pointer + 1;
                end
            end
            else if(action == 'd6)begin
                sort_ACT_ns[pointer] = IMAGE_FILTER;
                pointer_ns = pointer + 1;
            end
        end
        ACT_standby:begin
            sort_ACT_ns[0] = sort_ACT[1];
            sort_ACT_ns[1] = sort_ACT[2];
            sort_ACT_ns[2] = sort_ACT[3];
            sort_ACT_ns[3] = sort_ACT[4];
            sort_ACT_ns[4] = sort_ACT[5];
            sort_ACT_ns[5] = 0;
        end
    endcase
end
always @(*) begin
    if(image_size_reg == 0)
        if(sort_ACT[0] == 1 || sort_ACT[0] == 2)
            sort_done = 0;
        else
            sort_done = 1;
    else
        sort_done = 1;
end
//==================================
// neagtive_flag, horizontal_flag
//==================================
// always @(posedge clk) begin
//     neagtive_flag <= neagtive_flag_ns;
//     horizontal_flag <= horizontal_flag_ns;
// end
// always @(*) begin
//     if(cs == IDLE)
//         neagtive_flag_ns = 0;
//     else if (in_valid2)begin
//         if (action == 'd4) 
//             neagtive_flag_ns = ~neagtive_flag;
//         else
//             neagtive_flag_ns = neagtive_flag;
//     end
//     else
//         neagtive_flag_ns = neagtive_flag;
// end
// always @(*) begin
//     if(cs == IDLE)
//         horizontal_flag_ns = 0;
//     else if (in_valid2)begin
//         if (action == 'd5) 
//             horizontal_flag_ns = ~horizontal_flag;        
//         else
//             horizontal_flag_ns = horizontal_flag;
//     end
//     else
//         horizontal_flag_ns = horizontal_flag;
// end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        neagtive_flag <= 0;
    else if(ns == IDLE)
        neagtive_flag <= 0;
    else if(in_valid2)
        if(action == 'd4) 
            neagtive_flag <= ~neagtive_flag;
        else
            neagtive_flag <= neagtive_flag;
    else
        neagtive_flag <= neagtive_flag;        
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        horizontal_flag <= 0;
    else if(ns == IDLE)
        horizontal_flag <= 0;
    else if(in_valid2)
        if(action == 'd5) 
            horizontal_flag <= ~horizontal_flag;
        else
            horizontal_flag <= horizontal_flag;
    else
        horizontal_flag <= horizontal_flag;
end
//==================================
// gray_scale_select,image_size
//==================================
always @(posedge clk ) begin
    if(cs == IDLE && in_valid)
        image_size_reg <= image_size;
    else if(cs == IDLE)
        image_size_reg <= original_image_size;
    else if(pool_done && (cs == MAX_POOL || cs == MIN_POOL))
        image_size_reg <= image_size_reg - 1;
    else
        image_size_reg <= image_size_reg;
end
always @(posedge clk ) begin
    if(cs == IDLE && in_valid)
        original_image_size <= image_size;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        gray_scale_select <= 0;
    else if (in_valid2)
        case (action)
            'd0:
                gray_scale_select <= 1;
            'd1:
                gray_scale_select <= 2;
            'd2:
                gray_scale_select <= 3;
            default: gray_scale_select <= gray_scale_select;
        endcase
    else
        gray_scale_select <= gray_scale_select;
end
// always @(*) begin
//     gray_scale_select_ns = gray_scale_select;  
//     if(in_valid2)begin
//         case (action)
//             'd0:
//                 gray_scale_select_ns = 1;
//             'd1:
//                 gray_scale_select_ns = 2;
//             'd2:
//                 gray_scale_select_ns = 3;         
//         endcase
//     end
// end
always @(*) begin
    case (gray_scale_select)
        0:address_big_base = 0;
        1:address_big_base = 128;
        2:address_big_base = 256;
        3:address_big_base = 384;
    endcase
end
//==================================================================
// MAX_MIN_POOL
//==================================================================
max_min_pool u_max_min_pool
(
    max_min_in1, max_min_in2, max_min_in3, max_min_in4,
    pool_flag,
    max_min_out
);
always @(*) begin
    max_min_in1 = max_min_reg [0];
    max_min_in2 = max_min_reg [1];
    max_min_in3 = max_min_reg [2];
    max_min_in4 = max_min_reg [3];
end
always @(*) begin
    case (cs)
        MAX_POOL:pool_flag = 1;
        MIN_POOL:pool_flag = 0; 
        default :pool_flag = 0; 
    endcase
end
always @(posedge clk) begin
    // if(~rst_n)begin
        
    // end
    cnt_mp_sfm <= cnt_mp_sfm_ns;
    cnt_sfm_for16x16 <= cnt_sfm_for16x16_ns;
end
always @(*) begin
    cnt_mp_sfm_ns = 0;
    case (cs)
        MAX_POOL    :cnt_mp_sfm_ns = cnt_mp_sfm + 1 ;
        MIN_POOL    :cnt_mp_sfm_ns = cnt_mp_sfm + 1 ;
        IMAGE_FILTER:cnt_mp_sfm_ns = cnt_mp_sfm + 1 ;
    endcase
end
always @(*) begin
    cnt_sfm_for16x16_ns = 0;
    case (cs)
        IMAGE_FILTER:cnt_sfm_for16x16_ns = cnt_sfm_for16x16 + 1 ;
    endcase
end
always @(posedge clk) begin
    cnt_wait_2cycle <= cnt_wait_2cycle_ns;
end
always @(*) begin
    cnt_wait_2cycle_ns = cnt_wait_2cycle;
    case (cs)
        IDLE       :cnt_wait_2cycle_ns = 0;
        ACT_standby:cnt_wait_2cycle_ns = 0;
        MAX_POOL   :cnt_wait_2cycle_ns = cnt_wait_2cycle == 2 ? cnt_wait_2cycle : cnt_wait_2cycle + 1;//modify
        MIN_POOL   :cnt_wait_2cycle_ns = cnt_wait_2cycle == 2 ? cnt_wait_2cycle : cnt_wait_2cycle + 1;//modify
    endcase
end
always @(posedge clk) begin
    max_min_reg [2] <= write_en_big ? sram_big_out_1 : sram_small_out_1;
    max_min_reg [3] <= write_en_big ? sram_big_out_2 : sram_small_out_2;
    max_min_reg [0] <= max_min_reg [2];
    max_min_reg [1] <= max_min_reg [3];
end
always @(posedge clk) begin
    if(cnt_mp_sfm[1:0] == 'b11)
        max_min_out_reg <= max_min_out;
end
//==================================================================
//Image Filter
//==================================================================
sorting_find_median u_sorting_find_median(
    sfm_in1,sfm_in2,sfm_in3,sfm_in4,sfm_in5,sfm_in6,
    sfm_in7,sfm_in8,sfm_in9,sfm_in10,sfm_in11,sfm_in12,
    sfm_out1,sfm_out2
);
always @(*) begin
    sfm_in1 = 0; sfm_in4 = 0; sfm_in7 = 0; sfm_in10 = 0;
    sfm_in2 = 0; sfm_in5 = 0; sfm_in8 = 0; sfm_in11 = 0;
    sfm_in3 = 0; sfm_in6 = 0; sfm_in9 = 0; sfm_in12 = 0;
    case (image_size_reg)
        'd0:begin
            case (cnt_mp_sfm)
                'd5:begin
                    sfm_in1 = sfm_reg[0][0]; sfm_in4 = sfm_reg[0][0]; sfm_in7 = sfm_reg[0][1]; sfm_in10 = sfm_reg[0][2]; 
                    sfm_in2 = sfm_reg[0][0]; sfm_in5 = sfm_reg[0][0]; sfm_in8 = sfm_reg[0][1]; sfm_in11 = sfm_reg[0][2];
                    sfm_in3 = sfm_reg[1][0]; sfm_in6 = sfm_reg[1][0]; sfm_in9 = sfm_reg[1][1]; sfm_in12 = sfm_reg[1][2];
                end 
                'd6:begin
                    sfm_in1 = sfm_reg[0][1]; sfm_in4 = sfm_reg[0][2]; sfm_in7 = sfm_reg[0][3]; sfm_in10 = sfm_reg[0][3]; 
                    sfm_in2 = sfm_reg[0][1]; sfm_in5 = sfm_reg[0][2]; sfm_in8 = sfm_reg[0][3]; sfm_in11 = sfm_reg[0][3];
                    sfm_in3 = sfm_reg[1][1]; sfm_in6 = sfm_reg[1][2]; sfm_in9 = sfm_reg[1][3]; sfm_in12 = sfm_reg[1][3];
                end
                'd7:begin
                    sfm_in1 = sfm_reg[0][0]; sfm_in4 = sfm_reg[0][0]; sfm_in7 = sfm_reg[0][1]; sfm_in10 = sfm_reg[0][2]; 
                    sfm_in2 = sfm_reg[1][0]; sfm_in5 = sfm_reg[1][0]; sfm_in8 = sfm_reg[1][1]; sfm_in11 = sfm_reg[1][2];
                    sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2];
                end
                'd8:begin
                    sfm_in1 = sfm_reg[0][1]; sfm_in4 = sfm_reg[0][2]; sfm_in7 = sfm_reg[0][3]; sfm_in10 = sfm_reg[0][3]; 
                    sfm_in2 = sfm_reg[1][1]; sfm_in5 = sfm_reg[1][2]; sfm_in8 = sfm_reg[1][3]; sfm_in11 = sfm_reg[1][3];
                    sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][3];
                end 
                'd9:begin
                    sfm_in1 = sfm_reg[1][0]; sfm_in4 = sfm_reg[1][0]; sfm_in7 = sfm_reg[1][1]; sfm_in10 = sfm_reg[1][2]; 
                    sfm_in2 = sfm_reg[2][0]; sfm_in5 = sfm_reg[2][0]; sfm_in8 = sfm_reg[2][1]; sfm_in11 = sfm_reg[2][2];
                    sfm_in3 = sfm_reg[0][4]; sfm_in6 = sfm_reg[0][4]; sfm_in9 = sfm_reg[0][5]; sfm_in12 = sfm_reg[0][6];
                end
                'd10:begin
                    sfm_in1 = sfm_reg[1][1]; sfm_in4 = sfm_reg[1][2]; sfm_in7 = sfm_reg[1][3]; sfm_in10 = sfm_reg[1][3]; 
                    sfm_in2 = sfm_reg[2][1]; sfm_in5 = sfm_reg[2][2]; sfm_in8 = sfm_reg[2][3]; sfm_in11 = sfm_reg[2][3];
                    sfm_in3 = sfm_reg[0][5]; sfm_in6 = sfm_reg[0][6]; sfm_in9 = sfm_reg[0][7]; sfm_in12 = sfm_reg[0][7];
                end
                'd11:begin
                    sfm_in1 = sfm_reg[2][0]; sfm_in4 = sfm_reg[2][0]; sfm_in7 = sfm_reg[2][1]; sfm_in10 = sfm_reg[2][2]; 
                    sfm_in2 = sfm_reg[0][4]; sfm_in5 = sfm_reg[0][4]; sfm_in8 = sfm_reg[0][5]; sfm_in11 = sfm_reg[0][6];
                    sfm_in3 = sfm_reg[0][4]; sfm_in6 = sfm_reg[0][4]; sfm_in9 = sfm_reg[0][5]; sfm_in12 = sfm_reg[0][6];
                end
                'd12:begin
                    sfm_in1 = sfm_reg[2][1]; sfm_in4 = sfm_reg[2][2]; sfm_in7 = sfm_reg[2][3]; sfm_in10 = sfm_reg[2][3]; 
                    sfm_in2 = sfm_reg[0][5]; sfm_in5 = sfm_reg[0][6]; sfm_in8 = sfm_reg[0][7]; sfm_in11 = sfm_reg[0][7];
                    sfm_in3 = sfm_reg[0][5]; sfm_in6 = sfm_reg[0][6]; sfm_in9 = sfm_reg[0][7]; sfm_in12 = sfm_reg[0][7];
                end
            endcase
        end 
        'd1:begin
            if(cnt_mp_sfm > 10 && cnt_mp_sfm < 35)begin
                case (cnt_mp_sfm[1:0])
                    'b11:begin
                        sfm_in1 = sfm_reg[0][0]; sfm_in4 = sfm_reg[0][0]; sfm_in7 = sfm_reg[0][1]; sfm_in10 = sfm_reg[0][2];
                        sfm_in2 = sfm_reg[1][0]; sfm_in5 = sfm_reg[1][0]; sfm_in8 = sfm_reg[1][1]; sfm_in11 = sfm_reg[1][2];
                        sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2];
                    end
                    'b00:begin
                        sfm_in1 = sfm_reg[0][1]; sfm_in4 = sfm_reg[0][2]; sfm_in7 = sfm_reg[0][3]; sfm_in10 = sfm_reg[0][4];
                        sfm_in2 = sfm_reg[1][1]; sfm_in5 = sfm_reg[1][2]; sfm_in8 = sfm_reg[1][3]; sfm_in11 = sfm_reg[1][4];
                        sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][4];
                    end
                    'b01:begin
                        sfm_in1 = sfm_reg[0][3]; sfm_in4 = sfm_reg[0][4]; sfm_in7 = sfm_reg[0][5]; sfm_in10 = sfm_reg[0][6];
                        sfm_in2 = sfm_reg[1][3]; sfm_in5 = sfm_reg[1][4]; sfm_in8 = sfm_reg[1][5]; sfm_in11 = sfm_reg[1][6];
                        sfm_in3 = sfm_reg[2][3]; sfm_in6 = sfm_reg[2][4]; sfm_in9 = sfm_reg[2][5]; sfm_in12 = sfm_reg[2][6];
                    end
                    'b10:begin
                        sfm_in1 = sfm_reg[0][5]; sfm_in4 = sfm_reg[0][6]; sfm_in7 = sfm_reg[0][7]; sfm_in10 = sfm_reg[0][7];
                        sfm_in2 = sfm_reg[1][5]; sfm_in5 = sfm_reg[1][6]; sfm_in8 = sfm_reg[1][7]; sfm_in11 = sfm_reg[1][7];
                        sfm_in3 = sfm_reg[2][5]; sfm_in6 = sfm_reg[2][6]; sfm_in9 = sfm_reg[2][7]; sfm_in12 = sfm_reg[2][7];
                    end
                endcase
            end
            else begin
                case (cnt_mp_sfm)
                    'd7:begin
                        sfm_in1 = sfm_reg[1][0]; sfm_in4 = sfm_reg[1][0]; sfm_in7 = sfm_reg[1][1]; sfm_in10 = sfm_reg[1][2];
                        sfm_in2 = sfm_reg[1][0]; sfm_in5 = sfm_reg[1][0]; sfm_in8 = sfm_reg[1][1]; sfm_in11 = sfm_reg[1][2];
                        sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2];    
                    end 
                    'd8:begin
                        sfm_in1 = sfm_reg[1][1]; sfm_in4 = sfm_reg[1][2]; sfm_in7 = sfm_reg[1][3]; sfm_in10 = sfm_reg[1][4];
                        sfm_in2 = sfm_reg[1][1]; sfm_in5 = sfm_reg[1][2]; sfm_in8 = sfm_reg[1][3]; sfm_in11 = sfm_reg[1][4];
                        sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][4];
                    end
                    'd9:begin
                        sfm_in1 = sfm_reg[1][3]; sfm_in4 = sfm_reg[1][4]; sfm_in7 = sfm_reg[1][5]; sfm_in10 = sfm_reg[1][6];
                        sfm_in2 = sfm_reg[1][3]; sfm_in5 = sfm_reg[1][4]; sfm_in8 = sfm_reg[1][5]; sfm_in11 = sfm_reg[1][6];
                        sfm_in3 = sfm_reg[2][3]; sfm_in6 = sfm_reg[2][4]; sfm_in9 = sfm_reg[2][5]; sfm_in12 = sfm_reg[2][6];
                    end
                    'd10:begin
                        sfm_in1 = sfm_reg[1][5]; sfm_in4 = sfm_reg[1][6]; sfm_in7 = sfm_reg[1][7]; sfm_in10 = sfm_reg[1][7];
                        sfm_in2 = sfm_reg[1][5]; sfm_in5 = sfm_reg[1][6]; sfm_in8 = sfm_reg[1][7]; sfm_in11 = sfm_reg[1][7];
                        sfm_in3 = sfm_reg[2][5]; sfm_in6 = sfm_reg[2][6]; sfm_in9 = sfm_reg[2][7]; sfm_in12 = sfm_reg[2][7];
                    end
                    'd35:begin
                        sfm_in1 = sfm_reg[1][0]; sfm_in4 = sfm_reg[1][0]; sfm_in7 = sfm_reg[1][1]; sfm_in10 = sfm_reg[1][2];
                        sfm_in2 = sfm_reg[2][0]; sfm_in5 = sfm_reg[2][0]; sfm_in8 = sfm_reg[2][1]; sfm_in11 = sfm_reg[2][2];
                        sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2];
                    end
                    'd36:begin
                        sfm_in1 = sfm_reg[1][1]; sfm_in4 = sfm_reg[1][2]; sfm_in7 = sfm_reg[1][3]; sfm_in10 = sfm_reg[1][4];
                        sfm_in2 = sfm_reg[2][1]; sfm_in5 = sfm_reg[2][2]; sfm_in8 = sfm_reg[2][3]; sfm_in11 = sfm_reg[2][4];
                        sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][4];
                    end
                    'd37:begin
                        sfm_in1 = sfm_reg[1][3]; sfm_in4 = sfm_reg[1][4]; sfm_in7 = sfm_reg[1][5]; sfm_in10 = sfm_reg[1][6];
                        sfm_in2 = sfm_reg[2][3]; sfm_in5 = sfm_reg[2][4]; sfm_in8 = sfm_reg[2][5]; sfm_in11 = sfm_reg[2][6];
                        sfm_in3 = sfm_reg[2][3]; sfm_in6 = sfm_reg[2][4]; sfm_in9 = sfm_reg[2][5]; sfm_in12 = sfm_reg[2][6];
                    end
                    'd38:begin
                        sfm_in1 = sfm_reg[1][5]; sfm_in4 = sfm_reg[1][6]; sfm_in7 = sfm_reg[1][7]; sfm_in10 = sfm_reg[1][7];
                        sfm_in2 = sfm_reg[2][5]; sfm_in5 = sfm_reg[2][6]; sfm_in8 = sfm_reg[2][7]; sfm_in11 = sfm_reg[2][7];
                        sfm_in3 = sfm_reg[2][5]; sfm_in6 = sfm_reg[2][6]; sfm_in9 = sfm_reg[2][7]; sfm_in12 = sfm_reg[2][7];
                    end
                endcase
            end
        end
        'd2:begin
            if(cnt_sfm_for16x16 > 18 && cnt_sfm_for16x16 < 131)begin
                case (cnt_sfm_for16x16[2:0])
                    'b011:begin
                        sfm_in1 = sfm_reg[0][0]; sfm_in4 = sfm_reg[0][0]; sfm_in7 = sfm_reg[0][1]; sfm_in10 = sfm_reg[0][2];
                        sfm_in2 = sfm_reg[1][0]; sfm_in5 = sfm_reg[1][0]; sfm_in8 = sfm_reg[1][1]; sfm_in11 = sfm_reg[1][2];
                        sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2];
                    end 
                    'b100:begin
                        sfm_in1 = sfm_reg[0][1]; sfm_in4 = sfm_reg[0][2]; sfm_in7 = sfm_reg[0][3]; sfm_in10 = sfm_reg[0][4];
                        sfm_in2 = sfm_reg[1][1]; sfm_in5 = sfm_reg[1][2]; sfm_in8 = sfm_reg[1][3]; sfm_in11 = sfm_reg[1][4];
                        sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][4];
                    end
                    'b101:begin
                        sfm_in1 = sfm_reg[0][3]; sfm_in4 = sfm_reg[0][4]; sfm_in7 = sfm_reg[0][5]; sfm_in10 = sfm_reg[0][6];
                        sfm_in2 = sfm_reg[1][3]; sfm_in5 = sfm_reg[1][4]; sfm_in8 = sfm_reg[1][5]; sfm_in11 = sfm_reg[1][6];
                        sfm_in3 = sfm_reg[2][3]; sfm_in6 = sfm_reg[2][4]; sfm_in9 = sfm_reg[2][5]; sfm_in12 = sfm_reg[2][6];
                    end
                    'b110:begin
                        sfm_in1 = sfm_reg[0][5]; sfm_in4 = sfm_reg[0][6]; sfm_in7 = sfm_reg[0][7]; sfm_in10 = sfm_reg[0][8];
                        sfm_in2 = sfm_reg[1][5]; sfm_in5 = sfm_reg[1][6]; sfm_in8 = sfm_reg[1][7]; sfm_in11 = sfm_reg[1][8];
                        sfm_in3 = sfm_reg[2][5]; sfm_in6 = sfm_reg[2][6]; sfm_in9 = sfm_reg[2][7]; sfm_in12 = sfm_reg[2][8];
                    end
                    'b111:begin
                        sfm_in1 = sfm_reg[0][7]; sfm_in4 = sfm_reg[0][8]; sfm_in7 = sfm_reg[0][9]; sfm_in10 = sfm_reg[0][10];
                        sfm_in2 = sfm_reg[1][7]; sfm_in5 = sfm_reg[1][8]; sfm_in8 = sfm_reg[1][9]; sfm_in11 = sfm_reg[1][10];
                        sfm_in3 = sfm_reg[2][7]; sfm_in6 = sfm_reg[2][8]; sfm_in9 = sfm_reg[2][9]; sfm_in12 = sfm_reg[2][10];
                    end
                    'b000:begin
                        sfm_in1 = sfm_reg[0][9]; sfm_in4 = sfm_reg[0][10]; sfm_in7 = sfm_reg[0][11]; sfm_in10 = sfm_reg[0][12];
                        sfm_in2 = sfm_reg[1][9]; sfm_in5 = sfm_reg[1][10]; sfm_in8 = sfm_reg[1][11]; sfm_in11 = sfm_reg[1][12];
                        sfm_in3 = sfm_reg[2][9]; sfm_in6 = sfm_reg[2][10]; sfm_in9 = sfm_reg[2][11]; sfm_in12 = sfm_reg[2][12];
                    end
                    'b001:begin
                        sfm_in1 = sfm_reg[0][11]; sfm_in4 = sfm_reg[0][12]; sfm_in7 = sfm_reg[0][13]; sfm_in10 = sfm_reg[0][14];
                        sfm_in2 = sfm_reg[1][11]; sfm_in5 = sfm_reg[1][12]; sfm_in8 = sfm_reg[1][13]; sfm_in11 = sfm_reg[1][14];
                        sfm_in3 = sfm_reg[2][11]; sfm_in6 = sfm_reg[2][12]; sfm_in9 = sfm_reg[2][13]; sfm_in12 = sfm_reg[2][14];
                    end
                    'b010:begin
                        sfm_in1 = sfm_reg[0][13]; sfm_in4 = sfm_reg[0][14]; sfm_in7 = sfm_reg[0][15]; sfm_in10 = sfm_reg[0][15];
                        sfm_in2 = sfm_reg[1][13]; sfm_in5 = sfm_reg[1][14]; sfm_in8 = sfm_reg[1][15]; sfm_in11 = sfm_reg[1][15];
                        sfm_in3 = sfm_reg[2][13]; sfm_in6 = sfm_reg[2][14]; sfm_in9 = sfm_reg[2][15]; sfm_in12 = sfm_reg[2][15];
                    end
                endcase
            end
            else begin
                case (cnt_sfm_for16x16)
                    'd11:begin
                        sfm_in1 = sfm_reg[1][0]; sfm_in4 = sfm_reg[1][0]; sfm_in7 = sfm_reg[1][1]; sfm_in10 = sfm_reg[1][2];
                        sfm_in2 = sfm_reg[1][0]; sfm_in5 = sfm_reg[1][0]; sfm_in8 = sfm_reg[1][1]; sfm_in11 = sfm_reg[1][2];
                        sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2]; 
                    end 
                    'd12:begin
                        sfm_in1 = sfm_reg[1][1]; sfm_in4 = sfm_reg[1][2]; sfm_in7 = sfm_reg[1][3]; sfm_in10 = sfm_reg[1][4];
                        sfm_in2 = sfm_reg[1][1]; sfm_in5 = sfm_reg[1][2]; sfm_in8 = sfm_reg[1][3]; sfm_in11 = sfm_reg[1][4];
                        sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][4];
                    end
                    'd13:begin
                        sfm_in1 = sfm_reg[1][3]; sfm_in4 = sfm_reg[1][4]; sfm_in7 = sfm_reg[1][5]; sfm_in10 = sfm_reg[1][6];
                        sfm_in2 = sfm_reg[1][3]; sfm_in5 = sfm_reg[1][4]; sfm_in8 = sfm_reg[1][5]; sfm_in11 = sfm_reg[1][6];
                        sfm_in3 = sfm_reg[2][3]; sfm_in6 = sfm_reg[2][4]; sfm_in9 = sfm_reg[2][5]; sfm_in12 = sfm_reg[2][6];
                    end
                    'd14:begin
                        sfm_in1 = sfm_reg[1][5]; sfm_in4 = sfm_reg[1][6]; sfm_in7 = sfm_reg[1][7]; sfm_in10 = sfm_reg[1][8];
                        sfm_in2 = sfm_reg[1][5]; sfm_in5 = sfm_reg[1][6]; sfm_in8 = sfm_reg[1][7]; sfm_in11 = sfm_reg[1][8];
                        sfm_in3 = sfm_reg[2][5]; sfm_in6 = sfm_reg[2][6]; sfm_in9 = sfm_reg[2][7]; sfm_in12 = sfm_reg[2][8];
                    end
                    'd15:begin
                        sfm_in1 = sfm_reg[1][7]; sfm_in4 = sfm_reg[1][8]; sfm_in7 = sfm_reg[1][9]; sfm_in10 = sfm_reg[1][10];
                        sfm_in2 = sfm_reg[1][7]; sfm_in5 = sfm_reg[1][8]; sfm_in8 = sfm_reg[1][9]; sfm_in11 = sfm_reg[1][10];
                        sfm_in3 = sfm_reg[2][7]; sfm_in6 = sfm_reg[2][8]; sfm_in9 = sfm_reg[2][9]; sfm_in12 = sfm_reg[2][10];
                    end
                    'd16:begin
                        sfm_in1 = sfm_reg[1][9]; sfm_in4 = sfm_reg[1][10]; sfm_in7 = sfm_reg[1][11]; sfm_in10 = sfm_reg[1][12];
                        sfm_in2 = sfm_reg[1][9]; sfm_in5 = sfm_reg[1][10]; sfm_in8 = sfm_reg[1][11]; sfm_in11 = sfm_reg[1][12];
                        sfm_in3 = sfm_reg[2][9]; sfm_in6 = sfm_reg[2][10]; sfm_in9 = sfm_reg[2][11]; sfm_in12 = sfm_reg[2][12];
                    end
                    'd17:begin
                        sfm_in1 = sfm_reg[1][11]; sfm_in4 = sfm_reg[1][12]; sfm_in7 = sfm_reg[1][13]; sfm_in10 = sfm_reg[1][14];
                        sfm_in2 = sfm_reg[1][11]; sfm_in5 = sfm_reg[1][12]; sfm_in8 = sfm_reg[1][13]; sfm_in11 = sfm_reg[1][14];
                        sfm_in3 = sfm_reg[2][11]; sfm_in6 = sfm_reg[2][12]; sfm_in9 = sfm_reg[2][13]; sfm_in12 = sfm_reg[2][14];
                    end
                    'd18:begin
                        sfm_in1 = sfm_reg[1][13]; sfm_in4 = sfm_reg[1][14]; sfm_in7 = sfm_reg[1][15]; sfm_in10 = sfm_reg[1][15];
                        sfm_in2 = sfm_reg[1][13]; sfm_in5 = sfm_reg[1][14]; sfm_in8 = sfm_reg[1][15]; sfm_in11 = sfm_reg[1][15];
                        sfm_in3 = sfm_reg[2][13]; sfm_in6 = sfm_reg[2][14]; sfm_in9 = sfm_reg[2][15]; sfm_in12 = sfm_reg[2][15];
                    end
                    'd131:begin
                        sfm_in1 = sfm_reg[1][0]; sfm_in4 = sfm_reg[1][0]; sfm_in7 = sfm_reg[1][1]; sfm_in10 = sfm_reg[1][2];
                        sfm_in2 = sfm_reg[2][0]; sfm_in5 = sfm_reg[2][0]; sfm_in8 = sfm_reg[2][1]; sfm_in11 = sfm_reg[2][2];
                        sfm_in3 = sfm_reg[2][0]; sfm_in6 = sfm_reg[2][0]; sfm_in9 = sfm_reg[2][1]; sfm_in12 = sfm_reg[2][2];
                    end
                    'd132:begin
                        sfm_in1 = sfm_reg[1][1]; sfm_in4 = sfm_reg[1][2]; sfm_in7 = sfm_reg[1][3]; sfm_in10 = sfm_reg[1][4];
                        sfm_in2 = sfm_reg[2][1]; sfm_in5 = sfm_reg[2][2]; sfm_in8 = sfm_reg[2][3]; sfm_in11 = sfm_reg[2][4];
                        sfm_in3 = sfm_reg[2][1]; sfm_in6 = sfm_reg[2][2]; sfm_in9 = sfm_reg[2][3]; sfm_in12 = sfm_reg[2][4];
                    end
                    'd133:begin
                        sfm_in1 = sfm_reg[1][3]; sfm_in4 = sfm_reg[1][4]; sfm_in7 = sfm_reg[1][5]; sfm_in10 = sfm_reg[1][6];
                        sfm_in2 = sfm_reg[2][3]; sfm_in5 = sfm_reg[2][4]; sfm_in8 = sfm_reg[2][5]; sfm_in11 = sfm_reg[2][6];
                        sfm_in3 = sfm_reg[2][3]; sfm_in6 = sfm_reg[2][4]; sfm_in9 = sfm_reg[2][5]; sfm_in12 = sfm_reg[2][6];
                    end
                    'd134:begin
                        sfm_in1 = sfm_reg[1][5]; sfm_in4 = sfm_reg[1][6]; sfm_in7 = sfm_reg[1][7]; sfm_in10 = sfm_reg[1][8];
                        sfm_in2 = sfm_reg[2][5]; sfm_in5 = sfm_reg[2][6]; sfm_in8 = sfm_reg[2][7]; sfm_in11 = sfm_reg[2][8];
                        sfm_in3 = sfm_reg[2][5]; sfm_in6 = sfm_reg[2][6]; sfm_in9 = sfm_reg[2][7]; sfm_in12 = sfm_reg[2][8];
                    end
                    'd135:begin
                        sfm_in1 = sfm_reg[1][7]; sfm_in4 = sfm_reg[1][8]; sfm_in7 = sfm_reg[1][9]; sfm_in10 = sfm_reg[1][10];
                        sfm_in2 = sfm_reg[2][7]; sfm_in5 = sfm_reg[2][8]; sfm_in8 = sfm_reg[2][9]; sfm_in11 = sfm_reg[2][10];
                        sfm_in3 = sfm_reg[2][7]; sfm_in6 = sfm_reg[2][8]; sfm_in9 = sfm_reg[2][9]; sfm_in12 = sfm_reg[2][10];
                    end
                    'd136:begin
                        sfm_in1 = sfm_reg[1][9]; sfm_in4 = sfm_reg[1][10]; sfm_in7 = sfm_reg[1][11]; sfm_in10 = sfm_reg[1][12];
                        sfm_in2 = sfm_reg[2][9]; sfm_in5 = sfm_reg[2][10]; sfm_in8 = sfm_reg[2][11]; sfm_in11 = sfm_reg[2][12];
                        sfm_in3 = sfm_reg[2][9]; sfm_in6 = sfm_reg[2][10]; sfm_in9 = sfm_reg[2][11]; sfm_in12 = sfm_reg[2][12];
                    end
                    'd137:begin
                        sfm_in1 = sfm_reg[1][11]; sfm_in4 = sfm_reg[1][12]; sfm_in7 = sfm_reg[1][13]; sfm_in10 = sfm_reg[1][14];
                        sfm_in2 = sfm_reg[2][11]; sfm_in5 = sfm_reg[2][12]; sfm_in8 = sfm_reg[2][13]; sfm_in11 = sfm_reg[2][14];
                        sfm_in3 = sfm_reg[2][11]; sfm_in6 = sfm_reg[2][12]; sfm_in9 = sfm_reg[2][13]; sfm_in12 = sfm_reg[2][14];
                    end
                    'd138:begin
                        sfm_in1 = sfm_reg[1][13]; sfm_in4 = sfm_reg[1][14]; sfm_in7 = sfm_reg[1][15]; sfm_in10 = sfm_reg[1][15];
                        sfm_in2 = sfm_reg[2][13]; sfm_in5 = sfm_reg[2][14]; sfm_in8 = sfm_reg[2][15]; sfm_in11 = sfm_reg[2][15];
                        sfm_in3 = sfm_reg[2][13]; sfm_in6 = sfm_reg[2][14]; sfm_in9 = sfm_reg[2][15]; sfm_in12 = sfm_reg[2][15];
                    end
                endcase
            end
        end
    endcase
end
always @(*) begin
    if(cs == CC_OUT)begin
        if(write_en_big)begin
            sram_out_to_sfm_1 = horizontal_flag ? sram_big_out_2 : sram_big_out_1;
            sram_out_to_sfm_2 = horizontal_flag ? sram_big_out_1 : sram_big_out_2;
        end
        else begin
            sram_out_to_sfm_1 = horizontal_flag ? sram_small_out_2 : sram_small_out_1;
            sram_out_to_sfm_2 = horizontal_flag ? sram_small_out_1 : sram_small_out_2;
        end
    end
    else begin
        sram_out_to_sfm_1 = write_en_big ? sram_big_out_1 : sram_small_out_1;
        sram_out_to_sfm_2 = write_en_big ? sram_big_out_2 : sram_small_out_2;
    end
end
always @(posedge clk) begin
    if(ns == IDLE || cs == ACT_standby)begin
        for(i = 0; i < 3; i = i + 1)begin
            for(j = 0; j < 16; j = j + 1)
                sfm_reg[i][j] <= 0;
        end
    end
    else begin
        if(cs == IMAGE_FILTER)begin
            case (image_size_reg)
                'd0:begin
                    case (cnt_mp_sfm)
                        'd1:begin
                            sfm_reg[0][0] <= sram_out_to_sfm_1;
                            sfm_reg[0][1] <= sram_out_to_sfm_2;
                        end
                        'd2:begin
                            sfm_reg[0][2] <= sram_out_to_sfm_1;
                            sfm_reg[0][3] <= sram_out_to_sfm_2;
                        end
                        'd3:begin
                            sfm_reg[1][0] <= sram_out_to_sfm_1;
                            sfm_reg[1][1] <= sram_out_to_sfm_2;
                        end 
                        'd4:begin
                            sfm_reg[1][2] <= sram_out_to_sfm_1;
                            sfm_reg[1][3] <= sram_out_to_sfm_2;
                        end
                        'd5:begin
                            sfm_reg[2][0] <= sram_out_to_sfm_1;
                            sfm_reg[2][1] <= sram_out_to_sfm_2;
                        end
                        'd6:begin
                            sfm_reg[2][2] <= sram_out_to_sfm_1;
                            sfm_reg[2][3] <= sram_out_to_sfm_2;
                        end
                        'd7:begin
                            sfm_reg[0][4] <= sram_out_to_sfm_1;
                            sfm_reg[0][5] <= sram_out_to_sfm_2;
                        end
                        'd8:begin
                            sfm_reg[0][6] <= sram_out_to_sfm_1;
                            sfm_reg[0][7] <= sram_out_to_sfm_2;
                        end 
                    endcase
                end 
                'd1:begin
                    if(cnt_mp_sfm < 33)begin
                        case (cnt_mp_sfm[1:0])
                            'b01:begin
                                sfm_reg[0][0] <= sfm_reg[1][0];
                                sfm_reg[0][1] <= sfm_reg[1][1]; 
                                sfm_reg[1][0] <= sfm_reg[2][0]; 
                                sfm_reg[1][1] <= sfm_reg[2][1];
                                sfm_reg[2][0] <= sram_out_to_sfm_1;
                                sfm_reg[2][1] <= sram_out_to_sfm_2;
                            end
                            'b10:begin
                                sfm_reg[0][2] <= sfm_reg[1][2];
                                sfm_reg[0][3] <= sfm_reg[1][3];
                                sfm_reg[1][2] <= sfm_reg[2][2];
                                sfm_reg[1][3] <= sfm_reg[2][3];
                                sfm_reg[2][2] <= sram_out_to_sfm_1;
                                sfm_reg[2][3] <= sram_out_to_sfm_2;
                            end
                            'b11:begin
                                sfm_reg[0][4] <= sfm_reg[1][4];
                                sfm_reg[0][5] <= sfm_reg[1][5];
                                sfm_reg[1][4] <= sfm_reg[2][4];
                                sfm_reg[1][5] <= sfm_reg[2][5];
                                sfm_reg[2][4] <= sram_out_to_sfm_1;
                                sfm_reg[2][5] <= sram_out_to_sfm_2;
                            end
                            'b00:begin
                                sfm_reg[0][6] <= sfm_reg[1][6];
                                sfm_reg[0][7] <= sfm_reg[1][7];
                                sfm_reg[1][6] <= sfm_reg[2][6];
                                sfm_reg[1][7] <= sfm_reg[2][7];
                                sfm_reg[2][6] <= sram_out_to_sfm_1;
                                sfm_reg[2][7] <= sram_out_to_sfm_2;
                            end
                        endcase
                    end
                end
                'd2:begin
                    if(cnt_sfm_for16x16 < 129)begin//modify
                        case (cnt_sfm_for16x16[2:0])
                            'b001:begin
                                sfm_reg[0][0] <= sfm_reg[1][0];
                                sfm_reg[0][1] <= sfm_reg[1][1]; 
                                sfm_reg[1][0] <= sfm_reg[2][0]; 
                                sfm_reg[1][1] <= sfm_reg[2][1];
                                sfm_reg[2][0] <= sram_out_to_sfm_1;
                                sfm_reg[2][1] <= sram_out_to_sfm_2;
                            end
                            'b010:begin
                                sfm_reg[0][2] <= sfm_reg[1][2];
                                sfm_reg[0][3] <= sfm_reg[1][3];
                                sfm_reg[1][2] <= sfm_reg[2][2];
                                sfm_reg[1][3] <= sfm_reg[2][3];
                                sfm_reg[2][2] <= sram_out_to_sfm_1;
                                sfm_reg[2][3] <= sram_out_to_sfm_2;
                            end
                            'b011:begin
                                sfm_reg[0][4] <= sfm_reg[1][4];
                                sfm_reg[0][5] <= sfm_reg[1][5];
                                sfm_reg[1][4] <= sfm_reg[2][4];
                                sfm_reg[1][5] <= sfm_reg[2][5];
                                sfm_reg[2][4] <= sram_out_to_sfm_1;
                                sfm_reg[2][5] <= sram_out_to_sfm_2;
                            end
                            'b100:begin
                                sfm_reg[0][6] <= sfm_reg[1][6];
                                sfm_reg[0][7] <= sfm_reg[1][7];
                                sfm_reg[1][6] <= sfm_reg[2][6];
                                sfm_reg[1][7] <= sfm_reg[2][7];
                                sfm_reg[2][6] <= sram_out_to_sfm_1;
                                sfm_reg[2][7] <= sram_out_to_sfm_2;
                            end
                            'b101:begin
                                sfm_reg[0][8] <= sfm_reg[1][8];
                                sfm_reg[0][9] <= sfm_reg[1][9];
                                sfm_reg[1][8] <= sfm_reg[2][8];
                                sfm_reg[1][9] <= sfm_reg[2][9];
                                sfm_reg[2][8] <= sram_out_to_sfm_1;
                                sfm_reg[2][9] <= sram_out_to_sfm_2;
                            end
                            'b110:begin
                                sfm_reg[0][10] <= sfm_reg[1][10];
                                sfm_reg[0][11] <= sfm_reg[1][11];
                                sfm_reg[1][10] <= sfm_reg[2][10];
                                sfm_reg[1][11] <= sfm_reg[2][11];
                                sfm_reg[2][10] <= sram_out_to_sfm_1;
                                sfm_reg[2][11] <= sram_out_to_sfm_2;
                            end
                            'b111:begin
                                sfm_reg[0][12] <= sfm_reg[1][12];
                                sfm_reg[0][13] <= sfm_reg[1][13];
                                sfm_reg[1][12] <= sfm_reg[2][12];
                                sfm_reg[1][13] <= sfm_reg[2][13];
                                sfm_reg[2][12] <= sram_out_to_sfm_1;
                                sfm_reg[2][13] <= sram_out_to_sfm_2;
                            end
                            'b000:begin
                                sfm_reg[0][14] <= sfm_reg[1][14];
                                sfm_reg[0][15] <= sfm_reg[1][15];
                                sfm_reg[1][14] <= sfm_reg[2][14];
                                sfm_reg[1][15] <= sfm_reg[2][15];
                                sfm_reg[2][14] <= sram_out_to_sfm_1;
                                sfm_reg[2][15] <= sram_out_to_sfm_2;
                            end
                        endcase
                    end
                end
            endcase
        end
        else if(cs == CC_OUT)begin
            case (image_size_reg)
                'd0:begin
                    case (cnt_cc_sel)
                        'd1:begin
                            sfm_reg[0][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                            sfm_reg[0][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                        end 
                        'd2:begin
                            sfm_reg[1][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                            sfm_reg[1][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                        end
                        'd3:begin
                            sfm_reg[0][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                            sfm_reg[0][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                        end
                        'd4:begin
                            sfm_reg[1][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                            sfm_reg[1][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                        end
                        'd5:begin
                            sfm_reg[0][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;//[2][0]
                            sfm_reg[0][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;//[2][1]
                        end
                        'd6:begin
                            sfm_reg[1][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;//[2][2]
                            sfm_reg[1][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;//[2][3]
                        end
                        'd7:begin
                            sfm_reg[0][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;//[3][0]
                            sfm_reg[0][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;//[3][1]
                        end
                        'd8:begin
                            sfm_reg[1][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;//[3][2]
                            sfm_reg[1][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;//[3][3]
                        end 
                    endcase
                end 
                'd1:begin
                    if(~cc_first_row_done && cnt_row_cc_check == 0)begin
                        case (cnt_cc_sel)
                            'd1:begin
                                sfm_reg[1][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end 
                            'd2:begin
                                sfm_reg[2][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd3:begin
                                sfm_reg[1][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd4:begin
                                sfm_reg[2][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd5:begin
                                sfm_reg[1][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd6:begin
                                sfm_reg[2][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd7:begin
                                sfm_reg[1][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd8:begin
                                sfm_reg[2][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                        endcase
                    end
                    else if(cnt_row_cc_check == 7)begin
                        case (cnt_cc_20)
                            'd2:begin
                                sfm_reg[0][0] <= sfm_reg[1][0];
                                sfm_reg[0][1] <= sfm_reg[1][1];
                                sfm_reg[1][0] <= sfm_reg[2][0];
                                sfm_reg[1][1] <= sfm_reg[2][1];
                                sfm_reg[2][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end 
                            'd3:begin
                                sfm_reg[0][2] <= sfm_reg[1][2];
                                sfm_reg[0][3] <= sfm_reg[1][3];
                                sfm_reg[1][2] <= sfm_reg[2][2];
                                sfm_reg[1][3] <= sfm_reg[2][3];
                                sfm_reg[2][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd4:begin
                                sfm_reg[0][4] <= sfm_reg[1][4];
                                sfm_reg[0][5] <= sfm_reg[1][5];
                                sfm_reg[1][4] <= sfm_reg[2][4];
                                sfm_reg[1][5] <= sfm_reg[2][5];
                                sfm_reg[2][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd5:begin
                                sfm_reg[0][6] <= sfm_reg[1][6];
                                sfm_reg[0][7] <= sfm_reg[1][7];
                                sfm_reg[1][6] <= sfm_reg[2][6];
                                sfm_reg[1][7] <= sfm_reg[2][7];
                                sfm_reg[2][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                        endcase
                    end
                end
                'd2:begin
                    if(~cc_first_row_done && cnt_row_cc_check == 0)begin
                        case (cnt_cc_sel)
                            'd1:begin
                                sfm_reg[1][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd2:begin
                                sfm_reg[2][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd3:begin
                                sfm_reg[1][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd4:begin
                                sfm_reg[2][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd5:begin
                                sfm_reg[1][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd6:begin
                                sfm_reg[2][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd7:begin
                                sfm_reg[1][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd8:begin
                                sfm_reg[2][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd9:begin
                                sfm_reg[1][8] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][9] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd10:begin
                                sfm_reg[2][8] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][9] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd11:begin
                                sfm_reg[1][10] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][11] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd12:begin
                                sfm_reg[2][10] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][11] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd13:begin
                                sfm_reg[1][12] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][13] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd14:begin
                                sfm_reg[2][12] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][13] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd15:begin
                                sfm_reg[1][14] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[1][15] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd16:begin
                                sfm_reg[2][14] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][15] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                        endcase
                    end 
                    else if(cnt_row_cc_check == 15)begin
                        case (cnt_cc_20)
                            'd2:begin
                                sfm_reg[0][0] <= sfm_reg[1][0];
                                sfm_reg[0][1] <= sfm_reg[1][1];
                                sfm_reg[1][0] <= sfm_reg[2][0];
                                sfm_reg[1][1] <= sfm_reg[2][1];
                                sfm_reg[2][0] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][1] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end 
                            'd3:begin
                                sfm_reg[0][2] <= sfm_reg[1][2];
                                sfm_reg[0][3] <= sfm_reg[1][3];
                                sfm_reg[1][2] <= sfm_reg[2][2];
                                sfm_reg[1][3] <= sfm_reg[2][3];
                                sfm_reg[2][2] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][3] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd4:begin
                                sfm_reg[0][4] <= sfm_reg[1][4];
                                sfm_reg[0][5] <= sfm_reg[1][5];
                                sfm_reg[1][4] <= sfm_reg[2][4];
                                sfm_reg[1][5] <= sfm_reg[2][5];
                                sfm_reg[2][4] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][5] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd5:begin
                                sfm_reg[0][6] <= sfm_reg[1][6];
                                sfm_reg[0][7] <= sfm_reg[1][7];
                                sfm_reg[1][6] <= sfm_reg[2][6];
                                sfm_reg[1][7] <= sfm_reg[2][7];
                                sfm_reg[2][6] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][7] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd6:begin
                                sfm_reg[0][8] <= sfm_reg[1][8];
                                sfm_reg[0][9] <= sfm_reg[1][9];
                                sfm_reg[1][8] <= sfm_reg[2][8];
                                sfm_reg[1][9] <= sfm_reg[2][9];
                                sfm_reg[2][8] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][9] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd7:begin
                                sfm_reg[0][10] <= sfm_reg[1][10];
                                sfm_reg[0][11] <= sfm_reg[1][11];
                                sfm_reg[1][10] <= sfm_reg[2][10];
                                sfm_reg[1][11] <= sfm_reg[2][11];
                                sfm_reg[2][10] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][11] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd8:begin
                                sfm_reg[0][12] <= sfm_reg[1][12];
                                sfm_reg[0][13] <= sfm_reg[1][13];
                                sfm_reg[1][12] <= sfm_reg[2][12];
                                sfm_reg[1][13] <= sfm_reg[2][13];
                                sfm_reg[2][12] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][13] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                            'd9:begin
                                sfm_reg[0][14] <= sfm_reg[1][14];
                                sfm_reg[0][15] <= sfm_reg[1][15];
                                sfm_reg[1][14] <= sfm_reg[2][14];
                                sfm_reg[1][15] <= sfm_reg[2][15];
                                sfm_reg[2][14] <= neagtive_flag ? ~sram_out_to_sfm_1 : sram_out_to_sfm_1;
                                sfm_reg[2][15] <= neagtive_flag ? ~sram_out_to_sfm_2 : sram_out_to_sfm_2;
                            end
                        endcase
                    end
                end
            endcase
        end
    end
end
//==================================================================
// Cross Correlation
//==================================================================
//=============================
// template
//=============================
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_template <= 0;
    else
    if(in_valid && cnt_template < 9)
        cnt_template <= cnt_template + 1;
    else if (cs == IDLE)
        cnt_template <= 0;
end
always @(posedge clk) begin
    if(in_valid && cnt_template < 9)begin
        template_reg[0][0] <= template_reg[0][1];
        template_reg[0][1] <= template_reg[0][2];
        template_reg[0][2] <= template_reg[1][0];
        template_reg[1][0] <= template_reg[1][1];
        template_reg[1][1] <= template_reg[1][2];
        template_reg[1][2] <= template_reg[2][0];
        template_reg[2][0] <= template_reg[2][1];
        template_reg[2][1] <= template_reg[2][2];
        template_reg[2][2] <= template;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_cc <= 0;
    else if(ns == IDLE || (ns == CC_OUT && cs == ACT_sort))
        cnt_cc <= 0;
    else if(ns == CC_OUT && cnt_cc < 20)
        cnt_cc <= cnt_cc + 1;
    else 
        cnt_cc <= cnt_cc;
end
always @(*) begin
    cnt_cc_sel = horizontal_flag ? (cnt_cc == 0 ? 0 : cnt_cc - 1) : cnt_cc;
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_cc_20 <= 0;
    else if(cs == IDLE)
        cnt_cc_20 <= 0;
    else if(ns == CC_OUT)begin
        if(cnt_cc_sel == 5 || cnt_cc_20 == 19)
            cnt_cc_20 <= 0;
        else 
            cnt_cc_20 <= cnt_cc_20 + 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_row_cc_check <= 0;
    else if(cs == IDLE)
        cnt_row_cc_check <= 0;
    else if(ns == CC_OUT) begin
        if(image_size_reg == 0 && cnt_row_cc_check == 3 && cnt_cc_20 == 19)
            cnt_row_cc_check <= 0;
        else if(image_size_reg == 1 && cnt_row_cc_check == 7 && cnt_cc_20 == 19)
            cnt_row_cc_check <= 0;
        else if(image_size_reg == 2 && cnt_row_cc_check == 15 && cnt_cc_20 == 19)
            cnt_row_cc_check <= 0;
        else if(cnt_cc_20 == 19)
            cnt_row_cc_check <= cnt_row_cc_check + 1;
    end
    else 
        cnt_row_cc_check <= cnt_row_cc_check;
end
always @(posedge clk) begin
    if(cs == IDLE)
        cc_first_row_done <= 0;
    else begin
        case (image_size_reg)
            'd0: cc_first_row_done <= (cnt_row_cc_check == 3  && cnt_cc_20 == 19) ? 1 : cc_first_row_done;
            'd1: cc_first_row_done <= (cnt_row_cc_check == 7  && cnt_cc_20 == 19) ? 1 : cc_first_row_done;
            'd2: cc_first_row_done <= (cnt_row_cc_check == 15 && cnt_cc_20 == 19) ? 1 : cc_first_row_done;
            default: cc_first_row_done <= cc_first_row_done;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cnt_which_row <= 0;
    else if(ns == IDLE)
        cnt_which_row <= 0;
    else if(ns == CC_OUT)begin
        case (image_size_reg)
            'd0: cnt_which_row <= (cnt_row_cc_check == 3  && cnt_cc_20 == 19) ? cnt_which_row + 1 : cnt_which_row;
            'd1: cnt_which_row <= (cnt_row_cc_check == 7  && cnt_cc_20 == 19) ? cnt_which_row + 1 : cnt_which_row;
            'd2: cnt_which_row <= (cnt_row_cc_check == 15 && cnt_cc_20 == 19) ? cnt_which_row + 1 : cnt_which_row;
            default: cnt_which_row <= cnt_which_row;
        endcase
    end
end
//=============================
// multiplication
//=============================
reg [7:0]  mul_in1, mul_in2;
wire [15:0] mul_out;
assign mul_out = mul_in1 * mul_in2;
always @(*) begin
    mul_in1 = 0;
    mul_in2 = 0;
    if(cnt_cc_sel == 2)begin
        mul_in1 = image_size_reg == 0 ? sfm_reg[0][0] : sfm_reg[1][0];
        mul_in2 = template_reg[1][1];
    end
    else if (cnt_cc_sel == 3)begin
        mul_in1 = image_size_reg == 0 ? sfm_reg[0][1] : sfm_reg[1][1];
        mul_in2 = template_reg[1][2];
    end
    else if (cnt_cc_sel == 4)begin
        mul_in1 = image_size_reg == 0 ? sfm_reg[1][0] : sfm_reg[2][0];
        mul_in2 = template_reg[2][1];
    end
    else if (cnt_cc_sel == 5)begin
        mul_in1 = image_size_reg == 0 ? sfm_reg[1][1] : sfm_reg[2][1];
        mul_in2 = template_reg[2][2];
    end
    else begin
        case (image_size_reg)
            'd0:begin
                case (cnt_which_row)
                    0:begin
                        case(cnt_row_cc_check)
                            0:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][0];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[1][0];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][1];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[0][2];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end
                            1:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][1];
                                        mul_in2 = template_reg[1][0];
                                    end 
                                    'd13:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][2];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[0][3];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[1][3];
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            2:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][2];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][3];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][3];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            3:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][0];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][0];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[0][4];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[0][1];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                        endcase
                    end 
                    1:begin
                        case (cnt_row_cc_check)
                            0:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][0];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][0];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[0][4];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][1];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[0][2];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end 
                            1:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][1];
                                        mul_in2 = template_reg[0][0];
                                    end
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][2];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[0][3];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][3];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[1][5];
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            2:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][2];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][3];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][3];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][5];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            3:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[1][0];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][4];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[0][6];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end
                        endcase
                    end
                    2:begin
                        case (cnt_row_cc_check)
                            0:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[1][0];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][4];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[0][6];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end 
                            1:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[1][1];
                                        mul_in2 = template_reg[0][0];
                                    end
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[1][3];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][5];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[1][7];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end
                            2:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[1][2];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[1][3];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][5];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[1][7];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            3:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end
                                    'd12:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][4];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][6];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                        endcase
                    end
                    3:begin
                        case (cnt_row_cc_check)
                            0:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][4];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][6];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end 
                            1:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][5];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[1][5];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][7];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            2:begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[1][4];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[1][5];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][7];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                        endcase
                    end
                endcase
            end 
            'd1:begin
                if(cnt_which_row == 7)begin
                    if(cnt_row_cc_check == 6)begin
                        case (cnt_cc_20)
                            'd11:begin
                                mul_in1 = sfm_reg[0][6];
                                mul_in2 = template_reg[0][0];
                            end 
                            'd12:begin
                                mul_in1 = sfm_reg[1][6];
                                mul_in2 = template_reg[1][0];
                            end
                            'd13:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][0];
                            end
                            'd14:begin
                                mul_in1 = sfm_reg[0][7];
                                mul_in2 = template_reg[0][1];
                            end
                            'd15:begin
                                mul_in1 = sfm_reg[1][7];
                                mul_in2 = template_reg[1][1];
                            end
                            'd16:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][1];
                            end
                            'd17:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[0][2];
                            end
                            'd18:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[1][2];
                            end
                            'd19:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][2];
                            end 
                        endcase
                    end
                    else begin
                        case (cnt_cc_20)
                            'd11:begin
                                mul_in1 = sfm_reg[0][0 + cnt_row_cc_check];
                                mul_in2 = template_reg[0][0];
                            end 
                            'd12:begin
                                mul_in1 = sfm_reg[1][0 + cnt_row_cc_check];
                                mul_in2 = template_reg[1][0];
                            end
                            'd13:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][0];
                            end
                            'd14:begin
                                mul_in1 = sfm_reg[0][1 + cnt_row_cc_check];
                                mul_in2 = template_reg[0][1];
                            end
                            'd15:begin
                                mul_in1 = sfm_reg[1][1 + cnt_row_cc_check];
                                mul_in2 = template_reg[1][1];
                            end
                            'd16:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][1];
                            end
                            'd17:begin
                                mul_in1 = sfm_reg[0][2 + cnt_row_cc_check];
                                mul_in2 = template_reg[0][2];
                            end
                            'd18:begin
                                mul_in1 = sfm_reg[1][2 + cnt_row_cc_check];
                                mul_in2 = template_reg[1][2];
                            end
                            'd19:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][2];
                            end 
                        endcase
                    end
                end
                else begin
                    if (cnt_row_cc_check == 7)begin
                        if(cnt_which_row == 6)begin
                            case (cnt_cc_20)
                                'd11:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[0][0];
                                end 
                                'd12:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[1][0];
                                end
                                'd13:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][0];
                                end
                                'd14:begin
                                    mul_in1 = sfm_reg[0][0];
                                    mul_in2 = template_reg[0][1];
                                end
                                'd15:begin
                                    mul_in1 = sfm_reg[1][0];
                                    mul_in2 = template_reg[1][1];
                                end
                                'd16:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][1];
                                end
                                'd17:begin
                                    mul_in1 = sfm_reg[0][1];
                                    mul_in2 = template_reg[0][2];
                                end
                                'd18:begin
                                    mul_in1 = sfm_reg[1][1];
                                    mul_in2 = template_reg[1][2];
                                end
                                'd19:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][2];
                                end 
                            endcase
                        end
                        else begin
                            case (cnt_cc_20)
                                'd11:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[0][0];
                                end 
                                'd12:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[1][0];
                                end
                                'd13:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][0];
                                end
                                'd14:begin
                                    mul_in1 = sfm_reg[0][0];
                                    mul_in2 = template_reg[0][1];
                                end
                                'd15:begin
                                    mul_in1 = sfm_reg[1][0];
                                    mul_in2 = template_reg[1][1];
                                end
                                'd16:begin
                                    mul_in1 = sfm_reg[2][0];
                                    mul_in2 = template_reg[2][1];
                                end
                                'd17:begin
                                    mul_in1 = sfm_reg[0][1];
                                    mul_in2 = template_reg[0][2];
                                end
                                'd18:begin
                                    mul_in1 = sfm_reg[1][1];
                                    mul_in2 = template_reg[1][2];
                                end
                                'd19:begin
                                    mul_in1 = sfm_reg[2][1];
                                    mul_in2 = template_reg[2][2];
                                end 
                            endcase
                        end
                    end
                    else begin
                        if(cc_first_row_done)begin
                            if(cnt_row_cc_check == 6)begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][6];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][6];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][7];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][7];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][7];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            else begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[0][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[2][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                        end
                        else begin
                            if (cnt_row_cc_check == 6)begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][6];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][6];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][7];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][7];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            else begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[2][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                        end
                    end
                end
            end
            'd2:begin
                if(cnt_which_row == 15)begin
                    if(cnt_row_cc_check == 14)begin
                        case (cnt_cc_20)
                            'd11:begin
                                mul_in1 = sfm_reg[0][14];
                                mul_in2 = template_reg[0][0];
                            end 
                            'd12:begin
                                mul_in1 = sfm_reg[1][14];
                                mul_in2 = template_reg[1][0];
                            end
                            'd13:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][0];
                            end
                            'd14:begin
                                mul_in1 = sfm_reg[0][15];
                                mul_in2 = template_reg[0][1];
                            end
                            'd15:begin
                                mul_in1 = sfm_reg[1][15];
                                mul_in2 = template_reg[1][1];
                            end
                            'd16:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][1];
                            end
                            'd17:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[0][2];
                            end
                            'd18:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[1][2];
                            end
                            'd19:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][2];
                            end 
                        endcase
                    end
                    else begin
                        case (cnt_cc_20)
                            'd11:begin
                                mul_in1 = sfm_reg[0][0 + cnt_row_cc_check];
                                mul_in2 = template_reg[0][0];
                            end 
                            'd12:begin
                                mul_in1 = sfm_reg[1][0 + cnt_row_cc_check];
                                mul_in2 = template_reg[1][0];
                            end
                            'd13:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][0];
                            end
                            'd14:begin
                                mul_in1 = sfm_reg[0][1 + cnt_row_cc_check];
                                mul_in2 = template_reg[0][1];
                            end
                            'd15:begin
                                mul_in1 = sfm_reg[1][1 + cnt_row_cc_check];
                                mul_in2 = template_reg[1][1];
                            end
                            'd16:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][1];
                            end
                            'd17:begin
                                mul_in1 = sfm_reg[0][2 + cnt_row_cc_check];
                                mul_in2 = template_reg[0][2];
                            end
                            'd18:begin
                                mul_in1 = sfm_reg[1][2 + cnt_row_cc_check];
                                mul_in2 = template_reg[1][2];
                            end
                            'd19:begin
                                mul_in1 = 0;
                                mul_in2 = template_reg[2][2];
                            end
                        endcase
                    end
                end
                else begin
                    if (cnt_row_cc_check == 15)begin
                        if(cnt_which_row == 14)begin
                            case (cnt_cc_20)
                                'd11:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[0][0];
                                end 
                                'd12:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[1][0];
                                end
                                'd13:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][0];
                                end
                                'd14:begin
                                    mul_in1 = sfm_reg[0][0];
                                    mul_in2 = template_reg[0][1];
                                end
                                'd15:begin
                                    mul_in1 = sfm_reg[1][0];
                                    mul_in2 = template_reg[1][1];
                                end
                                'd16:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][1];
                                end
                                'd17:begin
                                    mul_in1 = sfm_reg[0][1];
                                    mul_in2 = template_reg[0][2];
                                end
                                'd18:begin
                                    mul_in1 = sfm_reg[1][1];
                                    mul_in2 = template_reg[1][2];
                                end
                                'd19:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][2];
                                end 
                            endcase
                        end
                        else begin
                            case (cnt_cc_20)
                                'd11:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[0][0];
                                end 
                                'd12:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[1][0];
                                end
                                'd13:begin
                                    mul_in1 = 0;
                                    mul_in2 = template_reg[2][0];
                                end
                                'd14:begin
                                    mul_in1 = sfm_reg[0][0];
                                    mul_in2 = template_reg[0][1];
                                end
                                'd15:begin
                                    mul_in1 = sfm_reg[1][0];
                                    mul_in2 = template_reg[1][1];
                                end
                                'd16:begin
                                    mul_in1 = sfm_reg[2][0];
                                    mul_in2 = template_reg[2][1];
                                end
                                'd17:begin
                                    mul_in1 = sfm_reg[0][1];
                                    mul_in2 = template_reg[0][2];
                                end
                                'd18:begin
                                    mul_in1 = sfm_reg[1][1];
                                    mul_in2 = template_reg[1][2];
                                end
                                'd19:begin
                                    mul_in1 = sfm_reg[2][1];
                                    mul_in2 = template_reg[2][2];
                                end
                            endcase
                        end
                    end
                    else begin
                        if(cc_first_row_done)begin
                            if(cnt_row_cc_check == 14)begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][14];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][14];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][14];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][15];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][15];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][15];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            else begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = sfm_reg[0][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = sfm_reg[0][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = sfm_reg[0][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[2][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end
                        end
                        else begin
                            if (cnt_row_cc_check == 14)begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][14];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][14];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][15];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][15];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[2][2];
                                    end 
                                endcase
                            end
                            else begin
                                case (cnt_cc_20)
                                    'd11:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][0];
                                    end 
                                    'd12:begin
                                        mul_in1 = sfm_reg[1][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][0];
                                    end
                                    'd13:begin
                                        mul_in1 = sfm_reg[2][0 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][0];
                                    end
                                    'd14:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][1];
                                    end
                                    'd15:begin
                                        mul_in1 = sfm_reg[1][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][1];
                                    end
                                    'd16:begin
                                        mul_in1 = sfm_reg[2][1 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][1];
                                    end
                                    'd17:begin
                                        mul_in1 = 0;
                                        mul_in2 = template_reg[0][2];
                                    end
                                    'd18:begin
                                        mul_in1 = sfm_reg[1][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[1][2];
                                    end
                                    'd19:begin
                                        mul_in1 = sfm_reg[2][2 + cnt_row_cc_check];
                                        mul_in2 = template_reg[2][2];
                                    end
                                endcase
                            end
                        end
                    end
                end
            end
        endcase
    end
end
always @(posedge clk ) begin
    if(cs == IDLE)
        cc_out <= 0;
    else if(cnt_cc_sel == 6 || cnt_cc_20 == 19)
        cc_out <= 0;
    else 
        cc_out <= cc_out + mul_out;
end
//====================================
// store cc_out
//====================================
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        output_shift_reg <= 0;
    else if(cnt_cc_sel == 5)
        output_shift_reg <= cc_out + mul_out;
    else if(cnt_cc_20 == 19)
        output_shift_reg <= cc_out + mul_out;
    else
        output_shift_reg <= output_shift_reg << 1;
end
// always @(posedge clk) begin
//     if(cnt_cc_20 == 9)
//         output_result_temp <= cc_out;
//     else 
//         output_result_temp <= output_result_temp;
// end
//==================================================================
// Output
//==================================================================
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        out_valid <= 0;
    else if(ns == CC_OUT && cnt_cc_sel > 4)
        out_valid <= 1;
    else
        out_valid <= 0;
end
always @(*) begin
    if (out_valid)
        out_value = output_shift_reg[19];
    else
        out_value = 0;
end
endmodule


module cmp_2(
    in1,in2,in3,
    out
    );    
    input  [7:0] in1,in2,in3;
    output [7:0] out;

    wire [7:0] temp;
    assign temp = in1 > in2 ? in1 : in2;
    assign out = temp > in3 ? temp : in3;
endmodule


module max_min_pool(
    in1, in2, in3, in4,
    flag,
    out);
    input [7:0] in1, in2, in3, in4;
    input flag;
    output [7:0] out;

    wire [7:0] temp1, temp2, temp3, temp4, temp5, temp6;
    assign temp1 = in1 > in3 ? in1 : in3;
    assign temp2 = in1 > in3 ? in3 : in1;
    assign temp3 = in2 > in4 ? in2 : in4;
    assign temp4 = in2 > in4 ? in4 : in2;
    assign temp5 = temp1 > temp3 ? temp1 : temp3;
    assign temp6 = temp2 > temp4 ? temp4 : temp2;

    assign out = flag ? temp5 : temp6;
endmodule

module sorting_find_median(
    in1,in2,in3,in4,in5,in6,
    in7,in8,in9,in10,in11,in12,
    out1,out2
    );
    input  [7:0] in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12;
    output [7:0] out1,out2;

    wire [7:0] a_0_0, a_0_1, a_0_2, a_0_3, a_0_4, a_0_5, a_0_6, a_0_7, a_0_8, a_0_9, a_0_10, a_0_11;
    wire [7:0] a_1_0, a_1_1, a_1_2, a_1_3, a_1_4, a_1_5, a_1_6, a_1_7, a_1_8, a_1_9, a_1_10, a_1_11;
    wire [7:0] a_2_0, a_2_1, a_2_2, a_2_3, a_2_4, a_2_5, a_2_6, a_2_7, a_2_8, a_2_9, a_2_10, a_2_11;
    wire [7:0] b_0_0, b_0_1, b_1_0, b_1_1, b_1_2;
    wire [7:0] c_0_0, c_0_1, c_1_0, c_1_1, c_1_2, c_2_0, c_2_1, c_2_2;
    wire [7:0] d_0_0, d_0_1, d_1_0; 
    wire [7:0] e_0_0, e_0_1, e_1_0, e_1_1, e_1_2;

    wire [7:0] b_out1_1_0, b_out1_1_1;
    wire [7:0] c_out1_1_0, c_out1_1_1, c_out1_2_0, c_out1_2_1; 
    wire [7:0] d_out1_1_0, e_out1_1_0, e_out1_1_1, e_out1_1_2, e_out1_1_3;
//a-group
    assign a_0_0 = in1 > in2 ? in1 : in2;
    assign a_0_1 = in1 > in2 ? in2 : in1;
    assign a_0_2 = in3;
    assign a_0_3 = in4 > in5 ? in4 : in5;
    assign a_0_4 = in4 > in5 ? in5 : in4;
    assign a_0_5 = in6;
    assign a_0_6 = in7 > in8 ? in7 : in8;
    assign a_0_7 = in7 > in8 ? in8 : in7;
    assign a_0_8 = in9;
    assign a_0_9 = in10 > in11 ? in10 : in11;
    assign a_0_10 = in10 > in11 ? in11 : in10;
    assign a_0_11 = in12;

    assign a_1_0 = a_0_0;
    assign a_1_1 = a_0_1 > a_0_2 ? a_0_1 : a_0_2;
    assign a_1_2 = a_0_1 > a_0_2 ? a_0_2 : a_0_1;
    assign a_1_3 = a_0_3;
    assign a_1_4 = a_0_4 > a_0_5 ? a_0_4 : a_0_5;
    assign a_1_5 = a_0_4 > a_0_5 ? a_0_5 : a_0_4;
    assign a_1_6 = a_0_6;
    assign a_1_7 = a_0_7 > a_0_8 ? a_0_7 : a_0_8;
    assign a_1_8 = a_0_7 > a_0_8 ? a_0_8 : a_0_7;
    assign a_1_9 = a_0_9;
    assign a_1_10 = a_0_10 > a_0_11 ? a_0_10 : a_0_11;
    assign a_1_11 = a_0_10 > a_0_11 ? a_0_11 : a_0_10;

    assign a_2_0 = a_1_0 > a_1_1 ? a_1_0 : a_1_1;
    assign a_2_1 = a_1_0 > a_1_1 ? a_1_1 : a_1_0;
    assign a_2_2 = a_1_2;
    assign a_2_3 = a_1_3 > a_1_4 ? a_1_3 : a_1_4;
    assign a_2_4 = a_1_3 > a_1_4 ? a_1_4 : a_1_3;
    assign a_2_5 = a_1_5;
    assign a_2_6 = a_1_6 > a_1_7 ? a_1_6 : a_1_7;
    assign a_2_7 = a_1_6 > a_1_7 ? a_1_7 : a_1_6;
    assign a_2_8 = a_1_8;
    assign a_2_9 = a_1_9 > a_1_10 ? a_1_9 : a_1_10;
    assign a_2_10 = a_1_9 > a_1_10 ? a_1_10 : a_1_9;
    assign a_2_11 = a_1_11;
//b-group
    assign b_0_0 = a_2_3 > a_2_6 ? a_2_3 : a_2_6;
    assign b_0_1 = a_2_3 > a_2_6 ? a_2_6 : a_2_3;

    assign b_1_0 = b_0_0;
    assign b_1_1 = b_0_1 > a_2_9 ? b_0_1 : a_2_9;
    assign b_1_2 = b_0_1 > a_2_9 ? a_2_9 : b_0_1;
//c-group
    assign c_0_0 = a_2_4 > a_2_7 ? a_2_4 : a_2_7;
    assign c_0_1 = a_2_4 > a_2_7 ? a_2_7 : a_2_4;

    assign c_1_0 = c_0_0;
    assign c_1_1 = c_0_1 > a_2_10 ? c_0_1 : a_2_10; 
    assign c_1_2 = c_0_1 > a_2_10 ? a_2_10 : c_0_1;

    assign c_2_0 = c_1_0 > c_1_1 ? c_1_0 : c_1_1;
    assign c_2_1 = c_1_0 > c_1_1 ? c_1_1 : c_1_0;
    assign c_2_2 = c_1_2;
//d-group
    assign d_0_0 = a_2_5 > a_2_8 ? a_2_5 : a_2_8;
    assign d_0_1 = a_2_5 > a_2_8 ? a_2_8 : a_2_5;

    assign d_1_0 = d_0_0 > a_2_11 ? d_0_0 : a_2_11;
//e-group
    assign e_0_0 = d_1_0 > c_2_1 ? d_1_0 : c_2_1;
    assign e_0_1 = d_1_0 > c_2_1 ? c_2_1 : d_1_0;

    assign e_1_0 = e_0_0;
    assign e_1_1 = e_0_1 > b_1_2 ? e_0_1 : b_1_2;
    assign e_1_2 = e_0_1 > b_1_2 ? b_1_2 : e_0_1;

    assign out2 = e_1_0 > e_1_1 ? e_1_1 : e_1_0; 
//-------------------------------------------------------
// out1
//-------------------------------------------------------
//b-group
    assign b_out1_1_0 = a_2_0 > b_0_1 ? a_2_0 : b_0_1;
    assign b_out1_1_1 = a_2_0 > b_0_1 ? b_0_1 : a_2_0;
//c-group
    assign c_out1_1_0 = a_2_1 > c_0_0 ? a_2_1 : c_0_0;
    assign c_out1_1_1 = a_2_1 > c_0_0 ? c_0_0 : a_2_1;

    assign c_out1_2_0 = c_out1_1_1 > c_0_1 ? c_out1_1_1 : c_0_1;
    assign c_out1_2_1 = c_out1_1_1 > c_0_1 ? c_0_1 : c_out1_1_1;
//d-group
    assign d_out1_1_0 = a_2_2 > d_0_0 ? a_2_2 : d_0_0;
//e-group
    assign e_out1_1_0 = d_out1_1_0 > c_out1_2_0 ? d_out1_1_0 : c_out1_2_0;
    assign e_out1_1_1 = d_out1_1_0 > c_out1_2_0 ? c_out1_2_0 : d_out1_1_0;

    assign e_out1_1_2 = e_out1_1_1 > b_out1_1_1 ? e_out1_1_1 : b_out1_1_1;
    assign e_out1_1_3 = e_out1_1_1 > b_out1_1_1 ? b_out1_1_1 : e_out1_1_1;

    assign out1 = e_out1_1_0 > e_out1_1_2 ? e_out1_1_2 : e_out1_1_0;
endmodule