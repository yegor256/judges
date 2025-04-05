/*
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
 */

const { configs } = require('@eslint/js');

module.exports = [
  {
    ...configs.all,
    files: ['**/*.js'],
    ignores: ['node_modules/**/*.js', 'coverage/**/*.js', 'doc/**/*.js'],
    languageOptions: {
      ecmaVersion: 2019,
      sourceType: 'module'
    },
    rules: {
      ...configs.all.rules,
      'indent': ['error', 2],
      'max-len': ['error', { code: 200 }],
      'no-magic-numbers': 'off',
      'no-undef': 'off',
      'one-var': 'off'
    }
  }
];
