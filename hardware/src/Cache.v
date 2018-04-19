//////////////////////////////////////////////////////////////////////////////////
// 
//	GENERIC DIRECT-MAPPED CACHE MODEL WITH WRITE-THROUGH AND NO-WRITE-ALLOCATE
// 
//////////////////////////////////////////////////////////////////////////////////

// TODO: should have different read and write inputs for consistency?

module Cache #(
	parameter LOG_NUM_LINES = 2,		// number of lines (entries) in cache
	parameter LOG_NUM_BLOCKS = 1,		// number of blocks in each cache line
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 8)(
	input 						clk,
	input 						rst,
	input 						write_en,
	input 	[DATA_WIDTH-1:0]	write_data,
	input 	[ADDR_WIDTH-1:0] 	address,
	output						hit,
	output	[DATA_WIDTH-1:0]	read_data
);

	localparam NUM_TAG_BITS = DATA_WIDTH-LOG_NUM_LINES-LOG_NUM_BLOCKS;
	localparam NUM_LINES = 2**LOG_NUM_LINES;
	localparam NUM_BLOCKS = 2**LOG_NUM_BLOCKS;

	// valid bits of all data in cache
	reg valid[0:NUM_LINES-1];
	
	// tags of all data in cache
	reg [NUM_TAG_BITS-1:0] tags[0:NUM_LINES-1];

	// actual cache storage. each cache line is of size (data width) * (num blocks)
	reg [DATA_WIDTH-1:0] cachemem[0:NUM_LINES-1][0:NUM_BLOCKS-1];

	// index, tag, block offset bits in requested address
	wire [NUM_TAG_BITS-1:0] tag = address[ADDR_WIDTH-1:ADDR_WIDTH-NUM_TAG_BITS];
	wire [LOG_NUM_BLOCKS-1:0] block_offset = address[LOG_NUM_BLOCKS-1:0];
	wire [LOG_NUM_LINES-1:0] index = address[LOG_NUM_LINES+LOG_NUM_BLOCKS-1:LOG_NUM_BLOCKS];

	// does this cache have the requested data
	assign hit = valid[index] && tags[index]==tag;

	// asynchronous read
	assign read_data = cachemem[index][block_offset];

	integer i;
	always @ (posedge clk) begin

		if (rst) begin

			for (i = 0; i < NUM_LINES; i=i+1) begin
				valid[i] <= 1'b0;
			end
		
		end // if (rst)

		else if (write_en) begin

			cachemem[index][block_offset] = write_data;
			valid[index] <= 1'b1;
		
		end // if (write_en)

	end // always @ (posedge clk)

endmodule
