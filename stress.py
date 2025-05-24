with open("stress", "wb") as f:
    for x in range(0, 256):
        f.write(bytes([y for y in range(0, 256)]))
