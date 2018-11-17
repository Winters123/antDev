# ANT
Agile Network Tester is a FPGA-CPUs based Network Tester based on [FAST](www.fastswitch.org). We write this to help people test the performance of network prototypes,
when they don't have commercial testers at hand.

the ANT v1 has been up online since 2018.11.7, welcome to use!

Tips: ANT is aimming to be deployed on both Xilinx and Altera FPGAs, but we set Xilinx Zynq 7000 as the platform in ANT v1.  

### How to use
Firstly, you need to clone `/App/BOOT.bin` and `/App/ant` into the directory of /mnt of ARM core of Zynq. Then, reboot the SoC. run `./ant` for prompt. 

The test report will be seen on both the `terminal` and the file named `latency_out`.
