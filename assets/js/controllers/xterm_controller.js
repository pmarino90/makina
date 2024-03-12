import { Controller } from "@hotwired/stimulus";
import { Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";

export default class XtermController extends Controller {
  connect() {
    const fitAddon = new FitAddon();

    this.term = new Terminal({ disableStdin: true, cols: 80 });

    this.term.loadAddon(fitAddon);
    this.term.open(this.element);

    fitAddon.fit();

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
