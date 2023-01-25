`timescale 1 ns / 1 ns

module motion_detect_tb;

localparam BG_IMG_NAME  = "/home/gfa2226/fpga/hw3/motion_detect/base.bmp";
localparam FR_IMG_NAME  = "/home/gfa2226/fpga/hw3/motion_detect/pedestrians.bmp";
localparam HIGHLIGHT_FR_IMG_NAME  = "/home/gfa2226/fpga/hw3/motion_detect/pedestrians_copy.bmp";
localparam IMG_CMP_NAME = "/home/gfa2226/fpga/hw3/motion_detect/img_out.bmp";
localparam IMG_OUT_NAME = "/home/gfa2226/fpga/hw3/motion_detect/detect.bmp";
localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic        bg_wr_en = '0;
logic [23:0] bg_din   = '0;
logic        bg_full;
logic        fr_wr_en = '0;
logic [23:0] fr_din   = '0;
logic        fr_full;
logic        highlight_fr_wr_en = '0;
logic [23:0] highlight_fr_din = '0;
logic        highlight_fr_full;
logic        rd_en;
logic [23:0] dout;
logic        empty;

logic hold_clock = '0;
logic bg_write_done = '0;
logic fr_write_done = '0;
logic highlight_fr_write_done = '0;
logic out_read_done = '0;
integer errors = '0;

localparam WIDTH = 768;
localparam HEIGHT = 576;
localparam BMP_HEADER_SIZE = 54;
localparam BYTES_PER_PIXEL = 3;
localparam BMP_DATA_SIZE = WIDTH*HEIGHT*BYTES_PER_PIXEL;

motion_detect_top dut (
    .clock(clock),
    .reset(reset),
    .bg_wr_en(bg_wr_en),
    .bg_din(bg_din),
    .bg_full(bg_full),
    .fr_wr_en(fr_wr_en),
    .fr_din(fr_din),
    .fr_full(fr_full),
    .highlight_fr_wr_en(highlight_fr_wr_en),
    .highlight_fr_din(highlight_fr_din),
    .highlight_fr_full(highlight_fr_full),
    .rd_en(rd_en),
    .dout(dout),
    .empty(empty)
);

always begin
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
end

initial begin
    @(posedge clock);
    reset = 1'b1;
    @(posedge clock);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;

    @(negedge reset);
    @(posedge clock);
    start_time = $time;

// start
    $display("@ %0t: Beginning simulation...", start_time);
    start = 1'b1;
    @(posedge clock);
    start = 1'b0;

    wait(out_read_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Total error count: %0d", errors);

    // end the simulation
    $stop;
end

initial begin : bg_read_process
    int i, r;
    int bg_file;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, BG_IMG_NAME);

    bg_file = $fopen(BG_IMG_NAME, "rb");
    bg_wr_en = 1'b0;

    // Skip BMP header
    r = $fread(bmp_header, bg_file, 0, BMP_HEADER_SIZE);

    // Read data from image file 
    i = 0;
    while ( i < BMP_DATA_SIZE ) begin
        @(negedge clock);
        bg_wr_en = 1'b0;
        if (bg_full == 1'b0) begin
            r = $fread(bg_din, bg_file, BMP_HEADER_SIZE + i, BYTES_PER_PIXEL);
            bg_wr_en = 1'b1;
            i += BYTES_PER_PIXEL;
        end
    end

    @(negedge clock);
    bg_wr_en = 1'b0;
    $fclose(bg_file);
    bg_write_done = 1'b1;

end

initial begin : fr_read_process
    int i, r;
    int fr_file;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FR_IMG_NAME);

    fr_file = $fopen(FR_IMG_NAME, "rb");
    fr_wr_en = 1'b0;

    // Skip BMP header
    r = $fread(bmp_header, fr_file, 0, BMP_HEADER_SIZE);

    // Read data from image file 
    i = 0;
    while ( i < BMP_DATA_SIZE ) begin
        @(negedge clock);
        fr_wr_en = 1'b0;
        if (fr_full == 1'b0) begin
            r = $fread(fr_din, fr_file, BMP_HEADER_SIZE + i, BYTES_PER_PIXEL);
            fr_wr_en = 1'b1;
            i += BYTES_PER_PIXEL;
        end
    end

    @(negedge clock);
    fr_wr_en = 1'b0;
    $fclose(fr_file);
    fr_write_done = 1'b1;

end

initial begin : highlight_fr_read_process  
    int i, r;
    int highlight_fr_file;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);

    $display("@ %0t: Loading file %s...", $time, HIGHLIGHT_FR_IMG_NAME);

    highlight_fr_file = $fopen(HIGHLIGHT_FR_IMG_NAME, "rb");
    highlight_fr_wr_en = 1'b0;

    // Skip BMP header
    r = $fread(bmp_header, highlight_fr_file, 0, BMP_HEADER_SIZE);

    // Read data from image file 
    i = 0;
    while ( i < BMP_DATA_SIZE ) begin
        @(negedge clock);
        highlight_fr_wr_en = 1'b0;
        if (highlight_fr_full == 1'b0) begin
            r = $fread(highlight_fr_din, highlight_fr_file, BMP_HEADER_SIZE + i, BYTES_PER_PIXEL);
            highlight_fr_wr_en = 1'b1;
            i += BYTES_PER_PIXEL;
        end
    end

    @(negedge clock);
    highlight_fr_wr_en = 1'b0;
    $fclose(highlight_fr_file);
    highlight_fr_write_done = 1'b1;

end

initial begin : img_write_process
    int i, r;
    int out_file;
    int cmp_file;
    logic [23:0] cmp_dout;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, IMG_OUT_NAME);

    out_file = $fopen(IMG_OUT_NAME, "wb");
    cmp_file = $fopen(IMG_CMP_NAME, "rb");
    rd_en = 1'b0;

    // Copy the BMP header
    r = $fread(bmp_header, cmp_file, 0, BMP_HEADER_SIZE);
    for (i = 0; i < BMP_HEADER_SIZE; i++) begin
        $fwrite(out_file, "%c", bmp_header[i]);
    end

    i = 0;
    while (i < BMP_DATA_SIZE) begin
        @(negedge clock);
        rd_en = 1'b0;
        if (empty == 1'b0) begin
            r = $fread(cmp_dout, cmp_file, BMP_HEADER_SIZE+i, 1);
            $fwrite(out_file, "%c%c%c", dout[23:16], dout[15:8], dout[7:0]);
            
            if (cmp_dout != dout) begin
                errors += 1;
                $write("@ %0t: %s(%0d): ERROR: %x != %x at address 0x%x.\n", $time, IMG_OUT_NAME, i+1, dout, cmp_dout, i);
            end
            rd_en = 1'b1;
            i += BYTES_PER_PIXEL;
        end
    end

    @(negedge clock);
    rd_en = 1'b0;
    $fclose(out_file);
    $fclose(cmp_file);
    out_read_done = 1'b1;
end

endmodule
