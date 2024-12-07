//import "../css/app.css";

import "phoenix_html";
import "preline";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { Application } from "@hotwired/stimulus";

import topbar from "../vendor/topbar";

import GlobalSocketHook from "./hooks/global_socket_hook";
import XtermController from "./controllers/xterm_controller";
import HotkeyController from "./controllers/hotkey_controller";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    GlobalSocket: GlobalSocketHook,
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

window.addEventListener("phx:page-loading-stop", (_info) =>
  window.HSStaticMethods.autoInit(),
);

const Stimulus = Application.start();

Stimulus.register("xterm", XtermController);
Stimulus.register("hotkey", HotkeyController);

// connect if there are any LiveViews on the page
liveSocket.connect();
