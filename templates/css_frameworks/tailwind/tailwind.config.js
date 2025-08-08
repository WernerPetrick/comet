/** @type {import('tailwindcss').Config} */
module.exports = {
	content: ["./src/**/*.{html,js,erb,md}", "./dist/**/*.html"],
	theme: {
		extend: {
			colors: {
				"comet-primary": "#667eea",
				"comet-secondary": "#764ba2",
			},
			backgroundImage: {
				"gradient-comet": "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
				"gradient-comet-hover":
					"linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)",
			},
			boxShadow: {
				comet:
					"0 4px 6px -1px rgba(102, 126, 234, 0.1), 0 2px 4px -1px rgba(102, 126, 234, 0.06)",
				"comet-lg":
					"0 10px 15px -3px rgba(102, 126, 234, 0.1), 0 4px 6px -2px rgba(102, 126, 234, 0.05)",
			},
		},
	},
	plugins: [],
};
