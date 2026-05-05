#ifndef __CRC_H__
#define __CRC_H__

#define CRC_SIZE 2048
#define CRC_LOOP_COUNT 300

unsigned char crc_buffer[CRC_SIZE];

// 标准 CRC-16 MODBUS 实现
unsigned short crc16_modbus(unsigned char* data, int len) {
    unsigned short crc = 0xFFFF;
    for (int i = 0; i < len; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            if (crc & 1)
                crc = (crc >> 1) ^ 0xA001;
            else
                crc >>= 1;
        }
    }
    return crc;
}

// 每轮数据初始化（确定性）
void init_crc_buffer(int seed) {
    for (int i = 0; i < CRC_SIZE; i++) {
        crc_buffer[i] = (i * 17 + seed * 23 + 29) % 256;
    }
}

// CRC 测试函数（多轮，且不依赖 expected_crc 硬编码）
int run_crc_test() {
    for (int round = 0; round < CRC_LOOP_COUNT; round++) {
        init_crc_buffer(round);

        // 计算正确 CRC
        unsigned short crc_ok = crc16_modbus(crc_buffer, CRC_SIZE);

        // 引入错误后再计算
        crc_buffer[round * 123 % CRC_SIZE] ^= 0x5A;
        unsigned short crc_err = crc16_modbus(crc_buffer, CRC_SIZE);
        crc_buffer[round * 123 % CRC_SIZE] ^= 0x5A;  // 恢复

        // 检查：篡改后 CRC 必须不相等；恢复后必须一致
        unsigned short crc_verify = crc16_modbus(crc_buffer, CRC_SIZE);

        if (crc_ok == crc_err) return 0;         // 错误未被检测出
        if (crc_verify != crc_ok) return 0;      // 恢复后未恢复成功
    }

    return 1;
}

#endif
