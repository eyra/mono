module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js",
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    colors: {
      primary: '#4272EF',
      secondary: '#FF5E5E',
      tertiary: '#FFCF60',
      success: '#6FCA37',
      warning: '#F28D15',
      delete: '#DB1E1E',
      black: '#000000',
      grey1: '#222222',
      grey2: '#999999',
      grey3: '#CCCCCC',
      grey4: '#EEEEEE',
      grey5: '#F6F6F6',
      grey6: '#FAFAFA',
      white: '#FFFFFF',
      apple: '#000000',
      google: '#EA4335',
    },    
    extend: {
      width: {
        "sidebar" : "68px",
        "main-left" : "56px",
        "logo" : "23px",
        "logo-sm" : "48px",
        "hero" : "188px",
        "hero-sm" : "320px",
        "hero-md" : "398px",
        "hero-lg" : "696px",
        "form" : "400px",
        "card": "376px"
      },
        height: {
        "topbar" : "64px",
        "topbar-sm" : "96px",
        "topbar-lg" : "128px",
        "header" : "100px",
        "header-sm" : "170px",
        "header-md" : "212px",
        "header-lg" : "370px",
        "logo" : "32px",
        "logo-sm" : "48px",
        "48px" : "48px",
        "44px" : "44px",
      },
      fontFamily: {
        'sans': ['Finador', 'sans-serif']
      },
      fontSize: {
        "title1": ['48px', '52px'],
        "title2": ['40px', '44px'],
        "title3": ['36px', '38px'],
        "title4": ['32px', '32px'],
        "title5": ['24px', '26px'],
        "title6": ['20px', '22px'],
        "caption": ['14px', '18px'],
        "subhead": ['14px', '14px'],
        "labels": ['16px', '16px'],
        "button": ['18px', '18px'],
        "intro": ['20px', '30px'],
        "introdesktop": ['24px', '36px'],
        "bodylarge": ['24px', '24px'],
        "bodymedium": ['20px', '24px'],
        "bodysmall": ['16px', '24px'],
        "bodylink": ['16px', '24px'],
      },
      maxWidth: {
        "card": "376px",
        "form": "400px"
      },
    },  
  },
  variants: {
    variants: {
      extend: {
       borderColor: ['active'],
      },
    }  
  },
  plugins: [],
}
