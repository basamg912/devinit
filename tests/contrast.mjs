import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const records = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const backgrounds = {
  light: ['#eff1f5', '#ffffff'],
  dark: ['#1e1e2e', '#0d1117'],
};

function luminance(hex) {
  const rgb = hex.slice(1).match(/../g).map(value => parseInt(value, 16) / 255);
  const linear = rgb.map(value => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
  return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
}

function contrast(fg, bg) {
  const a = luminance(fg);
  const b = luminance(bg);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

function indexedColor(index) {
  assert.ok(index >= 16 && index <= 255, `Theme-dependent ANSI color: ${index}`);
  if (index >= 232) {
    return '#' + (8 + (index - 232) * 10).toString(16).padStart(2, '0').repeat(3);
  }
  const cube = [0, 95, 135, 175, 215, 255];
  const offset = index - 16;
  return '#' + [Math.floor(offset / 36), Math.floor(offset / 6) % 6, offset % 6]
    .map(value => cube[value].toString(16).padStart(2, '0')).join('');
}

for (const record of records) {
  const palette = Object.entries(record.lightline).flatMap(([mode, sections]) =>
    Object.entries(sections).flatMap(([section, colors]) => colors.map((color, index) =>
      [`lightline.${mode}.${section}.${index}`, { fg: color[0], bg: color[1], ctermfg: color[2], ctermbg: color[3] }])));
  for (const base of backgrounds[record.background]) {
    let minimum = Infinity;
    let minimumGroup = '';
    for (const [group, color] of [...Object.entries(record.groups), ...palette]) {
      assert.equal(indexedColor(Number(color.ctermfg)), color.fg, `${group}: GUI/terminal foreground mismatch`);
      if (color.bg) {
        assert.equal(indexedColor(Number(color.ctermbg)), color.bg, `${group}: GUI/terminal background mismatch`);
      }
      const ratio = contrast(color.fg, color.bg || base);
      assert.ok(ratio >= 4.5, `${record.background} ${base} ${group}: ${ratio.toFixed(2)}:1`);
      if (ratio < minimum) {
        minimum = ratio;
        minimumGroup = group;
      }
    }
    console.log(`${record.background} ${base}: minimum ${minimum.toFixed(2)}:1 (${minimumGroup})`);
  }
}
