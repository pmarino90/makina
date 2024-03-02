import { Controller } from "@hotwired/stimulus";
import { Terminal } from "@xterm/xterm";

export default class XtermController extends Controller {
  connect() {
    this.term = new Terminal({ disableStdin: true, cols: 80 });

    this.term.open(this.element);

    window.addEventListener("phx:log_update", this.handleLogUpdate.bind(this));
  }

  disconnect() {
    window.removeEventListener(
      "phx:log_update",
      this.handleLogUpdate.bind(this),
    );
  }

  handleLogUpdate(e) {
    this.term.write(e.detail.entry);
  }
}
