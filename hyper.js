// Future versions of Hyper may add additional config options,
// which will not automatically be merged into this file.
// See https://hyper.is#cfg for all currently supported options.

module.exports = {
  config: {
    updateChannel: 'stable',
    fontSize: 12,
    fontFamily: '"Fira Mono for Powerline", Menlo, "DejaVu Sans Mono", "Lucida Console", monospace',
//    fontFamily: '"Fira Mono Powerline", "Anonymice Powerline", "Roboto Mono for Powerline", "Meslo LG S for Powerline", "DejaVu Sans Mono", "Lucida Console", monospace',
    fontWeight: 'normal',
    fontWeightBold: 'bold',
    lineHeight: 1,
    letterSpacing: 0,
    cursorColor: 'rgba(248,28,229,0.8)',
    cursorAccentColor: '#000',
    cursorShape: 'BLOCK',
    cursorBlink: false,
    foregroundColor: '#fff',
    backgroundColor: '#000',
    selectionColor: 'rgba(248,28,229,0.3)',
    borderColor: '#333',
    css: '',
    termCSS: '',
    showHamburgerMenu: '',
    showWindowControls: '',
    padding: '0px 0px',
    colors: {
      black: '#000000',
      red: '#C51E14',
      green: '#1DC121',
      yellow: '#C7C329',
      blue: '#0A2FC4',
      magenta: '#C839C5',
      cyan: '#20C5C6',
      white: '#C7C7C7',
      lightBlack: '#686868',
      lightRed: '#FD6F6B',
      lightGreen: '#67F86F',
      lightYellow: '#FFFA72',
      lightBlue: '#6A76FB',
      lightMagenta: '#FD7CFC',
      lightCyan: '#68FDFE',
      lightWhite: '#FFFFFF',
    },

    env: {},
    bell: false,
    copyOnSelect: false,
    defaultSSHApp: true,
    quickEdit: false,
    macOptionSelectionMode: 'vertical',
    webGLRenderer: true,

  },

  plugins: [
    'hyperterm-atom-dark'
  ],

  localPlugins: [],

  keymaps: {
  },
};
