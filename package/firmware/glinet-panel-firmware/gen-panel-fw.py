import os

# The BE10000 and the BE14000 carry the same ST7789P3, mounted 180 degrees
# apart, so the init sequence is shared and only MADCTL differs. Both values
# set MV, so both panels are landscape 320x240.
#
#   0xA0 = MV|MY = 270 degrees, BE10000
#   0x60 = MV|MX =  90 degrees, BE14000
#
# panel-mipi-dbi names the firmware after the first compatible string of the
# panel node, so each board gets its own blob under its own name.
boards = [
    ('gl-panel.bin', 0xA0),
    ('gl-be14000-panel.bin', 0x60),
]


# vendor st7789p3 init_display() sequence, ('cmd', [params]) or ('delay', ms)
def sequence(madctl):
    return [
        (0x11, []),            # SLPOUT
        ('delay', 120),
        (0x36, [madctl]),      # MADCTL
        (0x3A, [0x05]),        # COLMOD 16bpp/RGB565
        (0xB2, [0x05,0x05,0x00,0x33,0x33]),  # PORCTRL
        (0xB7, [0x35]),        # GCTRL
        (0xBB, [0x21]),        # VCOMS
        (0xC0, [0x2C]),        # LCMCTRL
        (0xC2, [0x01]),        # VDVVRHEN
        (0xC3, [0x0B]),        # VRHS
        (0xC4, [0x20]),        # VDVS
        (0xC6, [0x0A]),        # FRCTRL2
        (0xD0, [0xA7,0xA1]),   # PWCTRL1
        (0xD0, [0xA4,0xA1]),   # PWCTRL1
        (0x35, [0x00]),        # TEON
        (0xD6, [0xA1]),        # vendor
        (0xE0, [0xD0,0x04,0x08,0x0A,0x09,0x05,0x2D,0x43,0x49,0x09,0x16,0x15,0x26,0x2B]),  # PVGAMCTRL
        (0xE1, [0xD0,0x03,0x09,0x0A,0x0A,0x06,0x2E,0x44,0x40,0x3A,0x15,0x15,0x26,0x2A]),  # NVGAMCTRL
        (0x21, []),            # INVON
        ('delay', 10),
        (0x29, []),            # DISPON
        ('delay', 120),
    ]


for name, madctl in boards:
    out = bytearray(b'MIPI DBI' + b'\x00'*7 + b'\x01')

    for c, p in sequence(madctl):
        if c == 'delay':
            out += bytes([0x00, 0x01, p & 0xff])
        else:
            out += bytes([c, len(p)] + p)

    dst = os.path.join(os.path.dirname(__file__), 'files', name)
    open(dst, 'wb').write(out)
    print("wrote", dst, "size", len(out), "madctl 0x%02x" % madctl)
