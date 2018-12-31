/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: gac.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)receive MD(Index) from previous module 
// 2)action match according to the rule 
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/09/11
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 


 module gac #(
	parameter	PLATFORM = "Xilinx",
                LMID = 8'd4,
		NMID =8'd5
)(
    input clk,
    input rst_n,
    
    input [5:0] sys_max_cpuid,
	
	 
//waiting for pkt
    input in_gac_data_wr,
    input [133:0] in_gac_data,
    input in_gac_valid_wr,
    input in_gac_valid,
    output out_gac_data_alf,		
//receive form gme 
    input [255:0]  in_gac_md,
	input in_gac_md_wr,
	output wire out_gac_md_alf, 
		
    input [1023:0] in_gac_phv,
	input in_gac_phv_wr,
	output wire out_gac_phv_alf,
	  	
//transmit to next module(goeatch)
    output reg [133:0] out_gac_data,
	output reg out_gac_data_wr,
	output reg out_gac_valid_wr,
    output reg out_gac_valid,
	input in_gac_alf,
		
    output reg [1023:0] out_gac_phv,
	output reg out_gac_phv_wr,
	input in_gac_phv_alf,
		
//localbus to gac
    input cfg2gac_cs, 
	output reg gac2cfg_ack, 
	input cfg2gac_rw, //0 :write, 1 :read
	input [15:0] cfg2gac_addr,
	input [31:0] cfg2gac_wdata,
	output reg [31:0] gac2cfg_rdata,

//input configure pkt from DMA 	
    input [133:0] cin_gac_data,
	input cin_gac_data_wr,
	output cout_gac_ready,
	
//output configure pkt to next module 
    output [133:0] cout_gac_data,
	output cout_gac_data_wr,
	input cin_gac_ready,

//for ANT control of SCM
	input in_gac_sent_start_flag,
	input in_gac_sent_finish_flag,

	output out_gac_sent_start_flag,
	output out_gac_sent_finish_flag
);    

//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here 
reg [31:0] gac_status;
reg [31:0] in_gac_data_count;
reg [31:0] in_gac_md_count;
reg [31:0] in_gac_phv_count;
reg [31:0] out_gac_data_count;
reg [31:0] out_gac_phv_count;

reg gac_dfifo_rd;
wire [133:0] gac_dfifo_rdata;
wire [9:0] gac_dfifo_usedw;
wire gac_dfifo_empty;

reg gac_vfifo_rd;
wire gac_vfifo_rdata;
wire gac_vfifo_empty;
wire [8:0] gac_vfifo_usedw;

reg MD_fifo_rd;
wire [255:0] MD_fifo_rdata; 
wire MD_fifo_empty;
wire [7:0] MD_fifo_usedw;

reg PHV_fifo_rd;
wire [1023:0] PHV_fifo_rdata;  
wire [8:0]PHV_fifo_usedw;
wire PHV_fifo_empty;


reg [5:0] polling_cpuid;
reg [2:0] gac_state;
reg flag;
reg [2:0] cfg_state;

reg [7:0] cfg_address;
reg [7:0] gac_address;
reg [31:0] cfg_wdata;
reg cfg_ram_wr;
//reg cfg_ram_rd;
//reg gac_ram_rd;
wire [31:0] cfg_rdata;
wire [31:0] gac_rdata;
wire sync_cfg2gac_cs;

assign out_gac_data_alf = gac_dfifo_usedw[9];
assign out_gac_md_alf = MD_fifo_usedw > 8'd250;
assign out_gac_phv_alf = PHV_fifo_usedw > 8'd250;
assign cout_gac_ready = cin_gac_ready;
assign cout_gac_data_wr = cin_gac_data_wr;
assign cout_gac_data = cin_gac_data;


//signals for PGM
assign out_gac_sent_start_flag = in_gac_sent_start_flag;
assign out_gac_sent_finish_flag = in_gac_sent_finish_flag;
//*****************************************
//         Flow table configuration
//*****************************************
sync_sig #(2)sync_cfgcs(
//sync the cfg2gda_cs signal from cfg_clk to clk
    .clk(clk),
    .rst_n(rst_n),
    .in_sig(cfg2gac_cs),
    .out_sig(sync_cfg2gac_cs)
);

localparam  R_IDLE_S = 3'd0,
            R_WRITE_S = 3'd1,
			R_READ_S  = 3'd2,
			R_WAIT_S  = 3'd3,
			R_ACK_S   = 3'd4;
				
always @(posedge clk or negedge rst_n) begin
     if(rst_n == 1'b0) begin
	    gac2cfg_rdata <= 32'b0;
		gac2cfg_ack <= 1'b0;
		cfg_address <= 8'b0;
		cfg_wdata <= 32'b0;
		//cfg_ram_rd <= 1'b0;
		cfg_ram_wr <= 1'b0;
		cfg_state <= R_IDLE_S;
	  end
	  else begin
	      case(cfg_state) 
			    R_IDLE_S: begin
				    gac2cfg_rdata <= 32'b0;
		            gac2cfg_ack <= 1'b0;
					cfg_address <= 8'b0;
					cfg_wdata <= 32'b0;					 
					 if((sync_cfg2gac_cs == 1'b1) && (cfg2gac_rw == 1'b0)) begin  //write  
						    cfg_ram_wr <= 1'b1;
							gac2cfg_ack <= 1'b1;
							cfg_wdata   <= cfg2gac_wdata;
							cfg_address <= cfg2gac_addr[9:2];   
						    cfg_state <= R_WRITE_S;
                     end
					 else if((sync_cfg2gac_cs == 1'b1) && (cfg2gac_rw == 1'b1)) begin  //read                      
						    //cfg_ram_rd <= 1'b1;
							if(cfg2gac_addr[10] == 1'b0) begin  //read flow table
							   cfg_address <= cfg2gac_addr[9:2];
							   flag <= 1'b1;
							end
							else begin                          //read count and status
							   flag <= 1'b0;
							end   
						    cfg_state <= R_READ_S;
					 end				      
					 else begin
					    cfg_state <= R_IDLE_S;
					 end			 
				 end
				 
				 R_WRITE_S: begin
				    cfg_ram_wr <= 1'b0;
				    cfg_state <= R_ACK_S;		 
				 end
				 
				 R_READ_S: begin	
		           // cfg_ram_rd <= 1'b0;		 
				    cfg_state <= R_WAIT_S;
				 end
				 
				 R_WAIT_S: begin
				    //cfg_ram_rd <= 1'b0;		 
				    cfg_state <= R_ACK_S;
				 end
				 
				 R_ACK_S: begin
				    if(flag) begin
					   gac2cfg_rdata <= cfg_rdata;
					end
					else begin
					   case(cfg2gac_addr[9:2])
					      8'h0:begin
						     gac2cfg_rdata <= 32'b0;
						  end
						  8'h1:begin
						     gac2cfg_rdata <= gac_status;
						  end
						  8'h2:begin
						     gac2cfg_rdata <= 32'b0;
						  end
						  8'h3:begin
						     gac2cfg_rdata <= in_gac_data_count;
						  end
						  8'h4:begin
						     gac2cfg_rdata <= 32'b0;
						  end
						  8'h5:begin
						     gac2cfg_rdata <= in_gac_md_count;
						  end
						  8'h6:begin
						     gac2cfg_rdata <= 32'b0;
						  end
						  8'h7:begin
						     gac2cfg_rdata <= in_gac_phv_count;
						  end
						  8'h8:begin
						     gac2cfg_rdata <= 32'b0;
						  end
						  8'h9:begin
						     gac2cfg_rdata <= out_gac_data_count;
						  end
						  8'ha:begin
						     gac2cfg_rdata <= 32'b0;
						  end
						  8'hb:begin
						     gac2cfg_rdata <= out_gac_phv_count;
						  end						 						  
						  default:begin
						    gac2cfg_rdata <= 32'b0;
						  end
					   endcase					
					end
				    if(sync_cfg2gac_cs == 1'b1) begin
					    gac2cfg_ack <= 1'b1;
						cfg_state <= R_ACK_S;
				    end
					 else begin
					    gac2cfg_ack <= 1'b0;
						cfg_state <= R_IDLE_S;
				    end	
				 end
				 
				 default begin
				    gac2cfg_rdata <= 32'b0;
		            gac2cfg_ack <= 1'b0;
					cfg_state <= R_IDLE_S;				 
				 end		
			endcase	  
	  end
end





//*****************************************
//         Action Match and Execution
//*****************************************

localparam  IDLE_S     = 3'd0,
            LOOKUP_S   = 3'd1,
			WAIT_S     = 3'd2,
            METADATA_S = 3'd3,
            TRANS_S    = 3'd4,
            DISCARD_S  = 3'd5;

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
	     gac_vfifo_rd <= 1'b0;
         gac_dfifo_rd <= 1'b0;
		 PHV_fifo_rd  <= 1'b0;
		 MD_fifo_rd   <= 1'b0;  
	//	 gac_ram_rd <= 1'b0;		  
		 out_gac_data <= 134'b0;
         out_gac_data_wr <= 1'b0;		    	  
         out_gac_phv <= 1024'b0;
		 out_gac_phv_wr <= 1'b0;	                 
         out_gac_valid_wr <= 1'b0;	
         out_gac_valid<=1'b0;		 
         polling_cpuid <= 6'b0;
		 gac_address <= 8'b0;
         gac_state <= IDLE_S;
    end
	 else begin
	    case(gac_state)
		     IDLE_S: begin
			    gac_vfifo_rd <= 1'b0;
                gac_dfifo_rd <= 1'b0;
		        PHV_fifo_rd  <= 1'b0;
		        MD_fifo_rd   <= 1'b0;  
		     //   gac_ram_rd <= 1'b0;
				gac_address <= 8'b0;			  
                out_gac_valid_wr <= 1'b0;
				out_gac_valid<=1'b0;
				out_gac_data_wr <= 1'b0;				 
				  if((gac_vfifo_empty == 1'b0) && (MD_fifo_empty == 1'b0) && (in_gac_alf == 1'b0)&& (in_gac_phv_alf==1'b0)) begin //wait pkt and md(index)
				     if(MD_fifo_rdata[87:80] == LMID) begin //DMID = 4
					  MD_fifo_rd <= 1'b0;					 
                   //   gac_ram_rd <= 1'b1;  
                      gac_address <= MD_fifo_rdata[57:50];  //index
                      gac_state <= LOOKUP_S;
					  end
					  else begin //DMID != 4
                          gac_vfifo_rd <= 1'b1;
				          gac_dfifo_rd <= 1'b1;
						  PHV_fifo_rd <= 1'b1;
						  MD_fifo_rd <= 1'b1;						 								
						  out_gac_phv_wr <= 1'b1;
						  out_gac_phv <= PHV_fifo_rdata;
					      gac_state <= TRANS_S;
					  end
			     end       
				  else begin
			           gac_vfifo_rd <= 1'b0;
                       gac_dfifo_rd <= 1'b0;
					   PHV_fifo_rd <= 1'b0;								  
					   out_gac_data <= 134'b0;
                       out_gac_data_wr <= 1'b0;			  
					   out_gac_phv <= 1024'b0;
					   out_gac_phv_wr <= 1'b0;							  
                    gac_state <= IDLE_S;			  
				  end		  
			  end
			  
			  LOOKUP_S: begin
			     MD_fifo_rd <= 1'b0;
			//	 gac_ram_rd <= 1'b0;
			//	 gac_address <= 8'b0;			  
				 gac_state <= WAIT_S;			  
			  end
			  
			  WAIT_S: begin    //ram read have 2 cycle delay
				  gac_vfifo_rd <= 1'b1;
                  gac_dfifo_rd <= 1'b1;
				  PHV_fifo_rd <= 1'b1;
				  MD_fifo_rd <= 1'b1;								               
				  out_gac_phv_wr <= 1'b0;										
                  gac_state <= METADATA_S;		  
			  end
			  
			  METADATA_S: begin
		         gac_vfifo_rd <= 1'b0;
				 PHV_fifo_rd  <= 1'b0;
				 MD_fifo_rd <= 1'b0;	
                 out_gac_phv <= PHV_fifo_rdata;	
                 out_gac_phv_wr <= 1'b1;				 
                 case(gac_rdata[31:28])
                   4'd1: begin//1 trans to CPU with thread id assignd by user
                        out_gac_data_wr <= 1'b1;							
						out_gac_data[133:128] <= gac_dfifo_rdata[133:128];
						out_gac_data[127]     <= MD_fifo_rdata[127];      //pktsrc
						out_gac_data[126]     <= 1'b1;                    //pkedes
						out_gac_data[125:120] <= MD_fifo_rdata[125:120];  //inport
						out_gac_data[119:118] <= gac_rdata[31:28];        //outtype
						out_gac_data[117:112] <= gac_rdata[5:0];           //outport
						out_gac_data[111:109] <= MD_fifo_rdata[111:109];  //priority
						out_gac_data[108]     <= MD_fifo_rdata[108];      //discard
						out_gac_data[107:88]  <= MD_fifo_rdata[107:88];
						out_gac_data[87:80]   <= 8'd5;          //dmid
                        out_gac_data[79:0]    <= MD_fifo_rdata[79:0];
                        gac_state <= TRANS_S;
                    end
                    
                   4'd2: begin//2 trans to CPU with polling thread id
                        out_gac_data_wr <= 1'b1;
						out_gac_data[133:128] <= gac_dfifo_rdata[133:128];
						out_gac_data[127]     <= MD_fifo_rdata[127];      //pktsrc
						out_gac_data[126]     <= 1'b1;                    //pktdes
						out_gac_data[125:120] <= MD_fifo_rdata[125:120];  //inport
						out_gac_data[119:118] <= gac_rdata[31:28];         //outtype
						out_gac_data[117:112] <= polling_cpuid ;           //outport
						out_gac_data[111:109] <= MD_fifo_rdata[111:109];  //priority
						out_gac_data[108]     <= MD_fifo_rdata[108];      //discard
						out_gac_data[107:88]  <= MD_fifo_rdata[107:88];
						out_gac_data[87:80]   <= 8'd5;          //dmid
                        out_gac_data[79:0]    <= MD_fifo_rdata[79:0];
                        if((polling_cpuid+6'b1) < sys_max_cpuid) begin
                        //if use sys_max_cpuid -1,maybe underflow
                            polling_cpuid <= polling_cpuid + 6'd1;
                        end							
                        else begin
                            polling_cpuid <= 6'b0;
                        end
                        gac_state <= TRANS_S;
                    end
                    
                   4'd3: begin//3 trans to port 
                        out_gac_data_wr <= 1'b1;								
                        out_gac_data[133:128] <= gac_dfifo_rdata[133:128];
						out_gac_data[127]     <= MD_fifo_rdata[127];      //pktsrc
						out_gac_data[126]     <= 1'b0;                    //pktdes
						out_gac_data[125:120] <= MD_fifo_rdata[125:120];  //inport
						out_gac_data[119:118] <= 2'b0;         //outtype
						out_gac_data[117:112] <= gac_rdata[5:0];          //outport
						out_gac_data[111:109] <=MD_fifo_rdata[111:109];                  //priority
						out_gac_data[108]     <= MD_fifo_rdata[108];      //discard
						out_gac_data[107:88]  <= MD_fifo_rdata[107:88];
						out_gac_data[87:80]   <= 8'd5;          //dmid
                        out_gac_data[79:0]    <= MD_fifo_rdata[79:0];
                        gac_state <= TRANS_S;
                    end
                    
                   4'd4: begin//4 assign Mid
                        out_gac_data_wr <= 1'b1;
					  	out_gac_data[133:128] <= gac_dfifo_rdata[133:128];
						out_gac_data[127]     <= MD_fifo_rdata[127];      //pktsrc
						out_gac_data[126]     <= 1'b1;                    //pktdes
						out_gac_data[125:120] <= MD_fifo_rdata[125:120];  //inport
						out_gac_data[119:118] <= 2'b0;        //outtype
						out_gac_data[117:112] <= MD_fifo_rdata[117:112];   //outport
						out_gac_data[111:109] <= MD_fifo_rdata[111:109];  //priority
						out_gac_data[108]     <= MD_fifo_rdata[108];      //discard
						out_gac_data[107:88]  <= MD_fifo_rdata[107:88];
						out_gac_data[87:80]   <= gac_rdata[7:0];          //dmid
						out_gac_data[79:0]    <= MD_fifo_rdata[79:0];
                        gac_state <= TRANS_S;
                    end									
                    
                   default: begin 

                   /**
                    * in order to allow ant_pkt sent arrive pgm, we need to judge if the pkt comes from CPU or
                    *  phy, if the pkt from CPU, we need to allow it to pass, else, we discard the pkt.
                    */
                   		if(gac_dfifo_rdata[127]==1'b1) begin
                   			gac_state <= TRANS_S;
                        	out_gac_phv_wr <= 1'b1;
                        	out_gac_phv <= 1024'b0;
                        	out_gac_data_wr <= 1'b1;
                        	out_gac_data <= {gac_dfifo_rdata[133:88], 8'd5, gac_dfifo_rdata[79:0]};
                   		end
                   		
                   		else begin
                            gac_state <= DISCARD_S;
							out_gac_phv_wr <= 1'b0;	
							out_gac_phv <=1024'b0;
						end
                   end
               endcase		  
			  end
			  
			  TRANS_S: begin
			      gac_vfifo_rd <= 1'b0;
				  PHV_fifo_rd  <= 1'b0; 	
			      MD_fifo_rd <= 1'b0;				
			      out_gac_data <= gac_dfifo_rdata;
				  out_gac_data_wr <= 1'b1;	
				  out_gac_phv_wr <= 1'b0;				
               if(gac_dfifo_rdata[133:132] == 2'b10) begin//end of pkt					  
                   gac_dfifo_rd <= 1'b0;
                   out_gac_valid_wr <= 1'b1;
				   out_gac_valid<=1'b1;
                   gac_state <= IDLE_S;
               end
               else begin				  
                   gac_dfifo_rd <= 1'b1;
                   out_gac_valid_wr <= 1'b0;
				   out_gac_valid<=1'b0;
                   gac_state <= TRANS_S;
               end		  
			  end
			  
			  DISCARD_S: begin
				 gac_vfifo_rd <= 1'b0;
				 PHV_fifo_rd  <= 1'b0;
				 MD_fifo_rd <= 1'b0;				 
				 out_gac_phv <= 1024'b0;
				 out_gac_phv_wr <= 1'b0;					 
                if(gac_dfifo_rdata[133:132] == 2'b10) begin//end of pkt
					gac_dfifo_rd <= 1'b0;
                    gac_state <= IDLE_S;
                end
                else begin
                    gac_dfifo_rd <= 1'b1;
                    gac_state <= DISCARD_S;
                end		  
			  end
			  
			  default: begin
			     gac_vfifo_rd <= 1'b0;
                 gac_dfifo_rd <= 1'b0;
		         PHV_fifo_rd  <= 1'b0;
		         MD_fifo_rd   <= 1'b0;  
		   //      gac_ram_rd <= 1'b0;	  
		         out_gac_data <= 134'b0;
                 out_gac_data_wr <= 1'b0;		    	  
                 out_gac_phv <= 1024'b0;
		         out_gac_phv_wr <= 1'b0;	
                 out_gac_valid <= 1'b0;
                 out_gac_valid_wr <= 1'b0;		  
                 polling_cpuid <= 6'b0;
		         gac_address <= 8'b0;
                 gac_state <= IDLE_S;		  
			  end		 
		 endcase	 
	 end
end


//***************************************************
//                  Other IP Instance
//***************************************************

ram_32_256 gac_ram
(      
    .clka(clk),
    .dina(cfg_wdata),
    .wea(cfg_ram_wr),
    .addra(cfg_address),
    .douta(cfg_rdata),
    .clkb(clk),
    .web(1'b0),
    .addrb(gac_address),
    .dinb(32'b0),
    .doutb(gac_rdata)//.q_b(gac_rdata)    
);


fifo_134_1024  gac_dfifo(
	.srst(!rst_n),
	.clk(clk),
	.din(in_gac_data),
	.rd_en(gac_dfifo_rd),
	.wr_en(in_gac_data_wr),
	.dout(gac_dfifo_rdata),
	.data_count(gac_dfifo_usedw),
	.empty(gac_dfifo_empty),
	.full()

	);
 fifo_1_256  gac_vfifo(
       .srst(!rst_n),
       .clk(clk),
       .din(in_gac_valid),
       .rd_en(gac_vfifo_rd),
       .wr_en(in_gac_valid_wr),
       .dout(gac_vfifo_rdata),
       .data_count(),
       .empty(gac_vfifo_empty),
       .full()
   
       );
 fifo_256_256  MD_fifo(
       .srst(!rst_n),
       .clk(clk),
       .din(in_gac_md),
       .rd_en(MD_fifo_rd),
       .wr_en(in_gac_md_wr),
       .dout(MD_fifo_rdata),
       .data_count(MD_fifo_usedw),
       .empty(MD_fifo_empty),
       .full()
   
       );
fifo_1024_256  PHV_fifo(
	.srst(!rst_n),
	.clk(clk),
	.din(in_gac_phv),
	.rd_en(PHV_fifo_rd),
	.wr_en(in_gac_phv_wr),
	.dout(PHV_fifo_rdata),
	.data_count(PHV_fifo_usedw),
	.empty(PHV_fifo_empty),
	.full()

	);
	

	
 //***************************************************
//                 out_gac_phv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gac_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gac_phv_wr == 1'b1 ) begin
		    out_gac_phv_count <= out_gac_phv_count + 32'b1; 
	    end
		else begin
		    out_gac_phv_count <= out_gac_phv_count; 
		end	     
	 end	 
end

 //***************************************************
//                 out_gac_data_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gac_data_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gac_valid_wr == 1'b1 ) begin
		    out_gac_data_count <= out_gac_data_count + 32'b1;
		end
		else begin
		    out_gac_data_count <= out_gac_data_count ;
		end
	      
	 end	 
end
 

//***************************************************
//                 in_gac_md_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gac_md_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gac_md_wr == 1'b1 ) begin
		    in_gac_md_count <= in_gac_md_count + 32'b1;  
		end
		else begin
		    in_gac_md_count <= in_gac_md_count ;  
		end	    
	 end	 
end
 
 //***************************************************
//                 in_gac_phv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gac_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gac_phv_wr == 1'b1) begin
		    in_gac_phv_count <= in_gac_phv_count + 32'b1 ;  
		end
		else begin
		    in_gac_phv_count <= in_gac_phv_count;  
		end	    
	 end	 
end

 //***************************************************
//                 in_gac_data_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gac_data_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gac_valid_wr == 1'b1) begin
		    in_gac_data_count <= in_gac_data_count + 32'b1;
		end
		else begin
		    in_gac_data_count <= in_gac_data_count ;
		end	      
	 end	 
end

//***************************************************
//                 status
//***************************************************
always @(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      gac_status <= 32'b0;
   end
   else begin
      gac_status <= {cfg_state,gac_state,21'b0,out_gac_data_alf,out_gac_md_alf,out_gac_phv_alf,in_gac_alf,in_gac_phv_alf};
   end
end

endmodule