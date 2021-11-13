本工程为《基于FPGA的图像采集与处理系统》课题的工程文件
开发软件为Xilinx的ISE Design Suite

文件目录结构为：
doc：一些说明文件

prj：工程相关文件，包括IP核、综合布线产生的文件、引脚约束文件、下载验证的比特流文件等

src_rtl：工程的RTL源代码文件
	key：按键控制模块
	lcd：图像显示模块
	ov5640：图像采集模块
	process：图像处理模块
	sdram：图像存储模块
	top：系统顶层模块

src_sim：部分仿真源代码文件
