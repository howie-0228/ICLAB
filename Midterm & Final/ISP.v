module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input [1:0] in_mode,
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
parameter IDLE = 0, WAIT_DRAM = 1, FUNC = 2, OUT = 3;
parameter S_ADDR = 4, R_DATA = 5, W_ADDR = 6, W_DATA = 7;

integer i,j;
genvar g;
//============================================================
// Register
//============================================================
reg [1:0] cs_isp , ns_isp;
reg [2:0] cs_dram, ns_dram;

reg [3:0] in_pic_no_reg;
reg [1:0] in_mode_reg;
reg [1:0] in_ratio_mode_reg;
//dram signal...............................................
reg [127:0] rdata_s_inf_reg;
reg rlast_s_inf_reg;
reg rvalid_s_inf_reg;

reg [31:0] araddr_s_inf_reg;
reg rready_s_inf_reg;

reg [31:0] awaddr_s_inf_reg;
reg wvalid_s_inf_reg;
reg bready_s_inf_reg;
//dram signal...............................................
reg [5:0] cnt_func;
reg cnt_2_cycle;
reg [1:0] cnt_rgb;

wire do_focus_accumulation;
wire do_upper_shift_focus_reg;
wire do_left_shift_focus_reg;
wire do_cal_difference;

wire do_find_max_min;

wire focus_done;
wire am_done;

wire start_write_data, w_data_done;
reg func_done;

reg [7:0] rdata_after_shift[0:2];
reg [1:0] max_contrast;

reg [7:0] rdata_times_ratio[0:15];

reg exposure_detect;
reg picture_detect;

wire [7:0] find_max, find_min;
wire [7:0] cmp_1_max_out, cmp_1_min_out, cmp_2_max_out, cmp_2_min_out;
reg [7:0] max_in, min_in;
wire [7:0] avg_max_divide_3, avg_min_divide_3;
wire [8:0] max_min_result;

reg early_output;
reg zero_detect;
reg zero_detect_reg[0:15];
//stored unit...............................................
reg [7:0] rdata_times_ratio_reg[0:15];

reg [7:0]  Autofocus_reg [0:5][0:5];
reg [9:0]  D2x2;
reg [12:0] D4x4;
reg [13:0] D6x6;
reg [1:0]  focus_result_reg[0:15];

reg [7:0] write_data_buffer[0:2][0:15];
reg [7:0] exposure_result_reg[0:15];

reg exposure_check_flag[0:15];
reg picture_check_flag[0:15];

reg [8:0] avg_pipe_reg[0:3];
reg [17:0] Avg_reg;

reg [7:0] max_min_result_reg[0:15];
reg [7:0] max_result_reg, min_result_reg;
reg [9:0] avg_max_reg, avg_min_reg;
reg [7:0] find_max_reg, find_min_reg;
//output data...............................................
reg [7:0] out_data_sel;  
//============================================================
// DRAM Read Signal Control
//============================================================
assign arid_s_inf = 4'b0000;
assign arlen_s_inf = 8'd191;
assign arsize_s_inf = 3'b100;
assign arburst_s_inf = 2'b01;
//============================================================
// DRAM Write Signal Control
//============================================================
assign awid_s_inf = 4'b0000;
assign awlen_s_inf = 8'd191;
assign awsize_s_inf = 3'b100;
assign awburst_s_inf = 2'b01;
//============================================================
// Input Buffer
//============================================================
always @(posedge clk ) begin
    if(in_valid) begin
        in_pic_no_reg <= in_pic_no;
        in_mode_reg <= in_mode;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        in_ratio_mode_reg <= 2;
    end
    else if(in_valid) begin
        if(in_mode[0])
            in_ratio_mode_reg <= in_ratio_mode;
        else
            in_ratio_mode_reg <= 2;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        rdata_s_inf_reg <= 0;
        rlast_s_inf_reg <= 0;
        rvalid_s_inf_reg <= 0;
    end
    else begin
        rdata_s_inf_reg <= rdata_s_inf;
        rlast_s_inf_reg <= rlast_s_inf;
        rvalid_s_inf_reg <= rvalid_s_inf;
    end
end
//============================================================
// FSM_ISP
//============================================================
always @(*) begin
    func_done = 0;
    case (in_mode_reg)
        // 'd0: func_done = rlast_s_inf;//or rlast_s_inf_reg;
        'd0: func_done = cnt_rgb == 3 && cnt_func == 3;
        'd1: func_done = bvalid_s_inf;
        'd2: func_done = cnt_rgb == 3 && cnt_func == 5;
    endcase
end

always @(*) begin
    early_output = 0;
    case (in_mode_reg)
        'd0: early_output = picture_detect;
        'd1: early_output = in_ratio_mode_reg == 'd2 && exposure_detect;
        'd2: early_output = picture_detect;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cs_isp <= IDLE;
    end
    else begin
        cs_isp <= ns_isp;
    end
end
always @(*) begin
    case (cs_isp)
        IDLE     : ns_isp = in_valid     ? WAIT_DRAM : IDLE;
        WAIT_DRAM: ns_isp = (early_output || zero_detect) ? OUT : (rvalid_s_inf ? FUNC : WAIT_DRAM); 
        FUNC     : ns_isp = func_done    ? OUT : FUNC;
        OUT      : ns_isp = IDLE;
        default  : ns_isp = IDLE; 
    endcase
end
//============================================================
// FSM_DRAM 
//============================================================
assign start_write_data = (cs_isp == WAIT_DRAM) && (ns_isp == FUNC) && (in_mode_reg[0]);   
assign w_data_done = cnt_rgb == 3 && cnt_func == 2;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cs_dram <= IDLE;
    end
    else begin
        cs_dram <= ns_dram;
    end
end
always @(*) begin
    case (cs_dram)
        IDLE   : ns_dram = (cs_isp == WAIT_DRAM && !early_output && !zero_detect)  ? S_ADDR : IDLE;
        // S_ADDR : ns_dram = arready_s_inf     ? R_DATA : awready_s_inf ? W_DATA : S_ADDR;
        S_ADDR : ns_dram = arready_s_inf        ? R_DATA : S_ADDR;
        R_DATA : ns_dram = start_write_data     ? W_DATA : (rlast_s_inf_reg ?  IDLE: R_DATA);
        // W_ADDR : ns_dram = awready_s_inf     ? W_DATA : W_ADDR;
        W_DATA : ns_dram = w_data_done          ? IDLE : W_DATA;  
        default: ns_dram = IDLE;
    endcase
end
//============================================================
// Dram Read Control
//============================================================
always @(posedge clk) begin
    if(ns_dram == S_ADDR) begin
        araddr_s_inf_reg[31:16] <= 16'h0001;
        araddr_s_inf_reg[15:8]  <= (in_pic_no_reg * 3) << 2;//*12
        araddr_s_inf_reg[7:0]   <= 8'h00;
    end
    else begin
        araddr_s_inf_reg  <= 32'h10000;
    end
end

always @(posedge clk) begin
    if(ns_dram == IDLE) 
        rready_s_inf_reg <= 0;
    else if(ns_dram == R_DATA)
        rready_s_inf_reg <= 1;
end

assign arvalid_s_inf = cs_dram == S_ADDR;
assign araddr_s_inf  = araddr_s_inf_reg;
assign rready_s_inf  = rready_s_inf_reg;
//============================================================
// Dram Write Control
//============================================================
always @(posedge clk) begin
    if(ns_dram == S_ADDR && in_mode_reg[0]) begin
        awaddr_s_inf_reg[31:16] <= 16'h0001;
        awaddr_s_inf_reg[15:8]  <= (in_pic_no_reg * 3) << 2;//*12
        awaddr_s_inf_reg[7:0]   <= 8'h00;
    end
    else begin
        awaddr_s_inf_reg  <= 32'h10000;
    end
end
always @(posedge clk ) begin
    if(ns_dram == IDLE)
        wvalid_s_inf_reg <= 0;
    else if(w_data_done)
        wvalid_s_inf_reg <= 0;
    else if(start_write_data)
        wvalid_s_inf_reg <= 1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        bready_s_inf_reg <= 0;
    end
    else if(start_write_data)
        bready_s_inf_reg <= 1;
    else if(bvalid_s_inf)
        bready_s_inf_reg <= 0;
end

always @(posedge clk ) begin
    if(rvalid_s_inf_reg || cnt_rgb == 3) begin
        for(i = 0; i < 16; i = i + 1) begin
            write_data_buffer[0][i] <= write_data_buffer[1][i];
            write_data_buffer[1][i] <= write_data_buffer[2][i];
        end
        case (in_ratio_mode_reg)
            0:begin
                write_data_buffer[2][0]  <= rdata_s_inf_reg[7:0]     >> 2;
                write_data_buffer[2][1]  <= rdata_s_inf_reg[15:8]    >> 2;
                write_data_buffer[2][2]  <= rdata_s_inf_reg[23:16]   >> 2;
                write_data_buffer[2][3]  <= rdata_s_inf_reg[31:24]   >> 2;
                write_data_buffer[2][4]  <= rdata_s_inf_reg[39:32]   >> 2;
                write_data_buffer[2][5]  <= rdata_s_inf_reg[47:40]   >> 2;
                write_data_buffer[2][6]  <= rdata_s_inf_reg[55:48]   >> 2;
                write_data_buffer[2][7]  <= rdata_s_inf_reg[63:56]   >> 2;
                write_data_buffer[2][8]  <= rdata_s_inf_reg[71:64]   >> 2;
                write_data_buffer[2][9]  <= rdata_s_inf_reg[79:72]   >> 2;
                write_data_buffer[2][10] <= rdata_s_inf_reg[87:80]   >> 2;
                write_data_buffer[2][11] <= rdata_s_inf_reg[95:88]   >> 2;
                write_data_buffer[2][12] <= rdata_s_inf_reg[103:96]  >> 2;
                write_data_buffer[2][13] <= rdata_s_inf_reg[111:104] >> 2;
                write_data_buffer[2][14] <= rdata_s_inf_reg[119:112] >> 2;
                write_data_buffer[2][15] <= rdata_s_inf_reg[127:120] >> 2;
            end 
            1:begin
                write_data_buffer[2][0]  <= rdata_s_inf_reg[7:0]     >> 1;
                write_data_buffer[2][1]  <= rdata_s_inf_reg[15:8]    >> 1;
                write_data_buffer[2][2]  <= rdata_s_inf_reg[23:16]   >> 1;
                write_data_buffer[2][3]  <= rdata_s_inf_reg[31:24]   >> 1;
                write_data_buffer[2][4]  <= rdata_s_inf_reg[39:32]   >> 1;
                write_data_buffer[2][5]  <= rdata_s_inf_reg[47:40]   >> 1;
                write_data_buffer[2][6]  <= rdata_s_inf_reg[55:48]   >> 1;
                write_data_buffer[2][7]  <= rdata_s_inf_reg[63:56]   >> 1;
                write_data_buffer[2][8]  <= rdata_s_inf_reg[71:64]   >> 1;
                write_data_buffer[2][9]  <= rdata_s_inf_reg[79:72]   >> 1;
                write_data_buffer[2][10] <= rdata_s_inf_reg[87:80]   >> 1;
                write_data_buffer[2][11] <= rdata_s_inf_reg[95:88]   >> 1;
                write_data_buffer[2][12] <= rdata_s_inf_reg[103:96]  >> 1;
                write_data_buffer[2][13] <= rdata_s_inf_reg[111:104] >> 1;
                write_data_buffer[2][14] <= rdata_s_inf_reg[119:112] >> 1;
                write_data_buffer[2][15] <= rdata_s_inf_reg[127:120] >> 1;
            end 
            2:begin
                write_data_buffer[2][0]  <= rdata_s_inf_reg[7:0];
                write_data_buffer[2][1]  <= rdata_s_inf_reg[15:8];
                write_data_buffer[2][2]  <= rdata_s_inf_reg[23:16];
                write_data_buffer[2][3]  <= rdata_s_inf_reg[31:24];
                write_data_buffer[2][4]  <= rdata_s_inf_reg[39:32];
                write_data_buffer[2][5]  <= rdata_s_inf_reg[47:40];
                write_data_buffer[2][6]  <= rdata_s_inf_reg[55:48];
                write_data_buffer[2][7]  <= rdata_s_inf_reg[63:56];
                write_data_buffer[2][8]  <= rdata_s_inf_reg[71:64];
                write_data_buffer[2][9]  <= rdata_s_inf_reg[79:72];
                write_data_buffer[2][10] <= rdata_s_inf_reg[87:80];
                write_data_buffer[2][11] <= rdata_s_inf_reg[95:88];
                write_data_buffer[2][12] <= rdata_s_inf_reg[103:96];
                write_data_buffer[2][13] <= rdata_s_inf_reg[111:104];
                write_data_buffer[2][14] <= rdata_s_inf_reg[119:112];
                write_data_buffer[2][15] <= rdata_s_inf_reg[127:120];
            end
            3:begin
                write_data_buffer[2][0]  <= rdata_s_inf_reg[7]  ? 8'hFF : rdata_s_inf_reg[7:0]     << 1;
                write_data_buffer[2][1]  <= rdata_s_inf_reg[15] ? 8'hFF : rdata_s_inf_reg[15:8]    << 1;
                write_data_buffer[2][2]  <= rdata_s_inf_reg[23] ? 8'hFF : rdata_s_inf_reg[23:16]   << 1;
                write_data_buffer[2][3]  <= rdata_s_inf_reg[31] ? 8'hFF : rdata_s_inf_reg[31:24]   << 1;
                write_data_buffer[2][4]  <= rdata_s_inf_reg[39] ? 8'hFF : rdata_s_inf_reg[39:32]   << 1;
                write_data_buffer[2][5]  <= rdata_s_inf_reg[47] ? 8'hFF : rdata_s_inf_reg[47:40]   << 1;
                write_data_buffer[2][6]  <= rdata_s_inf_reg[55] ? 8'hFF : rdata_s_inf_reg[55:48]   << 1;
                write_data_buffer[2][7]  <= rdata_s_inf_reg[63] ? 8'hFF : rdata_s_inf_reg[63:56]   << 1;
                write_data_buffer[2][8]  <= rdata_s_inf_reg[71] ? 8'hFF : rdata_s_inf_reg[71:64]   << 1;
                write_data_buffer[2][9]  <= rdata_s_inf_reg[79] ? 8'hFF : rdata_s_inf_reg[79:72]   << 1;
                write_data_buffer[2][10] <= rdata_s_inf_reg[87] ? 8'hFF : rdata_s_inf_reg[87:80]   << 1;
                write_data_buffer[2][11] <= rdata_s_inf_reg[95] ? 8'hFF : rdata_s_inf_reg[95:88]   << 1;
                write_data_buffer[2][12] <= rdata_s_inf_reg[103]? 8'hFF : rdata_s_inf_reg[103:96]  << 1;
                write_data_buffer[2][13] <= rdata_s_inf_reg[111]? 8'hFF : rdata_s_inf_reg[111:104] << 1;
                write_data_buffer[2][14] <= rdata_s_inf_reg[119]? 8'hFF : rdata_s_inf_reg[119:112] << 1;
                write_data_buffer[2][15] <= rdata_s_inf_reg[127]? 8'hFF : rdata_s_inf_reg[127:120] << 1;
            end
        endcase
    end
end
assign awaddr_s_inf = awaddr_s_inf_reg;
assign awvalid_s_inf = cs_dram == S_ADDR && in_mode_reg[0];
assign wvalid_s_inf = wvalid_s_inf_reg;
assign wdata_s_inf = {write_data_buffer[0][15], write_data_buffer[0][14], write_data_buffer[0][13], write_data_buffer[0][12], write_data_buffer[0][11], write_data_buffer[0][10], write_data_buffer[0][9], write_data_buffer[0][8], write_data_buffer[0][7], write_data_buffer[0][6], write_data_buffer[0][5], write_data_buffer[0][4], write_data_buffer[0][3], write_data_buffer[0][2], write_data_buffer[0][1], write_data_buffer[0][0]};
assign wlast_s_inf = w_data_done;   
assign bready_s_inf = bready_s_inf_reg;
//============================================================
// Function Control
//============================================================
assign do_focus_accumulation = cnt_func > 25 && cnt_func < 38;
assign do_upper_shift_focus_reg = cnt_func > 37 && cnt_func < 44;
assign do_left_shift_focus_reg = cnt_func > 43 && cnt_func < 50;
assign do_cal_difference     = cnt_rgb[1]    && cnt_func > 38;

assign focus_done = cnt_rgb[1]   && cnt_func == 53;
assign am_done    = cnt_rgb == 3 && cnt_func == 4 ;

assign do_find_max_min = cnt_rgb > 0 || cnt_func > 0;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt_func <= 0;
    end
    else begin
        if(cs_isp == FUNC)
            cnt_func <= cnt_func + 1;
        else
            cnt_func <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt_2_cycle <= 0;
    end
    else begin
        if(do_focus_accumulation)
            cnt_2_cycle <= cnt_2_cycle + 1;
        else
            cnt_2_cycle <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt_rgb <= 0;
    end
    else if(cs_isp == IDLE)begin
        cnt_rgb <= 0;
    end
    else if(cnt_func == 'd63)begin
        cnt_rgb <= cnt_rgb + 1;
    end
end
//rdata_times_ratio
    always @(*) begin
        case (in_ratio_mode_reg)
            0:begin
                rdata_times_ratio[0] = rdata_s_inf_reg[7:0]   >> 2; rdata_times_ratio[4] = rdata_s_inf_reg[39:32] >> 2 ;rdata_times_ratio[8] = rdata_s_inf_reg[71:64]  >> 2; rdata_times_ratio[12] = rdata_s_inf_reg[103:96]  >> 2;
                rdata_times_ratio[1] = rdata_s_inf_reg[15:8]  >> 2; rdata_times_ratio[5] = rdata_s_inf_reg[47:40] >> 2 ;rdata_times_ratio[9] = rdata_s_inf_reg[79:72]  >> 2; rdata_times_ratio[13] = rdata_s_inf_reg[111:104] >> 2;
                rdata_times_ratio[2] = rdata_s_inf_reg[23:16] >> 2; rdata_times_ratio[6] = rdata_s_inf_reg[55:48] >> 2 ;rdata_times_ratio[10] = rdata_s_inf_reg[87:80] >> 2; rdata_times_ratio[14] = rdata_s_inf_reg[119:112] >> 2;
                rdata_times_ratio[3] = rdata_s_inf_reg[31:24] >> 2; rdata_times_ratio[7] = rdata_s_inf_reg[63:56] >> 2 ;rdata_times_ratio[11] = rdata_s_inf_reg[95:88] >> 2; rdata_times_ratio[15] = rdata_s_inf_reg[127:120] >> 2;
            end 
            1:begin
                rdata_times_ratio[0] = rdata_s_inf_reg[7:0]   >> 1; rdata_times_ratio[4] = rdata_s_inf_reg[39:32] >> 1 ;rdata_times_ratio[8] = rdata_s_inf_reg[71:64]  >> 1; rdata_times_ratio[12] = rdata_s_inf_reg[103:96]  >> 1;
                rdata_times_ratio[1] = rdata_s_inf_reg[15:8]  >> 1; rdata_times_ratio[5] = rdata_s_inf_reg[47:40] >> 1 ;rdata_times_ratio[9] = rdata_s_inf_reg[79:72]  >> 1; rdata_times_ratio[13] = rdata_s_inf_reg[111:104] >> 1;
                rdata_times_ratio[2] = rdata_s_inf_reg[23:16] >> 1; rdata_times_ratio[6] = rdata_s_inf_reg[55:48] >> 1 ;rdata_times_ratio[10] = rdata_s_inf_reg[87:80] >> 1; rdata_times_ratio[14] = rdata_s_inf_reg[119:112] >> 1;
                rdata_times_ratio[3] = rdata_s_inf_reg[31:24] >> 1; rdata_times_ratio[7] = rdata_s_inf_reg[63:56] >> 1 ;rdata_times_ratio[11] = rdata_s_inf_reg[95:88] >> 1; rdata_times_ratio[15] = rdata_s_inf_reg[127:120] >> 1;
            end
            2:begin
                rdata_times_ratio[0] = rdata_s_inf_reg[7:0]   ; rdata_times_ratio[4] = rdata_s_inf_reg[39:32] ;rdata_times_ratio[8] = rdata_s_inf_reg[71:64]  ; rdata_times_ratio[12] = rdata_s_inf_reg[103:96]  ;
                rdata_times_ratio[1] = rdata_s_inf_reg[15:8]  ; rdata_times_ratio[5] = rdata_s_inf_reg[47:40] ;rdata_times_ratio[9] = rdata_s_inf_reg[79:72]  ; rdata_times_ratio[13] = rdata_s_inf_reg[111:104] ;
                rdata_times_ratio[2] = rdata_s_inf_reg[23:16] ; rdata_times_ratio[6] = rdata_s_inf_reg[55:48] ;rdata_times_ratio[10] = rdata_s_inf_reg[87:80] ; rdata_times_ratio[14] = rdata_s_inf_reg[119:112] ;
                rdata_times_ratio[3] = rdata_s_inf_reg[31:24] ; rdata_times_ratio[7] = rdata_s_inf_reg[63:56] ;rdata_times_ratio[11] = rdata_s_inf_reg[95:88] ; rdata_times_ratio[15] = rdata_s_inf_reg[127:120] ;
            end
            3:begin
                rdata_times_ratio[0] = rdata_s_inf_reg[7]  ? 8'hFF : rdata_s_inf_reg[7:0]   << 1; rdata_times_ratio[4] = rdata_s_inf_reg[39] ? 8'hFF : rdata_s_inf_reg[39:32] << 1 ;rdata_times_ratio[8] = rdata_s_inf_reg[71] ? 8'hFF : rdata_s_inf_reg[71:64]  << 1; rdata_times_ratio[12] = rdata_s_inf_reg[103] ? 8'hFF : rdata_s_inf_reg[103:96]  << 1;
                rdata_times_ratio[1] = rdata_s_inf_reg[15] ? 8'hFF : rdata_s_inf_reg[15:8]  << 1; rdata_times_ratio[5] = rdata_s_inf_reg[47] ? 8'hFF : rdata_s_inf_reg[47:40] << 1 ;rdata_times_ratio[9] = rdata_s_inf_reg[79] ? 8'hFF : rdata_s_inf_reg[79:72]  << 1; rdata_times_ratio[13] = rdata_s_inf_reg[111] ? 8'hFF : rdata_s_inf_reg[111:104] << 1;
                rdata_times_ratio[2] = rdata_s_inf_reg[23] ? 8'hFF : rdata_s_inf_reg[23:16] << 1; rdata_times_ratio[6] = rdata_s_inf_reg[55] ? 8'hFF : rdata_s_inf_reg[55:48] << 1 ;rdata_times_ratio[10] = rdata_s_inf_reg[87] ? 8'hFF : rdata_s_inf_reg[87:80] << 1; rdata_times_ratio[14] = rdata_s_inf_reg[119] ? 8'hFF : rdata_s_inf_reg[119:112] << 1;
                rdata_times_ratio[3] = rdata_s_inf_reg[31] ? 8'hFF : rdata_s_inf_reg[31:24] << 1; rdata_times_ratio[7] = rdata_s_inf_reg[63] ? 8'hFF : rdata_s_inf_reg[63:56] << 1 ;rdata_times_ratio[11] = rdata_s_inf_reg[95] ? 8'hFF : rdata_s_inf_reg[95:88] << 1; rdata_times_ratio[15] = rdata_s_inf_reg[127] ? 8'hFF : rdata_s_inf_reg[127:120] << 1;
            end
            default:begin
                rdata_times_ratio[0] = 0; rdata_times_ratio[4] = 0; rdata_times_ratio[8]  = 0; rdata_times_ratio[12] = 0;
                rdata_times_ratio[1] = 0; rdata_times_ratio[5] = 0; rdata_times_ratio[9]  = 0; rdata_times_ratio[13] = 0;
                rdata_times_ratio[2] = 0; rdata_times_ratio[6] = 0; rdata_times_ratio[10] = 0; rdata_times_ratio[14] = 0;
                rdata_times_ratio[3] = 0; rdata_times_ratio[7] = 0; rdata_times_ratio[11] = 0; rdata_times_ratio[15] = 0;
            end 
        endcase
    end
    always @(posedge clk ) begin
            for(i = 0; i < 16; i = i + 1) begin
                rdata_times_ratio_reg[i] <= rdata_times_ratio[i];
            end
    end
//============================================================
// Auto Focus 
//============================================================
//rdata_after_shift
    always @(*) begin
        rdata_after_shift[0] = 0;
        rdata_after_shift[1] = 0;
        rdata_after_shift[2] = 0;
        case (in_ratio_mode_reg)
            0:begin
                rdata_after_shift[0] = cnt_2_cycle ? rdata_s_inf_reg[7:0]   >> 2 : rdata_s_inf_reg[111:104] >> 2;
                rdata_after_shift[1] = cnt_2_cycle ? rdata_s_inf_reg[15:8]  >> 2 : rdata_s_inf_reg[119:112] >> 2;
                rdata_after_shift[2] = cnt_2_cycle ? rdata_s_inf_reg[23:16] >> 2 : rdata_s_inf_reg[127:120] >> 2;
            end
            1:begin
                rdata_after_shift[0] = cnt_2_cycle ? rdata_s_inf_reg[7:0]   >> 1 : rdata_s_inf_reg[111:104] >> 1;
                rdata_after_shift[1] = cnt_2_cycle ? rdata_s_inf_reg[15:8]  >> 1 : rdata_s_inf_reg[119:112] >> 1;
                rdata_after_shift[2] = cnt_2_cycle ? rdata_s_inf_reg[23:16] >> 1 : rdata_s_inf_reg[127:120] >> 1;
            end
            2:begin
                rdata_after_shift[0] = cnt_2_cycle ? rdata_s_inf_reg[7:0]   : rdata_s_inf_reg[111:104] ;
                rdata_after_shift[1] = cnt_2_cycle ? rdata_s_inf_reg[15:8]  : rdata_s_inf_reg[119:112] ;
                rdata_after_shift[2] = cnt_2_cycle ? rdata_s_inf_reg[23:16] : rdata_s_inf_reg[127:120] ;
            end
            3:begin
                if(cnt_2_cycle)begin
                    rdata_after_shift[0] = rdata_s_inf_reg[7]  ? 'd255 : rdata_s_inf_reg[7:0]   << 1;
                    rdata_after_shift[1] = rdata_s_inf_reg[15] ? 'd255 : rdata_s_inf_reg[15:8]  << 1;
                    rdata_after_shift[2] = rdata_s_inf_reg[23] ? 'd255 : rdata_s_inf_reg[23:16] << 1;
                end
                else begin
                    rdata_after_shift[0] = rdata_s_inf_reg[111] ? 'd255 : rdata_s_inf_reg[111:104] << 1;
                    rdata_after_shift[1] = rdata_s_inf_reg[119] ? 'd255 : rdata_s_inf_reg[119:112] << 1;
                    rdata_after_shift[2] = rdata_s_inf_reg[127] ? 'd255 : rdata_s_inf_reg[127:120] << 1;
                end
            end 
        endcase
    end
//AF reg
    always @(posedge clk) begin
        if(cs_isp == IDLE) begin
            for(i = 0; i < 6; i = i + 1) begin
                for(j = 0; j < 6; j = j + 1) begin
                    Autofocus_reg[i][j] <= 0;
                end
            end
        end
        else if(do_focus_accumulation) begin
            if(cnt_2_cycle) begin
                if(cnt_rgb[0])begin
                    // Autofocus_reg[5][3] <= Autofocus_reg[0][3] + (rdata_s_inf_reg[7:0]   >> 1);
                    // Autofocus_reg[5][4] <= Autofocus_reg[0][4] + (rdata_s_inf_reg[15:8]  >> 1);
                    // Autofocus_reg[5][5] <= Autofocus_reg[0][5] + (rdata_s_inf_reg[23:16] >> 1);
                    Autofocus_reg[5][3] <= Autofocus_reg[0][3] + (rdata_after_shift[0] >> 1);
                    Autofocus_reg[5][4] <= Autofocus_reg[0][4] + (rdata_after_shift[1] >> 1);
                    Autofocus_reg[5][5] <= Autofocus_reg[0][5] + (rdata_after_shift[2] >> 1);
                end
                else begin
                    Autofocus_reg[5][3] <= Autofocus_reg[0][3] + (rdata_after_shift[0] >> 2);
                    Autofocus_reg[5][4] <= Autofocus_reg[0][4] + (rdata_after_shift[1] >> 2);
                    Autofocus_reg[5][5] <= Autofocus_reg[0][5] + (rdata_after_shift[2] >> 2);
                end
                for(i = 0; i < 5; i = i + 1) begin
                    for(j = 3; j < 6; j = j + 1) begin
                        Autofocus_reg[i][j] <= Autofocus_reg[i+1][j];
                    end
                end
            end
            else begin
                if(cnt_rgb[0])begin
                    Autofocus_reg[5][0] <= Autofocus_reg[0][0] + (rdata_after_shift[0] >> 1);
                    Autofocus_reg[5][1] <= Autofocus_reg[0][1] + (rdata_after_shift[1] >> 1);
                    Autofocus_reg[5][2] <= Autofocus_reg[0][2] + (rdata_after_shift[2] >> 1);
                end
                else begin
                    // Autofocus_reg[5][0] <= Autofocus_reg[0][0] + (rdata_s_inf_reg[111:104] >> 2);
                    // Autofocus_reg[5][1] <= Autofocus_reg[0][1] + (rdata_s_inf_reg[119:112] >> 2);
                    // Autofocus_reg[5][2] <= Autofocus_reg[0][2] + (rdata_s_inf_reg[127:120] >> 2);
                    Autofocus_reg[5][0] <= Autofocus_reg[0][0] + (rdata_after_shift[0] >> 2);
                    Autofocus_reg[5][1] <= Autofocus_reg[0][1] + (rdata_after_shift[1] >> 2);
                    Autofocus_reg[5][2] <= Autofocus_reg[0][2] + (rdata_after_shift[2] >> 2);
                end
                for(i = 0; i < 5; i = i + 1) begin
                    for(j = 0; j < 3; j = j + 1) begin
                        Autofocus_reg[i][j] <= Autofocus_reg[i+1][j];
                    end
                end
            end
        end
        else if(do_upper_shift_focus_reg) begin
            for(i = 0; i < 5; i = i + 1) begin
                for(j = 0; j < 6; j = j + 1) begin
                    Autofocus_reg[i][j] <= Autofocus_reg[i+1][j];
                end
            end
            for(j = 0; j < 6; j = j + 1) begin
                Autofocus_reg[5][j] <= Autofocus_reg[0][j];
            end
        end
        else if(do_left_shift_focus_reg) begin
            for(i = 0; i < 6; i = i + 1) begin
                for(j = 0; j < 5; j = j + 1) begin
                    Autofocus_reg[i][j] <= Autofocus_reg[i][j+1];
                end
            end
            for(i = 0; i < 6; i = i + 1) begin
                Autofocus_reg[i][5] <= Autofocus_reg[i][0];
            end
        end
    end
//Calculate Differece Reg...............................................
    reg  [7:0] cmp_in_1_1, cmp_in_1_2, cmp_in_2_1, cmp_in_2_2, cmp_in_3_1, cmp_in_3_2, cmp_in_4_1, cmp_in_4_2, cmp_in_5_1, cmp_in_5_2;
    wire [7:0] cmp_out_1_1, cmp_out_1_2;
    wire [7:0] cmp_out_2_1, cmp_out_2_2;
    wire [7:0] cmp_out_3_1, cmp_out_3_2;
    wire [7:0] cmp_out_4_1, cmp_out_4_2;
    wire [7:0] cmp_out_5_1, cmp_out_5_2;

    wire [7:0] sub_1_out, sub_2_out, sub_3_out, sub_4_out, sub_5_out;
//comparator
    assign cmp_out_1_1 = (cmp_in_1_1 > cmp_in_1_2) ? cmp_in_1_1 : cmp_in_1_2;
    assign cmp_out_1_2 = (cmp_in_1_1 > cmp_in_1_2) ? cmp_in_1_2 : cmp_in_1_1;
    assign cmp_out_2_1 = (cmp_in_2_1 > cmp_in_2_2) ? cmp_in_2_1 : cmp_in_2_2;
    assign cmp_out_2_2 = (cmp_in_2_1 > cmp_in_2_2) ? cmp_in_2_2 : cmp_in_2_1;
    assign cmp_out_3_1 = (cmp_in_3_1 > cmp_in_3_2) ? cmp_in_3_1 : cmp_in_3_2;
    assign cmp_out_3_2 = (cmp_in_3_1 > cmp_in_3_2) ? cmp_in_3_2 : cmp_in_3_1;
    assign cmp_out_4_1 = (cmp_in_4_1 > cmp_in_4_2) ? cmp_in_4_1 : cmp_in_4_2;
    assign cmp_out_4_2 = (cmp_in_4_1 > cmp_in_4_2) ? cmp_in_4_2 : cmp_in_4_1;
    assign cmp_out_5_1 = (cmp_in_5_1 > cmp_in_5_2) ? cmp_in_5_1 : cmp_in_5_2;
    assign cmp_out_5_2 = (cmp_in_5_1 > cmp_in_5_2) ? cmp_in_5_2 : cmp_in_5_1;

    reg[7:0] cmp_out_1_1_reg;
    reg[7:0] cmp_out_1_2_reg;
    reg[7:0] cmp_out_2_1_reg;
    reg[7:0] cmp_out_2_2_reg;
    reg[7:0] cmp_out_3_1_reg;
    reg[7:0] cmp_out_3_2_reg;
    reg[7:0] cmp_out_4_1_reg;
    reg[7:0] cmp_out_4_2_reg;
    reg[7:0] cmp_out_5_1_reg;
    reg[7:0] cmp_out_5_2_reg;

    always @(posedge clk ) begin
        cmp_out_1_1_reg <= cmp_out_1_1;
        cmp_out_1_2_reg <= cmp_out_1_2;
        cmp_out_2_1_reg <= cmp_out_2_1;
        cmp_out_2_2_reg <= cmp_out_2_2;
        cmp_out_3_1_reg <= cmp_out_3_1;
        cmp_out_3_2_reg <= cmp_out_3_2;
        cmp_out_4_1_reg <= cmp_out_4_1;
        cmp_out_4_2_reg <= cmp_out_4_2;
        cmp_out_5_1_reg <= cmp_out_5_1;
        cmp_out_5_2_reg <= cmp_out_5_2;
    end 
//subtractor
    assign sub_1_out = cmp_out_1_1_reg - cmp_out_1_2_reg;
    assign sub_2_out = cmp_out_2_1_reg - cmp_out_2_2_reg;
    assign sub_3_out = cmp_out_3_1_reg - cmp_out_3_2_reg;
    assign sub_4_out = cmp_out_4_1_reg - cmp_out_4_2_reg;
    assign sub_5_out = cmp_out_5_1_reg - cmp_out_5_2_reg;
//cmp_in
    always @(*) begin
        cmp_in_1_1 = 0;
        cmp_in_1_2 = 0;
        cmp_in_2_1 = 0;
        cmp_in_2_2 = 0;
        cmp_in_3_1 = 0;
        cmp_in_3_2 = 0;
        cmp_in_4_1 = 0;
        cmp_in_4_2 = 0;
        cmp_in_5_1 = 0;
        cmp_in_5_2 = 0;
        if(do_upper_shift_focus_reg)begin
            cmp_in_1_1 = Autofocus_reg[5][0];
            cmp_in_1_2 = Autofocus_reg[5][1];
            cmp_in_2_1 = Autofocus_reg[5][1];
            cmp_in_2_2 = Autofocus_reg[5][2];
            cmp_in_3_1 = Autofocus_reg[5][2];
            cmp_in_3_2 = Autofocus_reg[5][3];
            cmp_in_4_1 = Autofocus_reg[5][3];
            cmp_in_4_2 = Autofocus_reg[5][4];
            cmp_in_5_1 = Autofocus_reg[5][4];
            cmp_in_5_2 = Autofocus_reg[5][5];
        end
        else if(do_left_shift_focus_reg)begin
            cmp_in_1_1 = Autofocus_reg[0][0];
            cmp_in_1_2 = Autofocus_reg[1][0];
            cmp_in_2_1 = Autofocus_reg[1][0];
            cmp_in_2_2 = Autofocus_reg[2][0];
            cmp_in_3_1 = Autofocus_reg[2][0];
            cmp_in_3_2 = Autofocus_reg[3][0];
            cmp_in_4_1 = Autofocus_reg[3][0];
            cmp_in_4_2 = Autofocus_reg[4][0];
            cmp_in_5_1 = Autofocus_reg[4][0];
            cmp_in_5_2 = Autofocus_reg[5][0];
        end
    end
//pipe
    reg [7:0] sub_out[0:4];
    always @(posedge clk ) begin
        sub_out[0] <= sub_1_out;
        sub_out[1] <= sub_2_out;
        sub_out[2] <= sub_3_out;
        sub_out[3] <= sub_4_out;
        sub_out[4] <= sub_5_out;
    end
//stored data into D2x2, D4x4, D6x6...............................................
    wire [9:0] add_diff_1_out;
    wire [8:0] add_diff_2_out;
    wire [13:0] add_diff_out; 
    assign add_diff_1_out = sub_out[1] + sub_out[2] + sub_out[3]; ;
    assign add_diff_2_out = sub_out[0] + sub_out[4];
    assign add_diff_out = add_diff_1_out + add_diff_2_out + D6x6;

    always @(posedge clk ) begin
        if(cs_isp == IDLE)
            D2x2 <= 0;
        else if(do_cal_difference && (cnt_func == 43 || cnt_func == 44 || cnt_func == 48 || cnt_func == 49))begin
            D2x2 <= D2x2 + sub_out[2];
        end
    end
    always @(posedge clk ) begin
        if(cs_isp == IDLE)
            D4x4 <= 0;
        else if(do_cal_difference && (cnt_func == 42 || cnt_func == 43 || cnt_func == 44 || cnt_func == 45 || cnt_func == 47 || cnt_func == 48 || cnt_func == 49 || cnt_func == 50))begin
                D4x4 <= D4x4 + add_diff_1_out;
        end
    end
    always @(posedge clk ) begin
        if(cs_isp == IDLE)
            D6x6 <= 0;
        else if(do_cal_difference)begin
            D6x6 <= add_diff_out;
        end
    end
//Calculate Max_Contrast...............................................
    wire [9:0] D2x2_cal;
    wire [12:0] D4x4_cal;
    reg  [8:0] D6x6_cal;

    assign D2x2_cal = D2x2 >> 2;
    assign D4x4_cal = D4x4 >> 4;
    // assign D6x6_cal = (D6x6 >> 2)/9;
    always @(posedge clk ) begin
        D6x6_cal <= (D6x6 >> 2)/9;
    end

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
    generate
        for(g = 0;g < 16;g = g + 1)begin:focus_result
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    focus_result_reg[g] <= 0;
                else if(focus_done)begin
                    if(in_pic_no_reg == g)
                        focus_result_reg[g] <= max_contrast;
                end
            end
        end
    endgenerate
//============================================================
// Auto Exposure
//============================================================
// wire [6:0] add_for_avg_in1, add_for_avg_in2, add_for_avg_in3, add_for_avg_in4, add_for_avg_in5, add_for_avg_in6, add_for_avg_in7, add_for_avg_in8;
// wire [6:0] add_for_avg_in9, add_for_avg_in10, add_for_avg_in11, add_for_avg_in12, add_for_avg_in13, add_for_avg_in14, add_for_avg_in15, add_for_avg_in16;
    reg [7:0] add_for_avg_out1, add_for_avg_out2, add_for_avg_out3, add_for_avg_out4, add_for_avg_out5, add_for_avg_out6, add_for_avg_out7, add_for_avg_out8;

    always @(*) begin
        if(cnt_rgb[0])begin
            add_for_avg_out1 = (rdata_times_ratio[0]  >> 1) + (rdata_times_ratio[1]  >> 1);
            add_for_avg_out2 = (rdata_times_ratio[2]  >> 1) + (rdata_times_ratio[3]  >> 1);
            add_for_avg_out3 = (rdata_times_ratio[4]  >> 1) + (rdata_times_ratio[5]  >> 1);
            add_for_avg_out4 = (rdata_times_ratio[6]  >> 1) + (rdata_times_ratio[7]  >> 1);
            add_for_avg_out5 = (rdata_times_ratio[8]  >> 1) + (rdata_times_ratio[9]  >> 1);
            add_for_avg_out6 = (rdata_times_ratio[10] >> 1) + (rdata_times_ratio[11] >> 1);
            add_for_avg_out7 = (rdata_times_ratio[12] >> 1) + (rdata_times_ratio[13] >> 1);
            add_for_avg_out8 = (rdata_times_ratio[14] >> 1) + (rdata_times_ratio[15] >> 1);
        end
        else begin
            add_for_avg_out1 = (rdata_times_ratio[0]  >> 2) + (rdata_times_ratio[1]  >> 2);
            add_for_avg_out2 = (rdata_times_ratio[2]  >> 2) + (rdata_times_ratio[3]  >> 2);
            add_for_avg_out3 = (rdata_times_ratio[4]  >> 2) + (rdata_times_ratio[5]  >> 2);
            add_for_avg_out4 = (rdata_times_ratio[6]  >> 2) + (rdata_times_ratio[7]  >> 2);
            add_for_avg_out5 = (rdata_times_ratio[8]  >> 2) + (rdata_times_ratio[9]  >> 2);
            add_for_avg_out6 = (rdata_times_ratio[10] >> 2) + (rdata_times_ratio[11] >> 2);
            add_for_avg_out7 = (rdata_times_ratio[12] >> 2) + (rdata_times_ratio[13] >> 2);
            add_for_avg_out8 = (rdata_times_ratio[14] >> 2) + (rdata_times_ratio[15] >> 2);
        end
    end

    wire [8:0] add_for_avg_n2_out1, add_for_avg_n2_out2, add_for_avg_n2_out3, add_for_avg_n2_out4;

    assign add_for_avg_n2_out1 = add_for_avg_out1 + add_for_avg_out2;
    assign add_for_avg_n2_out2 = add_for_avg_out3 + add_for_avg_out4;
    assign add_for_avg_n2_out3 = add_for_avg_out5 + add_for_avg_out6;
    assign add_for_avg_n2_out4 = add_for_avg_out7 + add_for_avg_out8;

    always @(posedge clk ) begin
        avg_pipe_reg[0] <= add_for_avg_n2_out1;
        avg_pipe_reg[1] <= add_for_avg_n2_out2;
        avg_pipe_reg[2] <= add_for_avg_n2_out3;
        avg_pipe_reg[3] <= add_for_avg_n2_out4;
    end

    wire [9:0] add_for_avg_n3_out1, add_for_avg_n3_out2;

    assign add_for_avg_n3_out1 = avg_pipe_reg[0] + avg_pipe_reg[1];
    assign add_for_avg_n3_out2 = avg_pipe_reg[2] + avg_pipe_reg[3];

    wire [10:0] add_for_avg_n4_out;
    assign add_for_avg_n4_out = add_for_avg_n3_out1 + add_for_avg_n3_out2;
    //Avg_reg
        always @(posedge clk) begin
            if(cs_isp == IDLE)
                Avg_reg <= 18'd0;
            else if(cs_isp == FUNC)begin
                // if(cnt_rgb[0])begin
                //     Avg_reg <= Avg_reg + (rdata_times_ratio[0]>>1) + (rdata_times_ratio[1]>>1) + (rdata_times_ratio[2]>>1) + (rdata_times_ratio[3]>>1) + (rdata_times_ratio[4]>>1) + (rdata_times_ratio[5]>>1) + (rdata_times_ratio[6]>>1) + (rdata_times_ratio[7]>>1) + (rdata_times_ratio[8]>>1) + (rdata_times_ratio[9]>>1) + (rdata_times_ratio[10]>>1) + (rdata_times_ratio[11]>>1) + (rdata_times_ratio[12]>>1) + (rdata_times_ratio[13]>>1) + (rdata_times_ratio[14]>>1) + (rdata_times_ratio[15]>>1);  
                // end
                // else begin
                //     Avg_reg <= Avg_reg + (rdata_times_ratio[0]>>2) + (rdata_times_ratio[1]>>2) + (rdata_times_ratio[2]>>2) + (rdata_times_ratio[3]>>2) + (rdata_times_ratio[4]>>2) + (rdata_times_ratio[5]>>2) + (rdata_times_ratio[6]>>2) + (rdata_times_ratio[7]>>2) + (rdata_times_ratio[8]>>2) + (rdata_times_ratio[9]>>2) + (rdata_times_ratio[10]>>2) + (rdata_times_ratio[11]>>2) + (rdata_times_ratio[12]>>2) + (rdata_times_ratio[13]>>2) + (rdata_times_ratio[14]>>2) + (rdata_times_ratio[15]>>2);
                // end
                Avg_reg <= Avg_reg + add_for_avg_n4_out;
            end
        end
    //exposure_result_reg
        generate
            for(g = 0; g < 16; g = g + 1)begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)
                        exposure_result_reg[g] <= 8'd0;
                    else if(cs_isp == FUNC && in_mode_reg[0])begin
                        if(in_pic_no_reg == g)
                            exposure_result_reg[g] <= Avg_reg[17:10];
                    end
                end
            end
        endgenerate
//============================================================
// Exposure Check 
//============================================================
//exposure_detect
    always @(*) begin
        exposure_detect = 0;
        case (in_pic_no_reg)
            'd0 : exposure_detect = exposure_check_flag[0]  ;
            'd1 : exposure_detect = exposure_check_flag[1]  ;
            'd2 : exposure_detect = exposure_check_flag[2]  ;
            'd3 : exposure_detect = exposure_check_flag[3]  ;
            'd4 : exposure_detect = exposure_check_flag[4]  ;
            'd5 : exposure_detect = exposure_check_flag[5]  ;
            'd6 : exposure_detect = exposure_check_flag[6]  ;
            'd7 : exposure_detect = exposure_check_flag[7]  ;
            'd8 : exposure_detect = exposure_check_flag[8]  ;
            'd9 : exposure_detect = exposure_check_flag[9]  ;
            'd10: exposure_detect = exposure_check_flag[10] ;
            'd11: exposure_detect = exposure_check_flag[11] ;
            'd12: exposure_detect = exposure_check_flag[12] ;
            'd13: exposure_detect = exposure_check_flag[13] ;
            'd14: exposure_detect = exposure_check_flag[14] ;
            'd15: exposure_detect = exposure_check_flag[15] ;
        endcase
    end
//exposure_check_flag
    generate
        for(g = 0;g < 16;g = g + 1)begin:exposure_check
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    exposure_check_flag[g] <= 0;
                else if(in_mode_reg[0] && func_done)begin
                    if(in_pic_no_reg == g)
                        exposure_check_flag[g] <= 1;
                end
            end
        end
    endgenerate
//============================================================
// Picture Check
//============================================================
    always @(*) begin
        picture_detect = 0;
        case (in_pic_no_reg)
            'd0 : picture_detect = picture_check_flag[0]  ;
            'd1 : picture_detect = picture_check_flag[1]  ;
            'd2 : picture_detect = picture_check_flag[2]  ;
            'd3 : picture_detect = picture_check_flag[3]  ;
            'd4 : picture_detect = picture_check_flag[4]  ;
            'd5 : picture_detect = picture_check_flag[5]  ;
            'd6 : picture_detect = picture_check_flag[6]  ;
            'd7 : picture_detect = picture_check_flag[7]  ;
            'd8 : picture_detect = picture_check_flag[8]  ;
            'd9 : picture_detect = picture_check_flag[9]  ;
            'd10: picture_detect = picture_check_flag[10] ;
            'd11: picture_detect = picture_check_flag[11] ;
            'd12: picture_detect = picture_check_flag[12] ;
            'd13: picture_detect = picture_check_flag[13] ;
            'd14: picture_detect = picture_check_flag[14] ;
            'd15: picture_detect = picture_check_flag[15] ; 
        endcase
    end
    generate
        for(g = 0;g < 16;g = g + 1)begin:picture_check
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    picture_check_flag[g] <= 0;
                else if(func_done)begin
                    if(in_pic_no_reg == g)
                        picture_check_flag[g] <= 1;
                end
            end
        end
    endgenerate
//============================================================
// Auto Max and Min
//============================================================
    find_max_min u_find_max_min(.clk(clk),
        .in1(rdata_times_ratio[0]), .in2(rdata_times_ratio[1]), .in3(rdata_times_ratio[2]), .in4(rdata_times_ratio[3]), 
        .in5(rdata_times_ratio[4]), .in6(rdata_times_ratio[5]), .in7(rdata_times_ratio[6]), .in8(rdata_times_ratio[7]), 
        .in9(rdata_times_ratio[8]), .in10(rdata_times_ratio[9]), .in11(rdata_times_ratio[10]), .in12(rdata_times_ratio[11]), 
        .in13(rdata_times_ratio[12]), .in14(rdata_times_ratio[13]), .in15(rdata_times_ratio[14]), .in16(rdata_times_ratio[15]), 
        .out_max(find_max), .out_min(find_min)
    );
    always @(*) begin
        if(cnt_func == 2)begin
            max_in = 0;
            min_in = 255;
        end
        else begin
            max_in = max_result_reg;
            min_in = min_result_reg;
        end
    end
    always @(posedge clk ) begin
        find_max_reg <= find_max;
        find_min_reg <= find_min;
    end
    cmp2 u_cmp_max(.in1(max_in), .in2(find_max_reg), .out1(cmp_1_max_out), .out2(cmp_1_min_out));
    cmp2 u_cmp_min(.in1(min_in), .in2(find_min_reg), .out1(cmp_2_max_out), .out2(cmp_2_min_out));
    always @(posedge clk ) begin
        if(cnt_rgb == 3 && cnt_func == 3)begin
            max_result_reg <= avg_max_divide_3;
            min_result_reg <= avg_min_divide_3;
        end
        else begin
            max_result_reg <= cmp_1_max_out;
            min_result_reg <= cmp_2_min_out;
        end
    end
    always @(posedge clk ) begin
        if(cs_isp == IDLE)begin
            avg_max_reg <= 0;
            avg_min_reg <= 0;
        end
        else if(cs_isp == FUNC && cnt_func == 2 && cnt_rgb != 0)begin
            avg_max_reg <= avg_max_reg + max_result_reg;
            avg_min_reg <= avg_min_reg + min_result_reg;
        end
    end
    assign avg_max_divide_3 = avg_max_reg / 3;
    assign avg_min_divide_3 = avg_min_reg / 3;


    assign max_min_result = max_result_reg + min_result_reg;
    //max_min_result_reg
        generate
            for(g = 0; g < 16; g = g + 1)begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)
                        max_min_result_reg[g] <= 8'd0;
                    else if(am_done)begin
                        if(in_pic_no_reg == g)
                            max_min_result_reg[g] <= max_min_result >> 1;
                    end
                end
            end
        endgenerate
//============================================================
// Zero Detector
//============================================================
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
    generate
        for(g = 0;g < 16;g = g + 1)begin:zero_detector
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    zero_detect_reg[g] <= 0;
                else if(cs_dram == W_DATA && ns_dram == IDLE)begin
                    if(in_pic_no_reg == g)
                        zero_detect_reg[g] <= ~zero_detect_reg[g];
                end
                else if(in_mode_reg[0] && cs_dram == W_DATA)begin
                    if(in_pic_no_reg == g)begin
                        if(zero_detect_reg[g] == 1)
                            zero_detect_reg[g] <= 1;
                        else if((zero_detect_reg[g] == 0) && (write_data_buffer[0][15] != 0) || (write_data_buffer[0][14] != 0) || (write_data_buffer[0][13] != 0) || (write_data_buffer[0][12] != 0) || (write_data_buffer[0][11] != 0) || (write_data_buffer[0][10] != 0) || (write_data_buffer[0][9] != 0) || (write_data_buffer[0][8] != 0) || (write_data_buffer[0][7] != 0) || (write_data_buffer[0][6] != 0) || (write_data_buffer[0][5] != 0) || (write_data_buffer[0][4] != 0) || (write_data_buffer[0][3] != 0) || (write_data_buffer[0][2] != 0) || (write_data_buffer[0][1] != 0) || (write_data_buffer[0][0] != 0))
                            zero_detect_reg[g] <= 1;
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
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        out_data_sel <= 0;
    else if(ns_isp == OUT)begin
        if(zero_detect)
            out_data_sel <= 0;
        else begin
            case (in_mode_reg)
                'd0: out_data_sel <= focus_result_reg[in_pic_no_reg];
                'd1: out_data_sel <= exposure_result_reg[in_pic_no_reg];
                'd2: out_data_sel <= max_min_result_reg[in_pic_no_reg];
            endcase
        end
    end
    else 
        out_data_sel <= 0;
end
endmodule

module cmp2 (
    in1, in2,
    out1, out2
);
    input [7:0] in1, in2;  
    output [7:0] out1, out2;

    assign out1 = (in1 > in2) ? in1 : in2;
    assign out2 = (in1 > in2) ? in2 : in1;
endmodule

module find_max_min (
    clk,
    in1, in2, in3, in4, in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16,
    out_max, out_min
);
    input clk;
    input [7:0] in1, in2, in3, in4, in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,in16;
    output [7:0] out_max, out_min;

    wire [7:0] cmp_1_out_max, cmp_1_out_min;
    wire [7:0] cmp_2_out_max, cmp_2_out_min;
    wire [7:0] cmp_3_out_max, cmp_3_out_min;
    wire [7:0] cmp_4_out_max, cmp_4_out_min;
    wire [7:0] cmp_5_out_max, cmp_5_out_min;
    wire [7:0] cmp_6_out_max, cmp_6_out_min;
    wire [7:0] cmp_7_out_max, cmp_7_out_min;
    wire [7:0] cmp_8_out_max, cmp_8_out_min;

    cmp2 cmp1 (in1, in2, cmp_1_out_max, cmp_1_out_min);
    cmp2 cmp2 (in3, in4, cmp_2_out_max, cmp_2_out_min);
    cmp2 cmp3 (in5, in6, cmp_3_out_max, cmp_3_out_min);
    cmp2 cmp4 (in7, in8, cmp_4_out_max, cmp_4_out_min);
    cmp2 cmp5 (in9, in10, cmp_5_out_max, cmp_5_out_min);
    cmp2 cmp6 (in11, in12, cmp_6_out_max, cmp_6_out_min);
    cmp2 cmp7 (in13, in14, cmp_7_out_max, cmp_7_out_min);
    cmp2 cmp8 (in15, in16, cmp_8_out_max, cmp_8_out_min);

    wire [7:0] cmp_9_out_max, cmp_9_out_min;
    wire [7:0] cmp_10_out_max, cmp_10_out_min;
    wire [7:0] cmp_11_out_max, cmp_11_out_min;
    wire [7:0] cmp_12_out_max, cmp_12_out_min;
    wire [7:0] cmp_13_out_max, cmp_13_out_min;
    wire [7:0] cmp_14_out_max, cmp_14_out_min;
    wire [7:0] cmp_15_out_max, cmp_15_out_min;
    wire [7:0] cmp_16_out_max, cmp_16_out_min;

    cmp2 cmp9 (cmp_1_out_max, cmp_2_out_max, cmp_9_out_max, cmp_9_out_min);
    cmp2 cmp10 (cmp_3_out_max, cmp_4_out_max, cmp_10_out_max, cmp_10_out_min);
    cmp2 cmp11 (cmp_5_out_max, cmp_6_out_max, cmp_11_out_max, cmp_11_out_min);
    cmp2 cmp12 (cmp_7_out_max, cmp_8_out_max, cmp_12_out_max, cmp_12_out_min);

    cmp2 cmp13 (cmp_1_out_min, cmp_2_out_min, cmp_13_out_max, cmp_13_out_min);
    cmp2 cmp14 (cmp_3_out_min, cmp_4_out_min, cmp_14_out_max, cmp_14_out_min);
    cmp2 cmp15 (cmp_5_out_min, cmp_6_out_min, cmp_15_out_max, cmp_15_out_min);
    cmp2 cmp16 (cmp_7_out_min, cmp_8_out_min, cmp_16_out_max, cmp_16_out_min);

    reg [7:0] max_reg[0:3];
    reg [7:0] min_reg[0:3];
    always @(posedge clk ) begin
        max_reg[0] <= cmp_9_out_max;
        max_reg[1] <= cmp_10_out_max;
        max_reg[2] <= cmp_11_out_max;
        max_reg[3] <= cmp_12_out_max;

        min_reg[0] <= cmp_13_out_min;
        min_reg[1] <= cmp_14_out_min;
        min_reg[2] <= cmp_15_out_min;
        min_reg[3] <= cmp_16_out_min;
    end

    wire [7:0] cmp_17_out_max, cmp_17_out_min;
    wire [7:0] cmp_18_out_max, cmp_18_out_min;
    wire [7:0] cmp_19_out_max, cmp_19_out_min;
    wire [7:0] cmp_20_out_max, cmp_20_out_min;

    cmp2 cmp17 (max_reg[0], max_reg[1], cmp_17_out_max, cmp_17_out_min);
    cmp2 cmp18 (max_reg[2], max_reg[3], cmp_18_out_max, cmp_18_out_min);

    cmp2 cmp19 (min_reg[0], min_reg[1], cmp_19_out_max, cmp_19_out_min);
    cmp2 cmp20 (min_reg[2], min_reg[3], cmp_20_out_max, cmp_20_out_min);

    wire [7:0] cmp_21_out_max, cmp_21_out_min;
    wire [7:0] cmp_22_out_max, cmp_22_out_min;

    cmp2 cmp21 (cmp_17_out_max, cmp_18_out_max, cmp_21_out_max, cmp_21_out_min);
    cmp2 cmp22 (cmp_19_out_min, cmp_20_out_min, cmp_22_out_max, cmp_22_out_min);

    assign out_max = cmp_21_out_max;
    assign out_min = cmp_22_out_min;
endmodule
