// Mobile nav toggle
const toggle = document.getElementById('navToggle');
const links = document.getElementById('navLinks');
toggle.addEventListener('click', () => {
  const open = links.classList.toggle('open');
  toggle.setAttribute('aria-expanded', open);
});
// Close menu when a link is tapped
links.querySelectorAll('a').forEach(a =>
  a.addEventListener('click', () => {
    links.classList.remove('open');
    toggle.setAttribute('aria-expanded', 'false');
  })
);

// Current year in footer
document.getElementById('year').textContent = new Date().getFullYear();

// Contact form — AJAX submit to Formspree (falls back gracefully)
const form = document.getElementById('contactForm');
const note = document.getElementById('formNote');
form.addEventListener('submit', async (e) => {
  // If the Formspree endpoint hasn't been set yet, let the mailto fallback happen
  if (form.action.includes('YOUR_FORM_ID')) {
    e.preventDefault();
    note.className = 'form-note error';
    note.textContent = 'Message form not connected yet — please book online, call 973.896.4547, or email jfedorka1@gmail.com.';
    return;
  }
  e.preventDefault();
  const btn = form.querySelector('button[type="submit"]');
  const original = btn.textContent;
  btn.textContent = 'Sending…';
  btn.disabled = true;
  try {
    const res = await fetch(form.action, {
      method: 'POST',
      body: new FormData(form),
      headers: { Accept: 'application/json' },
    });
    if (res.ok) {
      form.reset();
      note.className = 'form-note success';
      note.textContent = "Thank you! We'll be in touch within 24 hours. 🐾";
    } else {
      throw new Error('bad response');
    }
  } catch (err) {
    note.className = 'form-note error';
    note.textContent = 'Something went wrong — please call 973.896.4547 or email jfedorka1@gmail.com instead.';
  } finally {
    btn.textContent = original;
    btn.disabled = false;
  }
});
