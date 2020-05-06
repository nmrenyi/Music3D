# readme

此文件夹包含两个文件`mTXD.vhdl`和`mUART.vhdl`，功能如下：

`mTXD.vhdl`：TX数据发送模块，用于将8位并行数据转为串行数据，并以适配的传输频率传送。

`mUART.vhdl`：测试模块，用于在fpga板上测试串口信号能否正确输出；每次按下按键`send_button`将会连续地输出指定信号。

以上文件已经过PC上的串口调试工具调试，能够正确输出串口信号。但还未通过光立方测试。

## 设定参数和使用

当前设定的参数如下：

```
clk: 11.0592MHz
baud: 115200 bps
data: 8 bits serial
```

`mTXD`模块接口如下：

```vhdl
----------------------------------------------------------------------
-- Input:      clk        | System clock at 11.0592 MHz (Baud: 115200)
--             data_in    | Input data (serial 8 bits)
--             send_cmd   | Input command : Input data valid
--
-- Output:     data_out   | TX line 
--             in_valid   | '1' when transmitter accepts
-----------------------------------------------------------------------
```

需要传输数据时将8位数据传入`data_in`，并同时将`send_cmd`置1；这二者需保持一定时间（具体来说是96个时钟周期以上）。每个数据帧之间建议隔一段时间。每次传入数据时需要确保`in_valid`为'1'，否则接收不到数据。