(function() {
  define(function(require, exports, module) {
    return module.exports = function(value) {
      var component, listener, obj, state, stateKey, _i, _j, _len, _len1, _ref, _ref1, _ref2;
      _ref = this.components;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        obj = _ref[_i];
        if (obj.stateKey) {
          component = obj.component, stateKey = obj.stateKey;
          if (component.setState) {
            state = {};
            state[stateKey] = value;
            component.setState(state);
          }
        }
      }
      if (((_ref1 = this.listeners['update']) != null ? _ref1.length : void 0) > 0) {
        _ref2 = this.listeners['update'];
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
          listener = _ref2[_j];
          listener(value);
        }
      }
      return this;
    };
  });

}).call(this);
