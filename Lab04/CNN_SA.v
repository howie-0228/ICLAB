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
reg [31:0] Img_reg[24:0], Img_reg_ns[24:0];

reg [31:0] K_ch1_1_reg [3:0], K_ch1_1_reg_ns [3:0];
reg [31:0] K_ch1_2_reg [3:0], K_ch1_2_reg_ns [3:0];
reg [31:0] K_ch1_3_reg [3:0], K_ch1_3_reg_ns [3:0];

reg [31:0] K_ch2_1_reg [3:0], K_ch2_1_reg_ns [3:0];
reg [31:0] K_ch2_2_reg [3:0], K_ch2_2_reg_ns [3:0];
reg [31:0] K_ch2_3_reg [3:0], K_ch2_3_reg_ns [3:0];

reg [31:0] Weight_reg[23:0], Weight_reg_ns[23:0];
reg [31:0] Opt_reg, Opt_reg_ns;

//systolic array
reg [31:0] SA_img[3:0];

integer i;
//=====================================================================
//   Counter
//=====================================================================
always @(posedge clk) begin
    count <= count_ns;
end
always @(*) begin
    if(!in_valid)
        count_ns = 'd0;
    else 
        count_ns = count+1;
end
//=====================================================================
//   Opt
//=====================================================================
always @(posedge clk ) begin
    Opt_reg <= Opt_reg_ns;
end
always @(*) begin
    Opt_reg_ns = (in_valid&&count=='d0) ? Opt Opt_reg;
end
//=====================================================================
//   Img
//=====================================================================
always @(posedge clk ) begin
    Img_reg <= Img_reg_ns;
end
always @(*) begin
    case (count)
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
        default : Img_reg_ns = Img_reg; 
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
    case (count)
        'd0: K_ch1_1_reg_ns[0] = Kernel_ch1;
        'd1: K_ch1_1_reg_ns[1] = Kernel_ch1;
        'd2: K_ch1_1_reg_ns[2] = Kernel_ch1;
        'd3: K_ch1_1_reg_ns[3] = Kernel_ch1; 
        default: K_ch1_1_reg_ns = K_ch1_1_reg;
    endcase
end
always @(*) begin
    case (count)
        'd4: K_ch1_2_reg_ns[0] = Kernel_ch1;
        'd5: K_ch1_2_reg_ns[1] = Kernel_ch1;
        'd6: K_ch1_2_reg_ns[2] = Kernel_ch1;
        'd7: K_ch1_2_reg_ns[3] = Kernel_ch1; 
        default: K_ch1_2_reg_ns = K_ch1_2_reg;
    endcase
end
always @(*) begin
    case (count)
        'd8: K_ch1_3_reg_ns[0] = Kernel_ch1;
        'd9: K_ch1_3_reg_ns[1] = Kernel_ch1;
        'd10: K_ch1_3_reg_ns[2] = Kernel_ch1;
        'd11: K_ch1_3_reg_ns[3] = Kernel_ch1; 
        default: K_ch1_3_reg_ns = K_ch1_3_reg;
    endcase
end
always @(*) begin
    case (count)
        'd0: K_ch2_1_reg_ns[0] = Kernel_ch2;
        'd1: K_ch2_1_reg_ns[1] = Kernel_ch2;
        'd2: K_ch2_1_reg_ns[2] = Kernel_ch2;
        'd3: K_ch2_1_reg_ns[3] = Kernel_ch2; 
        default: K_ch2_1_reg_ns = K_ch2_1_reg;
    endcase
end
always @(*) begin
    case (count)
        'd4: K_ch2_2_reg_ns[0] = Kernel_ch2;
        'd5: K_ch2_2_reg_ns[1] = Kernel_ch2;
        'd6: K_ch2_2_reg_ns[2] = Kernel_ch2;
        'd7: K_ch2_2_reg_ns[3] = Kernel_ch2; 
        default: K_ch2_2_reg_ns = K_ch2_2_reg;
    endcase
end
always @(*) begin
    case (count)
        'd8: K_ch2_3_reg_ns[0] = Kernel_ch2;
        'd9: K_ch2_3_reg_ns[1] = Kernel_ch2;
        'd10: K_ch2_3_reg_ns[2] = Kernel_ch2;
        'd11: K_ch2_3_reg_ns[3] = Kernel_ch2; 
        default: K_ch2_3_reg_ns = K_ch2_3_reg;
    endcase
end
//=====================================================================
// Systolic Array
//=====================================================================
//SA selector
always @(*) begin
    case(count)
        'd1:SA_img[0] = Opt_reg ? 0 , Img_reg[0];
        'd2:SA_img[0] = Opt_reg ? 0 , Img_reg[0];
        'd3:SA_img[0] = Opt_reg ? 0 , Img_reg[1];
        'd4:SA_img[0] = Opt_reg ? 0 , Img_reg[2];
        'd5:SA_img[0] = Opt_reg ? 0 , Img_reg[3];
        'd6:SA_img[0] = Opt_reg ? 0 , Img_reg[3];
        default: SA_img = SA_img_2to0reg;
    endcase
end
always @(*) begin
    case(count)
        'd2:SA_img[1] = Opt_reg ? 0 , Img_reg[0];
        'd3:SA_img[1] = Opt_reg ? 0 , Img_reg[1];
        'd4:SA_img[1] = Opt_reg ? 0 , Img_reg[2];
        'd5:SA_img[1] = Opt_reg ? 0 , Img_reg[3];
        'd6:SA_img[1] = Opt_reg ? 0 , Img_reg[4];
        'd7:SA_img[1] = Opt_reg ? 0 , Img_reg[4];
        default: SA_img = SA_img_3to1reg;
    endcase
end
always @(*) begin
    case (count)
        'd3:SA_img[2] = Opt_reg ? 0 , Img_reg[0];
        'd4:SA_img[2] = Opt_reg ? 0 , Img_reg[0];
        'd5:SA_img[2] = Opt_reg ? 0 , Img_reg[1];
        'd6:SA_img[2] = Opt_reg ? 0 , Img_reg[2];
        'd7:SA_img[2] = Opt_reg ? 0 , Img_reg[3];
        'd8:SA_img[2] = Opt_reg ? 0 , Img_reg[4]; 
        default: 
    endcase
end
endmodule
