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
	
	reg 					l1i_hit, l1d_hit;
	reg 					l1i_is_dirty, l1d_is_dirty;
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
		.is_dirty  (l1i_is_dirty),
		.read_data (l1i_read_data)
	);

	Cache l1dcache (
		.clk       (clk),
		.rst       (rst),
		.write_en  (l1d_write_en),
		.write_data(l1d_write_data),
		.address   (l1d_address),
		.hit       (l1d_hit),
		.is_dirty  (l1d_is_dirty),
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
		.is_dirty  (l2_is_dirty),
		.read_data (l2_read_data)
	);

	// TODO
	wire readEnable = 1;

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

	always @(posedge clk) begin

		if (~l1d_hit) begin
			l1d_write_en <= 1;
			l1d_write_data <= mm_read_data;
		end // if (~l1d_hit)

	end // always @(posedge clk)

///////////////////////////////////// WRITES /////////////////////////////////////

	// always @(posedge clk) begin
		
	// 	if (~rst) begin

	// 		if (write_en) begin

	// 			// if dirty then need to transfer to main before overwriting
	// 			if (l1d_is_dirty) begin
	// 				mm_write_en <= 1;
	// 				mm_write_data <= l1d_read_data;
	// 			end

	// 			// just write to l1 cache now, move to lower when dirty
	// 			l1d_write_en <= 1;	

	// 		end // if (write_en)

	// 	end

	// end // always @(posedge clk)



endmodule
