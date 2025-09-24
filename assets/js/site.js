(function(){
  const q = document.getElementById('q');
  const grid = document.getElementById('grid');
  if (!grid) return;
  const cards = Array.from(grid.querySelectorAll('.card'));
  let category = null;

  function apply() {
    const term = (q?.value || '').toLowerCase();
    cards.forEach(c => {
      const title = c.querySelector('h3')?.textContent.toLowerCase() || '';
      const tags = (c.getAttribute('data-tags') || '').toLowerCase();
      const cat = c.getAttribute('data-cat');
      const matchesTerm = !term || title.includes(term) || tags.includes(term);
      const matchesCat = !category || cat === category;
      c.style.display = (matchesTerm && matchesCat) ? '' : 'none';
    });
  }
  q?.addEventListener('input', apply);

  document.querySelectorAll('[data-chip]').forEach(btn => {
    btn.addEventListener('click', () => {
      category = btn.getAttribute('data-chip');
      apply();
    });
  });

  apply();
})();
