import { StrictMode, lazy, Suspense, type ReactNode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import { AuthProvider } from './contexts/AuthContext';
import { RegionalSettingsProvider } from './contexts/RegionalSettingsContext';
import { ToastProvider } from './contexts/ToastContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { initCapacitor } from './services/capacitorService';
import { CRYPTO_ENABLED } from './lib/featureFlags';
import './index.css';

// Lazy-load crypto providers only when feature is enabled
const CryptoProviders = CRYPTO_ENABLED
  ? lazy(() => import('./providers/CryptoProviders').then((m) => ({ default: m.CryptoProviders })))
  : ({ children }: { children: ReactNode }) => <>{children}</>;

// Initialize Capacitor plugins (no-op on web)
initCapacitor().catch(console.error);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ThemeProvider>
      <AuthProvider>
        <Suspense fallback={null}>
          <CryptoProviders>
            <RegionalSettingsProvider>
              <ToastProvider>
                <App />
              </ToastProvider>
            </RegionalSettingsProvider>
          </CryptoProviders>
        </Suspense>
      </AuthProvider>
    </ThemeProvider>
  </StrictMode>
);

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/service-worker.js').catch(err => {
    console.log('Service Worker registration failed:', err);
  });
}
