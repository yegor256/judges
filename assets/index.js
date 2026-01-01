/*
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
 */

$(() => {
  $('#facts').tablesorter();
});

updateTime = () => {
  const now = new Date();
  const iso = now.toISOString();
  const div = document.getElementById('current-time');
  div.textContent = `Current time: ${iso}`;
}
$(() => {
  updateTime();
  setInterval(updateTime, 1000);
});
