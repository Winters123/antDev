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
	output out_pgm_data_alf,

//receive from gac

	input [1023:0] in_pgm_phv,
	input in_pgm_phv_wr,
	output out_pgm_phv_alf,

//transmit to next module (goe)
	
	output reg [133:0] out_pgm_data,
	output reg out_pgm_data_wr,
	output reg out_pgm_valid_wr,
	output reg out_pgm_valid,
	input in_pgm_alf,

	output reg [1023:0] out_pgm_phv,
	output reg out_pgm_phv_wr,
	input in_pgm_phv_alf,

//localbus to pgm

	input cfg2pgm_cs,
	output reg pgm2cfg_ack,
	input cfg2pgm_rw, //0: write, 1:read
	input [15:0] cfg2pgm_addr, //the addr is 16bit
	input [31:0] cfg2pgm_wdata,
	output reg [31:0] pgm2cfg_rdata,

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
wire [1023:0] wr2_rd_phv;
wire wr2_rd_phv_wr;
wire wr2_rd_phv_alf;

reg [133:0]wr2rd_data;
reg wr2rd_data_wr;
reg wr2rd_data_valid;
reg wr2rd_data_valid_wr;

wire pgm_bypass_flag;
wire pgm_sent_start_flag;

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
assign out_pgm_data_alf = 

//***************************************************
//                  PGM Bypass
//***************************************************
localparam IDLE_S = 3'd0,
		   BYPASS = 3'd1,
		   PGM_S = 3'd2;

always @(posedge clk or negedge rst_n) begin
	if(rst_n == 1'b0) begin
		
	end
end






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

pgm_wr #()

pgm_rd #()
