`timescale 1 ns/ 1ps
module pgm_rd_test
	(
	);
//define reg and wire


	reg clk;
	reg rst_n;

//receive data & phv from Previous module
	
    reg [1023:0] in_rd_phv;
	reg in_rd_phv_wr;
	wire out_rd_phv_alf;

	reg [133:0] in_rd_data;
	reg in_rd_data_wr;
	reg in_rd_valid_wr;
	reg in_rd_valid;
	wire out_rd_alf;

//transport phv and data to pgm_rd
    wire [1023:0] out_rd_phv;
	wire out_rd_phv_wr;
	reg in_rd_phv_alf;
	wire [133:0] out_rd_data;
	wire out_rd_data_wr;
	wire out_rd_valid;
	wire out_rd_valid_wr;
	reg in_rd_alf;

//wire to PGM_RA;
	wire rd2ram_rd;
	wire [6:0] rd2ram_addr;
	reg [143:0] ram2rd_rdata;


//signals to PRM_R;
	reg pgm_bypass_flag;
	reg pgm_sent_start_flag;
	reg pgm_sent_finish_flag;

//reg cfg packet from DMA
    reg [133:0] cin_rd_data;
	reg cin_rd_data_wr;
	wire cout_rd_ready;

//wire configure pkt to next module
    wire [133:0] cout_rd_data;
	wire cout_rd_data_wr;
	reg cin_rd_ready;




//initialize module
pgm_rd pgm_rd_ctl_tb(

	.clk(clk),
	.rst_n(rst_n),
	.in_rd_phv(in_rd_phv),
	.in_rd_phv_wr(in_rd_phv_wr), 
	.out_rd_phv_alf(out_rd_phv_wr),
	.in_rd_data(in_rd_data),
	.in_rd_data_wr(in_rd_data_wr),
	.in_rd_valid_wr(in_rd_valid_wr),
	.in_rd_valid(in_rd_valid),
	.out_rd_alf(out_rd_alf),

//transport phv and data to pgm_rd
    .out_rd_phv(out_rd_phv),
	.out_rd_phv_wr(out_rd_phv_wr),
	.in_rd_phv_alf(in_rd_phv_alf),

	.out_rd_data(out_rd_data), 
	.out_rd_data_wr(out_rd_data_wr),
	.out_rd_valid(out_rd_valid),
	.out_rd_valid_wr(out_rd_valid_wr),
	.in_rd_alf(in_rd_alf),

//wire to PGM_RAM
	.rd2ram_rd(rd2ram_rd),
	.ram2rd_rdata(ram2rd_rdata),
	.rd2ram_addr(rd2ram_addr),


//signals to PRM_RD
	.pgm_bypass_flag(pgm_bypass_flag),
	.pgm_sent_start_flag(pgm_sent_start_flag),
	.pgm_sent_finish_flag(pgm_sent_finish_flag),

//reg cfg packet from DMA
    .cin_rd_data(cin_rd_data),
	.cin_rd_data_wr(cin_rd_data_wr),
	.cout_rd_ready(cout_rd_ready),

//wire configure pkt to next module
    .cout_rd_data(cout_rd_data),
	.cout_rd_data_wr(cout_rd_data_wr),
	.cin_rd_ready(cin_rd_ready)
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

	/*
	//tb for control path
	
	#CYCLE in_rd_phv = 1024'b0;
	in_rd_phv_wr = 1'b0;
	in_rd_phv_wr = 1'b0;

	in_rd_data = 133'b0;
	in_rd_data_wr = 1'b0;
	in_rd_valid = 1'b0;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b1;
	cin_rd_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd62,32'h00010001,32'hffffffff,32'h00000000};

	#CYCLE in_rd_phv = 1024'b0;
	in_rd_phv_wr = 1'b0;
	in_rd_phv_wr = 1'b0;

	in_rd_data = 133'b0;
	in_rd_data_wr = 1'b0;
	in_rd_valid = 1'b0;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b1;
	cin_rd_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd62,32'h00010001,32'hffffffff,32'h00000000};
	

	#CYCLE in_rd_phv = 1024'b0;
	in_rd_phv_wr = 1'b0;
	in_rd_phv_wr = 1'b0;

	in_rd_data = 133'b0;
	in_rd_data_wr = 1'b0;
	in_rd_valid = 1'b0;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b1;
	cin_rd_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd62,32'h00010002,32'hffffffff,32'h00000000};

	#CYCLE in_rd_phv = 1024'b0;
	in_rd_phv_wr = 1'b0;
	in_rd_phv_wr = 1'b0;

	in_rd_data = 133'b0;
	in_rd_data_wr = 1'b0;
	in_rd_valid = 1'b0;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b1;
	cin_rd_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd62,32'h00010002,32'hffffffff,32'h00000000};

	#(10*CYCLE);
	$finish; 
	*/


	//tb for data path
	
	#CYCLE in_rd_phv = 1024'b0;
	pgm_bypass_flag <= 1'b1;

	in_rd_phv_wr = 1'b1;
	in_rd_phv_alf = 1'b0;

	in_rd_data = {6'b010000, 16'b0, 3'b111, 13'b0, 32'b0, 64'b0};


	in_rd_data_wr = 1'b1;
	in_rd_valid = 1'b1;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b0;
	cin_rd_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};

	//2nd
	#CYCLE in_rd_phv = 1024'b0;
	in_rd_phv_wr = 1'b1;
	in_rd_phv_alf = 1'b0;

	in_rd_data = {6'b110000, 16'b0, 16'b0, 32'b0, 64'd2};
	

	in_rd_data_wr = 1'b1;
	in_rd_valid = 1'b1;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b0;
	cin_rd_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};

	//3rd
	#CYCLE in_rd_phv = 1024'b0;
	in_rd_phv_wr = 1'b1;
	in_rd_phv_alf = 1'b0;

	in_rd_data = {6'b110000, 16'b0, 16'b0, 32'b0, 64'd2};
	

	in_rd_data_wr = 1'b1;
	in_rd_valid = 1'b1;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b0;
	cin_rd_data = {6'b010000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};


	//4th
	#CYCLE in_rd_phv = 1024'b0;

	pgm_bypass_flag <= 1'b0;

	in_rd_phv_wr = 1'b1;
	in_rd_phv_alf = 1'b0;

	in_rd_data = {6'b100000, 16'b0, 16'b0, 32'b0, 64'd3};
	

	in_rd_data_wr = 1'b1;
	in_rd_valid = 1'b1;
	in_rd_valid_wr = 1'b1;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b0;
	cin_rd_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};

	//5th
	#CYCLE in_rd_phv = 1024'b0;

	pgm_bypass_flag <= 1'b0;

	in_rd_phv_wr = 1'b0;
	in_rd_phv_alf = 1'b0;

	in_rd_data = {6'b100000, 16'b0, 16'b0, 32'b0, 64'd3};
	

	in_rd_data_wr = 1'b0;
	in_rd_valid = 1'b1;
	in_rd_valid_wr = 1'b0;
	in_rd_alf = 1'b0;

	cin_rd_ready = 1'b1;

	cin_rd_data_wr = 1'b0;
	cin_rd_data = {6'b100000,1'b1,3'b001,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};

	#(10*CYCLE);
	$finish; 

	//tb for RAM
	
	
end

always begin
	#(CYCLE/2) clk = ~ clk;
end

endmodule