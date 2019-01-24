# 项目简介
这个一个使用Verilog语言开发的，基于MIPS32 Release 1指令集的五级流水CPU。

# 主要特性
1. 五级整数流水线，分别是：取指、译码、执行、访存、回写。
2. 哈佛结构，分开的指令、数据接口。
3. 32个32位整数寄存器。
4. 大端模式。
5. 具有32bit数据、地址总线宽度。
6. 支持延迟转移。
7. 兼容MIPS32指令集架构，支持MIPS32指令集中的大部分指令。
8. 大多数指令可以在一个时钟周期内完成。

# 支持的指令
## 逻辑指令
* and
* andi
* or
* ori
* xor
* xori
* nor
* lui

## 移位指令
* sll
* sllv
* sra
* srav
* srl
* srlv

## 移动指令
* movz
* movn
* mfhi
* mthi
* mflo
* mtlo

## 算术指令
### 简单算术操作指令
* add
* addi
* addiu
* addu
* sub
* subu
* clo
* clz
* slt
* slti
* sltiu
* sltu
* mul
* mult
* multu

### 乘累加、乘累减指令
* madd
* maddu
* msub
* msubu

## 转移指令
### 跳转指令
* j
* jal
* jalr
* jr

### 分支指令
* b
* bal
* beq
* bgez
* bgezal
* bgtz
* blez
* bltz
* bltzal
* bne

## 加载存储指令
### 加载指令
* lb
* lbu
* lh
* lhu
* lw
* lwl
* lwr

### 储存指令
* sb
* sh
* sw
* swl
* swr

## 特殊指令
* nop
* ssnop
* sync
* pref

# 贡献
[帅天强](https://github.com/shuaitq)  
[高翔宇](blacktion07@gmail.com)  
[马庆涛](https://github.com/MaQingT)

# 参考
[自己动手写CPU](https://www.amazon.cn/dp/B01HLURAGI)