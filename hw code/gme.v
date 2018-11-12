/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: gme.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)receive key from previous module 
// 2)transmit key to lookup
// 3)transmit index to next module
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/08/24
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 
module gme #(
    parameter    PLATFORM = "Xilinx",
         LMID = 8'd3,
		 NMID = 8'd7
)(   
    input clk,
    input rst_n,
			 
//lookup gme read index
    input in_gme_index_wr,
    input [15:0] in_gme_index,
	output wire out_gme_index_alf,		 
//receive from Previous module
    input [511:0] in_gme_key,
	input  in_gme_key_wr,
	output out_gme_key_alf,

    input [255:0] in_gme_md,
	input in_gme_md_wr,
	output wire out_gme_md_alf,
	
    input [1023:0] in_gme_phv,
	input in_gme_phv_wr,   
	output wire out_gme_phv_alf,
	
//transport to next module
    output reg [255:0] out_gme_md,
	output reg  out_gme_md_wr,
	input in_gme_md_alf,

    output reg [1023:0] out_gme_phv,
	output reg  out_gme_phv_wr,   
	input in_gme_phv_alf,
	 
//transport key to lookup
    output reg out_gme_key_wr,
    output reg [511:0] out_gme_key,
    input in_gme_key_alf,
//localbus to gme
    input cfg2gme_cs_n, //low active
	output reg gme2cfg_ack_n, //low active
	input cfg2gme_rw, //0 :write, 1 :read
	input [31:0] cfg2gme_addr,
	input [31:0] cfg2gme_wdata,
	output reg [31:0] gme2cfg_rdata,
	
//input configure pkt from DMA
    input [133:0] cin_gme_data,
	input cin_gme_data_wr,
	output cout_gme_ready,
	
//output configure pkt to next module
    output [133:0] cout_gme_data,
	output cout_gme_data_wr,
	input cin_gme_ready
         
);

//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here 
reg [31:0] in_gme_index_count;
reg [31:0] gme_status;
reg [31:0] in_gme_key_count;
reg [31:0] in_gme_md_count;
reg [31:0] out_gme_md_count;    //gme output md count
reg [31:0] out_gme_phv_count;   //gme output phv count
reg [31:0] out_gme_key_count;   //gme output key count
reg [31:0] in_gme_phv_count;

reg MD_fifo_rd;
wire [255:0] MD_fifo_rdata; 
wire MD_fifo_empty;
wire [7:0] MD_fifo_usedw;

reg PHV_fifo_rd;
wire [1023:0] PHV_fifo_rdata;
wire PHV_fifo_empty;
wire [7:0] PHV_fifo_usedw;

reg index_fifo_rd;
wire [15:0]index_fifo_rdata;
wire [10:0] um2match_usedw;
wire index_fifo_empty;

assign out_gme_key_alf=in_gme_key_alf;
assign out_gme_md_alf= in_gme_md_alf  ||(MD_fifo_usedw>8'd250);
assign out_gme_phv_alf = in_gme_phv_alf ||(PHV_fifo_usedw>8'd250);
assign out_gme_index_alf = um2match_usedw>11'd1020;
assign cout_gme_data_wr = cin_gme_data_wr;
assign cout_gme_data = cin_gme_data;
assign cout_gme_ready = cin_gme_ready;


//*******************************************
//         Transport key to lookup
//*******************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        out_gme_key_wr <= 1'b0;
        out_gme_key <= 512'b0;
    end
    else begin
        if((in_gme_key_wr == 1'b1) &&(in_gme_md[87:80] == LMID))begin
            out_gme_key_wr <= in_gme_key_wr;
            out_gme_key <= in_gme_key;
        end
        else begin
            out_gme_key_wr <= 1'b0;
            out_gme_key <= out_gme_key;
        end
    end
end

//***************************************
//            Transmit MD & PHV
//***************************************
reg [1:0]md_phv_state;
localparam md_phv_idle=2'd0,
	       md_phv_data=2'd1;
reg md_flag;
reg  [255:0]out_gme_md_reg;
always @(posedge clk or negedge rst_n) begin 
    if(rst_n == 1'b0) begin 
	    MD_fifo_rd<=1'b0;
        out_gme_md <= 256'b0;
        out_gme_md_wr <= 1'b0;
		out_gme_md_reg<=256'b0;
		PHV_fifo_rd <= 1'b0;
        out_gme_phv <= 1024'b0;	
		out_gme_phv_wr<=1'b0;
		md_phv_state <= md_phv_idle;
		index_fifo_rd<=1'b0;
		md_flag<=1'b0;
    end 

    else begin
    	case(md_phv_state)
    		md_phv_idle: begin
				if((MD_fifo_empty == 1'b0) && (PHV_fifo_empty == 1'b0)) begin

					out_gme_phv <= 1024'b0;	
					out_gme_phv_wr<=1'b0;
		        	out_gme_md <= 256'b0;
		        	out_gme_md_wr <= 1'b0;

					if(index_fifo_empty == 1'b0)begin
						MD_fifo_rd <= 1'b1;
						index_fifo_rd <= 1'b1;
						PHV_fifo_rd <= 1'b1;
						md_phv_state <= md_phv_data;
					end

					else begin
						md_phv_state <= md_phv_idle;
					end
				end
				else begin
					MD_fifo_rd<=1'b0;
		        	out_gme_md <= 256'b0;
		        	out_gme_md_wr <= 1'b0;
					md_flag<=1'b0;
					PHV_fifo_rd <= 1'b0;
		        	out_gme_phv <= 1024'b0;	
					out_gme_phv_wr<=1'b0;
					out_gme_md_reg<=256'b0;
					index_fifo_rd <= 1'b0;
					md_phv_state <= md_phv_idle;
				end
			end

			md_phv_data: begin
				MD_fifo_rd<=1'b0;
				PHV_fifo_rd <= 1'b0;
				index_fifo_rd<=1'b0;
				
				out_gme_phv <= PHV_fifo_rdata;
				out_gme_phv_wr <= 1'b1;
				out_gme_md <= {MD_fifo_rdata[255:88],NMID,MD_fifo_rdata[79:64],index_fifo_rdata[12:0],1'b1,MD_fifo_rdata[49:0]};
				out_gme_md_wr <= 1'b1;

				md_phv_state <= md_phv_idle;

			end

			default: md_phv_state <= md_phv_idle;

			endcase
	end
			    							      
end 

//***************************************************
//                  Other IP Instance
//***************************************************
//likely fifo/ram/async block.... 
//should be instantiated below here


fifo_16_1024  fifo_16_1024_inst(
	.srst(!rst_n),
	.clk(clk),
	.din(in_gme_index),
	.rd_en(index_fifo_rd),
	.wr_en(in_gme_index_wr),
	.dout(index_fifo_rdata),
	.data_count(um2match_usedw),
	.empty(index_fifo_empty),
	.full()

	);
fifo_256_256  MD_fifo(
	.srst(!rst_n),
	.clk(clk),
	.din(in_gme_md),
	.rd_en(MD_fifo_rd),
	.wr_en(in_gme_md_wr),
	.dout(MD_fifo_rdata),
	.data_count(MD_fifo_usedw),
	.empty(MD_fifo_empty),
	.full()

	);
fifo_1024_256  PHV_fifo(
    .srst(!rst_n),
    .clk(clk),
    .din(in_gme_phv),
    .rd_en(PHV_fifo_rd),
    .wr_en(in_gme_phv_wr),
    .dout(PHV_fifo_rdata),
    .data_count(PHV_fifo_usedw),
    .empty(PHV_fifo_empty),
    .full()
    );
		
	
//***************************************************
//                 out_gme_md_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gme_md_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gme_md_wr == 1'b1 ) begin
		    out_gme_md_count <= out_gme_md_count + 32'b1 ; 
		end
		else begin
		    out_gme_md_count <= out_gme_md_count; 
		end
	     
	 end	 
end

//***************************************************
//                 out_gme_phv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gme_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gme_phv_wr == 1'b1 ) begin
		   out_gme_phv_count <= out_gme_phv_count + 32'b1;
		end
		else begin
		   out_gme_phv_count <= out_gme_phv_count ;
		end
	      
	 end	 
end

//***************************************************
//                 out_gme_key_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gme_key_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gme_key_wr == 1'b1 ) begin
		   out_gme_key_count <= out_gme_key_count + 32'b1; 
		end
		else begin
		   out_gme_key_count <= out_gme_key_count ; 
		end	     
	 end	 
end	

//***************************************************
//                 in_gme_md_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gme_md_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gme_md_wr == 1'b1 ) begin
		    in_gme_md_count <= in_gme_md_count + 32'b1 ; 
		end
		else begin
		    in_gme_md_count <= in_gme_md_count ; 
		end
	     
	 end	 
end

//***************************************************
//                 in_gme_phv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gme_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gme_phv_wr == 1'b1 ) begin
		   in_gme_phv_count <= in_gme_phv_count + 32'b1;
		end
		else begin
		   in_gme_phv_count <= in_gme_phv_count ;
		end
	      
	 end	 
end

//***************************************************
//                 in_gme_key_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gme_key_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gme_key_wr == 1'b1 ) begin
		   in_gme_key_count <= in_gme_key_count + 32'b1; 
		end
		else begin
		   in_gme_key_count <= in_gme_key_count ; 
		end	     
	 end	 
end

//***************************************************
//                 in_gme_index_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gme_index_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gme_index_wr == 1'b1 ) begin
		   in_gme_index_count <= in_gme_index_count + 32'b1; 
		end
		else begin
		   in_gme_index_count <= in_gme_index_count ; 
		end	     
	 end	 
end

//***************************************************
//                 status
//***************************************************
always @(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      gme_status <= 32'b0;
   end
   else begin
      gme_status <= {md_phv_state,23'b0,out_gme_md_alf,out_gme_phv_alf,out_gme_key_alf,in_gme_md_alf,in_gme_phv_alf,in_gme_key_alf,out_gme_index_alf};
   end
end

//***************************************************
//                 cfg entry
//***************************************************
wire gme_cs_n;
reg [2:0] gme_cfg_state;
sync_sig sync_gme_inst(
    .clk(clk),
	.rst_n(rst_n),
	.in_sig(~cfg2gme_cs_n),
	.out_sig(gme_cs_n)
);

localparam IDLE_C  = 3'd1,
           WRITE_C = 3'd2,
		   READ_C  = 3'd3,
		   WAIT_C  = 3'd4,
		   ACK_C   = 3'd5;
		  
always@(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      gme2cfg_ack_n <= 1'b1;
	  gme2cfg_rdata <= 32'b0;
	  gme_cfg_state <= IDLE_C;
   end
   else begin
      case(gme_cfg_state)
	    IDLE_C:begin
		   gme2cfg_ack_n <= 1'b1;
		   gme2cfg_rdata <= 32'b0;
		   if((gme_cs_n == 1'b1) && (gme2cfg_ack_n == 1'b1)) begin
		      if(cfg2gme_rw == 1'b0) begin    //write
			     gme_cfg_state <= WRITE_C;
			  end
			  else begin                      //read
			     gme_cfg_state <= READ_C;
			  end
		   end
		   else begin
		      gme_cfg_state <= IDLE_C;
		   end
		
		end
		WRITE_C:begin
		   gme_cfg_state <= ACK_C;
		end
		READ_C:begin
		   gme_cfg_state <= WAIT_C;
		end
		WAIT_C:begin
		   gme_cfg_state <= ACK_C;
		end
		ACK_C:begin
		   case(cfg2gme_addr[9:2])
		       8'h0:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'h1:begin
			      gme2cfg_rdata <= gme_status;
			   end
			   8'h2:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'h3:begin
			      gme2cfg_rdata <= in_gme_md_count;
			   end
			   8'h4:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'h5:begin
			      gme2cfg_rdata <= in_gme_phv_count;
			   end
			   8'h6:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'h7:begin
			      gme2cfg_rdata <= in_gme_key_count;
			   end 
			   8'h8:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'h9:begin
			      gme2cfg_rdata <= in_gme_index_count;
			   end
			   8'ha:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'hb:begin
			      gme2cfg_rdata <= out_gme_md_count;
			   end
			   8'hc:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'hd:begin
			      gme2cfg_rdata <= out_gme_phv_count;
			   end
			   8'he:begin
			      gme2cfg_rdata <= 32'b0;
			   end
			   8'hf:begin
			      gme2cfg_rdata <= out_gme_key_count;
			   end
			   default:begin
			      gme2cfg_rdata <= 32'b0;
			   end
		   endcase
		   
		   if(gme_cs_n == 1'b1) begin
		      gme2cfg_ack_n <= 1'b0;
			  gme_cfg_state <= ACK_C;
		   end
		   else begin
		      gme2cfg_ack_n <= 1'b1;
			  gme_cfg_state <= IDLE_C;
		   end		   
		
		end
		default:begin
		   gme2cfg_ack_n <= 1'b1;
		   gme2cfg_rdata <= 32'b0;
		   gme_cfg_state <= IDLE_C;
		end
	  endcase
   end

end


endmodule
   





    
