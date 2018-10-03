`timescale 1ns/1ps

module tb_um();

reg clk;
reg [63:0] um_timestamp;
reg rst_n;

//cpu or port
reg pktin_data_wr;
reg [133:0] pktin_data;
reg pktin_data_valid;
reg pktin_data_valid_wr;
wire pktin_ready;

wire pktout_data_wr;
wire [133:0] pktout_data;
wire pktout_data_valid;
wire pktout_data_valid_wr;
reg pktout_ready;

//control path
reg [133:0] dma2um_data;
reg dma2um_data_wr;
wire um2dma_ready;

wire [133:0] um2dma_data;
wire um2dma_data_wr;
reg dma2um_ready;

//to match
wire um2me_key_wr;
wire um2me_key_valid;
wire [511:0] um2match_key;
reg um2me_ready;
//from match
reg me2um_id_wr;
reg [15:0] match2um_id;
wire um2match_gme_alful;
//localbus
reg ctrl_valid;
reg ctrl2um_cs_n;
wire um2ctrl_ack_n;
reg ctrl_cmd;
reg [31:0] ctrl_datain;
reg [31:0] ctrl_addr;
wire [31:0] ctrl_dataout;


//*************************************************************************************
//clock signal
initial begin
    clk = 1'b0;
    forever # 5 clk = ~clk;
end
//*************************************************************************************


//*************************************************************************************
//reset signal
initial begin
    rst_n = 1'b0;
    # 200
    rst_n = 1'b1;
end
//*************************************************************************************


//*************************************************************************************
//test the control path

/*
//software write signal into reg protocol_type
initial begin
    dma2um_data = {6'b010000, 128'hA0008007700000000000000000000082};
    dma2um_data_wr = 1'b1;
    dma2um_ready = 1'b1;
end

//software write signal into reg statistic_reset
initial begin
    dma2um_data = {6'b010000, 128'hA0008007700000010000000000000001};
    dma2um_data_wr = 1'b1;
    dma2um_ready = 1'b1;
end

//software write signal into reg n_RTT
initial begin
    dma2um_data = {6'b010000, 128'hA0008007700000020000000000000030};
    dma2um_data_wr = 1'b1;
    dma2um_ready = 1'b1;
end
*/
//software fetch signal from reg scm_bit_num_cnt
//software fetch signal from reg scm_pkt_num_cnt
//software fetch signal from reg scm_time_cnt
initial begin
    dma2um_data = {6'b010000, 128'hA0008007700000000000000000000082};
    dma2um_data_wr = 1'b1;
    dma2um_ready = 1'b1;
    # 500
    dma2um_data = {6'b010000, 128'hA0008007700000020000000000000030};
    dma2um_data_wr = 1'b1;
    dma2um_ready = 1'b1;
    # 500
    pktin_data = {};
    pktin_data_wr = 1'b1;
    pktin_data_valid = 1'b1;
    pktin_data_valid_wr = 1'b1;
end

//*************************************************************************************

um um(
    .clk(clk),
    .um_timestamp(um_timestamp),
    .rst_n(rst_n),

    .pktin_data_wr(pktin_data_wr),
    .pktin_data(pktin_data),
    .pktin_data_valid(pktin_data_valid),
    .pktin_data_valid_wr(pktin_data_valid_wr),
    .pktin_ready(pktin_ready),

    .dma2um_data(dma2um_data),
    .dma2um_data_wr(dma2um_data_wr),
    .um2dma_ready(um2dma_ready),
    .um2dma_data(um2dma_data),
    .um2dma_data_wr(um2dma_data_wr),
    .dma2um_ready(dma2um_ready),

    .um2me_key_wr(um2me_key_wr),
    .um2me_key_valid(um2me_key_valid),
    .um2match_key(um2match_key),
    .um2me_ready(um2me_ready),

    .me2um_id_wr(me2um_id_wr),
    .match2um_id(match2um_id),
    .um2match_gme_alful(um2match_gme_alful),

    .ctrl_valid(ctrl_valid),
    .ctrl2um_cs_n(ctrl2um_cs_n),
    .um2ctrl_ack_n(um2ctrl_ack_n),
    .ctrl_cmd(ctrl_cmd),
    .ctrl_datain(ctrl_datain),
    .ctrl_addr(ctrl_addr),
    .ctrl_dataout(ctrl_dataout)
);

endmodule