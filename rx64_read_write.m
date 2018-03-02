% 需要修改的地方：
% 1.ID = ?; 通过调试软件设置
% 2.DEVICENAME = 'COM?'; 通过设备管理器查看

clc;
clear all;

lib_name = '';
%根据不同的系统选择不同的库名，库名为字符串
if strcmp(computer, 'PCWIN')
  lib_name = 'dxl_x86_c';
elseif strcmp(computer, 'PCWIN64')
  lib_name = 'dxl_x64_c';
elseif strcmp(computer, 'GLNX86')
  lib_name = 'libdxl_x86_c';
elseif strcmp(computer, 'GLNXA64')
  lib_name = 'libdxl_x64_c';
elseif strcmp(computer, 'MACI64')
  lib_name = 'libdxl_mac_c';
end

% 加载库
if ~libisloaded(lib_name)
    [notfound, warnings] = loadlibrary(lib_name, 'dynamixel_sdk.h', 'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

% 控制表地址
ADDR_MX_TORQUE_ENABLE       = 24;           % Torque Enable (24)，0关1开
ADDR_MX_GOAL_POSITION       = 30;           % Goal Position (30)， 0 ~ 1023，单位 0.29°
ADDR_MX_PRESENT_POSITION    = 36;           % Present Position (36)， 0~1023，单位 0.29°

% 协议版本
PROTOCOL_VERSION            = 1.0;          % RX-64使用的是协议1.0

% 默认设置
ID_1                        = 1;            % ID (3)
ID_2                        = 12;
BAUDRATE                    = 57142;        % Baud Rate (4)
DEVICENAME                  = 'COM5';       % 端口号

TORQUE_ENABLE               = 1;            % Torque Enable 开
TORQUE_DISABLE              = 0;            % Torque Enable 关

ESC_CHARACTER               = 'e';          % 按'e'键可退出循环

COMM_SUCCESS                = 0;            % 通信成功结果值
COMM_TX_FAIL                = -1001;        % 通信发送失败


% 初始化端口
port_num = portHandler(DEVICENAME);
packetHandler();

dxl_comm_result = COMM_TX_FAIL;             % 通信结果
dxl_error = 0;                              % 舵机错误

% 打开端口
if (openPort(port_num))
    fprintf('Succeeded to open the port!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to open the port!\n');
    input('Press any key to terminate...\n');
    return;
end


% 设置波特率
if (setBaudRate(port_num, BAUDRATE))
    fprintf('Succeeded to change the baudrate!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to change the baudrate!\n');
    input('Press any key to terminate...\n');
    return;
end


% 舵机1不使能，舵机2使能
write1ByteTxRx(port_num, PROTOCOL_VERSION, ID_1, ADDR_MX_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, ID_2, ADDR_MX_TORQUE_ENABLE, TORQUE_ENABLE);

dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
else
    fprintf('Dynamixel has been successfully connected \n');
end

% 循环
while 1

    if input('Press any key to continue! (or input e to quit!)\n', 's') == ESC_CHARACTER
        break;
    end

    for i=1:100
        % 读当前的位置
        dxl_present_position_1 = read2ByteTxRx(port_num, PROTOCOL_VERSION, ID_1, ADDR_MX_PRESENT_POSITION);
        write2ByteTxRx(port_num, PROTOCOL_VERSION, ID_2, ADDR_MX_GOAL_POSITION, dxl_present_position_1);
        dxl_present_position_2 = read2ByteTxRx(port_num, PROTOCOL_VERSION, ID_2, ADDR_MX_PRESENT_POSITION);
        
        dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
        dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
        if dxl_comm_result ~= COMM_SUCCESS
            fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
        elseif dxl_error ~= 0
            fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
        end
        %输出当前位置
        fprintf('[ID:%03d]  PresPos:%03d  [ID:%03d]  PresPos:%03d\n', ID_1, dxl_present_position_1, ID_2,dxl_present_position_2);
        pause(0.1)
    end

end


% 关闭舵机转矩
write1ByteTxRx(port_num, PROTOCOL_VERSION, ID_1, ADDR_MX_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, ID_2, ADDR_MX_TORQUE_ENABLE, TORQUE_DISABLE);

dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
end

% 关闭端口
closePort(port_num);

% 卸掉加载库
unloadlibrary(lib_name);

close all;
clear all;
