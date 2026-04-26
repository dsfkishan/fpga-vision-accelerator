`timescale 1ns / 1ps

module line_buffer #(
    parameter WIDTH = 128
)(
    input wire clk,
    input wire reset,
    input wire valid_in,
    input wire [7:0] pixel_in,   // This is the gray_out from the color_processor

    output reg [7:0] row0_out,   // Oldest pixel (2 rows up)
    output reg [7:0] row1_out,   // Middle pixel (1 row up)
    output wire [7:0] row2_out,  // Newest pixel (current row)
    output reg valid_out
);

    // Create memory for two rows
    reg [7:0] line_buf_0 [0:WIDTH-1]; 
    reg [7:0] line_buf_1 [0:WIDTH-1]; 

    reg [7:0] col_ptr;
    
    // NEW: A 16-bit counter to track how many pixels have entered the pipeline
    // (16 bits allows image widths up to 32,768, plenty big enough for 1080p or 4K later!)
    reg [15:0] pixel_count; 

    // The current row is just the pixel coming in right now
    assign row2_out = pixel_in; 

    always @(posedge clk) begin
        if (reset) begin
            col_ptr <= 0;
            valid_out <= 0;
            row0_out <= 0;
            row1_out <= 0;
            pixel_count <= 0; // Reset the fill counter
        end else begin
            
            if (valid_in) begin
                // 1. Output the old pixels from the exact same column
                row1_out <= line_buf_0[col_ptr];
                row0_out <= line_buf_1[col_ptr];

                // 2. Write the newer pixels into the buffers (shifting them down)
                line_buf_0[col_ptr] <= pixel_in;            
                line_buf_1[col_ptr] <= line_buf_0[col_ptr]; 

                // 3. Move the column pointer left to right
                if (col_ptr == WIDTH - 1) begin
                    col_ptr <= 0; 
                end else begin
                    col_ptr <= col_ptr + 1;
                end
                
                // --- THE PIPELINE FILL GATEKEEPER ---
                // Wait until 2 complete rows (2 * WIDTH) have filled the buffer
                if (pixel_count < (2 * WIDTH)) begin
                    pixel_count <= pixel_count + 1;
                    valid_out <= 1'b0; // FORCE valid LOW. Pipeline is warming up.
                end else begin
                    valid_out <= 1'b1; // Pipeline is full! Let data flow.
                end

            end else begin
                // If no valid data is coming in, no valid data goes out
                valid_out <= 1'b0;
            end
        end
    end
endmodule