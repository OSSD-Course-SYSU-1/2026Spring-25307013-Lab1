export interface ThemePalette {
  background: string;
  surface: string;
  card: string;
  border: string;
  textPrimary: string;
  textMuted: string;
  accent: string;
  accentStrong: string;
  accentSoft: string;
  danger: string;
  success: string;
  notePaper: string;
  noteBorder: string;
  noteShadow: string;
  pinBg: string;
  pinText: string;
  tagBg: string;
  tagText: string;
  toolbarBg: string;
  disabledBg: string;
  disabledText: string;
  overlay: string;
}

export interface ThemeRadius {
  pageCard: number;
  input: number;
  smallButton: number;
  largeButton: number;
}

export interface ThemeButtonHeight {
  primary: number;
  tool: number;
  mode: number;
}

export interface ThemeSpacing {
  pageMargin: number;
  cardPadding: number;
  cardGap: number;
}

export interface ThemeTokens {
  radius: ThemeRadius;
  buttonHeight: ThemeButtonHeight;
  spacing: ThemeSpacing;
}

export const LIGHT_THEME: ThemePalette = {
  background: '#F7F1E7',
  surface: '#FFF9F1',
  card: '#FFFDF8',
  border: '#E3D9CB',
  textPrimary: '#241A16',
  textMuted: '#7A6D62',
  accent: '#B46454',
  accentStrong: '#8D463B',
  accentSoft: '#F3DED7',
  danger: '#BA1A1A',
  success: '#2E6B42',
  notePaper: '#FFFAF2',
  noteBorder: '#E8DDCE',
  noteShadow: '#14000000',
  pinBg: '#E7D8C4',
  pinText: '#5E5046',
  tagBg: '#EFE7DA',
  tagText: '#6B5A4D',
  toolbarBg: '#F1E8DB',
  disabledBg: '#DDD4C8',
  disabledText: '#8C8176',
  overlay: '#99000000'
};

export const DARK_THEME: ThemePalette = {
  background: '#171311',
  surface: '#241F1B',
  card: '#2D2722',
  border: '#50473F',
  textPrimary: '#F4ECE3',
  textMuted: '#CBBFB3',
  accent: '#D99584',
  accentStrong: '#FFC3B4',
  accentSoft: '#54352F',
  danger: '#FFB4AB',
  success: '#95D5A6',
  notePaper: '#332D27',
  noteBorder: '#5A5148',
  noteShadow: '#33000000',
  pinBg: '#5D4E3D',
  pinText: '#EAD8BF',
  tagBg: '#3B342D',
  tagText: '#E5D7C8',
  toolbarBg: '#29231F',
  disabledBg: '#49413A',
  disabledText: '#A49A91',
  overlay: '#B3000000'
};

export const UI_TOKENS: ThemeTokens = {
  radius: {
    pageCard: 20,
    input: 16,
    smallButton: 14,
    largeButton: 18
  },
  buttonHeight: {
    primary: 48,
    tool: 40,
    mode: 36
  },
  spacing: {
    pageMargin: 20,
    cardPadding: 16,
    cardGap: 12
  }
};

export function resolveTheme(colorMode: string): ThemePalette {
  return colorMode.toLowerCase() === 'dark' ? DARK_THEME : LIGHT_THEME;
}
