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

//clock signal
always begin
    #(CYCLE/2) clk = ~ clk;
end


parameter CYCLE = 10;

//reset signal
initial begin
    clk = 0;
    rst_n = 1;
    #(5);
    rst_n = 0;
    #(5);
    rst_n = 1;
end

initial begin
    # (2*CYCLE) 
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b0;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b010000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000002,32'h00010000};

    #CYCLE
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b0;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b100000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000000,32'h00010000};

    #CYCLE
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b0;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b010000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000003,32'h00010000};


    #CYCLE
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    in_scm_md = 256'b0;
    in_scm_md_wr = 1'b0;
    in_scm_phv_alf = 1'b0;
    gac2scm_sent_start = 1'b0;
    gac2scm_sent_end = 1'b0;
    cin_scm_data = {6'b100000,1'b1,3'b001,12'b0,8'd123,8'd7,32'h80000003,32'h00010000};


end
//*************************************************************************************
//check software signal

/*
//wr signal
initial begin
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    //# 180
    //cin_scm_data_wr = 1'b0;
    //cin_scm_ready = 1'b0;
end

//test software signal
initial begin
    cin_scm_data = {6'b010000, 128'hA0008007700000000000000000000082};
    # 20
    cin_scm_data = {6'b010000, 128'hA0008007700000010000000000000001};
    # 20
    cin_scm_data = {6'b010000, 128'hA0008007700000020000000000000030};
    # 20
    cin_scm_data = {6'b010000, 128'h90008007700000080000000000000300};
    # 20
    cin_scm_data = {6'b010000, 128'h90008007700000090000000000000003};
    # 20
    cin_scm_data = {6'b010000, 128'h900080077000000A0000000000000400};
    # 20
    cin_scm_data = {6'b010000, 128'h900080077000000B0000000000000004};
    # 20
    cin_scm_data = {6'b010000, 128'h900080077000000C0000000000000500};
    # 20
    cin_scm_data = {6'b010000, 128'h900080077000000D0000000000000005}; 
end
*/
//*************************************************************************************




//*************************************************************************************
//check state machine


///////////////////////////////////////////////////////////////////////
//IDLE_S
/*
//state: IDLE_S -> IDLE_S
//nothing

//state: IDLE_S -> SEND_S
/LMID:
initial begin 
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 80'd1};
    in_scm_phv = {1024'b0};
end
/Not LMID:
initial begin
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000101, 80'd1};
    in_scm_phv = {1024'b0};
end

//state: IDLE_S -> CNT_S
initial begin
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 80'd1};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
end
*/
///////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////
//SEND_S
/*
//state: SEND_S -> IDLE_S
initial begin 
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 80'd1};
    in_scm_phv = {1024'b0};
end
*/
///////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////
//CNT_S
/*
//state: CNT_S -> WAIT_S
initial begin
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 80'd1};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
    # 20
    gac2scm_sent_end = 1'b1;
end
*/

//state: CNT_S -> SEND_S
/*
/satisfy the required protocol
initial begin
    //control data
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000000000000000000082};
    //dataplane
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 72'b0};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
    gac2scm_sent_end = 1'b0;
end
/not satify the required protocol
initial begin
    //control data
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000000000000000000082};
    //dataplane
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000011, 72'b0};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
    gac2scm_sent_end = 1'b0;
end
*/
///////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////
//WAIT_S

//state: WAIT_S -> SEND_S
//state: WAIT_S -> FETCH_S
/*
initial begin
    //control data
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000000000000000000082};
    # 500
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000020000000000000030};
    //dataplane
    # 500
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 40'b0, 32'd10};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
    # 500
    gac2scm_sent_end = 1'b1;
    # 500
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 40'b0, 32'd80};
    in_scm_phv = {1024'b0};
end
*/
///////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////
//FETCH_S

//state: FETCH_S -> FETCH_S
/*
initial begin
    //control data
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000000000000000000082};
    # 500
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000020000000000000030};
    //dataplane
    # 500
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 40'b0, 32'd10};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
    # 500
    gac2scm_sent_end = 1'b1;
    # 500
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 40'b0, 32'd80};
    in_scm_phv = {1024'b0};
end
*/

//state: FETCH_S -> IDLE_S
/*
initial begin
    //control data
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000000000000000000082};
    # 500
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000020000000000000030};
    //dataplane
    # 500
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 40'b0, 32'd10};
    in_scm_phv = {1024'b0};
    gac2scm_sent_start = 1'b1;
    # 500
    gac2scm_sent_end = 1'b1;
    # 500
    in_scm_md_wr = 1'b1;
    in_scm_phv_wr = 1'b1;
    in_scm_md = {168'b0, 8'b00000111, 8'b10000010, 40'b0, 32'd80};
    in_scm_phv = {1024'b0};
    # 500
    cin_scm_data_wr = 1'b1;
    cin_scm_ready = 1'b1;
    cin_scm_data = {6'b010000, 128'hA0008007700000010000000000000001};
    # 50
    rst_n = 1'b0;
end
*/
///////////////////////////////////////////////////////////////////////





scm scm(
    .clk(clk),
    .rst_n(rst_n),

    .in_scm_md(in_scm_md),
    .in_scm_md_wr(in_scm_md_wr),
    .out_scm_md_alf(out_scm_md_alf),

    .in_scm_phv(in_scm_phv),
    .in_scm_phv_wr(in_scm_phv_wr),
    .out_scm_phv_alf(out_scm_phv_alf),

    .out_scm_md(out_scm_md),
    .out_scm_md_wr(out_scm_md_wr),
    .in_scm_md_alf(in_scm_md_alf),

    .out_scm_phv(out_scm_phv),
    .out_scm_phv_wr(out_scm_phv_wr),
    .in_scm_phv_alf(in_scm_phv_alf),

    .gac2scm_sent_start(gac2scm_sent_start),
    .gac2scm_sent_end(gac2scm_sent_end),

    .cin_scm_data(cin_scm_data),
    .cin_scm_data_wr(cin_scm_data_wr),
    .cout_scm_ready(cout_scm_ready),

    .cout_scm_data(cout_scm_data),
    .cout_scm_data_wr(cout_scm_data_wr),
    .cin_scm_ready(cin_scm_ready)
);

endmodule