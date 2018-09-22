/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: data_cache.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)receive pkt from gpp module
// 2)transmit pkt to gac module
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/07/17
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 

`timescale  1 ns / 1 ps
module data_cache #(
    parameter    PLATFORM = "xilinx"
)(
    input clk,
    input rst_n,
	
//pkt from gpp
    input in_data_cache_data_wr,
    input [133:0] in_data_cache_data,
    input in_data_cache_valid_wr,
    input in_data_cache_valid,
    output out_data_cache_alf,
	
//transport to gda module     
    output reg out_data_cache_data_wr,
    output reg [133:0] out_data_cache_data,
    output reg out_data_cache_valid_wr,
    output reg out_data_cache_valid,
    input in_data_cache_alf,

	
//localbus to data_cache
    input cfg2data_cache_cs_n, //low active
	output reg data_cache2cfg_ack_n, //low active
	input cfg2data_cache_rw, //0 :write, 1 :read
	input [31:0] cfg2data_cache_addr,
	input [31:0] cfg2data_cache_wdata,
	output reg [31:0] data_cache2cfg_rdata
);
//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here 
reg [31:0] data_cache_status;
reg  [31:0] in_cache_data_count;     //in data_cache data count
reg  [31:0] out_cache_data_count;    //out data_cache data count


reg pkt_dfifo_rd;
wire [133:0] pkt_dfifo_rdata;
wire [9:0] pkt_dfifo_usedw;

reg pkt_vfifo_rd;
wire pkt_vfifo_rdata;
wire pkt_vfifo_empty;

assign out_data_cache_alf = pkt_dfifo_usedw[9];
//***********************************
//            Data Cache
//***********************************
//assign out_data_cache_valid = out_data_cache_valid_wr;
reg [1:0] data_cache_state;
localparam  IDLE_S = 2'd1,
            SEND_S = 2'd2,
            DISCARD_S = 2'd3;
always @(posedge clk or negedge rst_n) begin 
    if(rst_n == 1'b0) begin         
        out_data_cache_data_wr <= 1'b0;
        out_data_cache_data <= 134'b0;
        out_data_cache_valid_wr <= 1'b0;
		out_data_cache_valid <= 1'b0;
        pkt_dfifo_rd <= 1'b0;
        pkt_vfifo_rd <= 1'b0;
        data_cache_state <= IDLE_S;
    end
    else begin
        case(data_cache_state)
            IDLE_S: begin
                out_data_cache_data_wr <= 1'b0;
                out_data_cache_valid_wr <= 1'b0;
                if(pkt_vfifo_empty == 1'b0) begin
                    if(pkt_vfifo_rdata == 1'b0) begin //discard data
                        pkt_dfifo_rd <= 1'b1;
                        pkt_vfifo_rd <= 1'b1;
                        data_cache_state <= DISCARD_S;
                    end
                    else begin//send data
                        if(in_data_cache_alf == 1'b0)begin//next module can store a pkt
                            pkt_dfifo_rd <= 1'b1;
                            pkt_vfifo_rd <= 1'b1;
                            data_cache_state <= SEND_S;
                        end
                        else begin //next module can't  store a complete pkt or there isn't a pkt
                            pkt_dfifo_rd <= 1'b0;
                            pkt_vfifo_rd <= 1'b0;
                            data_cache_state <= IDLE_S;
                        end
                    end
                end
                else begin
                    pkt_dfifo_rd <= 1'b0;
                    pkt_vfifo_rd <= 1'b0;
                    data_cache_state <= IDLE_S;
                end
            end
            
            SEND_S: begin 
                pkt_vfifo_rd <= 1'b0;
                out_data_cache_data_wr <= 1'b1;
                out_data_cache_data <= pkt_dfifo_rdata;
                if(pkt_dfifo_rdata[133:132] == 2'b10)begin 
                    pkt_dfifo_rd <= 1'b0;
						out_data_cache_valid  <= 1'b1;
                    out_data_cache_valid_wr <= 1'b1;
                    data_cache_state <= IDLE_S;
                end
                else begin 
                    pkt_dfifo_rd <= 1'b1;
					out_data_cache_valid  <= 1'b0;
                    out_data_cache_valid_wr <= 1'b0;
                    data_cache_state <= SEND_S;
                end
            end
            
            DISCARD_S: begin 
                pkt_vfifo_rd <= 1'b0;
				out_data_cache_data <= 134'b0;
                out_data_cache_data_wr <= 1'b0;
				out_data_cache_valid <= 1'b0;
                out_data_cache_valid_wr <= 1'b0;
                if(pkt_dfifo_rdata[133:132] == 2'b10) begin
                    pkt_dfifo_rd <= 1'b0;
                    data_cache_state <= IDLE_S;
                end
                else begin
                    pkt_dfifo_rd <= 1'b1;
                    data_cache_state <= DISCARD_S;
                end
            end
            
            default: begin 
                out_data_cache_data_wr <= 1'b0;
                out_data_cache_data <= 134'b0;
				out_data_cache_valid <= 1'b0;
                out_data_cache_valid_wr <= 1'b0;
                pkt_dfifo_rd <= 1'b0;
                pkt_vfifo_rd <= 1'b0;
                data_cache_state <= IDLE_S;
            end
        endcase
    end
end
//***************************************************
//                  Other IP Instance
//***************************************************
//likely fifo/ram/async block.... 
//should be instantiated below here              

 fifo_134_1024  pkt_dfifo(
	.srst(!rst_n),
	.clk(clk),
	.din(in_data_cache_data),
	.rd_en(pkt_dfifo_rd),
	.wr_en(in_data_cache_data_wr),
	.dout(pkt_dfifo_rdata),
	.data_count(pkt_dfifo_usedw),
	.empty(),
	.full()

	);

fifo_1_256  pkt_vfifo(
	.srst(!rst_n),
	.clk(clk),
	.din(in_data_cache_valid),
	.rd_en(pkt_vfifo_rd),
	.wr_en(in_data_cache_valid_wr),
	.dout(pkt_vfifo_rdata),
	.data_count(),
	.empty(pkt_vfifo_empty),
	.full()

	);
	
//***************************************************
//                 in_cache_data_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_cache_data_count <= 32'b0;	 
	 end
	 else begin
	    if(in_data_cache_valid_wr == 1'b1 ) begin
		    in_cache_data_count <= in_cache_data_count + 32'b1; 
		end
		else begin
		    in_cache_data_count <= in_cache_data_count ; 
		end
	     
	 end	 
end 

//***************************************************
//                 out_cache_data_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_cache_data_count <= 32'b0;	 
	 end
	 else begin
	    if(out_data_cache_valid_wr == 1'b1 ) begin
		  	out_cache_data_count <= out_cache_data_count + 32'b1;  
		end
		else begin
		   	out_cache_data_count <= out_cache_data_count ;  
		end
	 end	 
end 
	
//***************************************************
//                 status
//***************************************************
always @(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      data_cache_status <= 32'b0;
   end
   else begin
      data_cache_status <= {data_cache_state,28'b0,out_data_cache_alf,in_data_cache_alf};
   end
end

//***************************************************
//                 cfg entry
//***************************************************
wire data_cache_cs_n;
reg [2:0] cache_cfg_state;
sync_sig sync_data_cache_inst(
    .clk(clk),
	.rst_n(rst_n),
	.in_sig(~cfg2data_cache_cs_n),
	.out_sig(data_cache_cs_n)
);

localparam IDLE_C  = 3'd1,
           WRITE_C = 3'd2,
		   READ_C  = 3'd3,
		   WAIT_C  = 3'd4,
		   ACK_C   = 3'd5;
		  
always@(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      data_cache2cfg_ack_n <= 1'b1;
	  data_cache2cfg_rdata <= 32'b0;
	  cache_cfg_state <= IDLE_C;
   end
   else begin
      case(cache_cfg_state)
	    IDLE_C:begin
		   data_cache2cfg_ack_n <= 1'b1;
		   data_cache2cfg_rdata <= 32'b0;
		   if((data_cache_cs_n == 1'b1) && (data_cache2cfg_ack_n == 1'b1)) begin
		      if(cfg2data_cache_rw == 1'b0) begin    //write
			     cache_cfg_state <= WRITE_C;
			  end
			  else begin                      //read
			     cache_cfg_state <= READ_C;
			  end
		   end
		   else begin
		      cache_cfg_state <= IDLE_C;
		   end
		
		end
		WRITE_C:begin
		   cache_cfg_state <= ACK_C;
		end
		READ_C:begin
		   cache_cfg_state <= WAIT_C;
		end
		WAIT_C:begin
		   cache_cfg_state <= ACK_C;
		end
		ACK_C:begin
		   case(cfg2data_cache_addr[9:2])
		       8'h0:begin
			      data_cache2cfg_rdata <= 32'b0;
			   end
			   8'h1:begin
			      data_cache2cfg_rdata <= data_cache_status;
			   end
			   8'h2:begin
			      data_cache2cfg_rdata <= 32'b0;
			   end
			   8'h3:begin
			      data_cache2cfg_rdata <= in_cache_data_count;
			   end
			   8'h4:begin
			      data_cache2cfg_rdata <= 32'b0;
			   end
			   8'h5:begin
			      data_cache2cfg_rdata <= out_cache_data_count;
			   end
			   default:begin
			      data_cache2cfg_rdata <= 32'b0;
			   end
		   endcase
		   
		   if(data_cache_cs_n == 1'b1) begin
		      data_cache2cfg_ack_n <= 1'b0;
			  cache_cfg_state <= ACK_C;
		   end
		   else begin
		      data_cache2cfg_ack_n <= 1'b1;
			  cache_cfg_state <= IDLE_C;
		   end		   
		
		end
		default:begin
		   data_cache2cfg_ack_n <= 1'b1;
		   data_cache2cfg_rdata <= 32'b0;
		   cache_cfg_state <= IDLE_C;
		end
	  endcase
   end

end



endmodule                              