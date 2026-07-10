/* ============================================================
   Clicker Pro Admin - minimal interactivity
   Theme toggle, mobile sidebar, and modal helpers.
   ============================================================ */
(function () {
  'use strict';

  var THEME_KEY = 'cp_admin_theme';
  var root = document.documentElement;

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    var icon = document.querySelector('[data-theme-toggle] .material-symbols-rounded');
    if (icon) icon.textContent = theme === 'dark' ? 'light_mode' : 'dark_mode';
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

  function initSidebar() {
    var sidebar = document.querySelector('.sidebar');
    var scrim = document.querySelector('.scrim');
    var toggle = document.querySelector('.menu-toggle');
    if (!sidebar || !toggle) return;

    function open() {
      sidebar.classList.add('is-open');
      if (scrim) scrim.classList.add('is-open');
    }

    function close() {
      sidebar.classList.remove('is-open');
      if (scrim) scrim.classList.remove('is-open');
    }

    toggle.addEventListener('click', function () {
      sidebar.classList.contains('is-open') ? close() : open();
    });
    if (scrim) scrim.addEventListener('click', close);
  }

  initTheme();

  document.addEventListener('DOMContentLoaded', function () {
    initTheme();
    initSidebar();
    var toggle = document.querySelector('[data-theme-toggle]');
    if (toggle) toggle.addEventListener('click', toggleTheme);
  });
})();
