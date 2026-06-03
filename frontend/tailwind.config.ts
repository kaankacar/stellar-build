import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ember: {
          100: "#fdf0e0",
          200: "#f9ddb8",
          300: "#f5c98a",
          400: "#f0b36f",
          500: "#e8994a",
          600: "#c97d30",
        },
        ink: {
          900: "#0a1726",
          950: "#05111e",
        },
      },
      boxShadow: {
        halo: "0 0 80px rgba(240, 179, 111, 0.15), 0 18px 64px rgba(0, 0, 0, 0.35)",
      },
    },
  },
  plugins: [],
};

export default config;
