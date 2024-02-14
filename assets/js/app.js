import "../css/app.css";

import "phoenix_html";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { Application } from "@hotwired/stimulus";

import topbar from "../vendor/topbar";

import HotkeyController from "./controllers/hotkey_controller";
import DropdownController from "./controllers/dropdown_controller";
import SortableController from "./controllers/sortable_controller";
import ToastController from "./controllers/toast_controller";
import GlobalSocketHook from "./hooks/global_socket_hook";

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

// connect if there are any LiveViews on the page
liveSocket.connect();

const Stimulus = Application.start();

Stimulus.register("hotkey", HotkeyController);
Stimulus.register("dropdown", DropdownController);
Stimulus.register("sortable", SortableController);
Stimulus.register("rich-text", RichTextController);
Stimulus.register("toast", ToastController);
