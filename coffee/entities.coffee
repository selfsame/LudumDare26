class Entity
	constructor: (element, dynamic=0)->
		@init()
		@element = $(element)
		@angle = window.game.get_element_rotation element
		if not @angle
			@angle = 0

		if dynamic is 1 or @element.hasClass 'dynamic'
			@dynamic = 1
		else
			@dynamic = 0


		@x = element.offsetLeft
		@y = element.offsetTop

		@w = @element.outerWidth()
		@h = @element.outerHeight()

		@construct_physical()

	init: ()->
		@_cached_x = 0
		@_cached_y = 0
		@_cached_degrees = 0
		@_show_rotation = 1
		@_keep_upright = 0
		@max_force = 0


	construct_physical: ()->
		@Box_ref = window.game.create_body(@x+(@w/2),@y+(@h/2),@w/2,@h/2, @angle, @dynamic)
		@Body = @Box_ref.m_body
		@Body.SetUserData @

		@max_force = 300.0 * @Body.GetMass()

	contact_add: (entity, point)->
	contact_begin: (entity, point)->
	contact_persist: (entity, point)->
	contact_remove: (entity, point)->
	pre_step_update: ()->
	update: ()->
		x = @Body.m_xf.position.x - @w/2
		y = @Body.m_xf.position.y - @h/2

		gp = window.game.game_area_position
		eo = $('#game_entities').offset()
		ep = [eo[0], eo[1]]
		
		needs_pos_redraw = 0
		if Math.abs(@_cached_x - x) >= 1
			@_cached_x = x
			needs_pos_redraw = 1
		if Math.abs(@_cached_y - y) >= 1
			@_cached_y = y
			needs_pos_redraw = 1
		if needs_pos_redraw
			if @_show_rotation
				@element.css('-webkit-transform', '')
			@element.css
				left:x # +gp[0]#  - ep[0]
				top:y # +gp[1]#  - ep[1]

		if @_show_rotation
			degrees = @Body.GetAngle() * (180/Math.PI)
			if Math.abs(@_cached_degrees - degrees) >= 1 or needs_pos_redraw
				@_cached_degrees = degrees
				@element.css('-webkit-transform', 'rotate('+degrees+'deg)')

		if @_keep_upright
			@Body.m_sweep.a = 0

		@update_other()

	update_other: ()->
		n = false

class Sentient extends Entity
	init: ()->
		@_cached_x = 0
		@_cached_y = 0
		@_cached_degrees = 0
		@_show_rotation = 1
		@_keep_upright = 0
		@move_intent = [0,0]
		

	apply_force: ()->
		x = @move_intent[0] * @max_force
		y = @move_intent[1] * @max_force
		v = new Box2D.Common.Math.b2Vec2(x,y)
		p = @Body.GetWorldCenter()
		#console.log x, y
		@Body.ApplyForce( v, p )

		#@Body.m_linearVelocity.x = x
		#@Body.m_linearVelocity.y = y

	apply_impulse: (x, y)->
		vel = @Body.GetLinearVelocity()
		x = vel.x
		y = y * @max_force
		v = new Box2D.Common.Math.b2Vec2(x,y)

		
		#console.log vel.x
		#v.Set v.x + vel.x, v.y + vel.y

		p = @Body.GetWorldCenter()
		@Body.ApplyImpulse( v, p )

	

	update_other: ()->
		
		@update_2()
		contactlist = @Body.GetContactList()
		

		@x = @Body.GetWorldCenter().x
		@y = @Body.GetWorldCenter().y

		#console.log "has " +contactlist.length+" contacts ", contactlist



class Player extends Sentient
	init: ()->
		@_cached_x = 0
		@_cached_y = 0
		@_cached_degrees = 0
		@_show_rotation = 1
		@_keep_upright = 1
		@keys = {}
		@move_intent = [0,0]
		@contacts = 0
		@can_jump = 0


	contact_add: (entity, point)->
		
	contact_begin: (entity, point)->
		
		if not @bbb
			console.log point
			@bbb = []

		c_point = point.m_manifold.m_localPoint
		c_normal = point.m_manifold.m_localPlaneNormal

		if point.m_nodeB.other.m_userData is @
			@contacts += 1

			d = $('<div style="width:3px;height:3px;position:absolute;z-index:9999;background-color:red;"></div>')
			@element.append d
			@bbb.push d

		
			d.css
				'margin-left': c_point.x + @w/2
				'margin-top': c_point.y + @h/2

			x = c_point.x + @w/2
			y = c_point.y + @h/2

			if y >= @h * .8
				@can_jump = 1

		if point.m_next
			@contact_begin(entity, point.m_next)

		
		
	contact_persist: (entity, point)->
		

	contact_remove: (entity, point)->
		if point.m_nodeB.other.m_userData is @
			@contacts -= 1
		if point.m_next
			@contact_remove(entity, point.m_next)

	pre_step_update: ()->
		if @bbb
			for d in @bbb
				$(d).detach()
			@bbb = []

	update_2: ()->

		if not @debug
			@debug = $('<div class="debug"></div>')
			@element.append @debug
		if @can_jump
			@debug.html "JUMP " + @contacts
		else
			@debug.html " " + @contacts

		@can_jump = 0

		

		@move_intent = [0,0]

		if @keys['up'] is 1
			@move_intent[1] -= .4
		else
			@move_intent[1] = 0

		
		if @keys['right'] is 1
			@move_intent[0] += .1

		if @keys['left'] is 1
			@move_intent[0] += -.1

		@apply_force()
		

	keydown: (e)->
		if e.keyCode in [32, 87, 38]
			@keys['up'] = 1
		else if e.keyCode in [68, 39]
			@keys['right'] = 1
		else if e.keyCode in [65, 37]
			@keys['left'] = 1
	keyup: (e)->
		if e.keyCode in [32, 87, 38]
			@keys['up'] = 0
		else if e.keyCode in [68, 39]
			@keys['right'] = 0
		else if e.keyCode in [65, 37]
			@keys['left'] = 0

window.entities =
	Entity: Entity
	Sentient: Sentient
	Player: Player
				