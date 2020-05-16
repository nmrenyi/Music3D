# readme

此目录下包含四个文件：

`top.vhd`为测试文件，在最后建立工程的时候**不需要包括**这个文件，但是它可以一定程度上告诉你如何使用`mTransmitter`；

`mTransmitter.vhd`为`mTransmitter`所在的文件，也是最这部分核心的文件。`mTransmitter`包含“从音频输出处接受输入并整理成队列形式”、“将队列内容打包逐个输出给串口模块`mTXD`”、"串口模块`mTXD`输出"三个功能，建立工程时重点关注这个文件即可。

`mTXD.vhd` 见`UART`目录的readme

`trans.pkg_vhd` 包文件，定义数据类型cube_vector。（8x64的向量）

## mTransmitter

输入输出如下：

```vhdl
-----------------------------------------------------------------------
-- Input:      iCLK_11MHz | System clock at 11.0592 MHz (Baud: 115200)
--             data_in    | Input data (serial 64 bits)
--             send_cmd   | Input command : Input data valid
--
-- Output:     tx_out     | TX line 
-----------------------------------------------------------------------
```

`iCLK_11MHz` 接fpga板上的11MHz时钟；

`data_in` 接输入的64位std_logic_vector；

`send_cmd` 接输入的可接受信号；

`tx_out` 接fpga串口输出；

## 注意事项

1.`data_in`在变更之前建议一直保持