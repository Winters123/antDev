/** *************************************************************************
 *  @file          scm.v
 *  @brief		硬件统计模块
 * 
 *   此文件包括对测试报文信息的统计和
 * 
 *  @date		2018/10/24 10:53:51 星期三
 *  @author		Jiang(Copyright  2018  JInag Yue)
 *  @email		<lang_jy@outlook.com>
 *  @version	0.1.0
 ****************************************************************************/
module scm #(
    parameter PLATFORM = "Xilinx",
              LMID = 8'd7,
              NMID = 8'd5
)(
    input clk,
    input rst_n,

    //receive from gme
    input [255:0] in_scm_md,
    input in_scm_md_wr,
    output wire out_scm_md_alf,

    input [1023:0] in_scm_phv,
    input in_scm_phv_wr,
    output wire out_scm_phv_alf,

    //transport to next module
    output reg [255:0] out_scm_md,
    output reg out_scm_md_wr,
    input in_scm_md_alf,

    output reg [1023:0] out_scm_phv,
    output reg out_scm_phv_wr,
    input in_scm_phv_alf,

    //start or end signal
    input gac2scm_sent_start,
    input gac2scm_sent_end,
    
    //input configure pkt from DMA
    input [133:0] cin_scm_data,
    input cin_scm_data_wr,
    output cout_scm_ready,

    //output configure pkt to next module
    output reg [133:0] cout_scm_data,
    output reg cout_scm_data_wr,
    input cin_scm_ready
);

//**************************************************
//        Intermediate variable Declaration
//**************************************************
//all wire/ref/parameter variable
//should be declared below here
reg [31:0] scm_status;
reg [31:0] in_scm_md_count;
reg [31:0] in_scm_phv_count;
reg [31:0] out_scm_md_count;
reg [31:0] out_scm_phv_count;

reg MD_fifo_rd;
wire [255:0] MD_fifo_rdata;
wire MD_fifo_empty;
wire [7:0] MD_fifo_usedw;

reg PHV_fifo_rd;
wire [1023:0] PHV_fifo_rdata;
wire [7:0] PHV_fifo_usedw;
wire PHV_fifo_empty;

//**************************************************
//                Counters Declaration
//**************************************************
reg [63:0] scm_bit_num_cnt;
reg [63:0] scm_pkt_num_cnt;
reg [63:0] scm_time_cnt;

//**************************************************
//             Software Signal Declaration
//**************************************************
reg [7:0] protocol_type;
reg statistic_reset;
reg [31:0] n_RTT;

reg ctl_write_flag; //if its a read signal or write signal that the destination isn't self, we set the flag as 0, else we set it as 1

assign out_scm_md_alf = in_scm_md_alf || (MD_fifo_usedw > 8'd250);
assign out_scm_phv_alf = in_scm_phv_alf || (MD_fifo_usedw > 8'd250);
/*
assign cout_scm_data_wr = cin_scm_data_wr;
assign cout_scm_data = cin_scm_data;
*/
assign cout_scm_ready = cin_scm_ready;

reg md_flag;
reg record_endtime_tag;
reg [2:0] scm_state;
reg [31:0] last_timestamp;
reg [31:0] end_time;
reg [255:0] out_scm_md_reg;

//State Declaration
localparam IDLE_S   = 3'd0,
           SEND_S   = 3'd1,
           CNT_S    = 3'd2,
           WAIT_S   = 3'd3,
           FETCH_S  = 3'd4;
//Protocol Declaration
localparam IPv4_TCP     = 3'b000,
           IPv4_UDP     = 3'b001,
           ARP          = 3'b010,
           IPv6_TCP     = 3'b011,
           IPv6_UDP     = 3'b100,
           IPv6_LISP    = 3'b101;

//**************************************************
//                Software Signal
//**************************************************
always @(posedge clk) begin

    if (cin_scm_data_wr == 1'b1 && cin_scm_data[133:132] == 2'b01) begin
        if ((cin_scm_data[126:124] == 3'b010) && (cin_scm_data[103:96] == 8'd7)&& (rst_n==1'b1) && (statistic_reset==1'b0)) begin
                ctl_write_flag <= 1'b1;
                case (cin_scm_data[95:64])
                    32'h70000000: begin
                        protocol_type <= cin_scm_data[7:0];
                    end

                    32'h70000001: begin
                        statistic_reset <= cin_scm_data[0];
                    end

                    32'h70000002: begin
                        n_RTT <= cin_scm_data[31:0];
                    end
                endcase
                cout_scm_data <= 134'b0;
                cout_scm_data_wr <= 1'b0;
                
        end
        else if ((cin_scm_data[126:124] == 3'b001) && (cin_scm_data[103:96]== 8'd7)) begin

                ctl_write_flag <= 1'b0;
                
                cout_scm_data_wr <= cin_scm_data_wr;
                
                case (cin_scm_data[95:64])
                    32'h70000008: begin
                        cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], scm_bit_num_cnt[31:0]};
                    end

                    32'h70000009 :begin
                        cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], scm_bit_num_cnt[63:32]};
                    end

                    32'h7000000A: begin
                        cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], scm_pkt_num_cnt[31:0]};
                    end

                    32'h7000000B: begin
                        cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], scm_pkt_num_cnt[63:32]};
                    end

                    32'h7000000C: begin
                        cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], scm_time_cnt[31:0]};
                    end

                    32'h7000000D: begin
                        cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], scm_time_cnt[63:32]};
                    end

                    default: begin
                        cout_scm_data <= cin_scm_data;
                    end
                endcase

        end
        else if (cin_scm_ready == 1'b1) begin
            ctl_write_flag <= 1'b0;
            cout_scm_data <= cin_scm_data;
            cout_scm_data_wr <= cin_scm_data_wr;
        end
    end

    else if (cin_scm_data_wr == 1'b1 && cin_scm_data[133:132] == 2'b10) begin
        if (ctl_write_flag == 1'b0) begin
            cout_scm_data <= cin_scm_data;
            cout_scm_data_wr <= cin_scm_data_wr;
        end
        else begin
            cout_scm_data_wr <= 1'b0;
            cout_scm_data <= 134'b0;
            ctl_write_flag <= 1'b0;
        end

    end
    else begin
        cout_scm_data <= 134'b0;
        cout_scm_data_wr <= 1'b0;
    end

end

//**************************************************
//                Transport MD & PHV
//**************************************************
always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0 || statistic_reset == 1'b1) begin
        out_scm_md <= 256'b0;
        out_scm_md_wr <= 1'b0;
        out_scm_phv <= 1024'b0;
        out_scm_phv_wr <= 1'b0;
        scm_bit_num_cnt <= 64'b0;
        scm_pkt_num_cnt <= 64'b0;
        scm_time_cnt <= 64'b0;
        last_timestamp <= 32'b0;
        end_time <= 32'b0;
        //protocol_type <= 8'b0;
        //statistic_reset <= 1'b0;
        //nRTT <= 32'b0;
        md_flag <= 1'b0;
        record_endtime_tag <= 1'b0;
        out_scm_md_reg <= 256'b0;
        scm_state <= IDLE_S;

        //protocol_type <= 8'b0;
        //statistic_reset <= 1'b0;
        //n_RTT <= 32'b0;

        //ctl_write_flag <= 1'b0;
    end
    else begin
        case (scm_state)
            IDLE_S: begin
                out_scm_md <= 256'b0;
                out_scm_md_wr <= 1'b0;
                out_scm_phv <= 1024'b0;
                out_scm_phv_wr <= 1'b0;
                if ((MD_fifo_empty == 1'b0) && (PHV_fifo_empty == 1'b0)) begin
                    if (MD_fifo_rdata[87:80] == LMID) begin
                        MD_fifo_rd <= 1'b1;
                        PHV_fifo_rd <= 1'b1;
                        out_scm_md_reg <= {MD_fifo_rdata[255:88], NMID, MD_fifo_rdata[79:0]};
                        if (gac2scm_sent_start == 1'b1) begin  //start to statistic
                            scm_state <= CNT_S;
                        end
                        else begin  //no need to statistic, just modify NMID and trans
                            md_flag <= 1'b1;
                            scm_state <= SEND_S;
                        end
                    end
                    else begin  //just bypass
                        MD_fifo_rd <= 1'b1;
                        PHV_fifo_rd <= 1'b1;
                        out_scm_md_reg <= 256'b0;
                        md_flag <= 1'b0;
                        scm_state <= SEND_S;
                    end
                end
                else begin
                    scm_state <= IDLE_S;
                end
            end

            SEND_S: begin  //bypass, just trans
                MD_fifo_rd <= 1'b0;
                PHV_fifo_rd <= 1'b0;
                out_scm_md_wr <= 1'b1;
                if (md_flag == 1'b1) begin
                    out_scm_md <= out_scm_md_reg;
                end 
                else begin
                    out_scm_md <= MD_fifo_rdata;
                end 
                out_scm_phv_wr <= 1'b1;
                out_scm_phv <= PHV_fifo_rdata;
                scm_state <= IDLE_S;
            end

            CNT_S: begin  //statistic the data and information
                if (gac2scm_sent_end == 1'b1) begin
                    scm_state <= WAIT_S;
                end
                else begin
                    if (out_scm_md_reg[79:72] == protocol_type) begin  //satisfy the requirement of protocol
                        //statistic
                        scm_bit_num_cnt <= scm_bit_num_cnt + {52'b0, out_scm_md_reg[107:96]};
                        scm_pkt_num_cnt <= scm_pkt_num_cnt + 64'b1;
                        last_timestamp <= out_scm_md_reg[31:0];
                        scm_time_cnt <= scm_time_cnt + out_scm_md_reg[31:0] - last_timestamp;
                        //discard
                        out_scm_md_reg[108] <= 1;
                        //trans
                        MD_fifo_rd <= 1'b1;
                        PHV_fifo_rd <= 1'b1;
                        md_flag <= 1'b1;
                        scm_state <= SEND_S;
                    end
                    else begin
                        //just trans
                        MD_fifo_rd <= 1'b1;
                        PHV_fifo_rd <= 1'b1;
                        md_flag <= 1'b1;
                        scm_state <= SEND_S;
                    end
                end
            end

            WAIT_S: begin
                if (!record_endtime_tag) begin
                    end_time <= last_timestamp;
                    record_endtime_tag <= 1'b1;
                end

                if (out_scm_md_reg[31:0] < (end_time + n_RTT)) begin
                    if (out_scm_md_reg[79:72] == protocol_type) begin  //satisfy the requirement of protocol
                        //statistic
                        scm_bit_num_cnt <= scm_bit_num_cnt + {52'b0, out_scm_md_reg[107:96]};
                        scm_pkt_num_cnt <= scm_pkt_num_cnt + 64'b1;
                        last_timestamp <= out_scm_md_reg[31:0];
                        scm_time_cnt <= scm_time_cnt + out_scm_md_reg[31:0] - last_timestamp;
                        //discard
                        out_scm_md_reg[108] <= 1;
                        //trans
                        MD_fifo_rd <= 1'b1;
                        PHV_fifo_rd <= 1'b1;
                        md_flag <= 1'b1;
                        scm_state <= SEND_S;
                    end
                    else begin
                        //just trans
                        MD_fifo_rd <= 1'b1;
                        PHV_fifo_rd <= 1'b1;
                        md_flag <= 1'b1;
                        scm_state <= SEND_S;
                    end
                end
                else begin
                    scm_state <= FETCH_S;
                end
            end

            FETCH_S: begin
                if (statistic_reset == 1'b1) begin
                    scm_state <= IDLE_S;
                end
                else begin
                    scm_state <= FETCH_S;
                end
            end

            default: begin
                scm_state <= IDLE_S;
            end

        endcase
    end
end

//**************************************************
//                Reset Statisitc Reg
//**************************************************
/*always @(posedge clk) begin 
    if (statistic_reset == 1'b1) begin
        scm_bit_num_cnt <= 64'b0;
        scm_pkt_num_cnt <= 64'b0;
        scm_time_cnt <= 64'b0;
        last_timestamp <= 32'b0;
        protocol_type <= 8'b0;
        n_RTT <= 32'b0;
        record_endtime_tag <= 1'b0;
    end
    else begin
        scm_bit_num_cnt <= scm_bit_num_cnt;
        scm_pkt_num_cnt <= scm_pkt_num_cnt;
        scm_time_cnt <= scm_time_cnt;
        last_timestamp <= last_timestamp;
        protocol_type <= protocol_type;
        n_RTT <= n_RTT;
    end
end*/

//**************************************************
//                Other IP Instance
//**************************************************
fifo_256_256 MD_fifo(
    .srst(!rst_n),
    .clk(clk),
    .din(in_scm_md),
    .rd_en(MD_fifo_rd),
    .wr_en(in_scm_md_wr),
    .dout(MD_fifo_rdata),
    .data_count(MD_fifo_usedw),
    .empty(MD_fifo_empty),
    .full()
);

fifo_1024_256 PHV_fifo(
    .srst(!rst_n),
    .clk(clk),
    .din(in_scm_phv),
    .rd_en(PHV_fifo_rd),
    .wr_en(in_scm_phv_wr),
    .dout(PHV_fifo_rdata),
    .data_count(PHV_fifo_usedw),
    .empty(PHV_fifo_empty),
    .full()
);

endmodule