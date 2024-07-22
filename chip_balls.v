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

module chip_balls(
`ifdef ARTY7
           input clk_100mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output [3:0] led
`elsif I9PLUS
           input clk_25mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           input TMDS_Clk_p,
           input TMDS_Clk_n,
           input [2:0] DVI0_p,
           input [2:0] DVI0_n,
           input [1:0] P4sw,
           output led
`endif
       );

reg [7:0] vga_red;
reg [7:0] vga_blue;
reg [7:0] vga_green;


//todo good candidate for a "delay" generator...  
localparam buf1PixDel = 30;
localparam buf1PixFade = 'hEB;  //out of FF
reg [7:0] buf1Cnt = 0;
reg [7:0] vga_red_buf1;
reg [7:0] vga_blue_buf1;
reg [7:0] vga_green_buf1;

localparam buf2PixDel = 50;
localparam buf2PixFade = 'hAB;  //out of FF
reg [7:0] buf2Cnt = 0;
reg [7:0] vga_red_buf2;
reg [7:0] vga_blue_buf2;
reg [7:0] vga_green_buf2;

localparam buf3PixDel = 80;
localparam buf3PixFade = 'h7B;  //out of FF
reg [7:0] buf3Cnt = 0;
reg [7:0] vga_red_buf3;
reg [7:0] vga_blue_buf3;
reg [7:0] vga_green_buf3;

localparam buf4PixDel = 130;
localparam buf4PixFade = 'h2B;  //out of FF
reg [7:0] buf4Cnt = 0;
reg [7:0] vga_red_buf4;
reg [7:0] vga_blue_buf4;
reg [7:0] vga_green_buf4;

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
localparam x_res             = 800;
localparam y_res             = 600;
localparam frame_rate        = 60;

`include "video_timings.v"

// clock generator
`ifdef I9PLUS

wire pclk_25mhz;
wire clk_x5;
wire clk_x10;
wire clk_16m;  //names are for 800x600 values
wire clk_11_4M;
wire clk_7_27M;
wire clk_6_66M;
wire tmds_clk = clk_x10;
wire pclk = pclk_25mhz;
wire locked;

clk_tmds
    #(
        .DDR_ENABLED(DDR_HDMI_TRANSFER)
    )
    clk_tmds_i
    (
        pclk_25mhz,
        clk_x10,
        clk_x5,
        clk_11_4m,
        clk_7_27m,
        clk_6_66m,
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
//wire blankn;
//assign blank = ~blankn;


my_vga_clk_generator
    
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
    
    my_vga_clk_generator_i(
        .pclk(pclk),
        .out_hcnt(hcnt),
        .out_vcnt(vcnt),
        .out_hsync(hsync),
        .out_vsync(vsync),
        .out_blank(blank),
        .reset_n(1'b1)
    );

/* Kinda works, outputs a singal, but no content
wire sof_state, hblank_out, vblank_out, fsync_out; //ununsed
//default config is 720p
v_tc_0 video_timing_i (
  .clk(pclk),                            // input wire clk
  .clken(1'b1),                        // input wire clken
  .gen_clken(1'b1),                // input wire gen_clken
  .sof_state(sof_state),                // input wire sof_state
  .hsync_out(hsync),                // output wire hsync_out
  .hblank_out(hblank_out),              // output wire hblank_out
  .vsync_out(vsync),                // output wire vsync_out
  .vblank_out(vblank_out),              // output wire vblank_out
  .active_video_out(blank),  // output wire active_video_out - setup active low
  .resetn(1'b1),                      // input wire resetn
  .fsync_out(fsync_out)                // output wire [0 : 0] fsync_out
);
*/
`ifdef I9PLUS
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


wire clk_40Hz;
clk_div #(.DIV(1000000)) 
clk_div_40(
  .clk(pclk), .ena(1'b1), .clk_out(clk_40Hz));
  
reg [7:0] triangle_fader_1;
cntr_triangle #(.WIDTH(9)) 
    lfo_tri_1(
    .clk(clk_40Hz), .ena(1'b1), .rst(1'b0), .sload(1'b0), .sdata(8'b0), 
    .sclear(1'b0), .q(triangle_fader_1));

/***
        clk_11_4m,
        clk_7_27m,
        clk_6_66m,
***/
wire clk_11Hz, clk_7Hz, clk_6Hz;
clk_div #(.DIV(1000000)) 
clk_div_11(
      .clk(clk_11_4m), .ena(1'b1), .clk_out(clk_11Hz));

clk_div #(.DIV(1000000)) 
clk_div_7(
  .clk(clk_7_27m), .ena(1'b1), .clk_out(clk_7Hz));

clk_div #(.DIV(1000000)) 
clk_div_6(
  .clk(clk_6_66m), .ena(1'b1), .clk_out(clk_6Hz));
        
reg [8:0] triangle_fader_r, triangle_fader_g, triangle_fader_b;
cntr_triangle #(.WIDTH(8)) 
    lfo_tri_r(
    .clk(clk_11Hz), .ena(1'b1), .rst(1'b0), .sload(1'b0), .sdata(8'b0), 
    .sclear(1'b0), .q(triangle_fader_r));

cntr_triangle #(.WIDTH(8)) 
    lfo_tri_g(
    .clk(clk_7Hz), .ena(1'b1), .rst(1'b0), .sload(1'b0), .sdata(8'b0), 
    .sclear(1'b0), .q(triangle_fader_g));
    
cntr_triangle #(.WIDTH(8)) 
    lfo_tri_b(
    .clk(clk_6Hz), .ena(1'b1), .rst(1'b0), .sload(1'b0), .sdata(8'b0), 
    .sclear(1'b0), .q(triangle_fader_b));
/* */

localparam N = 10;
wire [N-1:0] draw_ball;

//reg [N-1:0] in_opposite = 0;
genvar i;
generate
    for (i = 0; i < N; i = i +1)
    begin: gen_ball
        ball #(
//                 .START_X( i*10 % x_res),
//                 .START_Y( i*10 % y_res),
//                 .DELTA_X( 1+(i) % 4 ),
//                 .DELTA_Y( 1+(i) % 4 ),
                 .START_X( (i*100 ) % x_res ),
                 .START_Y( (i*50 ) % y_res ),
                 .DELTA_X( i[0] ),
                 .DELTA_Y( i[1]  ),
//                 .BALL_WIDTH( 10 +i % 100 ),
//                 .BALL_HEIGHT( 10 +i % 100 ),
                 .X_RES( x_res ),
                 .Y_RES( y_res )
             ) ball_i (
                 .clk(pclk),
                 .i_vcnt(vcnt),
                 .i_hcnt(hcnt),
                 .width(triangle_fader_1[ (i%5 + 2):0]),
                 .height(triangle_fader_1[7: (i % 3) ]),
                 //.in_opposite(in_opposite[i]),
                 .i_opposite(1'b0),
                 .o_draw(draw_ball[i])
             );
    end
endgenerate
/////////////////////

wire starClk;
reg [7:0] starDiv;
always @(posedge pclk) begin
    starDiv <= starDiv + 1;
end
assign starClk = clk_6_66m; //starDiv[5];

wire [15:0] lfsr;
wire draw_stars = hcnt >= 0 && hcnt < x_res/2 && vcnt >= 0 && vcnt < y_res/2;
wire star_object = (&lfsr[15:6] & draw_stars);
LFSR #(16'b1_0000_0000_1011,0)
     lfsr_i(starClk, 1'b0, draw_stars, lfsr);

wire [15:0] lfsr1;
wire draw_stars1 = hcnt >= x_res/2 && hcnt < x_res && vcnt >= 0 && vcnt < y_res/2;
wire star_object1 = (&lfsr1[15:6] & draw_stars1);
LFSR #(16'b1000000001011,0)
     lfsr_i1(starClk, 1'b0, draw_stars1, lfsr1);

wire [15:0] lfsr2;
wire draw_stars2 = hcnt >= x_res/2 && hcnt < (x_res+256) && vcnt >= 0 && vcnt < y_res/2;
wire star_object2 = (&lfsr2[15:6] & draw_stars2);
LFSR #(16'b1000000001011,0)
     lfsr_i2(starClk, 1'b0, draw_stars2, lfsr2);

//////

wire [15:0] lfsr3;
wire draw_stars3 = hcnt >= 0 && hcnt < x_res/2 && vcnt >= y_res/2 && vcnt < y_res;
wire star_object3 = (&lfsr3[15:6] & draw_stars3);
LFSR #(16'b1000000001011,0)
     lfsr_i3(starClk, 1'b0, draw_stars3, lfsr3);

wire [15:0] lfsr4;
wire draw_stars4 = hcnt >= x_res/2 && hcnt < x_res && vcnt >= y_res/2 && vcnt < y_res;
wire star_object4 = (&lfsr4[15:6] & draw_stars4);
LFSR #(16'b1000000001011,0)
     lfsr_i4(starClk, 1'b0, draw_stars4, lfsr4);

wire [15:0] lfsr5;
wire draw_stars5 = hcnt >= x_res && hcnt < (x_res+256) && vcnt >= y_res/2 && vcnt < y_res;
wire star_object5 = (&lfsr5[15:6] & draw_stars5);
LFSR #(16'b1000000001011,0)
     lfsr_i5(starClk, 1'b0, draw_stars5, lfsr5);

//wire stars = star_object  | star_object1 |
//     star_object2 | star_object3 |
//     star_object4 | star_object5;

wire stars;

/////////////////////
/*wire [7:0] W              = {8{hcnt[7:0]==vcnt[7:0]}};
wire [7:0] A              = {8{hcnt[7:5]==3'h2 && vcnt[7:5]==3'h2}};
wire [7:0] vga_red_test   = ({hcnt[5:0] & {6{vcnt[4:3]==~hcnt[4:3]}}, 2'b00} | W) & ~A;
wire [7:0] vga_green_test = (hcnt[7:0] & {8{vcnt[6]}} | W) & ~A;
wire [7:0] vga_blue_test  = vcnt[7:0] | W | A;*/

/* kinda failed experiment

//delay output
reg [7:0] vga_red_del_out = 0; 
reg [7:0] vga_green_del_out = 0;
reg [7:0] vga_blue_del_out = 0;

always @(posedge pclk) begin   
    buf1Cnt <= (buf1Cnt < buf1PixDel)? buf1Cnt + 1 : 0;
    buf2Cnt <= (buf2Cnt < buf2PixDel)? buf2Cnt + 1 : 0;
    buf3Cnt <= (buf3Cnt < buf3PixDel)? buf3Cnt + 1 : 0;
    buf4Cnt <= (buf4Cnt < buf4PixDel)? buf4Cnt + 1 : 0;
    
    vga_red_buf1 <= (buf1Cnt == 0) ? (vga_red & buf1PixFade) : vga_red_buf1;
    vga_green_buf1 <= (buf1Cnt == 0) ? (vga_green & buf1PixFade) : vga_green_buf1;
    vga_blue_buf1 <= (buf1Cnt == 0) ? (vga_blue & buf1PixFade) : vga_blue_buf1;

    vga_red_buf2 <= (buf2Cnt == 0) ? (vga_red & buf2PixFade) : vga_red_buf2;
    vga_green_buf2 <= (buf2Cnt == 0) ? (vga_green & buf2PixFade) : vga_green_buf2;
    vga_blue_buf2 <= (buf2Cnt == 0) ? (vga_blue & buf2PixFade) : vga_blue_buf2;

    vga_red_buf3 <= (buf3Cnt == 0) ? (vga_red & buf3PixFade) : vga_red_buf3;
    vga_green_buf3 <= (buf3Cnt == 0) ? (vga_green & buf3PixFade) : vga_green_buf3;
    vga_blue_buf3 <= (buf3Cnt == 0) ? (vga_blue & buf3PixFade) : vga_blue_buf3;

    vga_red_buf4 <= (buf4Cnt == 0) ? (vga_red & buf4PixFade) : vga_red_buf4;
    vga_green_buf4 <= (buf4Cnt == 0) ? (vga_green & buf4PixFade) : vga_green_buf4;
    vga_blue_buf4 <= (buf4Cnt == 0) ? (vga_blue & buf4PixFade) : vga_blue_buf4;

    vga_red_del_out <= (buf1Cnt == 0) ? vga_red_buf1 : ((buf2Cnt == 0) ? vga_red_buf2 : ((buf3Cnt == 0) ? vga_red_buf3 : ((buf4Cnt == 0) ? vga_red_buf4 : 8'h00 )));
    vga_green_del_out <= (buf1Cnt == 0) ? vga_green_buf1 : ((buf2Cnt == 0) ? vga_green_buf2 : ((buf3Cnt == 0) ? vga_green_buf3 : ((buf4Cnt == 0) ? vga_green_buf4 : 8'h00 )));
    vga_blue_del_out <= (buf1Cnt == 0) ? vga_blue_buf1 : ((buf2Cnt == 0) ? vga_blue_buf2 : ((buf3Cnt == 0) ? vga_blue_buf3 : ((buf4Cnt == 0) ? vga_blue_buf4 : 8'h00 )));
end
*/
       
always @(posedge pclk) begin
    vga_blank <= blank;
    vga_hsync <= hsync;
    vga_vsync <= vsync;

    if (~blank) begin        
        vga_red   <= (stars || draw_ball[N/3-1:0] || draw_ball[(2*N/3-1):N/3-1] ) ? triangle_fader_r : 8'h00;
        vga_green <= (stars || draw_ball[(2*N/3)-1:N/3-1] ) ? triangle_fader_g : 8'h00;
        vga_blue  <= (stars || draw_ball[N-1:(2*N/3)-1] ) ? triangle_fader_b : 8'h00;
    end
    else begin
        vga_red   <= 8'h0;
        vga_blue  <= 8'h0;
        vga_green <= 8'h0;
    end
end

localparam OUT_TMDS_MSB = DDR_HDMI_TRANSFER ? 1 : 0;
wire [OUT_TMDS_MSB:0] in_tmds_red;
wire [OUT_TMDS_MSB:0] in_tmds_green;
wire [OUT_TMDS_MSB:0] in_tmds_blue;
wire [OUT_TMDS_MSB:0] in_tmds_clk;
            
// IBUF DVI0_3_p_ibufg
//      (.O (in_tmds_clk),
//       .I (DVI0_p[3]));
// IBUF DVI0_2_p_ibufg
//      (.O (in_tmds_red),
//       .I (DVI0_p[2]));
// IBUF DVI0_1_p_ibufg
//      (.O (in_tmds_green),
//       .I (DVI0_p[1]));
// IBUF DVI0_0_p_ibufg
//      (.O (in_tmds_blue),
//       .I (DVI0_p[0]));

wire [OUT_TMDS_MSB:0] mix_tmds_red;
wire [OUT_TMDS_MSB:0] mix_tmds_green;
wire [OUT_TMDS_MSB:0] mix_tmds_blue;
wire [OUT_TMDS_MSB:0] mix_tmds_clk;

wire [OUT_TMDS_MSB:0] out_tmds_red;
wire [OUT_TMDS_MSB:0] out_tmds_green;
wire [OUT_TMDS_MSB:0] out_tmds_blue;
wire [OUT_TMDS_MSB:0] out_tmds_clk;

////clk
// IBUFDS_DIFF_OUT DVI0_3_ibufds (.O(hdmi_p[3]), .OB(hdmi_n[3]), .I(DVI0_p[3]), .IB(DVI0_n[3]));
// //red
// IBUFDS_DIFF_OUT DVI0_2_ibufds (.O(hdmi_p[2]), .OB(hdmi_n[2]), .I(DVI0_p[2]), .IB(DVI0_n[2]));
// //green
// IBUFDS_DIFF_OUT DVI0_1_ibufds (.O(hdmi_p[1]), .OB(hdmi_n[1]), .I(DVI0_p[1]), .IB(DVI0_n[1]));
// //blue
// IBUFDS_DIFF_OUT DVI0_0_ibufds (.O(hdmi_p[0]), .OB(hdmi_n[0]), .I(DVI0_p[0]), .IB(DVI0_n[0]));

////clk
//IBUFDS DVI0_3_ibufds (.O(in_tmds_clk), .I(DVI0_p[3]), .IB(DVI0_n[3]));
////red
//IBUFDS DVI0_2_ibufds (.O(in_tmds_red), .I(DVI0_p[2]), .IB(DVI0_n[2]));
////green
//IBUFDS DVI0_1_ibufds (.O(in_tmds_green), .I(DVI0_p[1]), .IB(DVI0_n[1]));
////blue
//IBUFDS DVI0_0_ibufds (.O(in_tmds_blue), .I(DVI0_p[0]), .IB(DVI0_n[0]));

wire in_clk_p, in_clk_n;

//BUFMR clk_p_buf ( .O(in_clk_p), .I(TMDS_Clk_p));
//BUFMR clk_n_buf ( .O(in_clk_n), .I(TMDS_Clk_n));

wire inDE, inPClk, inVSync, inHSync, inSClk, inRst, inLocked, inPLocked;
wire mixDE, mixPClk, mixVSync, mixHSync, mixSClk;
wire [23 : 0] vid_pData;

dvi2rgb_0 dvi_in (
  .TMDS_Clk_p(TMDS_Clk_p),        // input wire TMDS_Clk_p
  .TMDS_Clk_n(TMDS_Clk_n),        // input wire TMDS_Clk_n
  .TMDS_Data_p(DVI0_p[2:0]),      // input wire [2 : 0] TMDS_Data_p
  .TMDS_Data_n(DVI0_n[2:0]),      // input wire [2 : 0] TMDS_Data_n
  .RefClk(clk_x5),                // input wire RefClk
  .aRst(inRst),                    // input wire aRst
  .vid_pData(vid_pData),          // output wire [23 : 0] vid_pData
  .vid_pVDE(inDE),            // output wire vid_pVDE
  .vid_pHSync(inHSync),        // output wire vid_pHSync
  .vid_pVSync(inVSync),        // output wire vid_pVSync
  .PixelClk(inPClk),            // output wire PixelClk
  .SerialClk(inSClk),          // output wire SerialClk, x5 not x10!!!
  .aPixelClkLckd(inPLocked),  // output wire aPixelClkLckd
  .pLocked(inLocked),              // output wire pLocked
  .pRst(inRst)                    // input wire pRst
);

reg [7:0] in_red = vid_pData[23:16];
reg [7:0] in_green = vid_pData[15:8];
reg [7:0] in_blue = vid_pData[7:0];

reg [7:0] mix_red = vga_red + in_red;
reg [7:0] mix_green = vga_green;
reg [7:0] mix_blue= vga_blue;

assign mixHSync = inHSync;
assign mixVSync = inVSync;
assign mixPClk = inPClk;
assign mixDE = inDE;

hdmi_device #(.DDR_ENABLED(DDR_HDMI_TRANSFER)) hdmi_device_i(
                pclk,
                tmds_clk,
//                mixPClk,
//                mixSClk, 
                
                // in_red,
                // in_green,
                // in_blue,
               mix_red,
               mix_green,
               mix_blue,
                
                //  mixDE,
                //  mixVSync,
                //  mixHSync,
              vga_blank,
              vga_vsync,
              vga_hsync,

                out_tmds_red,
                out_tmds_green,
                out_tmds_blue,
                out_tmds_clk
            );


`ifdef ARTY7
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
        // assign out_tmds_clk_n = ~mix_tmds_clk;
        assign out_tmds_red_n = ~out_tmds_red;
        // assign out_tmds_green_n = ~mix_tmds_green;
        // assign out_tmds_blue_n = ~mix_tmds_blue;
        assign out_tmds_clk_n = ~out_tmds_clk;
        // assign out_tmds_red_n = ~out_tmds_red;
        assign out_tmds_green_n = ~out_tmds_green;
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
//        assign out_ddr_tmds_green_n = ~out_ddr_tmds_green;
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
        OBUFDS OBUFDS_green(.I(out_ddr_tmds_green), .O(hdmi_p[1]), .OB(out_ddr_tmds_green_n));
//        OBUF OBUF_green_p(.I(out_ddr_tmds_green), .O(hdmi_p[1]));
        OBUF OBUF_green_n(.I(out_ddr_tmds_green_n), .O(hdmi_n[1]));
//        OBUFDS OBUFDS_green(.I(out_ddr_tmds_green), .O(hdmi_p[1]), .OB(hdmi_n[1]));

        wire out_ddr_tmds_blue, out_ddr_tmds_blue_n;
//        assign out_ddr_tmds_blue_n = ~out_ddr_tmds_blue;
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
        OBUFDS OBUFDS_blue(.I(out_ddr_tmds_blue), .O(hdmi_p[0]), .OB(out_ddr_tmds_blue_n));
//        OBUF OBUF_blue_p(.I(out_ddr_tmds_blue), .O(hdmi_p[0]));
        OBUF OBUF_blue_n(.I(out_ddr_tmds_blue_n), .O(hdmi_n[0]));
//        OBUFDS OBUFDS_blue(.I(out_ddr_tmds_blue), .O(hdmi_p[0]), .OB(hdmi_n[0]));
    end endgenerate

`endif

endmodule

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
#(
    parameter DDR_ENABLED = 1
)
(// Clock in ports
  // Clock out ports
  output        clk_out1,
  output        clk_out2,
  output        clk_out3,
  output        clk_out4,
  output        clk_out5,
  output        clk_out6,
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
  wire        clkout2_unused;
  wire        clkout3_unused;
  wire        clkout4_unused;
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
    .CLKFBOUT_MULT        (32), //800x600@60 32 //640x480@60 40
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE       (20), //800x600@60 20 //640x480@60 40
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT1_DIVIDE       (DDR_ENABLED ? 4 : 2), //800x600@60 4:2 //640x480@60 8:4
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT2_DIVIDE       (4), //x5
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT3_DIVIDE       (70), // 11.43M utility clocks ... 128 div max pclk 
    .CLKOUT3_PHASE        (0.000),
    .CLKOUT3_DUTY_CYCLE   (0.500),
    .CLKOUT4_DIVIDE       (110), // 7.27 M
    .CLKOUT4_PHASE        (0.000),
    .CLKOUT4_DUTY_CYCLE   (0.500),
    .CLKOUT5_DIVIDE       (120), // 6.66M
    .CLKOUT5_PHASE        (0.000),
    .CLKOUT5_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (40.000))
  plle2_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_0),
    .CLKOUT0             (clk_out1_clk_wiz_0),
    .CLKOUT1             (clk_out2_clk_wiz_0),
    .CLKOUT2             (clk_out3_clk_wiz_0),
    .CLKOUT3             (clk_out4_clk_wiz_0),
    .CLKOUT4             (clk_out5_clk_wiz_0),
    .CLKOUT5             (clk_out6_clk_wiz_0),
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

// MUST assign and comment OUT for 
// .COMPENSATION         ("INTERNAL"), //("ZHOLD"),
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

   BUFG clkout3_buf
    (.O   (clk_out3),
     .I   (clk_out3_clk_wiz_0));
//assign clk_out3 = clk_out3_clk_wiz_0;

   BUFG clkout4_buf
    (.O   (clk_out4),
     .I   (clk_out4_clk_wiz_0));
//assign clk_out4 = clk_out4_clk_wiz_0;

   BUFG clkout5_buf
    (.O   (clk_out5),
     .I   (clk_out5_clk_wiz_0));
//assign clk_out5 = clk_out5_clk_wiz_0;

   BUFG clkout6_buf
    (.O   (clk_out6),
     .I   (clk_out6_clk_wiz_0));
//assign clk_out6 = clk_out6_clk_wiz_0;


endmodule

`endif