/////////////////////////////////////////////////////////////////
// NUDT.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: NUDT
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: pgm.v
//Version: 2.0
//Author : (Yang Xiangrui) FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)store pkt sending from UA
// 2)generating pkts
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/09/25
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 

module pgm #(
	parameter PLATFORM = "Xilinx",
		LMID = 8'd6, //self MID
		NMID = 8'd5 //next MID
)(
	input clk,
	input rst_n,

//waiting for pkt
	input in_pgm_data_wr,
	input [133:0] in_pgm_data, 
	input in_pgm_valid_wr,
	input in_pgm_valid,
	output out_pgm_alf,

//receive from gac

	input [1023:0] in_pgm_phv,
	input in_pgm_phv_wr,
	output out_pgm_phv_alf,

//transmit to next module (goe)
	
	output [133:0] out_pgm_data,
	output out_pgm_data_wr,
	output out_pgm_valid_wr,
	output out_pgm_valid,
	input in_pgm_alf,

	output [1023:0] out_pgm_phv,
	output out_pgm_phv_wr,
	input in_pgm_phv_alf,


/**************localbus to pgm**********

	input cfg2pgm_cs,
	output reg pgm2cfg_ack,
	input cfg2pgm_rw, //0: write, 1:read
	input [15:0] cfg2pgm_addr, //the addr is 16bit
	input [31:0] cfg2pgm_wdata,
	output reg [31:0] pgm2cfg_rdata,
***************************************/

//input configuree pkt from DMA
	input [133:0] cin_pgm_data,
	input cin_pgm_data_wr,
	output cout_pgm_ready,

//output configure pkt to next module
	output [133:0] cout_pgm_data,
	output cout_pgm_data_wr,
	input cin_pgm_ready

);

//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here 


//WR to RD

wire [1023:0] wr2rd_phv;
wire wr2rd_phv_wr;
wire wr2rd_phv_alf;

reg [133:0]wr2rd_data;
reg wr2rd_data_wr;
reg wr2rd_data_valid;
reg wr2rd_data_valid_wr;
wire in_wr_alf;

wire pgm_bypass_flag;
wire pgm_sent_start_flag;
wire pgm_sent_finish_flag;


wire [133:0] cout_wr_data;
wire cout_wr_data_wr;
wire cin_wr_ready;

//WR to RAM

wire wr2ram_wr_en;
wire [143:0]wr2ram_wdata;
wire [6:0]wr2ram_addr;

//RD to RAM
wire rd2ram_rd;
wire [143:0]rd2ram_rdata;
wire [6:0]rd2ram_raddr;



reg [2:0]pgm_state;

//assign out_pgm_phv_alf = 1'b0;
//assign out_pgm_alf = in_pgm_alf;




//***************************************************
//                  Module Instance
//***************************************************
//likely fifo/ram/async block.... 
//should be instantiated below here 

ram_144_128 pgm_ram
(
	.clka(clk),
	.dina(wr2ram_wdata),
	.wea(wr2ram_wr_en),
	.addra(wr2ram_addr),
	.douta(),
	.clkb(clk),
	.web(~rd2ram_rd),
	.addrd(rd2ram_raddr),
	.dinb(),
	.doutb(rd2ram_rdata)
);

pgm_wr #(
	.PLATFORM(PLATFORM),
	.LMID(61),
	.NMID(62)
	)pgm_wr(
	.in_wr_phv(in_pgm_phv),
	.in_wr_phv_wr(in_pgm_phv_wr), 
	.out_wr_phv_alf(out_pgm_phv_alf),
	.in_wr_data(in_pgm_data),
	.in_wr_data_wr(in_pgm_data_wr),
	.in_wr_valid_wr(in_pgm_valid_wr),
	.in_wr_valid(in_pgm_valid),
	.out_wr_alf(out_pgm_alf),

//transport phv and data to pgm_rd
    .out_wr_phv(out_pgm_phv),
	.out_wr_phv_wr(out_pgm_phv_wr),
	.in_wr_phv_alf(out_pgm_phv_alf),

	.out_wr_data(out_pgm_data), 
	.out_wr_data_wr(out_pgm_data_wr),
	.out_wr_valid(out_pgm_valid),
	.out_wr_valid_wr(out_pgm_valid_wr),
	.in_wr_alf(in_wr_alf),

//output to PGM_RAM
	.wr2ram_wr_en(wr2ram_wr_en),
	.wr2ram_wdata(wr2ram_wdata),
	.wr2ram_addr(wr2ram_addr),


//signals to PRM_RD
	.pgm_bypass_flag(pgm_bypass_flag),
	.pgm_sent_start_flag(pgm_sent_start_flag),
	.pgm_sent_finish_flag(pgm_sent_finish_flag),

//input cfg packet from DMA
    .cin_wr_data(cin_pgm_data),
	.cin_wr_data_wr(cin_pgm_data_wr),
	.cout_wr_ready(cout_pgm_ready),

//output configure pkt to next module
    .cout_wr_data(cout_pgm_data),
	.cout_wr_data_wr(cout_pgm_data_wr),
	.cin_wr_ready(cin_pgm_ready)
);

pgm_rd #(
	.PLATFORM(PLATFORM),
	.LMID(62),
	.DMID(5)
	)pgm_rd(
	.clk(clk),
	.rst_n(rst_n),

//receive data & phv from Previous module
	
    .in_rd_phv(wr2rd_phv),
	.in_rd_phv_wr(wr2rd_phv_wr), 
	.out_rd_phv_alf(in_wr_alf),

	.in_rd_data(wr2rd_data),
	.in_rd_data_wr(wr2rd_data_wr),
	.in_rd_valid_wr(wr2rd_data_valid_wr),
	.in_rd_valid(wr2rd_data_valid),
	.out_rd_alf(in_wr_alf),

//transport phv and data to pgm_rd
    .out_rd_phv(out_pgm_phv),
	.out_rd_phv_wr(out_pgm_valid_wr),
	.in_rd_phv_alf(in_pgm_phv_alf),

	.out_rd_data(out_pgm_data), 
	.out_rd_data_wr(out_rd_data_wr),
	.out_rd_valid(out_pgm_valid),
	.out_rd_valid_wr(out_rd_valid_wr),
	.in_rd_alf(in_pgm_alf),

//signals from PGM_WR
	.pgm_bypass_flag(pgm_bypass_flag),
	.pgm_sent_start_flag(pgm_sent_start_flag),
	.pgm_sent_finish_flag(pgm_sent_finish_flag),

//opration with PGM_RAM
	.rd2ram_rd(rd2ram_rd),
	.rd2ram_addr(rd2ram_raddr),
	.ram2rd_rdata(ram2rd_rdata),

//input cfg packet from DMA
    .cin_rd_data(cout_wr_data),
	.cin_rd_data_wr(cout_rd_data_wr),
	.cout_rd_ready(cin_wr_ready),

//output configure pkt to next module
    .cout_rd_data(cout_pgm_data),
	.cout_rd_data_wr(cout_rd_data_wr),
	.cin_rd_ready(cin_pgm_ready)
);

endmodule 
