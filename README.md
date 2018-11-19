# ANT
Agile Network Tester is a FPGA-CPUs based Network Tester based on [FAST](www.fastswitch.org). We write this to help people test the performance of network prototypes,
when they don't have commercial testers at hand.

the ANT v1 has been up online since 2018.11.7, welcome to use!

Tips: ANT is aimming to be deployed on both Xilinx and Altera FPGAs, but we set Xilinx Zynq 7000 as the platform in ANT v1.  

### How to use
Firstly, you need to clone `/App/BOOT.bin` and `/App/ant` into the directory of `/mnt` of ARM core of Zynq. Then, reboot the SoC. run `./ant` for prompt. 

After finish the test, the testing report will be seen on both the `terminal` and the file named `latency_out`. 

Remember that ANT now is only used for *throughput/jitter/latency/drop-rate* test, We are working on *compiler back-end design to enable complex network function evaluation*. What's more, if you and your company have some interesting demands, please leave a comment in the `issues` and we are willing to support them in the next version of ANT to help as many people as we can.

Let's see what ANT can do :)
