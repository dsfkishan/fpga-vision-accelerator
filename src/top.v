`timescale 1ns / 1ps

module top #(
    parameter WIDTH = 128,
    parameter HEIGHT = 128
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] color_mode,    
    input wire [1:0] filter_select, 
    input wire bypass_conv,         

    output reg [23:0] final_pixel,
    output reg final_valid
);

    wire [13:0] rom_addr; wire addr_valid; wire [23:0] raw_rgb;
    wire [23:0] processed_rgb; wire [7:0] processed_gray; wire color_valid;
    
    // --- 1 & 2. Address Gen & ROM ---
    address_gen #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) addr_inst (.clk(clk), .reset(reset), .enable(enable), .x(), .y(), .address(rom_addr), .valid_out(addr_valid));
    image_rom rom_inst (.clk(clk), .address(rom_addr), .rgb_data(raw_rgb));

    // --- 3. Color Processor ---
    color_processor color_inst (.clk(clk), .reset(reset), .valid_in(addr_valid), .rgb_in(raw_rgb), .mode(color_mode), .rgb_out(processed_rgb), .gray_out(processed_gray), .valid_out(color_valid));

    // ==========================================
    //  THE TRIPLE PARALLEL CONVOLUTION ENGINE
    // ==========================================

    // --- RED CHANNEL ---
    wire [7:0] lb_r_0, lb_r_1, lb_r_2; wire lb_r_valid;
    wire [7:0] pr1, pr2, pr3, pr4, pr5, pr6, pr7, pr8, pr9; wire win_r_valid;
    wire [7:0] conv_r_pixel; wire conv_r_valid;

    line_buffer #(.WIDTH(WIDTH)) lb_R (.clk(clk), .reset(reset), .valid_in(color_valid), .pixel_in(processed_rgb[23:16]), .row0_out(lb_r_0), .row1_out(lb_r_1), .row2_out(lb_r_2), .valid_out(lb_r_valid));
    window_gen win_R (.clk(clk), .reset(reset), .valid_in(lb_r_valid), .row0_in(lb_r_0), .row1_in(lb_r_1), .row2_in(lb_r_2), .p1(pr1), .p2(pr2), .p3(pr3), .p4(pr4), .p5(pr5), .p6(pr6), .p7(pr7), .p8(pr8), .p9(pr9), .valid_out(win_r_valid));
    conv_core conv_R (.clk(clk), .reset(reset), .valid_in(win_r_valid), .p1(pr1), .p2(pr2), .p3(pr3), .p4(pr4), .p5(pr5), .p6(pr6), .p7(pr7), .p8(pr8), .p9(pr9), .filter_select(filter_select), .pixel_out(conv_r_pixel), .valid_out(conv_r_valid));

    // --- GREEN CHANNEL ---
    wire [7:0] lb_g_0, lb_g_1, lb_g_2; wire lb_g_valid;
    wire [7:0] pg1, pg2, pg3, pg4, pg5, pg6, pg7, pg8, pg9; wire win_g_valid;
    wire [7:0] conv_g_pixel; 

    line_buffer #(.WIDTH(WIDTH)) lb_G (.clk(clk), .reset(reset), .valid_in(color_valid), .pixel_in(processed_rgb[15:8]), .row0_out(lb_g_0), .row1_out(lb_g_1), .row2_out(lb_g_2), .valid_out(lb_g_valid));
    window_gen win_G (.clk(clk), .reset(reset), .valid_in(lb_g_valid), .row0_in(lb_g_0), .row1_in(lb_g_1), .row2_in(lb_g_2), .p1(pg1), .p2(pg2), .p3(pg3), .p4(pg4), .p5(pg5), .p6(pg6), .p7(pg7), .p8(pg8), .p9(pg9), .valid_out(win_g_valid));
    conv_core conv_G (.clk(clk), .reset(reset), .valid_in(win_g_valid), .p1(pg1), .p2(pg2), .p3(pg3), .p4(pg4), .p5(pg5), .p6(pg6), .p7(pg7), .p8(pg8), .p9(pg9), .filter_select(filter_select), .pixel_out(conv_g_pixel), .valid_out());

    // --- BLUE CHANNEL ---
    wire [7:0] lb_b_0, lb_b_1, lb_b_2; wire lb_b_valid;
    wire [7:0] pb1, pb2, pb3, pb4, pb5, pb6, pb7, pb8, pb9; wire win_b_valid;
    wire [7:0] conv_b_pixel; 

    line_buffer #(.WIDTH(WIDTH)) lb_B (.clk(clk), .reset(reset), .valid_in(color_valid), .pixel_in(processed_rgb[7:0]), .row0_out(lb_b_0), .row1_out(lb_b_1), .row2_out(lb_b_2), .valid_out(lb_b_valid));
    window_gen win_B (.clk(clk), .reset(reset), .valid_in(lb_b_valid), .row0_in(lb_b_0), .row1_in(lb_b_1), .row2_in(lb_b_2), .p1(pb1), .p2(pb2), .p3(pb3), .p4(pb4), .p5(pb5), .p6(pb6), .p7(pb7), .p8(pb8), .p9(pb9), .valid_out(win_b_valid));
    conv_core conv_B (.clk(clk), .reset(reset), .valid_in(win_b_valid), .p1(pb1), .p2(pb2), .p3(pb3), .p4(pb4), .p5(pb5), .p6(pb6), .p7(pb7), .p8(pb8), .p9(pb9), .filter_select(filter_select), .pixel_out(conv_b_pixel), .valid_out());

    // ==========================================

    // --- 7. Pipeline Balancing & Output Routing ---
    reg [23:0] rgb_delay_1, rgb_delay_2, rgb_delay_3;

    always @(posedge clk) begin
        if (reset) begin
            rgb_delay_1 <= 0; rgb_delay_2 <= 0; rgb_delay_3 <= 0;
            final_pixel <= 0; final_valid <= 0;
        end else begin
            rgb_delay_1 <= processed_rgb;
            rgb_delay_2 <= rgb_delay_1;
            rgb_delay_3 <= rgb_delay_2;

            if (bypass_conv) begin
                final_pixel <= rgb_delay_3; 
                final_valid <= conv_r_valid; // All pipelines finish at the same time, so we just check Red
            end else begin
                // Recombine the three separate math outputs into one full-color pixel
                final_pixel <= {conv_r_pixel, conv_g_pixel, conv_b_pixel}; 
                final_valid <= conv_r_valid;
            end
        end
    end
endmodule
