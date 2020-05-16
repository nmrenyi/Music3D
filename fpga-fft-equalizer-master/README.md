# FPGA FFT Equalizer(original code description)

FPGA FFT Equalizer is a basic audio processing tool. It can accept audio signal via Line-in 3,5mm Jack, analyze it, remove frequency bands chosen by the user and send processed signal to headphones or speakers via Line-out 3,5mm Jack. It also visualizes present frequencies on a monitor screen as a bar graph via VGA interface.

Project is implemented in VHDL hardware description language and was designed to be used on Terasic DE2-70 evaluation board equipped with an Altera Cyclone II FPGA core. It uses WM8731 audio controller for accepting and sending audio signals and ADV7123 VGA DAC for generating VGA signal.
Audio analysis and modification is done using FFT algorithm. Time-domain audio signal is transformed into frequency-domain, desired frequencies are muted and then it is transformed back to time-domain with IFFT. Frequency-domain samples are also used to generate visualization.

This project was created as an assignment for Microprocessor Technologies 2 course at AGH University of Science and Technology.




# FOR PCY: CODE DESCRIPTION

## FILE DESCRIPTION
In folder `quartus`, click `fpga-fft.qpf` to open Quartus project.

In folder `src`, `top.vhd` is the top entity, which is the only thing you need to care about when connecting to the hardware.

In folder `test`, it might be testing some module in this project. But I haven't studied it a lot.

## Port Description

In `top.vhd`, "fft_size_exp" is the exponent number of the number of points for fft(i.e. N = 2**fft_size_exp, N is the number of points for fft, and also the number of points per window). Sampling rate is 48kHz, so our time for one window is 1 / 48000 * 16 = 3 * 10^-4 s, which need to be adjusted in the following phase.

"bits_per_sample" is the sampling bits for one sample, default 24bits.

"iCLK_100" is the 100MHz clock.

"AUD_BCLK" needs to be connected to "VM_BCLK" on the AN831 module.

"AUD_ADCLRCK"needs to be connected to "VM_ADCLRC" on the AN831 module.

"iAUD_ADCDAT"needs to be connected to "VM_ADCDAT" on the AN831 module.

"I2C_SDAT"needs to be connected to "VM_I2C_SDAT" on the AN831 module.

"oI2C_SCLK"needs to be connected to "VM_I2C_SCLK" on the AN831 module.



# FOR RY---MAYBE NO NEED TO CHANGE THE REGISTERS
--data should be available on 2nd bclk rising edge after rising daclrc edge (in WM8731 set lrp=1)
--48kHz sampling rate
--18,432MHz MCLK 
--BOSR = 1 (384fs)

MUST SET `INSEL`

左右声道？？一样吗？
继续确定参数选择，尤其是LRP的设置。
还有其他参数，例如sample rate, I^2S mode, BOSR, MCLK等等——这个代码里的MCLK从哪儿来的？

1. 先确认所有寄存器参数
2. 再确认MCLK参数
3. 改编代码去掉VGA部分，使之可以顺利编译，如果能看到输出更好
4. 试图搞清楚里面FFT的做法是否对, 对特定频域静音？


BYPASS?

DSPMODE
NORMAL MODE
MASTER MODE
BOSR=1

(Base Over Sampling Rate=384fs)


1. What is the output format of freq spectrum
2. Are the FFT windows independent(i.e. without overlap)
3. How can I use the FFT result?
4. I^S mode? sample freq? How many bits?


# RY ASK
接3.3V/5V？接一个两个？
测试test文件
如何看architecture中间的输出
