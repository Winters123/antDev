/***************************************************************************
* @File         main_libant.c
* @Brief        Lib to support performance test of ANT network tester
*
* @Author: {Yang Xiangrui}
* @File:   main_libant.c
* @Date:   2018-10-03 11:38:21
* @Email:  nudtyxr@hotmail.com
* 
* ***************************************************************************/
/*
 * Copyright (C) 2018 - Yang Xiangrui
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
//#include "../../include/ant_driver.h"
#include "../../include/fast.h"

#define SCM_MID     7        
#define PGM_MID     6
#define PGM_WR_MID  61
#define PGM_RD_MID  62

#define MASK_1      0x0


/*---------------------------------ANT CORE FUNCTION ----------------------------*/
/**
 * collect result counter values from PGM and SCM modules
 * @param  outc valuable counter values in SCM and PGM module
 * @return      0 if success
 */
int ant_collect_counters(struct ant_cnt *outc)
{
	u64 test_time = ((u64)fast_ua_hw_rd(PGM_WR_MID, SENT_TIME_REG, MASK_1)<<32) + fast_ua_hw_rd(PGM_WR_MID, SENT_TIME_REG-1, MASK_1);

	//printf("test_time = %llx\n", test_time);
	u64 sent_bits = ((u64)fast_ua_hw_rd(PGM_RD_MID, SENT_BIT_CNT, MASK_1)<<32) + fast_ua_hw_rd(PGM_RD_MID, SENT_BIT_CNT-1, MASK_1);
	//printf("test_time = %llx\n", sent_bits);
	u64 sent_pkts = ((u64)fast_ua_hw_rd(PGM_RD_MID, SENT_PKT_CNT, MASK_1)<<32) + fast_ua_hw_rd(PGM_RD_MID, SENT_PKT_CNT-1, MASK_1);
	//printf("test_time = %llx\n", sent_pkts);
	u64 recv_bits = ((u64)fast_ua_hw_rd(SCM_MID, SCM_BIT_CNT, MASK_1)<<32) + fast_ua_hw_rd(SCM_MID, SCM_BIT_CNT-1, MASK_1);
	//printf("test_time = %llx\n", recv_bits);
	u64 recv_pkts = ((u64)fast_ua_hw_rd(SCM_MID, SCM_PKT_CNT, MASK_1)<<32) + fast_ua_hw_rd(SCM_MID, SCM_PKT_CNT-1, MASK_1);
	//printf("test_time = %llx\n", recv_pkts);
	
	outc->test_time = test_time;
	outc->sent_bits = sent_bits;
	outc->sent_pkts = sent_pkts;
	outc->recv_bits = recv_bits;
	outc->recv_pkts = recv_pkts;

	return 0;
}


/**
 * check the hw module of ANT to see if all the modules are waiting for software reset
 * @return     [0 if true, otherwise return 1]
 */
int ant_check_finish()
{
	if(fast_ua_hw_rd(PGM_RD_MID, ANT_HW_STATE, MASK_1) == 0x910){
		return 0;
	}
	else 
		return 1;
}

/**
 * set test parameters on registers of ANT modules 
 * @param  antp [the struct of ANT parameters]
 * @return      [0 if success]
 */
int ant_set_test_para(struct ant_parameter antp)
{
	int i=0;
	i += ant_set_sent_time_reg((u64)antp.sent_time);
	i += ant_set_sent_rate_reg((u64)antp.sent_rate);
	i += ant_set_lat_pkt_reg((u64)antp.lat_pkt);
	i += ant_set_lat_flag((u64)antp.lat_flag);
	i += ant_set_n_rtt((u64)antp.n_rtt);
	i += ant_set_proto_type((u64)antp.proto_type);
	
	return i;
}

/**
 * send a model packet to ANT hw and trigger ANT to start testing
 * @param  pkt     [model packet]
 * @param  pkt_len [the length of model packet]
 * @return         [pkt_len if success, else return -1]
 */
int ant_pkt_send(struct fast_packet *pkt, int pkt_len)
{
	//used for debug
	print_pkt(pkt, pkt_len);
	//sent model packet
	return fast_ua_send(pkt, pkt_len);
	
}

/**
 * test the throughput using dich method, caution that this is a blocking function, only
 * returns onces finished
 * @param  pkt     [model packet]
 * @param  pkt_len [the length of model packet]
 * @return         [final throughput of the tested port]
 */
/*
u32 ant_dich_throughput_test(struct fast_packet *pkt, int pkt_len, int rnt, u32 sent_rate, u64 test_time)
{
	int rnt_cnt;
	u32 sent_rate_low = 0, sent_rate_high = sent_rate;
	struct ant_cnt antc;
	//set test paramters
	struct ant_parameter antp;
	antp.sent_time = test_time;
	antp.sent_rate = sent_rate;
	antp.lat_pkt = 0;
	antp.lat_flag = 0;
	antp.n_rtt = 2; //we set n_rtt as 2 as default

	ant_set_test_para(antp);

	ant_pkt_send(pkt, pkt_len);

	usleep(test_time/100);
	//chech if the test is finished
	for(rnt_cnt = 0; rnt_cnt < rnt; rnt_cnt++){
		ant_set_test_para(antp);
		ant_pkt_send(pkt, pkt_len);
		usleep(test_time/100);
		while(!ant_check_finish()){
			usleep(100);
		}
		if(ant_collect_counters(antc)){
			printf("the dich exit with an error\n");
			return -1;
		}
		if (antc.sent_pkts == antc.recv_pkts)
		{
			sent_rate_low = (sent_rate_high + sent_rate_low) / 2;
			antp.sent_rate = sent_rate_low; 
		}
		else {
			sent_rate_high = (sent_rate_high + sent_rate_low) / 2;
			antp.sent_rate = sent_rate_high;
		}
	}
	return antp.sent_rate;

}
*/


/**
 * print the final counter values of the test
 * @param ant_cnt [description]
 */
void ant_print_counters(struct ant_cnt a_cnt, int len){
	printf("-----------------------***ANT COUNTERS***-----------------------\n");

	a_cnt.sent_bits = a_cnt.sent_bits-a_cnt.sent_pkts*16;
	
	a_cnt.recv_bits = a_cnt.recv_bits-a_cnt.recv_pkts*32;
	printf("Test Time:\t%llu *10ns\n", a_cnt.test_time);
	printf("Sent Pkt Bytes:\t%llu\t Bytes\n", a_cnt.sent_bits);
	printf("Sent Pkt Num:\t%llu\t\n", a_cnt.sent_pkts);
	printf("Sent Pkt Rate:\t%llf\tKpps\n", (double)(a_cnt.sent_pkts*100000.0/a_cnt.test_time));
	printf("Sent Bit Rate:\t%llf\tMbps\n", (double)(a_cnt.sent_bits*100*8.0/a_cnt.test_time));
	printf("Recv Pkt Bytes:\t%llu\t Bytes\n", a_cnt.recv_bits);
	printf("Recv Pkt Num:\t%llu\n", a_cnt.recv_pkts);
	printf("Recv Pkt Rate:\t%llf\tKpps\n",(double)(a_cnt.recv_pkts*100000.0/a_cnt.test_time));
	printf("Recv Bit Rate:\t%llf\tMbps\n",(double)((a_cnt.recv_bits*8*100.0)/a_cnt.test_time));

	printf("-----------------------***ANT COUNTERS***-----------------------\n");
}

/**
 * reset the hw pipeline in order to enable next text round
 * @return [0 if success, else failure]
 */
int ant_rst(){
	//reset PGM module
	u32 rd_state = fast_ua_hw_rd(PGM_RD_MID, RD_STATE, MASK_1);
	if (rd_state == 0x910){
		if(ant_set_rd_soft_rst(1) != 0)
			return -1;
		if(ant_set_rd_soft_rst(0) != 0)
			return -1;
		fast_ua_hw_wr(SCM_MID, 0x70000001, 1, MASK_1);
		fast_ua_hw_wr(SCM_MID, 0x70000001, 0, MASK_1);

	}
	else {
		return -1;
	}
	return 0;
}

/**
 * Read latency into latency test file, in a readable format
 * @return [0 if success, else return -1]
 */
int import_latency_to_txt(int size){

	FILE * fid = fopen("latency_out", "w");
	if (fid == NULL){
		printf("write latency_out.txt error!\n");
		return -1;
	}
	fprintf(fid, "/*****************latency test result****************/\n");
	fprintf(fid, "                                           Unit *10ns \n");
	int i, j=0;
	u32 in_file_latency = 0;
	for (i = 0; i < 1023; i++){
		in_file_latency = fast_ua_hw_rd(SCM_MID, SCM_RAM_ADDR + i, MASK_1);
		usleep(1);
		if(size>0 && size<=64){
			fprintf(fid, "%04d round: %uns\t", i, (in_file_latency*10-260));
		}

		else if(size >64 && size <=128){
			fprintf(fid, "%04d round: %uns\t", i, (in_file_latency*10-730));
		}
		else if(size>128 && size <=256){
			
			fprintf(fid, "%04d round: %uns\t", i, (in_file_latency*10-2400));
		}
		else if(size>256 && size <= 512){
			
			fprintf(fid, "%04d round: %uns\t", i, (in_file_latency*10-5710));
		}
		else if(size>512 && size <= 1024){
			
			fprintf(fid, "%04d round: %uns\t", i, (in_file_latency*10-12370));
		}
		else if(size>1024 && size <= 1500){
			fprintf(fid, "%04d round: %uns\t", i, (in_file_latency*10-19370));
		}
		else 
			fprintf(fid, "%04d round: invalid value.\t", i);
		j++;
		if(j == 5){
			fprintf(fid, "\n");
			j = 0;
		}
	}

	fprintf(fid, "\n/*****************latency test result****************/\n");
	fclose(fid);
	printf("latency_out.txt generated!\n");
	return 0;
}

/*---------------------------------ANT CORE FUNCTION ----------------------------*/


/*---------------------------------SET REG & COUNTERS----------------------------*/
/**
 * set sent_time_cnt value in PGM module
 * @param  regvalue         reset sent_time_cnt
 * @return                  0 if success
 */
int ant_set_sent_time_cnt(u64 regvalue)
{
	u32 regvalue_tmp_high = ((u32) regvalue>>32);
	u32 regvalue_tmp_low  = ((u32) regvalue);

	fast_ua_hw_wr(PGM_RD_MID, SENT_TIME_CNT, regvalue_tmp_high, MASK_1);
	fast_ua_hw_wr(PGM_RD_MID, SENT_TIME_CNT - 1, regvalue_tmp_low, MASK_1);

	return 0;
}

/**
 * set sent_time_reg as regvalue
 * @param  regvalue     sent_time_regvalue value
 * @return              0 if success
 */
int ant_set_sent_time_reg(u64 regvalue)
{
	u32 regvalue_tmp_high = regvalue>>32;
	printf("regvalue tmp high = %lx\n", regvalue_tmp_high);
	u32 regvalue_tmp_low  = ((u32) regvalue);
	printf("regvalue tmp low = %lx\n", regvalue_tmp_low);

	fast_ua_hw_wr(PGM_WR_MID, SENT_TIME_REG, regvalue_tmp_high, MASK_1);
	fast_ua_hw_wr(PGM_WR_MID, SENT_TIME_REG - 1, regvalue_tmp_low, MASK_1);

	return 0;
}

int ant_set_sent_rate_cnt(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(PGM_RD_MID, SENT_RATE_CNT, regvalue_tmp, MASK_1);
	return 0;
}

int ant_set_sent_rate_reg(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(PGM_RD_MID, SENT_RATE_REG, regvalue_tmp, MASK_1);
	return 0;
}

int ant_set_lat_pkt_cnt(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(PGM_RD_MID, LAT_PKT_CNT, regvalue_tmp, MASK_1);
	return 0;
}

int ant_set_lat_pkt_reg(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(PGM_RD_MID, LAT_PKT_REG, regvalue_tmp, MASK_1);
	return 0;
}

/**
 * set counters to count for total bytes of traffic
 * @param  regvalue    the counter value to be set
 * @return             0 if success
 */
int ant_set_sent_bit_cnt(u64 regvalue)
{
	
	u32 regvalue_tmp_high = ((u32) regvalue>>32);
	u32 regvalue_tmp_low  = ((u32) regvalue);

	fast_ua_hw_wr(PGM_RD_MID, SENT_BIT_CNT, regvalue_tmp_high, MASK_1);
	fast_ua_hw_wr(PGM_RD_MID, SENT_BIT_CNT - 1, regvalue_tmp_low, MASK_1);

	return 0;

}

int ant_set_sent_pkt_cnt(u64 regvalue)
{
	u32 regvalue_tmp_high = ((u32) regvalue>>32);
	u32 regvalue_tmp_low  = ((u32) regvalue);

	fast_ua_hw_wr(PGM_RD_MID, SENT_PKT_CNT, regvalue_tmp_high, MASK_1);
	fast_ua_hw_wr(PGM_RD_MID, SENT_PKT_CNT - 1, regvalue_tmp_low, MASK_1);
	
	return 0;
}

int ant_set_lat_flag(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(PGM_RD_MID, LAT_FLAG, regvalue_tmp, MASK_1);
	return 0;
}

int ant_set_rd_soft_rst(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(PGM_RD_MID, RD_SOFT_RST, regvalue_tmp, MASK_1);
	return 0;
}


int ant_set_proto_type(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(SCM_MID, PROTO_TYPE, regvalue_tmp, MASK_1);
	return 0;
}


int ant_set_scm_soft_rst(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(SCM_MID, SCM_SOFT_RST, regvalue_tmp, MASK_1);
	return 0;
}


int ant_set_n_rtt(u64 regvalue)
{
	u32 regvalue_tmp = (u32) regvalue;
	fast_ua_hw_wr(SCM_MID, N_RTT, regvalue_tmp, MASK_1);
	return 0;
}


int ant_set_scm_bit_cnt(u64 regvalue)
{
	u32 regvalue_tmp_high = ((u32) regvalue>>32);
	u32 regvalue_tmp_low =  ((u32) regvalue);

	fast_ua_hw_wr(SCM_MID, SCM_BIT_CNT, regvalue_tmp_high, MASK_1);
	fast_ua_hw_wr(SCM_MID, SCM_BIT_CNT - 1, regvalue_tmp_low, MASK_1);

	return 0;
}


int ant_set_scm_pkt_cnt(u64 regvalue)
{
	u32 regvalue_tmp_high = ((u32) regvalue>>32);
	u32 regvalue_tmp_low =  ((u32) regvalue);

	fast_ua_hw_wr(SCM_MID, SCM_PKT_CNT, regvalue_tmp_high, MASK_1);
	fast_ua_hw_wr(SCM_MID, SCM_PKT_CNT - 1, regvalue_tmp_low, MASK_1);

	return 0;
}



/*---------------------------------SET REG & COUNTERS----------------------------*/




/*---------------------------------GET REG & COUNTERS----------------------------*/
/**
 * get the reg value from ANT hw
 * @param  regvalue   	reg values that are to be obtained from hw.
 * @return          	0 if success
 */
int ant_get_sent_time_cnt(u64 *regvalue)
{
	u32 regvalue_tmp_high = fast_ua_hw_rd(PGM_WR_MID, SENT_TIME_CNT, MASK_1);
	u32 regvalue_tmp_low  = fast_ua_hw_rd(PGM_WR_MID, SENT_TIME_CNT - 1, MASK_1);

	*regvalue = ((u64)regvalue_tmp_high<<32) + (u64)regvalue_tmp_low;

	return 0;
}


int ant_get_sent_time_reg(u64 *regvalue)
{
	u32 regvalue_tmp_high = fast_ua_hw_rd(PGM_WR_MID, SENT_TIME_REG, MASK_1);
	u32 regvalue_tmp_low  = fast_ua_hw_rd(PGM_WR_MID, SENT_TIME_REG - 1, MASK_1);

	*regvalue = ((u64)regvalue_tmp_high<<32) + (u64)regvalue_tmp_low;

	return 0;
}


int ant_get_sent_rate_cnt(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(PGM_RD_MID, SENT_RATE_CNT, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_sent_rate_reg(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(PGM_RD_MID, SENT_TIME_REG, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_lat_pkt_cnt(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(PGM_RD_MID, LAT_PKT_CNT, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_lat_pkt_reg(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(PGM_RD_MID, LAT_PKT_REG, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_sent_bit_cnt(u64 *regvalue)
{
	u32 regvalue_tmp_high = fast_ua_hw_rd(PGM_RD_MID, SENT_BIT_CNT, MASK_1);
	u32 regvalue_tmp_low  = fast_ua_hw_rd(PGM_RD_MID, SENT_BIT_CNT - 1, MASK_1);

	*regvalue = ((u64)regvalue_tmp_high<<32) + (u64)regvalue_tmp_low;

	return 0;
}


int ant_get_sent_pkt_cnt(u64 *regvalue)
{
	u32 regvalue_tmp_high = fast_ua_hw_rd(PGM_RD_MID, SENT_PKT_CNT, MASK_1);
	u32 regvalue_tmp_low  = fast_ua_hw_rd(PGM_RD_MID, SENT_PKT_CNT - 1, MASK_1);

	*regvalue = ((u64)regvalue_tmp_high<<32) + (u64)regvalue_tmp_low;

	return 0;
}


int ant_get_lat_flag(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(PGM_RD_MID, LAT_FLAG, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_rd_soft_rst(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(PGM_RD_MID, RD_SOFT_RST, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}




int ant_get_proto_type(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(SCM_MID, PROTO_TYPE, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_scm_soft_rst(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(SCM_MID, SCM_SOFT_RST, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_n_rtt(u64 *regvalue)
{
	u32 regvalue_tmp = fast_ua_hw_rd(SCM_MID, N_RTT, MASK_1);
	*regvalue = regvalue_tmp;
	return 0;
}


int ant_get_scm_bit_cnt(u64 *regvalue)
{
	u32 regvalue_tmp_high = fast_ua_hw_rd(SCM_MID, SCM_BIT_CNT, MASK_1);
	u32 regvalue_tmp_low  = fast_ua_hw_rd(SCM_MID, SCM_BIT_CNT - 1, MASK_1);

	*regvalue = ((u64)regvalue_tmp_high<<32) + (u64)regvalue_tmp_low;

	return 0;
}


int ant_get_scm_pkt_cnt(u64 *regvalue)
{
	u32 regvalue_tmp_high = fast_ua_hw_rd(SCM_MID, SCM_PKT_CNT, MASK_1);
	u32 regvalue_tmp_low  = fast_ua_hw_rd(SCM_MID, SCM_PKT_CNT - 1, MASK_1);

	*regvalue = ((u64)regvalue_tmp_high<<32) + (u64)regvalue_tmp_low;

	return 0;
}




/*---------------------------------GET REG & COUNTERS----------------------------*/
