// Clicker Pro landing — minimal interactivity (no framework).
// Scroll-reveal + mobile nav toggle.
(function () {
  'use strict';

  // Reveal on scroll
  const els = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window && els.length) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) {
          en.target.classList.add('is-visible');
          io.unobserve(en.target);
        }
      });
    }, { threshold: 0.12 });
    els.forEach((el) => io.observe(el));
  } else {
    els.forEach((el) => el.classList.add('is-visible'));
  }

  // Mobile nav toggle
  const menuBtn = document.querySelector('.nav__menu');
  const links = document.querySelector('.nav__links');
  if (menuBtn && links) {
    menuBtn.addEventListener('click', () => links.classList.toggle('is-open'));
    links.addEventListener('click', (e) => {
      if (e.target.classList.contains('nav__link')) links.classList.remove('is-open');
    });
  }
})();
