// Clicker Pro landing â€” minimal interactivity (no framework).
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

  // Smooth-scroll section links without leaving #hash fragments in the URL.
  // The href values stay as fallbacks for no-JS browsers, but normal clicks keep
  // https://graphy7.tech/ clean while still moving to the right section.
  function scrollToHash(hash) {
    if (!hash || hash === '#') return false;
    const target = document.getElementById(hash.slice(1));
    if (!target) return false;
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    if (window.history && window.history.replaceState) {
      window.history.replaceState(null, document.title, window.location.pathname + window.location.search);
    }
    return true;
  }

  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (event) => {
      const hash = link.getAttribute('href');
      if (!scrollToHash(hash)) return;
      event.preventDefault();
    });
  });

  if (window.location.hash) {
    const initialHash = window.location.hash;
    window.setTimeout(() => scrollToHash(initialHash), 0);
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
