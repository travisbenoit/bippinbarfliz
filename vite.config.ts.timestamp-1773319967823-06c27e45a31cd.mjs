// vite.config.ts
import { defineConfig } from "file:///home/project/node_modules/vite/dist/node/index.js";
import react from "file:///home/project/node_modules/@vitejs/plugin-react/dist/index.js";
import path from "path";
import { copyFileSync, existsSync } from "fs";
var __vite_injected_original_dirname = "/home/project";
var vite_config_default = defineConfig({
  plugins: [
    react(),
    {
      name: "copy-pwa-files",
      writeBundle() {
        const files = ["manifest.json", "service-worker.js"];
        const srcDir = "public";
        const outDir = "dist";
        files.forEach((file) => {
          const src = path.join(srcDir, file);
          const dest = path.join(outDir, file);
          if (existsSync(src)) {
            copyFileSync(src, dest);
          }
        });
        const icons = ["app-icon-96.png", "app-icon-96-maskable.png", "app-icon-192.png", "app-icon-192-maskable.png", "app-icon-512.png", "app-icon-512-maskable.png"];
        icons.forEach((icon) => {
          const src = path.join(srcDir, icon);
          const dest = path.join(outDir, icon);
          if (existsSync(src)) {
            copyFileSync(src, dest);
          }
        });
      }
    }
  ],
  resolve: {
    alias: {
      "@": path.resolve(__vite_injected_original_dirname, "./src")
    }
  },
  optimizeDeps: {
    exclude: ["lucide-react"],
    include: ["leaflet"]
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          "vendor-react": ["react", "react-dom", "react-router-dom"],
          "vendor-supabase": ["@supabase/supabase-js"],
          "vendor-radar": ["radar-sdk-js"]
        }
      }
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvaG9tZS9wcm9qZWN0XCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCIvaG9tZS9wcm9qZWN0L3ZpdGUuY29uZmlnLnRzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9ob21lL3Byb2plY3Qvdml0ZS5jb25maWcudHNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcgfSBmcm9tICd2aXRlJztcbmltcG9ydCByZWFjdCBmcm9tICdAdml0ZWpzL3BsdWdpbi1yZWFjdCc7XG5pbXBvcnQgcGF0aCBmcm9tICdwYXRoJztcbmltcG9ydCB7IGNvcHlGaWxlU3luYywgZXhpc3RzU3luYyB9IGZyb20gJ2ZzJztcblxuLy8gaHR0cHM6Ly92aXRlanMuZGV2L2NvbmZpZy9cbmV4cG9ydCBkZWZhdWx0IGRlZmluZUNvbmZpZyh7XG4gIHBsdWdpbnM6IFtcbiAgICByZWFjdCgpLFxuICAgIHtcbiAgICAgIG5hbWU6ICdjb3B5LXB3YS1maWxlcycsXG4gICAgICB3cml0ZUJ1bmRsZSgpIHtcbiAgICAgICAgY29uc3QgZmlsZXMgPSBbJ21hbmlmZXN0Lmpzb24nLCAnc2VydmljZS13b3JrZXIuanMnXTtcbiAgICAgICAgY29uc3Qgc3JjRGlyID0gJ3B1YmxpYyc7XG4gICAgICAgIGNvbnN0IG91dERpciA9ICdkaXN0JztcblxuICAgICAgICBmaWxlcy5mb3JFYWNoKGZpbGUgPT4ge1xuICAgICAgICAgIGNvbnN0IHNyYyA9IHBhdGguam9pbihzcmNEaXIsIGZpbGUpO1xuICAgICAgICAgIGNvbnN0IGRlc3QgPSBwYXRoLmpvaW4ob3V0RGlyLCBmaWxlKTtcbiAgICAgICAgICBpZiAoZXhpc3RzU3luYyhzcmMpKSB7XG4gICAgICAgICAgICBjb3B5RmlsZVN5bmMoc3JjLCBkZXN0KTtcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuXG4gICAgICAgIGNvbnN0IGljb25zID0gWydhcHAtaWNvbi05Ni5wbmcnLCAnYXBwLWljb24tOTYtbWFza2FibGUucG5nJywgJ2FwcC1pY29uLTE5Mi5wbmcnLCAnYXBwLWljb24tMTkyLW1hc2thYmxlLnBuZycsICdhcHAtaWNvbi01MTIucG5nJywgJ2FwcC1pY29uLTUxMi1tYXNrYWJsZS5wbmcnXTtcbiAgICAgICAgaWNvbnMuZm9yRWFjaChpY29uID0+IHtcbiAgICAgICAgICBjb25zdCBzcmMgPSBwYXRoLmpvaW4oc3JjRGlyLCBpY29uKTtcbiAgICAgICAgICBjb25zdCBkZXN0ID0gcGF0aC5qb2luKG91dERpciwgaWNvbik7XG4gICAgICAgICAgaWYgKGV4aXN0c1N5bmMoc3JjKSkge1xuICAgICAgICAgICAgY29weUZpbGVTeW5jKHNyYywgZGVzdCk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgfSxcbiAgXSxcbiAgcmVzb2x2ZToge1xuICAgIGFsaWFzOiB7XG4gICAgICAnQCc6IHBhdGgucmVzb2x2ZShfX2Rpcm5hbWUsICcuL3NyYycpLFxuICAgIH0sXG4gIH0sXG4gIG9wdGltaXplRGVwczoge1xuICAgIGV4Y2x1ZGU6IFsnbHVjaWRlLXJlYWN0J10sXG4gICAgaW5jbHVkZTogWydsZWFmbGV0J10sXG4gIH0sXG4gIGJ1aWxkOiB7XG4gICAgcm9sbHVwT3B0aW9uczoge1xuICAgICAgb3V0cHV0OiB7XG4gICAgICAgIG1hbnVhbENodW5rczoge1xuICAgICAgICAgICd2ZW5kb3ItcmVhY3QnOiBbJ3JlYWN0JywgJ3JlYWN0LWRvbScsICdyZWFjdC1yb3V0ZXItZG9tJ10sXG4gICAgICAgICAgJ3ZlbmRvci1zdXBhYmFzZSc6IFsnQHN1cGFiYXNlL3N1cGFiYXNlLWpzJ10sXG4gICAgICAgICAgJ3ZlbmRvci1yYWRhcic6IFsncmFkYXItc2RrLWpzJ10sXG4gICAgICAgIH0sXG4gICAgICB9LFxuICAgIH0sXG4gIH0sXG59KTtcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFBeU4sU0FBUyxvQkFBb0I7QUFDdFAsT0FBTyxXQUFXO0FBQ2xCLE9BQU8sVUFBVTtBQUNqQixTQUFTLGNBQWMsa0JBQWtCO0FBSHpDLElBQU0sbUNBQW1DO0FBTXpDLElBQU8sc0JBQVEsYUFBYTtBQUFBLEVBQzFCLFNBQVM7QUFBQSxJQUNQLE1BQU07QUFBQSxJQUNOO0FBQUEsTUFDRSxNQUFNO0FBQUEsTUFDTixjQUFjO0FBQ1osY0FBTSxRQUFRLENBQUMsaUJBQWlCLG1CQUFtQjtBQUNuRCxjQUFNLFNBQVM7QUFDZixjQUFNLFNBQVM7QUFFZixjQUFNLFFBQVEsVUFBUTtBQUNwQixnQkFBTSxNQUFNLEtBQUssS0FBSyxRQUFRLElBQUk7QUFDbEMsZ0JBQU0sT0FBTyxLQUFLLEtBQUssUUFBUSxJQUFJO0FBQ25DLGNBQUksV0FBVyxHQUFHLEdBQUc7QUFDbkIseUJBQWEsS0FBSyxJQUFJO0FBQUEsVUFDeEI7QUFBQSxRQUNGLENBQUM7QUFFRCxjQUFNLFFBQVEsQ0FBQyxtQkFBbUIsNEJBQTRCLG9CQUFvQiw2QkFBNkIsb0JBQW9CLDJCQUEyQjtBQUM5SixjQUFNLFFBQVEsVUFBUTtBQUNwQixnQkFBTSxNQUFNLEtBQUssS0FBSyxRQUFRLElBQUk7QUFDbEMsZ0JBQU0sT0FBTyxLQUFLLEtBQUssUUFBUSxJQUFJO0FBQ25DLGNBQUksV0FBVyxHQUFHLEdBQUc7QUFDbkIseUJBQWEsS0FBSyxJQUFJO0FBQUEsVUFDeEI7QUFBQSxRQUNGLENBQUM7QUFBQSxNQUNIO0FBQUEsSUFDRjtBQUFBLEVBQ0Y7QUFBQSxFQUNBLFNBQVM7QUFBQSxJQUNQLE9BQU87QUFBQSxNQUNMLEtBQUssS0FBSyxRQUFRLGtDQUFXLE9BQU87QUFBQSxJQUN0QztBQUFBLEVBQ0Y7QUFBQSxFQUNBLGNBQWM7QUFBQSxJQUNaLFNBQVMsQ0FBQyxjQUFjO0FBQUEsSUFDeEIsU0FBUyxDQUFDLFNBQVM7QUFBQSxFQUNyQjtBQUFBLEVBQ0EsT0FBTztBQUFBLElBQ0wsZUFBZTtBQUFBLE1BQ2IsUUFBUTtBQUFBLFFBQ04sY0FBYztBQUFBLFVBQ1osZ0JBQWdCLENBQUMsU0FBUyxhQUFhLGtCQUFrQjtBQUFBLFVBQ3pELG1CQUFtQixDQUFDLHVCQUF1QjtBQUFBLFVBQzNDLGdCQUFnQixDQUFDLGNBQWM7QUFBQSxRQUNqQztBQUFBLE1BQ0Y7QUFBQSxJQUNGO0FBQUEsRUFDRjtBQUNGLENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
