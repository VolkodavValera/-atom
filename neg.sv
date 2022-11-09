module neg (clk, in, out);
    input   clk;
    input   in;
    output  out;
    logic   d;

    always_ff @ (posedge clk) begin
        d <= in;
    end

    assign out = (~in & d);

endmodule // neg
