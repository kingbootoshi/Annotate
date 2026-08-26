(function () {
  const canvas = document.getElementById('paper');
  const ctx = canvas.getContext('2d');
  const cursor = document.getElementById('cursor');
  const dot = document.getElementById('dot');
  const glyph = document.getElementById('glyph');
  const sizeInput = document.getElementById('size');
  const sizeLabel = document.getElementById('sizeLabel');

  let color = '#ff4d42';
  let width = parseFloat(sizeInput.value);
  let down = false;
  let last = null;

  function fit() {
    canvas.width = innerWidth * devicePixelRatio;
    canvas.height = innerHeight * devicePixelRatio;
    canvas.style.width = innerWidth + 'px';
    canvas.style.height = innerHeight + 'px';
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
    ctx.lineCap = ctx.lineJoin = 'round';
  }
  addEventListener('resize', fit);
  fit();

  function applySize() {
    width = parseFloat(sizeInput.value);
    sizeLabel.textContent = width.toFixed(0) + ' px';
    dot.setAttribute('r', Math.max(width, 2) / 2);
    const lift = Math.max(width, 2) / 2;
    glyph.setAttribute('transform',
      `translate(${lift * 0.643} ${-lift * 0.766}) rotate(40)`);
    if (window.onInk) window.onInk(color, width);
  }
  sizeInput.addEventListener('input', applySize);

  document.querySelectorAll('.swatch').forEach((el) => {
    el.addEventListener('click', () => {
      color = el.dataset.c;
      document.querySelectorAll('.swatch').forEach((s) => s.classList.toggle('on', s === el));
      dot.setAttribute('fill', color);
      if (window.onInk) window.onInk(color, width);
    });
  });

  document.getElementById('clear').addEventListener('click', () => {
    ctx.clearRect(0, 0, innerWidth, innerHeight);
  });

  addEventListener('pointermove', (e) => {
    cursor.style.transform = `translate(${e.clientX}px, ${e.clientY}px)`;
    if (down && last) {
      ctx.strokeStyle = color;
      ctx.lineWidth = width;
      ctx.beginPath();
      ctx.moveTo(last.x, last.y);
      ctx.lineTo(e.clientX, e.clientY);
      ctx.stroke();
      last = { x: e.clientX, y: e.clientY };
    }
  });
  addEventListener('pointerdown', (e) => {
    if (e.target instanceof Element && e.target.closest('.hud')) return;
    down = true;
    last = { x: e.clientX, y: e.clientY };
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(e.clientX, e.clientY, width / 2, 0, Math.PI * 2);
    ctx.fill();
  });
  addEventListener('pointerup', () => { down = false; last = null; });

  dot.setAttribute('fill', color);
  applySize();
})();
