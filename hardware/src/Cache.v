//////////////////////////////////////////////////////////////////////////////////
// 
//	GENERIC DIRECT-MAPPED CACHE MODEL WITH WRITEBACK & WRITEALLOCATE
// 
//////////////////////////////////////////////////////////////////////////////////

// TODO: should have different read and write inputs for consistency?
// TODO: implement lower levels memory search

module Cache #(
	parameter LOG_NUM_LINES = 12,		// number of entries in cache
	parameter LOG_NUM_BLOCKS = 2,		// number of blocks in each cache line
	parameter DATA_WIDTH = 32)(
	input 						clk,
	input 						rst,
	input 						write_en,
	input 	[DATA_WIDTH-1:0]	write_data,
	input 	[LOG_NUM_LINES:0] 	address,
	output						hit,
	output	[DATA_WIDTH-1:0]	read_data
);

	localparam NUM_TAG_BITS = DATA_WIDTH-LOG_NUM_LINES-LOG_NUM_BLOCKS;
	localparam NUM_LINES = 2**LOG_NUM_LINES;
	localparam NUM_BLOCKS = 2**LOG_NUM_BLOCKS;

	// tags of all data in cache
	reg [NUM_TAG_BITS-1:0] tags[0:2**LOG_NUM_LINES];

	// dirty bits of all data in cache
	reg dirty[0:NUM_LINES-1];

	// valid bits of all data in cache
	reg valid[0:NUM_LINES-1];
	
	// each cache line is of size (data width) * (num blocks)
	reg [DATA_WIDTH*NUM_BLOCKS-1:0] cachemem[0:NUM_LINES-1];

	// index, tag, block offset bits in requested address
	wire [NUM_TAG_BITS-1:0] tag = address[31:32-NUM_TAG_BITS];
	wire [LOG_NUM_BLOCKS-1:0] block_offset = address[LOG_NUM_BLOCKS-1:0];
	wire [LOG_NUM_LINES-1:0] index = address[LOG_NUM_LINES+LOG_NUM_BLOCKS-1:LOG_NUM_BLOCKS];

	// does this cache have the requested data
	assign hit = cachemem[index][ DATA_WIDTH*(NUM_BLOCKS-block_offset) - 1 : DATA_WIDTH*(NUM_BLOCKS-block_offset) - DATA_WIDTH ];

	// asynchronous read 
	assign read_data = hit ? cachemem[index][ DATA_WIDTH*(NUM_BLOCKS-block_offset) - 1 : DATA_WIDTH*(NUM_BLOCKS-block_offset) - DATA_WIDTH ]
					 : 0;

	always @ (posedge clk) begin

		if (write_en) begin
			cachemem[index][ DATA_WIDTH*(NUM_BLOCKS-block_offset) - 1 : DATA_WIDTH*(NUM_BLOCKS-block_offset) - DATA_WIDTH ] = write_data;
		end // if (write_en)

	end // always @ (posedge clk)

endmodule
