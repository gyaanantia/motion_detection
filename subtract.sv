module subtract (
    input  logic        clock,
    input  logic        reset,
    output logic        bg_rd_en,
    input  logic        bg_empty,
    input  logic [23:0] bg_dout,
    output logic        fr_rd_en,
    input  logic        fr_empty,
    input  logic [23:0] fr_dout,
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [23:0]  out_din
);

typedef enum logic [0:0] {s0, s1} state_types;
state_types state, state_c;

logic [23:0] sub, sub_c;
logic [8:0] tmp_sub, absolute;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= s0;
        sub <= 24'h0;
    end else begin
        state <= state_c;
        sub <= sub_c;
    end
end

always_comb begin
    bg_rd_en  = 1'b0;
    fr_rd_en  = 1'b0;
    out_wr_en = 1'b0;
    out_din   = 24'b0;
    state_c   = state;
    sub_c = sub;
    tmp_sub =  ($unsigned({1'b0, fr_dout[7:0]}) - $unsigned({1'b0, bg_dout[7:0]}));
    absolute = (tmp_sub[8] == 1'b1) ? ~tmp_sub + 9'd1 : tmp_sub;

    case (state)
        s0: begin
            if (bg_empty == 1'b0 && fr_empty == 1'b0) begin
                sub_c = ($unsigned(absolute) <= 9'd50) ? 24'b0 : 24'hffffff;
                bg_rd_en = 1'b1;
                fr_rd_en = 1'b1;
                state_c = s1;
            end
        end

        s1: begin
            if (out_full == 1'b0) begin
                out_din = sub;
                out_wr_en = 1'b1;
                state_c = s0;
            end
        end

        default: begin
            bg_rd_en  = 1'b0;
            fr_rd_en  = 1'b0;
            out_wr_en = 1'b0;
            out_din = 24'b0;
            state_c = s0;
            sub_c = 24'hX;
        end

    endcase
end

endmodule