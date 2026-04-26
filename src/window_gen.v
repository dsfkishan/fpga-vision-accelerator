`timescale 1ns / 1ps

module window_gen (
    input wire clk,
    input wire reset,
    input wire valid_in,
    input wire [7:0] row0_in,  // Top row from line buffer
    input wire [7:0] row1_in,  // Middle row from line buffer
    input wire [7:0] row2_in,  // Bottom row (current pixel)

    // 3x3 Window Outputs
    output reg [7:0] p1, output reg [7:0] p2, output reg [7:0] p3, // Top row
    output reg [7:0] p4, output reg [7:0] p5, output reg [7:0] p6, // Mid row
    output reg [7:0] p7, output reg [7:0] p8, output reg [7:0] p9, // Bot row
    
    output reg valid_out
);

    // We delay the valid signal by 2 clock cycles because it takes 
    // 2 cycles for a new pixel to shift all the way to the left side of the 3x3 window.
    reg valid_d1;

    always @(posedge clk) begin
        if (reset) begin
            p1 <= 0; p2 <= 0; p3 <= 0;
            p4 <= 0; p5 <= 0; p6 <= 0;
            p7 <= 0; p8 <= 0; p9 <= 0;
            valid_d1 <= 0;
            valid_out <= 0;
        end else begin
            // Shift the valid signal
            valid_d1 <= valid_in;
            valid_out <= valid_d1;

            if (valid_in) begin
                // --- Top Row Shift ---
                p3 <= row0_in; // Newest pixel enters on the right
                p2 <= p3;      // Old right pixel shifts to middle
                p1 <= p2;      // Old middle pixel shifts to left

                // --- Middle Row Shift ---
                p6 <= row1_in;
                p5 <= p6;
                p4 <= p5;

                // --- Bottom Row Shift ---
                p9 <= row2_in;
                p8 <= p9;
                p7 <= p8;
            end
        end
    end
endmodule