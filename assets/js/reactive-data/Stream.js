(function() {
  define(function(require, exports, module) {
    var Repository, Stream, init;
    init = require('./init');
    Repository = require('./Repository');
    Stream = function(individual) {
      var fn, onItem;
      if (individual == null) {
        individual = true;
      }
      this.items = [];
      onItem = (function(_this) {
        return function(itemOrItems) {
          var item, _i, _len;
          if (individual) {
            _this.items.push(itemOrItems);
          } else {
            for (_i = 0, _len = itemOrItems.length; _i < _len; _i++) {
              item = itemOrItems[_i];
              _this.items.push(item);
            }
          }
          return _this.update(_this.items);
        };
      })(this);
      fn = individual ? this.Repository.onItem : this.Repository.onItems;
      this.start = (function(_this) {
        return function() {
          return _this.stop = fn(_this.filter, onItem);
        };
      })(this);
      return this;
    };
    return module.exports = function(options) {
      return Stream.call(init(options));
    };
  });

}).call(this);
