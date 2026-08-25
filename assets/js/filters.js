const grid = document.querySelector('[data-product-grid]');

if (grid) {
  const cards = Array.from(grid.children);
  const emptyState = document.querySelector('[data-empty-state]');
  const countEl = document.querySelector('[data-count]');
  const state = { cat: 'all', brand: 'all' };

  const apply = () => {
    let shown = 0;
    for (const card of cards) {
      const match =
        (state.cat === 'all' || card.dataset.cat === state.cat) &&
        (state.brand === 'all' || card.dataset.brand === state.brand);
      card.hidden = !match;
      if (match) shown += 1;
    }
    countEl.textContent = String(shown);
    grid.hidden = shown === 0;
    emptyState.hidden = shown > 0;
  };

  document.addEventListener('click', (e) => {
    const pill = e.target.closest('[data-filter]');
    if (!pill) return;
    const group = pill.dataset.filter;
    state[group] = pill.dataset.value;
    for (const other of document.querySelectorAll(`[data-filter="${group}"]`)) {
      other.setAttribute('aria-pressed', String(other === pill));
    }
    apply();
  });
}
