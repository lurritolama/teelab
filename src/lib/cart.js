/**
 * Warenkorb im localStorage – reiner Browser-Code (Port aus dem munsby-Shop).
 * Gespeichert wird nur zur Anzeige (Titel/Preis). Beim Checkout gehen die
 * Positionen mit; die verbindliche Rechnung stellt später der Server aus DB-Preisen.
 */
const KEY = 'teelab-warenkorb-v1';

function melden() { window.dispatchEvent(new CustomEvent('warenkorb:geaendert')); }

export function lesen() {
  try {
    const roh = localStorage.getItem(KEY);
    if (!roh) return [];
    const d = JSON.parse(roh);
    return Array.isArray(d)
      ? d.filter((p) => p && typeof p.id === 'string' && Number.isInteger(p.qty) && p.qty > 0)
      : [];
  } catch { return []; }
}
function speichern(p) { localStorage.setItem(KEY, JSON.stringify(p)); melden(); }

export function hinzufuegen(neu) {
  const ps = lesen();
  const v = ps.find((p) => p.id === neu.id);
  if (v) v.qty += 1; else ps.push({ ...neu, qty: 1 });
  speichern(ps);
}
export function setzeMenge(id, qty) {
  const ps = lesen();
  const p = ps.find((x) => x.id === id);
  if (!p) return;
  if (qty < 1) { speichern(ps.filter((x) => x.id !== id)); return; }
  p.qty = Math.min(qty, 20);
  speichern(ps);
}
export function entfernen(id) { speichern(lesen().filter((p) => p.id !== id)); }
export function leeren() { speichern([]); }
export function anzahl() { return lesen().reduce((s, p) => s + p.qty, 0); }
export function subtotalRappen() { return lesen().reduce((s, p) => s + p.preisRappen * p.qty, 0); }
export function formatPreis(rappen) {
  return 'CHF ' + new Intl.NumberFormat('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(rappen / 100);
}
