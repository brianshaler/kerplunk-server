(function() {
  define(function(require, exports, module) {
    return module.exports = function(component, stateKey) {
      this.components.push({
        component: component,
        stateKey: stateKey
      });
      if (this.components.length === 1) {
        if (this.start && !this.started) {
          this.started = true;
          this.start();
        }
      }
      return this;
    };
  });

}).call(this);
