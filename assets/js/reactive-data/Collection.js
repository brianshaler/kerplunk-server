(function() {
  define(function(require, exports, module) {
    var Collection, Item, Repository, getId, init, _;
    _ = require('lodash');
    init = require('./init');
    Repository = require('./Repository');
    Item = require('./Item');
    getId = function(item, identifier) {
      if (typeof identifier === 'function') {
        return identifier(item);
      } else {
        return item[identifier];
      }
    };
    Collection = function() {
      this.items = [];
      this.start = (function(_this) {
        return function() {
          return _this.stop = _this.Repository.onItems(_this.filter, function(objs) {
            var item, newItem, newItemId, obj, objId, toRemove, updateIndex, updated, _i, _j, _k, _len, _len1, _len2;
            updated = false;
            if (_this.identifier) {
              toRemove = [];
              objs = _.uniq(objs, false, _this.identifier);
              for (_i = 0, _len = objs.length; _i < _len; _i++) {
                newItem = objs[_i];
                newItemId = getId(newItem, _this.identifier);
                updateIndex = _.findIndex(_this.items, function(existingItem) {
                  return getId(existingItem.value, _this.identifier) === newItemId;
                });
                if (updateIndex !== -1) {
                  updated = true;
                  toRemove.push(newItem);
                  _this.Repository.update(newItemId, newItem);
                }
              }
              for (_j = 0, _len1 = toRemove.length; _j < _len1; _j++) {
                newItem = toRemove[_j];
                _.remove(objs, newItem);
              }
            } else {
              objs = _.filter(objs, function(item) {
                var found;
                found = _.find(_this.items, function(existingItem) {
                  return existingItem === item;
                });
                return !found;
              });
              objs = _.uniq(objs);
            }
            for (_k = 0, _len2 = objs.length; _k < _len2; _k++) {
              obj = objs[_k];
              objId = getId(obj, _this.identifier);
              item = Item({
                key: objId
              });
              item.listen({});
              _this.items.push(item);
              _this.Repository.update(objId, obj);
            }
            if (objs.length === 0 && !updated) {
              return;
            }
            return _this.update(_this.items);
          });
        };
      })(this);
      return this;
    };
    return module.exports = function(options) {
      return Collection.call(init(options));
    };
  });

}).call(this);
