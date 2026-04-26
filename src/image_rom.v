`timescale 1ns / 1ps

module image_rom (
    input wire clk,
    input wire [13:0] address,   // 14-bit address for 16,384 pixels
    output reg [23:0] rgb_data   // 24-bit output (8-bit Red, Green, Blue)
);

    // Declare the memory array: 16,384 slots, each 24 bits wide
    reg [23:0] memory_array [0:16383];

    // Load the hex file into the memory array at the start of simulation/synthesis
    initial begin
        $readmemh("image_in.mem", memory_array);
    end

    // Synchronous read: Outputs data exactly one clock cycle after the address is requested
    // This is required for Vivado to synthesize this as true Block RAM (BRAM)
    always @(posedge clk) begin
        rgb_data <= memory_array[address];
    end

endmodule