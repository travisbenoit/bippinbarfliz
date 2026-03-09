import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import { AuthProvider } from './contexts/AuthContext';
import { RegionalSettingsProvider } from './contexts/RegionalSettingsContext';
import { ToastProvider } from './contexts/ToastContext';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <RegionalSettingsProvider>
        <ToastProvider>
          <App />
        </ToastProvider>
      </RegionalSettingsProvider>
    </AuthProvider>
  </StrictMode>
);

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/service-worker.js').catch(err => {
    console.log('Service Worker registration failed:', err);
  });
}
