import sys


def bin_to_coe(bin_file, coe_file, word_width=32):
    with open(bin_file, "rb") as f:
        data = f.read()

    word_bytes = word_width // 8
    words = []

    if len(data) % word_bytes != 0:
        data += b"\x00" * (word_bytes - len(data) % word_bytes)

    for i in range(0, len(data), word_bytes):
        word = data[i:i + word_bytes]
        hex_word = "".join(f"{b:02x}" for b in reversed(word))
        words.append(hex_word)

    with open(coe_file, "w") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        f.write(",\n".join(words))
        if not words:
            f.write("00000000")
        f.write(";\n")

    print(f"Converted {bin_file} -> {coe_file} ({len(words)} words)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python/python3 bin2coe.py input.bin")
        sys.exit(1)

    bin_to_coe(sys.argv[1], "./rom.coe")
