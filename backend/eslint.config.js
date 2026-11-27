export default [{
  files: ['src/**/*.js', 'test/**/*.js'],
  languageOptions: {
    globals: { console: 'readonly', fetch: 'readonly', process: 'readonly' }
  },
  rules: {
    'no-undef': 'error',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'no-unreachable': 'error'
  }
}];
