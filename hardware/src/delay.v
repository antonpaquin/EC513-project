module delay #(
        parameter BITS = 0
    ) (
        input wire [BITS-1:0] in,
        output reg [BITS-1:0] out,
        input wire en,
        input wire clk
    );

    always @(posedge clk) begin
        if (en) begin
            out <= in;
        end
    end

endmodule

