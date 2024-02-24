import { Controller } from "@hotwired/stimulus";
import { computePosition, shift } from "@floating-ui/dom";

export default class DropdownController extends Controller {
  static targets = ["menu", "toggleButton"];
  static values = {
    placement: String,
  };

  initailized = false;

  connect() {
    document.addEventListener("keydown", this.onEscapePressed.bind(this));
    document.addEventListener("click", this.onClickOutside.bind(this));
  }

  disconnect() {
    document.removeEventListener("keydown", this.onEscapePressed.bind(this));
    document.removeEventListener("click", this.onClickOutside.bind(this));
  }

  toggle() {
    if (!this.initailized) {
      computePosition(this.toggleButtonTarget, this.menuTarget, {
        placement: this.placementValue || "bottom",
        middleware: [
          shift({
            crossAxis: true,
          }),
        ],
      }).then(({ x, y }) => {
        Object.assign(this.menuTarget.style, {
          left: `${x}px`,
          top: `${y}px`,
        });
      });
    }

    this.menuTarget.classList.toggle("show");
  }

  close() {
    this.menuTarget.classList.remove("show");
  }

  onEscapePressed(e) {
    if (e.key == "Escape") {
      this.close();
    }
  }

  onClickOutside(e) {
    if (
      !this.element.contains(e.target) ||
      e.target.classList.contains("dropdown-item")
    ) {
      this.close();
    }
  }
}
