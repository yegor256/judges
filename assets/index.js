/*
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
 */

$.tablesorter.addParser({
  id: 'iso8601',
  is: (text) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/.test(text),
  format: (text) => text,
  type: 'text'
});

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
