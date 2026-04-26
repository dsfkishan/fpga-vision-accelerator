`timescale 1ns / 1ps

module address_gen #(
    parameter WIDTH = 128,
    parameter HEIGHT = 128
)(
    input wire clk,
    input wire reset,
    input wire enable,
    
    output reg [7:0] x,          // X coordinate (0 to 127)
    output reg [7:0] y,          // Y coordinate (0 to 127)
    output reg [13:0] address,   // 1D Memory Address
    output reg valid_out         
);

    always @(posedge clk) begin
        if (reset) begin
            x <= 0;
            y <= 0;
            address <= 0;
            valid_out <= 0;
        end else if (enable) begin
            valid_out <= 1; 

            // Coordinate counters
            if (x == WIDTH - 1) begin
                x <= 0;
                if (y == HEIGHT - 1) begin
                    y <= 0; // Reached the end of the image, reset to top
                end else begin
                    y <= y + 1; // Move to the next row
                end
            end else begin
                x <= x + 1; // Move to the next pixel in the row
            end

            address <= {y[6:0], x[6:0]}; 
            
        end else begin
            valid_out <= 0;
        end
    end
endmodule
