# Readme

> project: Music3D
>
> author: nmrenyi   pptrick
>
> latest update: 2020/5/2

这是一个关于光立方使用和串口协议的文档，方便之后编写控制代码以及上板实验。

## 光立方传输协议

![](.\res\coor.jpg)

坐标系选取如上图所示，其中坐标原点对应图中“亮灯点”，在“上位机开关”按键正上方。任意一个led的位置可由一个三元组表示：`(x,y,z)`，其中x,y,z取值均为0~7。

光立方串口通信参数如下：

>波特率： 115200
>
>数据位：8
>
>校验位： 无
>
>停止位：1

以下按“16进制”收发数据类型（还可以使用“ASCII”）对光立方具体控制协议进行说明：

```
F2 //数据包起始码 
00 00 00 00 00 00 00 00 //y=0
00 00 00 00 00 00 00 00 //y=1
00 00 00 00 00 00 00 00 //y=2
00 00 00 00 00 00 00 00 //y=3
00 00 00 00 00 00 00 00 //y=4
00 00 00 00 00 00 00 00 //y=5
00 00 00 00 00 00 00 00 //y=6
00 00 00 00 00 00 00 00 //y=7
```

称上述这一数据块为一个“数据包”；一个数据包可以完全控制某一时刻光立方的点亮状态。数据包中的每一个数据（如`00`,`F2`）成为“数据元”，每个“数据元”由一个二位16进制数构成，在实际串口传输时即为一个传输单元（8位数据，1字节）。可以看出，一个“数据包”包含65个“数据元”（65字节）。

### 数据元的位置控制x和y：
上述数据包中，`F2`为数据包起始码。剩下64个数据元，每个控制一条纵向（z方向）的灯：例如，第(i,j)个数据元控制y=i,x=j上的led（i,j编号与行列式一致）。

### 数据元的具体值控制z：
对于每一个数据元，都是个二位16进制数，不妨设为`mn`，其中m,n:0~F；则亮灯位置为，将`mn`转化成二进制数后，"1"的位置（右边低位，低位代表z小）。例如：`01`转化成二进制数为`00000001`，因此仅有z=0灯亮，`12`转化成二进制数为`00010010`，因此有z=1, z=4处的灯亮。

## FPGA串口控制

FPGA串口控制代码文件见`UART`目录。