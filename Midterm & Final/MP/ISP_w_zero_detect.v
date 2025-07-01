module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input       in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output out_valid,
    output [7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output [31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output [7:0]  awlen_s_inf,
    output        awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output [127:0] wdata_s_inf,
    output         wlast_s_inf,
    output         wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output         bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]   arid_s_inf,
    output [31:0]  araddr_s_inf,
    output [7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output         arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output         rready_s_inf
    
);

// Your Design
//============================================================
// Parameter and Integer
//============================================================
parameter IDLE = 0, S_ADDR = 1, R_DATA = 2;
parameter W_SRAM = 1, WAIT = 2, WAIT_2_CYCLE = 3;
parameter Exposure = 4, Focus = 5, OUT = 6 , WAIT_W_SRAM = 3;
integer i;
parameter READ = 1, SHIFT = 2, WRITE = 3;
genvar j;
//============================================================
// Register
//============================================================
// Input Buffer
reg [127:0] rdata_s_inf_reg;
reg rvalid_s_inf_reg;
reg rlast_s_inf_reg;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        rdata_s_inf_reg  <= 128'h0;
        rvalid_s_inf_reg <= 0;
        rlast_s_inf_reg  <= 0;
    end
    else begin
        rdata_s_inf_reg  <= rdata_s_inf;
        rvalid_s_inf_reg <= rvalid_s_inf;
        rlast_s_inf_reg  <= rlast_s_inf;
    end
end
//------------------------------------------------------------
reg [7:0] out_data_sel;
reg pattern_0_check;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        pattern_0_check <= 0;
    else if(out_valid)
        pattern_0_check <= 1;
end
//------------------------------------------------------------
reg zero_detect_reg[0:15];
//------------------------------------------------------------
reg [1:0] cs_dram, ns_dram;
wire read_data_done;
//------------------------------------------------------------
reg  [31:0] araddr_s_inf_reg;
wire [7:0] dram_data[0:15];
//------------------------------------------------------------
reg [3:0] cnt_dram_read_data;//cnt_12
reg [5:0] cnt_64;
reg [1:0] cnt_rgb, cnt_rgb_ns;
reg [3:0] cnt_img_or_focus;
reg [3:0] cnt_9_for_write_sram;
reg [2:0] cnt_6_for_read_focus_sram;
reg cnt_2_cycle;//can merge with sram_autofocus_addr_ctrl
//------------------------------------------------------------
reg  [43:0] exposure_reg[0:1][0:8];//rgb to rg
wire [10:0] exposure_table[0:7][0:7] ;
wire [395:0] exposure_information;
reg  [47:0] Autofocus_reg[0:5];
//------------------------------------------------------------
reg [2:0] cs_isp, ns_isp;
reg [1:0] cs_exposure, ns_exposure;
//------------------------------------------------------------
reg [8:0]  addr_e, addr_a;
reg [43:0] data_in_e, data_out_e;
reg [43:0] data_out_e_reg;
reg [47:0] data_in_a, data_out_a;
reg [47:0] data_out_a_reg;
reg WEB_e, WEB_a;
//------------------------------------------------------------
wire start_w_sram;
reg zero_detect;
wire finish_w_sram;
wire w_sram_done;
wire w_sram_from_dram_done;
wire wait_2_cycle_done;
wire exposure_done;
wire focus_done;
wire focus_grayscale_done;
wire start_cal_difference;
//------------------------------------------------------------
reg in_mode_reg;
reg [3:0] in_pic_no_reg;
reg [1:0] in_ratio_mode_reg;
//------------------------------------------------------------
reg [7:0] data_af_reg [0:2];
reg sram_autofocus_addr_ctrl;
wire [47:0] data_af;
//------------------------------------------------------------
reg [13:0] D6x6;
reg [12:0] D4x4;
reg [9:0]  D2x2;
reg [1:0] max_contrast_reg;
reg [1:0] max_contrast;
//------------------------------------------------------------
reg [17:0] avg_reg;
wire exposure_for_w_focus_sram;
wire exposure_for_w_focus_sram_done;
//exposure_triangle
wire [10:0] exposure_info_0;
wire [10:0] exposure_info_1, exposure_info_2;
wire [10:0] exposure_info_3, exposure_info_4, exposure_info_5;
wire [10:0] exposure_info_6, exposure_info_7, exposure_info_8, exposure_info_9;
wire [10:0] exposure_info_10, exposure_info_11, exposure_info_12, exposure_info_13, exposure_info_14;
wire [10:0] exposure_info_15, exposure_info_16, exposure_info_17, exposure_info_18, exposure_info_19, exposure_info_20;
wire [10:0] exposure_info_21, exposure_info_22, exposure_info_23, exposure_info_24, exposure_info_25, exposure_info_26, exposure_info_27;
wire [10:0] exposure_info_28, exposure_info_29, exposure_info_30, exposure_info_31, exposure_info_32, exposure_info_33, exposure_info_34, exposure_info_35;
//------------------------------------------------------------
// 22bit_adder*18
//------------------------------------------------------------
reg  [21:0] add_1_in1, add_2_in1, add_3_in1, add_4_in1, add_5_in1, add_6_in1, add_7_in1, add_8_in1, add_9_in1, add_10_in1, add_11_in1, add_12_in1, add_13_in1, add_14_in1, add_15_in1, add_16_in1, add_17_in1, add_18_in1;
reg  [21:0] add_1_in2, add_2_in2, add_3_in2, add_4_in2, add_5_in2, add_6_in2, add_7_in2, add_8_in2, add_9_in2, add_10_in2, add_11_in2, add_12_in2, add_13_in2, add_14_in2, add_15_in2, add_16_in2, add_17_in2, add_18_in2;
wire [21:0] add_1_out, add_2_out, add_3_out, add_4_out, add_5_out, add_6_out, add_7_out, add_8_out, add_9_out, add_10_out, add_11_out, add_12_out, add_13_out, add_14_out, add_15_out, add_16_out, add_17_out, add_18_out;

assign add_1_out  = add_1_in1  + add_1_in2;
assign add_2_out  = add_2_in1  + add_2_in2;
assign add_3_out  = add_3_in1  + add_3_in2;
assign add_4_out  = add_4_in1  + add_4_in2;
assign add_5_out  = add_5_in1  + add_5_in2;
assign add_6_out  = add_6_in1  + add_6_in2;
assign add_7_out  = add_7_in1  + add_7_in2;
assign add_8_out  = add_8_in1  + add_8_in2;
assign add_9_out  = add_9_in1  + add_9_in2;
assign add_10_out = add_10_in1 + add_10_in2;
assign add_11_out = add_11_in1 + add_11_in2;
assign add_12_out = add_12_in1 + add_12_in2;
assign add_13_out = add_13_in1 + add_13_in2;
assign add_14_out = add_14_in1 + add_14_in2;
assign add_15_out = add_15_in1 + add_15_in2;
assign add_16_out = add_16_in1 + add_16_in2;
assign add_17_out = add_17_in1 + add_17_in2;
assign add_18_out = add_18_in1 + add_18_in2;
always @(*) begin
    add_1_in1  = 22'h0;add_1_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_1_in2 = {exposure_table[0][0], exposure_table[2][0]};
        case (cnt_rgb)
            'd0,'d2:
                add_1_in1 = exposure_reg[0][0][43:22];
            'd1,'d3:
                add_1_in1 = exposure_reg[1][0][43:22];
        endcase
    end
    else begin
        if(cs_exposure == READ && ns_exposure == SHIFT)begin
            add_1_in1 = {           11'd0, exposure_info_21};
            add_1_in2 = {exposure_info_35, exposure_info_35};
        end
        else if(cs_exposure == SHIFT)begin
            add_1_in1 = cnt_6_for_read_focus_sram[0] ? exposure_info_2 : 0;
            add_1_in2 = cnt_6_for_read_focus_sram[0] ? exposure_info_4 : 0;
        end
        else if(cs_exposure == WRITE)begin
            add_1_in1 = exposure_reg[1][0][43:22];//1
            add_1_in2 = exposure_reg[1][0][21:0 ];//2
        end
    end
end
always @(*) begin
    add_2_in1  = 22'h0;add_2_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_2_in2 = {exposure_table[2][1], exposure_table[2][2]};
        case (cnt_rgb)
            'd0,'d2:
                add_2_in1 = exposure_reg[0][0][21:0];
            'd1,'d3:
                add_2_in1 = exposure_reg[1][0][21:0];
        endcase
    end
    else begin
        if(cs_exposure == READ && ns_exposure == SHIFT)begin
            add_2_in1 = {exposure_info_22, exposure_info_23};
            add_2_in2 = {exposure_info_35, exposure_info_35};
        end
        else if(cs_exposure == SHIFT)begin
            add_2_in1 = cnt_6_for_read_focus_sram[0] ? exposure_info_7  : 0;
            add_2_in2 = cnt_6_for_read_focus_sram[0] ? exposure_info_11 : 0;
        end
        else if(cs_exposure == WRITE)begin
            add_2_in1 = exposure_reg[1][1][43:22];//5
            add_2_in2 = exposure_reg[1][1][21:0 ];//10
        end
    end
end
always @(*) begin
    add_3_in1  = 22'h0;add_3_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_3_in2 = {exposure_table[1][0], exposure_table[1][1]};
        case (cnt_rgb)
            'd0,'d2:
                add_3_in1 = exposure_reg[0][1][43:22];
            'd1,'d3:
                add_3_in1 = exposure_reg[1][1][43:22];
        endcase
    end
    else begin
        if(cs_exposure == READ && ns_exposure == SHIFT)begin
            add_3_in1 = {exposure_info_24, exposure_info_25};
            add_3_in2 = {exposure_info_35, exposure_info_35};
        end
        else if(cs_exposure == SHIFT)begin
            add_3_in1 = cnt_6_for_read_focus_sram[0] ? exposure_info_16 : 0;
            add_3_in2 = cnt_6_for_read_focus_sram[0] ? exposure_info_22 : 0;
        end
        else if(cs_exposure == WRITE)begin
            add_3_in1 = exposure_reg[1][2][43:22];//6
            add_3_in2 = exposure_reg[1][2][21:0 ];//11
        end
    end
end
always @(*) begin
    add_4_in1  = 22'h0;add_4_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_4_in2 = {exposure_table[5][4], exposure_table[5][5]};
        case (cnt_rgb)
            'd0,'d2:
                add_4_in1 = exposure_reg[0][1][21:0];
            'd1,'d3:
                add_4_in1 = exposure_reg[1][1][21:0];
        endcase
    end
    else begin
        if(cs_exposure == READ && ns_exposure == SHIFT)begin
            add_4_in1 = {exposure_info_26, exposure_info_27};
            add_4_in2 = {exposure_info_35, exposure_info_35};
        end
        else if(cs_exposure == SHIFT)begin
            add_4_in1 = cnt_6_for_read_focus_sram[0] ? exposure_info_29 : 0;
            add_4_in2 = 22'd0;
        end 
        else if(cs_exposure == WRITE)begin
            add_4_in1 = exposure_reg[1][3][43:22];//7
            add_4_in2 = exposure_reg[1][3][21:0 ];//12
        end       
    end
end
always @(*) begin
    add_5_in1  = 22'h0;add_5_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_5_in2 = {exposure_table[4][4], exposure_table[6][4]};
        case (cnt_rgb)
            'd0,'d2:
                add_5_in1 = exposure_reg[0][2][43:22];
            'd1,'d3:
                add_5_in1 = exposure_reg[1][2][43:22];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_5_in1 = exposure_info_5 ;
            add_5_in2 = exposure_info_8 ;
        end
        else if(cs_exposure == WRITE)begin
            add_5_in1 = exposure_reg[1][4][43:22];//8
            add_5_in2 = exposure_reg[1][4][21:0 ];//13
        end
    end
end
always @(*) begin
    add_6_in1  = 22'h0;add_6_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_6_in2 = {exposure_table[6][5], exposure_table[6][6]};
        case (cnt_rgb)
            'd0,'d2:
                add_6_in1 = exposure_reg[0][2][21:0];
            'd1,'d3:
                add_6_in1 = exposure_reg[1][2][21:0];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_6_in1 = exposure_info_12 ;
            add_6_in2 = exposure_info_17 ;
        end
        else if(cs_exposure == WRITE)begin
            add_6_in1 = exposure_reg[1][5][43:22];//9
            add_6_in2 = exposure_reg[1][5][21:0 ];//14
        end
    end
end
always @(*) begin
    add_7_in1  = 22'h0;add_7_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_7_in2 = {exposure_table[3][0], exposure_table[3][1]};
        case (cnt_rgb)
            'd0,'d2:
                add_7_in1 = exposure_reg[0][3][43:22];
            'd1,'d3:
                add_7_in1 = exposure_reg[1][3][43:22];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_7_in1 = exposure_info_23;
            add_7_in2 = exposure_info_30;
        end
        else if(cs_exposure == WRITE)begin
            add_7_in1 = exposure_reg[1][1][43:22];//6+11
            add_7_in2 = exposure_reg[1][6][43:22];//3
        end
    end
end
always @(*) begin
    add_8_in1  = 22'h0;add_8_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_8_in2 = {exposure_table[3][2], exposure_table[3][3]};
        case (cnt_rgb)
            'd0,'d2:
                add_8_in1 = exposure_reg[0][3][21:0];
            'd1,'d3:
                add_8_in1 = exposure_reg[1][3][21:0];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_8_in1 = exposure_info_9 ;
            add_8_in2 = exposure_info_13;
        end
        else if(cs_exposure == WRITE)begin
            add_8_in1 = exposure_reg[1][1][21:0 ];//7+12
            add_8_in2 = exposure_reg[1][6][21:0 ];//4
        end
    end
end
always @(*) begin
    add_9_in1  = 22'h0;add_9_in2  = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_9_in2 = {exposure_table[4][0], exposure_table[4][1]};
        case (cnt_rgb)
            'd0,'d2:
                add_9_in1 = exposure_reg[0][4][43:22];
            'd1,'d3:
                add_9_in1 = exposure_reg[1][4][43:22];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_9_in1 = exposure_info_18 ;
            add_9_in2 = exposure_info_24 ;
        end
        else if(cs_exposure == WRITE)begin
            add_9_in1 = exposure_reg[1][1][43:22]  ;
            add_9_in2 = exposure_reg[1][1][21:0 ]  ;
        end
    end
end
always @(*) begin
    add_10_in1 = 22'h0;add_10_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_10_in2 = {exposure_table[4][2], exposure_table[4][3]};
        case (cnt_rgb)
            'd0,'d2:
                add_10_in1 = exposure_reg[0][4][21:0];
            'd1,'d3:
                add_10_in1 = exposure_reg[1][4][21:0];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_10_in1 = exposure_info_31 ;
            add_10_in2 = 22'd0 ;
        end
        else if(cs_exposure == WRITE)begin
            add_10_in1 = exposure_reg[1][0][21:0]  ;
            add_10_in2 = exposure_reg[1][3][43:22] ;
        end
    end
end
always @(*) begin
    add_11_in1 = 22'h0;add_11_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_11_in2 = {exposure_table[5][0], exposure_table[5][1]};
        case (cnt_rgb)
            'd0,'d2:
                add_11_in1 = exposure_reg[0][5][43:22];
            'd1,'d3:
                add_11_in1 = exposure_reg[1][5][43:22];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_11_in1 = exposure_info_14 ;
            add_11_in2 = exposure_info_19 ;
        end
        else if(cs_exposure == WRITE)begin
            add_11_in1 = exposure_reg[1][0][43:22]  ;//5+8
            add_11_in2 = exposure_reg[1][3][21:0 ] ;//12+17
        end
    end
end
always @(*) begin
    add_12_in1 = 22'h0;add_12_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_12_in2 = {exposure_table[5][2], exposure_table[5][3]};
        case (cnt_rgb)
            'd0,'d2:
                add_12_in1 = exposure_reg[0][5][21:0];
            'd1,'d3:
                add_12_in1 = exposure_reg[1][5][21:0];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_12_in1 = exposure_info_25 ;
            add_12_in2 = exposure_info_32 ;
        end
        else if(cs_exposure == WRITE)begin
            add_12_in1 = exposure_reg[1][0][43:22] ;
            add_12_in2 = exposure_reg[1][0][21:0 ] ;
        end
    end
end
always @(*) begin
    add_13_in1 = 22'h0;add_13_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_13_in2 = {exposure_table[6][0], exposure_table[6][1]};
        case (cnt_rgb)
            'd0,'d2:
                add_13_in1 = exposure_reg[0][6][43:22];
            'd1,'d3:
                add_13_in1 = exposure_reg[1][6][43:22];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_13_in1 = exposure_info_20 ;
            add_13_in2 = exposure_info_26 ;
        end
        else if(cs_exposure == WRITE)begin
            add_13_in1 = exposure_reg[1][1][43:22] ;
            add_13_in2 = exposure_reg[1][1][21:0 ] ;
        end
        
    end
end
always @(*) begin
    add_14_in1 = 22'h0;add_14_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_14_in2 = {exposure_table[6][2], exposure_table[6][3]};
        case (cnt_rgb)
            'd0,'d2:
                add_14_in1 = exposure_reg[0][6][21:0];
            'd1,'d3:
                add_14_in1 = exposure_reg[1][6][21:0];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_14_in1 = exposure_info_33 ;
            add_14_in2 = 22'd0 ;
        end
        else if(cs_exposure == WRITE)begin
            add_14_in1 = exposure_reg[1][2][43:22] ;
            add_14_in2 = exposure_reg[1][2][21:0] ;
        end
    end
end
always @(*) begin
    add_15_in1 = 22'h0;add_15_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_15_in2 = {exposure_table[7][0], exposure_table[7][1]};
        case (cnt_rgb)
            'd0,'d2:
                add_15_in1 = exposure_reg[0][7][43:22];
            'd1,'d3:
                add_15_in1 = exposure_reg[1][7][43:22];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_15_in1 = exposure_info_27 ;
            add_15_in2 = exposure_info_34 ;
        end
        else if(cs_exposure == WRITE)begin
            add_15_in1 = exposure_reg[1][4][43:22] ;
            add_15_in2 = exposure_reg[1][4][21:0] ;
        end
    end
end
always @(*) begin
    add_16_in1 = 22'h0;add_16_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_16_in2 = {exposure_table[7][2], exposure_table[7][3]};
        case (cnt_rgb)
            'd0,'d2:
                add_16_in1 = exposure_reg[0][7][21:0];
            'd1,'d3:
                add_16_in1 = exposure_reg[1][7][21:0];
        endcase
    end
    else begin
        if(cs_exposure == SHIFT)begin
            add_16_in1 = exposure_info_35 ;
            add_16_in2 = 22'd0 ;
        end
        else if(cs_exposure == WRITE)begin
            add_16_in1 = exposure_reg[1][5][43:22] ;
            add_16_in2 = exposure_reg[1][5][21:0] ;
        end
    end
end
always @(*) begin
    add_17_in1 = 22'h0;add_17_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_17_in2 = {exposure_table[7][4], exposure_table[7][5]};
        case (cnt_rgb)
            'd0,'d2:
                add_17_in1 = exposure_reg[0][8][43:22];
            'd1,'d3:
                add_17_in1 = exposure_reg[1][8][43:22];
        endcase
    end
    else begin
        if(cs_exposure == WRITE)begin
            add_17_in1 = exposure_reg[1][6][43:22] ;
            add_17_in2 = exposure_reg[1][6][21:0] ;
        end
    end
end
always @(*) begin
    add_18_in1 = 22'h0;add_18_in2 = 22'h0;
    if(rvalid_s_inf_reg)begin
        add_18_in2 = {exposure_table[7][6], exposure_table[7][7]};
        case (cnt_rgb)
            'd0,'d2:
                add_18_in1 = exposure_reg[0][8][21:0];
            'd1,'d3:
                add_18_in1 = exposure_reg[1][8][21:0];
        endcase
    end
    else begin
        if(cs_isp == Exposure)begin
            add_18_in1 = avg_reg;
            if(cs_exposure == WRITE)begin
                case (cnt_6_for_read_focus_sram)
                    'd2:begin
                        case (cnt_9_for_write_sram)
                            'd0:add_18_in2 = exposure_reg[1][7][21:0 ]  << 6;
                            'd1:add_18_in2 = exposure_reg[1][7][43:22]  << 5;
                            'd2:add_18_in2 = exposure_reg[1][8][43:22]  << 4;
                            'd3:add_18_in2 = exposure_reg[1][8][21:0 ]  << 3;
                            'd4:add_18_in2 = exposure_reg[1][2][43:22]  << 2;
                            'd5:add_18_in2 = exposure_reg[1][2][21:0 ]  << 1;
                            'd6:add_18_in2 = exposure_reg[1][3][43:22]      ;
                        endcase
                    end 
                    'd1,'d3:begin
                        case (cnt_9_for_write_sram)
                            'd0:add_18_in2 = exposure_reg[1][7][21:0 ]  << 5;
                            'd1:add_18_in2 = exposure_reg[1][7][43:22]  << 4;
                            'd2:add_18_in2 = exposure_reg[1][8][43:22]  << 3;
                            'd3:add_18_in2 = exposure_reg[1][8][21:0 ]  << 2;
                            'd4:add_18_in2 = exposure_reg[1][2][43:22]  << 1;
                            'd5:add_18_in2 = exposure_reg[1][2][21:0 ]      ;
                        endcase
                    end
                endcase
            end
        end
    end
end
//============================================================
// Avg Register
//============================================================
    always @(posedge clk) begin
        if(cs_isp == IDLE)
            avg_reg <= 18'd0;
        else if(cs_isp == Exposure)
            avg_reg <= add_18_out;
    end
//============================================================
// DRAM FSM
//============================================================
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs_dram <= IDLE;
        end else begin
            cs_dram <= ns_dram;
        end
    end
    always @(*) begin
        case (cs_dram)
            IDLE   : ns_dram = read_data_done   ? IDLE : S_ADDR;
            S_ADDR : ns_dram = arready_s_inf    ? R_DATA : S_ADDR;
            R_DATA : ns_dram = rlast_s_inf_reg  ? (cnt_dram_read_data == 'd11 ? WAIT_W_SRAM : S_ADDR) : R_DATA; 
            WAIT_W_SRAM : ns_dram = (cnt_9_for_write_sram == 8) ? IDLE : WAIT_W_SRAM;
            default: ns_dram = IDLE;
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cnt_dram_read_data <= 0;
        end else begin
            if(cnt_dram_read_data == 'd12)
                cnt_dram_read_data <= cnt_dram_read_data;
            else if (cs_dram == R_DATA && rlast_s_inf_reg ) 
                cnt_dram_read_data <= cnt_dram_read_data + 1;
        end
    end
    assign read_data_done = (cnt_dram_read_data == 'd12);
//============================================================
// Read data from DRAM
//============================================================
    assign arid_s_inf = 4'b0000;
    assign arlen_s_inf = 8'd255;
    assign arsize_s_inf = 3'b100;
    assign arburst_s_inf = 2'b01;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            araddr_s_inf_reg <= 32'h10000;
        else if(cs_dram == S_ADDR && arready_s_inf)begin
            // araddr_s_inf_reg <= araddr_s_inf_reg + 32'h01000;
            araddr_s_inf_reg[31:16] <= araddr_s_inf_reg[31:16];
            araddr_s_inf_reg[15:12] <= araddr_s_inf_reg[15:12] + 4'd1;
            araddr_s_inf_reg[11:0]  <= 12'h0;
        end
    end
    assign arvalid_s_inf = cs_dram == S_ADDR;
    assign araddr_s_inf  = arvalid_s_inf ? araddr_s_inf_reg : 0;
    assign rready_s_inf = cs_dram == R_DATA;

//Debug
    assign dram_data[0]  = rdata_s_inf_reg[7:0];
    assign dram_data[1]  = rdata_s_inf_reg[15:8];
    assign dram_data[2]  = rdata_s_inf_reg[23:16];
    assign dram_data[3]  = rdata_s_inf_reg[31:24];
    assign dram_data[4]  = rdata_s_inf_reg[39:32];
    assign dram_data[5]  = rdata_s_inf_reg[47:40];
    assign dram_data[6]  = rdata_s_inf_reg[55:48];
    assign dram_data[7]  = rdata_s_inf_reg[63:56];
    assign dram_data[8]  = rdata_s_inf_reg[71:64];
    assign dram_data[9]  = rdata_s_inf_reg[79:72];
    assign dram_data[10] = rdata_s_inf_reg[87:80];
    assign dram_data[11] = rdata_s_inf_reg[95:88];
    assign dram_data[12] = rdata_s_inf_reg[103:96];
    assign dram_data[13] = rdata_s_inf_reg[111:104];
    assign dram_data[14] = rdata_s_inf_reg[119:112];
    assign dram_data[15] = rdata_s_inf_reg[127:120];
//============================================================
// Exposure Register
//============================================================
exposure_prossesor p0(
    .data(rdata_s_inf_reg),
    .exposure_information(exposure_information)
);
//exposure_information to exposure_table
    assign exposure_table[0][0] = exposure_information[10:0];
    assign exposure_table[1][0] = exposure_information[21:11];
    assign exposure_table[1][1] = exposure_information[32:22];
    assign exposure_table[2][0] = exposure_information[43:33];
    assign exposure_table[2][1] = exposure_information[54:44];
    assign exposure_table[2][2] = exposure_information[64:55];
    assign exposure_table[3][0] = exposure_information[76:66];
    assign exposure_table[3][1] = exposure_information[87:77];
    assign exposure_table[3][2] = exposure_information[98:88];
    assign exposure_table[3][3] = exposure_information[109:99];
    assign exposure_table[4][0] = exposure_information[120:110];
    assign exposure_table[4][1] = exposure_information[131:121];
    assign exposure_table[4][2] = exposure_information[142:132];
    assign exposure_table[4][3] = exposure_information[153:143];
    assign exposure_table[4][4] = exposure_information[164:154];
    assign exposure_table[5][0] = exposure_information[175:165];
    assign exposure_table[5][1] = exposure_information[186:176];
    assign exposure_table[5][2] = exposure_information[197:187];
    assign exposure_table[5][3] = exposure_information[208:198];
    assign exposure_table[5][4] = exposure_information[219:209];
    assign exposure_table[5][5] = exposure_information[230:220];
    assign exposure_table[6][0] = exposure_information[241:231];
    assign exposure_table[6][1] = exposure_information[252:242];
    assign exposure_table[6][2] = exposure_information[263:253];
    assign exposure_table[6][3] = exposure_information[274:264];
    assign exposure_table[6][4] = exposure_information[285:275];
    assign exposure_table[6][5] = exposure_information[296:286];
    assign exposure_table[6][6] = exposure_information[307:297];
    assign exposure_table[7][0] = exposure_information[318:308];
    assign exposure_table[7][1] = exposure_information[329:319];
    assign exposure_table[7][2] = exposure_information[340:330];
    assign exposure_table[7][3] = exposure_information[351:341];
    assign exposure_table[7][4] = exposure_information[362:352];
    assign exposure_table[7][5] = exposure_information[373:363];
    assign exposure_table[7][6] = exposure_information[384:374];
    assign exposure_table[7][7] = exposure_information[395:385];
// assign saturation_value = exposure_information[406:396];
    assign exposure_info_0  = exposure_reg[0][0][43:33];
    assign exposure_info_3  = exposure_reg[0][0][32:22];
    assign exposure_info_4  = exposure_reg[0][0][21:11];
    assign exposure_info_5  = exposure_reg[0][0][10:0 ];

    assign exposure_info_1  = exposure_reg[0][1][43:33];
    assign exposure_info_2  = exposure_reg[0][1][32:22];
    assign exposure_info_19 = exposure_reg[0][1][21:11];
    assign exposure_info_20 = exposure_reg[0][1][10:0 ];

    assign exposure_info_14 = exposure_reg[0][2][43:33];
    assign exposure_info_25 = exposure_reg[0][2][32:22];
    assign exposure_info_26 = exposure_reg[0][2][21:11];
    assign exposure_info_27 = exposure_reg[0][2][10:0 ];

    assign exposure_info_6  = exposure_reg[0][3][43:33];
    assign exposure_info_7  = exposure_reg[0][3][32:22];
    assign exposure_info_8  = exposure_reg[0][3][21:11];
    assign exposure_info_9  = exposure_reg[0][3][10:0 ];

    assign exposure_info_10 = exposure_reg[0][4][43:33];
    assign exposure_info_11 = exposure_reg[0][4][32:22];
    assign exposure_info_12 = exposure_reg[0][4][21:11];
    assign exposure_info_13 = exposure_reg[0][4][10:0 ];

    assign exposure_info_15 = exposure_reg[0][5][43:33];
    assign exposure_info_16 = exposure_reg[0][5][32:22];
    assign exposure_info_17 = exposure_reg[0][5][21:11];
    assign exposure_info_18 = exposure_reg[0][5][10:0 ];

    assign exposure_info_21 = exposure_reg[0][6][43:33];
    assign exposure_info_22 = exposure_reg[0][6][32:22];
    assign exposure_info_23 = exposure_reg[0][6][21:11];
    assign exposure_info_24 = exposure_reg[0][6][10:0 ];

    assign exposure_info_28 = exposure_reg[0][7][43:33];
    assign exposure_info_29 = exposure_reg[0][7][32:22];
    assign exposure_info_30 = exposure_reg[0][7][21:11];
    assign exposure_info_31 = exposure_reg[0][7][10:0 ];

    assign exposure_info_32 = exposure_reg[0][8][43:33];
    assign exposure_info_33 = exposure_reg[0][8][32:22];
    assign exposure_info_34 = exposure_reg[0][8][21:11];
    assign exposure_info_35 = exposure_reg[0][8][10:0 ];
//debug
    wire [10:0] e_debug[0:35];
        assign e_debug[0 ] = exposure_reg[1][0][43:22];
        assign e_debug[1 ] = exposure_reg[1][0][21:0 ];
        assign e_debug[2 ] = exposure_reg[1][1][43:22];
        assign e_debug[3 ] = exposure_reg[1][1][22:0 ];
        assign e_debug[4 ] = exposure_reg[1][2][43:22];
        assign e_debug[5 ] = exposure_reg[1][2][21:0 ];
        assign e_debug[6 ] = exposure_reg[1][3][43:22];
        assign e_debug[7 ] = exposure_reg[1][3][21:0];
        assign e_debug[8 ] = exposure_reg[1][4][43:22];
        assign e_debug[9 ] = exposure_reg[1][4][21:0 ];
        assign e_debug[10] = exposure_reg[1][5][43:22];
        assign e_debug[11] = exposure_reg[1][5][22:0 ];
        assign e_debug[12] = exposure_reg[1][6][43:22];
        assign e_debug[13] = exposure_reg[1][6][21:0 ];
        assign e_debug[14] = exposure_reg[1][7][43:22];
        assign e_debug[15] = exposure_reg[1][7][21:0];
        assign e_debug[16] = exposure_reg[1][8][43:22];
        assign e_debug[17] = exposure_reg[1][8][10:0 ];
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        exposure_reg[0][0] <= 44'h0;exposure_reg[0][1] <= 44'h0;exposure_reg[0][2] <= 44'h0;
        exposure_reg[0][3] <= 44'h0;exposure_reg[0][4] <= 44'h0;exposure_reg[0][5] <= 44'h0;
        exposure_reg[0][6] <= 44'h0;exposure_reg[0][7] <= 44'h0;exposure_reg[0][8] <= 44'h0;
    end 
    else if(cs_dram == R_DATA)begin
        if((cnt_rgb == 0  || cnt_rgb == 2) && cnt_64 == 0)begin
            exposure_reg[0][0] <= {exposure_table[0][0], exposure_table[2][0], exposure_table[2][1], exposure_table[2][2]};
            exposure_reg[0][1] <= {exposure_table[1][0], exposure_table[1][1], exposure_table[5][4], exposure_table[5][5]};
            exposure_reg[0][2] <= {exposure_table[4][4], exposure_table[6][4], exposure_table[6][5], exposure_table[6][6]};
            exposure_reg[0][3] <= {exposure_table[3][0], exposure_table[3][1], exposure_table[3][2], exposure_table[3][3]};
            exposure_reg[0][4] <= {exposure_table[4][0], exposure_table[4][1], exposure_table[4][2], exposure_table[4][3]};
            exposure_reg[0][5] <= {exposure_table[5][0], exposure_table[5][1], exposure_table[5][2], exposure_table[5][3]};
            exposure_reg[0][6] <= {exposure_table[6][0], exposure_table[6][1], exposure_table[6][2], exposure_table[6][3]};
            exposure_reg[0][7] <= {exposure_table[7][0], exposure_table[7][1], exposure_table[7][2], exposure_table[7][3]};
            exposure_reg[0][8] <= {exposure_table[7][4], exposure_table[7][5], exposure_table[7][6], exposure_table[7][7]};
        end
        else begin
            case (cnt_rgb)
                'd0:begin
                    exposure_reg[0][0] <= {add_1_out , add_2_out };
                    exposure_reg[0][1] <= {add_3_out , add_4_out };
                    exposure_reg[0][2] <= {add_5_out , add_6_out };
                    exposure_reg[0][3] <= {add_7_out , add_8_out };
                    exposure_reg[0][4] <= {add_9_out , add_10_out};
                    exposure_reg[0][5] <= {add_11_out, add_12_out};
                    exposure_reg[0][6] <= {add_13_out, add_14_out};
                    exposure_reg[0][7] <= {add_15_out, add_16_out};
                    exposure_reg[0][8] <= {add_17_out, add_18_out}; 
                end 
                'd2:begin
                    exposure_reg[0][0] <= {add_1_out , add_2_out };
                    exposure_reg[0][1] <= {add_3_out , add_4_out };
                    exposure_reg[0][2] <= {add_5_out , add_6_out };
                    exposure_reg[0][3] <= {add_7_out , add_8_out };
                    exposure_reg[0][4] <= {add_9_out , add_10_out};
                    exposure_reg[0][5] <= {add_11_out, add_12_out};
                    exposure_reg[0][6] <= {add_13_out, add_14_out};
                    exposure_reg[0][7] <= {add_15_out, add_16_out};
                    exposure_reg[0][8] <= {add_17_out, add_18_out}; 
                end
            endcase
        end
    end
    else if(ns_isp == Exposure || cs_isp == Exposure)begin
        if(cs_exposure == IDLE && ns_exposure == READ)begin
            exposure_reg[0][8] <= data_out_e;
            for(i = 0; i < 8; i = i + 1)
                exposure_reg[0][i] <= exposure_reg[0][i + 1];
        end
        else if(ns_exposure == SHIFT)begin
            case (in_ratio_mode_reg)
                    'd0:begin//<<2
                        exposure_reg[0][0] <= {exposure_info_5 , exposure_info_12, exposure_info_13, exposure_info_14};
                        exposure_reg[0][1] <= {exposure_info_8 , exposure_info_9 , exposure_info_34, exposure_info_35};
                        exposure_reg[0][2] <= {exposure_info_27,            11'd0,            11'd0,            11'd0};
                        exposure_reg[0][3] <= {exposure_info_17, exposure_info_18, exposure_info_19, exposure_info_20};
                        exposure_reg[0][4] <= {exposure_info_23, exposure_info_24, exposure_info_25, exposure_info_26};
                        exposure_reg[0][5] <= {exposure_info_30, exposure_info_31, exposure_info_32, exposure_info_33};
                        exposure_reg[0][6] <= {           11'd0,            11'd0,            11'd0,            11'd0};
                        exposure_reg[0][7] <= {           11'd0,            11'd0,            11'd0,            11'd0};
                        exposure_reg[0][8] <= {           11'd0,            11'd0,            11'd0,            11'd0};
                    end 
                    'd1:begin//<<1
                        exposure_reg[0][0] <= {exposure_info_2 , exposure_info_7 , exposure_info_8 , exposure_info_9 };
                        exposure_reg[0][1] <= {exposure_info_4 , exposure_info_5 , exposure_info_26, exposure_info_27};
                        exposure_reg[0][2] <= {exposure_info_20, exposure_info_33, exposure_info_34, exposure_info_35};
                        exposure_reg[0][3] <= {exposure_info_11, exposure_info_12, exposure_info_13, exposure_info_14};
                        exposure_reg[0][4] <= {exposure_info_16, exposure_info_17, exposure_info_18, exposure_info_19};
                        exposure_reg[0][5] <= {exposure_info_22, exposure_info_23, exposure_info_24, exposure_info_25};
                        exposure_reg[0][6] <= {exposure_info_29, exposure_info_30, exposure_info_31, exposure_info_32};
                        exposure_reg[0][7] <= {           11'd0,            11'd0,            11'd0,            11'd0};
                        exposure_reg[0][8] <= {           11'd0,            11'd0,            11'd0,            11'd0};
                    end
                    'd2:begin
                        for(i = 0; i < 9; i = i + 1)
                            exposure_reg[0][i] <= exposure_reg[0][i];
                    end
                    'd3:begin//>>1
                        exposure_reg[0][0] <= {          11'd0 ,            11'd0, exposure_info_1 , exposure_info_2 };
                        exposure_reg[0][1] <= {          11'd0 , exposure_info_0 , exposure_info_13, exposure_info_14};
                        exposure_reg[0][2] <= {exposure_info_9 , exposure_info_18, exposure_info_19, exposure_info_20};
                        exposure_reg[0][3] <= {          11'd0 , exposure_info_3 , exposure_info_4 , exposure_info_5 };
                        exposure_reg[0][4] <= {          11'd0 , exposure_info_6 , exposure_info_7 , exposure_info_8 };
                        exposure_reg[0][5] <= {          11'd0 , exposure_info_10, exposure_info_11, exposure_info_12};
                        exposure_reg[0][6] <= {          11'd0 , exposure_info_15, exposure_info_16, exposure_info_17};
                        exposure_reg[0][7] <= {add_1_out       , add_2_out       };
                        exposure_reg[0][8] <= {add_3_out       , add_4_out       };
                    end
                endcase
        end
        else if(cs_exposure == READ)begin
            exposure_reg[0][8] <= data_out_e;
            for(i = 0; i < 8; i = i + 1)
                exposure_reg[0][i] <= exposure_reg[0][i + 1];
        end
        else if(cs_exposure == WRITE)begin
            exposure_reg[0][8] <= 'd0;
            for(i = 0; i < 8; i = i + 1)
                exposure_reg[0][i] <= exposure_reg[0][i + 1];
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        exposure_reg[1][0] <= 44'h0;exposure_reg[1][1] <= 44'h0;exposure_reg[1][2] <= 44'h0;
        exposure_reg[1][3] <= 44'h0;exposure_reg[1][4] <= 44'h0;exposure_reg[1][5] <= 44'h0;
        exposure_reg[1][6] <= 44'h0;exposure_reg[1][7] <= 44'h0;exposure_reg[1][8] <= 44'h0;
    end 
    else if(cs_dram == R_DATA)begin
        if((cnt_rgb == 1 || cnt_rgb == 3) && cnt_64 == 0)begin
            exposure_reg[1][0] <= {exposure_table[0][0], exposure_table[2][0], exposure_table[2][1], exposure_table[2][2]};
            exposure_reg[1][1] <= {exposure_table[1][0], exposure_table[1][1], exposure_table[5][4], exposure_table[5][5]};
            exposure_reg[1][2] <= {exposure_table[4][4], exposure_table[6][4], exposure_table[6][5], exposure_table[6][6]};
            exposure_reg[1][3] <= {exposure_table[3][0], exposure_table[3][1], exposure_table[3][2], exposure_table[3][3]};
            exposure_reg[1][4] <= {exposure_table[4][0], exposure_table[4][1], exposure_table[4][2], exposure_table[4][3]};
            exposure_reg[1][5] <= {exposure_table[5][0], exposure_table[5][1], exposure_table[5][2], exposure_table[5][3]};
            exposure_reg[1][6] <= {exposure_table[6][0], exposure_table[6][1], exposure_table[6][2], exposure_table[6][3]};
            exposure_reg[1][7] <= {exposure_table[7][0], exposure_table[7][1], exposure_table[7][2], exposure_table[7][3]};
            exposure_reg[1][8] <= {exposure_table[7][4], exposure_table[7][5], exposure_table[7][6], exposure_table[7][7]};
        end
        else begin
            case (cnt_rgb)
                'd1,'d3:begin
                    exposure_reg[1][0] <= {add_1_out , add_2_out };
                    exposure_reg[1][1] <= {add_3_out , add_4_out };
                    exposure_reg[1][2] <= {add_5_out , add_6_out };
                    exposure_reg[1][3] <= {add_7_out , add_8_out };
                    exposure_reg[1][4] <= {add_9_out , add_10_out};
                    exposure_reg[1][5] <= {add_11_out, add_12_out};
                    exposure_reg[1][6] <= {add_13_out, add_14_out};
                    exposure_reg[1][7] <= {add_15_out, add_16_out};
                    exposure_reg[1][8] <= {add_17_out, add_18_out}; 
                end
            endcase
        end
    end
    else if(cs_isp == Exposure)begin
        if(cs_exposure == SHIFT && ns_exposure == WRITE)begin
            exposure_reg[1][0] <= {add_1_out , add_2_out };
            exposure_reg[1][1] <= {add_3_out , add_4_out };
            exposure_reg[1][2] <= {add_5_out , add_6_out };
            exposure_reg[1][3] <= {add_7_out , add_8_out };
            exposure_reg[1][4] <= {add_9_out , add_10_out};
            exposure_reg[1][5] <= {add_11_out, add_12_out};
            exposure_reg[1][6] <= {add_13_out, add_14_out};
            exposure_reg[1][7] <= {add_15_out, add_16_out};
            exposure_reg[1][8] <= 44'd0;
        end
        else if(cs_exposure == WRITE)begin
            case (cnt_9_for_write_sram)
                'd0:begin
                    exposure_reg[1][8] <= {add_17_out, add_16_out };//20+26+33, 14+19+25+32
                    exposure_reg[1][0] <= {add_15_out, add_14_out };//18+24+30, 5+8+12+17
                    exposure_reg[1][1] <= {add_13_out, add_12_out };//16+22+29, 2+4+7+11
                end 
                'd1:begin
                    exposure_reg[1][2] <= {add_11_out, add_10_out };//9+13+18+24+30,5+8+12+17+23+30
                    exposure_reg[1][3] <= {add_9_out ,22'd0       };//2+4+7+11+16+22+29, 0
                end
            endcase
            
        end
    end
end
//============================================================
// Debug 
//============================================================
    wire [10:0] sum_0;
    wire [10:0] sum_1[0:1];
    wire [10:0] sum_2[0:2];
    wire [10:0] sum_3[0:3];
    wire [10:0] sum_4[0:4];
    wire [10:0] sum_5[0:5];
    wire [10:0] sum_6[0:6];
    wire [10:0] sum_7[0:7];

    assign sum_0    = exposure_reg[0][0][43:33];

    assign sum_1[1] = exposure_reg[0][1][32:22];
    assign sum_1[0] = exposure_reg[0][1][43:33];

    assign sum_2[2] = exposure_reg[0][0][10:0 ];
    assign sum_2[1] = exposure_reg[0][0][21:11];
    assign sum_2[0] = exposure_reg[0][0][32:22];

    assign sum_3[3] = exposure_reg[0][3][10:0 ];
    assign sum_3[2] = exposure_reg[0][3][21:11];
    assign sum_3[1] = exposure_reg[0][3][32:22];
    assign sum_3[0] = exposure_reg[0][3][43:33];

    assign sum_4[4] = exposure_reg[0][2][43:33];
    assign sum_4[3] = exposure_reg[0][4][10:0 ];
    assign sum_4[2] = exposure_reg[0][4][21:11];
    assign sum_4[1] = exposure_reg[0][4][32:22];
    assign sum_4[0] = exposure_reg[0][4][43:33];

    assign sum_5[5] = exposure_reg[0][1][10:0];
    assign sum_5[4] = exposure_reg[0][1][21:11];
    assign sum_5[3] = exposure_reg[0][5][10:0 ];
    assign sum_5[2] = exposure_reg[0][5][21:11];
    assign sum_5[1] = exposure_reg[0][5][32:22];
    assign sum_5[0] = exposure_reg[0][5][43:33];

    assign sum_6[6] = exposure_reg[0][2][10:0];
    assign sum_6[5] = exposure_reg[0][2][21:11];
    assign sum_6[4] = exposure_reg[0][2][32:22];
    assign sum_6[3] = exposure_reg[0][6][10:0 ];
    assign sum_6[2] = exposure_reg[0][6][21:11];
    assign sum_6[1] = exposure_reg[0][6][32:22];
    assign sum_6[0] = exposure_reg[0][6][43:33];

    assign sum_7[7] = exposure_reg[0][8][10:0 ];
    assign sum_7[6] = exposure_reg[0][8][21:11];
    assign sum_7[5] = exposure_reg[0][8][32:22];
    assign sum_7[4] = exposure_reg[0][8][43:33];
    assign sum_7[3] = exposure_reg[0][7][10:0 ];
    assign sum_7[2] = exposure_reg[0][7][21:11];
    assign sum_7[1] = exposure_reg[0][7][32:22];
    assign sum_7[0] = exposure_reg[0][7][43:33];
    
    wire [10:0] g_sum_0;
    wire [10:0] g_sum_1[0:1];
    wire [10:0] g_sum_2[0:2];
    wire [10:0] g_sum_3[0:3];
    wire [10:0] g_sum_4[0:4];
    wire [10:0] g_sum_5[0:5];
    wire [10:0] g_sum_6[0:6];
    wire [10:0] g_sum_7[0:7];

    assign g_sum_0    = exposure_reg[1][0][43:33];

    assign g_sum_1[1] = exposure_reg[1][1][32:22];
    assign g_sum_1[0] = exposure_reg[1][1][43:33];

    assign g_sum_2[2] = exposure_reg[1][0][10:0 ];
    assign g_sum_2[1] = exposure_reg[1][0][21:11];
    assign g_sum_2[0] = exposure_reg[1][0][32:22];

    assign g_sum_3[3] = exposure_reg[1][3][10:0 ];
    assign g_sum_3[2] = exposure_reg[1][3][21:11];
    assign g_sum_3[1] = exposure_reg[1][3][32:22];
    assign g_sum_3[0] = exposure_reg[1][3][43:33];

    assign g_sum_4[4] = exposure_reg[1][2][43:33];
    assign g_sum_4[3] = exposure_reg[1][4][10:0 ];
    assign g_sum_4[2] = exposure_reg[1][4][21:11];
    assign g_sum_4[1] = exposure_reg[1][4][32:22];
    assign g_sum_4[0] = exposure_reg[1][4][43:33];

    assign g_sum_5[5] = exposure_reg[1][1][10:0];
    assign g_sum_5[4] = exposure_reg[1][1][21:11];
    assign g_sum_5[3] = exposure_reg[1][5][10:0 ];
    assign g_sum_5[2] = exposure_reg[1][5][21:11];
    assign g_sum_5[1] = exposure_reg[1][5][32:22];
    assign g_sum_5[0] = exposure_reg[1][5][43:33];

    assign g_sum_6[6] = exposure_reg[1][2][10:0];
    assign g_sum_6[5] = exposure_reg[1][2][21:11];
    assign g_sum_6[4] = exposure_reg[1][2][32:22];
    assign g_sum_6[3] = exposure_reg[1][6][10:0 ];
    assign g_sum_6[2] = exposure_reg[1][6][21:11];
    assign g_sum_6[1] = exposure_reg[1][6][32:22];
    assign g_sum_6[0] = exposure_reg[1][6][43:33];

    assign g_sum_7[7] = exposure_reg[1][8][10:0 ];
    assign g_sum_7[6] = exposure_reg[1][8][21:11];
    assign g_sum_7[5] = exposure_reg[1][8][32:22];
    assign g_sum_7[4] = exposure_reg[1][8][43:33];
    assign g_sum_7[3] = exposure_reg[1][7][10:0 ];
    assign g_sum_7[2] = exposure_reg[1][7][21:11];
    assign g_sum_7[1] = exposure_reg[1][7][32:22];
    assign g_sum_7[0] = exposure_reg[1][7][43:33];
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
        cnt_64 <= 0;
    else if(rvalid_s_inf_reg) 
        cnt_64 <= cnt_64 + 1;
    else if(cs_isp == IDLE)
        cnt_64 <= 0;
    else if(cs_isp == Focus || cs_isp == Exposure)
        cnt_64 <= cnt_64 + 1;
end
//0:red, 1:green, 2:blue
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
        cnt_rgb <= 0;
    else
        cnt_rgb <= cnt_rgb_ns;
end
always @(*) begin
    cnt_rgb_ns = cnt_rgb;
    if(cs_dram == IDLE)begin
        if(cs_isp == IDLE)
            cnt_rgb_ns = 0;
        else if(cs_isp == Focus)begin
            if(cnt_6_for_read_focus_sram == 5)begin
                case (cnt_rgb)
                    0: cnt_rgb_ns = 1;
                    1: cnt_rgb_ns = 2;
                    2: cnt_rgb_ns = 0; 
                endcase
            end
        end
        else if(cs_isp == Exposure)begin
            if(cnt_img_or_focus == 11)begin
                case (cnt_rgb)
                    0: cnt_rgb_ns = 1;
                    1: cnt_rgb_ns = 2;
                    2: cnt_rgb_ns = 0; 
                endcase
            end
        end
    end
    else if(cnt_64 == 63)begin//for READ_DATA_FROM_DRAM
        // case (cnt_rgb)
        //     0: cnt_rgb_ns = 1;
        //     1: cnt_rgb_ns = 2;
        //     2: cnt_rgb_ns = 0; 
        // endcase
        cnt_rgb_ns = cnt_rgb + 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
        cnt_img_or_focus <= 0;
    else if(cs_dram == R_DATA)begin
        if(cnt_rgb == 2 && cnt_64 == 63) 
            cnt_img_or_focus <= cnt_img_or_focus + 1;
    end
    else if(cs_isp == IDLE)
        cnt_img_or_focus <= 0;
    else if(cs_isp == Focus)begin
        if(start_cal_difference)
            cnt_img_or_focus <= cnt_img_or_focus + 1;
        else 
            cnt_img_or_focus <= 0;
    end
    else if(cs_isp == Exposure)begin
        if(cnt_img_or_focus == 'd11)
            cnt_img_or_focus <= 0;
        else
            cnt_img_or_focus <= cnt_img_or_focus + 1;
    end            
end
//============================================================
// ISP FSM
//============================================================
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
            cs_isp <= IDLE;
        else
            cs_isp <= ns_isp;
    end 
    always @(*) begin
        case (cs_isp)
            IDLE    :begin
                if(finish_w_sram)begin
                    if(in_valid)
                        ns_isp = WAIT_2_CYCLE;
                    else 
                        ns_isp = IDLE;
                end
                else if(start_w_sram)
                    ns_isp = W_SRAM;
                else
                    ns_isp = IDLE;
            end 
            W_SRAM  : begin
                if(w_sram_done)
                    ns_isp = OUT;
                else if(w_sram_from_dram_done)
                    ns_isp = WAIT;
                else
                    ns_isp = W_SRAM;
            end 
            WAIT    : begin
                if(finish_w_sram)
                    ns_isp = WAIT_2_CYCLE;
                else if(start_w_sram)
                    ns_isp = W_SRAM;
                else
                    ns_isp = WAIT;
            end
            WAIT_2_CYCLE : begin
                if(zero_detect)
                    ns_isp = OUT;
                else if(wait_2_cycle_done)begin
                    if(in_mode_reg)
                        ns_isp = Exposure;
                    else
                        ns_isp = Focus;
                end
                else
                    ns_isp = WAIT_2_CYCLE;
            end
            Exposure: ns_isp = exposure_done ? OUT : Exposure;
            Focus   : ns_isp = focus_done ? OUT : Focus;
            OUT     : ns_isp = IDLE;
            default : ns_isp = IDLE; 
        endcase
    end
//============================================================
// ISP FSM Control Signal
//============================================================
    assign start_w_sram = ((cnt_rgb == 0 || cnt_rgb == 1 || cnt_rgb == 2 || cnt_rgb == 3) && cnt_64 == 63);
    assign w_sram_from_dram_done = cnt_9_for_write_sram == 8;
    assign finish_w_sram = cs_dram == IDLE;
    assign wait_2_cycle_done = cnt_2_cycle;
    assign focus_done = cnt_img_or_focus == 15;
    assign exposure_done = cnt_64 == 60;
    assign exposure_for_w_focus_sram = cnt_img_or_focus > 'd5;
    assign exposure_for_w_focus_sram_done = cnt_64 > 'd35;
    always @(*) begin
        zero_detect = 0;
        case (in_pic_no_reg)
            'd0 : zero_detect = zero_detect_reg[0] ;
            'd1 : zero_detect = zero_detect_reg[1] ;
            'd2 : zero_detect = zero_detect_reg[2] ;
            'd3 : zero_detect = zero_detect_reg[3] ;
            'd4 : zero_detect = zero_detect_reg[4] ;
            'd5 : zero_detect = zero_detect_reg[5] ;
            'd6 : zero_detect = zero_detect_reg[6] ;
            'd7 : zero_detect = zero_detect_reg[7] ;
            'd8 : zero_detect = zero_detect_reg[8] ;
            'd9 : zero_detect = zero_detect_reg[9] ;
            'd10: zero_detect = zero_detect_reg[10];
            'd11: zero_detect = zero_detect_reg[11];
            'd12: zero_detect = zero_detect_reg[12];
            'd13: zero_detect = zero_detect_reg[13];
            'd14: zero_detect = zero_detect_reg[14];
            'd15: zero_detect = zero_detect_reg[15];
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt_9_for_write_sram <= 0;
        else if(finish_w_sram)begin
            case (cs_exposure)
                IDLE  : cnt_9_for_write_sram <= 0;
                READ  : cnt_9_for_write_sram <= cnt_9_for_write_sram + 1;
                SHIFT : cnt_9_for_write_sram <= 0;
                WRITE : cnt_9_for_write_sram <= cnt_9_for_write_sram + 1; 
            endcase
        end
        else begin
            if(cnt_9_for_write_sram == 8)
                cnt_9_for_write_sram <= 0;
            else if(cs_isp == W_SRAM)
                cnt_9_for_write_sram <= cnt_9_for_write_sram + 1;
            else if (cnt_9_for_write_sram != 0)
                cnt_9_for_write_sram <= cnt_9_for_write_sram + 1;
        end
        
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cnt_2_cycle <= 0;
        else if(cs_isp == IDLE)
            cnt_2_cycle <= 0;
        else if(cs_isp == WAIT_2_CYCLE || cs_exposure == IDLE)
            cnt_2_cycle <= ~cnt_2_cycle;
        else 
            cnt_2_cycle <= 0;
    end
//============================================================
// Exposure FSM of ISP
//============================================================
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            cs_exposure <= IDLE;
        else
            cs_exposure <= ns_exposure;
    end
    always @(*) begin
        case (cs_exposure)
            IDLE  : ns_exposure = (ns_isp == Exposure && wait_2_cycle_done) ? READ  : IDLE;
            READ  : ns_exposure = (cnt_9_for_write_sram[3]) ? SHIFT : READ  ;
            SHIFT : ns_exposure = WRITE;
            WRITE : ns_exposure = (cnt_9_for_write_sram[3]) ? IDLE  : WRITE ;
        endcase
    end
//============================================================
// SRAM
//============================================================
    SUMA180_432X44X1BM1 sram_exposure(
        .A0(addr_e[0]), .A1(addr_e[1]), .A2(addr_e[2]), .A3(addr_e[3]), .A4(addr_e[4]), .A5(addr_e[5]), .A6(addr_e[6]), .A7(addr_e[7]), .A8(addr_e[8]),
        .DO0(data_out_e[0]), .DO1(data_out_e[1]), .DO2(data_out_e[2]), .DO3(data_out_e[3]), .DO4(data_out_e[4]), .DO5(data_out_e[5]), .DO6(data_out_e[6]), .DO7(data_out_e[7]), .DO8(data_out_e[8]), .DO9(data_out_e[9]), .DO10(data_out_e[10]), .DO11(data_out_e[11]), .DO12(data_out_e[12]), .DO13(data_out_e[13]), .DO14(data_out_e[14]), .DO15(data_out_e[15]), .DO16(data_out_e[16]), .DO17(data_out_e[17]), .DO18(data_out_e[18]), .DO19(data_out_e[19]), .DO20(data_out_e[20]), .DO21(data_out_e[21]), .DO22(data_out_e[22]), .DO23(data_out_e[23]), .DO24(data_out_e[24]), .DO25(data_out_e[25]), .DO26(data_out_e[26]), .DO27(data_out_e[27]), .DO28(data_out_e[28]), .DO29(data_out_e[29]), .DO30(data_out_e[30]), .DO31(data_out_e[31]), .DO32(data_out_e[32]), .DO33(data_out_e[33]), .DO34(data_out_e[34]), .DO35(data_out_e[35]), .DO36(data_out_e[36]), .DO37(data_out_e[37]), .DO38(data_out_e[38]), .DO39(data_out_e[39]), .DO40(data_out_e[40]), .DO41(data_out_e[41]), .DO42(data_out_e[42]), .DO43(data_out_e[43]),
        .DI0(data_in_e[0]), .DI1(data_in_e[1]), .DI2(data_in_e[2]), .DI3(data_in_e[3]), .DI4(data_in_e[4]), .DI5(data_in_e[5]), .DI6(data_in_e[6]), .DI7(data_in_e[7]), .DI8(data_in_e[8]), .DI9(data_in_e[9]), .DI10(data_in_e[10]), .DI11(data_in_e[11]), .DI12(data_in_e[12]), .DI13(data_in_e[13]), .DI14(data_in_e[14]), .DI15(data_in_e[15]), .DI16(data_in_e[16]), .DI17(data_in_e[17]), .DI18(data_in_e[18]), .DI19(data_in_e[19]), .DI20(data_in_e[20]), .DI21(data_in_e[21]), .DI22(data_in_e[22]), .DI23(data_in_e[23]), .DI24(data_in_e[24]), .DI25(data_in_e[25]), .DI26(data_in_e[26]), .DI27(data_in_e[27]), .DI28(data_in_e[28]), .DI29(data_in_e[29]), .DI30(data_in_e[30]), .DI31(data_in_e[31]), .DI32(data_in_e[32]), .DI33(data_in_e[33]), .DI34(data_in_e[34]), .DI35(data_in_e[35]), .DI36(data_in_e[36]), .DI37(data_in_e[37]), .DI38(data_in_e[38]), .DI39(data_in_e[39]), .DI40(data_in_e[40]), .DI41(data_in_e[41]), .DI42(data_in_e[42]), .DI43(data_in_e[43]),
        .CK(clk), .WEB(WEB_e), .CS(1'b1), .OE(1'b1)
    );
    SUMA180_288X48X1BM1 sram_autofocus(
        .A0(addr_a[0]), .A1(addr_a[1]), .A2(addr_a[2]), .A3(addr_a[3]), .A4(addr_a[4]), .A5(addr_a[5]), .A6(addr_a[6]), .A7(addr_a[7]), .A8(addr_a[8]),
        .DO0(data_out_a[0]), .DO1(data_out_a[1]), .DO2(data_out_a[2]), .DO3(data_out_a[3]), .DO4(data_out_a[4]), .DO5(data_out_a[5]), .DO6(data_out_a[6]), .DO7(data_out_a[7]), .DO8(data_out_a[8]), .DO9(data_out_a[9]), .DO10(data_out_a[10]), .DO11(data_out_a[11]), .DO12(data_out_a[12]), .DO13(data_out_a[13]), .DO14(data_out_a[14]), .DO15(data_out_a[15]), .DO16(data_out_a[16]), .DO17(data_out_a[17]), .DO18(data_out_a[18]), .DO19(data_out_a[19]), .DO20(data_out_a[20]), .DO21(data_out_a[21]), .DO22(data_out_a[22]), .DO23(data_out_a[23]), .DO24(data_out_a[24]), .DO25(data_out_a[25]), .DO26(data_out_a[26]), .DO27(data_out_a[27]), .DO28(data_out_a[28]), .DO29(data_out_a[29]), .DO30(data_out_a[30]), .DO31(data_out_a[31]), .DO32(data_out_a[32]), .DO33(data_out_a[33]), .DO34(data_out_a[34]), .DO35(data_out_a[35]), .DO36(data_out_a[36]), .DO37(data_out_a[37]), .DO38(data_out_a[38]), .DO39(data_out_a[39]), .DO40(data_out_a[40]), .DO41(data_out_a[41]), .DO42(data_out_a[42]), .DO43(data_out_a[43]), .DO44(data_out_a[44]), .DO45(data_out_a[45]), .DO46(data_out_a[46]), .DO47(data_out_a[47]),
        .DI0(data_in_a[0]), .DI1(data_in_a[1]), .DI2(data_in_a[2]), .DI3(data_in_a[3]), .DI4(data_in_a[4]), .DI5(data_in_a[5]), .DI6(data_in_a[6]), .DI7(data_in_a[7]), .DI8(data_in_a[8]), .DI9(data_in_a[9]), .DI10(data_in_a[10]), .DI11(data_in_a[11]), .DI12(data_in_a[12]), .DI13(data_in_a[13]), .DI14(data_in_a[14]), .DI15(data_in_a[15]), .DI16(data_in_a[16]), .DI17(data_in_a[17]), .DI18(data_in_a[18]), .DI19(data_in_a[19]), .DI20(data_in_a[20]), .DI21(data_in_a[21]), .DI22(data_in_a[22]), .DI23(data_in_a[23]), .DI24(data_in_a[24]), .DI25(data_in_a[25]), .DI26(data_in_a[26]), .DI27(data_in_a[27]), .DI28(data_in_a[28]), .DI29(data_in_a[29]), .DI30(data_in_a[30]), .DI31(data_in_a[31]), .DI32(data_in_a[32]), .DI33(data_in_a[33]), .DI34(data_in_a[34]), .DI35(data_in_a[35]), .DI36(data_in_a[36]), .DI37(data_in_a[37]), .DI38(data_in_a[38]), .DI39(data_in_a[39]), .DI40(data_in_a[40]), .DI41(data_in_a[41]), .DI42(data_in_a[42]), .DI43(data_in_a[43]), .DI44(data_in_a[44]), .DI45(data_in_a[45]), .DI46(data_in_a[46]), .DI47(data_in_a[47]),
        .CK(clk), .WEB(WEB_a), .CS(1'b1), .OE(1'b1)
    );
    always @(*) begin
        if(sram_autofocus_addr_ctrl)
            data_in_a = data_af;
        else if(cs_isp == Exposure)begin
            if(cnt_rgb == 0)
                data_in_a = Autofocus_reg[0];
            else
                data_in_a = Autofocus_reg[2];
        end
        else
            data_in_a = 0;
    end
    always @(*) begin
        data_in_e = 0;
        if(cs_isp == W_SRAM)begin
            case (cnt_rgb)
                1,3: data_in_e = exposure_reg[0][cnt_9_for_write_sram];
                2,0: data_in_e = exposure_reg[1][cnt_9_for_write_sram];
                // 0: data_in_e = exposure_reg[0][cnt_9_for_write_sram];
                default: data_in_e = 0;
            endcase
        end
        else if(cs_isp == Exposure)begin
            data_in_e = exposure_reg[0][0];
        end
        
    end
    always @(*) begin
        WEB_e = (cs_isp == W_SRAM || cs_exposure == WRITE) ? 1'b0 : 1'b1;
        WEB_a = ((finish_w_sram && cs_isp == W_SRAM && ns_isp != WAIT) || (sram_autofocus_addr_ctrl) || (cs_isp == Exposure && exposure_for_w_focus_sram && !exposure_for_w_focus_sram_done)) ? 1'b0 : 1'b1;
    end
//============================================================
// Read mode
//============================================================
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            in_mode_reg       <= 0;
            in_pic_no_reg     <= 0; 
            in_ratio_mode_reg <= 0;
        end
        else if(in_valid)begin
            in_mode_reg       <= in_mode;
            in_pic_no_reg     <= in_pic_no;
            in_ratio_mode_reg <= in_ratio_mode;
        end
    end
//============================================================
// READ/Write SRAM Exposure
//============================================================
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            addr_e <= 0;
        else begin  
            if(finish_w_sram)begin
                if(cs_isp == IDLE && ns_isp == W_SRAM)begin
                    case (in_pic_no_reg)
                        'd0 : addr_e <= 'd0;
                        'd1 : addr_e <= 'd27;
                        'd2 : addr_e <= 'd54;
                        'd3 : addr_e <= 'd81;
                        'd4 : addr_e <= 'd108;
                        'd5 : addr_e <= 'd135;
                        'd6 : addr_e <= 'd162;
                        'd7 : addr_e <= 'd189;
                        'd8 : addr_e <= 'd216;
                        'd9 : addr_e <= 'd243;
                        'd10: addr_e <= 'd270;
                        'd11: addr_e <= 'd297;
                        'd12: addr_e <= 'd324;
                        'd13: addr_e <= 'd351;
                        'd14: addr_e <= 'd378;
                        'd15: addr_e <= 'd405; 
                    endcase
                end
                else if(cs_isp == WAIT_2_CYCLE || cs_isp == Exposure)begin
                    // if(addr_e == 'd431)
                    //     addr_e <= addr_e;
                    // else begin
                        case (cs_exposure)
                            IDLE   : begin
                                if(addr_e == 'd431)
                                    addr_e <= addr_e;
                                else
                                    addr_e <= addr_e + 1 ;
                            end
                            READ   : begin
                                if(addr_e == 'd431)
                                    addr_e <= addr_e;
                                else
                                    addr_e <= addr_e + 1 ;
                            end
                            SHIFT  : begin
                                if(addr_e == 'd431)
                                    addr_e <= addr_e - 8;
                                else
                                    addr_e <= addr_e - 11 ;
                            end
                            WRITE  : begin
                                if(addr_e == 'd431)
                                    addr_e <= addr_e;
                                else
                                    addr_e <= addr_e + 1 ;
                            end
                            default: addr_e <= addr_e;
                        endcase
                    // end
                end
                else if(ns_isp == WAIT_2_CYCLE)begin
                    if(~pattern_0_check)begin
                        case (in_pic_no_reg)
                            'd0 : addr_e <= 'd0;
                            'd1 : addr_e <= 'd27;
                            'd2 : addr_e <= 'd54;
                            'd3 : addr_e <= 'd81;
                            'd4 : addr_e <= 'd108;
                            'd5 : addr_e <= 'd135;
                            'd6 : addr_e <= 'd162;
                            'd7 : addr_e <= 'd189;
                            'd8 : addr_e <= 'd216;
                            'd9 : addr_e <= 'd243;
                            'd10: addr_e <= 'd270;
                            'd11: addr_e <= 'd297;
                            'd12: addr_e <= 'd324;
                            'd13: addr_e <= 'd351;
                            'd14: addr_e <= 'd378;
                            'd15: addr_e <= 'd405; 
                        endcase
                    end
                    else begin
                        case (in_pic_no)
                            'd0 : addr_e <= 'd0;
                            'd1 : addr_e <= 'd27;
                            'd2 : addr_e <= 'd54;
                            'd3 : addr_e <= 'd81;
                            'd4 : addr_e <= 'd108;
                            'd5 : addr_e <= 'd135;
                            'd6 : addr_e <= 'd162;
                            'd7 : addr_e <= 'd189;
                            'd8 : addr_e <= 'd216;
                            'd9 : addr_e <= 'd243;
                            'd10: addr_e <= 'd270;
                            'd11: addr_e <= 'd297;
                            'd12: addr_e <= 'd324;
                            'd13: addr_e <= 'd351;
                            'd14: addr_e <= 'd378;
                            'd15: addr_e <= 'd405; 
                        endcase
                    end
                end
                else if(cs_isp == W_SRAM)
                    addr_e <= addr_e + 1;
            end
            else begin
                if(cs_isp == W_SRAM)begin
                    if(addr_e == 'd431)
                        addr_e <= addr_e;
                    else
                        addr_e <= addr_e + 1;
                end 
                else
                    addr_e <= addr_e;
            end
        end 
    end
    always @(posedge clk ) begin
        data_out_e_reg <= data_out_e;
    end
//============================================================
// READ/Write SRAM Autofocus
//============================================================
    assign data_af = {data_af_reg[2], data_af_reg[1], data_af_reg[0], rdata_s_inf_reg[7:0], rdata_s_inf_reg[15:8], rdata_s_inf_reg[23:16]};
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            for(i = 0; i < 3; i = i + 1) 
                data_af_reg[i] <= 0;
        end
        else if(cnt_64 > 'd25)begin
            data_af_reg[0] <= rdata_s_inf_reg[127:120];
            data_af_reg[1] <= rdata_s_inf_reg[119:112];
            data_af_reg[2] <= rdata_s_inf_reg[111:104];
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            sram_autofocus_addr_ctrl <= 0;
        else if(cs_dram == IDLE)
            sram_autofocus_addr_ctrl <= 0;
        else if(cs_dram == R_DATA)
            if( cnt_64 > 'd25 && cnt_64 < 'd38)
                sram_autofocus_addr_ctrl <= ~sram_autofocus_addr_ctrl;
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            addr_a <= 0;   
        else if(cs_dram == R_DATA)begin
            if(addr_a == 'd287)
                addr_a <= addr_a;
            else if(cnt_64 > 'd25 && cnt_64 < 'd38)begin
                if(sram_autofocus_addr_ctrl)
                    addr_a <= addr_a + 1;
                else
                    addr_a <= addr_a;
            end
        end
        else if(cs_isp == WAIT_2_CYCLE || cs_isp == Focus)begin
            if(addr_a == 'd287)
                addr_a <= addr_a;
            else
                addr_a <= addr_a + 1;
        end
        else if(cs_isp == Exposure)begin
            if(cnt_img_or_focus == 5)begin
                case (in_pic_no_reg)
                    'd0 : addr_a <= 'd0   + (6 * cnt_rgb);//modify
                    'd1 : addr_a <= 'd18  + (6 * cnt_rgb);//modify
                    'd2 : addr_a <= 'd36  + (6 * cnt_rgb);//modify
                    'd3 : addr_a <= 'd54  + (6 * cnt_rgb);//modify
                    'd4 : addr_a <= 'd72  + (6 * cnt_rgb);//modify
                    'd5 : addr_a <= 'd90  + (6 * cnt_rgb);//modify
                    'd6 : addr_a <= 'd108 + (6 * cnt_rgb);//modify
                    'd7 : addr_a <= 'd126 + (6 * cnt_rgb);//modify
                    'd8 : addr_a <= 'd144 + (6 * cnt_rgb);//modify
                    'd9 : addr_a <= 'd162 + (6 * cnt_rgb);//modify
                    'd10: addr_a <= 'd180 + (6 * cnt_rgb);//modify
                    'd11: addr_a <= 'd198 + (6 * cnt_rgb);//modify
                    'd12: addr_a <= 'd216 + (6 * cnt_rgb);//modify
                    'd13: addr_a <= 'd234 + (6 * cnt_rgb);//modify
                    'd14: addr_a <= 'd252 + (6 * cnt_rgb);//modify
                    'd15: addr_a <= 'd270 + (6 * cnt_rgb);//modify
                endcase
            end
            else if(addr_a == 'd287)
                addr_a <= addr_a;
            else
                addr_a <= addr_a + 1;
        end
        else if(ns_isp == WAIT_2_CYCLE)begin
            if(~pattern_0_check)begin
                case (in_pic_no_reg)
                    'd0 : addr_a <= 'd0;
                    'd1 : addr_a <= 'd18;
                    'd2 : addr_a <= 'd36;
                    'd3 : addr_a <= 'd54;
                    'd4 : addr_a <= 'd72;
                    'd5 : addr_a <= 'd90;
                    'd6 : addr_a <= 'd108;
                    'd7 : addr_a <= 'd126;
                    'd8 : addr_a <= 'd144;
                    'd9 : addr_a <= 'd162;
                    'd10: addr_a <= 'd180;
                    'd11: addr_a <= 'd198;
                    'd12: addr_a <= 'd216;
                    'd13: addr_a <= 'd234;
                    'd14: addr_a <= 'd252;
                    'd15: addr_a <= 'd270;
                endcase
            end
            else begin
                case (in_pic_no)
                    'd0 : addr_a <= 'd0;
                    'd1 : addr_a <= 'd18;
                    'd2 : addr_a <= 'd36;
                    'd3 : addr_a <= 'd54;
                    'd4 : addr_a <= 'd72;
                    'd5 : addr_a <= 'd90;
                    'd6 : addr_a <= 'd108;
                    'd7 : addr_a <= 'd126;
                    'd8 : addr_a <= 'd144;
                    'd9 : addr_a <= 'd162;
                    'd10: addr_a <= 'd180;
                    'd11: addr_a <= 'd198;
                    'd12: addr_a <= 'd216;
                    'd13: addr_a <= 'd234;
                    'd14: addr_a <= 'd252;
                    'd15: addr_a <= 'd270;
                endcase
            end
        end
    end
    always @(posedge clk ) begin
        data_out_a_reg <= data_out_a;
    end
//============================================================
// Autofocus Reg
//============================================================
    assign focus_grayscale_done = cnt_64 > 'd17;
    assign start_cal_difference = cnt_64 > 'd15;
    //8bit adder * 6
    reg  [7:0] add_af_1_in1, add_af_2_in1, add_af_3_in1, add_af_4_in1, add_af_5_in1, add_af_6_in1; 
    reg  [7:0] add_af_1_in2, add_af_2_in2, add_af_3_in2, add_af_4_in2, add_af_5_in2, add_af_6_in2; 
    wire [7:0] add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out;
    //adder
    assign add_af_1_out = add_af_1_in1 + add_af_1_in2;
    assign add_af_2_out = add_af_2_in1 + add_af_2_in2;
    assign add_af_3_out = add_af_3_in1 + add_af_3_in2;
    assign add_af_4_out = add_af_4_in1 + add_af_4_in2;
    assign add_af_5_out = add_af_5_in1 + add_af_5_in2;
    assign add_af_6_out = add_af_6_in1 + add_af_6_in2;
    //input control
    always @(*) begin
        add_af_1_in1 = 0;add_af_2_in1 = 0;add_af_3_in1 = 0;add_af_4_in1 = 0;add_af_5_in1 = 0;add_af_6_in1 = 0;
        case (cs_isp)
            Focus:begin
                case (cnt_6_for_read_focus_sram)
                    'd0:begin
                        add_af_1_in1 = Autofocus_reg[0][47:40];
                        add_af_2_in1 = Autofocus_reg[0][39:32];
                        add_af_3_in1 = Autofocus_reg[0][31:24];
                        add_af_4_in1 = Autofocus_reg[0][23:16];
                        add_af_5_in1 = Autofocus_reg[0][15:8];
                        add_af_6_in1 = Autofocus_reg[0][7:0];
                    end 
                    'd1:begin
                        add_af_1_in1 = Autofocus_reg[1][47:40];
                        add_af_2_in1 = Autofocus_reg[1][39:32];
                        add_af_3_in1 = Autofocus_reg[1][31:24];
                        add_af_4_in1 = Autofocus_reg[1][23:16];
                        add_af_5_in1 = Autofocus_reg[1][15:8];
                        add_af_6_in1 = Autofocus_reg[1][7:0];
                    end
                    'd2:begin
                        add_af_1_in1 = Autofocus_reg[2][47:40];
                        add_af_2_in1 = Autofocus_reg[2][39:32];
                        add_af_3_in1 = Autofocus_reg[2][31:24];
                        add_af_4_in1 = Autofocus_reg[2][23:16];
                        add_af_5_in1 = Autofocus_reg[2][15:8];
                        add_af_6_in1 = Autofocus_reg[2][7:0];
                    end
                    'd3:begin
                        add_af_1_in1 = Autofocus_reg[3][47:40];
                        add_af_2_in1 = Autofocus_reg[3][39:32];
                        add_af_3_in1 = Autofocus_reg[3][31:24];
                        add_af_4_in1 = Autofocus_reg[3][23:16];
                        add_af_5_in1 = Autofocus_reg[3][15:8];
                        add_af_6_in1 = Autofocus_reg[3][7:0];
                    end
                    'd4:begin
                        add_af_1_in1 = Autofocus_reg[4][47:40];
                        add_af_2_in1 = Autofocus_reg[4][39:32];
                        add_af_3_in1 = Autofocus_reg[4][31:24];
                        add_af_4_in1 = Autofocus_reg[4][23:16];
                        add_af_5_in1 = Autofocus_reg[4][15:8];
                        add_af_6_in1 = Autofocus_reg[4][7:0];
                    end
                    'd5:begin
                        add_af_1_in1 = Autofocus_reg[5][47:40];
                        add_af_2_in1 = Autofocus_reg[5][39:32];
                        add_af_3_in1 = Autofocus_reg[5][31:24];
                        add_af_4_in1 = Autofocus_reg[5][23:16];
                        add_af_5_in1 = Autofocus_reg[5][15:8];
                        add_af_6_in1 = Autofocus_reg[5][7:0];
                    end
                endcase
            end  
        endcase
    end    
    always @(*) begin
        add_af_1_in2 = 0;add_af_2_in2 = 0;add_af_3_in2 = 0;add_af_4_in2 = 0;add_af_5_in2 = 0;add_af_6_in2 = 0;
        case (cs_isp)
            Focus:begin
                case (cnt_rgb)
                    0:begin
                        add_af_1_in2 = data_out_a_reg[47:40] >> 2;
                        add_af_2_in2 = data_out_a_reg[39:32] >> 2;
                        add_af_3_in2 = data_out_a_reg[31:24] >> 2;
                        add_af_4_in2 = data_out_a_reg[23:16] >> 2;
                        add_af_5_in2 = data_out_a_reg[15:8]  >> 2;
                        add_af_6_in2 = data_out_a_reg[7:0]   >> 2;
                    end 
                    1:begin
                        add_af_1_in2 = data_out_a_reg[47:40] >> 1;
                        add_af_2_in2 = data_out_a_reg[39:32] >> 1;
                        add_af_3_in2 = data_out_a_reg[31:24] >> 1;
                        add_af_4_in2 = data_out_a_reg[23:16] >> 1;
                        add_af_5_in2 = data_out_a_reg[15:8]  >> 1;
                        add_af_6_in2 = data_out_a_reg[7:0]   >> 1;
                    end  
                    2:begin
                        add_af_1_in2 = data_out_a_reg[47:40] >> 2;
                        add_af_2_in2 = data_out_a_reg[39:32] >> 2;
                        add_af_3_in2 = data_out_a_reg[31:24] >> 2;
                        add_af_4_in2 = data_out_a_reg[23:16] >> 2;
                        add_af_5_in2 = data_out_a_reg[15:8]  >> 2;
                        add_af_6_in2 = data_out_a_reg[7:0]   >> 2;
                    end 
                endcase
            end 
        endcase
    end
    reg [7:0] af_sft[0:5];
    always @(*) begin
        af_sft[0] = 0;
        af_sft[1] = 0;
        af_sft[2] = 0;
        af_sft[3] = 0;
        af_sft[4] = 0;
        af_sft[5] = 0;
        case (in_ratio_mode_reg)
            'd0:begin
                af_sft[0] = data_out_a_reg[47:40] >> 2;
                af_sft[1] = data_out_a_reg[39:32] >> 2;
                af_sft[2] = data_out_a_reg[31:24] >> 2;
                af_sft[3] = data_out_a_reg[23:16] >> 2;
                af_sft[4] = data_out_a_reg[15:8]  >> 2;
                af_sft[5] = data_out_a_reg[7:0]   >> 2;
            end
            'd1:begin
                af_sft[0] = data_out_a_reg[47:40] >> 1;
                af_sft[1] = data_out_a_reg[39:32] >> 1;
                af_sft[2] = data_out_a_reg[31:24] >> 1;
                af_sft[3] = data_out_a_reg[23:16] >> 1;
                af_sft[4] = data_out_a_reg[15:8]  >> 1;
                af_sft[5] = data_out_a_reg[7:0]   >> 1;
            end
            'd2:begin
                af_sft[0] = data_out_a_reg[47:40];
                af_sft[1] = data_out_a_reg[39:32];
                af_sft[2] = data_out_a_reg[31:24];
                af_sft[3] = data_out_a_reg[23:16];
                af_sft[4] = data_out_a_reg[15:8];
                af_sft[5] = data_out_a_reg[7:0];
            end
            'd3:begin
                af_sft[0] = data_out_a_reg[47] ? 'd255 : data_out_a_reg[47:40] << 1;
                af_sft[1] = data_out_a_reg[39] ? 'd255 : data_out_a_reg[39:32] << 1;
                af_sft[2] = data_out_a_reg[31] ? 'd255 : data_out_a_reg[31:24] << 1;
                af_sft[3] = data_out_a_reg[23] ? 'd255 : data_out_a_reg[23:16] << 1;
                af_sft[4] = data_out_a_reg[15] ? 'd255 : data_out_a_reg[15:8]  << 1;
                af_sft[5] = data_out_a_reg[7]  ? 'd255 : data_out_a_reg[7:0]   << 1;
            end
        endcase
    end 
    always @(posedge clk) begin
        if(cs_isp == IDLE)begin 
            Autofocus_reg[0] <= 0;
            Autofocus_reg[1] <= 0;
            Autofocus_reg[2] <= 0;
            Autofocus_reg[3] <= 0;
            Autofocus_reg[4] <= 0;
            Autofocus_reg[5] <= 0;
        end
        else if(cs_isp == Focus)begin
            if(focus_grayscale_done)begin
                Autofocus_reg[0] <= Autofocus_reg[0];
                Autofocus_reg[1] <= Autofocus_reg[1];
                Autofocus_reg[2] <= Autofocus_reg[2];
                Autofocus_reg[3] <= Autofocus_reg[3];
                Autofocus_reg[4] <= Autofocus_reg[4];
                Autofocus_reg[5] <= Autofocus_reg[5];
            end
            else begin
                case (cnt_6_for_read_focus_sram)
                    'd0:Autofocus_reg[0] <= {add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out};
                    'd1:Autofocus_reg[1] <= {add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out};
                    'd2:Autofocus_reg[2] <= {add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out};
                    'd3:Autofocus_reg[3] <= {add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out};
                    'd4:Autofocus_reg[4] <= {add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out};
                    'd5:Autofocus_reg[5] <= {add_af_1_out, add_af_2_out, add_af_3_out, add_af_4_out, add_af_5_out, add_af_6_out};
                endcase
                
            end
        end   
        else if(cs_isp == Exposure)begin
            Autofocus_reg[0] <= Autofocus_reg[1];
            Autofocus_reg[1] <= Autofocus_reg[2];
            Autofocus_reg[2] <= Autofocus_reg[3];
            Autofocus_reg[3] <= Autofocus_reg[4];
            Autofocus_reg[4] <= Autofocus_reg[5];
            Autofocus_reg[5] <= {af_sft[0], af_sft[1], af_sft[2], af_sft[3], af_sft[4], af_sft[5]};
        end     
    end
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            cnt_6_for_read_focus_sram <= 0;
        else if(cnt_6_for_read_focus_sram == 5)
            cnt_6_for_read_focus_sram <= 0;
        else if(cs_isp == Focus)
            cnt_6_for_read_focus_sram <= cnt_6_for_read_focus_sram + 1;
        else if(cs_isp == Exposure)begin
            if(cs_exposure == SHIFT)
                cnt_6_for_read_focus_sram <= cnt_6_for_read_focus_sram + 1;
        end
            
        else if(cs_isp == IDLE)
            cnt_6_for_read_focus_sram <= 0;
    end
//============================================================
// Difference Reg
//============================================================
    reg  [7:0] cmp_in_1_1, cmp_in_1_2, cmp_in_2_1, cmp_in_2_2, cmp_in_3_1, cmp_in_3_2, cmp_in_4_1, cmp_in_4_2;
    wire [7:0] cmp_out_1_1, cmp_out_1_2;
    wire [7:0] cmp_out_2_1, cmp_out_2_2;
    wire [7:0] cmp_out_3_1, cmp_out_3_2;
    wire [7:0] cmp_out_4_1, cmp_out_4_2;

    wire [7:0] sub_1_out, sub_2_out, sub_3_out, sub_4_out;
    //comparator
    assign cmp_out_1_1 = (cmp_in_1_1 > cmp_in_1_2) ? cmp_in_1_1 : cmp_in_1_2;
    assign cmp_out_1_2 = (cmp_in_1_1 > cmp_in_1_2) ? cmp_in_1_2 : cmp_in_1_1;
    assign cmp_out_2_1 = (cmp_in_2_1 > cmp_in_2_2) ? cmp_in_2_1 : cmp_in_2_2;
    assign cmp_out_2_2 = (cmp_in_2_1 > cmp_in_2_2) ? cmp_in_2_2 : cmp_in_2_1;
    assign cmp_out_3_1 = (cmp_in_3_1 > cmp_in_3_2) ? cmp_in_3_1 : cmp_in_3_2;
    assign cmp_out_3_2 = (cmp_in_3_1 > cmp_in_3_2) ? cmp_in_3_2 : cmp_in_3_1;
    assign cmp_out_4_1 = (cmp_in_4_1 > cmp_in_4_2) ? cmp_in_4_1 : cmp_in_4_2;
    assign cmp_out_4_2 = (cmp_in_4_1 > cmp_in_4_2) ? cmp_in_4_2 : cmp_in_4_1;
    //subtractor
    assign sub_1_out = cmp_out_1_1 - cmp_out_1_2;
    assign sub_2_out = cmp_out_2_1 - cmp_out_2_2;
    assign sub_3_out = cmp_out_3_1 - cmp_out_3_2;
    assign sub_4_out = cmp_out_4_1 - cmp_out_4_2;
    always @(*) begin
        cmp_in_1_1 = 0;
        cmp_in_1_2 = 0;
        cmp_in_2_1 = 0;
        cmp_in_2_2 = 0;
        cmp_in_3_1 = 0;
        cmp_in_3_2 = 0;
        cmp_in_4_1 = 0;
        cmp_in_4_2 = 0;
        case (cnt_img_or_focus)
            'd0:begin
                cmp_in_1_1 = Autofocus_reg[2][31:24];
                cmp_in_1_2 = Autofocus_reg[2][23:16];
                cmp_in_2_1 = Autofocus_reg[3][31:24];
                cmp_in_2_2 = Autofocus_reg[3][23:16];
                cmp_in_3_1 = Autofocus_reg[2][31:24];
                cmp_in_3_2 = Autofocus_reg[3][31:24];
                cmp_in_4_1 = Autofocus_reg[2][23:16];
                cmp_in_4_2 = Autofocus_reg[3][23:16];
            end 
            'd1:begin
                cmp_in_1_1 = Autofocus_reg[1][39:32];
                cmp_in_1_2 = Autofocus_reg[2][39:32];
                cmp_in_2_1 = Autofocus_reg[1][31:24];
                cmp_in_2_2 = Autofocus_reg[2][31:24];
                cmp_in_3_1 = Autofocus_reg[1][23:16];
                cmp_in_3_2 = Autofocus_reg[2][23:16];
                cmp_in_4_1 = Autofocus_reg[1][15:8];
                cmp_in_4_2 = Autofocus_reg[2][15:8];
            end
            'd2:begin
                cmp_in_1_1 = Autofocus_reg[3][39:32];
                cmp_in_1_2 = Autofocus_reg[4][39:32];
                cmp_in_2_1 = Autofocus_reg[3][31:24];
                cmp_in_2_2 = Autofocus_reg[4][31:24];
                cmp_in_3_1 = Autofocus_reg[3][23:16];
                cmp_in_3_2 = Autofocus_reg[4][23:16];
                cmp_in_4_1 = Autofocus_reg[3][15:8];
                cmp_in_4_2 = Autofocus_reg[4][15:8];
            end
            'd3:begin
                cmp_in_1_1 = Autofocus_reg[1][39:32];
                cmp_in_1_2 = Autofocus_reg[1][31:24];
                cmp_in_2_1 = Autofocus_reg[2][39:32];
                cmp_in_2_2 = Autofocus_reg[2][31:24];
                cmp_in_3_1 = Autofocus_reg[3][39:32];
                cmp_in_3_2 = Autofocus_reg[3][31:24];
                cmp_in_4_1 = Autofocus_reg[4][39:32];
                cmp_in_4_2 = Autofocus_reg[4][31:24];
            end
            'd4:begin
                cmp_in_1_1 = Autofocus_reg[1][23:16];
                cmp_in_1_2 = Autofocus_reg[1][15:8];
                cmp_in_2_1 = Autofocus_reg[2][23:16];
                cmp_in_2_2 = Autofocus_reg[2][15:8];
                cmp_in_3_1 = Autofocus_reg[3][23:16];
                cmp_in_3_2 = Autofocus_reg[3][15:8] ;
                cmp_in_4_1 = Autofocus_reg[4][23:16];
                cmp_in_4_2 = Autofocus_reg[4][15:8] ;
            end
            'd5:begin
                cmp_in_1_1 = Autofocus_reg[1][31:24];
                cmp_in_1_2 = Autofocus_reg[1][23:16];
                cmp_in_2_1 = Autofocus_reg[4][31:24];
                cmp_in_2_2 = Autofocus_reg[4][23:16];
                cmp_in_3_1 = Autofocus_reg[2][39:32];
                cmp_in_3_2 = Autofocus_reg[3][39:32];
                cmp_in_4_1 = Autofocus_reg[2][15:8];
                cmp_in_4_2 = Autofocus_reg[3][15:8];
            end
            'd6:begin
                cmp_in_1_1 = Autofocus_reg[0][39:32];
                cmp_in_1_2 = Autofocus_reg[1][39:32];
                cmp_in_2_1 = Autofocus_reg[0][31:24];
                cmp_in_2_2 = Autofocus_reg[1][31:24];
                cmp_in_3_1 = Autofocus_reg[0][23:16];
                cmp_in_3_2 = Autofocus_reg[1][23:16];
                cmp_in_4_1 = Autofocus_reg[0][15:8];
                cmp_in_4_2 = Autofocus_reg[1][15:8];
            end
            'd7:begin
                cmp_in_1_1 = Autofocus_reg[4][39:32];
                cmp_in_1_2 = Autofocus_reg[5][39:32];
                cmp_in_2_1 = Autofocus_reg[4][31:24];
                cmp_in_2_2 = Autofocus_reg[5][31:24];
                cmp_in_3_1 = Autofocus_reg[4][23:16];
                cmp_in_3_2 = Autofocus_reg[5][23:16];
                cmp_in_4_1 = Autofocus_reg[4][15:8];
                cmp_in_4_2 = Autofocus_reg[5][15:8];
            end
            'd8:begin
                cmp_in_1_1 = Autofocus_reg[1][47:40];
                cmp_in_1_2 = Autofocus_reg[1][39:32];
                cmp_in_2_1 = Autofocus_reg[2][47:40];
                cmp_in_2_2 = Autofocus_reg[2][39:32];
                cmp_in_3_1 = Autofocus_reg[3][47:40];
                cmp_in_3_2 = Autofocus_reg[3][39:32];
                cmp_in_4_1 = Autofocus_reg[4][47:40];
                cmp_in_4_2 = Autofocus_reg[4][39:32];
            end
            'd9:begin
                cmp_in_1_1 = Autofocus_reg[1][15:8];
                cmp_in_1_2 = Autofocus_reg[1][7:0];
                cmp_in_2_1 = Autofocus_reg[2][15:8];
                cmp_in_2_2 = Autofocus_reg[2][7:0];
                cmp_in_3_1 = Autofocus_reg[3][15:8];
                cmp_in_3_2 = Autofocus_reg[3][7:0] ;
                cmp_in_4_1 = Autofocus_reg[4][15:8];
                cmp_in_4_2 = Autofocus_reg[4][7:0] ;
            end
            'd10:begin
                cmp_in_1_1 = Autofocus_reg[0][47:40];
                cmp_in_1_2 = Autofocus_reg[1][47:40];
                cmp_in_2_1 = Autofocus_reg[1][47:40];
                cmp_in_2_2 = Autofocus_reg[2][47:40];
                cmp_in_3_1 = Autofocus_reg[3][47:40];
                cmp_in_3_2 = Autofocus_reg[4][47:40];
                cmp_in_4_1 = Autofocus_reg[4][47:40];
                cmp_in_4_2 = Autofocus_reg[5][47:40];
            end
            'd11:begin
                cmp_in_1_1 = Autofocus_reg[0][7:0];
                cmp_in_1_2 = Autofocus_reg[1][7:0];
                cmp_in_2_1 = Autofocus_reg[1][7:0];
                cmp_in_2_2 = Autofocus_reg[2][7:0];
                cmp_in_3_1 = Autofocus_reg[3][7:0];
                cmp_in_3_2 = Autofocus_reg[4][7:0];
                cmp_in_4_1 = Autofocus_reg[4][7:0];
                cmp_in_4_2 = Autofocus_reg[5][7:0];
            end
            'd12:begin
                cmp_in_1_1 = Autofocus_reg[0][47:40];
                cmp_in_1_2 = Autofocus_reg[0][39:32];
                cmp_in_2_1 = Autofocus_reg[0][39:32];
                cmp_in_2_2 = Autofocus_reg[0][31:24];
                cmp_in_3_1 = Autofocus_reg[5][47:40];
                cmp_in_3_2 = Autofocus_reg[5][39:32];
                cmp_in_4_1 = Autofocus_reg[5][39:32];
                cmp_in_4_2 = Autofocus_reg[5][31:24];
            end
            'd13:begin
                cmp_in_1_1 = Autofocus_reg[0][23:16];
                cmp_in_1_2 = Autofocus_reg[0][15:8] ;
                cmp_in_2_1 = Autofocus_reg[0][15:8];
                cmp_in_2_2 = Autofocus_reg[0][7:0] ;
                cmp_in_3_1 = Autofocus_reg[5][23:16];
                cmp_in_3_2 = Autofocus_reg[5][15:8];
                cmp_in_4_1 = Autofocus_reg[5][15:8];
                cmp_in_4_2 = Autofocus_reg[5][7:0];
            end
            'd14:begin
                cmp_in_1_1 = Autofocus_reg[0][31:24];
                cmp_in_1_2 = Autofocus_reg[0][23:16];
                cmp_in_2_1 = Autofocus_reg[5][31:24];
                cmp_in_2_2 = Autofocus_reg[5][23:16];
                cmp_in_3_1 = Autofocus_reg[2][47:40];
                cmp_in_3_2 = Autofocus_reg[3][47:40];
                cmp_in_4_1 = Autofocus_reg[2][7:0];
                cmp_in_4_2 = Autofocus_reg[3][7:0];
            end
        endcase
    end

    wire [8:0] add_diff_1_out,add_diff_2_out;
    wire [9:0] add_diff_3_out;
    wire [13:0] add_diff_4_out;
    assign add_diff_1_out = sub_1_out + sub_2_out;
    assign add_diff_2_out = sub_3_out + sub_4_out;
    assign add_diff_3_out = add_diff_1_out + add_diff_2_out;
    assign add_diff_4_out = add_diff_3_out + D6x6;

    always @(posedge clk ) begin
        if(cs_isp == IDLE)
            D2x2 <= 0;
        else if(cs_isp == Focus)begin
            if(cnt_img_or_focus == 1)
                D2x2 <= D6x6;
        end
    end
    always @(posedge clk ) begin
        if(cs_isp == IDLE)
            D4x4 <= 0;
        else if(cs_isp == Focus)begin
            if(cnt_img_or_focus == 6)
                D4x4 <= D6x6;
        end
    end
    always @(posedge clk /*or negedge rst_n*/) begin
        // if(~rst_n)
        //     D6x6 <= 0;
        // else 
        if(cs_isp == IDLE)
            D6x6 <= 0;
        else if(cs_isp == Focus && start_cal_difference)begin
            D6x6 <= add_diff_4_out;
        end
    end
//============================================================
// Cal_max_contrast
//============================================================
    wire [9:0] D2x2_cal;
    wire [12:0] D4x4_cal;
    wire [13:0] D6x6_cal;
    // assign D2x2_cal = D2x2 >> 3 + D2x2;
    // assign D4x4_cal = (D4x4 >> 3 + D4x4) << 1;
    assign D2x2_cal = D2x2 >> 2;
    assign D4x4_cal = D4x4 >> 4;
    assign D6x6_cal = (D6x6 >> 2)/9;
    wire [13:0] cmp_wire_1,cmp_wire_2;

    assign cmp_wire_1 = (D2x2_cal   >= D4x4_cal) ? D2x2_cal   : D4x4_cal;
    assign cmp_wire_2 = (cmp_wire_1 >= D6x6_cal) ? cmp_wire_1 : D6x6_cal;
    always @(*) begin
        if(cmp_wire_2 == D2x2_cal)
            max_contrast = 0;
        else if(cmp_wire_2 == D4x4_cal)
            max_contrast = 1;
        else if(cmp_wire_2 == D6x6_cal)
            max_contrast = 2;
        else
            max_contrast = 3;
    end
    always @(posedge clk) begin
        if(focus_done)begin
            max_contrast_reg <= max_contrast;
        end
    end
//============================================================
// Zero Detector
//============================================================
generate
    for(j = 0;j < 16;j = j + 1)begin:zero_detector
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n)
                zero_detect_reg[j] <= 0;
            else if(cs_isp == Exposure && ns_isp == OUT)begin
                if(in_pic_no_reg == j)
                    zero_detect_reg[j] <= ~zero_detect_reg[j];
            end
            else if(cs_exposure == WRITE)begin
                if(in_pic_no_reg == j)begin
                    if(zero_detect_reg[j] == 1)
                        zero_detect_reg[j] <= 1;
                    else if(zero_detect_reg[j] == 0 && data_in_e != 0)
                        zero_detect_reg[j] <= 1;
                end
            end
        end
    end
endgenerate
//============================================================
// OUTPUT
//============================================================
    assign out_valid = cs_isp == OUT;
    assign out_data = out_data_sel;
    always @(*) begin
        out_data_sel = 0;
        if(cs_isp == OUT)begin
            if(zero_detect)begin
                out_data_sel = 0;
            end
            else begin
                if(in_mode_reg)
                    out_data_sel = avg_reg[17:10];
                else
                    out_data_sel = max_contrast_reg;
            end
        end
    end
endmodule

module exposure_prossesor(
    data,
    // d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15,
    exposure_information
    );
    input  [127:0] data ;
    // input  [7:0] d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15 ;
    output reg [395:0] exposure_information ;//36*11 = 396


    //============================================================
    // Parameter and Integer
    //============================================================
        integer i;
        genvar j;
    //============================================================
    // Declaration
    //============================================================
        wire [7:0] d[0:15] ;
        wire [3:0] d_out [0:15] ;
        wire saturatio_check [0:15] ;
        
        assign d[0]  = data[7:0]    ;assign d[1]  = data[15:8]    ;assign d[2] = data[23:16]    ;assign d[3]  = data[31:24]  ;
        assign d[4]  = data[39:32]  ;assign d[5]  = data[47:40]   ;assign d[6] = data[55:48]    ;assign d[7]  = data[63:56]  ;
        assign d[8]  = data[71:64]  ;assign d[9]  = data[79:72]   ;assign d[10] = data[87:80]   ;assign d[11] = data[95:88]  ;
        assign d[12] = data[103:96] ;assign d[13] = data[111:104] ;assign d[14] = data[119:112] ;assign d[15] = data[127:120];
    //============================================================
        reg [7:0]d_inf[0:15][0:7];
        classifier c0 (.in_data(d[0]) , .out(d_out[0]) ) ;
        classifier c1 (.in_data(d[1]) , .out(d_out[1]) ) ;
        classifier c2 (.in_data(d[2]) , .out(d_out[2]) ) ;
        classifier c3 (.in_data(d[3]) , .out(d_out[3]) ) ;
        classifier c4 (.in_data(d[4]) , .out(d_out[4]) ) ;
        classifier c5 (.in_data(d[5]) , .out(d_out[5]) ) ;
        classifier c6 (.in_data(d[6]) , .out(d_out[6]) ) ;
        classifier c7 (.in_data(d[7]) , .out(d_out[7]) ) ;
        classifier c8 (.in_data(d[8]) , .out(d_out[8]) ) ;
        classifier c9 (.in_data(d[9]) , .out(d_out[9]) ) ;
        classifier c10(.in_data(d[10]), .out(d_out[10])) ;
        classifier c11(.in_data(d[11]), .out(d_out[11])) ;
        classifier c12(.in_data(d[12]), .out(d_out[12])) ;
        classifier c13(.in_data(d[13]), .out(d_out[13])) ;
        classifier c14(.in_data(d[14]), .out(d_out[14])) ;
        classifier c15(.in_data(d[15]), .out(d_out[15])) ;
    //============================================================
    // Exposure Information:
    //  1         [10:0]
    //  2-3       [32,22],[21:11]
    //  4-7       [65,55],[54,44],[43:33]
    //  8-15      [109,99],[98,88],[87,77],[76:66]
    //  16-31     [164,154],[153,143],[142,132],[131,121],[120:110]
    //  32-63     [230,220],[219,209],[208,198],[197,187],[186,176],[175:165]
    //  64-127    [307,297],[296,286],[285,275],[274,264],[263,253],[252,242],[241:231]
    //  128-254   [395,385],[384,374],[373,363],[362,352],[351,341],[340,330],[329,319],[318:308]
    //  255       [406:396]
    //============================================================
    // assign exposure_information[406:396] = saturatio_check[15] + saturatio_check[14] + saturatio_check[13] + saturatio_check[12] + saturatio_check[11] + saturatio_check[10] + saturatio_check[9] + saturatio_check[8] + saturatio_check[7] + saturatio_check[6] + saturatio_check[5] + saturatio_check[4] + saturatio_check[3] + saturatio_check[2] + saturatio_check[1] + saturatio_check[0];
    generate
        for(j = 0; j < 16; j = j + 1) begin:gen
            always @(*) begin
                for(i = 0; i < 8; i = i + 1) begin
                    d_inf[j][i] = 0;
                end
                case (d_out[j])
                    'd8: d_inf[j][7] = d[j];
                    'd7: d_inf[j][6] = d[j];
                    'd6: d_inf[j][5] = d[j];
                    'd5: d_inf[j][4] = d[j];
                    'd4: d_inf[j][3] = d[j];
                    'd3: d_inf[j][2] = d[j];
                    'd2: d_inf[j][1] = d[j];
                    'd1: d_inf[j][0] = d[j]; 
                endcase
            end
        end
    endgenerate
    assign exposure_information[10:0]  = d_inf[0][0][0] + d_inf[1][0][0] + d_inf[2][0][0] + d_inf[3][0][0] + d_inf[4][0][0] + d_inf[5][0][0] + d_inf[6][0][0] + d_inf[7][0][0] + d_inf[8][0][0] + d_inf[9][0][0] + d_inf[10][0][0] + d_inf[11][0][0] + d_inf[12][0][0] + d_inf[13][0][0] + d_inf[14][0][0] + d_inf[15][0][0];

    assign exposure_information[21:11] = d_inf[0][1][0] + d_inf[1][1][0] + d_inf[2][1][0] + d_inf[3][1][0] + d_inf[4][1][0] + d_inf[5][1][0] + d_inf[6][1][0] + d_inf[7][1][0] + d_inf[8][1][0] + d_inf[9][1][0] + d_inf[10][1][0] + d_inf[11][1][0] + d_inf[12][1][0] + d_inf[13][1][0] + d_inf[14][1][0] + d_inf[15][1][0]; 
    assign exposure_information[32:22] = d_inf[0][1][1] + d_inf[1][1][1] + d_inf[2][1][1] + d_inf[3][1][1] + d_inf[4][1][1] + d_inf[5][1][1] + d_inf[6][1][1] + d_inf[7][1][1] + d_inf[8][1][1] + d_inf[9][1][1] + d_inf[10][1][1] + d_inf[11][1][1] + d_inf[12][1][1] + d_inf[13][1][1] + d_inf[14][1][1] + d_inf[15][1][1];

    assign exposure_information[43:33] = d_inf[0][2][0] + d_inf[1][2][0] + d_inf[2][2][0] + d_inf[3][2][0] + d_inf[4][2][0] + d_inf[5][2][0] + d_inf[6][2][0] + d_inf[7][2][0] + d_inf[8][2][0] + d_inf[9][2][0] + d_inf[10][2][0] + d_inf[11][2][0] + d_inf[12][2][0] + d_inf[13][2][0] + d_inf[14][2][0] + d_inf[15][2][0];
    assign exposure_information[54:44] = d_inf[0][2][1] + d_inf[1][2][1] + d_inf[2][2][1] + d_inf[3][2][1] + d_inf[4][2][1] + d_inf[5][2][1] + d_inf[6][2][1] + d_inf[7][2][1] + d_inf[8][2][1] + d_inf[9][2][1] + d_inf[10][2][1] + d_inf[11][2][1] + d_inf[12][2][1] + d_inf[13][2][1] + d_inf[14][2][1] + d_inf[15][2][1];
    assign exposure_information[64:55] = d_inf[0][2][2] + d_inf[1][2][2] + d_inf[2][2][2] + d_inf[3][2][2] + d_inf[4][2][2] + d_inf[5][2][2] + d_inf[6][2][2] + d_inf[7][2][2] + d_inf[8][2][2] + d_inf[9][2][2] + d_inf[10][2][2] + d_inf[11][2][2] + d_inf[12][2][2] + d_inf[13][2][2] + d_inf[14][2][2] + d_inf[15][2][2];

    assign exposure_information[76:66] = d_inf[0][3][0] + d_inf[1][3][0] + d_inf[2][3][0] + d_inf[3][3][0] + d_inf[4][3][0] + d_inf[5][3][0] + d_inf[6][3][0] + d_inf[7][3][0] + d_inf[8][3][0] + d_inf[9][3][0] + d_inf[10][3][0] + d_inf[11][3][0] + d_inf[12][3][0] + d_inf[13][3][0] + d_inf[14][3][0] + d_inf[15][3][0];
    assign exposure_information[87:77] = d_inf[0][3][1] + d_inf[1][3][1] + d_inf[2][3][1] + d_inf[3][3][1] + d_inf[4][3][1] + d_inf[5][3][1] + d_inf[6][3][1] + d_inf[7][3][1] + d_inf[8][3][1] + d_inf[9][3][1] + d_inf[10][3][1] + d_inf[11][3][1] + d_inf[12][3][1] + d_inf[13][3][1] + d_inf[14][3][1] + d_inf[15][3][1];
    assign exposure_information[98:88] = d_inf[0][3][2] + d_inf[1][3][2] + d_inf[2][3][2] + d_inf[3][3][2] + d_inf[4][3][2] + d_inf[5][3][2] + d_inf[6][3][2] + d_inf[7][3][2] + d_inf[8][3][2] + d_inf[9][3][2] + d_inf[10][3][2] + d_inf[11][3][2] + d_inf[12][3][2] + d_inf[13][3][2] + d_inf[14][3][2] + d_inf[15][3][2];
    assign exposure_information[109:99] = d_inf[0][3][3] + d_inf[1][3][3] + d_inf[2][3][3] + d_inf[3][3][3] + d_inf[4][3][3] + d_inf[5][3][3] + d_inf[6][3][3] + d_inf[7][3][3] + d_inf[8][3][3] + d_inf[9][3][3] + d_inf[10][3][3] + d_inf[11][3][3] + d_inf[12][3][3] + d_inf[13][3][3] + d_inf[14][3][3] + d_inf[15][3][3];

    assign exposure_information[120:110] = d_inf[0][4][0] + d_inf[1][4][0] + d_inf[2][4][0] + d_inf[3][4][0] + d_inf[4][4][0] + d_inf[5][4][0] + d_inf[6][4][0] + d_inf[7][4][0] + d_inf[8][4][0] + d_inf[9][4][0] + d_inf[10][4][0] + d_inf[11][4][0] + d_inf[12][4][0] + d_inf[13][4][0] + d_inf[14][4][0] + d_inf[15][4][0];
    assign exposure_information[131:121] = d_inf[0][4][1] + d_inf[1][4][1] + d_inf[2][4][1] + d_inf[3][4][1] + d_inf[4][4][1] + d_inf[5][4][1] + d_inf[6][4][1] + d_inf[7][4][1] + d_inf[8][4][1] + d_inf[9][4][1] + d_inf[10][4][1] + d_inf[11][4][1] + d_inf[12][4][1] + d_inf[13][4][1] + d_inf[14][4][1] + d_inf[15][4][1];
    assign exposure_information[142:132] = d_inf[0][4][2] + d_inf[1][4][2] + d_inf[2][4][2] + d_inf[3][4][2] + d_inf[4][4][2] + d_inf[5][4][2] + d_inf[6][4][2] + d_inf[7][4][2] + d_inf[8][4][2] + d_inf[9][4][2] + d_inf[10][4][2] + d_inf[11][4][2] + d_inf[12][4][2] + d_inf[13][4][2] + d_inf[14][4][2] + d_inf[15][4][2];
    assign exposure_information[153:143] = d_inf[0][4][3] + d_inf[1][4][3] + d_inf[2][4][3] + d_inf[3][4][3] + d_inf[4][4][3] + d_inf[5][4][3] + d_inf[6][4][3] + d_inf[7][4][3] + d_inf[8][4][3] + d_inf[9][4][3] + d_inf[10][4][3] + d_inf[11][4][3] + d_inf[12][4][3] + d_inf[13][4][3] + d_inf[14][4][3] + d_inf[15][4][3];
    assign exposure_information[164:154] = d_inf[0][4][4] + d_inf[1][4][4] + d_inf[2][4][4] + d_inf[3][4][4] + d_inf[4][4][4] + d_inf[5][4][4] + d_inf[6][4][4] + d_inf[7][4][4] + d_inf[8][4][4] + d_inf[9][4][4] + d_inf[10][4][4] + d_inf[11][4][4] + d_inf[12][4][4] + d_inf[13][4][4] + d_inf[14][4][4] + d_inf[15][4][4];

    assign exposure_information[175:165] = d_inf[0][5][0] + d_inf[1][5][0] + d_inf[2][5][0] + d_inf[3][5][0] + d_inf[4][5][0] + d_inf[5][5][0] + d_inf[6][5][0] + d_inf[7][5][0] + d_inf[8][5][0] + d_inf[9][5][0] + d_inf[10][5][0] + d_inf[11][5][0] + d_inf[12][5][0] + d_inf[13][5][0] + d_inf[14][5][0] + d_inf[15][5][0];
    assign exposure_information[186:176] = d_inf[0][5][1] + d_inf[1][5][1] + d_inf[2][5][1] + d_inf[3][5][1] + d_inf[4][5][1] + d_inf[5][5][1] + d_inf[6][5][1] + d_inf[7][5][1] + d_inf[8][5][1] + d_inf[9][5][1] + d_inf[10][5][1] + d_inf[11][5][1] + d_inf[12][5][1] + d_inf[13][5][1] + d_inf[14][5][1] + d_inf[15][5][1];
    assign exposure_information[197:187] = d_inf[0][5][2] + d_inf[1][5][2] + d_inf[2][5][2] + d_inf[3][5][2] + d_inf[4][5][2] + d_inf[5][5][2] + d_inf[6][5][2] + d_inf[7][5][2] + d_inf[8][5][2] + d_inf[9][5][2] + d_inf[10][5][2] + d_inf[11][5][2] + d_inf[12][5][2] + d_inf[13][5][2] + d_inf[14][5][2] + d_inf[15][5][2];
    assign exposure_information[208:198] = d_inf[0][5][3] + d_inf[1][5][3] + d_inf[2][5][3] + d_inf[3][5][3] + d_inf[4][5][3] + d_inf[5][5][3] + d_inf[6][5][3] + d_inf[7][5][3] + d_inf[8][5][3] + d_inf[9][5][3] + d_inf[10][5][3] + d_inf[11][5][3] + d_inf[12][5][3] + d_inf[13][5][3] + d_inf[14][5][3] + d_inf[15][5][3];
    assign exposure_information[219:209] = d_inf[0][5][4] + d_inf[1][5][4] + d_inf[2][5][4] + d_inf[3][5][4] + d_inf[4][5][4] + d_inf[5][5][4] + d_inf[6][5][4] + d_inf[7][5][4] + d_inf[8][5][4] + d_inf[9][5][4] + d_inf[10][5][4] + d_inf[11][5][4] + d_inf[12][5][4] + d_inf[13][5][4] + d_inf[14][5][4] + d_inf[15][5][4];
    assign exposure_information[230:220] = d_inf[0][5][5] + d_inf[1][5][5] + d_inf[2][5][5] + d_inf[3][5][5] + d_inf[4][5][5] + d_inf[5][5][5] + d_inf[6][5][5] + d_inf[7][5][5] + d_inf[8][5][5] + d_inf[9][5][5] + d_inf[10][5][5] + d_inf[11][5][5] + d_inf[12][5][5] + d_inf[13][5][5] + d_inf[14][5][5] + d_inf[15][5][5];

    assign exposure_information[241:231] = d_inf[0][6][0] + d_inf[1][6][0] + d_inf[2][6][0] + d_inf[3][6][0] + d_inf[4][6][0] + d_inf[5][6][0] + d_inf[6][6][0] + d_inf[7][6][0] + d_inf[8][6][0] + d_inf[9][6][0] + d_inf[10][6][0] + d_inf[11][6][0] + d_inf[12][6][0] + d_inf[13][6][0] + d_inf[14][6][0] + d_inf[15][6][0];
    assign exposure_information[252:242] = d_inf[0][6][1] + d_inf[1][6][1] + d_inf[2][6][1] + d_inf[3][6][1] + d_inf[4][6][1] + d_inf[5][6][1] + d_inf[6][6][1] + d_inf[7][6][1] + d_inf[8][6][1] + d_inf[9][6][1] + d_inf[10][6][1] + d_inf[11][6][1] + d_inf[12][6][1] + d_inf[13][6][1] + d_inf[14][6][1] + d_inf[15][6][1];
    assign exposure_information[263:253] = d_inf[0][6][2] + d_inf[1][6][2] + d_inf[2][6][2] + d_inf[3][6][2] + d_inf[4][6][2] + d_inf[5][6][2] + d_inf[6][6][2] + d_inf[7][6][2] + d_inf[8][6][2] + d_inf[9][6][2] + d_inf[10][6][2] + d_inf[11][6][2] + d_inf[12][6][2] + d_inf[13][6][2] + d_inf[14][6][2] + d_inf[15][6][2];
    assign exposure_information[274:264] = d_inf[0][6][3] + d_inf[1][6][3] + d_inf[2][6][3] + d_inf[3][6][3] + d_inf[4][6][3] + d_inf[5][6][3] + d_inf[6][6][3] + d_inf[7][6][3] + d_inf[8][6][3] + d_inf[9][6][3] + d_inf[10][6][3] + d_inf[11][6][3] + d_inf[12][6][3] + d_inf[13][6][3] + d_inf[14][6][3] + d_inf[15][6][3];
    assign exposure_information[285:275] = d_inf[0][6][4] + d_inf[1][6][4] + d_inf[2][6][4] + d_inf[3][6][4] + d_inf[4][6][4] + d_inf[5][6][4] + d_inf[6][6][4] + d_inf[7][6][4] + d_inf[8][6][4] + d_inf[9][6][4] + d_inf[10][6][4] + d_inf[11][6][4] + d_inf[12][6][4] + d_inf[13][6][4] + d_inf[14][6][4] + d_inf[15][6][4];
    assign exposure_information[296:286] = d_inf[0][6][5] + d_inf[1][6][5] + d_inf[2][6][5] + d_inf[3][6][5] + d_inf[4][6][5] + d_inf[5][6][5] + d_inf[6][6][5] + d_inf[7][6][5] + d_inf[8][6][5] + d_inf[9][6][5] + d_inf[10][6][5] + d_inf[11][6][5] + d_inf[12][6][5] + d_inf[13][6][5] + d_inf[14][6][5] + d_inf[15][6][5];
    assign exposure_information[307:297] = d_inf[0][6][6] + d_inf[1][6][6] + d_inf[2][6][6] + d_inf[3][6][6] + d_inf[4][6][6] + d_inf[5][6][6] + d_inf[6][6][6] + d_inf[7][6][6] + d_inf[8][6][6] + d_inf[9][6][6] + d_inf[10][6][6] + d_inf[11][6][6] + d_inf[12][6][6] + d_inf[13][6][6] + d_inf[14][6][6] + d_inf[15][6][6];

    assign exposure_information[318:308] = d_inf[0][7][0] + d_inf[1][7][0] + d_inf[2][7][0] + d_inf[3][7][0] + d_inf[4][7][0] + d_inf[5][7][0] + d_inf[6][7][0] + d_inf[7][7][0] + d_inf[8][7][0] + d_inf[9][7][0] + d_inf[10][7][0] + d_inf[11][7][0] + d_inf[12][7][0] + d_inf[13][7][0] + d_inf[14][7][0] + d_inf[15][7][0];
    assign exposure_information[329:319] = d_inf[0][7][1] + d_inf[1][7][1] + d_inf[2][7][1] + d_inf[3][7][1] + d_inf[4][7][1] + d_inf[5][7][1] + d_inf[6][7][1] + d_inf[7][7][1] + d_inf[8][7][1] + d_inf[9][7][1] + d_inf[10][7][1] + d_inf[11][7][1] + d_inf[12][7][1] + d_inf[13][7][1] + d_inf[14][7][1] + d_inf[15][7][1];
    assign exposure_information[340:330] = d_inf[0][7][2] + d_inf[1][7][2] + d_inf[2][7][2] + d_inf[3][7][2] + d_inf[4][7][2] + d_inf[5][7][2] + d_inf[6][7][2] + d_inf[7][7][2] + d_inf[8][7][2] + d_inf[9][7][2] + d_inf[10][7][2] + d_inf[11][7][2] + d_inf[12][7][2] + d_inf[13][7][2] + d_inf[14][7][2] + d_inf[15][7][2];
    assign exposure_information[351:341] = d_inf[0][7][3] + d_inf[1][7][3] + d_inf[2][7][3] + d_inf[3][7][3] + d_inf[4][7][3] + d_inf[5][7][3] + d_inf[6][7][3] + d_inf[7][7][3] + d_inf[8][7][3] + d_inf[9][7][3] + d_inf[10][7][3] + d_inf[11][7][3] + d_inf[12][7][3] + d_inf[13][7][3] + d_inf[14][7][3] + d_inf[15][7][3];
    assign exposure_information[362:352] = d_inf[0][7][4] + d_inf[1][7][4] + d_inf[2][7][4] + d_inf[3][7][4] + d_inf[4][7][4] + d_inf[5][7][4] + d_inf[6][7][4] + d_inf[7][7][4] + d_inf[8][7][4] + d_inf[9][7][4] + d_inf[10][7][4] + d_inf[11][7][4] + d_inf[12][7][4] + d_inf[13][7][4] + d_inf[14][7][4] + d_inf[15][7][4];
    assign exposure_information[373:363] = d_inf[0][7][5] + d_inf[1][7][5] + d_inf[2][7][5] + d_inf[3][7][5] + d_inf[4][7][5] + d_inf[5][7][5] + d_inf[6][7][5] + d_inf[7][7][5] + d_inf[8][7][5] + d_inf[9][7][5] + d_inf[10][7][5] + d_inf[11][7][5] + d_inf[12][7][5] + d_inf[13][7][5] + d_inf[14][7][5] + d_inf[15][7][5];
    assign exposure_information[384:374] = d_inf[0][7][6] + d_inf[1][7][6] + d_inf[2][7][6] + d_inf[3][7][6] + d_inf[4][7][6] + d_inf[5][7][6] + d_inf[6][7][6] + d_inf[7][7][6] + d_inf[8][7][6] + d_inf[9][7][6] + d_inf[10][7][6] + d_inf[11][7][6] + d_inf[12][7][6] + d_inf[13][7][6] + d_inf[14][7][6] + d_inf[15][7][6];
    assign exposure_information[395:385] = d_inf[0][7][7] + d_inf[1][7][7] + d_inf[2][7][7] + d_inf[3][7][7] + d_inf[4][7][7] + d_inf[5][7][7] + d_inf[6][7][7] + d_inf[7][7][7] + d_inf[8][7][7] + d_inf[9][7][7] + d_inf[10][7][7] + d_inf[11][7][7] + d_inf[12][7][7] + d_inf[13][7][7] + d_inf[14][7][7] + d_inf[15][7][7];
endmodule

module classifier(
    in_data,
    out
    );
    input [7:0] in_data;
    output reg [3:0] out;

    always @(*) begin
        // if(in_data == 'd255)begin
        //     saturatio_check = 1;
        //     out = 'd0;
        // end
        // else begin
        //     saturatio_check = 0;
            if(in_data[7])
                out = 'd8;
            else if(in_data[6])
                out = 'd7;
            else if(in_data[5])
                out = 'd6;
            else if(in_data[4])
                out = 'd5;
            else if(in_data[3])
                out = 'd4;
            else if(in_data[2])
                out = 'd3;
            else if(in_data[1])
                out = 'd2;
            else if(in_data[0])
                out = 'd1;
            else
                out = 'd0;
        end
    // end
endmodule
