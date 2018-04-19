//////////////////////////////////////////////////////////////////////////////////
// 
//	SIMULATES L1,L2 CACHE AND MAIN MEMORY ALL WORKING TOGETHER
// 
//////////////////////////////////////////////////////////////////////////////////

module CacheModel #(parameter CORE = 0, DATA_WIDTH = 32, ADDR_WIDTH = 8)(
	input 						clk,			// clock
	input 						rst,			// synchronous reset active high
	input 						report			// report stats active high
	input 						readEnable,
	input 						writeEnable,
	input	[ADDR_WIDTH-1:0]	readAddress,
	input	[ADDR_WIDTH-1:0]	writeAddress,
	input	[DATA_WIDTH-1:0]	writeData,
	output	[DATA_WIDTH-1:0]	readData
);


endmodule
