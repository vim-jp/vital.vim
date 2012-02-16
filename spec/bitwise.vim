source spec/base.vim

let g:B = vital#of('vital').import('Bitwise')

Context Bitwise.lshift()
  It shifts bits to left
    Should g:B.lshift(0, 0) == 0
    Should g:B.lshift(0, 1) == 0
    Should g:B.lshift(0, 31) == 0
    Should g:B.lshift(0, 32) == 0
    Should g:B.lshift(1, 0) == 0x1
    Should g:B.lshift(1, 1) == 0x2
    Should g:B.lshift(1, 31) == 0x80000000
    Should g:B.lshift(1, 32) == 1
    Should g:B.lshift(0x80000000, 0) == 0x80000000
    Should g:B.lshift(0x80000000, 1) == 0
  End
  It shifts bits to left (random)
    Should g:B.lshift(1483929134, 14) == -1114931200
    Should g:B.lshift(152442939, 25) == 1979711488
    Should g:B.lshift(505850863, -32) == 505850863
    Should g:B.lshift(1997594360, 18) == 2078277632
    Should g:B.lshift(2121708807, -5) == 939524096
    Should g:B.lshift(344493590, -27) == -1861107008
    Should g:B.lshift(630127521, 14) == -1092075520
    Should g:B.lshift(-601661263, 0) == -601661263
    Should g:B.lshift(661012213, -26) == -644891328
    Should g:B.lshift(828605241, -14) == 216268800
  End
End

Context Bitwise.rshift()
  It shifts bits to right
    Should g:B.rshift(0, 0) == 0
    Should g:B.rshift(0, 1) == 0
    Should g:B.rshift(0, 31) == 0
    Should g:B.rshift(0, 32) == 0
    Should g:B.rshift(0x80000000, 0) == 0x80000000
    Should g:B.rshift(0x80000000, 1) == 0x40000000
    Should g:B.rshift(0x80000000, 31) == 0x1
    Should g:B.rshift(0x80000000, 32) == 0x80000000
    Should g:B.rshift(1, 0) == 0x1
    Should g:B.rshift(1, 1) == 0
  End
  It shifts bits to right (random)
    Should g:B.rshift(-488472937, -18) == 232329
    Should g:B.rshift(2077835096, 9) == 4058271
    Should g:B.rshift(-944346085, -27) == 104706912
    Should g:B.rshift(-410125501, -23) == 7587581
    Should g:B.rshift(-976767239, 10) == 3240429
    Should g:B.rshift(999071336, 20) == 952
    Should g:B.rshift(1103884747, -13) == 2105
    Should g:B.rshift(1971440513, -1) == 0
    Should g:B.rshift(-440231805, -25) == 30115121
    Should g:B.rshift(1872776440, 23) == 223
  End
End

Context Bitwise.compare()
  It compares as unsigned int
    Should g:B.compare(2, 1) == 1
    Should g:B.compare(0xFFFFFFFE, 0xFFFFFFFF) == -1
    Should g:B.compare(0x0FFFFFFF, 0xFFFFFFFF) == -1
  End
End

Context Bitwise.invert()
  It returns bitwise invert
    Should g:B.invert(0) == -0x1
    Should g:B.invert(0xffffffff) == -0x100000000
    Should g:B.invert(0xf0f0f0f) == -0xf0f0f10
    Should g:B.invert(0xf0f0f0f0) == -0xf0f0f0f1
    Should g:B.invert(0xffff) == -0x10000
    Should g:B.invert(0xff) == -0x100
    Should g:B.invert(0xffffff) == -0x1000000
  End
  It returns bitwise invert (random)
    Should g:B.invert(-2104009955) == 2104009954
    Should g:B.invert(-1317510048) == 1317510047
    Should g:B.invert(1806018573) == -1806018574
    Should g:B.invert(-980665656) == 980665655
    Should g:B.invert(-537231506) == 537231505
    Should g:B.invert(-46151799) == 46151798
    Should g:B.invert(1213208697) == -1213208698
    Should g:B.invert(943205096) == -943205097
    Should g:B.invert(2015127505) == -2015127506
    Should g:B.invert(35201008) == -35201009
  End
End

Context Bitwise.and()
  It returns bitwise AND
    Should g:B.and(0, 0) == 0
    Should g:B.and(0xffffffff, 0) == 0
    Should g:B.and(0xffffffff, 0xffffffff) == 0xffffffff
    Should g:B.and(0xf0f0f0f0, 0xf0f0f0f) == 0
    Should g:B.and(0xf0f0f0f0, 0xf0f0f0f0) == 0xf0f0f0f0
    Should g:B.and(0xffff0000, 0xffff) == 0
    Should g:B.and(0xff000000, 0xff) == 0
    Should g:B.and(0xffffff00, 0xffffff) == 0xffff00
  End
  It returns bitwise AND (random)
    Should g:B.and(-1296912273, -1904774433) == -2110640049
    Should g:B.and(432461732, -859843378) == 143053956
    Should g:B.and(2098863212, 959746948) == 957353988
    Should g:B.and(144789504, -1435475015) == 136331264
    Should g:B.and(-1325876821, -209876503) == -1334277719
    Should g:B.and(-484132304, 491371309) == 16824864
    Should g:B.and(-1787481070, 1602359046) == 352322562
    Should g:B.and(-516431469, 1421177042) == 1077239954
    Should g:B.and(-2028633248, 1046228473) == 101974368
    Should g:B.and(764178285, 2068092473) == 688129577
  End
End

Context Bitwise.or()
  It returns bitwise OR
    Should g:B.or(0, 0) == 0
    Should g:B.or(0xffffffff, 0) == 0xffffffff
    Should g:B.or(0xffffffff, 0xffffffff) == 0xffffffff
    Should g:B.or(0xf0f0f0f0, 0xf0f0f0f) == 0xffffffff
    Should g:B.or(0xf0f0f0f0, 0xf0f0f0f0) == 0xf0f0f0f0
    Should g:B.or(0xffff0000, 0xffff) == 0xffffffff
    Should g:B.or(0xff000000, 0xff) == 0xff0000ff
    Should g:B.or(0xffffff00, 0xffffff) == 0xffffffff
  End
  It returns bitwise OR (random)
    Should g:B.or(173374042, -686154780) == -547390466
    Should g:B.or(988002410, 1611007623) == 2062008047
    Should g:B.or(1617121838, 2063766753) == 2070140655
    Should g:B.or(-68314761, -1067373081) == -68305417
    Should g:B.or(2110784177, 1692066345) == 2111496889
    Should g:B.or(-2063323858, -1250703135) == -1250431505
    Should g:B.or(-555502256, 1817484023) == -17317897
    Should g:B.or(1840020982, 1846433830) == 1873706486
    Should g:B.or(-1642487163, -2106395568) == -1636043051
    Should g:B.or(1706960204, 865619605) == 2008969181
  End
End

Context Bitwise.xor()
  It returns bitwise XOR
    Should g:B.xor(0, 0) == 0
    Should g:B.xor(0xffffffff, 0) == 0xffffffff
    Should g:B.xor(0xffffffff, 0xffffffff) == 0
    Should g:B.xor(0xf0f0f0f0, 0xf0f0f0f) == 0xffffffff
    Should g:B.xor(0xf0f0f0f0, 0xf0f0f0f0) == 0
    Should g:B.xor(0xffff0000, 0xffff) == 0xffffffff
    Should g:B.xor(0xff000000, 0xff) == 0xff0000ff
    Should g:B.xor(0xffffff00, 0xffffff) == 0xff0000ff
  End
  It returns bitwise XOR (random)
    Should g:B.xor(271738232, 581446732) == 848972084
    Should g:B.xor(-1493178930, 1597520677) == -104341781
    Should g:B.xor(-1605313579, -452835553) == 1163041994
    Should g:B.xor(-2010996666, 1805365375) == -474410951
    Should g:B.xor(189013461, 1428653660) == 1583586185
    Should g:B.xor(927050540, 304702767) == 627625475
    Should g:B.xor(-651395973, 726399460) == -228096609
    Should g:B.xor(292595176, -1074885945) == -1365364945
    Should g:B.xor(1544212087, -476653766) == -1080288947
    Should g:B.xor(838539477, 1024734483) == 217001414
  End
End

