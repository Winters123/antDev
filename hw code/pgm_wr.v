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

module pgm_wr #(
	parameter PLATFORM = "Xilinx",
	LMID = 8'd62, //set MID
	DMID = 8'd6  //next MID
)(
	input clk,
	input rst_n,

//receive data & phv from Previous module
	
    input [1023:0] in_wr_phv,
	input in_wr_phv_wr, 
	output out_wr_phv_alf,

	input [133:0] in_wr_data,
	input in_wr_data_wr,
	input in_wr_valid_wr,
	input in_wr_valid,
	output out_wr_alf,

//transport phv and data to pgm_rd
    output reg [1023:0] out_wr_phv,
	output reg out_wr_phv_wr,
	input in_wr_phv_alf,

	output reg [133:0] out_wr_data, 
	output reg out_wr_data_wr,
	output reg out_wr_valid,
	output reg out_wr_valid_wr,
	input in_wr_alf,

//output to PGM_RAM
	output reg wr2ram_wr_en,
	output reg [143:0] wr2ram_wdata,
	output reg [6:0] wr2ram_addr,


//signals to PRM_RD
	output reg pgm_bypass_flag,
	output reg pgm_sent_start_flag,
	output reg pgm_sent_finish_flag,

//input cfg packet from DMA
    input [133:0] cin_wr_data,
	input cin_wr_data_wr,
	output cout_wr_ready,

//output configure pkt to next module
    output reg [133:0] cout_wr_data,
	output reg cout_wr_data_wr,
	input cin_wr_ready

);

//***************************************************
//        Intermediate variable Declaration
//****************************************************
//all wire/reg/parameter variable
//should be declare below here

//user defined counters and regs
reg [63:0] sent_time_cnt;
reg [63:0] sent_time_reg;
reg soft_rst;



assign out_wr_phv_alf = in_wr_phv_alf;
assign out_wr_alf = in_wr_alf;
assign cout_wr_ready = cin_wr_ready;
//assign cout_wr_data = cin_wr_data;
//assign cout_wr_data_wr = cin_wr_data_wr;

reg [4:0] pgm_wr_state;

//***************************************************
//             Pkt Store & Transmit
//***************************************************

localparam  IDLE_S = 4'd0,
			WAIT_S = 4'd1,
			STORE_S = 4'd2,
			SENT_S = 4'd4,
			DISCARD_S = 4'd8;

always @(posedge clk or negedge rst_n) begin

	if(rst_n == 1'b0 || soft_rst == 1'b1) begin

		wr2ram_wr_en <= 1'b0;
		wr2ram_wdata <= 144'b0;
		wr2ram_addr <= 7'b0;

		//outputs set to 0
		out_wr_data <= 134'b0;
		out_wr_data_wr <= 1'b0;
		out_wr_valid <= 1'b0;
		out_wr_valid_wr <= 1'b0;

		out_wr_phv <= 1024'b0;
		out_wr_phv_wr <= 1'b0;

		//intermediate set to 0
		sent_time_cnt <= 64'b0;
		sent_time_reg <= 64'b0;
		soft_rst <= 1'b0;

		pgm_bypass_flag <= 1'b0;

		pgm_sent_start_flag <= 1'b0;
		pgm_sent_finish_flag <= 1'b0;

		pgm_wr_state <= IDLE_S;


		/*****used for tb, shall be delete later*****/


		sent_time_reg <= 64'b0;


		/*****used for tb, shall be delete later*****/
		
	end
	else begin
		case(pgm_wr_state)
			IDLE_S: begin
				
				//start bypassing
				if(in_wr_data_wr == 1'b1 && in_wr_data[133:132]==2'b01 && in_wr_data[111:109]!=3'b111) begin
					out_wr_data <= in_wr_data;
					out_wr_data_wr <= 1'b1;
					out_wr_phv <= in_wr_phv;
					out_wr_phv_wr <= 1'b1;
					out_wr_valid <= in_wr_valid;

					pgm_bypass_flag <= 1'b1;
					pgm_wr_state <= SENT_S;
				end

				//PGM start to store packet.
				else if(in_wr_data_wr == 1'b1 && in_wr_data[133:132]==2'b01 && in_wr_data[111:109]==3'b111) begin
					wr2ram_wr_en <= 1'b1;
					wr2ram_addr <= 7'b0;
					wr2ram_wdata <= {10'b0,in_wr_data};

					//pgm_sent_start_flag <= 1'b1;
					pgm_wr_state <= STORE_S;
				end
				else begin
					wr2ram_wr_en <= 1'b0;
					wr2ram_wdata <= 144'b0;
					wr2ram_addr <= 7'b0;

					//outputs set to 0
					out_wr_data <= 134'b0;
					out_wr_data_wr <= 1'b0;
					out_wr_valid <= 1'b0;
					out_wr_valid_wr <= 1'b0;

					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b0;

					pgm_bypass_flag <= 1'b0;
					pgm_sent_start_flag <= 1'b0;
					//pgm_sent_finish_flag <= 1'b0;

					pgm_wr_state <= IDLE_S;
				end
			end

			SENT_S: begin
				if(in_wr_data_wr == 1'b1 && in_wr_data[133:132] == 2'b11) begin
					out_wr_data <= in_wr_data;
					out_wr_data_wr <= 1'b1;
					out_wr_phv <= in_wr_phv;
					out_wr_phv_wr <= 1'b1;
					out_wr_valid <= in_wr_valid;
					pgm_wr_state <= SENT_S;
				end

				else if(in_wr_data_wr == 1'b1 && in_wr_data[133:132] == 2'b10) begin
					out_wr_data <= in_wr_data;
					out_wr_data_wr <= 1'b1;
					out_wr_valid <= 1'b1;
					out_wr_valid_wr <= 1'b1;

					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b1;
					pgm_wr_state <= IDLE_S;
				end

				else begin
					out_wr_data <= 134'b0;
					out_wr_data_wr <= 1'b0;
					out_wr_valid <= 1'b0;
					out_wr_valid_wr <= 1'b0;

					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b0;
					pgm_wr_state <= DISCARD_S;
				end
			end

			STORE_S: begin
				if(in_wr_data[133:132] == 2'b11 && in_wr_data_wr == 1'b1) begin
					wr2ram_wr_en <= 1'b1;
					wr2ram_wdata <= {10'b0, in_wr_data};
					wr2ram_addr <= wr2ram_addr + 1'b1;
				end
				else if(in_wr_data[133:132] == 2'b10) begin
					wr2ram_wr_en <= 1'b1;
					wr2ram_addr <= wr2ram_addr + 1'b1;
					wr2ram_wdata <= {10'b0, in_wr_data};
					pgm_sent_start_flag <= 1'b1;
					pgm_wr_state <= WAIT_S;
				end
				else begin
					/*TODO: clear all the values in RAM*/
					wr2ram_wr_en <= 1'b0;
					pgm_wr_state <= DISCARD_S;
				end
			end

			WAIT_S: begin
				if(sent_time_cnt != sent_time_reg) begin
					wr2ram_addr <= 7'b0;
					wr2ram_wdata <= 144'b0;
					wr2ram_wr_en <= 1'b0;
					sent_time_cnt <= sent_time_cnt + 1'b1;
				end
				else begin
					wr2ram_wdata <= {10'b0, in_wr_data};
					pgm_sent_finish_flag <= 1'b1;
					pgm_wr_state <= IDLE_S;
				end
			end

			DISCARD_S: begin
				if(in_wr_data[133:132] != 2'b10 && in_wr_data_wr == 1'b1) begin
					wr2ram_wr_en <= 1'b0;

					//outputs set to 0
					out_wr_data <= 134'b0;
					out_wr_data_wr <= 1'b0;
					out_wr_valid <= 1'b0;
					out_wr_valid_wr <= 1'b0;

					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b0;
				end 

				else begin
					pgm_wr_state <= IDLE_S;
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
	if(cin_wr_data[133:132] == 2'b01 && cin_wr_data_wr == 1'b1 && cin_wr_ready == 1'b1) begin
		if (cin_wr_data[103:96]== 8'd61 && cin_wr_data[126:124] == 3'b010) begin
			//write signal from SW
			case(cin_wr_data[95:64])
				32'h00000000: begin
					soft_rst <= cin_wr_data[0];
				end
				32'h00000001: begin
					sent_time_cnt[31:0] <= cin_wr_data[31:0];
				end
				32'h00000002: begin
					sent_time_cnt[63:32] <= cin_wr_data[31:0];
				end
				32'h00010001: begin
					sent_time_reg[31:0] <= cin_wr_data[31:0];
				end
				32'h00010002: begin
					sent_time_reg[63:32] <= cin_wr_data[31:0];
				end
				32'h11111111: begin
					pgm_wr_state <= cin_wr_data[3:0];
				end
			endcase
			//match input to output
		end
		else if(cin_wr_data[103:96]== 8'd61 && cin_wr_data[126:124] == 3'b001) begin
			//read signal from SW
			
			case(cin_wr_data[95:64])
				32'h00000000: begin
					//cin_rd_data[0] <= soft_rst;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:1], soft_rst};
				end
				32'h00000001: begin
					//cin_rd_data[31:0] <= sent_rate_cnt;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:32], sent_time_cnt[31:0]};
				end
				32'h00000002: begin
					//cin_rd_data[31:0] <= sent_rate_cnt;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:32], sent_time_cnt[63:32]};
				end
				32'h00010001: begin
					//cin_rd_data[31:0] <= sent_rate_reg;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:32], sent_time_reg[31:0]};
				end
				32'h00010002: begin
					//cin_rd_data[31:0] <= sent_rate_reg;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:32], sent_time_reg[63:32]};
				end
				32'h11111111: begin
					cout_wr_data  {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:4], pgm_wr_state};
				end
				default: begin
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:32], 32'hffffffff};
				end
			endcase
			//cout_wr_data_wr <= cin_wr_data_wr;
		end
		else begin
			cout_wr_data <= cin_wr_data;
		end
		cout_wr_data_wr <= cin_wr_data_wr;
	end

	//2nd cycle of control packet
	//TODO: the 2nd cycle can be used in the future. 
	else if(cin_wr_data[133:132] == 2'b10 && cin_wr_data_wr == 1'b1 && cin_wr_ready == 1'b1) begin
		cout_wr_data_wr <= cin_wr_data_wr;
		cout_wr_data <= cin_wr_data;
	end

	else begin
		cout_wr_data_wr <= cin_wr_data_wr;
		cout_wr_data <= cin_wr_data;
	end


end


endmodule