import { svelte } from "@sveltejs/vite-plugin-svelte";

export default {
  plugins: [svelte()],
  server: {
    proxy: {
      "/api": {
        target: "http://127.0.0.1:8991"
      }
    }
  }
};
