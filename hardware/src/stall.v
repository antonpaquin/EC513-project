module StallUnit (
        input wire clk,
        input wire start,

        output reg fd,
        output reg de,
        output reg em,
        output reg mw
    );

    initial begin
        fd <= 1;
        de <= 0;
        em <= 0;
        mw <= 0;
    end

    always @(posedge clk) begin
        fd <= mw;
        de <= fd;
        em <= de;
        mw <= em;
    end

endmodule
