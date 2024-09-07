import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class SortableController extends Controller {
  connect() {
    this.sortable = new Sortable.create(this.element, {
      onEnd: (e) => {
        const liveView = document.querySelector("main");
        const event = new Event("lv:pushEvent");
        event.data = {
          event: "move_block",
          payload: {
            blockId: e.item.getAttribute("data-block-id"),
            destination: e.newIndex,
          },
        };

        liveView.dispatchEvent(event);
      },
    });
  }
}
