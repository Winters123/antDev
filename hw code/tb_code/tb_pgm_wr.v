`timescale 1 ns/ 1ps
module pgm_wr_test
	(
	);
//define reg and wire


	reg clk;
	reg rst_n;

//receive data & phv from Previous module
	
    reg [1023:0] in_wr_phv;
	reg in_wr_phv_wr;
	wire out_wr_phv_alf;

	reg [133:0] in_wr_data;
	reg in_wr_data_wr;
	reg in_wr_valid_wr;
	reg in_wr_valid;
	wire out_wr_alf;

//transport phv and data to pgm_rd
    wire [1023:0] out_wr_phv;
	wire out_wr_phv_wr;
	reg in_wr_phv_alf;
	wire [133:0] out_wr_data;
	wire out_wr_data_wr;
	wire out_wr_valid;
	wire out_wr_valid_wr;
	reg in_wr_alf;

//wire to PGM_RA;
	wire wr2ram_wr_en;
	wire [143:0] wr2ram_wdata;
	wire [6:0] wr2ram_addr;

//signals to PRM_R;
	wire pgm_bypass_flag;
	wire pgm_sent_start_flag;
	wire pgm_sent_finish_flag;

//reg cfg packet from DMA
    reg [133:0] cin_wr_data;
	reg cin_wr_data_wr;
	wire cout_wr_ready;

//wire configure pkt to next module
    wire [133:0] cout_wr_data;
	wire cout_wr_data_wr;
	reg cin_wr_ready;




//initialize module
pgm_wr pgm_wr_ctl_tb(

	.clk(clk),
	.rst_n(rst_n),
	.in_wr_phv(in_wr_phv),
	.in_wr_phv_wr(in_wr_phv_wr), 
	.out_wr_phv_alf(out_wr_phv_wr),
	.in_wr_data(in_wr_data),
	.in_wr_data_wr(in_wr_data_wr),
	.in_wr_valid_wr(in_wr_valid_wr),
	.in_wr_valid(in_wr_valid),
	.out_wr_alf(out_wr_alf),

//transport phv and data to pgm_rd
    .out_wr_phv(out_wr_phv),
	.out_wr_phv_wr(out_wr_phv_wr),
	.in_wr_phv_alf(in_wr_phv_alf),

	.out_wr_data(out_wr_data), 
	.out_wr_data_wr(out_wr_data_wr),
	.out_wr_valid(out_wr_valid),
	.out_wr_valid_wr(out_wr_valid_wr),
	.in_wr_alf(in_wr_alf),

//wire to PGM_RAM
	.wr2ram_wr_en(wr2ram_wr_en),
	.wr2ram_wdata(wr2ram_wdata),
	.wr2ram_addr(wr2ram_addr),


//signals to PRM_RD
	.pgm_bypass_flag(pgm_bypass_flag),
	.pgm_sent_start_flag(pgm_sent_start_flag),
	.pgm_sent_finish_flag(pgm_sent_finish_flag),

//reg cfg packet from DMA
    .cin_wr_data(cin_wr_data),
	.cin_wr_data_wr(cin_wr_data_wr),
	.cout_wr_ready(cout_wr_ready),

//wire configure pkt to next module
    .cout_wr_data(cout_wr_data),
	.cout_wr_data_wr(cout_wr_data_wr),
	.cin_wr_ready(cin_wr_ready)
);
//Part 3: Clk

parameter CYCLE = 10;

//Part 1: wire connection
//Part 2: Reset
initial begin
	clk = 0;
	rst_n = 1;
	#(5);
	rst_n = 0;
	#(5);
	rst_n = 1;
end

//start user code
initial begin
	//tb for control path
	/*
	#CYCLE in_wr_phv = 1024'b0;
	in_wr_phv_wr = 1'b0;
	in_wr_phv_wr = 1'b0;

	in_wr_data = 133'b0;
	in_wr_data_wr = 1'b0;
	in_wr_valid = 1'b0;
	in_wr_valid_wr = 1'b0;
	in_wr_alf = 1'b0;

	cin_wr_ready = 1'b1;

	cin_wr_data_wr = 1'b1;
	cin_wr_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};

	#CYCLE in_wr_phv = 1024'b0;
	in_wr_phv_wr = 1'b0;
	in_wr_phv_wr = 1'b0;

	in_wr_data = 133'b0;
	in_wr_data_wr = 1'b0;
	in_wr_valid = 1'b0;
	in_wr_valid_wr = 1'b0;
	in_wr_alf = 1'b0;

	cin_wr_ready = 1'b1;

	cin_wr_data_wr = 1'b1;
	cin_wr_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};

	#CYCLE in_wr_phv = 1024'b0;
	in_wr_phv_wr = 1'b0;
	in_wr_phv_wr = 1'b0;

	in_wr_data = 133'b0;
	in_wr_data_wr = 1'b0;
	in_wr_valid = 1'b0;
	in_wr_valid_wr = 1'b0;
	in_wr_alf = 1'b0;

	cin_wr_ready = 1'b1;

	cin_wr_data_wr = 1'b1;
	cin_wr_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010002,32'hffffffff,32'h00000000};

	#CYCLE in_wr_phv = 1024'b0;
	in_wr_phv_wr = 1'b0;
	in_wr_phv_wr = 1'b0;

	in_wr_data = 133'b0;
	in_wr_data_wr = 1'b0;
	in_wr_valid = 1'b0;
	in_wr_valid_wr = 1'b0;
	in_wr_alf = 1'b0;

	cin_wr_ready = 1'b1;

	cin_wr_data_wr = 1'b1;
	cin_wr_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010002,32'hffffffff,32'h00000000};

	#(10*CYCLE);
	$finish; 
	*/
	//tb for data path
	#CYCLE in_wr_phv = 1024'b0;
	in_wr_phv_wr = 1'b1;
	in_wr_phv_wr = 1'b1;

	in_wr_data = {6'b010000, };
	in_wr_data_wr = 1'b1;
	in_wr_valid = 1'b1;
	in_wr_valid_wr = 1'b0;
	in_wr_alf = 1'b0;

	cin_wr_ready = 1'b1;

	cin_wr_data_wr = 1'b0;
	cin_wr_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};
end

always begin
	#(CYCLE/2) clk = ~ clk;
end

endmodule