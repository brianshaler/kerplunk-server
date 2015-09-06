(function() {
  define(function(require, exports, module) {
    var _;
    _ = require('lodash');
    return module.exports = function(component) {
      var i, _i, _ref;
      for (i = _i = _ref = this.components.length - 1; _i >= 0; i = _i += -1) {
        if (this.components[i].component === component) {
          this.components.splice(i, 1);
        }
      }
      if (this.components.length === 0) {
        if (this.stop) {
          this.stop();
        }
        this.started = false;
        this.stop = null;
      }
      return this;
    };
  });

}).call(this);
