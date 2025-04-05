/*
 SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
 SPDX-License-Identifier: MIT
*/

$(() => {
  $('#facts').tablesorter();
});

updateTime = () => {
  const now = new Date();
  const isoTime = now.toISOString();
  const timeElement = document.getElementById('current-time');
  timeElement.textContent = `Current time: ${isoTime}`;
}
updateTime();
setInterval(updateTime, 1000);
