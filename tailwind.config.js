/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: { moss: '#297757', expense: '#C04440', canvas: '#E6F9E8', surface: '#F4FFF5' },
      fontFamily: { sans: ['var(--font-montserrat)'], display: ['var(--font-playfair)'] },
    },
  },
  plugins: [],
}
