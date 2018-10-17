/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: goe.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)Transmit pkt to port or cpu
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/08/24
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 
module goe #(
    parameter   PLATFORM = "Xilinx",
	            LMID = 8'd5
    )(
    input clk,
    input rst_n,
	
//uda pkt waiting for transmit
    input in_goe_data_wr,
    input [133:0] in_goe_data,
    input in_goe_valid_wr,
    input in_goe_valid,
	output out_goe_alf,
	
    input [1023:0] in_goe_phv,
	input in_goe_phv_wr,
	output  out_goe_phv_alf,
//pkt waiting for transmit
    output reg pktout_data_wr,
    output reg [133:0] pktout_data,
    output reg pktout_data_valid_wr,
    output reg pktout_data_valid,
    input pktout_ready,
	
//localbus to goe
    input cfg2goe_cs_n, //low active
	output reg goe2cfg_ack_n, //low active
	input cfg2goe_rw, //0 :write, 1 :read
	input [31:0] cfg2goe_addr,
	input [31:0] cfg2goe_wdata,
	output reg [31:0] goe2cfg_rdata,
	
//input configure pkt from DMA
    input [133:0] cin_goe_data,
	input cin_goe_data_wr,
	output cout_goe_ready,
	
//output configure pkt to next module
    output reg [133:0] cout_goe_data,
	output reg cout_goe_data_wr,
	input cin_goe_ready
);

//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here 
reg [31:0] goe_status;
reg [31:0] in_goe_data_count;
reg [31:0] in_goe_phv_count;
reg [31:0] out_goe_data_count;

//stream fifo
reg in_stream_data_wr;
reg [133:0] in_stream_data;
reg in_stream_valid_wr;
reg in_stream_valid;
//cmd fifo
reg cin_goe_rd;
wire [133:0] cin_goe_rdata;
wire [7:0] ctrl_fifo_usedw;
wire ctrl_fifo_empty;
wire ctrl_fifo_full;
//ram
reg	[7:0]  address_a;
reg	[7:0]  address_b;
reg	[31:0] data_a;
reg	[31:0] data_b;
reg	 stream_rw;
reg	 cnt_rw;
wire[31:0]  q_a;
wire[31:0]  q_b; 


reg  [7:0]stream_addr;
reg stream_data_rd;
wire [133:0]stream_data_q;
wire [7:0]stream_data_usedw;
reg stream_valid_rd;
wire stream_valid_q;
wire stream_valid_emtpy;
//state
reg [1:0]del_state;
reg [2:0]cfg_state;
reg [2:0]cnt_state;

assign out_goe_phv_alf=1'b0;
assign out_goe_alf = stream_data_usedw > 8'd250;
assign cout_goe_ready = ~ctrl_fifo_full;

//***********************************
//       discard pkt
//***********************************
localparam del_idle=2'b00,
           del_trans=2'b01;
reg write_en;

always @(posedge clk or negedge rst_n) begin 
    if(rst_n == 1'b0) begin 
        in_stream_data_wr <= 1'b0;
        in_stream_valid_wr <= 1'b0;
        in_stream_data <= 134'b0;
		in_stream_valid<=1'b0;
		write_en<=1'b0;
		del_state<=del_idle;
    end
    else begin
		case(del_state)
		del_idle:begin
		    in_stream_data_wr <= 1'b0;
            in_stream_valid_wr <= 1'b0;
            in_stream_data <= 134'b0;
		    in_stream_valid<=1'b0;
		    write_en<=1'b0;
		    if(in_goe_data_wr==1'b1 && in_goe_data[133:132]==2'b01)begin
		        write_en<=in_goe_data[108];
                in_stream_data_wr <= ~in_goe_data[108]; 
                in_stream_data <= in_goe_data; 
                del_state<=del_trans;			
            end
		    else begin
		        del_state<=del_idle;		
		    end
        end
	    del_trans:begin
	        in_stream_data_wr <= 1'b0;
            in_stream_valid_wr <= 1'b0;
            in_stream_data <= 134'b0;
	    	in_stream_valid<=1'b0;
	        if(in_goe_data_wr==1'b1 && in_goe_data[133:132]==2'b10)begin
	    	    in_stream_data_wr <= ~write_en; 
                in_stream_data <= in_goe_data;
	    		in_stream_valid <= ~write_en;
                in_stream_valid_wr <= ~write_en;
	    		del_state<=del_idle;
	    	end
	    	else if(in_goe_data_wr)begin
	    	    in_stream_data_wr <= ~write_en; 
                in_stream_data <= in_goe_data;
	    		del_state<=del_trans;	
	    	end
	    	else begin
	    	    del_state<=del_trans;			
	    	end
	    end
	    default:begin del_state<=del_idle;end
	    endcase
	end
end

//***********************************
//       stream_cnt
//***********************************
localparam cnt_idle =3'd0,
		   cnt_wait0=3'd1,
		   cnt_wait1=3'd2,
		   cnt_write=3'd3,
		   cnt_trans=3'd4;
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
		address_b<=8'b0;
		data_b<=32'b0;
		stream_rw<=1'b0;
        pktout_data_wr<=1'b0;
        pktout_data<=134'b0;
        pktout_data_valid_wr<=1'b0;
        pktout_data_valid<=1'b0;
		stream_valid_rd<=1'b0;
		stream_data_rd<=1'b0;
		stream_addr<=8'b0;
		cnt_state<=cnt_idle;
	end
	else begin
	case(cnt_state)
	cnt_idle:begin
	    address_b<=8'b0;
		data_b<=32'b0;
		stream_rw<=1'b0;
        pktout_data_wr<=1'b0;
        pktout_data<=134'b0;
        pktout_data_valid_wr<=1'b0;
        pktout_data_valid<=1'b0;
		stream_valid_rd<=1'b0;
		stream_data_rd<=1'b0;
		stream_addr<=8'b0;
	    if(pktout_ready==1'b1 && stream_valid_emtpy==1'b0 )begin
			stream_valid_rd<=1'b1;
		    stream_data_rd<=1'b1;
			stream_rw<=1'b0;
			address_b<=stream_data_q[57:50];
			stream_addr<=stream_data_q[57:50];
			cnt_state<=cnt_wait0;
		end
		else begin
		    cnt_state<=cnt_idle;
		end
	end
	cnt_wait0:begin
	    stream_rw<=1'b0;
	    stream_valid_rd<=1'b0;
		stream_data_rd<=1'b1;
	    pktout_data_wr<=1'b1;
        pktout_data<=stream_data_q;
		cnt_state<=cnt_wait1;
	end
	cnt_wait1:begin
	    stream_valid_rd<=1'b0;
		stream_data_rd<=1'b1;
	    pktout_data_wr<=1'b1;
        pktout_data<=stream_data_q;
		cnt_state<=cnt_write;
	end
	cnt_write:begin
	    stream_rw<=1'b1;
		address_b<=stream_addr;
		data_b<=q_b[31:0]+1'b1;
		stream_valid_rd<=1'b0;
		stream_data_rd<=1'b1;
	    pktout_data_wr<=1'b1;
        pktout_data<=stream_data_q;
	    cnt_state<=cnt_trans;
	end
	cnt_trans:begin
	    stream_rw<=1'b0;
	    pktout_data_wr<=1'b1;
        pktout_data<=stream_data_q;
		if(stream_data_q[133:132]==2'b10)begin//tail
		    stream_data_rd<=1'b0;
			pktout_data_valid_wr<=1'b1;
            pktout_data_valid<=1'b1;
			cnt_state<=cnt_idle;
		end
		else begin
		    stream_data_rd<=1'b1;
			cnt_state<=cnt_trans;
	    end
	end
	default:cnt_state<=cnt_idle;
	endcase
	end
end	

//***********************************
//       read pkt count
//***********************************
localparam idle_s  = 3'd0,
           write_s = 3'd1,
		   wait0_s = 3'd2,
		   read_s  = 3'd3,
		   tran_s  = 3'd4,
		   discard_s = 3'd5;
           	   
always @ ( posedge clk or negedge rst_n ) begin
    if(rst_n == 1'b0) begin
	   cout_goe_data <= 134'b0;
	   cout_goe_data_wr <= 1'b0;	   
	   address_a <= 8'b0;
       cnt_rw <= 1'b0;
	   cfg_state <= idle_s;   
	end
	else begin
	   case(cfg_state)
	   idle_s:begin
	      cout_goe_data <= 134'b0;
	      cout_goe_data_wr <= 1'b0;
          cnt_rw <= 1'b0;
		  address_a <= 8'b0;
	      if((ctrl_fifo_empty == 1'b0)&&(cin_goe_ready == 1'b1)) begin
		     cin_goe_rd <= 1'b1;
		     if(cin_goe_rdata[103:96] == LMID ) begin
			    if((cin_goe_rdata[126:124] == 3'b001) && (cin_goe_rdata[133:132] == 2'b01) ) begin  //read
				   address_a <= cin_goe_rdata[71:64];     //read address
				   cfg_state <= wait0_s;
				end
				else if ((cin_goe_rdata [126:124] == 3'b010) && (cin_goe_rdata[133:132] == 2'b01)) begin  //write
				   cfg_state <= write_s;
				end
			 end
			 else begin
			    cfg_state <= tran_s;
			 end
		  end
		  else begin
		    cfg_state <= idle_s;
		  end	   
	   end
	   write_s: begin
	      cin_goe_rd <= 1'b1;
		  cnt_rw <= 1'b1;
		  address_a <= cin_goe_rdata[71:64];  //write address
		  data_a <= cin_goe_rdata[31:0];     //write data
	      cfg_state <= discard_s;
	   end
	   wait0_s: begin
	      cin_goe_rd <= 1'b1;
		//  address_a <= 8'b0;
	      cfg_state <= read_s;
	   end
	   read_s :begin
	      cin_goe_rd <= 1'b1;
	      cout_goe_data_wr <= 1'b1;
		  cout_goe_data[133:128] <= cin_goe_rdata[133:128];
		  cout_goe_data[127] <= cin_goe_rdata[127];
	      cout_goe_data[126:124] <= 3'b011;//read ack
	      cout_goe_data[123:112] <= cin_goe_rdata[123:112];
          cout_goe_data[111:104] <= cin_goe_rdata[103:96];
		  cout_goe_data[103:96] <= cin_goe_rdata[111:104];
		  cout_goe_data[95:32] <= cin_goe_rdata[95:32];
		  cout_goe_data[31:0] <= q_a;  //pkt cnt  
	      cfg_state <= tran_s;
	   end
	   tran_s: begin
		  cout_goe_data <= cin_goe_rdata;
		  cout_goe_data_wr <= 1'b1;
		  if(cin_goe_rdata[133:132] == 2'b10) begin
		     cin_goe_rd <= 1'b0;	     
		     cfg_state <= idle_s;	 	  
		  end
		  else begin
		     cin_goe_rd <= 1'b1;
		     cfg_state <= tran_s;	 
		  end		  		    
	   end	
	   discard_s:begin
          cin_goe_rd <= 1'b0;
		  cnt_rw <= 1'b0;
          cout_goe_data <= cin_goe_rdata;
	      if(cin_goe_rdata[133:132] == 2'b10) begin
	         cfg_state <= idle_s;
	      end
	      else begin
	         cfg_state <= discard_s;
			 cin_goe_rd <= 1'b1;
	      end   
	   end
       default : begin
          cfg_state <= idle_s;
       end	   
	   endcase	
	end
end



	   
//***************************************************
//                 out_goe_data_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_goe_data_count <= 32'b0;	 
	 end
	 else begin
	    if(pktout_data_valid_wr == 1'b1 ) begin
		    out_goe_data_count <= out_goe_data_count + 32'b1;
		end
		else begin
		    out_goe_data_count <= out_goe_data_count ;
		end
	      
	 end	 
end

//***************************************************
//                 in_goe_data_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_goe_data_count <= 32'b0;	 
	 end
	 else begin
	    if(in_goe_valid_wr == 1'b1 ) begin
		    in_goe_data_count <= in_goe_data_count + 32'b1 ; 
		end
		else begin
		    in_goe_data_count <= in_goe_data_count ; 	
		end
 
	 end	 
end

//***************************************************
//                 in_goe_pfv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_goe_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(in_goe_phv_wr == 1'b1 ) begin
		    in_goe_phv_count <= in_goe_phv_count + 32'b1 ; 
		end
		else begin
		    in_goe_phv_count <= in_goe_phv_count ; 
		end
	     
	 end	 
end	   

//***************************************************
//                 status
//***************************************************
always @(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      goe_status <= 32'b0;
   end
   else begin
      goe_status <= {cnt_state,27'b0,pktout_ready,out_goe_alf,out_goe_phv_alf};
   end
end	   


//***************************************************
//                 cfg entry
//***************************************************
wire goe_cs_n;
reg [2:0] goe_cfg_state;
sync_sig sync_goe_inst(
    .clk(clk),
	.rst_n(rst_n),
	.in_sig(~cfg2goe_cs_n),
	.out_sig(goe_cs_n)
);

localparam IDLE_C  = 3'd1,
           WRITE_C = 3'd2,
		   READ_C  = 3'd3,
		   WAIT_C  = 3'd4,
		   ACK_C   = 3'd5;
		  
always@(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      goe2cfg_ack_n <= 1'b1;
	  goe2cfg_rdata <= 32'b0;
	  goe_cfg_state <= IDLE_C;
   end
   else begin
      case(goe_cfg_state)
	    IDLE_C:begin
		   goe2cfg_ack_n <= 1'b1;
		   goe2cfg_rdata <= 32'b0;
		   if((goe_cs_n == 1'b1) && (goe2cfg_ack_n == 1'b1)) begin
		      if(cfg2goe_rw == 1'b0) begin    //write
			     goe_cfg_state <= WRITE_C;
			  end
			  else begin                      //read
			     goe_cfg_state <= READ_C;
			  end
		   end
		   else begin
		      goe_cfg_state <= IDLE_C;
		   end
		
		end
		WRITE_C:begin
		   goe_cfg_state <= ACK_C;
		end
		READ_C:begin
		   goe_cfg_state <= WAIT_C;
		end
		WAIT_C:begin
		   goe_cfg_state <= ACK_C;
		end
		ACK_C:begin
		   case(cfg2goe_addr[9:2])

		       8'h0:begin
			      goe2cfg_rdata <= 32'b0;
			   end
			   8'h1:begin
			      goe2cfg_rdata <= goe_status;
			   end
			   8'h2:begin
			      goe2cfg_rdata <= 32'b0;
			   end
			   8'h3:begin
			      goe2cfg_rdata <= in_goe_data_count;
			   end
			   8'h4:begin
			      goe2cfg_rdata <= 32'b0;
			   end
			   8'h5:begin
			      goe2cfg_rdata <= in_goe_phv_count;
			   end
			   8'h6:begin
			      goe2cfg_rdata <= 32'b0;
			   end
			   8'h7:begin
			      goe2cfg_rdata <= out_goe_data_count;
			   end
			   default:begin
			      goe2cfg_rdata <= 32'b0;
			   end
		   endcase
		   
		   if(goe_cs_n == 1'b1) begin
		      goe2cfg_ack_n <= 1'b0;
			  goe_cfg_state <= ACK_C;
		   end
		   else begin
		      goe2cfg_ack_n <= 1'b1;
			  goe_cfg_state <= IDLE_C;
		   end		   
		
		end
		default:begin
		   goe2cfg_ack_n <= 1'b1;
		   goe2cfg_rdata <= 32'b0;
		   goe_cfg_state <= IDLE_C;
		end
	  endcase
   end

end


fifo_134_128 ctrl_fifo(
    .srst(!rst_n),
	.clk(clk),
	.din(cin_goe_data),
	.wr_en(cin_goe_data_wr),
	.dout(cin_goe_rdata),
	.rd_en(cin_goe_rd),
	.data_count(ctrl_fifo_usedw),
	.empty(ctrl_fifo_empty),
	.full(ctrl_fifo_full)
);

	
ram_32_256 goe_ram_inst
(      
    .clka(clk),
    .dina(data_a),
    .wea(cnt_rw),
    .addra(address_a),
    .douta(q_a),
    .clkb(clk),
    .web(stream_rw),
    .addrb(address_b),
    .dinb(data_b),
    .doutb(q_b)   
);

fifo_134_256  stream_data(
	.srst(!rst_n),
	.clk(clk),
	.din(in_stream_data),
	.rd_en(stream_data_rd),
	.wr_en(in_stream_data_wr),
	.dout(stream_data_q),
	.data_count(stream_data_usedw),
	.empty(),
	.full()
	);
fifo_1_128  stream_valid(
	.srst(!rst_n),
	.clk(clk),
	.din(in_stream_valid),
	.rd_en(stream_valid_rd),
	.wr_en(in_stream_valid_wr),
	.dout(stream_valid_q),
	.empty(stream_valid_emtpy),
	.full()
	);	  	   
endmodule                
                   









    
    