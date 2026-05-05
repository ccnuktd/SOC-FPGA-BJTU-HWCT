#ifndef __SORT_H__
#define __SORT_H__

#define ARR_LEN 1000

// 插入排序替代原冒泡排序
void sort_insertion(int *arr, int len) {
    for (int i = 1; i < len; i++) {
        int key = arr[i];
        int j = i - 1;
        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = key;
    }
}

void sort_selection(int *arr, int len) {
    int i, j, min_idx;
    for (i = 0; i < len - 1; i++) {
        min_idx = i;
        for (j = i + 1; j < len; j++) {
            if (arr[j] < arr[min_idx]) {
                min_idx = j;
            }
        }
        if (min_idx != i) {
            int tmp = arr[i];
            arr[i] = arr[min_idx];
            arr[min_idx] = tmp;
        }
    }
}

int array_equal(int *a, int *b, int len) {
    int i;
    for (i = 0; i < len; i++) {
        if (a[i] != b[i]) return 0;
    }
    return 1;
}

void init_array(int *arr, int len, int rand) {
    int i;
    for (i = 0; i < len; i++) {
        arr[i] = (len * 73 - rand * 31 + i) % 12343;
    }
}

#endif
