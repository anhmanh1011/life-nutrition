document.addEventListener('click', (e) => {
  const toggle = e.target.closest('.site-nav__toggle');
  if (!toggle) return;
  const nav = toggle.closest('.site-nav');
  const open = nav.dataset.open !== 'true';
  nav.dataset.open = String(open);
  toggle.setAttribute('aria-expanded', String(open));
});
