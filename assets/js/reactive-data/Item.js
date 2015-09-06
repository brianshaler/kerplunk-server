(function() {
  define(function(require, exports, module) {
    var Item, Repository, init;
    init = require('./init');
    Repository = require('./Repository');
    Item = function() {
      if (this.value == null) {
        this.value = null;
      }
      this.save = (function(_this) {
        return function(value) {
          return _this.Repository.update(_this.key, value);
        };
      })(this);
      this.start = (function(_this) {
        return function() {
          return _this.stop = _this.Repository.subscribe(_this.key, function(value) {
            _this.value = value;
            return _this.update(value);
          });
        };
      })(this);
      return this;
    };
    return module.exports = function(options) {
      return Item.call(init(options));
    };
  });

}).call(this);
