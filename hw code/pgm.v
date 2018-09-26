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
	input rst_n;

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

assign out_pgm_phv_alf = 1'b0;
assign out_pgm_alf = in_pgm_alf;




//***************************************************
//                  Module Instance
//***************************************************
//likely fifo/ram/async block.... 
//should be instantiated below here 

ram_144_128 pmg_ram
(
	.clka(clk),
	.dina(),
	.wea(),
	.addra(),
	.douta(),
	.clkb(),
	.web(),
	.addrd(),
	.dinb(),
	.doutb()
);

pgm_wr #(
	.PLATFORM(PLATFORM),
	.LMID(61),
	.NMID(62)
	)pgm_wr(
	.in_wr_phv(in_wr_phv),
	.in_wr_phv_wr(in_wr_phv_wr), 
	.out_wr_phv_alf(out_wr_phv_alf),
	.in_wr_data(in_wr_data),
	.in_wr_data_wr(in_wr_data_wr),
	.in_wr_valid_wr(in_wr_valid_wr),
	.in_wr_valid(in_wr_valid),
	.out_wr_alf(out_wr_alf),

//transport phv and data to pgm_rd
    .out_wr_phv,
	.out_wr_phv_wr,
	.in_wr_phv_alf,

	.out_wr_data, 
	.out_wr_data_wr,
	.out_wr_valid,
	.out_wr_valid_wr,
	.in_wr_alf,

//output to PGM_RAM
	.wr2ram_wr_en,
	.wr2ram_wdata,
	.wr2ram_addr


//signals to PRM_RD
	.pgm_bypass_flag,
	.pgm_sent_start_flag,
	.pgm_sent_finish_flag,

//input cfg packet from DMA
    .cin_wr_data,
	.cin_wr_data_wr,
	.cout_wr_ready,

//output configure pkt to next module
    .cout_wr_data,
	.cout_wr_data_wr,
	.cin_wr_ready,
	);

pgm_rd #()




endmodule 
