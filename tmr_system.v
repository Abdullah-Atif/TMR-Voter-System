module tmr_system(
    input clk,              
    input [15:0] sw,        // SW[5:0]=A, SW[11:6]=B, SW[15:12]=Op
    input btnC,             // Corrupt Core A
    input btnU,             // Corrupt Core B
    input btnD,             // Corrupt Core C
    output reg [11:0] led,  // Result Display (LD0 to LD11)
    output led15_r,         // Irrecoverable Failure (Red LED LD17)
    output [7:0] an,        // 7-Seg Anodes
    output [6:0] seg        // 7-Seg Cathodes
);

    wire [11:0] resA_raw, resB_raw, resC_raw;
    reg [11:0] resA, resB, resC;
    reg [2:0] display_state; // 0:None, 1:A, 2:B, 3:C, 4:F (Failure)
    reg red_led_reg;

    // Instantiate 3 Identical ALU Cores
    alu_core coreA (.A(sw[5:0]), .B(sw[11:6]), .op(sw[15:12]), .result(resA_raw));
    alu_core coreB (.A(sw[5:0]), .B(sw[11:6]), .op(sw[15:12]), .result(resB_raw));
    alu_core coreC (.A(sw[5:0]), .B(sw[11:6]), .op(sw[15:12]), .result(resC_raw));

    // Radiation Simulator (Fault Injection)
    always @(*) begin
        resA = btnC ? 12'd0 : resA_raw;   // Stuck-at-0
        resB = btnU ? 12'hFFF : resB_raw; // Stuck-at-1 (all 1s)
        resC = btnD ? ~resC_raw : resC_raw;
    end

    // Majority Voter Logic 
    always @(*) begin
        red_led_reg = 1'b0;
        display_state = 3'd0;
        led = 12'd0;

        // All three agree → Normal Operation
        if ((resA == resB) && (resB == resC)) begin
            led = resA;
            red_led_reg = 1'b0;
            display_state = 3'd0;
        end

        // Core C is unmatched (A and B agree)
        else if (resA == resB) begin
            led = resA;
            display_state = 3'd3; // Show "C"
        end

        // Core B is unmatched (A and C agree)
        else if (resA == resC) begin
            led = resA;
            display_state = 3'd2; // Show "B"
        end

        //  Core A is unmatched (B and C agree)
        else if (resB == resC) begin
            led = resB;
            display_state = 3'd1; // Show "A"
        end

        //  All three disagree → Irrecoverable Failure
        else begin
            led = 12'd0;
            red_led_reg = 1'b1;
            display_state = 3'd4; // Show "F"
        end
    end

    assign led15_r = red_led_reg;

    // 7-Segment Logic (Active Low: 0 = Segment ON)
    assign an = 8'b11111110; 
    reg [6:0] seg_out;
    
    always @(*) begin
        case(display_state)
            3'd1:    seg_out = 7'b0001000; // "A"
            3'd2:    seg_out = 7'b0000000; // "b"
            3'd3:    seg_out = 7'b1000110; // "C"
            3'd4:    seg_out = 7'b0001110; // "F"
            default: seg_out = 7'b1111111; // OFF
        endcase
    end

    assign seg = seg_out;

endmodule


// ALU Module (UNCHANGED)
module alu_core(
    input [5:0] A, input [5:0] B, input [3:0] op,
    output reg [11:0] result
);

    always @(*) begin
        case(op)
            4'b0000: result = A + B;
            4'b0001: result = A - B;
            4'b0010: result = A * B;
            4'b0011: result = A & B;
            4'b0100: result = A | B;
            4'b0101: result = A ^ B;
            4'b0110: result = ~(A & B);
            4'b0111: result = ~(A | B);
            4'b1000: result = A << 1;
            4'b1001: result = A >> 1;
            4'b1010: result = (A > B) ? 12'd1 : 12'd0;
            4'b1011: result = (A == B) ? 12'd1 : 12'd0;
            4'b1100: result = {6'b0, ~A};
            4'b1101: result = {6'b0, ~B};
            4'b1110: result = A + 1'b1;
            4'b1111: result = B - 1'b1;
            default: result = 12'd0;
        endcase
    end

endmodule