module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
//==============================================//
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==========================================================//
//             Parameter and Integer and Register           //
//==========================================================//
// parameter IDLE = 3'd0, GUEST = 3'd1, HOME = 3'd2, OUT = 3'd3;
parameter IDLE = 2'd0, GUEST = 2'd2, HOME = 2'd3, OUT = 2'd1;
reg [1:0] cs, ns; // Current state, Next state
reg home_win_check; // Home team win check
reg home_win_assure; // Home team
reg base1, base2, base3; // Base status
reg base1_ns, base2_ns, base3_ns; // Next base status
reg [3:0] score_A_temp, score_A_temp_ns; // Next score status
reg [2:0] score_B_temp, score_B_temp_ns; // Next score status
reg [2:0] score_temp; // Next score status


wire change_of_sides;
wire hit_and_run;
reg [1:0] out_num, out_num_ns;
//============================================================================================//
//                                            FSM                                             //
//============================================================================================//
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)  cs <= IDLE;
        else        cs <= ns;
    end
    always @(*) begin
        case (cs)
            IDLE    : ns = in_valid       ? GUEST : cs;
            GUEST   : ns = half           ? HOME  : cs;
            HOME    : ns = in_valid       ? (half ? HOME : GUEST) : OUT;
            OUT     : ns = IDLE;
            default : ns = IDLE; 
        endcase
    end
    // always @(posedge half) begin
    //     if (inning == 3)
    //         home_win_assure <= (score_A_temp < score_B_temp);
    //     else
    //         home_win_assure <= 0;
    // end
    always @(*) begin
        if(ns == IDLE)
            home_win_check = 0;
        else if(inning == 'd3 & change_of_sides & score_B_temp > score_A_temp)
            home_win_check = 1;
        else
            home_win_check = home_win_assure;
    end
    always @(posedge clk) begin
            home_win_assure <= home_win_check; 
    end
//============================================================================================//
//                                          Base Logic                                        //
//============================================================================================//
    assign hit_and_run = out_num=='d2;
    assign change_of_sides = out_num_ns=='d3;
    // assign hit_and_run = out_num[1];
    // assign change_of_sides = out_num_ns[1]&out_num_ns[0];
//out_num calculation-------------------------------------------------------------------------//
    always @(posedge clk) begin
        out_num <= change_of_sides ? 0 : out_num_ns; 
    end
    always @(*) begin
        out_num_ns = 0;
        if (in_valid) begin
            case (action)
                3'd5:out_num_ns = out_num + 1'b1;
                3'd6:out_num_ns = hit_and_run ? 2'd3 : out_num + 1'b1 + base1;
                3'd7:out_num_ns = out_num + 1'b1; 
                default: out_num_ns = out_num;
            endcase
        end 
    end
    // always @(*) begin
    //     out_temp = 0;

    // end
    // always @(*) begin
    //     if(in_valid)begin
    //         if(action==3'd5 || action==3'd7)
    //             out_num_ns = out_num + 1'b1;
    //         else if(action==3'd6)
    //             out_num_ns = hit_and_run ? 2'd3 : out_num + 1'b1 + base1;
    //         else
    //             out_num_ns = out_num;
    //     end
    //     else
    //         out_num_ns = 0;
    // end
//base1, base2, base3 calculation-------------------------------------------------------------//
    always @(*) begin
        base1_ns = 0;
        case (ns)
            GUEST: begin
                if(change_of_sides)begin
                    base1_ns = 0;
                end else begin
                    case (action)
                        3'd0: base1_ns = 1;
                        3'd1: base1_ns = 1;
                        3'd7: base1_ns = base1;
                    endcase
                end
            end 
            HOME: begin
                if(change_of_sides)begin
                    base1_ns = 0;
                end else begin
                    case (action)
                        3'd0: base1_ns = 1;
                        3'd1: base1_ns = 1;
                        3'd7: base1_ns = base1;
                    endcase
                end
            end
        endcase
    end
    always @(*) begin
        base2_ns = 0;
        case (ns)
            GUEST: begin
                if(change_of_sides)begin
                    base2_ns = 0;
                end else begin
                    case (action)
                        3'd0: base2_ns = base1 ? 1 : base2;
                        3'd1: base2_ns = hit_and_run ? 0 : base1;
                        3'd2: base2_ns = 1;
                        3'd5: base2_ns = base1;
                        3'd7: base2_ns = base2;
                    endcase
                end
            end
            HOME: begin
                if(change_of_sides)begin
                    base2_ns = 0;
                end else begin
                    case (action)
                        3'd0: base2_ns = base1 ? 1 : base2;
                        3'd1: base2_ns = hit_and_run ? 0 : base1;
                        3'd2: base2_ns = 1;
                        3'd5: base2_ns = base1;
                        3'd7: base2_ns = base2;
                    endcase
                end
            end
        endcase
    end
    always @(*) begin
        base3_ns = 0;
        case (ns)
            GUEST: begin
                if(change_of_sides)begin
                    base3_ns = 0;
                end else begin
                    case (action)
                        // 3'd0: base3_ns = base1 ? base2 : base3;
                        3'd0: base3_ns = (base1 & base2) ? 1 : base3;
                        3'd1: base3_ns = out_num[1] ? base1 : base2;
                        3'd2: base3_ns = !hit_and_run ? base1 : 0;
                        3'd3: base3_ns = 1;
                        3'd4: base3_ns = 0;
                        3'd5: base3_ns = base2;
                        3'd6: base3_ns = base2;
                    endcase
                end
            end
            HOME: begin
                if(change_of_sides)begin
                    base3_ns = 0;
                end else begin
                    case (action)
                        // 3'd0: base3_ns = base1 ? base2 : base3;
                        3'd0: base3_ns = (base1 & base2) ? 1 : base3;
                        3'd1: base3_ns = out_num[1] ? base1 : base2;
                        3'd2: base3_ns = !hit_and_run ? base1 : 0;
                        3'd3: base3_ns = 1;
                        3'd4: base3_ns = 0;
                        3'd5: base3_ns = base2;
                        3'd6: base3_ns = base2;
                    endcase
                end
            end
        endcase
    end
    always @(posedge clk) begin
        base1 <= base1_ns;
        base2 <= base2_ns;
        base3 <= base3_ns;
    end
//============================================================================================//
//                                          Score Logic                                       //
//============================================================================================//
//2634
always @(*) begin
    score_temp = 1'b0;
    case (ns)
        GUEST: begin
            case (action)
                3'd0: score_temp = base1&base2&base3;
                3'd1: score_temp = hit_and_run ? base3 + base2         : base3 ? 1 : 0;
                3'd2: score_temp = hit_and_run ? base3 + base2 + base1 : base3 + base2;
                3'd3: score_temp = base3 + base2 + base1;
                3'd4: score_temp = base3 + base2 + base1 + 1'b1;
                3'd5: score_temp = base3 ? 1 : 0;
                3'd6: score_temp = change_of_sides ? 1'b0 : base3;   
                3'd7: score_temp = hit_and_run ? 1'b0 : base3;
            endcase
        end
        HOME: begin
            case (action)
                3'd0: score_temp = base1&base2&base3;
                3'd1: score_temp = hit_and_run ? base3 + base2         : base3 ? 1 : 0;
                3'd2: score_temp = hit_and_run ? base3 + base2 + base1 : base3 + base2;
                3'd3: score_temp = base3 + base2 + base1;
                3'd4: score_temp = base3 + base2 + base1 + 1'b1;
                3'd5: score_temp = base3 ? 1 : 0;
                3'd6: score_temp = change_of_sides ? 1'b0 : base3;   
                3'd7: score_temp = hit_and_run ? 1'b0 : base3;
            endcase
        end
    endcase
end
//============================================================================================//
//share adder
wire [3:0]score_sel;
assign score_sel = (ns==GUEST ? score_A_temp : score_B_temp) + score_temp;
// assign score_sel = (half ? score_B_temp : score_A_temp) + score_temp;
//============================================================================================//
always @(*) begin
    score_A_temp_ns = score_A_temp;
    case (ns)
        IDLE :score_A_temp_ns = 1'b0; 
        GUEST:score_A_temp_ns = score_sel;
    endcase
end
always @(*) begin
    score_B_temp_ns = score_B_temp;
    case (ns)
        IDLE : score_B_temp_ns = 1'b0;
        HOME : score_B_temp_ns = home_win_assure ? score_B_temp : score_sel;
    endcase
end
always @(posedge clk) begin
    score_A_temp <= score_A_temp_ns;
    score_B_temp <= score_B_temp_ns;
end
//============================================================================================//
//                                     Output Logic                                           //
//============================================================================================//
always @(*) begin
    if(cs == OUT)
        out_valid = 1'b1;
    else
        out_valid = 1'b0;
end
always @(*) begin
    if(out_valid)begin
        score_A = score_A_temp;
        score_B = score_B_temp;
    end
    else begin
        score_A = 'd0;
        score_B = 'd0;
    end
end
always @(*) begin
    if(out_valid)begin
        if(score_A < score_B)
            result = 'd1;
        else if(score_A > score_B)
            result = 'd0;
        else
            result = 'd2; 
    end
    else
        result = 'd0;
end







endmodule
