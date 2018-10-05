/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: gke.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)receive MD & PHV from Previous module
// 2)parse & transmit key to next module 
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/08/24
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 

module gke #(
    parameter    PLATFORM = "Xilinx",
	             LMID = 8'd2,
                 NMID = 8'd3
    )(
    input clk,
    input rst_n,
	   
//receive md & phv from Previous module
    input [255:0] in_gke_md,
	input in_gke_md_wr,
	output wire out_gke_md_alf,
	
    input [1023:0] in_gke_phv,
	input in_gke_phv_wr, 
	output wire out_gke_phv_alf,
		
//transport key to next module 
    output reg [511:0] out_gke_key,
    output reg out_gke_key_wr,
	input in_gke_key_alf,
		
    output reg [255:0] out_gke_md,
	output reg out_gke_md_wr,
	input in_gke_md_alf,
	
    output reg [1023:0] out_gke_phv,
	output reg out_gke_phv_wr,
	input in_gke_phv_alf,
	
//localbus to gke
    input cfg2gke_cs_n, //low active
	output reg gke2cfg_ack_n, //low active
	input cfg2gke_rw, //0 :write, 1 :read
	input [31:0] cfg2gke_addr,
	input [31:0] cfg2gke_wdata,
	output reg [31:0] gke2cfg_rdata,
	
//input configure pkt from DMA
    input [133:0] cin_gke_data,
	input cin_gke_data_wr,
	output cout_gke_ready,
	
//output configure pkt to next module
    output [133:0] cout_gke_data,
	output cout_gke_data_wr,
	input cin_gke_ready
);
//***************************************************
//        Intermediate variable Declaration
//****************************************************
//all wire/reg/parameter variable
//should be declare below here
 reg [31:0] gke_status;
 reg [31:0] in_gke_md_count;
 reg [31:0] in_gke_phv_count;
 reg [31:0] out_gke_key_count;
 reg [31:0] out_gke_md_count;
 reg [31:0] out_gke_phv_count;
 	
reg [47:0]  DMAC;
reg [47:0]  SMAC;
reg [15:0]  TCI;
reg [15:0]  ETH_TYPE;
reg [7:0]   IP_PROTO;
reg [7:0]   TOS;
reg [7:0]   TTL;
reg [3:0]   FRAG;
reg [31:0]  SIP;
reg [31:0]  DIP;
reg [127:0] Src_IP;
reg [127:0] Dst_IP;
reg [31:0]  LABEL;
reg [15:0]  SPORT;
reg [15:0]  DPORT;
reg [15:0]  FLAG;
reg [47:0]  SHA;
reg [47:0]  THA;
reg [5:0]   INPORT;
reg [3:0]   pst_switch;
reg [255:0] in_gke_md_dly;
reg [1023:0] in_gke_phv_dly;
reg  in_gke_md_wr_dly;


assign   out_gke_md_alf = in_gke_md_alf|in_gke_key_alf;
assign   out_gke_phv_alf = in_gke_phv_alf|in_gke_key_alf;
assign   cout_gke_data_wr = cin_gke_data_wr;
assign   cout_gke_data = cin_gke_data;
assign   cout_gke_ready = cin_gke_ready;

//***************************************************
//             Transmit MD AND PHV
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin 
        out_gke_md  <= 256'b0;
        out_gke_phv <= 1024'b0;
        out_gke_md_wr <= 1'b0;
		out_gke_phv_wr <= 1'b0;
    end
    else begin
	     in_gke_md_dly <= in_gke_md;     //Synchronize with key
        in_gke_md_wr_dly <= in_gke_md_wr;
		  in_gke_phv_dly <= in_gke_phv;
          
        if((in_gke_md_wr_dly == 1'b1)&&(in_gke_md_dly[87:80] == LMID))begin 
            out_gke_md <= {in_gke_md_dly[255:88],8'd3,in_gke_md_dly[79:0]};
            out_gke_phv <= in_gke_phv_dly;
            out_gke_md_wr <= 1'b1;
		    out_gke_phv_wr <= 1'b1;				
        end 
        else begin 
            if((in_gke_md_wr_dly == 1'b1)&&(in_gke_md_dly[87:80] != LMID)) begin 
                out_gke_md <= in_gke_md_dly;
                out_gke_phv <= in_gke_phv_dly;
                out_gke_md_wr <= 1'b1;
		        out_gke_phv_wr <= 1'b1;
            end
            else begin 
                out_gke_md <= 256'b0;
                out_gke_phv <= 1024'b0;
                out_gke_md_wr <= 1'b0;
		        out_gke_phv_wr <= 1'b0;
            end
        end
    end 
end

//***************************************************
//           Fetch Informations From PHV
//***************************************************

always @(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
		      DMAC <= 48'b0;
				SMAC <= 48'b0;
				TCI <= 16'b0;
				ETH_TYPE <= 16'b0;
				IP_PROTO <= 8'b0;
				TOS <= 8'b0;
				TTL <= 8'b0;
				FRAG <= 4'b0;
				SIP <= 32'b0;
				DIP <= 32'b0;
				Src_IP <= 128'b0;
				Dst_IP <= 128'b0;
				LABEL <= 32'b0;
				SPORT <= 16'b0;
				DPORT <= 16'b0;
				FLAG <= 16'b0;
				SHA <= 48'b0;
				THA <= 48'b0;
				INPORT <= 6'b0;	
	
            pst_switch <= 4'hf;			
		  end
		  else begin
		  if(in_gke_md_wr==1'b1)begin
		    if(in_gke_md[87:80] == LMID) begin
		       if((in_gke_phv_wr == 1'b1)&&((in_gke_md[79:72] == 8'b00000001) ||(in_gke_md[79:72] ==8'b00000111))) begin //is_ipv4_tcp or is_ipv4_udp
                    DMAC <= in_gke_phv[1023:976];    
                    SMAC <= in_gke_phv[975:928];  
                    TCI <= in_gke_phv[911:896]; 
                    ETH_TYPE <= in_gke_phv[927:912];         
                    TOS <= in_gke_phv[903:896];  
//		    	    INPORT <= in_gke_md[123:120];   //1.0
                    INPORT <= in_gke_md[125:120];   //2.0
                    FRAG <= {1'b0,in_gke_phv[863:861]};
                    TTL <= in_gke_phv[847:840];  
                    IP_PROTO <= in_gke_phv[839:832];       
                    SIP <= in_gke_phv[815:784];
                    DIP <= in_gke_phv[783:752];
                    SPORT <= in_gke_phv[751:736];
                    DPORT <= in_gke_phv[735:720];
                    FLAG <= in_gke_phv[655:650];				
                    pst_switch <= 4'd1;
              end
              else if((in_gke_phv_wr == 1'b1)&&(in_gke_md[79:72] == 8'b00000010)) begin//is_ipv4
                DMAC <= in_gke_phv[1023:976];
                SMAC <= in_gke_phv[975:928];
                TCI <= in_gke_phv[911:896];//VLAN_FIELD <= udp2uke_pfv[927:896] 
                ETH_TYPE <= in_gke_phv[927:912];           
                TOS <= in_gke_phv[903:896];
//              INPORT <= in_gke_md[123:120];	//1.0			
                INPORT <= in_gke_md[125:120];   //2.0
                FRAG <= {1'b0,in_gke_phv[863:861]};
                TTL <= in_gke_phv[847:840];
                IP_PROTO <= in_gke_phv[839:832];        
                SIP <= in_gke_phv[815:784];
                DIP <= in_gke_phv[783:752];
                SPORT <= in_gke_phv[751:736];
                DPORT <= in_gke_phv[735:720];
                FLAG <= in_gke_phv[655:650];				
                pst_switch <= 4'd2;              
              end
              else if((in_gke_phv_wr == 1'b1)&&(in_gke_md[79:72] == 8'b00000011)) begin//is_arp
                DMAC <= in_gke_phv[1023:976];  
                SMAC <= in_gke_phv[975:928];
                TCI <= in_gke_phv[911:896];//VLAN_FIELD <= udp2uke_pfv[927:896] 
                ETH_TYPE <= in_gke_phv[927:912];  
                TOS <= 8'b0;
//              INPORT <= in_gke_md[123:120];  //1.0				
                INPORT <= in_gke_md[125:120];   //2.0
                FRAG <= 4'b0;
                TTL <= 8'b0;
                IP_PROTO <= in_gke_phv[855:848]; 
                SHA <= in_gke_phv[847:800];
                SIP <= in_gke_phv[799:768];
                THA <= in_gke_phv[767:720];
                DIP <= in_gke_phv[719:688]; 				
                pst_switch <= 4'd3;            
              end
              else if((in_gke_phv_wr == 1'b1)&&((in_gke_md[79:72] == 8'b10000001) ||(in_gke_md[79:72] == 8'b10000011))) begin// is_ipv6_tcp or is_ipv6_udp        
                DMAC <= in_gke_phv[1023:976];
                SMAC <= in_gke_phv[975:928];
                TCI <= in_gke_phv[911:896];//VLAN_FIELD <= udp2uke_pfv[927:896] 
                ETH_TYPE <= in_gke_phv[927:912];                  
                TOS <= in_gke_phv[907:900];
                IP_PROTO <= in_gke_phv[863:856];
                TTL <= in_gke_phv[855:848];
                FRAG <= 4'b0;
 //             INPORT <= in_gke_md[123:120];  //1.0          
                INPORT <= in_gke_md[125:120];   //2.0
                LABEL <= {12'b0,in_gke_phv[899:880]};          
                Src_IP <= in_gke_phv[847:720];
                Dst_IP <= in_gke_phv[719:592];
                SPORT <= in_gke_phv[591:576];
                DPORT <= in_gke_phv[575:560]; 
                FLAG <= in_gke_phv[495:480];				
                pst_switch <= 4'd4;            
              end 
              else if((in_gke_phv_wr == 1'b1)&&(in_gke_md[79:72] == 8'b10000010)) begin //is_ipv6
                DMAC <= in_gke_phv[1023:976];
                SMAC <= in_gke_phv[975:928];
                TCI <= in_gke_phv[911:896];//VLAN_FIELD <= udp2uke_pfv[927:896] 
                ETH_TYPE <= in_gke_phv[927:912];                          
                TOS <= in_gke_phv[907:900];
                IP_PROTO <= in_gke_phv[863:856];
                TTL <= in_gke_phv[855:848];
                FRAG <= 4'b0;
 //             INPORT <= in_gke_md[123:120];   //1.0          
                INPORT <= in_gke_md[125:120];   //2.0
                LABEL <= {12'b0,in_gke_phv[899:880]};          
                Src_IP <= in_gke_phv[847:720];
                Dst_IP <= in_gke_phv[719:592];
                SPORT <= in_gke_phv[591:576];
                DPORT <= in_gke_phv[575:560]; 
                FLAG <= in_gke_phv[495:480];				
                pst_switch <= 4'd5;          
              end
              else begin
		        DMAC <= DMAC;
		    	SMAC <= SMAC;
		    	TCI <= TCI;
		    	ETH_TYPE <= ETH_TYPE;
		    	IP_PROTO <= IP_PROTO;
		    	TOS <= TOS;
		    	TTL <= TTL;
		    	FRAG <= FRAG;
		    	SIP <= SIP;
		    	DIP <= DIP;
		    	Src_IP <= Src_IP;
		    	Dst_IP <= Dst_IP;
		    	LABEL <= LABEL;
		    	SPORT <= SPORT;
		    	DPORT <= DPORT;
		    	FLAG <= FLAG;
		    	SHA <= SHA;
		    	THA <= THA;
		    	INPORT <= INPORT;
		    
                pst_switch <= 4'd0;
                end  
		      end
		      else begin
		        pst_switch <= 4'hf;
		      end	  
			end
			else begin
			   pst_switch <= 4'hf;
			end
		  end       
    end
	 
//***************************************************
//                  Key Field Wrapper
//***************************************************
  
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
		out_gke_key_wr <= 1'b0;
        out_gke_key <= 512'b0;        
    end
    else begin
	     if(pst_switch == 4'd0)begin
            out_gke_key_wr <= 1'b1;       
            out_gke_key <= 512'b0;            
        end
        else if(pst_switch == 4'd1)begin//is_ipv4_tcp/udp
        //send key at last cycle of pkt
            out_gke_key_wr <= 1'b1;
            out_gke_key[47:0]    <= DMAC;
            out_gke_key[95:48]   <= SMAC;
            out_gke_key[111:96]  <= TCI;
            out_gke_key[127:112] <= ETH_TYPE;
            out_gke_key[135:128] <= IP_PROTO;
            out_gke_key[143:136] <= TOS;
            out_gke_key[151:144] <= TTL;
            out_gke_key[155:152] <= FRAG;
            out_gke_key[161:156] <= INPORT;            
            out_gke_key[193:162] <= SIP;
            out_gke_key[225:195] <= DIP;
            out_gke_key[241:226] <= SPORT;
            out_gke_key[257:242] <= DPORT;
            out_gke_key[273:258] <= FLAG;			
			out_gke_key[511:274] <= 238'b0;
        end
        else if(pst_switch == 4'd2) begin//is_ipv4
            out_gke_key_wr <= 1'b1;
            out_gke_key[47:0]    <= DMAC;
            out_gke_key[95:48]   <= SMAC;
            out_gke_key[111:96]  <= TCI;
            out_gke_key[127:112] <= ETH_TYPE;
            out_gke_key[135:128] <= IP_PROTO;
            out_gke_key[143:136] <= TOS;
            out_gke_key[151:144] <= TTL;
            out_gke_key[155:152] <= FRAG;
            out_gke_key[161:156] <= INPORT;            
            out_gke_key[193:162] <= SIP;
            out_gke_key[225:194] <= DIP;
            out_gke_key[241:226] <= 16'b0;
            out_gke_key[257:242] <= 16'b0;
            out_gke_key[273:258] <= 16'b0;			
			out_gke_key[511:274] <= 238'b0;
        end            
        else if(pst_switch == 4'd3) begin//is_arp
            out_gke_key_wr <= 1'b1;
            out_gke_key[47:0]    <= DMAC;
            out_gke_key[95:48]   <= SMAC;
            out_gke_key[111:96]  <= TCI;
            out_gke_key[127:112] <= ETH_TYPE;           
            out_gke_key[135:128] <= IP_PROTO;
            out_gke_key[143:136] <= TOS;
            out_gke_key[151:144] <= TTL;
            out_gke_key[155:152] <= FRAG;
            out_gke_key[161:156] <= INPORT;            
            out_gke_key[193:162] <= SIP;
            out_gke_key[225:194] <= DIP;
            out_gke_key[273:226] <= SHA;
            out_gke_key[321:275] <= THA;			
			out_gke_key[511:322] <= 190'b0;
        end  
        else if(pst_switch == 4'd4) begin//is_ipv6_tcp/udp
            out_gke_key_wr <= 1'b1;
            out_gke_key[47:0]    <= DMAC;
            out_gke_key[95:48]   <= SMAC;
            out_gke_key[111:96]  <= TCI;
            out_gke_key[127:112] <= ETH_TYPE;
            out_gke_key[135:128] <= IP_PROTO;
            out_gke_key[143:136] <= TOS;
            out_gke_key[151:144] <= TTL;				
            out_gke_key[155:152] = FRAG;
            out_gke_key[161:156] = INPORT;
            out_gke_key[289:162] <= Src_IP;
            out_gke_key[417:290] <= Dst_IP;
            out_gke_key[449:418] <= LABEL;
            out_gke_key[465:450] <= SPORT;
            out_gke_key[481:466] <= DPORT;			
            out_gke_key[511:482] <= 30'b0;                                       
        end
        else if(pst_switch == 4'd5) begin//is_ipv6
            out_gke_key_wr <= 1'b1;
            out_gke_key[47:0]    <= DMAC;
            out_gke_key[95:48]   <= SMAC;
            out_gke_key[111:96]  <= TCI;
            out_gke_key[127:112] <= ETH_TYPE;
            out_gke_key[135:128] <= IP_PROTO;
            out_gke_key[143:136] <= TOS;
            out_gke_key[151:144] <= TTL;			
            out_gke_key[155:152] = FRAG;
            out_gke_key[161:156] = INPORT;
            out_gke_key[289:162] <= Src_IP;
            out_gke_key[417:290] <= Dst_IP;
            out_gke_key[449:418] <= LABEL;
            out_gke_key[465:450] <= 16'b0;
            out_gke_key[481:466] <= 16'b0;			
			out_gke_key[511:482] <= 30'b0;                        
        end        
        else begin
            out_gke_key_wr <= 1'b0;       
            out_gke_key <= 512'b0;            
        end
    end
end 

//***************************************************
//                 in_gke_md_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gke_md_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gke_md_wr == 1'b1) begin
		   in_gke_md_count <= in_gke_md_count + 32'b1;
		end
		else begin
		   in_gke_md_count <= in_gke_md_count ;
		end	      
	 end	 
end

//***************************************************
//                 in_gke_phv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    in_gke_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(in_gke_phv_wr == 1'b1) begin
		   in_gke_phv_count <= in_gke_phv_count + 32'b1;
		end
		else begin
		   in_gke_phv_count <= in_gke_phv_count ;
		end	      
	 end	 
end

//***************************************************
//                 out_gke_md_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gke_md_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gke_md_wr == 1'b1) begin
		   out_gke_md_count <= out_gke_md_count + 32'b1;
		end
		else begin
		   out_gke_md_count <= out_gke_md_count ;
		end
	      
	 end	 
end

//***************************************************
//                 out_gke_phv_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gke_phv_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gke_phv_wr == 1'b1) begin
		   out_gke_phv_count <= out_gke_phv_count + 32'b1;
		end
		else begin
		   out_gke_phv_count <= out_gke_phv_count ;
		end	      
	 end	 
end

//***************************************************
//                 out_gke_key_count
//***************************************************
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 ) begin
	    out_gke_key_count <= 32'b0;	 
	 end
	 else begin
	    if(out_gke_key_wr == 1'b1) begin
	       out_gke_key_count <= out_gke_key_count + 32'b1;			
		end
		else begin
		   out_gke_key_count <= out_gke_key_count;		
		end	      
	 end	 
end

//***************************************************
//                 status
//***************************************************
always @(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      gke_status <= 32'b0;
   end
   else begin
      gke_status <= {2'b00,25'b0,out_gke_md_alf,out_gke_phv_alf,in_gke_md_alf,in_gke_phv_alf,in_gke_key_alf};
   end
end


//***************************************************
//                 cfg entry
//***************************************************
wire gke_cs_n;
reg [2:0] gke_cfg_state;
sync_sig sync_gke_inst(
    .clk(clk),
	.rst_n(rst_n),
	.in_sig(~cfg2gke_cs_n),
	.out_sig(gke_cs_n)
);

localparam IDLE_C  = 3'd1,
           WRITE_C = 3'd2,
		   READ_C  = 3'd3,
		   WAIT_C  = 3'd4,
		   ACK_C   = 3'd5;
		  
always@(posedge clk or negedge rst_n) begin
   if(rst_n == 1'b0) begin
      gke2cfg_ack_n <= 1'b1;
	  gke2cfg_rdata <= 32'b0;
	  gke_cfg_state <= IDLE_C;
   end
   else begin
      case(gke_cfg_state)
	    IDLE_C:begin
		   gke2cfg_ack_n <= 1'b1;
		   gke2cfg_rdata <= 32'b0;
		   if((gke_cs_n == 1'b1) && (gke2cfg_ack_n == 1'b1)) begin
		      if(cfg2gke_rw == 1'b0) begin    //write
			     gke_cfg_state <= WRITE_C;
			  end
			  else begin                      //read
			     gke_cfg_state <= READ_C;
			  end
		   end
		   else begin
		      gke_cfg_state <= IDLE_C;
		   end
		
		end
		WRITE_C:begin
		   gke_cfg_state <= ACK_C;
		end
		READ_C:begin
		   gke_cfg_state <= WAIT_C;
		end
		WAIT_C:begin
		   gke_cfg_state <= ACK_C;
		end
		ACK_C:begin
		   case(cfg2gke_addr[9:2])
		       8'h0:begin
			      gke2cfg_rdata <= 32'b0;
			   end
			   8'h1:begin
			      gke2cfg_rdata <= gke_status;
			   end
			   8'h2:begin
			      gke2cfg_rdata <= 32'b0;
			   end
			   8'h3:begin
			      gke2cfg_rdata <= in_gke_md_count;
			   end
			   8'h4:begin
			      gke2cfg_rdata <= 32'b0;
			   end
			   8'h5:begin
			      gke2cfg_rdata <= in_gke_phv_count;
			   end
			   8'h6:begin
			      gke2cfg_rdata <= 32'b0;
			   end
			   8'h7:begin
			      gke2cfg_rdata <= out_gke_md_count;
			   end
			   8'h8:begin
			      gke2cfg_rdata <= 32'b0;
			   end
			   8'h9:begin
			      gke2cfg_rdata <= out_gke_phv_count;
			   end
			   8'ha:begin
			      gke2cfg_rdata <= 32'b0;
			   end
			   8'hb:begin
			      gke2cfg_rdata <= out_gke_key_count;
			   end
			   default:begin
			      gke2cfg_rdata <= 32'b0;
			   end
		   endcase
		   
		   if(gke_cs_n == 1'b1) begin
		      gke2cfg_ack_n <= 1'b0;
			  gke_cfg_state <= ACK_C;
		   end
		   else begin
		      gke2cfg_ack_n <= 1'b1;
			  gke_cfg_state <= IDLE_C;
		   end		   
		
		end
		default:begin
		   gke2cfg_ack_n <= 1'b1;
		   gke2cfg_rdata <= 32'b0;
		   gke_cfg_state <= IDLE_C;
		end
	  endcase
   end

end
     
endmodule

    