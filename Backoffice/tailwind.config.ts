import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx,js,jsx,mdx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          flexible: "#0D47A1",
          taxi: "#BF360C",
          eco: "#388E3C",
          serenity: "#1565C0",
          prestige: "#F57F17",
          stop: "#0277BD",
          traffic: "#E65100",
        },
      },
      fontFamily: { sans: ["Inter", "system-ui", "sans-serif"] },
    },
  },
  darkMode: "class",
  plugins: [],
};
export default config;
