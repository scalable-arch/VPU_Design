import random

# BF16 데이터를 생성하는 함수 (NaN과 Infinity를 제외한 값)
def generate_bf16_data():
    # 부호 비트 (0 또는 1)
    sign = random.randint(0, 1)
    # 지수부 (0x00부터 0xFE까지, 0xFF 제외)
    exponent = random.randint(0x01, 0xFE)
    # 가수부 (0x00부터 0x7F까지)
    significand = random.randint(0x01, 0x7F)
    # BF16 값 생성
    bf16_value = (sign << 15) | (exponent << 7) | significand
    return bf16_value

# BF16 데이터를 96개 생성하고 파일에 쓰는 함수
def create_bf16_file(filename, num_lines=100):
    with open(filename, 'w') as file:
        for _ in range(num_lines):
            bf16_data = [f"{generate_bf16_data():04x}" for _ in range(96)]  # 96개의 BF16 데이터 생성
            file.write(" ".join(bf16_data) + "\n")  # 한 줄에 96개 데이터를 공백으로 구분하여 작성

# 파일 생성
create_bf16_file("bf16_numbers.txt")
