#include <stdio.h>
#include <stdlib.h>

// 환경 변수를 읽어오는 함수
extern "C" {
    const char* get_env_var(const char* var_name) {
        // 환경 변수 가져오기
        const char* value = getenv(var_name);
        
        // NULL 체크: 환경 변수가 존재하지 않을 경우
        if (value == NULL) {
            return "Environment variable not found"; // 또는 적절한 에러 메시지
        }
        return value; // 환경 변수 값을 반환
    }
}