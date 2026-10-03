#!/bin/sh
# Hiscore restore/save path on After Burner (Ver 1.32): the saved table is
# streamed in through the 16-bit ioctl path, the game boots and wipes its
# table, hiscore.v puts the saved one back, then an OSD open and an index 4
# upload read the same bytes back. Both checks must print PASS.
# Both fixtures are written here (verif/golden/ is not in git):
#   hs_cfg.bin  = tools/gen_mra.py hiscore_config("aburner")
#   hs_dump.bin = the game's own default table (from a MAME nvram file, CPU
#                 byte order) with every letter shifted by three
set -e
cd "$(dirname "$0")/../.."
mkdir -p verif/golden/aburner
python3 - <<'PYEOF'
import sys; sys.path.insert(0, "tools"); import gen_mra, romsets
open("verif/golden/aburner/hs_cfg.bin", "wb").write(gen_mra.hiscore_config(romsets.ROMSETS["aburner"]))
open("verif/golden/aburner/hs_dump.bin", "wb").write(bytes.fromhex(
    "0070000042582e20100000050000006500004e4c505809000004000000600000454c51200800000300000058000056444744070000020000005300004e4c4252060000010000004800004b4c555205000000000000400000424456580400000000000035000057444e44030000000000002500005752"))
PYEOF
pkill -f Vtb_board 2>/dev/null || true
make -C verif/board run GAME=aburner FRAMES=${FRAMES:-70} PLUSARGS="+hiscore=$PWD/verif/golden/aburner +hs_check=${HS_CHECK:-60} +ana_mode=0" 2>&1 | tee verif/board/out/hiscore.log | grep -E "HISCORE|RENDER ABORT" || true
grep -q "restore check.*PASS" verif/board/out/hiscore.log && grep -q "upload check.*PASS" verif/board/out/hiscore.log && echo "hiscore: PASS" || { echo "hiscore: FAIL"; exit 1; }
