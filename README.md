# The Pet-Stetician — Website

Static marketing site for **The Pet-Stetician**, a mobile pet grooming business serving
Palm Beach, Martin & St. Lucie Counties, FL. No build step — plain HTML, CSS, and JS. Deploys to Vercel as-is.

## Files
```
index.html      # the whole site (single page)
styles.css      # brand styling (pink / sage / cream)
script.js       # mobile menu, footer year, contact-form submit
vercel.json     # caching + clean URLs
img/            # photos cropped from the flyer & van mockup
```

## Run locally
Just open `index.html` in a browser, or serve the folder:
```bash
npx serve .
```

## Deploy to Vercel
**Option A — CLI**
```bash
npm i -g vercel
cd pet-stetician
vercel          # first run: link/create project, follow prompts
vercel --prod   # production deploy
```

**Option B — Git + Dashboard**
1. Push this folder to a GitHub repo.
2. In the Vercel dashboard: **Add New → Project → Import** the repo.
3. Framework preset: **Other** (it's static). Leave build/output settings empty. Deploy.

## Before you go live — things to update
1. **Contact form endpoint (optional).** Booking now goes through MoeGo, so the form is just for
   questions. To make it actually send email: create a free form at https://formspree.io and paste
   your form ID over `YOUR_FORM_ID` in `index.html`. Until then it politely points people to
   book online / call / email.
2. **Instagram link.** Confirm `https://instagram.com/the_pet_stetician` is correct.
3. **Domain.** Add `thepet-stetician.com` (and `www.thepet-stetician.com`) in
   Vercel → Project → Settings → Domains, then set the DNS records Vercel shows you
   at your domain registrar.

### Already wired
- **Booking:** all "Book" buttons open the MoeGo page
  `https://booking.moego.pet/ol/landing?name=ThePetStetician` in a new tab.
- **Email:** `jfedorka1@gmail.com`  ·  **Phone:** `973.896.4547`  ·  **IG:** `@the_pet_stetician`

## Brand colors
| Token | Hex |
|-------|-----|
| Cream | `#fbf7ea` |
| Blush pink | `#f0c3cf` |
| Deep pink | `#e79fb3` |
| Sage green | `#d7e3b4` |
| Deep green (text) | `#3f5137` |
| Tan | `#c6a172` |

Photos were cropped from the flyer and van-wrap mockups provided by the owner.
