module motion_detect_top #(
    parameter DATA_WIDTH = 24,
    parameter FIFO_BUFFER_SIZE = 32
)
(
    input logic clock,
    input logic reset,
    
);

// input fifos

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) background (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(bg_wr_en), // TODO: add input logic signal
    .din(bg_din), // TODO: add input logic [DATA_WIDTH-1:0] signal
    .full(bg_full), // TODO: add output logic signal 
    .rd_clk(clock),
    .rd_en(bg_rd_en), // TODO: add logic signal output from the bg_grayscale module
    .dout(bg_dout), // TODO: add logic signal [DATA_WIDTH-1:0] input to the bg_grayscale instance
    .empty(bg_empty) // TODO: add logic signal input to the bg_grayscale instance
);

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) frame (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fr_wr_en), // TODO: add input logic signal
    .din(fr_din), // TODO: add input logic [DATA_WIDTH-1:0] signal
    .full(fr_full), // TODO: add output logic signal 
    .rd_clk(clock),
    .rd_en(fr_rd_en), // TODO: add logic signal output from the fr_grayscale module
    .dout(fr_dout), // TODO: add logic signal [DATA_WIDTH-1:0] input to the fr_grayscale instance
    .empty(fr_empty) // TODO: add logic signal input to the fr_grayscale instance
);

// grayscales

grayscale bg_grayscale (
    .clock(clock),
    .reset(reset),
    .in_dout(bg_dout),
    .in_rd_en(bg_rd_en),
    .in_empty(bg_empty),
    .out_din(gray_bg_din), // TODO: add logic signal [7:0] input to the gray_bg fifo
    .out_full(gray_bg_full), // TODO: add logic signal output from gray_bg fifo
    .out_wr_en(gray_bg_wr_en) // TODO: add logic signal input to gray_bg fifo 
);

grayscale fr_grayscale (
    .clock(clock),
    .reset(reset),
    .in_dout(fr_dout),
    .in_rd_en(fr_rd_en),
    .in_empty(fr_empty),
    .out_din(gray_fr_din), // TODO: add logic signal [7:0] input to the gray_fr fifo
    .out_full(gray_fr_full), // TODO: add logic signal output from the gray_fr fifo
    .out_wr_en(gray_fr_wr_en) // TODO: add logic signal input to gray_fr fifo 
);

// grayscale fifos

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) gray_bg (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(gray_bg_wr_en),
    .din({gray_bg_din, gray_bg_din, gray_bg_din}),
    .full(gray_bg_full),
    .rd_clk(clock),
    .rd_en(sub_bg_rd_en), // TODO: add logic signal output from subtract instance
    .dout(gray_bg_dout), // TODO: add logic signal [DATA_WIDTH-1:0] input to subtract instance
    .empty(gray_bg_empty) // TODO: add logic signal input to subtract instance
);

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) gray_fr (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(gray_fr_wr_en),
    .din({gray_fr_din, gray_fr_din, gray_fr_din}),
    .full(gray_fr_full),
    .rd_clk(clock),
    .rd_en(sub_fr_rd_en), // TODO: add logic signal output from subtract instance
    .dout(gray_fr_dout), // TODO: add logic signal [DATA_WIDTH-1:0] input to subtract instance
    .empty(gray_fr_empty) // TODO: add logic signal input to subtract instance
);

// subtract

subtract subtractor (
    .clock(clock),
    .reset(reset),
    .bg_rd_en(sub_bg_rd_en),
    .bg_empty(gray_bg_empty),
    .bg_dout(gray_bg_dout),
    .fr_rd_en(sub_fr_rd_en),
    .fr_empty(gray_fr_empty),
    .fr_dout(gray_fr_dout),
    .out_wr_en(sub_wr_en), // TODO: add logic signal input into sub_fifo
    .out_full(sub_full), // TODO: add logic signal output from sub_fifo
    .out_din(sub_din) // TODO: add logic signal [DATA_WIDTH-1:0] input to sub fifo
);

// post-subtract fifo and pre-highlight frame fifo

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) sub_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(sub_wr_en),
    .din(sub_din),
    .full(sub_full),
    .rd_clk(clock),
    .rd_en(highlight_sub_rd_en), // TODO: add logic signal output from highlight
    .dout(sub_fifo_dout), // TODO: add logic signal [DATA_WIDTH-1:0] input to highlight
    .empty(sub_fifo_empty) //TODO: add logic signal input to highlight
);

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) pre_highlight_frame_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(highlight_fr_wr_en), // TODO: add input logic signal
    .din(highlight_fr_din), // TODO: add input logic [DATA_WIDTH-1:0] signal
    .full(highlight_fr_full), // TODO: add output logic signal
    .rd_clk(clock),
    .rd_en(highlight_fr_rd_en), // TODO: add logic signal output from highlight
    .dout(highlight_fr_dout), // TODO: add logic signal [DATA_WIDTH-1:0] input to highlight
    .empty(highlight_fr_empty) //TODO: add logic signal input to highlight
);

// highlight

highlight highlighter (
    .clock(clock),
    .reset(reset),
    .img_rd_en(highlight_sub_rd_en),
    .img_empty(sub_fifo_empty),
    .img_dout(sub_fifo_dout),
    .fr_rd_en(highlight_fr_rd_en),
    .fr_empty(highlight_fr_empty),
    .fr_dout(highlight_fr_dout),
    .out_wr_en(final_fifo_wr_en), // TODO: add logic signal input to final fifo
    .out_full(final_fifo_full), // TODO: add logic signal output from final fifo
    .out_din(final_fifo_din) // TODO: add logic signal [DATA_WIDTH-1:0] input to final fifo
);

// final fifo

fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(DATA_WIDTH)
) final_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(final_fifo_wr_en),
    .din(final_fifo_din),
    .full(final_fifo_full),
    .rd_clk(clock),
    .rd_en(rd_en), // TODO: add output logic signal
    .dout(dout), // TODO: add output logic [DATA_WIDTH-1:0] signal
    .empty(empty) // TODO: add output logic signal
);

endmodule
