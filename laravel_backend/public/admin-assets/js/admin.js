/* ============================================================
   Clicker Pro Admin — minimal interactivity
   No framework. Only: theme toggle, mobile sidebar, active nav.
   ============================================================ */
(function () {
  'use strict';

  /* ---- Theme (persisted, respects system on first load) ---- */
  var THEME_KEY = 'cp_admin_theme';
  var root = document.documentElement;

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    var btn = document.querySelector('[data-theme-toggle]');
    if (btn) btn.textContent = theme === 'dark' ? '☀' : '☾';
  }

  function initTheme() {
    var saved = localStorage.getItem(THEME_KEY);
    if (!saved) {
      saved = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    applyTheme(saved);
  }

  function toggleTheme() {
    var next = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    localStorage.setItem(THEME_KEY, next);
    applyTheme(next);
  }

  /* ---- Mobile sidebar ---- */
  function initSidebar() {
    var sidebar = document.querySelector('.sidebar');
    var scrim = document.querySelector('.scrim');
    var toggle = document.querySelector('.menu-toggle');
    if (!sidebar || !toggle) return;

    function open() { sidebar.classList.add('is-open'); if (scrim) scrim.classList.add('is-open'); }
    function close() { sidebar.classList.remove('is-open'); if (scrim) scrim.classList.remove('is-open'); }

    toggle.addEventListener('click', function () {
      sidebar.classList.contains('is-open') ? close() : open();
    });
    if (scrim) scrim.addEventListener('click', close);
  }

  /* ---- Boot ---- */
  // Apply theme ASAP to avoid flash (also called inline in <head>).
  initTheme();

  document.addEventListener('DOMContentLoaded', function () {
    initTheme();
    initSidebar();
    var toggle = document.querySelector('[data-theme-toggle]');
    if (toggle) toggle.addEventListener('click', toggleTheme);
  });
})();
