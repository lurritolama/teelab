import { defineConfig } from 'astro/config';

// TeeLab — static site for now (Rechnung/manuell checkout).
// When we add the order API / Stripe later, add the @astrojs/netlify adapter
// and switch output to 'hybrid'.
export default defineConfig({
  site: 'https://teelab.ch',
});
