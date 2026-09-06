import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.vue',
    ],

    theme: {
        extend: {
            fontFamily: {
                sans: ['Figtree', ...defaultTheme.fontFamily.sans],
            },
            colors: {
                // Couleurs validées dans la maquette Stitch (7 écrans, groupe D)
                brand: {
                    DEFAULT: '#166534', // vert principal (logo, CTA secondaires, liens actifs)
                    dark: '#14532d',
                    light: '#dcfce7',
                },
                accent: {
                    DEFAULT: '#F97316', // orange — CTA principaux ("Demander ce service", "Publier ma demande")
                    dark: '#c2410c',
                    light: '#ffedd5',
                },
            },
        },
    },

    plugins: [forms],
};
