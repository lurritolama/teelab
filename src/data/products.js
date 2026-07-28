// Zentrale Produktliste für Shop + Produktseiten. Preise in Rappen (wie im munsby-Shop).
// id = slug (stabil). Bilder noch Platzhalter.
export const products = [
  {
    slug: 'fairway-70', id: 'fairway-70',
    tag: 'CLASSIC CUP', name: 'Fairway 70',
    priceRappen: 900, unit: '5er-Set', length: '70 mm', head: 'Cup',
    desc: 'Der Allrounder: 70 mm, klassische Mulde, passt für Driver bis Hybrid. Die beliebteste Länge – solide Höhe, konstanter Abschlag.',
  },
  {
    slug: 'iron-38', id: 'iron-38',
    tag: 'LOW PROFILE', name: 'Iron 38',
    priceRappen: 900, unit: '5er-Set', length: '38 mm', head: 'Flat',
    desc: 'Flacher Kopf, 38 mm – für Eisen und Par-3-Löcher, wo es nicht auf maximale Höhe ankommt.',
  },
  {
    slug: 'driver-101', id: 'driver-101',
    tag: 'MAX HEIGHT', name: 'Driver 101',
    priceRappen: 1000, unit: '5er-Set', length: '101 mm', head: 'Cup',
    desc: 'Maximale Abschlaghöhe (101 mm = Regel-Maximum) für grosse 460-cc-Driver. Für alle, die den Ball hoch aufs Tee legen.',
  },
  {
    slug: 'augen-tee', id: 'augen-tee',
    tag: 'SIGNATURE · AUGE', name: 'Augen-Tee',
    priceRappen: 1400, unit: '3er-Set', length: '70 mm', head: 'Auge',
    desc: 'Unser Hingucker: Der Cup ist einem Auge nachempfunden – schwarze Pupille, blaue Iris, weisser Rand, mehrfarbig gedruckt. Die runde Ball-Auflage hält den Ball wie gewohnt.',
    dots: ['#1c1c1c', '#2f6fd6', '#eceff0'],
  },
  {
    slug: 'neon-mix', id: 'neon-mix',
    tag: 'SIGNATURE', name: 'Neon Mix',
    priceRappen: 1200, unit: '5er-Set', length: '83 mm', head: 'Cup',
    desc: 'Gemischte Neon-Farben, 83 mm Driver-Länge. Auffällig auf dem Tee-Box und leicht wiederzufinden.',
    dots: ['#45f08a', '#22d3ee', '#f0459b', '#f5c518'],
  },
];

export const bySlug = (slug) => products.find((p) => p.slug === slug);
export const preisFormat = (rappen) =>
  'CHF ' + new Intl.NumberFormat('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(rappen / 100);
