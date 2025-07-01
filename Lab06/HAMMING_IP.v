//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0]  IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================
wire [3:0] partial_value[IP_BIT+4-1:0];
genvar i;
generate
    for ( i = 0 ; i < IP_BIT + 4; i = i + 1) begin
        assign partial_value[i] = IN_code[IP_BIT + 4 - 1 - i] ? i + 1 : 4'd0;
    end
endgenerate

wire [3:0]dec_value[IP_BIT + 4 - 1:0]; ;

generate
    for ( i = 0 ; i < IP_BIT + 4; i = i + 1) begin : loop_dec
        wire [3:0]dec_temp;
        assign dec_temp = partial_value[i];
        if(i == 0) begin
            // for ( j = 0 ; j < 4; j = j + 1) begin
            //     assign dec_value[0][j] = dec_temp[j];
            // end
            assign dec_value[0] = dec_temp;
        end
        else begin
            // for ( j = 0 ; j < 4; j = j + 1) begin
            //     assign dec_value[i][j] = dec_temp[j] ^ loop_dec[i-1].dec_value[i-1][j];
            // end
            assign dec_value[i] = dec_temp ^ dec_value[i-1];
        end
    end
endgenerate

wire [IP_BIT+4-1:0] OUT_code_temp;
generate
    for ( i = 0 ; i < IP_BIT + 4 ; i = i + 1) begin
        assign OUT_code_temp[i] = dec_value[IP_BIT+4-1] == (IP_BIT + 4 - i ) ? ~IN_code[i] : IN_code[i];
    end
endgenerate

always @(*) begin
    OUT_code[IP_BIT - 1] = OUT_code_temp[IP_BIT + 1];
    OUT_code[IP_BIT - 2] = OUT_code_temp[IP_BIT - 1];
    OUT_code[IP_BIT - 3] = OUT_code_temp[IP_BIT - 2];
    OUT_code[IP_BIT - 4] = OUT_code_temp[IP_BIT - 3];
end
generate
    for ( i = 0 ; i < IP_BIT - 4; i = i + 1) begin
        always @(*) begin
            OUT_code[i] = OUT_code_temp[i];
        end
    end
endgenerate


endmodule