`timescale 1ns / 1ps

module conv_core (
    input wire clk,
    input wire reset,
    input wire valid_in,
    
    // The 3x3 Window Inputs
    input wire [7:0] p1, input wire [7:0] p2, input wire [7:0] p3,
    input wire [7:0] p4, input wire [7:0] p5, input wire [7:0] p6,
    input wire [7:0] p7, input wire [7:0] p8, input wire [7:0] p9,
    
    input wire [1:0] filter_select, // 0: Blur, 1: Edge Detect, 2: Sharpen

    output reg [7:0] pixel_out,
    output reg valid_out
);

    // Use signed 16-bit integers for the math so we don't overflow or underflow during calculation
    reg signed [15:0] sum;
    
    // Intermediate sums to keep the math clean
    wire signed [15:0] sp1 = {8'b0, p1}; wire signed [15:0] sp2 = {8'b0, p2}; wire signed [15:0] sp3 = {8'b0, p3};
    wire signed [15:0] sp4 = {8'b0, p4}; wire signed [15:0] sp5 = {8'b0, p5}; wire signed [15:0] sp6 = {8'b0, p6};
    wire signed [15:0] sp7 = {8'b0, p7}; wire signed [15:0] sp8 = {8'b0, p8}; wire signed [15:0] sp9 = {8'b0, p9};

    always @(posedge clk) begin
        if (reset) begin
            pixel_out <= 0;
            valid_out <= 0;
            sum <= 0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                case (filter_select)
                    2'd0: begin
                        // --- BLUR (Box-like Blur) ---
                        // Math: Average of center and cross neighbors
                        // Sum = (p2 + p4 + p5*4 + p6 + p8) / 8
                        sum = (sp2 + sp4 + (sp5 << 2) + sp6 + sp8) >> 3;
                    end
                    
                    2'd1: begin
                        // --- EDGE DETECTION (Laplacian) ---
                        // Center is multiplied by 4, subtract the top, bottom, left, right neighbors
                        // Math: 4*p5 - p2 - p4 - p6 - p8
                        sum = (sp5 << 2) - sp2 - sp4 - sp6 - sp8;
                    end
                    
                    2'd2: begin
                        // --- SHARPEN ---
                        // Center is multiplied by 5, subtract the top, bottom, left, right neighbors
                        // Math: 5*p5 - p2 - p4 - p6 - p8
                        sum = (sp5 * 5) - sp2 - sp4 - sp6 - sp8;
                    end
                    
                    default: begin
                        // Pass-through center pixel
                        sum = sp5;
                    end
                endcase

                // --- CLAMPING LOGIC ---
                // If the math resulted in a negative number, clamp to 0 (Black)
                if (sum < 0) begin
                    pixel_out <= 8'd0;
                end 
                // If the math resulted in a number > 255, clamp to 255 (White)
                else if (sum > 255) begin
                    pixel_out <= 8'd255;
                end 
                // Otherwise, it's a safe 8-bit value
                else begin
                    pixel_out <= sum[7:0];
                end
            end
        end
    end
endmodule