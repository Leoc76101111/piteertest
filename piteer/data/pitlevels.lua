local pitLevels = {
    [1] = 0x1C34EB,
    [2] = 0x1C34EF,
    [3] = 0x1C34F1,
    [4] = 0x1C34F3,
    [5] = 0x1C34F5,
    [6] = 0x1C34F7,
    [7] = 0x1C34F9,
    [8] = 0x1C34FB,
    [9] = 0x1C34FD,
    [10] = 0x1C34FF,
    [11] = 0x1C3501,
    [12] = 0x1C3503,
    [13] = 0x1C3505,
    [14] = 0x1C3507,
    [15] = 0x1C3509,
    [16] = 0x1C350B,
    [17] = 0x1C350D,
    [18] = 0x1C3511,
    [19] = 0x1C3513,
    [20] = 0x1C3515,
    [21] = 0x1C3517,
    [22] = 0x1C3519,
    [23] = 0x1C351B,
    [24] = 0x1C351D,
    [25] = 0x1C351F,
    [26] = 0x1C3521,
    [27] = 0x1C3523,
    [28] = 0x1C3525,
    [29] = 0x1C3527,
    [30] = 0x1C3529,
    [31] = 0x1C352B,
    [32] = 0x1C352D,
    [33] = 0x1C352F,
    [34] = 0x1C3531,
    [35] = 0x1C3533,
    [36] = 0x1C3535,
    [37] = 0x1C3537,
    [38] = 0x1C3539,
    [39] = 0x1C353B,
    [40] = 0x1C353D,
    [41] = 0x1C353F,
    [42] = 0x1C3541,
    [43] = 0x1C3543,
    [44] = 0x1C3545,
    [45] = 0x1C3547,
    [46] = 0x1C354A,
    [47] = 0x1C354C,
    [48] = 0x1C354E,
    [49] = 0x1C3550,
    [50] = 0x1C3552,
    [51] = 0x1C3554,
    [52] = 0x1C3556,
    [53] = 0x1C3558,
    [54] = 0x1C355A,
    [55] = 0x1C355C,
    [56] = 0x1C355E,
    [57] = 0x1C3560,
    [58] = 0x1C3562,
    [59] = 0x1C3564,
    [60] = 0x1C3566,
    [61] = 0x1C3568,
    [62] = 0x1C356A,
    [63] = 0x1C356C,
    [64] = 0x1C356E,
    [65] = 0x1C3570,
    [66] = 0x1C3572,
    [67] = 0x1C3574,
    [68] = 0x1C3577,
    [69] = 0x1C3579,
    [70] = 0x1C357C,
    [71] = 0x1C357E,
    [72] = 0x1C3580,
    [73] = 0x1C3582,
    [74] = 0x1C3584,
    [75] = 0x1C3586,
    [76] = 0x1C3588,
    [77] = 0x1C358A,
    [78] = 0x1C358E,
    [79] = 0x1C3590,
    [80] = 0x1C3593,
    [81] = 0x1C3595,
    [82] = 0x1C3597,
    [83] = 0x1C3599,
    [84] = 0x1C359B,
    [85] = 0x1C359F,
    [86] = 0x1C35A1,
    [87] = 0x1C35A3,
    [88] = 0x1C35A5,
    [89] = 0x1C35A7,
    [90] = 0x1C35A9,
    [91] = 0x1C35AD,
    [92] = 0x1C35AF,
    [93] = 0x1C35B1,
    [94] = 0x1C35B4,
    [95] = 0x1C35B6,
    [96] = 0x1C35B8,
    [97] = 0x1C35BA,
    [98] = 0x1C35BC,
    [99] = 0x1C35BF,
    [100] = 0x1C35C1,
    [101] = 0x1D6CEF,
    [102] = 0x1D6CF3,
    [103] = 0x1D6CF5,
    [104] = 0x1D6CF7,
    [105] = 0x1D6CFB,
    [106] = 0x1D6CFD,
    [107] = 0x1D6D01,
    [108] = 0x1D6D03,
    [109] = 0x1D6D05,
    [110] = 0x1D6D07,
    [111] = 0x1D6D09,
    [112] = 0x1D6D0B,
    [113] = 0x1D6D0F,
    [114] = 0x1D6D11,
    [115] = 0x1D6D13,
    [116] = 0x1D6D15,
    [117] = 0x1D6D19,
    [118] = 0x1D6D1B,
    [119] = 0x1D6D1D,
    [120] = 0x1D6D1F,
    [121] = 0x1D6D21,
    [122] = 0x1D6D23,
    [123] = 0x1D6D25,
    [124] = 0x1D6D27,
    [125] = 0x1D6D2B,
    [126] = 0x1D6D2E,
    [127] = 0x1D6D30,
    [128] = 0x1D6D33,
    [129] = 0x1D6D36,
    [130] = 0x1D6D38,
    [131] = 0x1D6D3A,
    [132] = 0x1D6D3C,
    [133] = 0x1D6D3E,
    [134] = 0x1D6D40,
    [135] = 0x1D6D42,
    [136] = 0x1D6D44,
    [137] = 0x1D6D46,
    [138] = 0x1D6D48,
    [139] = 0x1D6D4A,
    [140] = 0x1D6D4C,
    [141] = 0x1D6D4E,
    [142] = 0x1D6D50,
    [143] = 0x1D6D52,
    [144] = 0x1D6D54,
    [145] = 0x1D6D58,
    [146] = 0x1D6D5A,
    [147] = 0x1D6D5C,
    [148] = 0x1D6D5E,
    [149] = 0x1D6D62,
    [150] = 0x1D6D64
}

return pitLevels
