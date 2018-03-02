% ��Ҫ�޸ĵĵط���
% 1.ID = ?; ͨ�������������
% 2.DEVICENAME = 'COM?'; ͨ���豸�������鿴

clc;
clear all;

lib_name = '';
%���ݲ�ͬ��ϵͳѡ��ͬ�Ŀ���������Ϊ�ַ���
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

% ���ؿ�
if ~libisloaded(lib_name)
    [notfound, warnings] = loadlibrary(lib_name, 'dynamixel_sdk.h', 'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

% ���Ʊ��ַ
ADDR_MX_TORQUE_ENABLE       = 24;           % Torque Enable (24)��0��1��
ADDR_MX_GOAL_POSITION       = 30;           % Goal Position (30)�� 0 ~ 1023����λ 0.29��
ADDR_MX_PRESENT_POSITION    = 36;           % Present Position (36)�� 0~1023����λ 0.29��

% Э��汾
PROTOCOL_VERSION            = 1.0;          % RX-64ʹ�õ���Э��1.0

% Ĭ������
ID_1                        = 1;            % ID (3)
ID_2                        = 12;
BAUDRATE                    = 57142;        % Baud Rate (4)
DEVICENAME                  = 'COM5';       % �˿ں�

TORQUE_ENABLE               = 1;            % Torque Enable ��
TORQUE_DISABLE              = 0;            % Torque Enable ��

ESC_CHARACTER               = 'e';          % ��'e'�����˳�ѭ��

COMM_SUCCESS                = 0;            % ͨ�ųɹ����ֵ
COMM_TX_FAIL                = -1001;        % ͨ�ŷ���ʧ��


% ��ʼ���˿�
port_num = portHandler(DEVICENAME);
packetHandler();

dxl_comm_result = COMM_TX_FAIL;             % ͨ�Ž��
dxl_error = 0;                              % �������

% �򿪶˿�
if (openPort(port_num))
    fprintf('Succeeded to open the port!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to open the port!\n');
    input('Press any key to terminate...\n');
    return;
end


% ���ò�����
if (setBaudRate(port_num, BAUDRATE))
    fprintf('Succeeded to change the baudrate!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to change the baudrate!\n');
    input('Press any key to terminate...\n');
    return;
end


% ���1��ʹ�ܣ����2ʹ��
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

% ѭ��
while 1

    if input('Press any key to continue! (or input e to quit!)\n', 's') == ESC_CHARACTER
        break;
    end

    for i=1:100
        % ����ǰ��λ��
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
        %�����ǰλ��
        fprintf('[ID:%03d]  PresPos:%03d  [ID:%03d]  PresPos:%03d\n', ID_1, dxl_present_position_1, ID_2,dxl_present_position_2);
        pause(0.1)
    end

end


% �رն��ת��
write1ByteTxRx(port_num, PROTOCOL_VERSION, ID_1, ADDR_MX_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, ID_2, ADDR_MX_TORQUE_ENABLE, TORQUE_DISABLE);

dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
end

% �رն˿�
closePort(port_num);

% ж�����ؿ�
unloadlibrary(lib_name);

close all;
clear all;
