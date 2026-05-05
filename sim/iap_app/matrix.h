#ifndef __MATRIX_H__
#define __MATRIX_H__

#define M_SIZE 30

typedef int Matrix[M_SIZE][M_SIZE];

void matmul_naive(Matrix A, Matrix B, Matrix C) {
    int i, j, k;
    for (i = 0; i < M_SIZE; i++) {
        for (j = 0; j < M_SIZE; j++) {
            int sum = 0;
            for (k = 0; k < M_SIZE; k++) {
                sum += A[i][k] * B[k][j];
            }
            C[i][j] = sum;
        }
    }
}

void matmul_transpose(Matrix A, Matrix B, Matrix C) {
    Matrix B_T;
    int i, j, k;

    // 先转置 B 到 B_T
    for (i = 0; i < M_SIZE; i++) {
        for (j = 0; j < M_SIZE; j++) {
            B_T[j][i] = B[i][j];
        }
    }

    // 再乘法
    for (i = 0; i < M_SIZE; i++) {
        for (j = 0; j < M_SIZE; j++) {
            int sum = 0;
            for (k = 0; k < M_SIZE; k++) {
                sum += A[i][k] * B_T[j][k];
            }
            C[i][j] = sum;
        }
    }
}

int verify(Matrix A, Matrix B) {
    int i, j;
    for (i = 0; i < M_SIZE; i++) {
        for (j = 0; j < M_SIZE; j++) {
            if (A[i][j] != B[i][j]) {
                return 0;
            }
        }
    }
    return 1;
}

void init_matrix(Matrix M, int seed) {
    int i, j;
    for (i = 0; i < M_SIZE; i++) {
        for (j = 0; j < M_SIZE; j++) {
            M[i][j] = (i * j + seed) % 100;
        }
    }
}

#endif
