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
	parameter PLATFORM = "Xilinx",
	LMID = 8'd61, //self MID
	NMID = 8'd62  //next MID
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
    output reg [133:0] cout_rd_data,
	output reg cout_rd_data_wr,
	input cin_rd_ready

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

reg [5:0] pgm_rd_state;





//**************************************************
//             Delay check & addition
//**************************************************

//reg [133:0] out_rd_data_dly[1:0];
//reg out_rd_data_wr_dly[1:0];
//reg out_rd_valid_dly[1:0];
//reg out_rd_valid_wr_dly[1:0];
//reg [1023:0] out_rd_phv_dly[1:0];
//reg out_rd_phy_wr_dly[1:0];
//
//always @(posedge clk) begin
//	out_rd_data <= out_rd_data_dly[0];
//	out_rd_data_dly[0] <= out_rd_data_dly[1];
//
//	out_rd_data_wr <= out_rd_data_wr_dly[0];
//	out_rd_data_wr_dly[0] <= out_rd_data_wr_dly[1];
//	
//	out_rd_valid <= out_rd_valid_dly[0];
//	out_rd_valid_dly[0] <= out_rd_valid_dly[1];
//
//	out_rd_valid_wr <= out_rd_valid_wr_dly[0];
//	out_rd_valid_wr_dly[0] <= out_rd_valid_wr_dly[1];
//
//	out_rd_phv <= out_rd_phv_dly[0];
//	out_rd_phv_dly[0] <= out_rd_phv_dly[1];
//
//	out_rd_phv_wr <= out_rd_phv_wr_dly[0];
//	out_rd_phv_wr_dly[0] <= out_rd_phv_wr_dly[1];
//end

//***************************************************
//             Pkt Rd & Transmit
//***************************************************

localparam  IDLE_S = 6'd0,
			SENT_S = 6'd1,
			HAUNT1_S = 6'd3,
			HAUNT2_S = 6'd5,
			READ_S = 6'd2,
			WAIT_S = 6'd4,
			PROBE_S = 6'd8,
			FIN_S = 6'd16;

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
		sent_rate_reg <= 32'hffffffff;
		lat_pkt_cnt <= 32'b0; //num of pkt between Probes
		lat_pkt_reg <= 32'hffffffff; //num of pkt between Probes
		sent_bit_cnt <= 64'b0;
		sent_pkt_cnt <= 64'b0;

		lat_flag <= 1'b0;  //TODO add latency flag here


		pgm_rd_state <= IDLE_S;
		
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
					out_rd_valid_wr <= 1'b0;

					pgm_rd_state <= SENT_S;
				end

				else if(pgm_sent_start_flag == 1'b1) begin
					out_rd_data <= 134'b0;
					rd2ram_addr <= 7'b0;
					rd2ram_rd <= 1'b1;

					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b0;
					//need jump to HAUNT1_S to wait for RAM output
					pgm_rd_state <= HAUNT1_S;
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
				else if(in_rd_data[133:132] == 2'b10 && in_rd_data_wr == 1'b1) begin
					out_rd_data <= in_rd_data;
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_valid_wr <= 1'b1;
					out_rd_phv <= in_rd_phv;
					out_rd_phv_wr <= 1'b1;

					pgm_rd_state <= IDLE_S;
				end

				else begin
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b0;

					pgm_rd_state <= IDLE_S;
				end
			end

			HAUNT1_S: begin
				rd2ram_rd <= 1'b1;
				rd2ram_addr <= 7'b1;
				pgm_rd_state <= HAUNT2_S;	
			end

			HAUNT2_S: begin
				//out_rd_data <= ram2rd_rdata[133:0];
				//rd2ram_addr <= 7'd2;
				//rd2ram_rd <= 1'b1;
				//out_rd_data_wr <= 1'b1;
				//out_rd_valid <= 1'b1;
				//out_rd_phv <= 1024'b0;
				//out_rd_phv_wr <= 1'b1;
				if(lat_flag == 1'b1) begin
					rd2ram_addr <= 7'd2;
					pgm_rd_state <= PROBE_S;
				end
				else begin
					rd2ram_addr <= 7'd2;
					pgm_rd_state <= READ_S;
				end
				

				//sent_bit_cnt <= sent_bit_cnt + 64'd16;
			end

			READ_S: begin
				if(ram2rd_rdata[133:132] == 2'b11) begin
					//clear counters of rate
					//sent_rate_cnt <= 64'b0;

					out_rd_data <= ram2rd_rdata[133:0];
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b1;
					out_rd_valid_wr <= 1'b0;

					rd2ram_rd <= 1'b1;
					rd2ram_addr <= rd2ram_addr + 1'b1;

					sent_bit_cnt <= sent_bit_cnt + 64'd16;

					pgm_rd_state <= READ_S;
				end

				else if(ram2rd_rdata[133:132] == 2'b10) begin
					rd2ram_rd <= 1'b0;
					rd2ram_addr <= 7'b0;

					out_rd_data <= ram2rd_rdata[133:0];
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b0;
					out_rd_valid_wr <= 1'b1;

					sent_bit_cnt <= sent_bit_cnt + ram2rd_rdata[131:128];
					sent_pkt_cnt <= sent_pkt_cnt + 1'b1;

					if(pgm_sent_finish_flag == 1'b1) begin
						pgm_rd_state <= FIN_S;
					end

					else begin
						pgm_rd_state <= WAIT_S;
					end
				end

				else if(ram2rd_rdata[133:132] == 2'b01) begin
					rd2ram_rd <= 1'b1;
					rd2ram_addr <= rd2ram_addr + 7'b1;

					out_rd_data <= ram2rd_rdata[133:0];
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv <= 1024'b1;
					out_rd_phv_wr <= 1'b1;
					out_rd_valid_wr <= 1'b0;

					pgm_rd_state <= READ_S;

					sent_bit_cnt <= sent_bit_cnt + 64'd16;

				end

			end

			FIN_S: begin
				if(soft_rst == 1'b1) begin
					pgm_rd_state <= IDLE_S;
				end	
				else begin
					out_rd_data <= 134'b0;
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b0;
					out_rd_valid_wr <= 1'b0;

					pgm_rd_state <= FIN_S;
				end
			end

			WAIT_S: begin
				
				//if(sent_rate_cnt == sent_rate_reg && lat_flag == 1'b1 && lat_pkt_cnt == lat_pkt_reg) begin
				//	rd2ram_rd <= 1'b1;
				//	rd2ram_addr <= 7'b0000000;
				//	out_rd_data <= ram2rd_rdata[133:0];
				//	out_rd_data_wr <= 1'b1;
				//	out_rd_valid <= 1'b1;
				//	out_rd_phv_wr <= 1'b1;
				//	out_rd_phv <= 1024'b1;

				//	sent_rate_cnt <= 32'b0;
				//	lat_pkt_cnt <= 32'b0;

				//	//need to add another states for 2cycles delay of PROBE send.
				//	pgm_rd_state <= PROBE_S;
				//end

				if(sent_rate_cnt==sent_rate_reg) begin
					rd2ram_rd <= 1'b1;
					rd2ram_addr <= 7'b0000000;
					out_rd_data <= 134'b0;
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv_wr <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_valid_wr <= 1'b0;

					sent_rate_cnt <= 32'b0;
					pgm_rd_state <= HAUNT1_S;
				end

				

				else begin
					out_rd_data <= 134'b0;
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_phv_wr <= 1'b0;
					out_rd_valid_wr <= 1'b0;

					lat_pkt_cnt <= lat_pkt_cnt + 1'b1;
					sent_rate_cnt <= sent_rate_cnt + 1'b1;
					pgm_rd_state <= WAIT_S;
				end
			end


			//NEED TO BE RE-WRITE FOR 2 CYCLES DELAY
			PROBE_S: begin
				//TODO: add timestamp in this part
				//but I still think that the timestamp should be added in UDO
				if(out_rd_data[133:132] != 2'b10) begin
					out_rd_data <= ram2rd_rdata[133:0];
					rd2ram_rd <= 1'b1;
					rd2ram_addr <= rd2ram_addr + 7'b1;
					out_rd_data_wr <= 1'b1;
					out_rd_valid <= 1'b1;
					out_rd_phv_wr <= 1'b1;
					out_rd_phv <= 1024'b0;
					out_rd_valid_wr <= 1'b0;
					
					pgm_rd_state <= PROBE_S;
				end

				else begin
					lat_pkt_cnt <= 32'b0;
					sent_rate_cnt <= 32'b0;

					rd2ram_rd <= 1'b0;
					rd2ram_addr <= 7'b0;

					out_rd_data <= 134'b0;
					out_rd_data_wr <= 1'b0;
					out_rd_valid <= 1'b0;
					out_rd_phv_wr <= 1'b0;
					out_rd_phv <= 1024'b0;
					out_rd_valid_wr <= 1'b1;

					if(pgm_sent_finish_flag == 1'b1) begin
						pgm_rd_state <= FIN_S;
					end

					else begin
						pgm_rd_state <= WAIT_S;
					end

				end
			end
		endcase
	end
end


//***************************************************
//          Operation of User Defined Regs
//***************************************************


always @(posedge clk) begin
	//1st cycle of control packet 
	if(cin_rd_data[133:132] == 2'b01 && cin_rd_data_wr == 1'b1 && cin_rd_ready == 1'b1) begin
		if (cin_rd_data[103:96]== 8'd62 && cin_rd_data[126:124] == 3'b010) begin
			//write signal from SW
			case(cin_rd_data[95:64])
				32'h00000000: begin
					soft_rst <= cin_rd_data[0];
				end
				32'h00000001: begin
					 sent_rate_cnt <= cin_rd_data[31:0];
				end
				32'h00010001: begin
					 sent_rate_reg <= cin_rd_data[31:0];
				end
				32'h00000002: begin
					 lat_pkt_cnt <= cin_rd_data[31:0];
				end
				32'h00010002: begin
					 lat_pkt_reg <= cin_rd_data[31:0];
				end
				32'h00000003: begin
					 sent_bit_cnt[31:0] <= cin_rd_data[31:0];
				end
				32'h00000004: begin
					 sent_bit_cnt[63:32] <= cin_rd_data[31:0];
				end
				32'h00000005: begin
					 sent_pkt_cnt[31:0] <= cin_rd_data[31:0];
				end
				32'h00000006: begin
					 sent_pkt_cnt[63:32] <= cin_rd_data[31:0];
				end
				32'h00010010: begin
					lat_flag <= cin_rd_data[0];
				end

			endcase
			cout_rd_data <= cin_rd_data;
			cout_rd_data_wr <= cin_rd_data_wr;
			
		end

		else if(cin_rd_data[103:96]== 8'd62 && cin_rd_data[126:124] == 3'b001) begin
			//read signal from SW
			
			case(cin_rd_data[95:64])
				32'h00000000: begin
					//cin_rd_data[0] <= soft_rst;
					cout_rd_data <= {cin_rd_data[133:128], 1'b1, 3'b011, cin_rd_data[123:1], soft_rst};
				end
				32'h00000001: begin
					//cin_rd_data[31:0] <= sent_rate_cnt;
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], sent_rate_cnt};
				end
				32'h00010001: begin
					//cin_rd_data[31:0] <= sent_rate_reg;
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], sent_rate_reg};
				end
				32'h00000002: begin
					//cin_rd_data[31:0] <= lat_pkt_cnt;
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], lat_pkt_cnt};
				end
				32'h00010002: begin
					//cin_rd_data[31:0] <= lat_pkt_reg;
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], lat_pkt_reg};
				end
				32'h00000003: begin
					//cin_rd_data[31:0] <= sent_bit_cnt[31:0];
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], sent_bit_cnt[31:0]};
				end
				32'h00000004: begin
					//cin_rd_data[31:0] <= sent_bit_cnt[63:32];
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], sent_bit_cnt[63:32]};
				end
				32'h00000005: begin
					//cin_rd_data[31:0] <= sent_pkt_cnt[31:0];
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], sent_pkt_cnt[31:0]};
				end
				32'h00000006: begin
					//cin_rd_data[31:0] <= sent_pkt_cnt[63:32];
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], sent_pkt_cnt[63:32]};
				end
				32'h00010010: begin
					cout_rd_data <= {cin_rd_data[133:128], 1'b1, 3'b011, cin_rd_data[123:1], lat_flag};
				end
				default: begin
					cout_rd_data <= {cin_rd_data[133:128], 4'b1011, cin_rd_data[123:32], 32'hffffffff};
				end

			endcase
			cout_rd_data_wr <= cin_rd_data_wr;
		end

		else begin
			cout_rd_data <= cin_rd_data;
			cout_rd_data_wr <= cin_rd_data_wr;
		end
	end
	//2nd cycle of control packet
	else if(cin_rd_data[133:132] == 2'b10 && cin_rd_data_wr == 1'b1 && cin_rd_ready == 1'b1) begin
		cout_rd_data_wr <= cin_rd_data_wr;
		cout_rd_data <= cin_rd_data;
	end

	else begin
		cout_rd_data_wr <= cin_rd_data_wr;
		cout_rd_data <= cin_rd_data;
	end


end



endmodule