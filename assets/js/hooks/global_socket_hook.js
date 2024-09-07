export default {
  mounted() {
    this.el.addEventListener(
      "lv:pushEvent",
      this.onPushEventHandler.bind(this)
    );
  },

  destroyed() {
    this.el.removeEventListener(
      "lv:pushEvent",
      this.onPushEventHandler.bind(this)
    );
  },

  onPushEventHandler(e) {
    const { event, payload } = e.data;
    this.pushEvent(event, payload);
  },
};
