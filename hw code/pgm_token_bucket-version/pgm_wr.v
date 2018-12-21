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
	LMID = 8'd61, //set MID
	DMID = 8'd62  //next MID
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
	input cin_wr_ready,

//output sent_time_reg to pgm_rd
	output [63:0] out_wr_sent_time_reg

);

//***************************************************
//        Intermediate variable Declaration
//****************************************************
//all wire/reg/parameter variable
//should be declare below here

//user defined counters and regs
reg [63:0] sent_time_cnt;
reg [63:0] sent_time_reg;
//reg soft_rst;

//used for recording 2nd part of control data
reg ctl_write_flag; //if its a read cin or a wirte cin that the destination is not it self, then we should send the second part of the packet; else, we should delete it.

//fifo control regs
wire data_full_flag;
wire data_almost_full_flag;
wire data_empty_flag;


//read data from fifo
wire [133:0] fifo_out_data;
reg fifo_out_data_rd;

wire fifo_out_data_wr;


assign out_wr_phv_alf = in_wr_phv_alf;
assign out_wr_alf = in_wr_alf;
assign cout_wr_ready = cin_wr_ready;
assign out_wr_sent_time_reg = sent_time_reg;


reg [4:0] pgm_wr_state;

//***************************************************
//             Pkt Store & Transmit
//***************************************************

localparam IDLE_S = 4'd0,
		   SENT_S = 4'd1,
		   STORE_S = 4'd2,
		   WAIT_S = 4'd3,
		   DISCARD_S = 4'd5;

always @(posedge clk or negedge rst_n) begin

	if(rst_n == 1'b0) begin
		out_wr_phv <= 1024'b0;
		out_wr_phv_wr <= 1'b0;

		out_wr_data_wr <= 1'b0;
		out_wr_data <= 134'b0;
		out_wr_valid <= 1'b0;
		out_wr_data <= 1'b1;


		wr2ram_wr_en <= 1'b0;
		wr2ram_wdata <= 144'b0;
		wr2ram_addr <= 7'b0;

		sent_time_cnt <= 64'b0;
		pgm_bypass_flag <= 1'b0;
		pgm_sent_start_flag <= 1'b0;
		pgm_sent_finish_flag <= 1'b0;

		pgm_wr_state <= IDLE_S;
	end

	else begin
		case(pgm_wr_state)
			IDLE_S: begin
				//start bypassing
				if(data_empty_flag == 1'b0) begin
					fifo_out_data_rd <= 1'b1;
					if(fifo_out_data[133:132] == 2'b01 && fifo_out_data[111:109]!=3'b111) begin
						//bypassing logic
						out_wr_data <= 134'b0;
						out_wr_data_wr <= 1'b0;
						out_wr_valid <= 1'b0;
						out_wr_valid_wr <= 1'b0;

						pgm_wr_state <= SENT_S;
					end

					else if(fifo_out_data[133:132] == 2'b01 && fifo_out_data[111:109]==3'b111) begin
						//starting of ANT
						wr2ram_wr_en <= 1'b0;
						wr2ram_addr <= 7'b0;
						wr2ram_wdata <= {10'b0, fifo_out_data};
						pgm_wr_state <= STORE_S;
					end

					else begin
						//discard the packet
						fifo_out_data_rd <= 1'b1;
						pgm_wr_state <= DISCARD_S;
					end
				end
				else begin
					fifo_out_data_rd <= 1'b0;

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


					//reset all the counters once test finished.
					sent_time_cnt <= 64'b0;
					
					pgm_bypass_flag <= 1'b0;
					pgm_sent_start_flag <= 1'b0;
					pgm_sent_finish_flag <= 1'b0;

					pgm_wr_state <= IDLE_S;
				end
			end


			SENT_S: begin

				if (out_wr_data[133:132] == 2'b10 && out_wr_data_wr==1'b1) begin
					out_wr_data_wr <= 1'b0;
					out_wr_data <= 134'b0;
					out_wr_valid <= 1'b1;
					out_wr_valid_wr <= 1'b1;
					pgm_wr_state <= IDLE_S;
				end

				else if (fifo_out_data_wr==1'b1 && fifo_out_data[133:132]==2'b01) begin
					out_wr_data <= fifo_out_data;
					out_wr_data_wr <= fifo_out_data_wr;
					fifo_out_data_rd <= 1'b1;
					out_wr_valid_wr <= 1'b0;
					out_wr_valid <= 1'b0;
					out_wr_phv_wr <= 1'b1;
					out_wr_phv <= 1024'b1;
					pgm_wr_state <= SENT_S;
				end

				else if(fifo_out_data_wr==1'b1 && fifo_out_data[133:132]==2'b11) begin
					out_wr_data <= fifo_out_data;
					out_wr_data_wr <= fifo_out_data_wr;
					fifo_out_data_rd <= 1'b1;
					out_wr_phv_wr <= 1'b0;
					out_wr_phv <= 1024'b0;
					pgm_wr_state <= SENT_S;
				end

				else if(fifo_out_data_wr==1'b1 && fifo_out_data[133:132]==2'b10) begin
					//set rd signal as 1'b0 after reading a pkt.
					fifo_out_data_rd <= 1'b0;
					
					out_wr_data <= fifo_out_data;
					out_wr_data_wr <= fifo_out_data_wr;

					//pgm_wr_state <= IDLE_S;

				end

				//when finish the trans, need to go back to idle state.
				
				else begin
					out_wr_data <= 134'b0;
					out_wr_data_wr <= 1'b0;
					out_wr_valid <= 1'b0;
					out_wr_valid_wr <= 1'b0;

					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b0;
					fifo_out_data_rd <= 1'b1;
					pgm_wr_state <= DISCARD_S;
				end
				
			end

			STORE_S: begin

				if(fifo_out_data_wr==1'b1 && fifo_out_data[133:132]==2'b01) begin
					wr2ram_wr_en <= 1'b1;
					wr2ram_wdata <= {10'b0, fifo_out_data};
					wr2ram_addr <= 7'b0;
				end

				else if(fifo_out_data_wr==1'b1 && fifo_out_data[133:132]!=2'b10) begin

					wr2ram_wr_en <= 1'b1;
					wr2ram_addr <= wr2ram_addr+7'b1;
					wr2ram_wdata <= {10'b0, fifo_out_data};

				end

				else if(fifo_out_data_wr==1'b1 && fifo_out_data[133:132]==2'b10) begin
					//set rd signal as 1'b0 after reading a pkt.
					fifo_out_data_rd <= 1'b0;

					wr2ram_wr_en <= 1'b1;
					wr2ram_wdata <= {10'b0, fifo_out_data};
					wr2ram_addr <= wr2ram_addr + 1'b1;
					pgm_sent_start_flag <= 1'b1;
					pgm_wr_state <= WAIT_S;
				end

				else begin
					wr2ram_wr_en <=1'b0;
					fifo_out_data_rd <= 1'b1;
					pgm_wr_state <= DISCARD_S;
				end
			end

			DISCARD_S: begin
				if(fifo_out_data[133:132] != 2'b10 && fifo_out_data_wr == 1'b1) begin
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
					fifo_out_data_rd <= 1'b0;
					pgm_wr_state <= IDLE_S;
				end
			end

			//this state is different from the former as it will response to packet arriving.
			WAIT_S: begin
				sent_time_cnt <= sent_time_cnt + 1'b1;
				wr2ram_addr <= 7'b0;
				wr2ram_wdata <= 144'b0;
				wr2ram_wr_en <= 1'b0;

				//it indicates there is a pkt needed to be transmitted.
				if(data_empty_flag == 1'b0) begin
					fifo_out_data_rd <= 1'b1; //start reading fifo
				end

				else begin
					fifo_out_data_rd <= 1'b0;
				end

				if(fifo_out_data_rd == 1'b1 && fifo_out_data[133:132] == 2'b01) begin
					out_wr_data <= fifo_out_data;
					out_wr_data_wr <= fifo_out_data_wr;
					out_wr_phv <= 1024'b1;
					out_wr_phv_wr <= 1'b1;
				end

				else if(fifo_out_data_rd == 1'b1 && fifo_out_data[133:132] == 2'b11) begin
					out_wr_data <= fifo_out_data;
					out_wr_data_wr <= fifo_out_data_wr;
					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b0;
				end

				else if(fifo_out_data_rd == 1'b1 && fifo_out_data[133:132] == 2'b10) begin
					out_wr_data <= fifo_out_data;
					out_wr_data_wr <= fifo_out_data_wr;
					
					fifo_out_data_rd <= 1'b0;



					if(sent_time_cnt >= sent_time_reg) begin
						pgm_sent_finish_flag <= 1'b1;
						pgm_wr_state <= IDLE_S;
					end
				end

				else if(fifo_out_data_rd == 1'b0) begin
					out_wr_data <= 134'b0;
					out_wr_data_wr <= 1'b0;
					out_wr_phv <= 1024'b0;
					out_wr_phv_wr <= 1'b0;
				end

				if(out_wr_data_wr==1'b1 && out_wr_data[133:132]==2'b10) begin
					out_wr_valid_wr <= 1'b1;
					out_wr_valid <= 1'b1;
				end

				else begin
					out_wr_valid <= 1'b0;
					out_wr_valid_wr <= 1'b0;
				end

				if(data_empty_flag == 1'b1 && sent_time_cnt >= sent_time_reg) begin
					pgm_sent_finish_flag <= 1'b1;
					pgm_wr_state <= IDLE_S;
				end


			end
		endcase

	end
end


//***************************************************
//                  Other IP Instance
//***************************************************
//likely fifo/ram/async block.... 
//should be instantiated below here

fifo_135_512 pgm_wr_data_fifo
(
	.clk(clk),
	.srst(!rst_n),
	.din({in_wr_data_wr,in_wr_data}),
	.wr_en(in_wr_data_wr),
	.rd_en(fifo_out_data_rd),
	.dout({fifo_out_data_wr,fifo_out_data}),
	.full(data_full_flag),
	.almost_full(),
	.empty(data_empty_flag),
	.data_count()
);




//***************************************************
//          Operation of User Defined Regs
//***************************************************

always @(posedge clk) begin
	//1st cycle of control packet 
	if(cin_wr_data[133:132] == 2'b01 && cin_wr_data_wr == 1'b1) begin
		if ((cin_wr_data[103:96]== 8'd61) && (cin_wr_data[126:124] == 3'b010)) begin
			//write signal from SW
			ctl_write_flag <= 1'b1;	

			case(cin_wr_data[95:64])
			
				32'h00010001: begin
					sent_time_reg[31:0] <= cin_wr_data[31:0];
				end
				32'h00010002: begin
					sent_time_reg[63:32] <= cin_wr_data[31:0];
				end
			
			endcase
			//match input to output
			cout_wr_data <= 134'b0;
			cout_wr_data_wr <= 1'b0;
		end
		else if(cin_wr_data[103:96]== 8'd61 && cin_wr_data[126:124] == 3'b001) begin
			//read signal from SW
			ctl_write_flag <= 1'b0;
			case(cin_wr_data[95:64])

				32'h00000001: begin
					//cin_rd_data[31:0] <= sent_rate_cnt;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:112], cin_wr_data[103:96], cin_wr_data[111:104], cin_wr_data[95:32],  sent_time_cnt[31:0]};
				end
				32'h00000002: begin
					//cin_rd_data[31:0] <= sent_rate_cnt;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:112], cin_wr_data[103:96], cin_wr_data[111:104], cin_wr_data[95:32], sent_time_cnt[63:32]};
				end
				32'h00010001: begin
					//cin_rd_data[31:0] <= sent_rate_reg;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:112], cin_wr_data[103:96], cin_wr_data[111:104], cin_wr_data[95:32],  sent_time_reg[31:0]};
				end
				32'h00010002: begin
					//cin_rd_data[31:0] <= sent_rate_reg;
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:112], cin_wr_data[103:96], cin_wr_data[111:104], cin_wr_data[95:32],  sent_time_reg[63:32]};
				end
				32'h11111111: begin
					cout_wr_data  <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:112], cin_wr_data[103:96], cin_wr_data[111:104], cin_wr_data[95:5],  pgm_wr_state};
				end
				default: begin
					cout_wr_data <= {cin_wr_data[133:128], 4'b1011, cin_wr_data[123:112], cin_wr_data[103:96], cin_wr_data[111:104], cin_wr_data[95:32],  32'hffffffff};
				end
			endcase
			cout_wr_data_wr <= cin_wr_data_wr;
		end
		else begin
			ctl_write_flag <= 1'b0;
			cout_wr_data <= cin_wr_data;
			cout_wr_data_wr <= cin_wr_data_wr;
		end
		//cout_wr_data_wr <= cin_wr_data_wr;
	end

	//2nd cycle of control packet
	//TODO: the 2nd cycle can be used in the future. 
	else if(cin_wr_data[133:132] == 2'b10 && cin_wr_data_wr == 1'b1) begin
		if (ctl_write_flag == 1'b1) begin
			cout_wr_data_wr <= 1'b0;
			cout_wr_data <= 134'b0;
			ctl_write_flag <= 1'b0;
		end

		else begin
			cout_wr_data_wr <= cin_wr_data_wr;
			cout_wr_data <= cin_wr_data;
		end

	end

	else begin
		cout_wr_data_wr <= 1'b0;
		cout_wr_data <= 134'b0;
	end


end


endmodule