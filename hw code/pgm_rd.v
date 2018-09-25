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

module pgm_rd #(
	parameter PLATFORM = "Xilinx"
)(
	input clk,
	input rst_n,

//receive data & phv from Previous module
	
    input [1023:0] in_rd_phv,
	input in_rd_phv_wr, 
	output out_rd_phv_alf,

	input [133:0] in_rd_data,
	input in_rd_data_wr,
	input in_rd_valid_wr,
	input in_rd_valid,
	output out_rd_alf,

//transport phv and data to pgm_rd
    output reg [1023:0] out_rd_phv,
	output reg out_rd_phv_wr,
	input in_rd_phv_alf,

	output reg [133:0] out_rd_data, 
	output reg out_rd_data_wr,
	output reg out_rd_valid,
	output reg out_rd_valid_wr,
	input in_rd_alf,

//signals from PGM_WR
	input pgm_bypass_flag,
	input pgm_sent_start_flag,
	input pgm_sent_finish_flag,

//opration with PGM_RAM
	output reg rd2ram_rd,
	output reg [6:0] rd2ram_addr,
	input [143:0] ram2rd_rdata,

//input cfg packet from DMA
    input [133:0] cin_rd_data,
	input cin_rd_data_wr,
	output cout_rd_ready,

//output configure pkt to next module
    output [133:0] cout_rd_data,
	output cout_rd_data_wr,
	input cin_rd_ready,

);

//***************************************************
//        Intermediate variable Declaration
//****************************************************
//all wire/reg/parameter variable
//should be declare below here

reg soft_rst;
reg [31:0] sent_rate_cnt;
reg [31:0] sent_rate_reg;
reg [31:0] lat_pkt_cnt; //num of pkt between Probes
reg [31:0] lat_pkt_reg; //num of pkt between Probes
reg [63:0] sent_bit_cnt;
reg [63:0] sent_pkt_cnt;
reg lat_flag;



assign out_rd_alf = in_rd_alf;
assign out_rd_phv_alf = in_rd_phv_alf;
assign cout_rd_ready = cin_rd_ready;
assign cout_rd_data = cin_rd_data;
assign cout_rd_data_wr = cin_rd_data_wr;

reg [5:0] pgm_rd_state;


//***************************************************
//             Pkt Rd & Transmit
//***************************************************

localparam IDLE_S = 6'd0,
			SENT_S = 6'd1,
			READ_S = 6'd2,
			WAIT_S = 6'd3,
			PROBE_S = 6'd4,
			FIN_S = 6'd5;

always @(posedge clk or negedge rst_n) begin
	if (rst_n == 1'b0 || soft_rst) begin
		// reset
		rd2ram_rd <= 1'b0;
		rd2ram_addr <= 7'b0;
		//outputs set to 0
		out_rd_data <= 134'b0;
		out_rd_data_wr <= 1'b0;
		out_rd_valid <= 1'b0;
		out_rd_valid_wr <= 1'b0;

		out_rd_phv <= 1024'b0;
		out_rd_phv_wr <= 1'b0;

		//intermidiate set to 0
		soft_rst <= 1'b0;
		sent_rate_cnt <= 32'b0;
		sent_rate_reg <= 32'b0;
		lat_pkt_cnt <= 32'b0; //num of pkt between Probes
		lat_pkt_reg <= 32'b0; //num of pkt between Probes
		sent_bit_cnt <= 64'b0;
		sent_pkt_cnt <= 64'b0;


		
	end
	else begin
		case(pgm_rd_state)
			IDLE_S: begin
				if(pgm_bypass_flag == 1'b1 && in_rd_data[133:132] == 2'b01 && in_rd_valid == 1'b1) begin
					out_rd_data <= in_rd_data;
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv <= in_rd_phv;
					out_rd_phv_wr <= 1'b1;

					pgm_rd_state <= SENT_S;
				end
				else if(pgm_sent_start_flag == 1'b1 && in_rd_data[133:132] == 2'b01 && in_rd_valid == 1'b1) begin
					out_rd_data <= ram2rd_rdata[133:0];
					rd2ram_addr <= 7'b0;
					rd2ram_rd <= 1'b1;
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv <= 1024'b0;

					pgm_rd_state <= READ_S;
				end

				else begin
					rd2ram_rd <= 1'b0;
					rd2ram_addr <= 7'b0;
					//outputs set to 0
					out_rd_data <= 134'b0;
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_valid_wr <= 1'b0;

					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b0;

					sent_rate_cnt <= 32'b0;
					//sent_rate_reg <= 32'b0;
					lat_pkt_cnt <= 32'b0; //num of pkt between Probes
					//lat_pkt_reg <= 32'b0; //num of pkt between Probes
					sent_bit_cnt <= 64'b0;
					sent_pkt_cnt <= 64'b0;



					pgm_rd_state <= IDLE_S;
				end
			end

			SENT_S: begin
				if(in_rd_data[133:132] == 2'b11 && in_rd_data_wr == 1'b1) begin
					out_rd_data <= in_rd_data;
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv <= in_rd_phv;
					out_rd_phv_wr <= 1'b1;
				end
				else if(in_rd_data[133:132] == 2'b10 && in_rd_data_rd == 1'b1) begin
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1028'b0;
					out_rd_phv_wr <= 1'b0;
				end

				else begin
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1028'b0;
					out_rd_phv_wr <= 1'b0;

					pgm_rd_state <= IDLE_S;
				end
			end

			READ_S: begin
				if(ram2rd_rdata[133:132] == 2'b11) begin
					//clear counters of rate
					//sent_rate_cnt <= 64'b0;

					out_rd_data <= ram2rd_rdata[133:0];
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv <= 1028'b0;
					out_rd_phv_wr <= 1'b0;

					rd2ram_rd <= 1'b1;
					rd2ram_addr <= rd2ram_addr + 1'b1;

					sent_bit_cnt <= sent_bit_cnt + 64'd16;
				end

				else if(ram2rd_rdata[133:132] == 2'b10) begin
					rd2ram_rd <= 1'b0;
					rd2ram_addr <= 7'b0;

					out_rd_data <= 134'b0;;
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1028'b0;
					out_rd_phv_wr <= 1'b0;

					sent_bit_cnt <= sent_bit_cnt + 64'd16;
					sent_pkt_cnt <= sent_pkt_cnt + 1'b1;

					if(pgm_sent_finish_flag == 1'b1) begin
						pgm_rd_state <= FIN_S;
					end

					else begin
						pgm_rd_state <= WAIT_S;
					end
				end

			end

			FIN_S: begin
				if(soft_rst == 1'b1) begin
					pgm_rd_state <= IDLE_S;
				end	
				else begin
					pgm_rd_state <= FIN_S;
				end
			end

			WAIT_S: begin
				if(sent_rate_cnt==sent_rate_reg && lat_flag == 1'b0) begin
					rd2ram_rd <= 1'b1;
					rd2ram_addr <= 7'b0;
					out_rd_data <= ram2rd_rdata[133:0];
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv_wr <= 1'b0;
					out_rd_phv <= 1028'b0;

					sent_rate_cnt <= 32'b0;
					pgm_rd_state <= READ_S;
				end

				else if(sent_rate_cnt==sent_rate_reg && lat_flag == 1'b1 && lat_pkt_cnt == lat_pkt_reg) begin
					rd2ram_rd <= 1'b1;
					rd2ram_addr <= 7'b0;
					out_rd_data <= ram2rd_rdata[133:0];
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv_wr <= 1'b0;
					out_rd_phv <= 1028'b0;

					sent_rate_cnt <= 32'b0;
					lat_pkt_cnt <= 32'b0;
					pgm_rd_state <= PROBE_S;
				end

				else begin
					lat_pkt_cnt <= lat_pkt_cnt + 1'b1;
					sent_rate_cnt <= sent_rate_cnt + 1'b1;
				end
			end

			PROBE_S: begin
				//TODO: add timestamp in this part
				//
			end
		
	end
end

endmodule