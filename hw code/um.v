/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: um.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)user define module 
// 2)a sdn network demo
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/08/24
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 

module um #(
    parameter    PLATFORM = "Xilinx"
)(
    input clk,
    input [63:0] um_timestamp,
    input rst_n,
    
//cpu or port
    input  pktin_data_wr,
    input  [133:0] pktin_data,
    input  pktin_data_valid,
    input  pktin_data_valid_wr,
    output pktin_ready,//pktin_ready = um2port_alf
    
    output pktout_data_wr,
    output [133:0] pktout_data,
    output pktout_data_valid,
    output pktout_data_valid_wr,
    input pktout_ready,//pktout_ready = port2um_alf    

//control path
    input [133:0] dma2um_data,
    input dma2um_data_wr,
    output um2dma_ready,
    
    output [133:0] um2dma_data,
    output um2dma_data_wr,
    input dma2um_ready,
    
//to match
    output um2me_key_wr,
    output um2me_key_valid,
    output [511:0] um2match_key,
    input um2me_ready,//um2me_ready = ~match2um_key_alful
//from match
    input me2um_id_wr,
    input [15:0] match2um_id,
    output um2match_gme_alful,
//localbus
    input ctrl_valid,  
    input ctrl2um_cs_n,
    output reg um2ctrl_ack_n,
    input ctrl_cmd,//ctrl2um_rd_wr,//0 write 1:read
    input [31:0] ctrl_datain,//ctrl2um_data_in,
    input [31:0] ctrl_addr,//ctrl2um_addr,
    output reg [31:0] ctrl_dataout//um2ctrl_data_out
 
);
    
//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here

//GPP to Gke 
wire [255:0] gpp2gke_md;
wire gpp2gke_md_wr;
wire [1023:0] gpp2gke_phv;
wire gpp2gke_phv_wr;
wire gke2gpp_md_alf;
wire gke2gpp_phv_alf;

//GPP to Data_cache
wire gpp2data_cache_data_wr;
wire [133:0]gpp2data_cache_data;
wire gpp2data_cache_valid_wr;
wire gpp2data_cache_valid;
wire data_cache2gpp_alf;

//GKE to Gme
wire [255:0] gke2gme_md;
wire gke2gme_md_wr;
wire [1023:0] gke2gme_phv;
wire gke2gme_phv_wr;
wire [511:0] gke2gme_key;
wire gke2gme_key_wr;
wire gme2gke_key_alf;
wire gme2gke_md_alf;
wire gme2gke_phv_alf;

//Data_cache to GAC
wire data_cache2gac_data_wr;
wire [133:0] data_cache2gac_data;
wire data_cache2gac_valid_wr;
wire data_cache2gac_valid;
wire gac2data_cache_alf;

//GAC to GOE 
//wire [133:0] gac2goe_data;
//wire gac2goe_data_wr;
//wire [1023:0] gac2goe_phv;
//wire gac2goe_phv_wr;
//wire gac2goe_valid;
//wire gac2goe_valid_wr;
//wire goe2gac_alf;
//wire goe2gac_phv_alf;

//GAC to PGM
wire [133:0] gac2pgm_data;
wire gac2pgm_data_wr;
wire [1023:0] gac2pgm_phv;
wire gac2pgm_phv_wr;
wire gac2pgm_valid;
wire gac2pgm_valid_wr;
wire pgm2gac_alf;
wire pgm2gac_phv_alf;

//PGM to GOE
wire [133:0] pgm2goe_data;
wire pgm2goe_data_wr;
wire [1023:0] pgm2goe_phv;
wire pgm2goe_phv_wr;
wire pgm2goe_valid;
wire pgm2goe_valid_wr;
wire goe2pgm_alf;
wire goe2pgm_phv_alf;

//GME to SCM
wire [255:0] gme2scm_md;   
wire gme2scm_md_wr;
wire [1023:0] gme2scm_phv;
wire gme2scm_phv_wr;
wire scm2gme_md_alf;
wire scm2gme_phv_alf;

//SCM to GAC
wire [255:0] scm2gac_md;
wire scm2gac_md_wr;
wire [1023:0] scm2gac_phv;
wire scm2gac_phv_wr;
wire gac2scm_md_alf;
wire gac2scm_phv_alf;

//GME to GAC
//wire [255:0] gme2gac_md;
//wire gme2gac_md_wr;
//wire [1023:0] gme2gac_phv;
//wire gme2gac_phv_wr;
//wire gac2gme_md_alf;
//wire gac2gme_phv_alf;

//PGM to GAC flag
wire pgm2gac_sent_start_flag;
wire pgm2gac_sent_finish_flag;

//GAC to SCM flag
wire gac2scm_sent_start_flag;
wire gac2scm_sent_finish_flag;

//cmd
wire [133:0] cout_gpp_data;
wire cout_gpp_data_wr;
wire cin_gpp_ready;

wire [133:0] cout_gke_data;
wire cout_gke_data_wr;
wire cin_gke_ready;

wire [133:0] cout_gme_data;
wire cout_gme_data_wr;
wire cin_gme_ready;

wire [133:0] cout_scm_data;
wire cout_scm_data_wr;
wire cin_scm_ready;

wire [133:0] cout_gac_data;
wire cout_gac_data_wr;
wire cin_gac_ready;

wire [133:0] cout_pgm_data;
wire cout_pgm_data_wr;
wire cin_pgm_ready;

//localbus
//gpp
reg cfg2gpp_cs_n;
wire gpp2cfg_ack_n;
reg cfg2gpp_rw;
reg [31:0] cfg2gpp_addr;
reg [31:0] cfg2gpp_wdata;
wire [31:0] gpp2cfg_rdata;

//gke
reg cfg2gke_cs_n;
wire gke2cfg_ack_n;
reg cfg2gke_rw;
reg [31:0] cfg2gke_addr;
reg [31:0] cfg2gke_wdata;
wire [31:0] gke2cfg_rdata;

//data_cache
reg cfg2data_cache_cs_n;
wire data_cache2cfg_ack_n;
reg cfg2data_cache_rw;
reg [31:0] cfg2data_cache_addr;
reg [31:0] cfg2data_cache_wdata;
wire [31:0] data_cache2cfg_rdata;

//gme
reg cfg2gme_cs_n;
wire gme2cfg_ack_n;
reg cfg2gme_rw;
reg [31:0] cfg2gme_addr;
reg [31:0] cfg2gme_wdata;
wire [31:0] gme2cfg_rdata;

//gac
reg cfg2gac_cs_n;
wire gac2cfg_ack_n;
reg cfg2gac_rw;
reg [15:0] cfg2gac_addr;
reg [31:0] cfg2gac_wdata;
wire [31:0] gac2cfg_rdata;

//goe
reg cfg2goe_cs_n;
wire goe2cfg_ack_n;
reg cfg2goe_rw;
reg [31:0] cfg2goe_addr;
reg [31:0] cfg2goe_wdata;
wire [31:0] goe2cfg_rdata;


wire gac2cfg_ack;
assign gac2cfg_ack_n = ~gac2cfg_ack;


wire cfg_valid;

sync_sig sync_sig_inst(
    .clk(clk),
    .rst_n(rst_n),    
    .in_sig(~ctrl2um_cs_n),
    .out_sig(cfg_valid)
);

//***************************************************
//                  Lookup Cfg
//***************************************************
reg  [3:0]      cfg_state;

localparam      IDLE_S     = 4'd0,
                PARSE_S    = 4'd1,
                WAIT_ACK_S = 4'd2,
                RELEASE_S  = 4'd3;
				
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        um2ctrl_ack_n <= 1'b1;
        ctrl_dataout <= 32'b0;
		//gpp
        cfg2gpp_cs_n <= 1'b1; 
		cfg2gpp_rw <= 1'b0;
		cfg2gpp_wdata <= 32'b0;
		cfg2gpp_addr <= 32'b0;
		//data_cache
        cfg2data_cache_cs_n <= 1'b1; 
		cfg2data_cache_rw <= 1'b0;
		cfg2data_cache_wdata <= 32'b0;
		cfg2data_cache_addr <= 32'b0;
		//gke
        cfg2gke_cs_n <= 1'b1; 
		cfg2gke_rw <= 1'b0;
		cfg2gke_wdata <= 32'b0;
		cfg2gke_addr <= 32'b0;
		//gme
        cfg2gme_cs_n <= 1'b1; 
		cfg2gme_rw <= 1'b0;
		cfg2gme_wdata <= 32'b0;
		cfg2gme_addr <= 32'b0;
        //gac
        cfg2gac_cs_n <= 1'b1; 
		cfg2gac_rw <= 1'b0;
		cfg2gac_wdata <= 32'b0;
		cfg2gac_addr <= 16'b0;
		//goe
		cfg2goe_cs_n <= 1'b1;
		cfg2goe_rw <= 1'b0;
		cfg2goe_wdata <= 32'b0;
		cfg2goe_addr <= 32'b0;
				
        cfg_state <= IDLE_S;
    end
    else begin
        case(cfg_state)
            IDLE_S: begin
                um2ctrl_ack_n <= 1'b1;
				cfg2gpp_cs_n <= 1'b1;
				cfg2data_cache_cs_n <= 1'b1;
				cfg2gke_cs_n <= 1'b1;
				cfg2gme_cs_n <= 1'b1;
				cfg2gac_cs_n <= 1'b1;
				cfg2goe_cs_n <= 1'b1;
                if((cfg_valid == 1'b1) && ({data_cache2cfg_ack_n,gpp2cfg_ack_n,gke2cfg_ack_n,gme2cfg_ack_n,gac2cfg_ack_n,goe2cfg_ack_n} == 6'b111111)) begin
                    //gpp
					cfg2gpp_rw <= ctrl_cmd;
					cfg2gpp_addr <= ctrl_addr;
					cfg2gpp_wdata <= ctrl_datain;
                    //data_cache
					cfg2data_cache_rw <= ctrl_cmd;
					cfg2data_cache_addr <= ctrl_addr;
					cfg2data_cache_wdata <= ctrl_datain;
                    //gke
					cfg2gke_rw <= ctrl_cmd;
					cfg2gke_addr <= ctrl_addr;
					cfg2gke_wdata <= ctrl_datain;
					//gme
                    cfg2gme_rw <= ctrl_cmd;
                    cfg2gme_addr <= ctrl_addr;
                    cfg2gme_wdata <= ctrl_datain;
					//gac
                    cfg2gac_rw <= ctrl_cmd;
                    cfg2gac_addr <= ctrl_addr[15:0];
                    cfg2gac_wdata <= ctrl_datain;
					//goe
					cfg2goe_rw <= ctrl_cmd;
					cfg2goe_addr <= ctrl_addr;
					cfg2goe_wdata <= ctrl_datain;
  
                    cfg_state <= PARSE_S;
                end
                else begin
					cfg2gpp_rw <= cfg2gpp_rw;
					cfg2gpp_addr <= cfg2gpp_addr;
					cfg2gpp_wdata <= cfg2gpp_wdata;

					cfg2data_cache_rw <= cfg2data_cache_rw;
					cfg2data_cache_addr <= cfg2data_cache_addr;
					cfg2data_cache_wdata <= cfg2data_cache_wdata;

					cfg2gke_rw <= cfg2gke_rw;
					cfg2gke_addr <= cfg2gke_addr;
					cfg2gke_wdata <= cfg2gke_wdata;

                    cfg2gme_rw <= cfg2gme_rw;
                    cfg2gme_addr <= cfg2gme_addr;
                    cfg2gme_wdata <= cfg2gme_wdata;

                    cfg2gac_rw <= cfg2gac_rw;
                    cfg2gac_addr <= cfg2gac_addr;
                    cfg2gac_wdata <= cfg2gac_wdata;

					cfg2goe_rw <= cfg2goe_rw;
					cfg2goe_addr <= cfg2goe_addr;
					cfg2goe_wdata <= cfg2goe_wdata;

                    cfg_state <= IDLE_S;
                end
            end
            
            PARSE_S: begin
                case(ctrl_addr[15:13])                                                             
                    3'b000: begin cfg2data_cache_cs_n <= 1'b0; cfg_state <= WAIT_ACK_S; end  //data_cache
					3'b001: begin cfg2gpp_cs_n <= 1'b0; cfg_state <= WAIT_ACK_S; end  //gpp
                    3'b010: begin cfg2gke_cs_n <= 1'b0; cfg_state <= WAIT_ACK_S; end  //gke
					3'b011: begin cfg2gme_cs_n <= 1'b0; cfg_state <= WAIT_ACK_S; end  //gme
					3'b100: begin cfg2gac_cs_n <= 1'b0; cfg_state <= WAIT_ACK_S; end  //gac
					3'b101: begin cfg2goe_cs_n <= 1'b0; cfg_state <= WAIT_ACK_S; end  //goe
                    default: begin
					    cfg2gpp_cs_n <= 1'b1;
						cfg2data_cache_cs_n <= 1'b1;
					    cfg2gke_cs_n <= 1'b1; 
						cfg2gme_cs_n <= 1'b1;
						cfg2gac_cs_n <= 1'b1;
						cfg2goe_cs_n <= 1'b1;
						cfg_state <= RELEASE_S; 
					end
                endcase
				cfg_state <= WAIT_ACK_S;
            end
            
            WAIT_ACK_S: begin
                if((&{data_cache2cfg_ack_n,gpp2cfg_ack_n,gke2cfg_ack_n,gme2cfg_ack_n,gac2cfg_ack_n,goe2cfg_ack_n}) == 1'b0)begin
                    cfg2gpp_cs_n <= 1'b1;				
                    cfg2data_cache_cs_n <= 1'b1;
					cfg2gke_cs_n <= 1'b1;
					cfg2gme_cs_n <= 1'b1;
					cfg2gac_cs_n <= 1'b1;
					cfg2goe_cs_n <= 1'b1;
                    casez({cfg2data_cache_cs_n,cfg2gpp_cs_n,cfg2gke_cs_n,cfg2gme_cs_n,cfg2gac_cs_n,cfg2goe_cs_n})
					    6'b0?????: ctrl_dataout <= data_cache2cfg_rdata;      //data_cache
						6'b10????: ctrl_dataout <= gpp2cfg_rdata;             //gpp			
						6'b110???: ctrl_dataout <= gke2cfg_rdata;             //gke
						6'b1110??: ctrl_dataout <= gme2cfg_rdata;             //gme
						6'b11110?: ctrl_dataout <= gac2cfg_rdata;             //gac
						6'b111110: ctrl_dataout <= goe2cfg_rdata;             //goe
                        default:   ctrl_dataout <= ctrl_dataout;
                    endcase
                    cfg_state <= RELEASE_S;
                end
                else begin
				    cfg2gpp_cs_n <= cfg2gpp_cs_n;
					cfg2data_cache_cs_n <= cfg2data_cache_cs_n;
					cfg2gke_cs_n <= cfg2gke_cs_n;
                    cfg2gme_cs_n <= cfg2gme_cs_n;
					cfg2gac_cs_n <= cfg2gac_cs_n;
					cfg2goe_cs_n <= cfg2goe_cs_n;			
                    cfg_state <= WAIT_ACK_S;
                end
            end
            
            RELEASE_S: begin
                if(cfg_valid == 1'b1) begin
                    um2ctrl_ack_n <= 1'b0;
                    cfg_state <= RELEASE_S;
                end
                else begin
                    um2ctrl_ack_n <= 1'b1;
                    cfg_state <= IDLE_S;
                end
            end
            
            default: begin
                um2ctrl_ack_n <= 1'b1;
                ctrl_dataout <= 32'b0;
		        //gpp
                cfg2gpp_cs_n <= 1'b1; 
		        cfg2gpp_rw <= 1'b0;
		        cfg2gpp_wdata <= 32'b0;
		        cfg2gpp_addr <= 32'b0;
		        //data_cache
                cfg2data_cache_cs_n <= 1'b1; 
		        cfg2data_cache_rw <= 1'b0;
		        cfg2data_cache_wdata <= 32'b0;
		        cfg2data_cache_addr <= 32'b0;
		        //gke
                cfg2gke_cs_n <= 1'b1; 
		        cfg2gke_rw <= 1'b0;
		        cfg2gke_wdata <= 32'b0;
		        cfg2gke_addr <= 32'b0;
		        //gme
                cfg2gme_cs_n <= 1'b1; 
		        cfg2gme_rw <= 1'b0;
		        cfg2gme_wdata <= 32'b0;
		        cfg2gme_addr <= 32'b0;
                //gac
                cfg2gac_cs_n <= 1'b1; 
		        cfg2gac_rw <= 1'b0;
		        cfg2gac_wdata <= 32'b0;
		        cfg2gac_addr <= 16'b0;
		        //goe
		        cfg2goe_cs_n <= 1'b1;
		        cfg2goe_rw <= 1'b0;
		        cfg2goe_wdata <= 32'b0;
		        cfg2goe_addr <= 32'b0;
				
                cfg_state <= IDLE_S;
            end
        endcase
    end
end



//***************************************************
//                  Module Instance
//***************************************************
//likely fifo/ram/async block.... 
//should be instantiated below here 
gpp #(
    .PLATFORM(PLATFORM),
    .LMID(1),
	.NMID(2)
    )gpp(
    .clk(clk),
    .rst_n(rst_n), 
//input pkt from port
    .pktin_data_wr(pktin_data_wr),
    .pktin_data(pktin_data),
    .pktin_valid_wr(pktin_data_valid_wr),
    .pktin_data_valid(pktin_data_valid),
    .pktin_ready(pktin_ready),
//parse key which transmit to gke
    .out_gpp_phv(gpp2gke_phv),
	.out_gpp_phv_wr(gpp2gke_phv_wr),
	.in_gpp_phv_alf(gke2gpp_phv_alf),
	
    .out_gpp_md(gpp2gke_md),
    .out_gpp_md_wr(gpp2gke_md_wr),
    .in_gpp_md_alf(gke2gpp_md_alf),	
//transport to next module
    .out_gpp_data_wr(gpp2data_cache_data_wr),
    .out_gpp_data(gpp2data_cache_data),
    .out_gpp_valid_wr(gpp2data_cache_valid_wr),
    .out_gpp_valid(gpp2data_cache_valid),
	.in_gpp_data_alf(data_cache2gpp_alf),
	
//localbus to gpp
    .cfg2gpp_cs_n(cfg2gpp_cs_n),
	.gpp2cfg_ack_n(gpp2cfg_ack_n),
	.cfg2gpp_rw(cfg2gpp_rw),
	.cfg2gpp_addr(cfg2gpp_addr),
	.cfg2gpp_wdata(cfg2gpp_wdata),
	.gpp2cfg_rdata(gpp2cfg_rdata),
	
	.cin_gpp_data(dma2um_data),
	.cin_gpp_data_wr(dma2um_data_wr),
	.cout_gpp_ready(um2dma_ready),
	
	.cout_gpp_data(cout_gpp_data),
	.cout_gpp_data_wr(cout_gpp_data_wr),
	.cin_gpp_ready(cin_gpp_ready)
);

data_cache #(
	.PLATFORM(PLATFORM)
) data_cache(
    .clk(clk),
    .rst_n(rst_n),
// ----------- store pkt from gpp-------- 
    .in_data_cache_data_wr(gpp2data_cache_data_wr),
    .in_data_cache_data(gpp2data_cache_data),
    .in_data_cache_valid(gpp2data_cache_valid),
    .in_data_cache_valid_wr(gpp2data_cache_valid_wr),
    .out_data_cache_alf(data_cache2gpp_alf),
// ----------- Trans to gac module--------  
    .out_data_cache_data_wr(data_cache2gac_data_wr),
    .out_data_cache_data(data_cache2gac_data),
    .out_data_cache_valid(data_cache2gac_valid),
    .out_data_cache_valid_wr(data_cache2gac_valid_wr),
    .in_data_cache_alf(gac2data_cache_alf),
	
//localbus to data_cache
    .cfg2data_cache_cs_n(cfg2data_cache_cs_n),
	.data_cache2cfg_ack_n(data_cache2cfg_ack_n),
	.cfg2data_cache_rw(cfg2data_cache_rw),
	.cfg2data_cache_addr(cfg2data_cache_addr),
	.cfg2data_cache_wdata(cfg2data_cache_wdata),
	.data_cache2cfg_rdata(data_cache2cfg_rdata)
);

gke #(
    .PLATFORM(PLATFORM),
    .LMID(2),
	.NMID(3)
    )gke (
    .clk(clk),
    .rst_n(rst_n),
//********************************
    .in_gke_md(gpp2gke_md),
	.in_gke_md_wr(gpp2gke_md_wr),
    .out_gke_md_alf(gke2gpp_md_alf),
	
    .in_gke_phv(gpp2gke_phv),
    .in_gke_phv_wr(gpp2gke_phv_wr),
	.out_gke_phv_alf(gke2gpp_phv_alf),
	
//********************************
    .out_gke_key_wr(gke2gme_key_wr),
	.out_gke_key(gke2gme_key),	 
	.in_gke_key_alf(gme2gke_key_alf),
	
    .out_gke_md(gke2gme_md),
	.out_gke_md_wr(gke2gme_md_wr),
	.in_gke_md_alf(gme2gke_md_alf),
	
    .out_gke_phv(gke2gme_phv),
	.out_gke_phv_wr(gke2gme_phv_wr),   
	.in_gke_phv_alf(gme2gke_phv_alf),
	
//localbus to gke
    .cfg2gke_cs_n(cfg2gke_cs_n),
	.gke2cfg_ack_n(gke2cfg_ack_n),
	.cfg2gke_rw(cfg2gke_rw),
	.cfg2gke_addr(cfg2gke_addr),
	.cfg2gke_wdata(cfg2gke_wdata),
	.gke2cfg_rdata(gke2cfg_rdata),
	
	.cin_gke_data(cout_gpp_data),
	.cin_gke_data_wr(cout_gpp_data_wr),
	.cout_gke_ready(cin_gpp_ready),
	
	.cout_gke_data(cout_gke_data),
	.cout_gke_data_wr(cout_gke_data_wr),
	.cin_gke_ready(cin_gke_ready)
); 

gme #(
    .PLATFORM(PLATFORM),
    .LMID(3),
	.NMID(4)
    )gme (
    .clk(clk),
    .rst_n(rst_n),
//********************************
    .in_gme_key(gke2gme_key),
	.in_gme_key_wr(gke2gme_key_wr),
    .out_gme_key_alf(gme2gke_key_alf),
	
    .in_gme_md(gke2gme_md),
	.in_gme_md_wr(gke2gme_md_wr),   
	.out_gme_md_alf(gme2gke_md_alf),
	
    .in_gme_phv(gke2gme_phv),
	.in_gme_phv_wr(gke2gme_phv_wr),	     
	.out_gme_phv_alf(gme2gke_phv_alf),
//********************************
    .out_gme_md(gme2scm_md),
	.out_gme_md_wr(gme2scm_md_wr),
	.in_gme_md_alf(scm2gme_md_alf),
	
    .out_gme_phv(gme2scm_phv),
	.out_gme_phv_wr(gme2scm_phv_wr),
	.in_gme_phv_alf(scm2gme_phv_alf),
//transport key to lookup      
    .out_gme_key_wr(um2me_key_wr),  
    .out_gme_key(um2match_key),
    .in_gme_key_alf(~um2me_ready), 
//lookup rule read index
    .in_gme_index_wr(me2um_id_wr),
    .in_gme_index(match2um_id),
	.out_gme_index_alf(um2match_gme_alful),
	
//localbus to gme
    .cfg2gme_cs_n(cfg2gme_cs_n),
	.gme2cfg_ack_n(gme2cfg_ack_n),
	.cfg2gme_rw(cfg2gme_rw),
	.cfg2gme_addr(cfg2gme_addr),
	.cfg2gme_wdata(cfg2gme_wdata),
	.gme2cfg_rdata(gme2cfg_rdata),
	
	.cin_gme_data(cout_gke_data),
	.cin_gme_data_wr(cout_gke_data_wr),
	.cout_gme_ready(cin_gke_ready),
	
	.cout_gme_data(cout_gme_data),
	.cout_gme_data_wr(cout_gme_data_wr),
	.cin_gme_ready(cin_gme_ready)
);

scm #(
    .PLATFORM(PLATFORM),
    .LMID(7),
    .NMID(5)
)scm (
    .clk(clk),
    .rst_n(rst_n),

        //receive from gme
    .in_scm_md(gme2scm_md),
    .in_scm_md_wr(gme2scm_md_wr),
    .out_scm_md_alf(scm2gme_md_alf),

    .in_scm_phv(gme2scm_phv),
    .in_scm_phv_wr(gme2scm_phv_wr),
    .out_scm_phv_alf(scm2gme_phv_alf),

    //transport to next module
    .out_scm_md(scm2gac_md),
    .out_scm_md_wr(scm2gac_md_wr),
    .in_scm_md_alf(gac2scm_md_alf),

    .out_scm_phv(scm2gac_phv),
    .out_scm_phv_wr(scm2gac_phv_wr),
    .in_scm_phv_alf(gac2scm_phv_alf),

    //start or end signal
    .gac2scm_sent_start(gac2scm_sent_start_flag),
    .gac2scm_sent_end(gac2scm_sent_finish_flag),
    
    //input configure pkt from DMA
    .cin_scm_data(cout_gme_data),
    .cin_scm_data_wr(cout_gme_data_wr),
    .cout_scm_ready(cin_gme_ready),

    //output configure pkt to next module
    .cout_scm_data(cout_scm_data),
    .cout_scm_data_wr(cout_scm_data_wr),
    .cin_scm_ready(cin_scm_ready)

);
    
gac #(
	.PLATFORM(PLATFORM),
    .LMID(4),
	.NMID(5)
)gac (
    .clk(clk),
    .rst_n(rst_n),
    
    .sys_max_cpuid(6'd8),
//************************************	 
    .in_gac_md(scm2gac_md),
	.in_gac_md_wr(scm2gac_md_wr),
	.out_gac_md_alf(scm2gme_md_alf),
	
    .in_gac_phv(scm2gac_phv),
	.in_gac_phv_wr(scm2gac_phv_wr),   
	.out_gac_phv_alf(gac2scm_phv_alf),	
	 
//Pkt waiting for rule 
    .in_gac_data_wr(data_cache2gac_data_wr),
    .in_gac_data(data_cache2gac_data),
    .in_gac_valid_wr(data_cache2gac_valid_wr),
    .in_gac_valid(data_cache2gac_valid),
    .out_gac_data_alf(gac2data_cache_alf),
	
//user cfg require
    .cfg2gac_cs(~cfg2gac_cs_n),//high active
    .gac2cfg_ack(gac2cfg_ack),//high active,handshake with cfg2rule_cs
    .cfg2gac_rw(cfg2gac_rw),//0 write 1:read
    .cfg2gac_addr(cfg2gac_addr),
    .cfg2gac_wdata(cfg2gac_wdata),
    .gac2cfg_rdata(gac2cfg_rdata),	
	 
//************************************
    .out_gac_data(gac2pgm_data),
    .out_gac_data_wr(gac2pgm_data_wr),
    .out_gac_valid(gac2pgm_valid),
	.out_gac_valid_wr(gac2pgm_valid_wr),
	.in_gac_alf(pgm2gac_alf),
	
	.out_gac_phv(gac2pgm_phv),
	.out_gac_phv_wr(gac2pgm_phv_wr),
	.in_gac_phv_alf(pgm2gac_phv_alf),
	
	.cin_gac_data(cout_scm_data),
	.cin_gac_data_wr(cout_scm_data_wr),
	.cout_gac_ready(cin_scm_ready),
	
	.cout_gac_data(cout_gac_data),
	.cout_gac_data_wr(cout_gac_data_wr),
	.cin_gac_ready(cin_gac_ready),

    .in_gac_sent_start_flag(pgm2gac_sent_start_flag),
    .in_gac_sent_finish_flag(pgm2gac_sent_finish_flag),
    .out_gac_sent_start_flag(gac2scm_sent_start_flag),
    .out_gac_sent_finish_flag(gac2scm_sent_finish_flag)
);


pgm #(
    .PLATFORM(PLATFORM),
    .LMID(6),
    .NMID(5)
)pgm(
    .clk(clk),
    .rst_n(rst_n),

//waiting for pkt
    .in_pgm_data_wr(gac2pgm_data_wr),
    .in_pgm_data(gac2pgm_data), 
    .in_pgm_valid_wr(gac2pgm_valid_wr),
    .in_pgm_valid(gac2pgm_valid),
    .out_pgm_alf(pgm2gac_alf),

//receive from gac

    .in_pgm_phv(gac2pgm_phv),
    .in_pgm_phv_wr(gac2pgm_phv_wr),
    .out_pgm_phv_alf(pgm2gac_phv_alf),

//transmit to next module (goe)
    
    .out_pgm_data(pgm2goe_data),
    .out_pgm_data_wr(pgm2goe_data_wr),
    .out_pgm_valid_wr(pgm2goe_valid_wr),
    .out_pgm_valid(pgm2goe_valid),
    .in_pgm_alf(pgm2gac_alf),

    .out_pgm_phv(pgm2goe_phv),
    .out_pgm_phv_wr(pgm2goe_phv_wr),
    .in_pgm_phv_alf(goe2pgm_phv_alf),


//alf to GAC
    .out_pgm_sent_start_flag(pgm2gac_sent_start_flag),
    .out_pgm_sent_finish_flag(pgm2gac_sent_finish_flag),



//input configuree pkt from DMA
    .cin_pgm_data(cout_gac_data),
    .cin_pgm_data_wr(cout_gac_data_wr),
    .cout_pgm_ready(cin_gac_ready),

//output configure pkt to next module
    .cout_pgm_data(cout_pgm_data),
    .cout_pgm_data_wr(cout_pgm_data_wr),
    .cin_pgm_ready(cin_pgm_ready)
);


goe #(
    .PLATFORM(PLATFORM),
    .LMID(5)
)goe(
    .clk(clk),
    .rst_n(rst_n),
//gac module's pkt waiting for transmit
    .in_goe_data(pgm2goe_data),
    .in_goe_data_wr(pgm2goe_data_wr),
	.in_goe_valid(pgm2goe_valid),
    .in_goe_valid_wr(pgm2goe_valid_wr),
	.out_goe_alf(goe2pgm_alf),
	
	.in_goe_phv(pgm2goe_phv),
	.in_goe_phv_wr(pgm2goe_phv_wr),
	.out_goe_phv_alf(goe2pgm_phv_alf),
//transmit to down port
    .pktout_data_wr(pktout_data_wr),
    .pktout_data(pktout_data),
    .pktout_data_valid_wr(pktout_data_valid_wr),
    .pktout_data_valid(pktout_data_valid),
    .pktout_ready(pktout_ready),

//localbus to goe	
	.cfg2goe_cs_n(cfg2goe_cs_n),
	.goe2cfg_ack_n(goe2cfg_ack_n),
	.cfg2goe_rw(cfg2goe_rw),
	.cfg2goe_addr(cfg2goe_addr),
	.cfg2goe_wdata(cfg2goe_wdata),
	.goe2cfg_rdata(goe2cfg_rdata),
	
	.cin_goe_data(cout_pgm_data),
	.cin_goe_data_wr(cout_pgm_data_wr),
	.cout_goe_ready(cin_pgm_ready),
	
	.cout_goe_data(um2dma_data),
	.cout_goe_data_wr(um2dma_data_wr),
	.cin_goe_ready(dma2um_ready)
	
);

endmodule    