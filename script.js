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

// Contact form — builds a pre-filled email to the business and opens the
// visitor's email app. No backend/third party required.
//
// WANT REAL FORM-TO-INBOX DELIVERY LATER? Sign up at https://formspree.io,
// create a form, then: (1) set the form's action to your Formspree URL,
// and (2) replace this handler with a fetch() POST of new FormData(form).
const BUSINESS_EMAIL = 'jfedorka1@gmail.com';
const form = document.getElementById('contactForm');
const note = document.getElementById('formNote');

form.addEventListener('submit', (e) => {
  e.preventDefault();
  const val = (id) => (document.getElementById(id)?.value || '').trim();
  const name = val('name');
  const subject = `Grooming inquiry from ${name || 'a pet parent'}`;
  const body =
    `Name: ${name}\n` +
    `Phone: ${val('phone')}\n` +
    `Email: ${val('email')}\n` +
    `Pet (name & breed): ${val('pet')}\n` +
    `Service interested in: ${val('service')}\n\n` +
    `Message:\n${val('message')}\n`;

  window.location.href =
    `mailto:${BUSINESS_EMAIL}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

  note.className = 'form-note success';
  note.textContent =
    `Opening your email app… if nothing happens, email ${BUSINESS_EMAIL} or call 973.896.4547.`;
});
