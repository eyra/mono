module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/components/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js",
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    colors: {
      primary: '#4272EF',
      primarylight: '#E3EAFD',
      secondary: '#FF5E5E',
      tertiary: '#FFCF60',
      success: '#6FCA37',
      successlight: '#EBFFDF',
      warning: '#F28D15',
      warninglight: '#FFEFDC',
      delete: '#DB1E1E',
      deletelight: '#FFECEC',
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
        "illustration" : "188px",
        "illustration-sm" : "320px",
        "illustration-md" : "398px",
        "illustration-lg" : "696px",
        "form" : "400px",
        "card": "376px"
      },
        height: {
        "topbar" : "64px",
        "topbar-sm" : "96px",
        "topbar-lg" : "128px",
        "footer" : "48px",
        "footer-sm" : "64px",
        "footer-lg" : "96px",
        "header1" : "100px",
        "header1-sm" : "170px",
        "header1-lg" : "370px",
        "header2" : "50px",
        "header2-sm" : "90px",
        "header2-lg" : "183px",
        "logo" : "32px",
        "logo-sm" : "48px",
        "48px" : "48px",
        "44px" : "44px",
        "1px" : "1px",
      },
      fontFamily: {
        'title1': ['Finador-Black', 'sans-serif'],
        'title2': ['Finador-Black', 'sans-serif'],
        'title3': ['Finador-Black', 'sans-serif'],
        'title4': ['Finador-Bold', 'sans-serif'],
        'title5': ['Finador-Bold', 'sans-serif'],
        'title6': ['Finador-Bold', 'sans-serif'],
        'caption': ['Finador-Medium', 'sans-serif'],
        'link': ['Finador-medium', 'sans-serif'],
        'subhead': ['Finador-Regular', 'sans-serif'],
        'button': ['Finador-Bold', 'sans-serif'],
        'intro': ['Finador-Medium', 'sans-serif'],
        'label': ['Finador-Bold', 'sans-serif'],
        'body': ['Finador-Light', 'sans-serif'],
      },
      fontSize: {
        "title1": ['50px', '55px'],
        "title2": ['40px', '44px'],
        "title3": ['32px', '38px'],
        "title4": ['32px', '32px'],
        "title5": ['24px', '26px'],
        "title6": ['20px', '22px'],
        "caption": ['14px', '18px'],
        "subhead": ['20px', '20px'],
        "label": ['16px', '16px'],
        "button": ['18px', '18px'],
        "intro": ['20px', '30px'],
        "introdesktop": ['24px', '36px'],
        "bodylarge": ['24px', '36px'],
        "bodymedium": ['20px', '30px'],
        "bodysmall": ['16px', '24px'],
        "link": ['16px', '24px'],
      },
      maxWidth: {
        "card": "376px",
        "form": "400px"
      },
      maxHeight: {
        "header1": "376px",
        "form": "400px"
      },
    },
  },
  variants: {
    variants: {
      extend: {
       borderColor: ['active', 'hover'],
      },
    }
  },
  plugins: [],
}
