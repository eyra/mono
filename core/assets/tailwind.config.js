const plugin = require("tailwindcss/plugin");

module.exports = {
  content: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/*.ex",
    "./js/**/*.js",
  ],
  safelist: [
    "drop-shadow-lg",
    "drop-shadow-2xl",
    "text-bold",
    "text-pre",
    "font-pre",
    { pattern: /bg-wysiwyg-./ },
    { pattern: /h-wysiwyg-./ },
    { pattern: /border-./ },
  ],
  theme: {
    colors: {
      primary: "#4272EF",
      primarylight: "#E3EAFD",
      secondary: "#FF5E5E",
      tertiary: "#FFCF60",
      success: "#52BA12",
      successlight: "#EBFFDF",
      warning: "#F28D15",
      warninglight: "#FFEFDC",
      delete: "#DB1E1E",
      deletelight: "#FFECEC",
      error: "#DB1E1E",
      errorlight: "#FFECEC",
      black: "#000000",
      grey1: "#222222",
      grey2: "#999999",
      grey3: "#CCCCCC",
      grey4: "#EEEEEE",
      grey5: "#F6F6F6",
      grey6: "#FAFAFA",
      white: "#FFFFFF",
      apple: "#000000",
      google: "#EA4335",
      surfconext: "#FEDB02",
    },
    extend: {
      boxShadow: {
        top4px: "inset 0 4px 0 0 rgba(0, 0, 0, 0.15);",
        top2px: "inset 0 2px 0 0 rgba(0, 0, 0, 0.15;);",
        floating: "0px 5px 20px 0px rgba(0, 0, 0, 0.10);",
      },
      transitionDuration: {
        2000: "2000ms",
      },
      opacity: {
        shadow: ".15",
      },
      backgroundImage: {
        "square-border-striped": "url('/images/square_border_striped.png')",
        "wysiwyg-bold": "url('/images/wysiwyg/bold.svg')",
        "wysiwyg-italic": "url('/images/wysiwyg/italic.svg')",
        "wysiwyg-strike": "url('/images/wysiwyg/strike.svg')",
        "wysiwyg-link": "url('/images/wysiwyg/link.svg')",
        "wysiwyg-heading": "url('/images/wysiwyg/heading.svg')",
        "wysiwyg-quote": "url('/images/wysiwyg/quote.svg')",
        "wysiwyg-code": "url('/images/wysiwyg/code.svg')",
        "wysiwyg-list-bullet": "url('/images/wysiwyg/list_bullet.svg')",
        "wysiwyg-list-number": "url('/images/wysiwyg/list_number.svg')",
        "wysiwyg-nesting-level-decrease":
          "url('/images/wysiwyg/nesting_level_decrease.svg')",
        "wysiwyg-nesting-level-increase":
          "url('/images/wysiwyg/nesting_level_increase.svg')",
        "wysiwyg-attach": "url('/images/wysiwyg/attach.svg')",
        "wysiwyg-history-undo": "url('/images/wysiwyg/history_undo.svg')",
        "wysiwyg-history-redo": "url('/images/wysiwyg/history_redo.svg')",
        "wysiwyg-bullet": "url('/images/wysiwyg/bullet.svg')",
        "wysiwyg-bullet-dark": "url('/images/wysiwyg/bullet-secondary.svg')",
      },
      spacing: {
        "1px": "1px",
        "2px": "2px",
        "3px": "3px",
        "5px": "5px",
        "6px": "6px",
        "7px": "7px",
        "9px": "9px",
        "10px": "10px",
        "11px": "11px",
        "13px": "13px",
        "14px": "14px",
        "15px": "15px",
        "17px": "17px",
        "18px": "18px",
        "19px": "19px",
        "22px": "22px",
        "30px": "30px",
        "48px": "48px",
        "44px": "44px",
        "60px": "60px",
        "64px": "64px",
        "84px": "84px",
        "200px": "200px",
        "224px": "224px",
        "248px": "248px",
        15: "60px",
        30: "120px",
        34: "136px",
        35: "140px",
        border: "2px",
        "action_menu-width": "180px",
        "tablet-menu-width": "72px",
        "desktop-menu-width": "296px",
        "mobile-menu-width": "256px",
        "platform-footer-height": "62px",
        "desktop-menu-bottom-padding": "54px",
        "navbar-height": "90px",
        "dialog-width": "320px",
        "dialog-width-sm": "400px",
      },
      width: {
        "main-left": "56px",
        logo: "23px",
        "logo-sm": "48px",
        illustration: "188px",
        "illustration-sm": "320px",
        "illustration-md": "398px",
        "illustration-lg": "696px",
        sheet: "760px",
        form: "400px",
        card: "376px",
        "image-preview": "120px",
        "image-preview-sm": "200px",
        "image-preview-circle": "120px",
        "image-preview-circle-sm": "150px",
        "button-sm": "14px",
        card: "376px",
        form: "400px",
        sheet: "760px",
        popup: "480px",
        "side-panel": "535px",
        "left-column": "368px",
        "popup-sm": "520px",
        "popup-md": "730px",
        "popup-lg": "1228px",
      },
      height: {
        topbar: "64px",
        "topbar-sm": "96px",
        "topbar-lg": "128px",
        footer: "48px",
        "platform-footer": "62px",
        "footer-sm": "64px",
        "footer-lg": "96px",
        hero1: "100px",
        "hero1-sm": "170px",
        "hero1-lg": "360px",
        hero2: "100px",
        "hero2-sm": "100px",
        "hero2-lg": "183px",
        logo: "32px",
        "logo-sm": "48px",
        "lab-day-popup-list": "392px",
        "image-header": "375px",
        "image-header-sm": "500px",
        "image-card": "212px",
        "image-preview": "90px",
        "image-preview-sm": "150px",
        "image-preview-circle": "120px",
        "image-preview-circle-sm": "150px",
        "campaign-banner": "224px",
        "button-sm": "14px",
        "file-selector": "96px",
      },
      borderWidth: {
        "1px": "px",
      },
      fontFamily: {
        title0: ["Finador-Black", "sans-serif"],
        title1: ["Finador-Black", "sans-serif"],
        title2: ["Finador-Black", "sans-serif"],
        title3: ["Finador-Black", "sans-serif"],
        title4: ["Finador-Black", "sans-serif"],
        title5: ["Finador-Bold", "sans-serif"],
        title6: ["Finador-Bold", "sans-serif"],
        title7: ["Finador-Bold", "sans-serif"],
        caption: ["Finador-Medium", "sans-serif"],
        link: ["Finador-Medium", "sans-serif"],
        subhead: ["Finador-Medium", "sans-serif"],
        button: ["Finador-Bold", "sans-serif"],
        footnote: ["Finador-Medium", "sans-serif"],
        intro: ["Finador-Medium", "sans-serif"],
        label: ["Finador-Bold", "sans-serif"],
        body: ["Finador-Light", "sans-serif"],
        hint: ["Finador-LightOblique", "sans-serif"],
        tablehead: ["Finador-Bold", "sans-serif"],
        tablerow: ["Finador-Regular", "sans-serif"],
        bold: ["Finador-Bold", "sans-serif"],
        quote: ["Finador-Bold", "sans-serif"],
      },
      fontSize: {
        title0: ["64px", "68px"],
        title1: ["50px", "55px"],
        title2: ["40px", "44px"],
        title3: ["32px", "38px"],
        title4: ["28px", "32px"],
        title5: ["24px", "26px"],
        title6: ["20px", "22px"],
        title7: ["16px", "20px"],
        caption: ["14px", "18px"],
        captionsmall: ["12px", "14px"],
        subhead: ["20px", "20px"],
        label: ["16px", "16px"],
        labelsmall: ["14px", "14px"],
        button: ["18px", "18px"],
        buttonsmall: ["16px", "16px"],
        footnote: ["16px", "30px"],
        intro: ["20px", "30px"],
        introdesktop: ["24px", "36px"],
        bodylarge: ["24px", "36px"],
        bodymedium: ["20px", "30px"],
        bodysmall: ["16px", "24px"],
        bodylinklarge: ["24px", "36px"],
        bodylinkmedium: ["30px", "30px"],
        link: ["16px", "24px"],
        hint: ["20px", "24px"],
        tablehead: ["14px", "16px"],
        tablerow: ["14px", "16px"],
        mono: ["20px", "24px"],
        quote: ["24px", "30px"],
      },
      minWidth: {
        "1/2": "50%",
        "3/4": "75%",
      },
      maxWidth: {
        card: "376px",
        form: "400px",
        sheet: "760px",
        popup: "480px",
        "popup-sm": "520px",
        "popup-md": "730px",
        "popup-lg": "1228px",
        "3/4": "75%",
        "9/10": "90%",
      },
      minHeight: {
        "wysiwyg-editor": "512px",
      },
      maxHeight: {
        dropdown: "317px",
        hero1: "376px",
        form: "400px",
        mailto: "128px",
        "wysiwyg-editor": "960px",
      },
    },
  },
  plugins: [
    plugin(function ({ addUtilities }) {
      const newUtilities = {
        ".h-viewport": {
          height: "calc(var(--vh, 1vh) * 100)",
        },
        ".safe-top": {
          paddingTop: "constant(safe-area-inset-top)",
          paddingTop: "env(safe-area-inset-top)",
        },
        ".safe-left": {
          paddingLeft: "constant(safe-area-inset-left)",
          paddingLeft: "env(safe-area-inset-left)",
        },
        ".safe-right": {
          paddingRight: "constant(safe-area-inset-right)",
          paddingRight: "env(safe-area-inset-right)",
        },
        ".safe-bottom": {
          paddingBottom: "constant(safe-area-inset-bottom)",
          paddingBottom: "env(safe-area-inset-bottom)",
        },
        ".scrollbar-hidden": {
          "-ms-overflow-style": "none" /* IE and Edge */,
          "scrollbar-width": "none" /* Firefox */,
        },
        ".scrollbar-hidden::-webkit-scrollbar": {
          display: "none" /* Chrome, Safari and Opera */,
        },
      };
      addUtilities(newUtilities);
    }),
  ],
};
