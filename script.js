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

// Contact form — submits to Formspree via AJAX (no page reload).
// Shows a success/error message inline; falls back to call/email on failure.
const form = document.getElementById('contactForm');
const note = document.getElementById('formNote');

form.addEventListener('submit', async (e) => {
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
      form.hidden = true;
      const success = document.getElementById('formSuccess');
      success.hidden = false;
      success.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } else {
      const data = await res.json().catch(() => ({}));
      const msg = data.errors ? data.errors.map((x) => x.message).join(', ') : 'bad response';
      throw new Error(msg);
    }
  } catch (err) {
    note.className = 'form-note error';
    note.textContent =
      'Something went wrong — please call 973.896.4547 or email jfedorka1@gmail.com instead.';
  } finally {
    btn.textContent = original;
    btn.disabled = false;
  }
});
