import { Controller } from "@hotwired/stimulus";

export default class ToastController extends Controller {
  static targets = ["close"];
  static values = {
    hideAfter: Number,
  };

  connect() {
    if (this.hasHideAfterValue) {
      this.timer = setTimeout(() => {
        this.closeTarget.click();
      }, this.hideAfterValue * 1000);
    }
  }

  disconnect() {
    clearTimeout(this.timer);
  }
}
