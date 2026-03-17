import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import path from 'path';
import { copyFileSync, existsSync } from 'fs';

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
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
    exclude: ['@privy-io/react-auth', '@solana/web3.js', '@solana/spl-token'],
    include: ['leaflet'],
  },
  build: {
    rolldownOptions: {
      external: (id: string) => {
        const optionalPackages = [
          '@privy-io/react-auth',
          '@solana/web3.js',
          '@solana/spl-token',
        ];
        return optionalPackages.some((pkg) => id === pkg || id.startsWith(pkg + '/'));
      },
      output: {
        manualChunks(id: string) {
          if (id.includes('node_modules/react/') || id.includes('node_modules/react-dom/') || id.includes('node_modules/react-router/')) {
            return 'vendor-react';
          }
          if (id.includes('node_modules/@supabase/')) {
            return 'vendor-supabase';
          }
        },
      },
    },
  },
});
