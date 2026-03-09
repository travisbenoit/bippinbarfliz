import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { copyFileSync, existsSync } from 'fs';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react(),
    {
      name: 'copy-pwa-files',
      writeBundle() {
        const files = ['manifest.json', 'service-worker.js'];
        const srcDir = 'public';
        const outDir = 'dist';

        files.forEach(file => {
          const src = path.join(srcDir, file);
          const dest = path.join(outDir, file);
          if (existsSync(src)) {
            copyFileSync(src, dest);
          }
        });

        const icons = ['app-icon-96.png', 'app-icon-96-maskable.png', 'app-icon-192.png', 'app-icon-192-maskable.png', 'app-icon-512.png', 'app-icon-512-maskable.png'];
        icons.forEach(icon => {
          const src = path.join(srcDir, icon);
          const dest = path.join(outDir, icon);
          if (existsSync(src)) {
            copyFileSync(src, dest);
          }
        });
      },
    },
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  optimizeDeps: {
    exclude: ['lucide-react'],
    include: ['leaflet', 'react-leaflet'],
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-supabase': ['@supabase/supabase-js'],
          'vendor-radar': ['radar-sdk-js'],
        },
      },
    },
  },
});
