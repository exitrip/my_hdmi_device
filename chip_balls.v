/*
my_hdmi_device

Copyright (C) 2021  Hirosh Dabui <hirosh@dabui.de>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/
//`define ARTY7
`define I9PLUS
//`define NANO_4K
`ifdef ICOBOARD
  `define HX8X
`endif
`ifdef BLACKICE_MX
  `define HX8X
`endif
module chip_balls(
`ifdef ICOBOARD
           input clk_100mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output reg [7:0] led,
           output reg [2:0] led1 = 4'b101
`elsif BLACKICE_MX
           input clk_25mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output reg [7:0] led,
           output reg [3:0] led1 = 4'b1001
`elsif ARTY7
           input clk_100mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output [3:0] led
`elsif I9PLUS
           input clk_25mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output led
`elsif COLORLIGHTI5
           input clk_25mhz,
           output [3:0] gpdi_dp,
           output led
`elsif NANO_4K
          input clk_27mhz,
          output [3:0] hdmi_p,
          output [3:0] hdmi_n,
          output       led
`else /* ulx3s */
           input clk_25mhz,
           output [3:0] gpdi_dp,
           output [7:0] led
`endif
       );

reg [7:0] vga_red;
reg [7:0] vga_blue;
reg [7:0] vga_green;

reg vga_hsync;
reg vga_vsync;
reg vga_blank;

localparam SYSTEM_CLK_MHZ = 25;
`ifdef HX8X
localparam DDR_HDMI_TRANSFER = 1;
`elsif ARTY7
localparam DDR_HDMI_TRANSFER = 1;
`elsif I9PLUS
localparam DDR_HDMI_TRANSFER = 0;
`elsif NANO_4K
localparam DDR_HDMI_TRANSFER = 1;
`else /* ulx3s or i9+*/
localparam DDR_HDMI_TRANSFER = 1;
`endif

// calculate video timings
localparam x_res             = 640;
localparam y_res             = 480;
localparam frame_rate        = 60;

`include "video_timings.v"

// clock generator
`ifdef BLACKICE_MX
wire clk_x5;
wire tmds_clk = clk_x5;
wire pclk = clk_25mhz;
wire locked;
SB_PLL40_CORE #(
                  .FEEDBACK_PATH ("SIMPLE"),
                  .DIVR (4'b0000),
                  .DIVF (7'b0100111),
                  .DIVQ (3'b011),
                  .FILTER_RANGE (3'b010)
              ) uut (
                  .RESETB         (1'b1),
                  .BYPASS         (1'b0),
                  .REFERENCECLK   (clk_25mhz),
                  .PLLOUTGLOBAL   (clk_x5) // 5xpclk = 125MHz tmds clock
              );
`elsif ICOBOARD
wire clk_x5;
wire tmds_clk = clk_x5;
wire pclk = clk_25mhz;
wire locked;
pll125 pll125_i(clk_100mhz, clk_x5, locked);
reg [4:0] clk_25mhz = 5'b000_11;
always @(posedge clk_x5) begin
    clk_25mhz <= {clk_25mhz[0], clk_25mhz[4:1]};
end
assign pclk = clk_25mhz[0];
`elsif ARTY7

wire clk_25mhz;
wire clk_x5;
wire tmds_clk = clk_x5;
wire pclk = clk_25mhz;
wire locked;

clk_tmds
    #(
        .DDR_ENABLED(DDR_HDMI_TRANSFER)
    )
    clk_tmds_i
    (
        clk_x5,
        clk_25mhz,
        clk_100mhz
    );

`elsif I9PLUS

wire clk_100mhz;
wire clk_x5;
wire tmds_clk = clk_x5;
wire pclk = clk_100mhz;
wire locked;

clk_tmds
    #(
        .DDR_ENABLED(DDR_HDMI_TRANSFER)
    )
    clk_tmds_i
    (
        clk_x5,
        clk_100mhz,
        clk_25mhz
    );


`elsif NANO_4K
  wire clk = clk_27mhz;
  wire clk_x5;
  wire pclk = clk_27mhz;
  wire tmds_clk = clk_x5;
  Gowin_PLLVR pllvr_i(
    .clkout(clk_x5), //output clkout 135 MHz
    .clkin(clk_27mhz) //input clkin
  );
`else /* ulx3s */
wire clk_locked;
wire [3:0] clocks;

ecp5pll
    #(
        .in_hz(SYSTEM_CLK_MHZ*1e6),
        .out0_hz(pixel_f * (DDR_HDMI_TRANSFER ? 5 : 10)),
        .out1_hz(pixel_f)
    )
    ecp5pll_inst
    (
        .clk_i(clk_25mhz),
        .clk_o(clocks),
        .locked(clk_locked)
    );

wire tmds_clk = clocks[0];
wire pclk = clocks[1];
`endif

wire [10:0] hcnt;
wire [10:0] vcnt;
wire hcycle;
wire vcycle;
wire hsync;
wire vsync;
wire blank;

my_vga_clk_generator
    /*
    //  one of my monitor dislikes autogenerated calculated values
    // just use default vga values in my_vga_clk_generator.vh
    #(
      .VPOL( 1 ),
      .HPOL( 1 ),
      .FRAME_RATE( frame_rate ),
      .VBP( vsync_back_porch ),
      .VFP( vsync_front_porch ),
      .VSLEN( vsync_pulse_width ),
      .VACTIVE( y_res ),
      .HBP( hsync_back_porch ),
      .HFP( hsync_front_porch ),
      .HSLEN( hsync_pulse_width ),
      .HACTIVE( x_res )
    )
    */
    my_vga_clk_generator_i(
        .pclk(pclk),
        .out_hcnt(hcnt),
        .out_vcnt(vcnt),
        .out_hsync(hsync),
        .out_vsync(vsync),
        .out_blank(blank),
        .reset_n(1'b1)
    );

`ifdef HX8X
wire clk = clk_25mhz;
reg [0:31] count = 0;
wire tick = (count == SYSTEM_CLK_MHZ * 1000_0);
always @(posedge clk) begin
    count <= (tick) ? 0 : count + 1;
end

reg [0:31] count1 = 0;
wire tick1 = (count1 == SYSTEM_CLK_MHZ * 1000_000);
always @(posedge clk) begin
    count1 <= (tick1) ? 0 : count1 + 1;
end

always @(posedge clk) begin
    if (tick) begin
        led <= vga_blue;
    end

    if (tick1) begin
        led1 <= led1 ^ 4'b1111;
    end
end
`elsif ARTY7
reg [31:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = frame_cnt == 59;
reg toogle;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= fps ? 0 : frame_cnt + 1;
    //toogle <= fps ? !toogle : toogle;
    toogle <= toogle ^ fps;
end

assign led = {4{toogle}};
`elsif I9PLUS
reg [31:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = frame_cnt == 59;
reg toogle = 1'b1;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= fps ? 0 : frame_cnt + 1;
    toogle <= toogle ^ fps;
end

assign led = toogle;
`elsif COLORLIGHTI5
reg [31:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = frame_cnt == 59;
reg toogle = 1'b1;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= fps ? 0 : frame_cnt + 1;
    toogle <= toogle ^ fps;
end

assign led = toogle;
`elsif NANO_4K
reg [5:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = (frame_cnt == 59);
reg toogle = 1'b1;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= fps ? 0 : frame_cnt + 1;
    toogle <= toogle ^ fps;
end

assign led = ~toogle;
`else /* ulx3s */
reg [31:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = frame_cnt == 59;
reg toogle;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= fps ? 0 : frame_cnt + 1;
    //toogle <= fps ? !toogle : toogle;
    toogle <= toogle ^ fps;
end

assign   led = {8{toogle}};
`endif

/* */
`ifdef HX8X
localparam N = 20;
`elsif NANO_4K
localparam N = 35;
`else
localparam N = 35;
`endif
wire [N-1:0] draw_ball;
//reg [N-1:0] in_opposite = 0;
genvar i;
generate
    for (i = 0; i < N; i = i +1)
    begin: gen_ball
        ball #(
                 .START_X( i*10 % x_res),
                 .START_Y( i*10 % y_res),
                 .DELTA_X( 1+(i) % 4 ),
                 .DELTA_Y( 1+(i) % 4 ),
                 .BALL_WIDTH( 10 +i % 100 ),
                 .BALL_HEIGHT( 10 +i % 100  ),
                 .X_RES( x_res ),
                 .Y_RES( y_res )
             ) ball_i (
                 .clk(pclk),
                 .i_vcnt(vcnt),
                 .i_hcnt(hcnt),
                 //.in_opposite(in_opposite[i]),
                 .i_opposite(1'b0),
                 .o_draw(draw_ball[i])
             );
    end
endgenerate
/////////////////////
wire [15:0] lfsr;
wire draw_stars = hcnt >= 0 && hcnt < 256 && vcnt >= 0 && vcnt < 256;
wire star_object = (&lfsr[15:6] & draw_stars);
LFSR #(16'b1_0000_0000_1011,0)
     lfsr_i(pclk, 1'b0, draw_stars, lfsr);

wire [15:0] lfsr1;
wire draw_stars1 = hcnt >= 256 && hcnt < 512 && vcnt >= 0 && vcnt < 256;
wire star_object1 = (&lfsr1[15:6] & draw_stars1);
LFSR #(16'b1000000001011,0)
     lfsr_i1(pclk, 1'b0, draw_stars1, lfsr1);

wire [15:0] lfsr2;
wire draw_stars2 = hcnt >= 512 && hcnt < (512+256) && vcnt >= 0 && vcnt < 256;
wire star_object2 = (&lfsr2[15:6] & draw_stars2);
LFSR #(16'b1000000001011,0)
     lfsr_i2(pclk, 1'b0, draw_stars2, lfsr2);

//////

wire [15:0] lfsr3;
wire draw_stars3 = hcnt >= 0 && hcnt < 256 && vcnt >= 224 && vcnt < 480;
wire star_object3 = (&lfsr3[15:6] & draw_stars3);
LFSR #(16'b1000000001011,0)
     lfsr_i3(pclk, 1'b0, draw_stars3, lfsr3);

wire [15:0] lfsr4;
wire draw_stars4 = hcnt >= 256 && hcnt < 512 && vcnt >= 224 && vcnt < 480;
wire star_object4 = (&lfsr4[15:6] & draw_stars4);
LFSR #(16'b1000000001011,0)
     lfsr_i4(pclk, 1'b0, draw_stars4, lfsr4);

wire [15:0] lfsr5;
wire draw_stars5 = hcnt >= 512 && hcnt < (512+256) && vcnt >= 224 && vcnt < 480;
wire star_object5 = (&lfsr5[15:6] & draw_stars5);
LFSR #(16'b1000000001011,0)
     lfsr_i5(pclk, 1'b0, draw_stars5, lfsr5);

wire stars = star_object  | star_object1 |
     star_object2 | star_object3 |
     star_object4 | star_object5;
/////////////////////
wire [7:0] W              = {8{hcnt[7:0]==vcnt[7:0]}};
wire [7:0] A              = {8{hcnt[7:5]==3'h2 && vcnt[7:5]==3'h2}};
wire [7:0] vga_red_test   = ({hcnt[5:0] & {6{vcnt[4:3]==~hcnt[4:3]}}, 2'b00} | W) & ~A;
wire [7:0] vga_green_test = (hcnt[7:0] & {8{vcnt[6]}} | W) & ~A;
wire [7:0] vga_blue_test  = vcnt[7:0] | W | A;

always @(posedge pclk) begin
    vga_blank <= blank;
    vga_hsync <= hsync;
    vga_vsync <= vsync;

    if (~blank) begin
    `ifdef HX8X
        vga_red   <= vga_red_test>>1   | (stars | |draw_ball[6:0] | |draw_ball[9:0] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
        vga_green <= vga_green_test>>1 | (stars | |draw_ball[15:7] ? 8'hff : 8'h0);
        vga_blue  <= vga_blue_test>>1  | (stars | |draw_ball[19:16] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
    `elsif NANO_4K
        vga_red   <= vga_red_test>>1   | (stars | |draw_ball[10:0] | |draw_ball[20:11] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
        vga_green <= vga_green_test>>1 | (stars | |draw_ball[20:11] ? 8'hff : 8'h0);
        vga_blue  <= vga_blue_test>>1  | (stars | |draw_ball[34:21] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
    `else
        vga_red   <= vga_red_test>>1   | (stars | |draw_ball[10:0] | |draw_ball[20:11] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
        vga_green <= vga_green_test>>1 | (stars | |draw_ball[20:11] ? 8'hff : 8'h0);
        vga_blue  <= vga_blue_test>>1  | (stars | |draw_ball[34:21] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
    `endif
    end
    else begin
        vga_red   <= 8'h0;
        vga_blue  <= 8'h0;
        vga_green <= 8'h0;
    end
end

localparam OUT_TMDS_MSB = DDR_HDMI_TRANSFER ? 1 : 0;
wire [OUT_TMDS_MSB:0] out_tmds_red;
wire [OUT_TMDS_MSB:0] out_tmds_green;
wire [OUT_TMDS_MSB:0] out_tmds_blue;
wire [OUT_TMDS_MSB:0] out_tmds_clk;

hdmi_device #(.DDR_ENABLED(DDR_HDMI_TRANSFER)) hdmi_device_i(
                pclk,
                tmds_clk,

                vga_red,
                vga_green,
                vga_blue,

                vga_blank,
                vga_vsync,
                vga_hsync,

                out_tmds_red,
                out_tmds_green,
                out_tmds_blue,
                out_tmds_clk
            );

`ifdef HX8X
generate
    if (DDR_HDMI_TRANSFER) begin /* we have no other choice as DDR */
        SB_LVCMOS SB_LVCMOS_RED   (.DP(hdmi_p[2]), .DN(hdmi_n[2]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_red));
        SB_LVCMOS SB_LVCMOS_GREEN (.DP(hdmi_p[1]), .DN(hdmi_n[1]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_green));
        SB_LVCMOS SB_LVCMOS_BLUE  (.DP(hdmi_p[0]), .DN(hdmi_n[0]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_blue));
        SB_LVCMOS SB_LVCMOS_CLK   (.DP(hdmi_p[3]), .DN(hdmi_n[3]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_clk));
    end
endgenerate
`elsif NANO_4K
  // DDR
 ODDR red_ddr_i   ( .CLK(tmds_clk), .D0(out_tmds_red[0]  )   , .D1(out_tmds_red[1] )     , .Q0(hdmi_p[2]));//, .Q1(hdmi_n[2]) );
 ODDR blue_ddr_i  ( .CLK(tmds_clk), .D0(out_tmds_blue[0] )   , .D1(out_tmds_blue[1])     , .Q0(hdmi_p[0]));//, .Q1(hdmi_n[0]) );
 ODDR green_ddr_i ( .CLK(tmds_clk), .D0(out_tmds_green[0])   , .D1(out_tmds_green[1] )   , .Q0(hdmi_p[1]));//, .Q1(hdmi_n[1]) );
 ODDR clk_ddr_i   ( .CLK(tmds_clk), .D0(out_tmds_clk[0]  )   , .D1(out_tmds_clk[1])      , .Q0(hdmi_p[3]));//, .Q1(hdmi_n[3]) );
 /*
 // SDR
 TLVDS_OBUF red_tlvds_obuf  (
   .I(out_tmds_red),
   .O(hdmi_p[2]),
   .OB(hdmi_n[2])
 );

 TLVDS_OBUF blue_tlvds_obuf  (
   .I(out_tmds_blue),
   .O(hdmi_p[0]),
   .OB(hdmi_n[0])
 );

 TLVDS_OBUF green_tlvds_obuf  (
   .I(out_tmds_green),
   .O(hdmi_p[1]),
   .OB(hdmi_n[1])
 );

 TLVDS_OBUF clk_tlvds_obuf  (
   .I(out_tmds_clk),
   .O(hdmi_p[3]),
   .OB(hdmi_n[3])
 );
 */

`elsif ARTY7
generate if (!DDR_HDMI_TRANSFER) begin
        OBUFDS OBUFDS_clock     (.I(out_tmds_clk),    .O(hdmi_p[3]), .OB(hdmi_n[3]));
        OBUFDS OBUFDS_red       (.I(out_tmds_red),    .O(hdmi_p[2]), .OB(hdmi_n[2]));
        OBUFDS OBUFDS_green     (.I(out_tmds_green),  .O(hdmi_p[1]), .OB(hdmi_n[1]));
        OBUFDS OBUFDS_blue      (.I(out_tmds_blue),   .O(hdmi_p[0]), .OB(hdmi_n[0]));
    end else begin
        wire out_ddr_tmds_clk;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_clk
            (
                .D1( out_tmds_clk[0]  ),
                .D2( out_tmds_clk[1]  ) ,
                .C ( tmds_clk         ),
                .CE( 1'b1             ),
                .Q ( out_ddr_tmds_clk ),
                .R ( 1'b0             ),
                .S ( 1'b0             )
            );
        OBUFDS OBUFDS_clock(.I(out_ddr_tmds_clk), .O(hdmi_p[3]), .OB(hdmi_n[3]));

        wire out_ddr_tmds_red;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_red
            (
                .D1( out_tmds_red[0]  ),
                .D2( out_tmds_red[1]  ),
                .C ( tmds_clk         ),
                .CE( 1'b1             ),
                .Q ( out_ddr_tmds_red ),
                .R ( 1'b0             ),
                .S ( 1'b0             )
            );
        OBUFDS OBUFDS_red(.I(out_ddr_tmds_red), .O(hdmi_p[2]), .OB(hdmi_n[2]));

        wire out_ddr_tmds_green;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_green
            (
                .D1( out_tmds_green[0]   ),
                .D2( out_tmds_green[1]   ),
                .C ( tmds_clk            ),
                .CE( 1'b1                ),
                .Q ( out_ddr_tmds_green  ),
                .R ( 1'b0                ),
                .S ( 1'b0                )
            );
        OBUFDS OBUFDS_green(.I(out_ddr_tmds_green), .O(hdmi_p[1]), .OB(hdmi_n[1]));

        wire out_ddr_tmds_blue;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_blue
            (
                .D1( out_tmds_blue[0]   ),
                .D2( out_tmds_blue[1]   ),
                .C ( tmds_clk            ),
                .CE( 1'b1                ),
                .Q ( out_ddr_tmds_blue  ),
                .R ( 1'b0                ),
                .S ( 1'b0                )
            );
        OBUFDS OBUFDS_blue(.I(out_ddr_tmds_blue), .O(hdmi_p[0]), .OB(hdmi_n[0]));
    end endgenerate

`elsif I9PLUS
generate if (!DDR_HDMI_TRANSFER) begin
//        OBUFDS OBUFDS_clock     (.I(out_tmds_clk),    .O(hdmi_p[3]), .OB(hdmi_n[3]));
//        OBUFDS OBUFDS_red       (.I(out_tmds_red),    .O(hdmi_p[2]), .OB(hdmi_n[2]));
//        OBUFDS OBUFDS_green     (.I(out_tmds_green),  .O(hdmi_p[1]), .OB(hdmi_n[1]));
//        OBUFDS OBUFDS_blue      (.I(out_tmds_blue),   .O(hdmi_p[0]), .OB(hdmi_n[0]));
        wire out_tmds_clk_n, out_tmds_red_n, out_tmds_green_n, out_tmds_blue_n;
        assign out_tmds_clk_n = ~out_tmds_clk;
        assign out_tmds_red_n = ~out_tmds_red;
        assign out_tmds_gree_n = ~out_tmds_green;
        assign out_tmds_blue_n = ~out_tmds_blue;
        OBUF OBUF_clock_p(.I(out_tmds_clk), .O(hdmi_p[3]));
        OBUF OBUF_clock_n(.I(out_tmds_clk_n), .O(hdmi_n[3]));
        OBUF OBUF_red_p(.I(out_tmds_red), .O(hdmi_p[2]));
        OBUF OBUF_red_n(.I(out_tmds_red_n), .O(hdmi_n[2]));
        OBUF OBUF_green_p(.I(out_tmds_green), .O(hdmi_p[1]));
        OBUF OBUF_green_n(.I(out_tmds_green_n), .O(hdmi_n[1]));
        OBUF OBUF_blue_p(.I(out_tmds_blue), .O(hdmi_p[0]));
        OBUF OBUF_blue_n(.I(out_tmds_blue_n), .O(hdmi_n[0]));
        
    end else begin
        wire out_ddr_tmds_clk, out_ddr_tmds_clk_n;
//        assign out_ddr_tmds_clk_n = ~out_ddr_tmds_clk;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_clk
            (
                .D1( out_tmds_clk[0]  ),
                .D2( out_tmds_clk[1]  ) ,
                .C ( tmds_clk         ),
                .CE( 1'b1             ),
                .Q ( out_ddr_tmds_clk ),
                .R ( 1'b0             ),
                .S ( 1'b0             )
            );
        OBUFDS OBUFDS_clock(.I(out_ddr_tmds_clk), .O(hdmi_p[3]), .OB(out_ddr_tmds_clk_n));
//        OBUF OBUF_clock_p(.I(out_ddr_tmds_clk), .O(hdmi_p[3]));
        OBUF OBUF_clock_n(.I(out_ddr_tmds_clk_n), .O(hdmi_n[3]));
//        OBUFDS OBUFDS_clock(.I(out_ddr_tmds_clk), .O(hdmi_p[3]), .OB(hdmi_n[3]));
        
        wire out_ddr_tmds_red, out_ddr_tmds_red_n;
//        assign out_ddr_tmds_red_n = ~out_ddr_tmds_red;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_red
            (
                .D1( out_tmds_red[0]  ),
                .D2( out_tmds_red[1]  ),
                .C ( tmds_clk         ),
                .CE( 1'b1             ),
                .Q ( out_ddr_tmds_red ),
                .R ( 1'b0             ),
                .S ( 1'b0             )
            );
            OBUFDS OBUFDS_red(.I(out_ddr_tmds_red), .O(hdmi_p[2]), .OB(out_ddr_tmds_red_n));
//        OBUF OBUF_red_p(.I(out_ddr_tmds_red), .O(hdmi_p[2]));
        OBUF OBUF_red_n(.I(out_ddr_tmds_red_n), .O(hdmi_n[2]));
//        OBUFDS OBUFDS_red(.I(out_ddr_tmds_red), .O(hdmi_p[2]), .OB(hdmi_n[2]));

        wire out_ddr_tmds_green, out_ddr_tmds_green_n;
        assign out_ddr_tmds_green_n = ~out_ddr_tmds_green;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_green
            (
                .D1( out_tmds_green[0]   ),
                .D2( out_tmds_green[1]   ),
                .C ( tmds_clk            ),
                .CE( 1'b1                ),
                .Q ( out_ddr_tmds_green  ),
                .R ( 1'b0                ),
                .S ( 1'b0                )
            );
        OBUF OBUF_green_p(.I(out_ddr_tmds_green), .O(hdmi_p[1]));
        OBUF OBUF_green_n(.I(out_ddr_tmds_green_n), .O(hdmi_n[1]));
//        OBUFDS OBUFDS_green(.I(out_ddr_tmds_green), .O(hdmi_p[1]), .OB(hdmi_n[1]));

        wire out_ddr_tmds_blue, out_ddr_tmds_blue_n;
        assign out_ddr_tmds_blue_n = ~out_ddr_tmds_blue;
        ODDR
            #(.DDR_CLK_EDGE   ("SAME_EDGE"), //"OPPOSITE_EDGE" "SAME_EDGE"
              .INIT           (1'b0),
              .SRTYPE         ("ASYNC")) oddr_blue
            (
                .D1( out_tmds_blue[0]   ),
                .D2( out_tmds_blue[1]   ),
                .C ( tmds_clk            ),
                .CE( 1'b1                ),
                .Q ( out_ddr_tmds_blue  ),
                .R ( 1'b0                ),
                .S ( 1'b0                )
            );
        OBUF OBUF_blue_p(.I(out_ddr_tmds_blue), .O(hdmi_p[0]));
        OBUF OBUF_blue_n(.I(out_ddr_tmds_blue_n), .O(hdmi_n[0]));
//        OBUFDS OBUFDS_blue(.I(out_ddr_tmds_blue), .O(hdmi_p[0]), .OB(hdmi_n[0]));
    end endgenerate

`else
/* ulx3s can SDR and DDR */
generate
    if (DDR_HDMI_TRANSFER) begin
        ODDRX1F ddr0_clock (.D0(out_tmds_clk   [0] ), .D1(out_tmds_clk   [1] ), .Q(gpdi_dp[3]), .SCLK(tmds_clk), .RST(0));
        ODDRX1F ddr0_red   (.D0(out_tmds_red   [0] ), .D1(out_tmds_red   [1] ), .Q(gpdi_dp[2]), .SCLK(tmds_clk), .RST(0));
        ODDRX1F ddr0_green (.D0(out_tmds_green [0] ), .D1(out_tmds_green [1] ), .Q(gpdi_dp[1]), .SCLK(tmds_clk), .RST(0));
        ODDRX1F ddr0_blue  (.D0(out_tmds_blue  [0] ), .D1(out_tmds_blue  [1] ), .Q(gpdi_dp[0]), .SCLK(tmds_clk), .RST(0));
    end else begin
        assign gpdi_dp[3] = out_tmds_clk;
        assign gpdi_dp[2] = out_tmds_red;
        assign gpdi_dp[1] = out_tmds_green;
        assign gpdi_dp[0] = out_tmds_blue;
    end
endgenerate
`endif

endmodule

`ifdef HX8X
    // LVDS Double Data RAGE (DDR) Output
    module SB_LVCMOS(input DP, input DN, input clk_x5, input [1:0] tmds_signal);
defparam tmds_p.PIN_TYPE = 6'b010000;
defparam tmds_p.IO_STANDARD = "SB_LVCMOS";
SB_IO tmds_p (
          .PACKAGE_PIN (DP),
          .CLOCK_ENABLE (1'b1),
          .OUTPUT_CLK (clk_x5),
          .OUTPUT_ENABLE (1'b1),
          .D_OUT_0 (tmds_signal[1]),
          .D_OUT_1 (tmds_signal[0])
      );

defparam tmds_n.PIN_TYPE = 6'b010000;
defparam tmds_n.IO_STANDARD = "SB_LVCMOS";
SB_IO tmds_n (
          .PACKAGE_PIN (DN),
          .CLOCK_ENABLE (1'b1),
          .OUTPUT_CLK (clk_x5),
          .OUTPUT_ENABLE (1'b1),
          .D_OUT_0 (~tmds_signal[1]),
          .D_OUT_1 (~tmds_signal[0])
      );
// D_OUT_0 and D_OUT_1 swapped?
// https://github.com/YosysHQ/yosys/issues/330
endmodule
`endif
`ifdef ICOBOARD
    /**
     * PLL configuration
     *
     * This Verilog module was generated automatically
     * using the icepll tool from the IceStorm project.
     * Use at your own risk.
     *
     * Given input frequency:       100.000 MHz
     * Requested output frequency:  125.000 MHz
     * Achieved output frequency:   125.000 MHz
     */

    module pll125(
        input  clock_in,
        output clock_out,
        output locked
    );

SB_PLL40_CORE #(
                  .FEEDBACK_PATH("SIMPLE"),
                  .DIVR(4'b0000),         // DIVR =  0
                  .DIVF(7'b0001001),      // DIVF =  9
                  .DIVQ(3'b011),          // DIVQ =  3
                  .FILTER_RANGE(3'b101)   // FILTER_RANGE = 5
              ) uut (
                  .LOCK(locked),
                  .RESETB(1'b1),
                  .BYPASS(1'b0),
                  .REFERENCECLK(clock_in),
                  .PLLOUTCORE(clock_out)
              );

endmodule
`endif
`ifdef ARTY7

    // 125MHz in DDR mode else 225 MHz and second clock always 25MHz
`timescale 1ps/1ps

    module clk_tmds

    #(parameter DDR_ENABLED = 1)
    (// Clock in ports
        // Clock out ports
        output        clk_out1,
        output        clk_out2,
        input         clk_in1
    );
// Input buffering
//------------------------------------
wire clk_in1_clk_tmds;
wire clk_in2_clk_tmds;
IBUF clkin1_ibufg
     (.O (clk_in1_clk_tmds),
      .I (clk_in1));

// Clocking PRIMITIVE
//------------------------------------

// Instantiation of the MMCM PRIMITIVE
//    * Unused inputs are tied off
//    * Unused outputs are labeled unused

wire        clk_out1_clk_tmds;
wire        clk_out2_clk_tmds;
wire        clk_out3_clk_tmds;
wire        clk_out4_clk_tmds;
wire        clk_out5_clk_tmds;
wire        clk_out6_clk_tmds;
wire        clk_out7_clk_tmds;

wire [15:0] do_unused;
wire        drdy_unused;
wire        psdone_unused;
wire        locked_int;
wire        clkfbout_clk_tmds;
wire        clkfbout_buf_clk_tmds;
wire        clkfboutb_unused;
wire clkout2_unused;
wire clkout3_unused;
wire clkout4_unused;
wire        clkout5_unused;
wire        clkout6_unused;
wire        clkfbstopped_unused;
wire        clkinstopped_unused;

PLLE2_ADV
    #(.BANDWIDTH            ("OPTIMIZED"),
      .COMPENSATION         ("INTERNAL"),
      .STARTUP_WAIT         ("FALSE"),
      .DIVCLK_DIVIDE        (DDR_ENABLED ? 4 : 1),
      .CLKFBOUT_MULT        (DDR_ENABLED ? 35 : 10),
      .CLKFBOUT_PHASE       (0.000),
      .CLKOUT0_DIVIDE       (DDR_ENABLED ? 7 : 4),
      .CLKOUT0_PHASE        (0.000),
      .CLKOUT0_DUTY_CYCLE   (0.500),
      .CLKOUT1_DIVIDE       (DDR_ENABLED ? 35 : 40),
      .CLKOUT1_PHASE        (0.000),
      .CLKOUT1_DUTY_CYCLE   (0.500),
      .CLKIN1_PERIOD        (10.000))
    plle2_adv_inst
    // Output clocks
    (
        .CLKFBOUT            (clkfbout_clk_tmds),
        .CLKOUT0             (clk_out1_clk_tmds),
        .CLKOUT1             (clk_out2_clk_tmds),
        .CLKOUT2             (clkout2_unused),
        .CLKOUT3             (clkout3_unused),
        .CLKOUT4             (clkout4_unused),
        .CLKOUT5             (clkout5_unused),
        // Input clock control
        .CLKFBIN           (clkfbout_clk_tmds),
        .CLKIN1              (clk_in1_clk_tmds),
        .CLKIN2              (1'b0),
        // Tied to always select the primary input clock
        .CLKINSEL            (1'b1),
        // Ports for dynamic reconfiguration
        .DADDR               (7'h0),
        .DCLK                (1'b0),
        .DEN                 (1'b0),
        .DI                  (16'h0),
        .DO                  (do_unused),
        .DRDY                (drdy_unused),
        .DWE                 (1'b0),
        // Other control and status signals
        .LOCKED              (locked_int),
        .PWRDWN              (1'b0),
        .RST                 (1'b0));

// Clock Monitor clock assigning
//--------------------------------------
// Output buffering
//-----------------------------------

assign clkfbout_buf_clk_tmds = clkfbout_clk_tmds;


BUFG clkout1_buf
     (.O   (clk_out1),
      .I   (clk_out1_clk_tmds));


BUFG clkout2_buf
     (.O   (clk_out2),
      .I   (clk_out2_clk_tmds));
endmodule

`endif

`ifdef I9PLUS

    // 125MHz in DDR mode , 250 in SDR
`timescale 1ps/1ps

module clk_tmds
#(parameter DDR_ENABLED = 1) //unused for now
(// Clock in ports
  // Clock out ports
  output        clk_out1,
  output        clk_out2,
  input         clk_in1
 );
  // Input buffering
  //------------------------------------
wire clk_in1_clk_wiz_0;
wire clk_in2_clk_wiz_0;
  IBUF clkin1_ibufg
   (.O (clk_in1_clk_wiz_0),
    .I (clk_in1));


  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        clk_out1_clk_wiz_0;
  wire        clk_out2_clk_wiz_0;
  wire        clk_out3_clk_wiz_0;
  wire        clk_out4_clk_wiz_0;
  wire        clk_out5_clk_wiz_0;
  wire        clk_out6_clk_wiz_0;
  wire        clk_out7_clk_wiz_0;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_0;
  wire        clkfbout_buf_clk_wiz_0;
  wire        clkfboutb_unused;
   wire clkout2_unused;
   wire clkout3_unused;
   wire clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        reset_high;

  PLLE2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT        (40),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE       (10),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT1_DIVIDE       (DDR_ENABLED ? 8 : 4),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (40.000))
  plle2_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_0),
    .CLKOUT0             (clk_out1_clk_wiz_0),
    .CLKOUT1             (clk_out2_clk_wiz_0),
    .CLKOUT2             (clkout2_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_wiz_0),
    .CLKIN1              (clk_in1_clk_wiz_0),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Other control and status signals
    .LOCKED              (locked_int),
    .PWRDWN              (1'b0),
    .RST                 (1'b0));

// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

   BUFG clkf_buf
    (.O (clkfbout_buf_clk_wiz_0),
     .I (clkfbout_clk_wiz_0));
//assign clkfbout_buf_clk_wiz_0 = clkfbout_clk_wiz_0;

   BUFG clkout1_buf
    (.O   (clk_out1),
     .I   (clk_out1_clk_wiz_0));
//assign clk_out1 = clk_out1_clk_wiz_0;

   BUFG clkout2_buf
    (.O   (clk_out2),
     .I   (clk_out2_clk_wiz_0));
//assign clk_out2 = clk_out2_clk_wiz_0;

endmodule

`endif