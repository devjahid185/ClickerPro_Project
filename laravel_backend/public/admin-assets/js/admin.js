/* ============================================================
   Graphy7 Admin - minimal interactivity
   Mobile sidebar + modal helpers. The Graphy7 Admin design is
   dark-only, so the old light/dark theme toggle is gone.
   ============================================================ */
(function () {
  'use strict';

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

  document.addEventListener('DOMContentLoaded', initSidebar);
})();
