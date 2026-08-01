import { createTheme } from '@mui/material/styles';

export const muiTheme = createTheme({
  palette: {
    mode: 'dark',
    background: {
      default: '#080914',
      paper: '#16192E'
    },
    primary: {
      main: '#00F5D4',
      contrastText: '#000000'
    },
    secondary: {
      main: '#6366F1',
      contrastText: '#FFFFFF'
    },
    warning: {
      main: '#F59E0B'
    },
    error: {
      main: '#F43F5E'
    },
    success: {
      main: '#10B981'
    },
    text: {
      primary: '#FFFFFF',
      secondary: '#A0AEC0'
    }
  },
  typography: {
    fontFamily: "'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    h1: { fontWeight: 800 },
    h2: { fontWeight: 800 },
    h3: { fontWeight: 800 },
    h4: { fontWeight: 800 },
    h5: { fontWeight: 700 },
    h6: { fontWeight: 700 },
    button: { textTransform: 'none', fontWeight: 700 }
  },
  shape: {
    borderRadius: 16
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          background: 'rgba(22, 25, 46, 0.75)',
          backdropFilter: 'blur(16px)',
          border: '1px solid rgba(0, 245, 212, 0.25)',
          boxShadow: '0 10px 30px rgba(0, 0, 0, 0.5)',
          transition: 'all 0.3s ease-in-out',
          '&:hover': {
            borderColor: 'rgba(0, 245, 212, 0.5)',
            boxShadow: '0 12px 35px rgba(0, 245, 212, 0.15)'
          }
        }
      }
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          padding: '8px 18px',
          boxShadow: 'none'
        },
        contained: {
          background: 'linear-gradient(135deg, #00F5D4 0%, #00C4A7 100%)',
          color: '#000000',
          boxShadow: '0 4px 20px rgba(0, 245, 212, 0.4)',
          '&:hover': {
            boxShadow: '0 6px 25px rgba(0, 245, 212, 0.6)'
          }
        }
      }
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none'
        }
      }
    }
  }
});
