`timescale 1ns / 1ps

module color_processor (
    input wire clk,
    input wire reset,
    input wire valid_in,         
    input wire [23:0] rgb_in,    // 24-bit input from ROM (Format: R[23:16], G[15:8], B[7:0])
    input wire [1:0] mode,       // Switch inputs to choose the effect
    
    output reg [23:0] rgb_out,   // 24-bit color output
    output reg [7:0] gray_out,   // 8-bit grayscale output (fed to the Convolution core)
    output reg valid_out         
);

    // Extract individual color channels for readability
    wire [7:0] r = rgb_in[23:16];
    wire [7:0] g = rgb_in[15:8];
    wire [7:0] b = rgb_in[7:0];

    // Hardware Math for Grayscale
    // Real math: Gray = 0.299*R + 0.587*G + 0.114*B
    // Multiply by 256 (which is an 8-bit shift) to avoid decimals
    // 0.299 * 256 ≈ 77  |  0.587 * 256 ≈ 150  |  0.114 * 256 ≈ 29
    wire [15:0] gray_calc = (r * 8'd77) + (g * 8'd150) + (b * 8'd29);
    wire [7:0] gray_pixel = gray_calc[15:8]; // Shift right by 8 (divide by 256)

    always @(posedge clk) begin
        if (reset) begin
            rgb_out <= 24'd0;
            gray_out <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            // Pass the valid signal down the pipeline
            valid_out <= valid_in;
            
            if (valid_in) begin
                // Always calculate grayscale output for the convolution engine
                gray_out <= gray_pixel;

                // Determine the 24-bit output based on the user's mode switch
                case (mode)
                    2'b00: begin
                        // Mode 0: Pass-through (Normal Image)
                        rgb_out <= rgb_in; 
                    end
                    2'b01: begin
                        // Mode 1: Color Invert (Negative Image)
                        // Inverting bits (~r) is mathematically 255 - r
                        rgb_out <= {~r, ~g, ~b}; 
                    end
                    2'b10: begin
                        // Mode 2: Grayscale output on the 24-bit channel
                        // We map the 8-bit gray value to all three R, G, and B channels
                        rgb_out <= {gray_pixel, gray_pixel, gray_pixel}; 
                    end
                    default: begin
                        rgb_out <= rgb_in;
                    end
                endcase
            end
        end
    end
endmodule
