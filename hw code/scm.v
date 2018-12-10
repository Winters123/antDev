/** *************************************************************************
 *  @file       scm.v
 *  @brief      recording statistics of received pkts.
 * 
 *  
 *  @date       2018/10/24 10:53:51 
 *  @author     Jiang(Copyright  2018  Jiang Yue)
 *  @modified   Yang XR
 *  @email      <lang_jy@outlook.com>
 *  @version    0.1.0
 ****************************************************************************/
module scm #(
    parameter PLATFORM = "Xilinx",
              LMID = 8'd7,
              NMID = 8'd4
)(
    input clk,
    input rst_n,

    //receive from gme
    input [255:0] in_scm_md,
    (*mark_debug = "true"*)input in_scm_md_wr,
    output wire out_scm_md_alf,


    input [1023:0] in_scm_phv,
    (*mark_debug = "true"*)input in_scm_phv_wr,
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
    input cin_scm_ready,

    //timestamp from UM
    input [31:0] um2scm_timestamp
);



//**************************************************
//                Counters Declaration
//**************************************************
reg [63:0] scm_bit_num_cnt;
reg [63:0] scm_pkt_num_cnt;

//**************************************************
//             Software Signal Declaration
//**************************************************
reg [7:0] protocol_type;
reg statistic_reset;
//reg [31:0] n_RTT;
//reg [31:0] n_RTT_cnt;

/*used for obatain the output of RAM*/
(*mark_debug = "true"*)wire [31:0] ram_latency_out;
/*used for restore the 2nd cycle of control read signal*/
reg [133:0] cin_scm_data_2_cycle;
(*mark_debug = "true"*)reg ram_latency_rd_en;
reg ctl_write_flag; //if its a read signal or write signal that the destination isn't self, we set the flag as 0, else we set it as 1
//Debug
(*mark_debug = "true"*)wire [9:0] ram_wr_addr;


assign out_scm_md_alf = in_scm_md_alf;
assign out_scm_phv_alf = in_scm_phv_alf;

assign cout_scm_ready = cin_scm_ready;


assign ram_wr_addr = in_scm_phv[585:576];
reg [2:0] scm_state;
reg  gac2scm_sent_start_dly;
reg [1023:0]in_scm_phv_dly;

//State Declaration
localparam NORMAL_S = 3'd0;


//**************************************************
//                Transport MD & PHV
//**************************************************
always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            out_scm_md <= 256'b0;
            out_scm_md_wr <= 1'b0;
            out_scm_phv <= 1024'b0;
            out_scm_phv_wr <= 1'b0;
            scm_bit_num_cnt <= 64'b0;
            scm_pkt_num_cnt <= 64'b0;

            //n_RTT_cnt <= 32'b0;
            gac2scm_sent_start_dly <= 1'b0;

            scm_state <= NORMAL_S;
        end

        else begin
            case(scm_state)
                NORMAL_S: begin

                    gac2scm_sent_start_dly <= gac2scm_sent_start;
                    //in_scm_phv_dly <= in_scm_phv;

                    if (statistic_reset == 1'b1) begin
                        scm_bit_num_cnt <= 64'b0;
                        scm_pkt_num_cnt <= 64'b0;
                        //n_RTT <= 32'b0;
                        out_scm_md <= 256'b0;
                        out_scm_md_wr <= 1'b0;
                        out_scm_phv <= 1024'b0;
                        out_scm_phv_wr <= 1'b0;
                    end

                    //if there are MD and PHV in fifo, need to read them out
                    else if (in_scm_md_wr == 1'b1 && in_scm_phv_wr == 1'b1) begin
                        if (in_scm_md[87:80] == LMID) begin
                            
                            out_scm_md_wr <= 1'b1;
                            out_scm_phv_wr <= 1'b1;
                            out_scm_md <= {in_scm_md[255:88], NMID, in_scm_md[79:0]};


                            if (gac2scm_sent_start == 1'b1 && protocol_type == in_scm_md[79:72]) begin  //start to count
                                scm_bit_num_cnt <= scm_bit_num_cnt + {52'b0, in_scm_md[107:96]};
                                scm_pkt_num_cnt <= scm_pkt_num_cnt + 64'b1;
                            end

                            //no need to count
                            else begin 
                                scm_bit_num_cnt <= scm_bit_num_cnt;
                                scm_pkt_num_cnt <= scm_pkt_num_cnt;
                            end
                        end
                        else begin  //just bypass
                            out_scm_md_wr <= 1'b1;
                            out_scm_phv_wr <= 1'b1;
                            out_scm_md <= in_scm_md;
                            out_scm_phv <= in_scm_phv;

                        end
                    end

                    else begin
                        out_scm_md <= 256'b0;
                        out_scm_md_wr <= 1'b0;
                        out_scm_phv <= 1024'b0;
                        out_scm_phv_wr <= 1'b0;
                    end
                end

                                
            endcase
        end
end



//**************************************************
//                Software Signal
//**************************************************

reg [2:0] scm_ctl_state;

//State Declaration
localparam IDLE_CTL_S = 3'd0,
           WAIT_CTL_S = 3'd1,
           WAIT_CTL_S2 = 3'd4,
           RESP1_CTL_S = 3'd2,


always @(posedge clk or negedge rst_n) begin

    if(rst_n == 1'b0) begin
        cout_scm_data <= 133'b0;
        cout_scm_data_wr <= 1'b0;
        ram_latency_rd_en <= 1'b0;
        scm_ctl_state = IDLE_CTL_S;
    end

    else begin
        case(scm_ctl_state) 

            IDLE_CTL_S: begin

                if (cin_scm_data_wr == 1'b1 && cin_scm_data[133:132] == 2'b01 && cin_scm_data[95:92] == 4'b1000 && cin_scm_data[126:124] == 3'b001) begin
                    ram_latency_rd_en <= 1'b1;
                    cout_scm_data <= cin_scm_data;
                    scm_ctl_state <= WAIT_CTL_S;
                    cout_scm_data_wr <= 1'b0;
                end

                //the 1st cycle
                else if (cin_scm_data_wr == 1'b1 && cin_scm_data[133:132] == 2'b01 && cin_scm_data[95:92] != 4'b1000) begin
                    if ((cin_scm_data[126:124] == 3'b010) && (cin_scm_data[103:96] == 8'd7)) begin
                            ctl_write_flag <= 1'b1;
                            case (cin_scm_data[95:64])
                      
                                32'h70000001: begin
                                    statistic_reset <= cin_scm_data[0];
                                end

                                32'h70000002: begin
                                    //n_RTT <= cin_scm_data[31:0];
                                end
                                32'h70000003: begin
                                    protocol_type <= cin_scm_data[7:0];
                                end
                            endcase
                            cout_scm_data <= 134'b0;
                            cout_scm_data_wr <= 1'b0;
                            
                    end

                    else if ((cin_scm_data[126:124] == 3'b001) && (cin_scm_data[103:96]== 8'd7)) begin

                            ctl_write_flag <= 1'b0;
                            
                            cout_scm_data_wr <= cin_scm_data_wr;
                            
                            case (cin_scm_data[95:64])
                                32'h70000000: begin
                                    cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], 29'b0, scm_state};
                                end
                                32'h70000002: begin
                                    //cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], n_RTT};
                                end
                                32'h70000003: begin
                                    cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], 24'b0, protocol_type};
                                end
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

                                default: begin
                                    cout_scm_data <= {cin_scm_data[133:128], 4'b1011, cin_scm_data[123:112], cin_scm_data[103:96], cin_scm_data[111:104], cin_scm_data[95:32], 32'hffffffff};
                                end
                            endcase

                    end
                    else if (cin_scm_ready == 1'b1) begin
                        ctl_write_flag <= 1'b0;
                        cout_scm_data <= cin_scm_data;
                        cout_scm_data_wr <= cin_scm_data_wr;
                    end
                end

                //the 2nd cycle
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
                    cout_scm_data <= cin_scm_data;
                    cout_scm_data_wr <= 1'b0;
                    ram_latency_rd_en <= 1'b0;
                    scm_ctl_state <= IDLE_CTL_S;
                end
            end

            WAIT_CTL_S: begin
                cout_scm_data <= cout_scm_data;
                /*store the 2nd cycle of cin read signal*/
                cin_scm_data_2_cycle <= cin_scm_data;
                cout_scm_data_wr <= 1'b0;
                ram_latency_rd_en <= 1'b0;
                scm_ctl_state <= WAIT_CTL_S2;
            end

            WAIT_CTL_S2: begin
                cout_scm_data <= cout_scm_data;
                cin_scm_data_2_cycle <= cin_scm_data_2_cycle;
                cout_scm_data_wr <= 1'b0;
                ram_latency_rd_en <= 1'b0;
                scm_ctl_state <= RESP1_CTL_S;
            end

            RESP1_CTL_S: begin
                cout_scm_data <= {cout_scm_data[133:128], 4'b1011, cout_scm_data[123:112], cout_scm_data[103:96], cout_scm_data[111:104], cout_scm_data[95:32], ram_latency_out};
                cout_scm_data_wr <= 1'b1;
                scm_ctl_state <= RESP2_CTL_S;

            end

            RESP2_CTL_S: begin
                cout_scm_data <= cin_scm_data_2_cycle;
                cout_scm_data_wr <= 1'b1;
                scm_ctl_state <= IDLE_CTL_S;
            end
        endcase
    end

end

(*mark_debug = "true"*)wire [31:0] time_latency;
assign time_latency = um2scm_timestamp-in_scm_phv[783:672];



/**----IP cores----*/
blk_mem_gen_0 scm_ram(
  .clka(clk),
  .wea(in_scm_md_wr),
  .addra(in_scm_phv[713:704]),
  .dina(time_latency),
  .douta(),
  .clkb(clk),
  .enb(1'b1),
  .web(1'b0),
  .addrb(cin_scm_data[73:64]),
  .dinb(32'b0),
  .doutb(ram_latency_out)
);
/**----IP cores----*/

endmodule
