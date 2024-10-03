#include <stdio.h>
#include <stdlib.h>
#define _USE_MATH_DEFINES 1 // required for M_E to be found in math.h when compiling on Windows
#include <math.h>
#include <float.h>
#include <string.h>
#include "floating_point_v7_1_bitacc_cmodel.h" // Must include before GMP and MPFR (see comments in the file for why)
#include "gmp.h"
#include "mpfr.h"
#include <libgen.h> 

#define DATA_SIZE 96
#define VECTOR_SIZE 32
#define LINES 100

void bf16_to_fp32(uint16_t bf16_value, float* fp_data) {
    uint32_t sign = (bf16_value >> 15) & 0x1;
    uint32_t exponent = (bf16_value >> 7) & 0xFF;
    uint32_t mantissa = bf16_value & 0x7F;

    uint32_t fp32_bits = (sign << 31)
        | (exponent << 23)
        | (mantissa << 16);

    *((uint32_t*)fp_data) = fp32_bits;
}

uint16_t fp32_to_bf16(float value) {
    uint32_t float_bits;
    memcpy(&float_bits, &value, sizeof(float));

    uint16_t bf16_bits = (uint16_t)(float_bits >> 16);

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
        xip_fpo_greater(res, src1[i], src2[i]);
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
        xip_fpo_greater(res1, src1[i], src2[i]);
        xip_fpo_greater(res2, src2[i], src3[i]);
        xip_fpo_greater(res3, src3[i], src1[i]);

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
    float fp32_dst[VECTOR_SIZE];
    for (int i = 0; i < VECTOR_SIZE; i++) {
        fp32_src[i] = xip_fpo_get_flt(src1[i]);
        xip_fpo_exp_flt(&fp32_dst[i], fp32_src[i]);
        xip_fpo_set_flt(dst[i], fp32_dst[i]);
    }
}

void vector_sqrt(xip_fpo_t* dst, xip_fpo_t* src1) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_sqrt(dst[i], src1[i]);
    }
}

void vector_reciprocal(xip_fpo_t* dst, xip_fpo_t* src1, xip_fpo_t* one) {
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_div(dst[i], *one, src1[i]);
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

void load_data_from_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    FILE* output_file = fopen("exapmle_out.txt", "w");

    float fp_data[DATA_SIZE];
    float fp_result[VECTOR_SIZE];
    uint16_t bf_data[DATA_SIZE];
    uint16_t bf_result[VECTOR_SIZE];
    uint8_t sign = 0;
    uint8_t exponent = 0;
    uint16_t mantissa = 0;

    xip_fpo_exp_t exp_prec, mant_prec;
    exp_prec = 8;
    mant_prec = 8;
    xip_fpo_exp_t exp1, exp2, exp3, exp4;
    char* result1 = 0;
    char* result2 = 0;
    char* result3 = 0;
    char* result4 = 0;

    xip_fpo_t src1[VECTOR_SIZE], src2[VECTOR_SIZE], src3[VECTOR_SIZE], dst[VECTOR_SIZE];
    xip_fpo_t src_for_exp[VECTOR_SIZE];
    xip_fpo_t one, two, three;

    int res1 = 0;
    int res2 = 0;
    int res3 = 0;
    int res[VECTOR_SIZE];

    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_init2(src1[i], exp_prec, mant_prec);
        xip_fpo_init2(src2[i], exp_prec, mant_prec);
        xip_fpo_init2(src3[i], exp_prec, mant_prec);
        xip_fpo_init2(src_for_exp[i], exp_prec, mant_prec);
        xip_fpo_init2(dst[i], exp_prec, mant_prec);
        res[i] = 0;
    }

    xip_fpo_inits2(exp_prec, mant_prec, one, two, three, (xip_fpo_ptr)0);
    xip_fpo_set_ui(one, 1);
    xip_fpo_set_ui(two, 2);
    xip_fpo_set_ui(three, 3);

    for (int line = 0; line < LINES; line++) {

        for (int i = 0; i < DATA_SIZE; i++) {
            fscanf(file, "%4hx", &bf_data[i]);
            bf16_to_fp32(bf_data[i], &fp_data[i]);
        }

        for (int i = 0; i < VECTOR_SIZE; i++) {
            xip_fpo_set_flt(src1[i], fp_data[i]);
            xip_fpo_set_flt(src2[i], fp_data[i + 32]);
            xip_fpo_set_flt(src3[i], fp_data[i + 64]);
        }

        // vector add
        // dst = src1 + src2
        //----------------------------------------------------------
        //vector_add(dst, src1, src2);

        // vector sub
        // dst = src1 - src2
        //----------------------------------------------------------
        //vector_sub(dst, src1, src2);

        // vector mul
        // dst = src1 * src2
        //----------------------------------------------------------
        //vector_mul(dst, src1, src2);

        // vector div
        // dst = src1 / src2
        //----------------------------------------------------------
        //vector_div(dst, src1, src2);

        // vector add3
        // dst = src1 + src2 + src3
        //----------------------------------------------------------
        //vector_add3(dst, src1, src2, src3);

        // vector max
        // dst = max(src1, src2)
        //----------------------------------------------------------
        //vector_max(dst, src1, src2, res1);

        // vector max3
        // dst = max(src1, src2, src3)
        //----------------------------------------------------------
        //vector_max3(dst, src1, src2, src3, res1, res2, res3);

        // vector avg
        // dst = (src1 + src2)/2
        //----------------------------------------------------------
        //vector_avg(dst, src1, src2, two);

        // vector avg3
        // dst = (src1 + src2 + src3)/3
        //----------------------------------------------------------
        //vector_avg3(dst, src1, src2, src3, three);

        // vector exp
        // dst = exp(src1)
        //----------------------------------------------------------
        //vector_exp(dst, src1);

        // vector sqrt
        // dst = sqrt(src1)
        //----------------------------------------------------------
        vector_sqrt(dst, src1);

        // vector reciprocal
        // dst = 1/src1
        //----------------------------------------------------------
        //vector_reciprocal(dst, src1, one);

        // vector redsum
        // dst = sumofall( src1[i] )
        // adder tree
        //----------------------------------------------------------
        //vector_redsum(dst, src1);

        // vector redmax
        // dst = max(src1[i])
        //----------------------------------------------------------
        //vector_redmax(dst, src1, res);

        // convert bf16 dst(xip_fpo_t) to fp32
        // and convert agaion fp32 to bf16 (uint16_t)
        // write to txt file
        for (int i = 0; i < VECTOR_SIZE; i++) {
            fp_result[i] = xip_fpo_get_flt(dst[i]);
            bf_result[i] = fp32_to_bf16(fp_result[i]);
        }
        for (int i = 0; i < VECTOR_SIZE; i++) {
            fprintf(output_file, "%04x ", bf_result[i]);
        }
        fprintf(output_file, "\n");
    }
    
    for (int i = 0; i < VECTOR_SIZE; i++) {
        xip_fpo_clears(src1[i], src2[i], src3[i], dst[i], (xip_fpo_ptr)0);
    }

    fclose(file);
    fclose(output_file);
}

int main(int argc, char *argv[]) {
    if (argc != 3 || strcmp(argv[1], "-input") != 0) {
        fprintf(stderr, "Usage: %s -input <input_file>\n", argv[0]);
        return 1;
    }

    const char* input_filename = argv[2];
    char* filename_only = basename((char*)input_filename);

    load_data_from_file(input_filename);

    return 0;
}