// Generated by CoffeeScript 1.3.1
(function() {
  var Entity, Player, Sentient,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Entity = (function() {

    Entity.name = 'Entity';

    function Entity(element, dynamic) {
      if (dynamic == null) {
        dynamic = 0;
      }
      this.init();
      this.element = $(element);
      this.angle = window.game.get_element_rotation(element);
      if (!this.angle) {
        this.angle = 0;
      }
      if (dynamic === 1 || this.element.hasClass('dynamic')) {
        this.dynamic = 1;
      } else {
        this.dynamic = 0;
      }
      this.x = element.offsetLeft;
      this.y = element.offsetTop;
      this.w = this.element.outerWidth();
      this.h = this.element.outerHeight();
      this.construct_physical();
    }

    Entity.prototype.init = function() {
      this._cached_x = 0;
      this._cached_y = 0;
      this._cached_degrees = 0;
      this._show_rotation = 1;
      this._keep_upright = 0;
      return this.max_force = 0;
    };

    Entity.prototype.construct_physical = function() {
      this.Box_ref = window.game.create_body(this.x + (this.w / 2), this.y + (this.h / 2), this.w / 2, this.h / 2, this.angle, this.dynamic);
      this.Body = this.Box_ref.m_body;
      this.Body.SetUserData(this);
      return this.max_force = 300.0 * this.Body.GetMass();
    };

    Entity.prototype.contact_add = function(entity, point) {};

    Entity.prototype.contact_begin = function(entity, point) {};

    Entity.prototype.contact_persist = function(entity, point) {};

    Entity.prototype.contact_remove = function(entity, point) {};

    Entity.prototype.pre_step_update = function() {};

    Entity.prototype.update = function() {
      var degrees, eo, ep, gp, needs_pos_redraw, x, y;
      x = this.Body.m_xf.position.x - this.w / 2;
      y = this.Body.m_xf.position.y - this.h / 2;
      gp = window.game.game_area_position;
      eo = $('#game_entities').offset();
      ep = [eo[0], eo[1]];
      needs_pos_redraw = 0;
      if (Math.abs(this._cached_x - x) >= 1) {
        this._cached_x = x;
        needs_pos_redraw = 1;
      }
      if (Math.abs(this._cached_y - y) >= 1) {
        this._cached_y = y;
        needs_pos_redraw = 1;
      }
      if (needs_pos_redraw) {
        if (this._show_rotation) {
          this.element.css('-webkit-transform', '');
        }
        this.element.css({
          left: x,
          top: y
        });
      }
      if (this._show_rotation) {
        degrees = this.Body.GetAngle() * (180 / Math.PI);
        if (Math.abs(this._cached_degrees - degrees) >= 1 || needs_pos_redraw) {
          this._cached_degrees = degrees;
          this.element.css('-webkit-transform', 'rotate(' + degrees + 'deg)');
        }
      }
      if (this._keep_upright) {
        this.Body.m_sweep.a = 0;
      }
      return this.update_other();
    };

    Entity.prototype.update_other = function() {
      var n;
      return n = false;
    };

    return Entity;

  })();

  Sentient = (function(_super) {

    __extends(Sentient, _super);

    Sentient.name = 'Sentient';

    function Sentient() {
      return Sentient.__super__.constructor.apply(this, arguments);
    }

    Sentient.prototype.init = function() {
      this._cached_x = 0;
      this._cached_y = 0;
      this._cached_degrees = 0;
      this._show_rotation = 1;
      this._keep_upright = 0;
      return this.move_intent = [0, 0];
    };

    Sentient.prototype.apply_force = function() {
      var p, v, x, y;
      x = this.move_intent[0] * this.max_force;
      y = this.move_intent[1] * this.max_force;
      v = new Box2D.Common.Math.b2Vec2(x, y);
      p = this.Body.GetWorldCenter();
      return this.Body.ApplyForce(v, p);
    };

    Sentient.prototype.apply_impulse = function(x, y) {
      var p, v, vel;
      vel = this.Body.GetLinearVelocity();
      x = vel.x;
      y = y * this.max_force;
      v = new Box2D.Common.Math.b2Vec2(x, y);
      p = this.Body.GetWorldCenter();
      return this.Body.ApplyImpulse(v, p);
    };

    Sentient.prototype.update_other = function() {
      var contactlist;
      this.update_2();
      contactlist = this.Body.GetContactList();
      this.x = this.Body.GetWorldCenter().x;
      return this.y = this.Body.GetWorldCenter().y;
    };

    return Sentient;

  })(Entity);

  Player = (function(_super) {

    __extends(Player, _super);

    Player.name = 'Player';

    function Player() {
      return Player.__super__.constructor.apply(this, arguments);
    }

    Player.prototype.init = function() {
      this._cached_x = 0;
      this._cached_y = 0;
      this._cached_degrees = 0;
      this._show_rotation = 1;
      this._keep_upright = 1;
      this.keys = {};
      this.move_intent = [0, 0];
      this.contacts = 0;
      return this.can_jump = 0;
    };

    Player.prototype.contact_add = function(entity, point) {};

    Player.prototype.contact_begin = function(entity, point) {
      var c_normal, c_point, d, x, y;
      if (!this.bbb) {
        console.log(point);
        this.bbb = [];
      }
      c_point = point.m_manifold.m_localPoint;
      c_normal = point.m_manifold.m_localPlaneNormal;
      if (point.m_nodeB.other.m_userData === this) {
        this.contacts += 1;
        d = $('<div style="width:3px;height:3px;position:absolute;z-index:9999;background-color:red;"></div>');
        this.element.append(d);
        this.bbb.push(d);
        d.css({
          'margin-left': c_point.x + this.w / 2,
          'margin-top': c_point.y + this.h / 2
        });
        x = c_point.x + this.w / 2;
        y = c_point.y + this.h / 2;
        if (y >= this.h * .8) {
          this.can_jump = 1;
        }
      }
      if (point.m_next) {
        return this.contact_begin(entity, point.m_next);
      }
    };

    Player.prototype.contact_persist = function(entity, point) {};

    Player.prototype.contact_remove = function(entity, point) {
      if (point.m_nodeB.other.m_userData === this) {
        this.contacts -= 1;
      }
      if (point.m_next) {
        return this.contact_remove(entity, point.m_next);
      }
    };

    Player.prototype.pre_step_update = function() {
      var d, _i, _len, _ref;
      if (this.bbb) {
        _ref = this.bbb;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          $(d).detach();
        }
        return this.bbb = [];
      }
    };

    Player.prototype.update_2 = function() {
      if (!this.debug) {
        this.debug = $('<div class="debug"></div>');
        this.element.append(this.debug);
      }
      if (this.can_jump) {
        this.debug.html("JUMP " + this.contacts);
      } else {
        this.debug.html(" " + this.contacts);
      }
      this.can_jump = 0;
      this.move_intent = [0, 0];
      if (this.keys['up'] === 1) {
        this.move_intent[1] -= .4;
      } else {
        this.move_intent[1] = 0;
      }
      if (this.keys['right'] === 1) {
        this.move_intent[0] += .1;
      }
      if (this.keys['left'] === 1) {
        this.move_intent[0] += -.1;
      }
      return this.apply_force();
    };

    Player.prototype.keydown = function(e) {
      var _ref, _ref1, _ref2;
      if ((_ref = e.keyCode) === 32 || _ref === 87 || _ref === 38) {
        return this.keys['up'] = 1;
      } else if ((_ref1 = e.keyCode) === 68 || _ref1 === 39) {
        return this.keys['right'] = 1;
      } else if ((_ref2 = e.keyCode) === 65 || _ref2 === 37) {
        return this.keys['left'] = 1;
      }
    };

    Player.prototype.keyup = function(e) {
      var _ref, _ref1, _ref2;
      if ((_ref = e.keyCode) === 32 || _ref === 87 || _ref === 38) {
        return this.keys['up'] = 0;
      } else if ((_ref1 = e.keyCode) === 68 || _ref1 === 39) {
        return this.keys['right'] = 0;
      } else if ((_ref2 = e.keyCode) === 65 || _ref2 === 37) {
        return this.keys['left'] = 0;
      }
    };

    return Player;

  })(Sentient);

  window.entities = {
    Entity: Entity,
    Sentient: Sentient,
    Player: Player
  };

}).call(this);