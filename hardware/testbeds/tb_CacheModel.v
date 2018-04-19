module tb_CacheModel;

	// Inputs
	reg 		clk;
	reg 		rst;
	reg 		report;
	reg 		write_en;
	reg	[7:0]	address;
	reg	[31:0]	write_data;

	// Outputs
	wire [31:0] read_data;

	CacheModel uut (
		.clk       (clk),
		.rst       (rst),
		.report    (report),
		.write_en  (write_en),
		.address   (address),
		.write_data(write_data),
		.read_data (read_data)
	);

	// clock generator
	always #1 clk = ~clk;

	initial begin

		$dumpfile("CacheModel.vcd");
		$dumpvars(0, uut, uut.l1dcache.cachemem[0][0], uut.l1dcache.cachemem[0][1]);

		clk = 1;
		rst = 1;
		report = 0;
		write_en = 0;
		address = 8'h20;
		write_data = 32'habcdef;

		#10 rst = 0;

		write_en = 1;

		#4;
		$finish;

	end // initial

endmodule