# Generates nes/src/bosses_chr.inc: 32x32 boss art for stages 3-6.
# Symmetric bosses are authored as 16-char left halves and mirrored;
# the Bastion is built programmatically (asymmetric, faces left).
$ErrorActionPreference = "Stop"

function Mirror([string[]]$halves) {
    $rows = @()
    foreach ($h in $halves) {
        if ($h.Length -ne 16) { throw "half not 16 chars: '$h' ($($h.Length))" }
        $rev = -join ($h.ToCharArray()[15..0])
        $rows += ($h + $rev)
    }
    return $rows
}

function Validate([string]$name, [string[]]$rows) {
    if ($rows.Count -ne 32) { throw "$name has $($rows.Count) rows" }
    foreach ($r in $rows) {
        if ($r.Length -ne 32) { throw "$name row not 32 chars: '$r' ($($r.Length))" }
        if ($r -notmatch '^[0-3]+$') { throw "$name bad chars: '$r'" }
    }
}

# ---- KRAKEN (stage 3): bio squid, two eyes, trailing tentacles ----
$kraken = Mirror @(
    "0000000000111111",
    "0000000111222222",
    "0000011122222222",
    "0000111222222222",
    "0001112222222222",
    "0011122222222222",
    "0011222222222222",
    "0111222033330222",
    "0112222033030222",
    "0112222033030222",
    "0112222033330222",
    "0111222200002222",
    "0011222222222222",
    "0011122222222222",
    "0001112222222222",
    "0000111222222221",
    "0000011122222211",
    "0002200220022002",
    "0002200220022002",
    "0002200220022002",
    "0002200220022002",
    "0002200220022002",
    "0000200220022002",
    "0000200220022002",
    "0000000220022002",
    "0000000220022002",
    "0000000020022002",
    "0000000020022002",
    "0000000000022002",
    "0000000000022002",
    "0000000000002002",
    "0000000000000000"
)

# ---- TETRA (stage 4): faceted crystal diamond, white core ----
$tetraTop = @(
    "0000000000000001",
    "0000000000000011",
    "0000000000000112",
    "0000000000001122",
    "0000000000011222",
    "0000000000112222",
    "0000000001122222",
    "0000000011222222",
    "0000000112222222",
    "0000001122222222",
    "0000011222222222",
    "0000112222222222",
    "0001122222222333",
    "0011222222223333",
    "0112222222233333",
    "1122222222233333"
)
$tetraHalves = $tetraTop + ($tetraTop[15..0])   # vertically symmetric
$tetra = Mirror $tetraHalves

# ---- OVERMIND (stage 6): wrinkled brain, glowing slit eye, stem ----
$overmind = Mirror @(
    "0000000000111111",
    "0000000111222222",
    "0000011122212222",
    "0000111222122122",
    "0001122212221222",
    "0011222122212221",
    "0011221222122212",
    "0112212221222122",
    "0112122212221222",
    "0112221222122212",
    "1122212221222122",
    "1122122212221222",
    "1122212221222122",
    "1122122212221222",
    "1122212221223330",
    "1122122212223330",
    "1122212221223330",
    "1122122212223330",
    "1122212221222330",
    "1122122212221222",
    "1122212221222122",
    "0112122212221222",
    "0112221222122212",
    "0112212221222122",
    "0011222122212221",
    "0011122212221222",
    "0001112221222122",
    "0000111222122212",
    "0000011122212222",
    "0000000111222222",
    "0000000000000122",
    "0000000000000122"
)

# ---- BASTION (stage 5): armored block, left gun port, core eye ----
$bastion = @()
for ($r = 0; $r -lt 32; $r++) {
    $row = New-Object char[] 32
    for ($c = 0; $c -lt 32; $c++) { $row[$c] = '2' }
    # outer frame
    $row[0] = '0'; $row[31] = '0'
    $row[1] = '1'; $row[2] = '1'; $row[29] = '1'; $row[30] = '1'
    if ($r -eq 0 -or $r -eq 31) {
        for ($c = 0; $c -lt 32; $c++) { $row[$c] = '0' }
        for ($c = 2; $c -le 29; $c++) { $row[$c] = '1' }
    }
    elseif ($r -eq 1 -or $r -eq 30) {
        for ($c = 3; $c -le 28; $c++) { $row[$c] = '2' }
        $row[0] = '0'; $row[1] = '1'; $row[2] = '1'
        $row[29] = '1'; $row[30] = '1'; $row[31] = '0'
    }
    else {
        # armor seams
        $row[9] = '1'; $row[22] = '1'
    }
    $bastion += ,$row
}
# vents top/bottom
foreach ($r in 3,4,27,28) {
    for ($c = 13; $c -le 18; $c++) { $bastion[$r][$c] = '0' }
}
# core eye: white box rows 12-19 cols 13-20, dark pupil rows 14-17 cols 15-18
for ($r = 12; $r -le 19; $r++) {
    for ($c = 13; $c -le 20; $c++) { $bastion[$r][$c] = '3' }
}
for ($r = 14; $r -le 17; $r++) {
    for ($c = 15; $c -le 18; $c++) { $bastion[$r][$c] = '0' }
}
# left gun port: notch rows 13-18 cols 0-3, barrel rows 15-16 cols 0-4
for ($r = 13; $r -le 18; $r++) {
    for ($c = 0; $c -le 3; $c++) { $bastion[$r][$c] = '0' }
}
foreach ($r in 15,16) {
    for ($c = 0; $c -le 4; $c++) { $bastion[$r][$c] = '3' }
}
$bastionRows = @()
foreach ($row in $bastion) { $bastionRows += (-join $row) }

Validate "kraken" $kraken
Validate "tetra" $tetra
Validate "bastion" $bastionRows
Validate "overmind" $overmind

# ---- emit include file ----
$out = @()
$out += "; ============================================================"
$out += "; bosses_chr.inc - stage 3-6 guardian art. GENERATED FILE:"
$out += "; edit and rerun nes/gen_bosses_chr.ps1 instead. 8 pairs each."
$out += "; ============================================================"
$sets = @(
    @{ name = "KRAKEN (stage 3)"; prefix = "KR"; rows = $kraken },
    @{ name = "TETRA (stage 4)";  prefix = "TE"; rows = $tetra },
    @{ name = "BASTION (stage 5)"; prefix = "BA"; rows = $bastionRows },
    @{ name = "OVERMIND (stage 6)"; prefix = "OV"; rows = $overmind }
)
foreach ($s in $sets) {
    $out += ""
    $out += "; ---- $($s.name) ----"
    for ($r = 0; $r -lt 32; $r++) {
        $out += (".define {0}{1:d2} `"{2}`"" -f $s.prefix, $r, $s.rows[$r])
    }
    $p = $s.prefix
    $it = $p.ToLower() + "col"
    $out += ""
    $out += ".repeat 4, $it"
    for ($block = 0; $block -lt 4; $block++) {
        $names = @()
        for ($i = 0; $i -lt 8; $i++) {
            $names += ("{0}{1:d2}" -f $p, ($block * 8 + $i))
        }
        $out += ("t8 {0}, {1}*8" -f ($names -join ","), $it)
    }
    $out += ".endrep"
}
$dest = "C:\Users\rhicks.RADINDIANA\Documents\GitHub\Vivaforte\nes\src\bosses_chr.inc"
Set-Content -Path $dest -Value ($out -join "`r`n") -Encoding ascii
Write-Host "wrote $dest ($($out.Count) lines)"
