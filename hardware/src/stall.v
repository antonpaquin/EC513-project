module StallUnit (
        input wire clk,
        input wire start,

        input wire [4:0] reg_src_a,
        input wire [4:0] reg_src_b,
        input wire [4:0] reg_dest,

        input wire [19:0] mem_src,
        input wire [19:0] mem_dest,

        input wire [6:0] opcode,

        output wire stall
    );

    reg [4:0] reg_queue [3:0];
    reg [19:0] mem_queue [3:0];
    reg branch_queue [3:0];

    wire branch;

    wire rega_dep;
    wire regb_dep;
    wire mem_dep;
    wire branch_dep;

    wire [4:0] reg_queue3 = reg_queue[3];
    wire [4:0] reg_queue2 = reg_queue[2];
    wire [4:0] reg_queue1 = reg_queue[1];
    wire [4:0] reg_queue0 = reg_queue[0];

    assign branch = (
        (opcode == 7'b1100011) ||
        (opcode == 7'b1100111) ||
        (opcode == 7'b1101111)
    );

    assign rega_dep = (
        (reg_src_a != 0) && 
        (
            reg_src_a == reg_queue[3] ||
            reg_src_a == reg_queue[2] ||
            reg_src_a == reg_queue[1] ||
            reg_src_a == reg_queue[0]
        )
    );
    assign regb_dep = (
        (reg_src_b != 0) && 
        (
            reg_src_b == reg_queue[3] ||
            reg_src_b == reg_queue[2] ||
            reg_src_b == reg_queue[1] ||
            reg_src_b == reg_queue[0]
        )
    );
    assign mem_dep = (
        (mem_src != 0) &&
        (
            mem_src == mem_queue[3] ||
            mem_src == mem_queue[2] ||
            mem_src == mem_queue[1] ||
            mem_src == mem_queue[0]
        )
    );
    assign branch_dep = (
        branch_queue[3] |
        branch_queue[2] |
        branch_queue[1] |
        branch_queue[0]
    );

    assign stall = (rega_dep || regb_dep || mem_dep || branch_dep);

    always @(posedge clk) begin
        if (stall) begin
            reg_queue[2] <= 0;
            mem_queue[2] <= 0;
            branch_queue[2] <= 0;
        end else begin
            reg_queue[2] <= reg_dest;
            mem_queue[2] <= mem_dest;
            branch_queue[2] <= branch;
        end
        //reg_queue[2] <= reg_queue[3];
        reg_queue[1] <= reg_queue[2];
        reg_queue[0] <= reg_queue[1];

        //mem_queue[2] <= mem_queue[3];
        mem_queue[1] <= mem_queue[2];
        mem_queue[0] <= mem_queue[1];

        //branch_queue[2] <= branch_queue[3];
        branch_queue[1] <= branch_queue[2];
        branch_queue[0] <= branch_queue[1];
    end

    initial begin
        reg_queue[3] <= 0;
        reg_queue[2] <= 0;
        reg_queue[1] <= 0;
        reg_queue[0] <= 0;

        mem_queue[3] <= 0;
        mem_queue[2] <= 0;
        mem_queue[1] <= 0;
        mem_queue[0] <= 0;

        branch_queue[3] <= 0;
        branch_queue[2] <= 0;
        branch_queue[1] <= 0;
        branch_queue[0] <= 0;
    end
endmodule
