//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter OUT = 3'd3;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [6:0 ] count ,count_ns;
reg [31:0] Img_reg[0:24], Img_reg_ns[0:24];

reg [31:0] K_ch1_1_reg [0:3], K_ch1_1_reg_ns [0:3];
reg [31:0] K_ch1_2_reg [0:3], K_ch1_2_reg_ns [0:3];
reg [31:0] K_ch1_3_reg [0:3], K_ch1_3_reg_ns [0:3];

reg [31:0] K_ch2_1_reg [0:3], K_ch2_1_reg_ns [0:3];
reg [31:0] K_ch2_2_reg [0:3], K_ch2_2_reg_ns [0:3];
reg [31:0] K_ch2_3_reg [0:3], K_ch2_3_reg_ns [0:3];

reg [31:0] Weight_reg_1[0:7], Weight_reg_1_ns[0:7];
reg [31:0] Weight_reg_2[0:7], Weight_reg_2_ns[0:7];
reg [31:0] Weight_reg_3[0:7], Weight_reg_3_ns[0:7];
reg [31:0] Opt_reg, Opt_reg_ns;

reg [31:0] act_out_2_ns[0:3];
reg [31:0] act_out_1_ns[0:3];
reg [31:0] fc_out_1_ns, fc_out_2_ns, fc_out_3_ns;

reg [31:0] M1_in1, M1_in2, M1_in3, M1_in4;
reg [31:0] M2_in1, M2_in2, M2_in3, M2_in4;
reg [31:0] M1_3to1reg, M1_4to2reg;
reg [31:0] M1_3to1_sh_reg[1:0], M1_4to2_sh_reg[1:0];
reg [31:0] M2_3to1reg, M2_4to2reg;
reg [31:0] M2_3to1_sh_reg[1:0], M2_4to2_sh_reg[1:0];

reg [31:0] k1_sel_1, k1_sel_2, k1_sel_3, k1_sel_4;
reg [31:0] k2_sel_1, k2_sel_2, k2_sel_3, k2_sel_4;

reg [31:0] p_sum_1_1_1, p_sum_1_1_2, p_sum_1_1_3, p_sum_1_1_4;
reg [31:0] p_sum_1_2_1, p_sum_1_2_2, p_sum_1_2_3, p_sum_1_2_4;
reg [31:0] p_sum_2_1_1, p_sum_2_1_2, p_sum_2_1_3, p_sum_2_1_4;
reg [31:0] p_sum_2_2_1, p_sum_2_2_2, p_sum_2_2_3, p_sum_2_2_4;

reg [31:0] p_sum_1_1_1_reg, p_sum_1_1_2_reg, p_sum_1_1_3_reg, p_sum_1_1_4_reg;
reg [31:0] p_sum_1_2_1_reg, p_sum_1_2_2_reg, p_sum_1_2_3_reg, p_sum_1_2_4_reg;
reg [31:0] p_sum_2_1_1_reg, p_sum_2_1_2_reg, p_sum_2_1_3_reg, p_sum_2_1_4_reg;
reg [31:0] p_sum_2_2_1_reg, p_sum_2_2_2_reg, p_sum_2_2_3_reg, p_sum_2_2_4_reg;

reg [31:0] FM1[0:35], FM1_ns[0:35];
reg [31:0] FM2[0:35], FM2_ns[0:35];

reg [31:0] add_in_1, add_in_2;
reg [31:0] add_out_1_1, add_out_1_2, add_out_1_3, add_out_1_4;
reg [31:0] add_out_2_1, add_out_2_2, add_out_2_3, add_out_2_4;
reg [31:0] add_sel_1_1_1, add_sel_1_1_2, add_sel_1_1_3;
reg [31:0] add_sel_1_2_1, add_sel_1_2_2, add_sel_1_2_3;

reg [31:0] add_sel_1_1_0, add_sel_1_2_0;
reg [31:0] add_out_1_1_reg;

reg [31:0] add_in_3, add_in_4;
reg [31:0] add_out_3_1, add_out_3_2, add_out_3_3, add_out_3_4;
reg [31:0] add_out_4_1, add_out_4_2, add_out_4_3, add_out_4_4;
reg [31:0] add_sel_2_1_1, add_sel_2_1_2, add_sel_2_1_3;
reg [31:0] add_sel_2_2_1, add_sel_2_2_2, add_sel_2_2_3;

reg [31:0] cmp_in_1_1, cmp_in_1_2, cmp_in_1_3, cmp_in_1_4;
reg [31:0] cmp_out_1_1, cmp_out_1_2;
reg [31:0] cmp_out_1_1_reg, cmp_out_1_2_reg;

reg [31:0] act_in_1[0:3], act_in_1_ns[0:3];

reg [31:0] cmp_in_2_1, cmp_in_2_2, cmp_in_2_3, cmp_in_2_4;
reg [31:0] cmp_out_2_1, cmp_out_2_2;
reg [31:0] cmp_out_2_1_reg, cmp_out_2_2_reg;

reg [31:0] act_in_2[0:3], act_in_2_ns[0:3];

reg [31:0] exp_in_1, exp_out_1, exp_out_1_reg;
reg [31:0] add_act_in_1_1, add_act_in_1_2;
reg [31:0] add_act_out_1_1, add_act_out_1_2;
reg [31:0] add_act_out_1_1_reg, add_act_out_1_2_reg;
reg [31:0] div_in_1_1, div_in_1_2, div_out_1, div_out_1_reg;

reg [31:0] exp_in_2, exp_out_2, exp_out_2_reg;
reg [31:0] add_act_in_2_1, add_act_in_2_2;
reg [31:0] add_act_out_2_1, add_act_out_2_2;
reg [31:0] add_act_out_2_1_reg, add_act_out_2_2_reg;
reg [31:0] div_in_2_1, div_in_2_2, div_out_2, div_out_2_reg;

reg [31:0] sm_1, sm_2, sm_3;
// reg [31:0] sm_1_reg, sm_2_reg, sm_3_reg;
//=====================================================================
//   parameter and interger
//=====================================================================
parameter FP_min = 32'b11111111011111111111111111111111;
integer i;
//=====================================================================
//   Counter
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count <= 'd0;
    else 
        count <= count_ns;
end
always @(*) begin
    if(count=='d0 && !in_valid)
        count_ns = 'd0;
    else if(count=='d90)
        count_ns = 'd0;
    else
        count_ns = count + 1;
end
//=====================================================================
//   cnt_Img
//=====================================================================
reg [6:0] cnt_Img, cnt_Img_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_Img <= 'd0;
    else 
        cnt_Img <= cnt_Img_ns;
end
always @(*) begin
    if(cnt_Img=='d0 && !in_valid)
        cnt_Img_ns = 'd0;
    else if(cnt_Img=='d90)
        cnt_Img_ns = 'd0;
    else
        cnt_Img_ns = cnt_Img + 1;
end
//=====================================================================
//   cnt_Kernel
//=====================================================================
reg [6:0] cnt_Kernel, cnt_Kernel_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_Kernel <= 'd0;
    else 
        cnt_Kernel <= cnt_Kernel_ns;
end
always @(*) begin
    if(cnt_Kernel=='d0 && !in_valid)
        cnt_Kernel_ns = 'd0;
    else if(cnt_Kernel=='d90)
        cnt_Kernel_ns = 'd0;
    else
        cnt_Kernel_ns = cnt_Kernel + 1;
end
//=====================================================================
//   cnt_Weight
//=====================================================================
reg [6:0] cnt_Weight, cnt_Weight_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_Weight <= 'd0;
    else 
        cnt_Weight <= cnt_Weight_ns;
end
always @(*) begin
    if(cnt_Weight=='d0 && !in_valid)
        cnt_Weight_ns = 'd0;
    else if(cnt_Weight=='d90)
        cnt_Weight_ns = 'd0;
    else
        cnt_Weight_ns = cnt_Weight + 1;
end
//=====================================================================
//   cnt_M1
//=====================================================================
reg [6:0] cnt_M1, cnt_M1_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_M1 <= 'd0;
    else 
        cnt_M1 <= cnt_M1_ns;
end
always @(*) begin
    if(cnt_M1=='d0 && !in_valid)
        cnt_M1_ns = 'd0;
    else if(cnt_M1=='d90)
        cnt_M1_ns = 'd0;
    else
        cnt_M1_ns = cnt_M1 + 1;
end
//=====================================================================
//   cnt_M2
//=====================================================================
reg [6:0] cnt_M2, cnt_M2_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_M2 <= 'd0;
    else 
        cnt_M2 <= cnt_M2_ns;
end
always @(*) begin
    if(cnt_M2=='d0 && !in_valid)
        cnt_M2_ns = 'd0;
    else if(cnt_M2=='d90)
        cnt_M2_ns = 'd0;
    else
        cnt_M2_ns = cnt_M2 + 1;
end
//=====================================================================
//   cnt_FM1
//=====================================================================
reg [6:0] cnt_FM1, cnt_FM1_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_FM1 <= 'd0;
    else 
        cnt_FM1 <= cnt_FM1_ns;
end
always @(*) begin
    if(cnt_FM1=='d0 && !in_valid)
        cnt_FM1_ns = 'd0;
    else if(cnt_FM1=='d90)
        cnt_FM1_ns = 'd0;
    else
        cnt_FM1_ns = cnt_FM1 + 1;
end
//=====================================================================
//   cnt_FM2
//=====================================================================
reg [6:0] cnt_FM2, cnt_FM2_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_FM2 <= 'd0;
    else 
        cnt_FM2 <= cnt_FM2_ns;
end
always @(*) begin
    if(cnt_FM2=='d0 && !in_valid)
        cnt_FM2_ns = 'd0;
    else if(cnt_FM2=='d90)
        cnt_FM2_ns = 'd0;
    else
        cnt_FM2_ns = cnt_FM2 + 1;
end
//=====================================================================
//   cnt_Maxpool
//=====================================================================
reg [6:0] cnt_Maxpool, cnt_Maxpool_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_Maxpool <= 'd0;
    else 
        cnt_Maxpool <= cnt_Maxpool_ns;
end
always @(*) begin
    if(cnt_Maxpool=='d0 && !in_valid)
        cnt_Maxpool_ns = 'd0;
    else if(count=='d90)
        cnt_Maxpool_ns = 'd0;
    else
        cnt_Maxpool_ns = cnt_Maxpool + 1;
end
//=====================================================================
//   cnt_Act
//=====================================================================
reg [6:0] cnt_Act, cnt_Act_ns;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_Act <= 'd0;
    else 
        cnt_Act <= cnt_Act_ns;
end
always @(*) begin
    if(cnt_Act=='d0 && !in_valid)
        cnt_Act_ns = 'd0;
    else if(count=='d90)
        cnt_Act_ns = 'd0;
    else
        cnt_Act_ns = cnt_Act + 1;
end
//=====================================================================
//   Opt
//=====================================================================
always @(posedge clk ) begin
    Opt_reg <= Opt_reg_ns;
end
always @(*) begin
    Opt_reg_ns = (in_valid&&count=='d0) ? Opt : Opt_reg;
end
//=====================================================================
//   Img 
//   shared with activation output (0~7)
//   shared with fully connected (8~10)
//   shared with softmax (11~13)
//=====================================================================
always @(posedge clk ) begin
    for(i=0;i<25;i=i+1)
        Img_reg[i] <= Img_reg_ns[i];
end
always @(*) begin
    for(i=0;i<25;i=i+1)
        Img_reg_ns[i] = Img_reg[i];
    case (cnt_Img)
        'd0,'d25,'d50 : Img_reg_ns[0] = Img;'d13,'d38,'d63 : Img_reg_ns[13] = Img;
        'd1,'d26,'d51 : Img_reg_ns[1] = Img;'d14,'d39,'d64 : Img_reg_ns[14] = Img;
        'd2,'d27,'d52 : Img_reg_ns[2] = Img;'d15,'d40,'d65 : Img_reg_ns[15] = Img;
        'd3,'d28,'d53 : Img_reg_ns[3] = Img;'d16,'d41,'d66 : Img_reg_ns[16] = Img;
        'd4,'d29,'d54 : Img_reg_ns[4] = Img;'d17,'d42,'d67 : Img_reg_ns[17] = Img;
        'd5,'d30,'d55 : Img_reg_ns[5] = Img;'d18,'d43,'d68 : Img_reg_ns[18] = Img;
        'd6,'d31,'d56 : Img_reg_ns[6] = Img;'d19,'d44,'d69 : Img_reg_ns[19] = Img;
        'd7,'d32,'d57 : Img_reg_ns[7] = Img;'d20,'d45,'d70 : Img_reg_ns[20] = Img;
        'd8,'d33,'d58 : Img_reg_ns[8] = Img;'d21,'d46,'d71 : Img_reg_ns[21] = Img;
        'd9,'d34,'d59 : Img_reg_ns[9] = Img;'d22,'d47,'d72 : Img_reg_ns[22] = Img;
        'd10,'d35,'d60 : Img_reg_ns[10] = Img;'d23,'d48,'d73 : Img_reg_ns[23] = Img;
        'd11,'d36,'d61 : Img_reg_ns[11] = Img;'d24,'d49,'d74 : Img_reg_ns[24] = Img;
        'd12,'d37,'d62 : Img_reg_ns[12] = Img;
        //shared with activation output
        //act_out_1:0~3, act_out_2:4~7
        'd78:begin
            Img_reg_ns[0] = act_out_1_ns[0];
            Img_reg_ns[4] = act_out_2_ns[0];
        end
        'd79: begin
            Img_reg_ns[1] = act_out_1_ns[1];
            Img_reg_ns[5] = act_out_2_ns[1];
            Img_reg_ns[8]  = 0;
            Img_reg_ns[9]  = 0;
            Img_reg_ns[10] = 0;
        end
        'd80: begin
            Img_reg_ns[2] = act_out_1_ns[2];
            Img_reg_ns[6] = act_out_2_ns[2];
            Img_reg_ns[8]  = add_out_3_2;
            Img_reg_ns[9]  = add_out_3_3;
            Img_reg_ns[10] = add_out_3_4;
        end
        'd81: begin
            Img_reg_ns[3] = act_out_1_ns[3];
            Img_reg_ns[7] = act_out_2_ns[3];
            Img_reg_ns[8]  = add_out_3_2;
            Img_reg_ns[9]  = add_out_3_3;
            Img_reg_ns[10] = add_out_3_4;
        end
        'd82: begin
            Img_reg_ns[8]  = add_out_3_2;
            Img_reg_ns[9]  = add_out_3_3;
            Img_reg_ns[10] = add_out_3_4;
        end
        'd83: begin
            Img_reg_ns[8]  = add_out_3_2;
            Img_reg_ns[9]  = add_out_3_3;
            Img_reg_ns[10] = add_out_3_4;
        end
        'd84: begin
            Img_reg_ns[11]  = sm_1;
            Img_reg_ns[12]  = sm_2;
        end
        'd85: begin
            Img_reg_ns[13]  = sm_3;
        end
    endcase
end
//=====================================================================
//   Kernel
//=====================================================================
always @(posedge clk ) begin
    K_ch1_1_reg <= K_ch1_1_reg_ns;
    K_ch1_2_reg <= K_ch1_2_reg_ns;
    K_ch1_3_reg <= K_ch1_3_reg_ns;
    K_ch2_1_reg <= K_ch2_1_reg_ns;
    K_ch2_2_reg <= K_ch2_2_reg_ns;
    K_ch2_3_reg <= K_ch2_3_reg_ns;
end
always @(*) begin
    K_ch1_1_reg_ns = K_ch1_1_reg;
    case (cnt_Kernel)
        'd0: K_ch1_1_reg_ns[0] = Kernel_ch1;
        'd1: K_ch1_1_reg_ns[1] = Kernel_ch1;
        'd2: K_ch1_1_reg_ns[2] = Kernel_ch1;
        'd3: K_ch1_1_reg_ns[3] = Kernel_ch1; 
        default: K_ch1_1_reg_ns = K_ch1_1_reg;
    endcase
end
always @(*) begin
    K_ch1_2_reg_ns = K_ch1_2_reg;
    case (cnt_Kernel)
        'd4: K_ch1_2_reg_ns[0] = Kernel_ch1;
        'd5: K_ch1_2_reg_ns[1] = Kernel_ch1;
        'd6: K_ch1_2_reg_ns[2] = Kernel_ch1;
        'd7: K_ch1_2_reg_ns[3] = Kernel_ch1; 
        default: K_ch1_2_reg_ns = K_ch1_2_reg;
    endcase
end
always @(*) begin
    K_ch1_3_reg_ns = K_ch1_3_reg;
    case (cnt_Kernel)
        'd8: K_ch1_3_reg_ns[0] = Kernel_ch1;
        'd9: K_ch1_3_reg_ns[1] = Kernel_ch1;
        'd10: K_ch1_3_reg_ns[2] = Kernel_ch1;
        'd11: K_ch1_3_reg_ns[3] = Kernel_ch1; 
        default: K_ch1_3_reg_ns = K_ch1_3_reg;
    endcase
end
always @(*) begin
    K_ch2_1_reg_ns = K_ch2_1_reg;
    case (cnt_Kernel)
        'd0: K_ch2_1_reg_ns[0] = Kernel_ch2;
        'd1: K_ch2_1_reg_ns[1] = Kernel_ch2;
        'd2: K_ch2_1_reg_ns[2] = Kernel_ch2;
        'd3: K_ch2_1_reg_ns[3] = Kernel_ch2; 
        default: K_ch2_1_reg_ns = K_ch2_1_reg;
    endcase
end
always @(*) begin
    K_ch2_2_reg_ns = K_ch2_2_reg;
    case (cnt_Kernel)
        'd4: K_ch2_2_reg_ns[0] = Kernel_ch2;
        'd5: K_ch2_2_reg_ns[1] = Kernel_ch2;
        'd6: K_ch2_2_reg_ns[2] = Kernel_ch2;
        'd7: K_ch2_2_reg_ns[3] = Kernel_ch2; 
        default: K_ch2_2_reg_ns = K_ch2_2_reg;
    endcase
end
always @(*) begin
    K_ch2_3_reg_ns = K_ch2_3_reg;
    case (cnt_Kernel)
        'd8: K_ch2_3_reg_ns[0] = Kernel_ch2;
        'd9: K_ch2_3_reg_ns[1] = Kernel_ch2;
        'd10: K_ch2_3_reg_ns[2] = Kernel_ch2;
        'd11: K_ch2_3_reg_ns[3] = Kernel_ch2; 
        default: K_ch2_3_reg_ns = K_ch2_3_reg;
    endcase
end
//=====================================================================
//   Weight
//=====================================================================
//after count
always @(posedge clk ) begin
    if (count>'d78) begin//shift
        for(i=0;i<7;i=i+1)begin
            Weight_reg_1[i] <= Weight_reg_1[i+1];
            Weight_reg_2[i] <= Weight_reg_2[i+1];
            Weight_reg_3[i] <= Weight_reg_3[i+1];
        end
    end
    else begin
        for(i=0;i<8;i=i+1)begin
            Weight_reg_1[i] <= Weight_reg_1_ns[i];
            Weight_reg_2[i] <= Weight_reg_2_ns[i];
            Weight_reg_3[i] <= Weight_reg_3_ns[i];
        end
    end
end
always @(*) begin
    for(i=0;i<8;i=i+1)
        Weight_reg_1_ns[i] = Weight_reg_1[i];
    case (cnt_Weight)
        'd0:Weight_reg_1_ns[0] = Weight;
        'd1:Weight_reg_1_ns[1] = Weight;
        'd2:Weight_reg_1_ns[2] = Weight;
        'd3:Weight_reg_1_ns[3] = Weight;   
        'd4:Weight_reg_1_ns[4] = Weight;
        'd5:Weight_reg_1_ns[5] = Weight;
        'd6:Weight_reg_1_ns[6] = Weight;
        'd7:Weight_reg_1_ns[7] = Weight; 
    endcase
end
always @(*) begin
    for(i=0;i<8;i=i+1)
        Weight_reg_2_ns[i] = Weight_reg_2[i];
    case (cnt_Weight)
        'd8:Weight_reg_2_ns[0] = Weight;
        'd9:Weight_reg_2_ns[1] = Weight;
        'd10:Weight_reg_2_ns[2] = Weight;
        'd11:Weight_reg_2_ns[3] = Weight;   
        'd12:Weight_reg_2_ns[4] = Weight;
        'd13:Weight_reg_2_ns[5] = Weight;
        'd14:Weight_reg_2_ns[6] = Weight;
        'd15:Weight_reg_2_ns[7] = Weight;
    endcase
end
always @(*) begin
    for(i=0;i<8;i=i+1)
        Weight_reg_3_ns[i] = Weight_reg_3[i];
    case (cnt_Weight)
        'd16:Weight_reg_3_ns[0] = Weight;
        'd17:Weight_reg_3_ns[1] = Weight;
        'd18:Weight_reg_3_ns[2] = Weight;
        'd19:Weight_reg_3_ns[3] = Weight;   
        'd20:Weight_reg_3_ns[4] = Weight;
        'd21:Weight_reg_3_ns[5] = Weight;
        'd22:Weight_reg_3_ns[6] = Weight;
        'd23:Weight_reg_3_ns[7] = Weight; 
    endcase
end
//=====================================================================
// Convolution
//=====================================================================
//================================
// M1
//================================
always @(posedge clk) begin
    M1_3to1reg <=  M1_3to1_sh_reg[0];
    M1_4to2reg <=  M1_4to2_sh_reg[0];
    M2_3to1reg <=  M2_3to1_sh_reg[0];
    M2_4to2reg <=  M2_4to2_sh_reg[0];
end
always @(posedge clk ) begin
    M1_3to1_sh_reg[1] <= M1_in3;
    M1_3to1_sh_reg[0] <= M1_3to1_sh_reg[1];
end
always @(posedge clk ) begin
    M1_4to2_sh_reg[1] <= M1_in4;
    M1_4to2_sh_reg[0] <= M1_4to2_sh_reg[1];
end
always @(posedge clk ) begin
    M2_3to1_sh_reg[1] <= M2_in3;
    M2_3to1_sh_reg[0] <= M2_3to1_sh_reg[1];
end
always @(posedge clk ) begin
    M2_4to2_sh_reg[1] <= M2_in4;
    M2_4to2_sh_reg[0] <= M2_4to2_sh_reg[1];
end
always @(*) begin
    case (cnt_M1)
        'd9, 'd34,'d59:M1_in1 = Opt_reg ? Img_reg[0] : 0;
        'd10,'d35,'d60:M1_in1 = Opt_reg ? Img_reg[1] : 0;
        'd11,'d36,'d61:M1_in1 = Opt_reg ? Img_reg[3] : 0;

        'd21,'d46,'d71: M1_in1 = Opt_reg ? Img_reg[15] : 0;
        'd22,'d47,'d72: M1_in1 = Img_reg[15];
        'd23,'d48,'d73: M1_in1 = Img_reg[16];
        'd24,'d49,'d74: M1_in1 = Img_reg[17];
        'd25,'d50,'d75: M1_in1 = Img_reg[18];
        'd26,'d51,'d76: M1_in1 = Img_reg[19];
        //shared with fully connected
        'd79: M1_in1 = Img_reg[0];
        'd80: M1_in1 = Img_reg[1];
        'd81: M1_in1 = Img_reg[2];
        'd82: M1_in1 = Img_reg[3];
        'd83: M1_in1 = 0;
        'd84: M1_in1 = 0;
        'd85: M1_in1 = 0;
        default: M1_in1 = M1_3to1reg;
    endcase
end
always @(*) begin
    case (cnt_M1)
        'd9, 'd34,'d59:M1_in2 = Opt_reg ? Img_reg[0] : 0;
        'd10,'d35,'d60:M1_in2 = Opt_reg ? Img_reg[2] : 0;
        'd11,'d36,'d61:M1_in2 = Opt_reg ? Img_reg[4] : 0;
        'd21,'d46,'d71: M1_in2 = Img_reg[15];
        'd22,'d47,'d72: M1_in2 = Img_reg[16];
        'd23,'d48,'d73: M1_in2 = Img_reg[17];
        'd24,'d49,'d74: M1_in2 = Img_reg[18];
        'd25,'d50,'d75: M1_in2 = Img_reg[19];
        'd26,'d51,'d76: M1_in2 = Opt_reg ? Img_reg[19] : 0;
        //shared with fully connected
        'd79: M1_in2 = Img_reg[0];
        'd80: M1_in2 = Img_reg[1];
        'd81: M1_in2 = Img_reg[2];
        'd82: M1_in2 = Img_reg[3];
        default: M1_in2 = M1_4to2reg;
    endcase
end
always @(*) begin
    case (cnt_M1)
        'd9 ,'d34,'d59:M1_in3 = Opt_reg ? Img_reg[0]  : 0;
        'd10,'d35,'d60:M1_in3 = Img_reg[1];
        'd11,'d36,'d61:M1_in3 = Img_reg[3];
        'd12,'d37,'d62:M1_in3 = Opt_reg ? Img_reg[5]  : 0;
        'd13,'d38,'d63:M1_in3 = Img_reg[6];
        'd14,'d39,'d64:M1_in3 = Img_reg[8];
        'd15,'d40,'d65:M1_in3 = Opt_reg ? Img_reg[10] : 0;
        'd16,'d41,'d66:M1_in3 = Img_reg[11];
        'd17,'d42,'d67:M1_in3 = Img_reg[13];
        'd18,'d43,'d68:M1_in3 = Opt_reg ? Img_reg[15] : 0;
        'd19,'d44,'d69:M1_in3 = Img_reg[16];
        'd20,'d45,'d70:M1_in3 = Img_reg[18];
        'd21,'d46,'d71:M1_in3 = Opt_reg ? Img_reg[20] : 0;
        'd22,'d47,'d72:M1_in3 = Img_reg[20];
        'd23,'d48,'d73:M1_in3 = Img_reg[21];
        'd24,'d49,'d74:M1_in3 = Img_reg[22];
        'd25,'d50,'d75:M1_in3 = Img_reg[23];
        'd26,'d51,'d76:M1_in3 = Img_reg[24];
        //shared with fully connected
        'd79: M1_in3 = Img_reg[0];
        'd80: M1_in3 = Img_reg[1];
        'd81: M1_in3 = Img_reg[2];
        'd82: M1_in3 = Img_reg[3];
        default: M1_in3 = 0;
    endcase
end
always @(*) begin
    case (cnt_M1)
        'd9 ,'d34,'d59:M1_in4 = Img_reg[0];
        'd10,'d35,'d60:M1_in4 = Img_reg[2];
        'd11,'d36,'d61:M1_in4 = Img_reg[4];
        'd12,'d37,'d62:M1_in4 = Img_reg[5];
        'd13,'d38,'d63:M1_in4 = Img_reg[7];
        'd14,'d39,'d64:M1_in4 = Img_reg[9];
        'd15,'d40,'d65:M1_in4 = Img_reg[10];
        'd16,'d41,'d66:M1_in4 = Img_reg[12];
        'd17,'d42,'d67:M1_in4 = Img_reg[14];
        'd18,'d43,'d68:M1_in4 = Img_reg[15];
        'd19,'d44,'d69:M1_in4 = Img_reg[17];
        'd20,'d45,'d70:M1_in4 = Img_reg[19];
        'd21,'d46,'d71:M1_in4 = Img_reg[20];
        'd22,'d47,'d72:M1_in4 = Img_reg[21];
        'd23,'d48,'d73:M1_in4 = Img_reg[22];
        'd24,'d49,'d74:M1_in4 = Img_reg[23];
        'd25,'d50,'d75:M1_in4 = Img_reg[24];
        'd26,'d51,'d76:M1_in4 = Opt_reg ? Img_reg[24] : 0;
        //shared with fully connected
        default: M1_in4 = 0;
    endcase
end
//================================
// M2
//================================
always @(*) begin
    case (cnt_M2)
        'd9 ,'d34,'d59:M2_in1 = Opt_reg ? Img_reg[0] : 0;
        'd10,'d35,'d60:M2_in1 = Opt_reg ? Img_reg[2] : 0;
        'd11,'d36,'d61:M2_in1 = Opt_reg ? Img_reg[4] : 0;

        'd21,'d46,'d71:M2_in1 = Opt_reg ? Img_reg[20] : 0;
        'd22,'d47,'d72:M2_in1 = Img_reg[20];
        'd23,'d48,'d73:M2_in1 = Img_reg[21];
        'd24,'d49,'d74:M2_in1 = Img_reg[22];
        'd25,'d50,'d75:M2_in1 = Img_reg[23];
        'd26,'d51,'d76:M2_in1 = Img_reg[24];
        //shared with fully connected
        'd79: M2_in1 = Img_reg[4];
        'd80: M2_in1 = Img_reg[5];
        'd81: M2_in1 = Img_reg[6];
        'd82: M2_in1 = Img_reg[7];
        'd83: M2_in1 = 0;
        'd84: M2_in1 = 0;
        'd85: M2_in1 = 0;
        default: M2_in1 = M2_3to1reg;
    endcase
end
always @(*) begin
    case (cnt_M2)
        'd9 ,'d34,'d59:M2_in2 = Opt_reg ? Img_reg[1] : 0;
        'd10,'d35,'d60:M2_in2 = Opt_reg ? Img_reg[3] : 0;
        'd11,'d36,'d61:M2_in2 = Opt_reg ? Img_reg[4] : 0;
        'd21,'d46,'d71: M2_in2 = Img_reg[20];
        'd22,'d47,'d72: M2_in2 = Img_reg[21];
        'd23,'d48,'d73: M2_in2 = Img_reg[22];
        'd24,'d49,'d74: M2_in2 = Img_reg[23];
        'd25,'d50,'d75: M2_in2 = Img_reg[24];
        'd26,'d51,'d76: M2_in2 = Opt_reg ? Img_reg[24] : 0;
        //shared with fully connected
        'd79: M2_in2 = Img_reg[4];
        'd80: M2_in2 = Img_reg[5];
        'd81: M2_in2 = Img_reg[6];
        'd82: M2_in2 = Img_reg[7];
        default: M2_in2 = M2_4to2reg;
    endcase
end
always @(*) begin
    case (cnt_M2)
        'd9 ,'d34,'d59:M2_in3 = Img_reg[0];
        'd10,'d35,'d60:M2_in3 = Img_reg[2];
        'd11,'d36,'d61:M2_in3 = Img_reg[4];
        'd12,'d37,'d62:M2_in3 = Img_reg[5];
        'd13,'d38,'d63:M2_in3 = Img_reg[7];
        'd14,'d39,'d64:M2_in3 = Img_reg[9];
        'd15,'d40,'d65:M2_in3 = Img_reg[10];
        'd16,'d41,'d66:M2_in3 = Img_reg[12];
        'd17,'d42,'d67:M2_in3 = Img_reg[14];
        'd18,'d43,'d68:M2_in3 = Img_reg[15];
        'd19,'d44,'d69:M2_in3 = Img_reg[17];
        'd20,'d45,'d70:M2_in3 = Img_reg[19];
        'd21,'d46,'d71:M2_in3 = Opt_reg ? Img_reg[20] : 0;
        'd22,'d47,'d72:M2_in3 = Opt_reg ? Img_reg[20] : 0;
        'd23,'d48,'d73:M2_in3 = Opt_reg ? Img_reg[21] : 0;
        'd24,'d49,'d74:M2_in3 = Opt_reg ? Img_reg[22] : 0;
        'd25,'d50,'d75:M2_in3 = Opt_reg ? Img_reg[23] : 0;
        'd26,'d51,'d76:M2_in3 = Opt_reg ? Img_reg[24] : 0;
        //shared with fully connected
        'd79: M2_in3 = Img_reg[4];
        'd80: M2_in3 = Img_reg[5];
        'd81: M2_in3 = Img_reg[6];
        'd82: M2_in3 = Img_reg[7];
        default: M2_in3 = 0;
    endcase
end
always @(*) begin
    case (cnt_M2)
        'd9 ,'d34,'d59:M2_in4 = Img_reg[1];
        'd10,'d35,'d60:M2_in4 = Img_reg[3];
        'd11,'d36,'d61:M2_in4 = Opt_reg ? Img_reg[4]  : 0;
        'd12,'d37,'d62:M2_in4 = Img_reg[6];
        'd13,'d38,'d63:M2_in4 = Img_reg[8]; 
        'd14,'d39,'d64:M2_in4 = Opt_reg ? Img_reg[9]  : 0;
        'd15,'d40,'d65:M2_in4 = Img_reg[11];
        'd16,'d41,'d66:M2_in4 = Img_reg[13];
        'd17,'d42,'d67:M2_in4 = Opt_reg ? Img_reg[14] : 0;
        'd18,'d43,'d68:M2_in4 = Img_reg[16];
        'd19,'d44,'d69:M2_in4 = Img_reg[18];
        'd20,'d45,'d70:M2_in4 = Opt_reg ? Img_reg[19] : 0;

        'd21,'d46,'d71:M2_in4 = Opt_reg ? Img_reg[20] : 0;
        'd22,'d47,'d72:M2_in4 = Opt_reg ? Img_reg[21] : 0;
        'd23,'d48,'d73:M2_in4 = Opt_reg ? Img_reg[22] : 0;
        'd24,'d49,'d74:M2_in4 = Opt_reg ? Img_reg[23] : 0;
        'd25,'d50,'d75:M2_in4 = Opt_reg ? Img_reg[24] : 0;
        'd26,'d51,'d76:M2_in4 = Opt_reg ? Img_reg[24] : 0;
        //shared with fully connected
        default: M2_in4 = 0;
    endcase
end
//================================
// Kernel Select
//================================
always @(*) begin
    k1_sel_1 = K_ch1_1_reg[0];
    k1_sel_2 = K_ch1_1_reg[1];
    k1_sel_3 = K_ch1_1_reg[2];
    k1_sel_4 = K_ch1_1_reg[3];
    if(count>'d26 && count<'d59)begin
        k1_sel_1 = K_ch1_2_reg[0];
        k1_sel_2 = K_ch1_2_reg[1];
        k1_sel_3 = K_ch1_2_reg[2];
        k1_sel_4 = K_ch1_2_reg[3];
    end else if(count>'d58 && count<'d77)begin
        k1_sel_1 = K_ch1_3_reg[0];
        k1_sel_2 = K_ch1_3_reg[1];
        k1_sel_3 = K_ch1_3_reg[2];
        k1_sel_4 = K_ch1_3_reg[3];
    end 
    else if(count>'d78)begin//shared with fully connected
        k1_sel_1 = Weight_reg_1[0];
        k1_sel_2 = Weight_reg_2[0];
        k1_sel_3 = Weight_reg_3[0];
    end 
    else begin
        k1_sel_1 = K_ch1_1_reg[0];
        k1_sel_2 = K_ch1_1_reg[1];
        k1_sel_3 = K_ch1_1_reg[2];
        k1_sel_4 = K_ch1_1_reg[3];
    end
end
always @(*) begin
    k2_sel_1 = K_ch2_1_reg[0];
    k2_sel_2 = K_ch2_1_reg[1];
    k2_sel_3 = K_ch2_1_reg[2];
    k2_sel_4 = K_ch2_1_reg[3];
    if(count>'d26 && count<'d59)begin
        k2_sel_1 = K_ch2_2_reg[0];
        k2_sel_2 = K_ch2_2_reg[1];
        k2_sel_3 = K_ch2_2_reg[2];
        k2_sel_4 = K_ch2_2_reg[3];
    end else if(count>'d58 && count<'d77)begin
        k2_sel_1 = K_ch2_3_reg[0];
        k2_sel_2 = K_ch2_3_reg[1];
        k2_sel_3 = K_ch2_3_reg[2];
        k2_sel_4 = K_ch2_3_reg[3];
    end 
    else if(count>'d78)begin//shared with fully connected
        k2_sel_1 = Weight_reg_1[4];
        k2_sel_2 = Weight_reg_2[4];
        k2_sel_3 = Weight_reg_3[4];
    end 
    else begin
        k2_sel_1 = K_ch2_1_reg[0];
        k2_sel_2 = K_ch2_1_reg[1];
        k2_sel_3 = K_ch2_1_reg[2];
        k2_sel_4 = K_ch2_1_reg[3];
    end
end
//================================
// Multiply
//================================
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_1_1_mult ( .a(M1_in1), .b(k1_sel_1), .rnd(3'b0), .z(p_sum_1_1_1), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_1_2_mult ( .a(M1_in2), .b(k1_sel_2), .rnd(3'b0), .z(p_sum_1_1_2), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_1_3_mult ( .a(M1_in3), .b(k1_sel_3), .rnd(3'b0), .z(p_sum_1_1_3), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_1_4_mult ( .a(M1_in4), .b(k1_sel_4), .rnd(3'b0), .z(p_sum_1_1_4), .status( ) );

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_2_1_mult ( .a(M2_in1), .b(k1_sel_1), .rnd(3'b0), .z(p_sum_1_2_1), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_2_2_mult ( .a(M2_in2), .b(k1_sel_2), .rnd(3'b0), .z(p_sum_1_2_2), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_2_3_mult ( .a(M2_in3), .b(k1_sel_3), .rnd(3'b0), .z(p_sum_1_2_3), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_2_4_mult ( .a(M2_in4), .b(k1_sel_4), .rnd(3'b0), .z(p_sum_1_2_4), .status( ) );

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_1_1_mult ( .a(M1_in1), .b(k2_sel_1), .rnd(3'b0), .z(p_sum_2_1_1), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_1_2_mult ( .a(M1_in2), .b(k2_sel_2), .rnd(3'b0), .z(p_sum_2_1_2), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_1_3_mult ( .a(M1_in3), .b(k2_sel_3), .rnd(3'b0), .z(p_sum_2_1_3), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_1_4_mult ( .a(M1_in4), .b(k2_sel_4), .rnd(3'b0), .z(p_sum_2_1_4), .status( ) );

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_2_1_mult ( .a(M2_in1), .b(k2_sel_1), .rnd(3'b0), .z(p_sum_2_2_1), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_2_2_mult ( .a(M2_in2), .b(k2_sel_2), .rnd(3'b0), .z(p_sum_2_2_2), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_2_3_mult ( .a(M2_in3), .b(k2_sel_3), .rnd(3'b0), .z(p_sum_2_2_3), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_2_4_mult ( .a(M2_in4), .b(k2_sel_4), .rnd(3'b0), .z(p_sum_2_2_4), .status( ) );
always @(posedge clk) begin
    p_sum_1_1_1_reg <= p_sum_1_1_1;
    p_sum_1_1_2_reg <= p_sum_1_1_2;
    p_sum_1_1_3_reg <= p_sum_1_1_3;
    p_sum_1_1_4_reg <= p_sum_1_1_4;
    p_sum_1_2_1_reg <= p_sum_1_2_1;
    p_sum_1_2_2_reg <= p_sum_1_2_2;
    p_sum_1_2_3_reg <= p_sum_1_2_3;
    p_sum_1_2_4_reg <= p_sum_1_2_4;
end
always @(posedge clk) begin
    p_sum_2_1_1_reg <= p_sum_2_1_1;
    p_sum_2_1_2_reg <= p_sum_2_1_2;
    p_sum_2_1_3_reg <= p_sum_2_1_3;
    p_sum_2_1_4_reg <= p_sum_2_1_4;
    p_sum_2_2_1_reg <= p_sum_2_2_1;
    p_sum_2_2_2_reg <= p_sum_2_2_2;
    p_sum_2_2_3_reg <= p_sum_2_2_3;
    p_sum_2_2_4_reg <= p_sum_2_2_4;
end
//=====================================================================
//   Feature Map 1
//=====================================================================
//================================
// adder-select 1
//================================
//shared with fully connected
always @(*) begin
    if(count<'d78)begin
        add_sel_1_1_1 = add_out_1_1;  
        add_sel_1_1_2 = add_out_1_2;
        add_sel_1_1_3 = add_out_1_3;
    end else begin
        add_sel_1_1_1 = p_sum_1_1_1_reg;
        add_sel_1_1_2 = p_sum_1_1_2_reg;
        add_sel_1_1_3 = p_sum_1_1_3_reg;
    end
end
always @(*) begin
    if(count<'d78)begin
        add_sel_1_2_1 = p_sum_1_1_2_reg;
        add_sel_1_2_2 = p_sum_1_1_3_reg;
        add_sel_1_2_3 = p_sum_1_1_4_reg;
    end else begin
        add_sel_1_2_1 = p_sum_2_2_1_reg;
        add_sel_1_2_2 = p_sum_2_2_2_reg;
        add_sel_1_2_3 = p_sum_2_2_3_reg;
    end
end
//shared with softmax
//=====================================================================
//   redundant register(add_out_1_1_reg),nedd to modify add_selector(add_out_1_4)
//=====================================================================
always @(posedge clk ) begin
    if(count<'d87)
        add_out_1_1_reg <= add_out_1_1;
    else
        add_out_1_1_reg <= add_out_1_1_reg;
end
always @(*) begin
    if(count<'d78)begin
        add_sel_1_1_0 = add_in_1;
        add_sel_1_2_0 = p_sum_1_1_1_reg;
    end else begin
        case (count)
            'd85:begin
                add_sel_1_1_0 = Img_reg[11];
                add_sel_1_2_0 = Img_reg[12];
            end 
            'd86:begin
                add_sel_1_1_0 = Img_reg[13];
                add_sel_1_2_0 = add_out_1_1_reg;
            end
            default: begin
                add_sel_1_1_0 = 0;
                add_sel_1_2_0 = 0;
            end
        endcase
    end
end
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_1_1 ( .a(add_sel_1_1_0), .b(add_sel_1_2_0), .rnd(3'b0), .z(add_out_1_1), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_1_2 ( .a(add_sel_1_1_1), .b(add_sel_1_2_1), .rnd(3'b0), .z(add_out_1_2), .status() );    
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_1_3 ( .a(add_sel_1_1_2), .b(add_sel_1_2_2), .rnd(3'b0), .z(add_out_1_3), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_1_4 ( .a(add_sel_1_1_3), .b(add_sel_1_2_3), .rnd(3'b0), .z(add_out_1_4), .status() );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_2_1 ( .a(add_in_2), .b(p_sum_1_2_1_reg), .rnd(3'b0), .z(add_out_2_1), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_2_2 ( .a(add_out_2_1), .b(p_sum_1_2_2_reg), .rnd(3'b0), .z(add_out_2_2), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_2_3 ( .a(add_out_2_2), .b(p_sum_1_2_3_reg), .rnd(3'b0), .z(add_out_2_3), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_2_4 ( .a(add_out_2_3), .b(p_sum_1_2_4_reg), .rnd(3'b0), .z(add_out_2_4), .status() );
always @(*) begin
    if((count>'d9&&count<'d28) || (count>'d34&&count<'d53) || (count>'d59&&count<'d78)) add_in_1 = FM1[0];
    else add_in_1 = 0;
end
always @(*) begin
    if((count>'d9&&count<'d28) || (count>'d34&&count<'d53) || (count>'d59&&count<'d78)) add_in_2 = FM1[1];
    else add_in_2 = 0;
end
//================================
// FM1
//================================
always @(posedge clk ) begin
    if((cnt_FM1>'d9&&cnt_FM1<'d28) || (cnt_FM1>'d34&&cnt_FM1<'d53) || (cnt_FM1>'d59&&cnt_FM1<'d78))begin
        for(i=0;i<34;i=i+1)begin
            FM1[i] <= FM1[i+2];
        end
        FM1[34] <= FM1_ns[34];
        FM1[35] <= FM1_ns[35];
    end
    else begin
        for(i=0;i<36;i=i+1)begin
            FM1[i] <= FM1_ns[i];
        end
    end
end
always @(*) begin
    if(cnt_FM1=='d0)begin
        for(i=0;i<36;i=i+1)begin
            FM1_ns[i] = 0;
        end
    end
    else if((cnt_FM1>'d9&&cnt_FM1<'d28) || (cnt_FM1>'d34&&cnt_FM1<'d53) || (cnt_FM1>'d59&&cnt_FM1<'d78))begin
        for(i=0;i<35;i=i+1)begin
            FM1_ns[i] = FM1[i];
        end
        FM1_ns[34] = add_out_1_4;
        FM1_ns[35] = add_out_2_4;
    end
    else begin
        for(i=0;i<36;i=i+1)begin
            FM1_ns[i] = FM1[i];
        end
    end
end
//=====================================================================
//   Feature Map 2
//=====================================================================
//================================
// adder-select 2
//================================
//shared with fully connected
always @(*) begin
    if(count<'d78)begin
        add_sel_2_1_1 = add_out_3_1;  
        add_sel_2_1_2 = add_out_3_2;
        add_sel_2_1_3 = add_out_3_3;
    end else begin
        add_sel_2_1_1 = add_out_1_2;
        add_sel_2_1_2 = add_out_1_3;
        add_sel_2_1_3 = add_out_1_4;
    end
end
// reg [31:0] fc_out_1, fc_out_2, fc_out_3;
always @(*) begin
    if(count<'d78)begin
        add_sel_2_2_1 = p_sum_2_1_2_reg;
        add_sel_2_2_2 = p_sum_2_1_3_reg;
        add_sel_2_2_3 = p_sum_2_1_4_reg;
    end else begin
        add_sel_2_2_1 = Img_reg[8];
        add_sel_2_2_2 = Img_reg[9];
        add_sel_2_2_3 = Img_reg[10];
    end
end
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_3_1 ( .a(add_in_3), .b(p_sum_2_1_1_reg), .rnd(3'b0), .z(add_out_3_1), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_3_2 ( .a(add_sel_2_1_1), .b(add_sel_2_2_1), .rnd(3'b0), .z(add_out_3_2), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_3_3 ( .a(add_sel_2_1_2), .b(add_sel_2_2_2), .rnd(3'b0), .z(add_out_3_3), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_p_sum_add_3_4 ( .a(add_sel_2_1_3), .b(add_sel_2_2_3), .rnd(3'b0), .z(add_out_3_4), .status() );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_4_1 ( .a(add_in_4), .b(p_sum_2_2_1_reg), .rnd(3'b0), .z(add_out_4_1), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_4_2 ( .a(add_out_4_1), .b(p_sum_2_2_2_reg), .rnd(3'b0), .z(add_out_4_2), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_4_3 ( .a(add_out_4_2), .b(p_sum_2_2_3_reg), .rnd(3'b0), .z(add_out_4_3), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_p_sum_add_4_4 ( .a(add_out_4_3), .b(p_sum_2_2_4_reg), .rnd(3'b0), .z(add_out_4_4), .status() );

always @(*) begin
    if((count>'d9&&count<'d28) || (count>'d34&&count<'d53) || (count>'d59&&count<'d78)) add_in_3 = FM2[0];
    else add_in_3 = 0;
end
always @(*) begin
    if((count>'d9&&count<'d28) || (count>'d34&&count<'d53) || (count>'d59&&count<'d78)) add_in_4 = FM2[1];
    else add_in_4 = 0;
end
//================================
// FM2
//================================
always @(posedge clk ) begin
    if((cnt_FM2>'d9&&cnt_FM2<'d28) || (cnt_FM2>'d34&&cnt_FM2<'d53) || (cnt_FM2>'d59&&cnt_FM2<'d78))begin
        for(i=0;i<34;i=i+1)begin
            FM2[i] <= FM2[i+2];
        end
        FM2[34] <= FM2_ns[34];
        FM2[35] <= FM2_ns[35];
    end
    else begin
        for(i=0;i<36;i=i+1)begin
            FM2[i] <= FM2_ns[i];
        end
    end
end
always @(*) begin
    if(cnt_FM2=='d0)begin
        for(i=0;i<36;i=i+1)begin
            FM2_ns[i] = 0;
        end
    end
    else if((cnt_FM2>'d9&&cnt_FM2<'d28) || (cnt_FM2>'d34&&cnt_FM2<'d53) || (cnt_FM2>'d59&&cnt_FM2<'d78))begin
        for(i=0;i<35;i=i+1)begin
            FM2_ns[i] = FM2[i];
        end
        FM2_ns[34] = add_out_3_4;
        FM2_ns[35] = add_out_4_4;
    end
    else begin
        for(i=0;i<36;i=i+1)begin
            FM2_ns[i] = FM2[i];
        end
    end
end
//=====================================================================
//   Max Pooling 1
//=====================================================================
//Max_pooling_out
//comparator
DW_fp_cmp#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_cmp_1 ( .a(cmp_in_1_1), .b(cmp_in_1_2), .zctr(1'b0),
    .aeqb(), .altb(), .agtb(), .unordered(),
    .z0(), .z1(cmp_out_1_1), .status0(), .status1() );
DW_fp_cmp#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_cmp_2 ( .a(cmp_in_1_3), .b(cmp_in_1_4), .zctr(1'b0), 
    .aeqb(), .altb(), .agtb(), .unordered(),
    .z0(), .z1(cmp_out_1_2), .status0(), .status1() );
//================================
// Cmp-select 1
//================================
always @(*) begin
    case (cnt_Maxpool)
        'd61:cmp_in_1_1 = FP_min;
        'd62:cmp_in_1_1 = cmp_out_1_2_reg; 
        'd63:cmp_in_1_1 = cmp_out_1_2_reg;
        'd64:cmp_in_1_1 = act_in_1[0];
        'd65:cmp_in_1_1 = cmp_out_1_2_reg;
        'd66:cmp_in_1_1 = cmp_out_1_2_reg;
        'd67:cmp_in_1_1 = act_in_1[0];
        'd68:cmp_in_1_1 = cmp_out_1_2_reg;
        'd69:cmp_in_1_1 = cmp_out_1_2_reg;
        'd70:cmp_in_1_1 = FP_min;
        'd71:cmp_in_1_1 = cmp_out_1_2_reg;
        'd72:cmp_in_1_1 = cmp_out_1_2_reg;
        'd73:cmp_in_1_1 = act_in_1[2];
        'd74:cmp_in_1_1 = cmp_out_1_2_reg;
        'd75:cmp_in_1_1 = cmp_out_1_2_reg;
        'd76:cmp_in_1_1 = act_in_1[3];//modify
        'd77:cmp_in_1_1 = cmp_out_1_2_reg;
        'd78:cmp_in_1_1 = cmp_out_1_2_reg;
        default: cmp_in_1_1 = FP_min;
    endcase
end
always @(*) begin
    if(cnt_Maxpool>'d60&&cnt_Maxpool<'d79)
        cmp_in_1_2 = FM1[34];
    else
        cmp_in_1_2 = FP_min;
end
always @(*) begin
    case (cnt_Maxpool)
        'd61:cmp_in_1_3 = cmp_out_1_1;
        'd62:cmp_in_1_3 = FP_min;
        'd63:cmp_in_1_3 = cmp_out_1_1;
        'd64:cmp_in_1_3 = cmp_out_1_1;
        'd65:cmp_in_1_3 = act_in_1[1];
        'd66:cmp_in_1_3 = cmp_out_1_1;
        'd67:cmp_in_1_3 = cmp_out_1_1;
        'd68:cmp_in_1_3 = act_in_1[1];
        'd69:cmp_in_1_3 = cmp_out_1_1;
        'd70:cmp_in_1_3 = cmp_out_1_1;
        'd71:cmp_in_1_3 = FP_min;
        'd72:cmp_in_1_3 = cmp_out_1_1;
        'd73:cmp_in_1_3 = cmp_out_1_1;
        'd74:cmp_in_1_3 = cmp_out_1_1;//modify
        'd75:cmp_in_1_3 = cmp_out_1_1;
        'd76:cmp_in_1_3 = cmp_out_1_1;
        'd77:cmp_in_1_3 = cmp_out_1_1;//modify
        'd78:cmp_in_1_3 = cmp_out_1_1;
        default: cmp_in_1_3 = FP_min;
    endcase
end
always @(*) begin
    if(cnt_Maxpool>'d60&&cnt_Maxpool<'d79)
        cmp_in_1_4 = FM1[35];
    else
        cmp_in_1_4 = FP_min;
end
always @(posedge clk) begin
    cmp_out_1_2_reg <= cmp_out_1_2;
end

//=====================================================================
//   Max_pooling_out 1
//=====================================================================
always @(posedge clk) begin
    for(i=0;i<4;i=i+1)begin
        act_in_1[i] <= act_in_1_ns[i];
    end
end
always @(*) begin
    for(i=0;i<4;i=i+1)begin
        act_in_1_ns[i] = act_in_1[i];
    end
    case (cnt_Maxpool)
        'd62,'d65,'d68:act_in_1_ns[0] = cmp_out_1_1;
        'd63,'d66,'d69:act_in_1_ns[1] = cmp_out_1_2; 
        'd71          :act_in_1_ns[2] = cmp_out_1_1;
        'd75          :act_in_1_ns[2] = cmp_out_1_2;
        'd72,'d78     :act_in_1_ns[3] = cmp_out_1_2;
        default: begin
            for(i=0;i<4;i=i+1)begin
                act_in_1_ns[i] = act_in_1[i];
            end
        end 
    endcase
end
//=====================================================================
//   Max Pooling 2
//=====================================================================
//Max_pooling_out
//comparator
DW_fp_cmp#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_cmp_1 ( .a(cmp_in_2_1), .b(cmp_in_2_2), .zctr(1'b0),
    .aeqb(), .altb(), .agtb(), .unordered(),
    .z0(), .z1(cmp_out_2_1), .status0(), .status1() );
DW_fp_cmp#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_cmp_2 ( .a(cmp_in_2_3), .b(cmp_in_2_4), .zctr(1'b0), 
    .aeqb(), .altb(), .agtb(), .unordered(),
    .z0(), .z1(cmp_out_2_2), .status0(), .status1() );
//================================
// Cmp-select 2
//================================
always @(*) begin
    case (cnt_Maxpool)
        'd61:cmp_in_2_1 = FP_min;
        'd62:cmp_in_2_1 = cmp_out_2_2_reg;
        'd63:cmp_in_2_1 = cmp_out_2_2_reg;
        'd64:cmp_in_2_1 = act_in_2[0];
        'd65:cmp_in_2_1 = cmp_out_2_2_reg;
        'd66:cmp_in_2_1 = cmp_out_2_2_reg;
        'd67:cmp_in_2_1 = act_in_2[0];
        'd68:cmp_in_2_1 = cmp_out_2_2_reg;
        'd69:cmp_in_2_1 = cmp_out_2_2_reg;
        'd70:cmp_in_2_1 = FP_min;
        'd71:cmp_in_2_1 = cmp_out_2_2_reg;
        'd72:cmp_in_2_1 = cmp_out_2_2_reg;
        'd73:cmp_in_2_1 = act_in_2[2];
        'd74:cmp_in_2_1 = cmp_out_2_2_reg;
        'd75:cmp_in_2_1 = cmp_out_2_2_reg;
        'd76:cmp_in_2_1 = act_in_2[3];
        'd77:cmp_in_2_1 = cmp_out_2_2_reg;
        'd78:cmp_in_2_1 = cmp_out_2_2_reg;
        default: cmp_in_2_1 = FP_min;
    endcase
end
always @(*) begin
    if(cnt_Maxpool>'d60&&cnt_Maxpool<'d79)
        cmp_in_2_2 = FM2[34];
    else
        cmp_in_2_2 = FP_min;    
end
always @(*) begin
    case (cnt_Maxpool)
        'd61:cmp_in_2_3 = cmp_out_2_1;
        'd62:cmp_in_2_3 = FP_min;
        'd63:cmp_in_2_3 = cmp_out_2_1;
        'd64:cmp_in_2_3 = cmp_out_2_1;
        'd65:cmp_in_2_3 = act_in_2[1];
        'd66:cmp_in_2_3 = cmp_out_2_1;
        'd67:cmp_in_2_3 = cmp_out_2_1;
        'd68:cmp_in_2_3 = act_in_2[1];
        'd69:cmp_in_2_3 = cmp_out_2_1;
        'd70:cmp_in_2_3 = cmp_out_2_1;
        'd71:cmp_in_2_3 = FP_min;
        'd72:cmp_in_2_3 = cmp_out_2_1;
        'd73:cmp_in_2_3 = cmp_out_2_1;
        'd74:cmp_in_2_3 = cmp_out_2_1;//modify
        'd75:cmp_in_2_3 = cmp_out_2_1;
        'd76:cmp_in_2_3 = cmp_out_2_1;
        'd77:cmp_in_2_3 = cmp_out_2_1;//modify
        'd78:cmp_in_2_3 = cmp_out_2_1;
        default: cmp_in_2_3 = FP_min;
    endcase
end
always @(*) begin
    if(cnt_Maxpool>'d60&&cnt_Maxpool<'d79)
        cmp_in_2_4 = FM2[35];
    else
        cmp_in_2_4 = FP_min;
end
always @(posedge clk) begin
    cmp_out_2_2_reg <= cmp_out_2_2;
end
//=====================================================================
//   Max_pooling_out 2
//=====================================================================
always @(posedge clk) begin
    for(i=0;i<4;i=i+1)begin
        act_in_2[i] <= act_in_2_ns[i];
    end
end
always @(*) begin
    for(i=0;i<4;i=i+1)begin
        act_in_2_ns[i] = act_in_2[i];
    end
    case (cnt_Maxpool)
        'd62,'d65,'d68:act_in_2_ns[0] = cmp_out_2_1;
        'd63,'d66,'d69:act_in_2_ns[1] = cmp_out_2_2; 
        'd71          :act_in_2_ns[2] = cmp_out_2_1;
        'd75          :act_in_2_ns[2] = cmp_out_2_2;
        'd72,'d78     :act_in_2_ns[3] = cmp_out_2_2;
        default: begin
            for(i=0;i<4;i=i+1)begin
                act_in_2_ns[i] = act_in_2[i];
            end
        end
    endcase
end
//=====================================================================
//   Activation Function 1
//=====================================================================
//EXP
always @(*) begin
    case (cnt_Act)
        'd76:exp_in_1 = Opt_reg ? {act_in_1[0][31], (act_in_1[0][30:23]+1'b1), act_in_1[0][22:0]} : {~act_in_1[0][31], act_in_1[0][30:23], act_in_1[0][22:0]};
        'd77:exp_in_1 = Opt_reg ? {act_in_1[1][31], (act_in_1[1][30:23]+1'b1), act_in_1[1][22:0]} : {~act_in_1[1][31], act_in_1[1][30:23], act_in_1[1][22:0]};
        'd78:exp_in_1 = Opt_reg ? {act_in_1[2][31], (act_in_1[2][30:23]+1'b1), act_in_1[2][22:0]} : {~act_in_1[2][31], act_in_1[2][30:23], act_in_1[2][22:0]};
        'd79:exp_in_1 = Opt_reg ? {act_in_1[3][31], (act_in_1[3][30:23]+1'b1), act_in_1[3][22:0]} : {~act_in_1[3][31], act_in_1[3][30:23], act_in_1[3][22:0]};
        'd84:exp_in_1 = Img_reg[8];
        'd85:exp_in_1 = Img_reg[10];
        default: exp_in_1 = 0;
    endcase
end
DW_fp_exp#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_exp ( .a(exp_in_1), .z(exp_out_1), .status() );
always @(posedge clk) begin
    exp_out_1_reg <= exp_out_1;
end
//ADD
always @(*) begin
    add_act_in_1_1 = exp_out_1_reg;
    add_act_in_1_2 = exp_out_1_reg;
end
DW_fp_add#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_add ( .a(add_act_in_1_1), .b(32'b00111111100000000000000000000000), .rnd(3'd0), .z(add_act_out_1_1), .status() );
DW_fp_add#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_add ( .a(add_act_in_1_2), .b(32'b10111111100000000000000000000000), .rnd(3'd0), .z(add_act_out_1_2), .status() );
always @(posedge clk ) begin
    add_act_out_1_1_reg <= add_act_out_1_1;
    add_act_out_1_2_reg <= add_act_out_1_2;
end
//DIV
always @(*) begin
    if(cnt_Act=='d87)
        div_in_1_1 = Img_reg[11];
    else if(cnt_Act=='d88)
        div_in_1_1 = Img_reg[12];
    else if(cnt_Act=='d89)
        div_in_1_1 = Img_reg[13];
    else begin
        case (Opt_reg)
            'd0:div_in_1_1 = 32'b00111111100000000000000000000000; 
            'd1:div_in_1_1 = add_act_out_1_2_reg;
            default: div_in_1_1 = 0;
        endcase
    end
end
always @(*) begin
    if(cnt_Act>'d86)
        div_in_1_2 = add_out_1_1_reg;
    else
        div_in_1_2 = add_act_out_1_1_reg;
end
DW_fp_div#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_div ( .a(div_in_1_1), .b(div_in_1_2), .rnd(3'd0), .z(div_out_1), .status() );
always @(posedge clk) begin
    div_out_1_reg <= div_out_1;
end
//Activation_out
always @(*) begin
    for(i=0;i<4;i=i+1)begin
        act_out_1_ns[i] = 0;
    end
    case (cnt_Act)
        'd78:act_out_1_ns[0] = div_out_1;
        'd79:act_out_1_ns[1] = div_out_1;
        'd80:act_out_1_ns[2] = div_out_1;
        'd81:act_out_1_ns[3] = div_out_1;
        default: begin
            for(i=0;i<4;i=i+1)begin
                act_out_1_ns[i] = 0;
            end
        end
    endcase
end
//=====================================================================
//   Activation Function 2
//=====================================================================
//EXP
always @(*) begin
    case (cnt_Act)
        'd76:exp_in_2 = Opt_reg ? {act_in_2[0][31], (act_in_2[0][30:23]+1'b1), act_in_2[0][22:0]} : {~act_in_2[0][31], act_in_2[0][30:23], act_in_2[0][22:0]};
        'd77:exp_in_2 = Opt_reg ? {act_in_2[1][31], (act_in_2[1][30:23]+1'b1), act_in_2[1][22:0]} : {~act_in_2[1][31], act_in_2[1][30:23], act_in_2[1][22:0]};
        'd78:exp_in_2 = Opt_reg ? {act_in_2[2][31], (act_in_2[2][30:23]+1'b1), act_in_2[2][22:0]} : {~act_in_2[2][31], act_in_2[2][30:23], act_in_2[2][22:0]};
        'd79:exp_in_2 = Opt_reg ? {act_in_2[3][31], (act_in_2[3][30:23]+1'b1), act_in_2[3][22:0]} : {~act_in_2[3][31], act_in_2[3][30:23], act_in_2[3][22:0]};
        'd84:exp_in_2 = Img_reg[9];
        default: exp_in_2 = 0;
    endcase
end
DW_fp_exp#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_exp ( .a(exp_in_2), .z(exp_out_2), .status() );
always @(posedge clk) begin
    exp_out_2_reg <= exp_out_2;
end
//ADD
always @(*) begin
    add_act_in_2_1 = exp_out_2_reg;
    add_act_in_2_2 = exp_out_2_reg;
end
DW_fp_add#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1_act_add ( .a(add_act_in_2_1), .b(32'b00111111100000000000000000000000), .rnd(3'd0), .z(add_act_out_2_1), .status() );
DW_fp_add#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_act_add ( .a(add_act_in_2_2), .b(32'b10111111100000000000000000000000), .rnd(3'd0), .z(add_act_out_2_2), .status() );
always @(posedge clk ) begin
    add_act_out_2_1_reg <= add_act_out_2_1;//+1
    add_act_out_2_2_reg <= add_act_out_2_2;//-1
end
//DIV
always @(*) begin
    case (Opt_reg)
        'd0:div_in_2_1 = 32'b00111111100000000000000000000000; 
        'd1:div_in_2_1 = add_act_out_2_2_reg;
        default: div_in_2_1 = 0;
    endcase
end
always @(*) begin
    div_in_2_2 = add_act_out_2_1_reg;
end
DW_fp_div#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2_div ( .a(div_in_2_1), .b(div_in_2_2), .rnd(3'd0), .z(div_out_2), .status() );
//Activation_out
always @(*) begin
    for(i=0;i<4;i=i+1)begin
        act_out_2_ns[i] = 0;
    end
    case (cnt_Act)
        'd78:act_out_2_ns[0] = div_out_2;
        'd79:act_out_2_ns[1] = div_out_2;
        'd80:act_out_2_ns[2] = div_out_2;
        'd81:act_out_2_ns[3] = div_out_2;
        default: begin
            for(i=0;i<4;i=i+1)begin
                act_out_2_ns[i] = 0;
            end
        end 
    endcase
end
//=====================================================================
//   Fully Connected Layer
//=====================================================================
// line:290, 303, 331, 371, 384, 412, 460, 507, 620, 807, 
always @(*) begin
    if(count>'d79)begin
        fc_out_1_ns = add_out_3_2;
        fc_out_2_ns = add_out_3_3;
        fc_out_3_ns = add_out_3_4;
    end
    else begin
        fc_out_1_ns = 0;
        fc_out_2_ns = 0;
        fc_out_3_ns = 0;
    end
end
//=====================================================================
//   Softmax
//=====================================================================
//exp:line 1237,1316
//add:line 616
//div:line 1299
//ba rst_n
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n) begin
//         sm_1_reg <= 0;
//         sm_2_reg <= 0;
//         sm_3_reg <= 0;
//     end
//     else begin
//         sm_1_reg <= sm_1;
//         sm_2_reg <= sm_2;
//         sm_3_reg <= sm_3;
//     end
// end
always @(*) begin
    if(count=='d84) sm_1 = exp_out_1;
    else sm_1 = Img_reg[11];
end
always @(*) begin
    if(count=='d84) sm_2 = exp_out_2;
    else sm_2 = Img_reg[12];
end
always @(*) begin
    if(count=='d85) sm_3 = exp_out_1;
    else sm_3 = Img_reg[13];
end
//=====================================================================
//   Output Logic
//=====================================================================
always @(*) begin
    if(count=='d88||count=='d89||count=='d90)
        out_valid = 1;
    else
        out_valid = 0;
end
always @(*) begin
    if(out_valid)
        out = div_out_1_reg;
    else
        out = 0;
end
endmodule
