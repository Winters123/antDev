/** *************************************************************************
 *  @file          ant_driver.h
 *  @brief		ANT相关函数头文件定义
 * 
 *   此头文件包含了ANT相关的所有定义文件，如虚拟地址空间定义、数据类型定义
 *   数据结构定义、枚举类型定义和错误信息定义
 * 
 *  @date		2018/10/03 12:14:24 星期三
 *  @author		Yang(Copyright  2018  Yang Xiangrui)
 *  @email		<nudtyxr@hotmail.com>
 *  @version	0.1.0
 ****************************************************************************/
/*
 * ant_driver.h
 *
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
 * */

#ifndef __ANT_DRIVER_H__
#define __ANT_DRIVER_H__

#include "fast.h"

/*
//declaration of vaddr on ANT
 */
#define SENT_TIME_CNT 0x00000002         // 64b, test time counter                  
#define SENT_TIME_REG 0x00010002         // 64b, test time reg
#define WR_SOFT_RST   0x00000000         //  1b, software rst for pgm_wr
#define SENT_RATE_CNT 0x00000001         // 32b, sent rate counter
#define SENT_RATE_REG 0x00010001         // 32b, sent rate reg
#define LAT_PKT_CNT   0x00000002         // 32b, for latency test cnt
#define LAT_PKT_REG   0x00010002         // 32b, for latency test reg
#define SENT_BIT_CNT  0x00000004         // 64b, total sent bits
#define SENT_PKT_CNT  0x00000006         // 64b, total sent packets
#define LAT_FLAG      0x00010010         //  1b, latency test flag  
#define RD_SOFT_RST   0x00000000		 //  1b, software rst for pgm_rd


/*
//declaration of vaddr on ANT (SCM part)
 */
#define PROTO_TYPE    0x70000000		  //  8b, protype of packets
#define SCM_SOFT_RST  0x70000001		  //  1b, software rst for SCM
#define N_RTT         0x70000002		  // 32b, total wait time after receiving finish signal
#define SCM_BIT_CNT   0x70000009		  // 64b, total received bits of SCM 
#define SCM_PKT_CNT   0x7000000b		  // 64b, total received packets of SCM
#define SCM_TIME_CNT  0x7000000d		  // 64b, total monitoring time of SCM





/*-------------------ANT CORE FUNCTION ------------------*/

int ant_collect_counters();
int ant_rst();


/*-------------------ANT CORE FUNCTION ------------------*/



/*-------------------SET COUNTER & REG------------------*/

int ant_set_sent_time_cnt(u64 regvalue);
int ant_set_sent_time_reg(u64 regvalue);
int ant_set_wr_soft_rst(u64 regvalue);
int ant_set_sent_rate_cnt(u64 regvalue);
int ant_set_sent_rate_reg(u64 regvalue);
int ant_set_lat_pkt_cnt(u64 regvalue);
int ant_set_lat_pkt_reg(u64 regvalue);
int ant_set_sent_bit_cnt(u64 regvalue);
int ant_set_sent_pkt_cnt(u64 regvalue);
int ant_set_lat_flag(u64 regvalue);
int ant_set_rd_soft_rst(u64 regvalue);


int ant_set_proto_type(u64 regvalue);
int ant_set_scm_soft_rst(u64 regvalue);
int ant_set_n_rtt(u64 regvalue);
int ant_set_scm_bit_cnt(u64 regvalue);
int ant_set_scm_pkt_cnt(u64 regvalue);
int ant_set_scm_time_cnt(u64 regvalue);

/*-------------------COUNTER & REG------------------*/


/*-------------------GET COUNTER & REG------------------*/

int ant_get_sent_time_cnt(u64 &regvalue);
int ant_get_sent_time_reg(u64 &regvalue);
int ant_get_wr_soft_rst(u64 &regvalue);
int ant_get_sent_rate_cnt(u64 &regvalue);
int ant_get_sent_rate_reg(u64 &regvalue);
int ant_get_lat_pkt_cnt(u64 &regvalue);
int ant_get_lat_pkt_reg(u64 &regvalue);
int ant_get_sent_bit_cnt(u64 &regvalue);
int ant_get_sent_pkt_cnt(u64 &regvalue);
int ant_get_lat_flag(u64 &regvalue);
int ant_get_rd_soft_rst(u64 &regvalue);


int ant_get_proto_type(u64 &regvalue);
int ant_get_scm_soft_rst(u64 &regvalue);
int ant_get_n_rtt(u64 &regvalue);
int ant_get_scm_bit_cnt(u64 &regvalue);
int ant_get_scm_pkt_cnt(u64 &regvalue);
int ant_get_scm_time_cnt(u64 &regvalue);

/*-------------------COUNTER & REG------------------*/

#endif