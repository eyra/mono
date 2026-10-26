import { PDFViewer } from "./pdf_viewer";
import { Viewport } from "./viewport";
import { SidePanel } from "./side_panel";
import { Toggle } from "./toggle";
import { Cell } from "./cell";
import { LiveContent, LiveField } from "./live_content";
import { Tab, TabBar, TabBarFit, TabContent, TabFooterItem } from "./tabbed";
import { Clipboard } from "./clipboard";
import { FeldsparApp } from "./feldspar_app";
import { FeldsparRecovery } from "./feldspar_recovery";
import { AuthCodeInput } from "./auth_code_input";
import { Wysiwyg } from "./wysiwyg";
import { AutoSubmit } from "./auto_submit";
import { ResetScroll } from "./reset_scroll";
import { FullscreenImage } from "./fullscreen_image";
import { Blurhash } from "./blurhash";
import { UserState } from "./user_state";

// Shared by app.js and storybook.js.
export const Hooks = {
  AuthCodeInput,
  Cell,
  Clipboard,
  FeldsparApp,
  FeldsparRecovery,
  LiveContent,
  LiveField,
  PDFViewer,
  SidePanel,
  Toggle,
  Tab,
  TabBar,
  TabBarFit,
  TabContent,
  TabFooterItem,
  Viewport,
  Wysiwyg,
  AutoSubmit,
  ResetScroll,
  FullscreenImage,
  Blurhash,
  UserState, // Deprecated: Use new user_state architecture (LiveSocket params + event bubbling)
};
