#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <libgen.h>
#include <sys/stat.h> // 디렉토리 존재 여부 확인 및 생성에 필요
#include <sys/types.h>
#include <unistd.h>
#include "floating_point_v7_1_bitacc_cmodel.h"
#include "gmp.h"
#include "mpfr.h"

#define DATA_SIZE 96
#define VECTOR_SIZE 32
#define LINES 100

typedef enum {
    OP_ADD,
    OP_SUB,
    OP_MUL,
    OP_DIV,
    OP_ADD3,
    OP_MAX,
    OP_MAX3,
    OP_AVG,
    OP_AVG3,
    OP_EXP,
    OP_SQRT,
    OP_SQRTRECIPROCAL,
    OP_REDSUM,
    OP_REDMAX,
    OP_INVALID,
    OP_COUNT // 연산자 총 개수
} Operation;

// 연산자 이름 배열
const char* operation_names[] = {
    "add",
    "sub",
    "mul",
    "div",
    "add3",
    "max",
    "max3",
    "avg",
    "avg3",
    "exp",
    "sqrt",
    "reci",
    "redsum",
    "redmax"
};

void bf16_to_fp32(uint16_t bf16_value, float* fp_data) {
    uint32_t sign = (bf16_value >> 15) & 0x1;
    uint32_t exponent = (bf16_value >> 7) & 0xFF;
    uint32_t mantissa = bf16_value & 0x7F;

    uint32_t fp32_bits = (sign << 31)
        | (exponent << 23)
        | (mantissa << 16);

    union {
        float fp32;
        uint32_t bits;
    } float_union;

    float_union.bits = fp32_bits;
    *fp_data = float_union.fp32;
}


uint16_t fp32_to_bf16(float value) {
    uint32_t float_bits;
    memcpy(&float_bits, &value, sizeof(float));

    uint16_t bf16_bits = (uint16_t)(float_bits >> 16);

    return bf16_bits;
}

uint16_t fp32_to_bf16_truncate(float fp32_value) {

    union {
        float fp32;
        uint32_t bits;
    } float_bits;

    float_bits.fp32 = fp32_value;

    uint16_t bf16_bits = (uint16_t)(float_bits.bits >> 16);

    return bf16_bits;
}

void vector_add(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_add(dst[i], src1[i], src2[i]);
    }
}

void vector_sub(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_sub(dst[i], src1[i], src2[i]);
    }
}

void vector_mul(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_mul (dst[i], src1[i], src2[i]);
    }
}

void vector_div(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_div(dst[i], src1[i], src2[i]);
    }
}

void vector_add3(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2, xip_fpo_t* src3) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_add(dst[i], src1[i], src2[i]);
        xip_fpo_add(dst[i], dst[i], src3[i]);
    }
}

void vector_max(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2, int* res) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_greaterequal(res, src1[i], src2[i]);
        if (*res == 1) {
            xip_fpo_set(dst[i], src1[i]);
        }
        else {
            xip_fpo_set(dst[i], src2[i]);
        }
    }
}

void vector_max3(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2, xip_fpo_t* src3, int* res1, int* res2, int* res3) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_greaterequal(res1, src1[i], src2[i]);
        xip_fpo_greaterequal(res2, src2[i], src3[i]);
        xip_fpo_greaterequal(res3, src3[i], src1[i]);

        if (*res1 == 1 && *res3 == 0) {
            xip_fpo_set(dst[i], src1[i]);
        }
        else if (*res2 == 1 && *res1 == 0) {
            xip_fpo_set(dst[i], src2[i]);
        }
        else {
            xip_fpo_set(dst[i], src3[i]);
        }
    }
}

void vector_avg(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2, xip_fpo_t* two) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_add(dst[i], src1[i], src2[i]);
        xip_fpo_div(dst[i], dst[i], *two);
    }
}

void vector_avg3(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* src2, xip_fpo_t* src3, xip_fpo_t* three) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_add(dst[i], src1[i], src2[i]);
        xip_fpo_add(dst[i], dst[i], src3[i]);
        xip_fpo_div(dst[i], dst[i], *three);
    }
}

void vector_exp(xip_fpo_t* dst, xip_fpo_t* src1) {
    float fp32_src[VECTOR_SIZE];
    float fp32_intermed[VECTOR_SIZE];
    uint16_t bf16_intermed[VECTOR_SIZE];
    float fp32_dst[VECTOR_SIZE];
    for (int i = 0; i < VECTOR_SIZE; i++) {
        fp32_src[i] = xip_fpo_get_flt(src1[i]);
        xip_fpo_exp_flt(&fp32_intermed[i], fp32_src[i]);
        bf16_intermed[i] = fp32_to_bf16_truncate(fp32_intermed[i]);
        bf16_to_fp32(bf16_intermed[i], &fp32_dst[i]);
        xip_fpo_set_flt(dst[i], fp32_dst[i]);
    }
}

void vector_sqrt(xip_fpo_t* dst, xip_fpo_t* src1) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_sqrt(dst[i], src1[i]);
    }
}

void vector_sqrtreciprocal(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* one) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_sqrt(dst[i], src1[i]);
    }
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_div(dst[i], *one, dst[i]);
    }
}

void vector_redmax(xip_fpo_t* dst, xip_fpo_t* src1, int* res) {
    for (int i = 0; i < 16; i++) {
        xip_fpo_greater(&res[i], src1[2 * i], src1[2 * i + 1]);
        if (res[i] == 1) {
            xip_fpo_set(dst[i], src1[2 * i]);
        }
        else {
            xip_fpo_set(dst[i], src1[2 * i + 1]);
        }
    }
    for (int i = 0; i < 8; i++) {
        xip_fpo_greater(&res[i + 16], dst[2 * i], dst[2 * i + 1]);
        if (res[i + 16] == 1) {
            xip_fpo_set(dst[i + 16], dst[2 * i]);
        }
        else {
            xip_fpo_set(dst[i + 16], dst[2 * i + 1]);
        }
    }
    for (int i = 0; i < 4; i++) {
        xip_fpo_greater(&res[i + 24], dst[2 * i + 16], dst[2 * i + 17]);
        if (res[i + 24] == 1) {
            xip_fpo_set(dst[i + 24], dst[2 * i + 16]);
        }
        else {
            xip_fpo_set(dst[i + 24], dst[2 * i + 17]);
        }
    }
    xip_fpo_greater(&res[28], dst[24], dst[25]);
    if (res[28] == 1) {
        xip_fpo_set(dst[28], dst[24]);
    }
    else {
        xip_fpo_set(dst[28], dst[25]);
    }
    xip_fpo_greater(&res[29], dst[26], dst[27]);
    if (res[29] == 1) {
        xip_fpo_set(dst[29], dst[26]);
    }
    else {
        xip_fpo_set(dst[29], dst[27]);
    }
    xip_fpo_greater(&res[30], dst[28], dst[29]);
    if (res[30] == 1) {
        xip_fpo_set(dst[30], dst[28]);
    }
    else {
        xip_fpo_set(dst[30], dst[29]);
    }
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_set(dst[i], dst[30]);
    }
}

void vector_redsum(xip_fpo_t* dst, xip_fpo_t* src1) {
    for (int i = 0; i < 16; i++) {
        xip_fpo_add(dst[i], src1[2 * i], src1[2 * i + 1]);
    }
    for (int i = 0; i < 8; i++) {
        xip_fpo_add(dst[i + 16], dst[2 * i], dst[2 * i + 1]);
    }
    for (int i = 0; i < 4; i++) {
        xip_fpo_add(dst[i + 24], dst[2 * i + 16], dst[2 * i + 17]);
    }
    xip_fpo_add(dst[28], dst[24], dst[25]);
    xip_fpo_add(dst[29], dst[26], dst[27]);
    xip_fpo_add(dst[30], dst[28], dst[29]);
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_set(dst[i], dst[30]);
    }
}

void load_data_from_file(const char* input_file, const char* positive_input_file, const char* output_dir) {
    FILE* file = NULL;
    FILE* positive_file = NULL;

    // 출력 디렉토리 확인 및 생성
    struct stat st = {0};
    if (stat(output_dir, &st) == -1) {
        // 디렉토리가 존재하지 않으면 생성
        if (mkdir(output_dir, 0700) != 0) {
            fprintf(stderr, "출력 디렉토리를 생성할 수 없습니다: %s\n", output_dir);
            exit(1);
        }
    }

    // 입력 파일 열기
    file = fopen(input_file, "r");
    if (file == NULL) {
        fprintf(stderr, "입력 파일을 열 수 없습니다: %s\n", input_file);
        exit(1);
    }

    positive_file = fopen(positive_input_file, "r");
    if (positive_file == NULL) {
        fprintf(stderr, "양수 입력 파일을 열 수 없습니다: %s\n", positive_input_file);
        exit(1);
    }

    // 데이터를 미리 저장할 배열
    float fp_data[LINES][DATA_SIZE];
    float positive_fp_data[LINES][DATA_SIZE];
    uint16_t bf_data[DATA_SIZE];
    uint16_t positive_bf_data[DATA_SIZE];

    // 모든 라인에 대해 데이터를 미리 읽어들임
    for (int line = 0; line < LINES; line++) {
        // 일반 입력 파일에서 데이터 읽기
        for (int i = 0; i < DATA_SIZE; i++) {
            if (fscanf(file, "%4hx", &bf_data[i]) != 1) {
                fprintf(stderr, "입력 파일에서 데이터를 읽는 중 오류 발생\n");
                exit(1);
            }
            bf16_to_fp32(bf_data[i], &fp_data[line][i]);
        }
        // 양수 입력 파일에서 데이터 읽기
        for (int i = 0; i < DATA_SIZE; i++) {
            if (fscanf(positive_file, "%4hx", &positive_bf_data[i]) != 1) {
                fprintf(stderr, "양수 입력 파일에서 데이터를 읽는 중 오류 발생\n");
                exit(1);
            }
            bf16_to_fp32(positive_bf_data[i], &positive_fp_data[line][i]);
        }
    }

    fclose(file);
    fclose(positive_file);

    xip_fpo_exp_t exp_prec = 8;
    xip_fpo_exp_t mant_prec = 8;

    xip_fpo_t src1[VECTOR_SIZE], src2[VECTOR_SIZE], src3[VECTOR_SIZE];
    xip_fpo_t dst[VECTOR_SIZE];

    xip_fpo_t one, two, three;

    int res1[VECTOR_SIZE] = {0};
    int res2[VECTOR_SIZE] = {0};
    int res3[VECTOR_SIZE] = {0};
    int res[VECTOR_SIZE] = {0};

    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_init2(src1[i], exp_prec, mant_prec);
        xip_fpo_init2(src2[i], exp_prec, mant_prec);
        xip_fpo_init2(src3[i], exp_prec, mant_prec);
        xip_fpo_init2(dst[i], exp_prec, mant_prec);
    }

    xip_fpo_inits2(exp_prec, mant_prec, one, two, three, (xip_fpo_ptr)0);
    xip_fpo_set_ui(one, 1);
    xip_fpo_set_ui(two, 2);
    xip_fpo_set_ui(three, 3);

    for (int line = 0; line < LINES; line++) {
        // 모든 연산에 대해 반복
        for (int op_code = OP_ADD; op_code < OP_COUNT; op_code++) {
            float* current_fp_data;

            // 연산에 따라 적절한 데이터 선택
            if (op_code == OP_SQRT || op_code == OP_SQRTRECIPROCAL) {
                current_fp_data = positive_fp_data[line];
            } else {
                current_fp_data = fp_data[line];
            }

            // 입력 데이터를 설정
            for (int i = 0; i < VECTOR_SIZE; i++) {
                xip_fpo_set_flt(src1[i], current_fp_data[i]);
                xip_fpo_set_flt(src2[i], current_fp_data[i + 32]);
                xip_fpo_set_flt(src3[i], current_fp_data[i + 64]);
            }

            // 해당 연산 수행
            switch (op_code) {
                case OP_ADD:
                    vector_add(dst, src1, src2);
                    break;
                case OP_SUB:
                    vector_sub(dst, src1, src2);
                    break;
                case OP_MUL:
                    vector_mul(dst, src1, src2);
                    break;
                case OP_DIV:
                    vector_div(dst, src1, src2);
                    break;
                case OP_ADD3:
                    vector_add3(dst, src1, src2, src3);
                    break;
                case OP_MAX:
                    vector_max(dst, src1, src2, res1);
                    break;
                case OP_MAX3:
                    vector_max3(dst, src1, src2, src3, res1, res2, res3);
                    break;
                case OP_AVG:
                    vector_avg(dst, src1, src2, &two);
                    break;
                case OP_AVG3:
                    vector_avg3(dst, src1, src2, src3, &three);
                    break;
                case OP_EXP:
                    vector_exp(dst, src1);
                    break;
                case OP_SQRT:
                    vector_sqrt(dst, src1);
                    break;
                case OP_SQRTRECIPROCAL:
                    vector_sqrtreciprocal(dst, src1, &one);
                    break;
                case OP_REDSUM:
                    vector_redsum(dst, src1);
                    break;
                case OP_REDMAX:
                    vector_redmax(dst, src1, res);
                    break;
                default:
                    continue; // 알 수 없는 연산자는 건너뜀
            }

            // 출력 파일 이름 생성
            char output_filename[512];
            snprintf(output_filename, sizeof(output_filename), "%s/%s_out.txt", output_dir, operation_names[op_code]);

            FILE* output_file = fopen(output_filename, "a"); // 결과를 추가 모드로 저장
            if (output_file == NULL) {
                fprintf(stderr, "출력 파일을 열 수 없습니다: %s\n", output_filename);
                exit(1);
            }

            // 결과를 파일에 저장
            for (int i = 0; i < VECTOR_SIZE; i++) {
                float fp_result = xip_fpo_get_flt(dst[i]);
                uint16_t bf_result = fp32_to_bf16(fp_result);
                fprintf(output_file, "%04x ", bf_result);
            }
            fprintf(output_file, "\n");

            fclose(output_file);
        }
    }

    // 메모리 해제
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_clears(src1[i], src2[i], src3[i], dst[i], (xip_fpo_ptr)0);
    }

    xip_fpo_clears(one, two, three, (xip_fpo_ptr)0);
}

int main(int argc, char *argv[]) {
    if (argc != 7 || strcmp(argv[1], "-input") != 0 || strcmp(argv[3], "-positive_input") != 0 || strcmp(argv[5], "-output") != 0) {
        fprintf(stderr, "사용법: %s -input <input_file> -positive_input <positive_input_file> -output <output_dir>\n", argv[0]);
        return 1;
    }

    const char* input_filename = argv[2];
    const char* positive_input_filename = argv[4];
    const char* output_dir = argv[6];

    load_data_from_file(input_filename, positive_input_filename, output_dir);

    return 0;
}