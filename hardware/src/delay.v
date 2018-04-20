module delay #(
        parameter BITS = 0
    ) (
        input wire [BITS-1:0] in,
        output reg [BITS-1:0] out,
        input wire clk
    );

    always @(posedge clk) begin
        out <= in;
    end

endmodule

