`timescale 1ns/1ps

module scm_tb();

reg clk;
reg rst_n;

reg [255:0] in_scm_md;
reg in_scm_md_wr;
wire out_scm_md_alf;

reg [1023:0] in_scm_phv;
reg in_scm_phv_wr;
wire out_scm_phv_alf;

wire [255:0] out_scm_md;
wire out_scm_md_wr;
reg in_scm_md_alf;

wire [1023:0] out_scm_phv;
wire out_scm_phv_wr;
reg in_scm_phv_alf;

reg gac2scm_sent_start;
reg gac2scm_sent_end;

reg [133:0] cin_scm_data;
reg cin_scm_data_wr;
wire cout_scm_ready;

wire [133:0] cout_scm_data;
wire cout_scm_data_wr;
reg cin_scm_ready;
reg [31:0] um2scm_timestamp;

//clock signal

parameter CYCLE = 10;

always begin
    #(CYCLE/2) clk = ~ clk;
end



//reset signal
initial begin
    clk = 0;
    rst_n = 1;
    #(10);
    rst_n = 0;
    #(10);
    rst_n = 1;
end


initial begin 
    #(2*CYCLE)

    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b0;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b010000,1'b1,3'b010,12'b0,8'd123,8'd7,32'h70000003,32'b1,32'he0};

    #CYCLE
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b1;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b100000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000000,32'b0,32'h00010000};
    
    #CYCLE;
    um2scm_timestamp = 32'h1;
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'he0,72'd1};
    in_scm_phv = {1000'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 24'heee1};
    cin_scm_data = 134'b0;
    cin_scm_data_wr = 1'b0;

    #CYCLE
    um2scm_timestamp = 32'heee1;
    in_scm_md_wr = 1'b0;
    in_scm_phv_wr = 1'b0;
    in_scm_md = 256'b0;
    in_scm_phv = 1024'b0;

    #CYCLE
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b1;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b010000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000003,32'b1,32'he0};

    #CYCLE
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b1;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b100000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000000,32'b0,32'h00010000};
    
    #CYCLE;
    um2scm_timestamp = 32'h1;
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'he0,72'd1};
    in_scm_phv = {438'b0, 10'b1, 32'heee1};
    cin_scm_data = 134'b0;
    cin_scm_data_wr = 1'b0;
    
    #CYCLE
    um2scm_timestamp = 32'heee1;
    in_scm_md_wr = 1'b0;
    in_scm_phv_wr = 1'b0;
    in_scm_md = 256'b0;
    in_scm_phv = 1024'b0;


    #(10*CYCLE);

    $finish;
end



scm scm(
    .clk(clk),
    .rst_n(rst_n),

    //receive from gme
    .in_scm_md(in_scm_md),
    .in_scm_md_wr(in_scm_md_wr),
    .out_scm_md_alf(out_scm_md_alf),

    .in_scm_phv(in_scm_phv),
    .in_scm_phv_wr(in_scm_phv_wr),
    .out_scm_phv_alf(out_scm_phv_alf),

    //transport to next module
    .out_scm_md(out_scm_md),
    .out_scm_md_wr(out_scm_md_wr),
    .in_scm_md_alf(in_scm_md_alf),

    .out_scm_phv(out_scm_phv),
    .out_scm_phv_wr(out_scm_phv_wr),
    .in_scm_phv_alf(in_scm_phv_alf),

    //start or end signal
    .gac2scm_sent_start(gac2scm_sent_start),
    .gac2scm_sent_end(gac2scm_sent_end),
    
    //input configure pkt from DMA
    .cin_scm_data(cin_scm_data),
    .cin_scm_data_wr(cin_scm_data_wr),
    .cout_scm_ready(cout_scm_ready),

    //output configure pkt to next module
    .cout_scm_data(cout_scm_data),
    .cout_scm_data_wr(cout_scm_data_wr),
    .cin_scm_ready(cin_scm_ready),

    //UM to SCM timestamp
    .um2scm_timestamp(um2scm_timestamp)
);

endmodule