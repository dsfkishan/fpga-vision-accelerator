`timescale 1ns / 1ps
 
module top_tb;

    reg clk;
    reg reset;
    reg enable;
    reg [1:0] color_mode;
    reg [1:0] filter_select;
    reg bypass_conv;

    wire [23:0] final_pixel;
    wire final_valid;

    // Instantiate TOP
    top #(.WIDTH(128), .HEIGHT(128)) uut (
        .clk(clk), .reset(reset), .enable(enable),
        .color_mode(color_mode), .filter_select(filter_select), .bypass_conv(bypass_conv),
        .final_pixel(final_pixel), .final_valid(final_valid)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    integer file_out;
    integer pixel_count;

    initial begin
        // --- USE ABSOLUTE PATH HERE ---
        // Change this path to exactly match your Python folder location so Vivado doesn't hide it!
        file_out = $fopen("C:/Users/dskfu/OneDrive/Desktop/python_practice/image_processing_engine/final_edge_image.mem", "w");
        
        pixel_count = 0;
        clk = 0; reset = 1; enable = 0;
        
        // CONFIGURATION: Edge Detection Setup
        color_mode = 2'b10;      // Normal color fed into pipeline
        filter_select = 2'd0;    // 1 = Edge Detection
        bypass_conv = 1'b1;      // 0 = Route convolution to output

        #20;
        reset = 0;
        #20;
        enable = 1;
        
        $display("🚀 Processing Full Image through Hardware Accelerator...");
    end

    // Write output to file
    always @(posedge clk) begin
        if (final_valid) begin
            $fdisplay(file_out, "%06x", final_pixel);
            pixel_count = pixel_count + 1;
            
            if (pixel_count == 16384) begin
                $display("✅ Acceleration Complete! Hardware output saved.");
                $fclose(file_out);
                $stop;
            end
        end
    end
endmodule