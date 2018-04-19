//////////////////////////////////////////////////////////////////////////////////
// 
//	SIMULATES L1,L2 CACHE AND MAIN MEMORY ALL WORKING TOGETHER
// 
//////////////////////////////////////////////////////////////////////////////////

// TODO: i-cache

module CacheModel #(parameter CORE = 0, DATA_WIDTH = 32, ADDR_WIDTH = 8)(
	input 						clk,			// clock
	input 						rst,			// synchronous reset active high
	input 						report,			// report stats active high
	input 						write_en,
	input	[ADDR_WIDTH-1:0]	address,
	input	[DATA_WIDTH-1:0]	write_data,
	output	[DATA_WIDTH-1:0]	read_data
);


///////////////////////////////////// L1 CACHE /////////////////////////////////////
	
	wire 					l1i_hit, l1d_hit;
	reg 					l1i_write_en, l1d_write_en;
	reg	[ADDR_WIDTH-1:0]	l1i_address, l1d_address;
	reg	[DATA_WIDTH-1:0]	l1i_write_data, l1d_write_data;
	reg	[DATA_WIDTH-1:0]	l1i_read_data, l1d_read_data;

	Cache l1icache (
		.clk       (clk),
		.rst       (rst),
		.write_en  (l1i_write_en),
		.write_data(l1i_write_data),
		.address   (l1i_address),
		.hit       (l1i_hit),
		.read_data (l1i_read_data)
	);

	Cache l1dcache (
		.clk       (clk),
		.rst       (rst),
		.write_en  (l1d_write_en),
		.write_data(l1d_write_data),
		.address   (l1d_address),
		.hit       (l1d_hit),
		.read_data (l1d_read_data)
	);


///////////////////////////////////// L2 CACHE /////////////////////////////////////

	Cache l2cache (
		.clk       (clk),
		.rst       (rst),
		.write_en  (l2_write_en),
		.write_data(l2_write_data),
		.address   (l2_address),
		.hit       (l2_hit),
		.read_data (l2_read_data)
	);


///////////////////////////////////// MAIN MEMORY /////////////////////////////////////

	BRAM main_memory (
		.clock       (clk),
		.readEnable  (readEnable),
		.readAddress (address),
		.readData    (mm_read_data),
		.writeEnable (mm_write_en),
		.writeAddress(address),
		.writeData   (mm_write_data)
	);


////////////////////////////////////// READS //////////////////////////////////////

	// In this simulation, all caches and mem can be read at the same time but
	// this is not realistic and impossible in real workd
	assign read_data = l1d_hit	?	l1d_read_data
					 : l2_hit	?	l2_read_data
					 : mm_read_data;


///////////////////////////////////// WRITES /////////////////////////////////////

	// write through all levels of memory
	assign l1d_write_en = write_en;
	assign l2_write_en = write_en;
	assign mm_write_en = write_en;

endmodule
