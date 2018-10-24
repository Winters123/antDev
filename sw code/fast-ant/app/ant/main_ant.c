/***************************************************************************
* @File         main_ant.c
* @Brief        a sample ant Network Tester demo
*
*
* @Author: {Yang Xiangrui}
* @File: main_ant.c
* @Date:   2018-10-17 16:56:03
* @Email: nudtyxr@hotmail.com
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
#include "../../include/fast.h"


#define ANT_MID 130

int callback(struct fast_packet *pkt,int pkt_len)
{
	print_pkt(pkt, pkt_len);
	return 0;
}

void ua_init(u8 mid)
{
	int ret = 0;
	/*向系统注册，自己进程处理报文模块ID为1的所有报文*/
	if((ret=fast_ua_init(mid,callback)))//UA模块实例化(输入参数1:接收模块ID号,输入参数2:接收报文的回调处理函数)
	{
		perror("fast_ua_init!\n");
		exit (ret);//如果初始化失败,则需要打印失败信息,并将程序结束退出!
	}
}


int main(int argc, char* argv[])
{
	u8 dmid = ANT_MID; 
	struct ant_parameter demo_parameter;
	struct ant_cnt *demo_cnt = (struct ant_cnt *)malloc(sizeof(struct ant_cnt));

	ua_init(ANT_MID);

	//set the test parameters
	demo_parameter.sent_time = 0x100010001000; //0x100010000 is about 3 seconds
	demo_parameter.sent_rate = 0x00001000; //about 6.5ms send a pkt
	demo_parameter.lat_pkt = 0;
	demo_parameter.lat_flag = 0; //disable latency test
	demo_parameter.n_rtt = 0x00010000; //wait about 6.5ms after sending the last pkt.

	if(ant_set_test_para(demo_parameter)){
		printf("set ant parameter error!\n");
		return -1;
	}

struct fast_packet *pkt = (struct fast_packet *)malloc(sizeof(struct um_metadata)+66);
	pkt->um.flowID = 3;
	pkt->um.seq = 4;
	pkt->um.outport = 1;
	pkt->um.priority = 7;
	pkt->um.dstmid = 1;
	pkt->um.len = sizeof(struct um_metadata)+66;
	int i;
	/*
	for(i=0;i<1400;i++){
		pkt->data[i] = 'c';
	}
	*/
	
	//construct a packet
	pkt->data[0] = 0xf0;
	pkt->data[1] = 0xde;
	pkt->data[2] = 0xf1;
	pkt->data[3] = 0x31;
	pkt->data[4] = 0x7b;
	pkt->data[5] = 0xc5;
	pkt->data[6] = 0x00;
	pkt->data[7] = 0x21;
	pkt->data[8] = 0x85;
	pkt->data[9] = 0xc5;
	pkt->data[10] = 0x2b;
	pkt->data[11] = 0x8f;
	pkt->data[12] = 0x08;
	pkt->data[13] = 0x00;
	pkt->data[14] = 0x45;
	pkt->data[15] = 0x00;
	pkt->data[16] = 0x00;
	pkt->data[17] = 0x3c;
	pkt->data[18] = 0x79;
	pkt->data[19] = 0x19;
	pkt->data[20] = 0x00;
	pkt->data[21] = 0x00;
	pkt->data[22] = 0x40;
	pkt->data[23] = 0x01;
	pkt->data[24] = 0x7b;
	pkt->data[25] = 0xdd;
	pkt->data[26] = 0xc0;
	pkt->data[27] = 0xa8;
	pkt->data[28] = 0x02;
	pkt->data[29] = 0x65;
	pkt->data[30] = 0xc0;
	pkt->data[31] = 0xa8;
	pkt->data[32] = 0x02;
	pkt->data[33] = 0x15;
	
	//i;
	for(i=34; i<66; i++ ){
		pkt->data[i] = 0xff;
	}
	//init packet
	ant_pkt_send(pkt, pkt->um.len); //trigger ANT to start
	printf("debug1\n");
	usleep(demo_parameter.sent_time/100);
	printf("debug2\n");
	while(ant_check_finish()==1){
		printf("the final is %d\n", ant_check_finish());
		sleep(1);
	}

	if(ant_collect_counters(demo_cnt)){
		printf("test result obtaining error!\n");
		return -1;
	}

	ant_print_counters(*demo_cnt);
	
	free(demo_cnt);
	
	return 0;
}
