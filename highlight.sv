module imgtract (
    input  logic        clock,
    input  logic        reset,
    output logic        img_rd_en,
    input  logic        img_empty,
    input  logic [23:0] img_dout,
    output logic        fr_rd_en,
    input  logic        fr_empty,
    input  logic [23:0] fr_dout,
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [23:0]  out_din
);

typedef enum logic [0:0] {s0, s1} state_types;
state_types state, state_c;

logic [23:0] img, img_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= s0;
        img <= 24'h0;
    end else begin
        state <= state_c;
        img <= img_c;
    end
end

always_comb begin
    img_rd_en  = 1'b0;
    fr_rd_en  = 1'b0;
    out_wr_en = 1'b0;
    out_din   = 24'b0;
    state_c   = state;
    img_c = img;

    case (state)
        s0: begin
            if (img_empty == 1'b0 && fr_empty == 1'b0) begin
                img_c = ($unsigned(sub_dout) == 24'b0) ? fr_dout : 24'h0000ff;
                img_rd_en = 1'b1;
                fr_rd_en = 1'b1;
                state_c = s1;
            end
        end

        s1: begin
            if (out_full == 1'b0) begin
                out_din = img;
                out_wr_en = 1'b1;
                state_c = s0;
            end
        end

        default: begin
            img_rd_en  = 1'b0;
            fr_rd_en  = 1'b0;
            out_wr_en = 1'b0;
            out_din = 24'b0;
            state_c = s0;
            img_c = 24'hX;
        end

    endcase
end

endmodule