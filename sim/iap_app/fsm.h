#ifndef __FSM_H__
#define __FSM_H__

#define FSM_ROUNDS 5000
#define FSM_TRACE_LEN 256

typedef enum {
    STATE_A = 0,
    STATE_B,
    STATE_C,
    STATE_D
} FSMState;

unsigned char trace[FSM_TRACE_LEN];

int fsm_transition(FSMState s, int input) {
    switch (s) {
        case STATE_A: return (input % 2 == 0) ? STATE_B : STATE_C;
        case STATE_B: return (input % 3 == 0) ? STATE_C : STATE_D;
        case STATE_C: return (input % 5 == 0) ? STATE_D : STATE_A;
        case STATE_D: return (input % 7 == 0) ? STATE_A : STATE_B;
        default: return STATE_A;
    }
}

int run_fsm_test() {
    FSMState state = STATE_A;
    int checksum = 0;

    for (int j = 0; j < FSM_ROUNDS; j++) {
        for (int i = 0; i < FSM_TRACE_LEN; i++) {
            trace[i] = (unsigned char)state;
            state = fsm_transition(state, i * 17 + 23);
            checksum += state * (i + 1);
        }
    }

    const int expected_checksum = 259865001;  // 稳定输入下的“黄金值”
    if (checksum != expected_checksum) return 0;

    // 防错扰动：改变初始状态或输入序列应得不同 checksum
    FSMState altered = STATE_B;
    int disturbed_checksum = 0;

    for (int j = 0; j < FSM_ROUNDS; j++) {
        for (int i = 0; i < FSM_TRACE_LEN; i++) {
            altered = fsm_transition(altered, i * 19 + 31);
            disturbed_checksum += altered * (i + 1);
        }
    }
    if (disturbed_checksum == expected_checksum) return 0; // 干扰也正确就说明逻辑错了

    return 1;
}

#endif
