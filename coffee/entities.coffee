class Entity
	constructor: (element, dynamic=0)->
		@init()
		@element = $(element)
		@element.data('entity', @)
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
		@max_velocity = 10


	construct_physical: ()->
		@Box_ref = window.game.create_body(@x+(@w/2),@y+(@h/2),@w/2,@h/2, @angle, @dynamic)
		@w = @w/window.game.scale
		@h = @h/window.game.scale
		@Body = @Box_ref.m_body
		@Body.SetUserData @

		if @element.hasClass('trigger') or @element.hasClass( 'door')
			@trigger = 1
		if @element.hasClass( 'player')
			@is_player = 1
		if @trigger or @is_player
			@Body.m_fixtureList.m_filter.groupIndex = -2

		if @trigger
			console.log @element[0]

		@max_force = (300.0 * @Body.GetMass()) / window.game.scale


	contact_add: (entity, point)->
	contact_begin: (entity, point)->
	contact_persist: (entity, point)->
	contact_remove: (entity, point)->
	pre_step_update: ()->
	update: ()->
		x = @Body.m_xf.position.x - @w/2
		y = @Body.m_xf.position.y - @h/2

		@x = x
		@y = y

		gp = window.game.game_area_position
		eo = $('#game_entities').offset()
		ep = [eo[0], eo[1]]
		
		needs_pos_redraw = 0
		if Math.abs(@_cached_x - x) >= 1 / window.game.scale
			@_cached_x = x
			needs_pos_redraw = 1
		if Math.abs(@_cached_y - y) >= 1 / window.game.scale
			@_cached_y = y
			needs_pos_redraw = 1
		if needs_pos_redraw
			if @_show_rotation
				@element.css('-webkit-transform', '')
			@element.css
				left:x * window.game.scale # +gp[0]#  - ep[0]
				top:y * window.game.scale # +gp[1]#  - ep[1]

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

		

	apply_velocity: (x=0, y=0)->
		vel = @Body.GetLinearVelocity()
		max = window.game.max_walk
		x = x+vel.x
		y = y+vel.y

		if Math.abs(x) > max
			x *= (max / Math.abs(x))
		if Math.abs(y) > max
			y *= (max / Math.abs(y))

		v = new Box2D.Common.Math.b2Vec2(x,y)

		@Body.SetLinearVelocity( v )

		if @debug
			@debug.html parseInt(v.x)+', '+parseInt(v.y)+'  :  '+parseInt(v.Length()) + ' <br>Jump: ' + @can_jump

	apply_force: (x, y)->
		vel = @Body.GetLinearVelocity()




		x = x * @max_force
		y = y * @max_force
		
		#console.log @move_intent, @max_velocity
		#x = x + vel.x
		#y = y + vel.y

		#if Math.abs(x) > @max_velocity
		#	x *= (@max_velocity / Math.abs(x))
		#if Math.abs(y) > @max_velocity
		#	y *= (@max_velocity / Math.abs(y))

		v = new Box2D.Common.Math.b2Vec2(x,y)
		
		#vel.Add( v )

		#vel.Normalize()

		p = @Body.GetWorldCenter()
		#console.log x, y
		@Body.ApplyForce( v, p )
		#@Body.SetLinearVelocity( v )

		

			#@Body.m_linearVelocity.x = x
			#@Body.m_linearVelocity.y = y

	apply_impulse: (x, y)->
		vel = @Body.GetLinearVelocity()
		x = x * @max_force
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
	animations:
		wave:[[0,0],[1,0],[0,1],[1,1],[2,0],[3,0],[2,1],[4,0],[2,1],[3,1],[0,2],[1,2],[0,3],[2,2],[1,3],[3,2],[2,3],[4,2]] 

		idle:[[0,0],[0,0],[0,0],[0,0],[1,0],[1,0],[1,0],[1,0],[0,1],[0,1],[0,1],[0,1],[1,1],[1,1],[1,1],[1,1],[1,1],[1,1],
			[1,1],[0,1],[0,1],[0,1],[0,1],[1,0],[1,0],[1,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0]] 
		run:[[3, 3],[4, 3],[5, 0],[6, 0],[5, 1],[7, 0],[6, 1],[5, 2],[8, 0],[7, 1],[6, 2],[5, 3],[8, 1],[7, 2],[6, 3],[8, 2],[7, 3],[8, 3],[0, 4],[1, 4]] 
		jump:[[6,2],[6,2],[6,2],[6,2],[6,2],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1],[7,1]]
		flail: [[2, 4],[1, 5],[3, 4],[2, 5],[4, 4],[3, 5],
				 [4, 4],[2, 5],[3, 4],[1, 5],[2, 4]] 
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

		@frame = 0
		@anim = 'idle'
		@anim_speed = 30
		@lastframe = 0

	play: (anim)->
		if @anim isnt anim
			@frame = 0
			@lastframe = 0
			@anim = anim

	contact_add: (entity, point)->
		
	contact_begin: (entity, point)->
		worldmanifold = new Box2D.Collision.b2WorldManifold()
		point.GetWorldManifold( worldmanifold )
		@contacts += 1
		if not @bbb	
			console.log point
			console.log worldmanifold
			console.log @Body.GetLinearVelocity()
			@bbb = []
		j = 0
		head = 0
		
		for v in worldmanifold.m_points
			if v.x isnt 0 and v.y isnt 0
				#d = $('<div style="width:4px;height:4px;position:absolute;z-index:9999;background-color:red;"></div>')
				#$('#game_entities').append d
				#@bbb.push d
				#d.css
				#	left: v.x * window.game.scale - 2
				#	top: v.y * window.game.scale - 2
				if v.y <= @y+( @h/2 * .1)
					head = 1
				if v.y >= @y+( @h/2 * .8)
					j += .5


		if j and head is 0
			@jump_point = point
			@can_jump = 1


		
		
	contact_persist: (entity, point)->
		

	contact_remove: (entity, point)->
		if @jump_point
			if @jump_point is point
				@jump_point = 0

				#console.log "JUMP MATCH"

		contact = point

		if contact
			@contacts -= 1

	pre_step_update: ()->
		if @bbb
			for d in @bbb
				$(d).detach()
			@bbb = []

	update_2: ()->
		if @can_jump > 0
			if @jump_point is 0
				@can_jump -= .1

		@check_triggers()

		@move_intent = [0,0]

		mod = 1
		if @can_jump > 0
			if @keys['up'] is 1
				@move_intent[1] -= 10


			else
				@move_intent[1] = 0
			mod = 1

		run = 0
		if @keys['right'] is 1
			@move_intent[0] += mod
			run = 1
			if @element.children('.anim').hasClass('flip')
				@element.children('.anim').removeClass('flip')
		else if @keys['left'] is 1
			@move_intent[0] += -mod
			run = 1
			if not @element.children('.anim').hasClass('flip')
				@element.children('.anim').addClass('flip')


		if @can_jump > 0 and run is 1
			@play('run')
		else if @can_jump > 0 and run is 0
			@play('idle')
		else if run
			@play('jump')
		else
			@play('flail')


		@apply_force(0, @move_intent[1])
		@apply_velocity(@move_intent[0], 0)

		d = new Date()
		time = d.getTime()
		#console.log @animations[@anim].length, time, @lastframe
		if @animations[@anim].length > 0 and time > @lastframe + @anim_speed
			#console.log 'anim frame'
			@lastframe = time
			
			$('#player').children('.anim').css 'background-position', @animations[@anim][@frame][0] * -100 + 'px ' + @animations[@anim][@frame][1] * -128 + 'px ' 
			@frame += 1
			if @frame > @animations[@anim].length-1
				@frame = 0

		if window.game.last_level
			console.log 'last level'
			
			name = window.game.last_level.split('.')[0]
			window.game.last_level = 0
			door = $('#'+name)
			if door.length > 0
				console.log door[0]
				e = door.first().data('entity').Body.GetPosition()
				console.log e.x, e.y
				#v = new Box2D.Common.Math.b2Vec2(e.x,e.y)
				@Body.SetPosition( e )





	check_triggers: ()->
		found = window.game.getBodyAtPoint(@x+@w/2, @y+@h/2)
		note = ''
		@interact = 0
		for entity in found
			if entity.trigger
				note = '-press (x) to interact-'
				@interact = entity

		if @interact.element
			if @interact.element.hasClass('sign')
				if @interact.element.attr('sign')
					note = @interact.element.attr('sign')

		$('#info').html note



	use_trigger: ()->
		if @interact
			el = @interact.element
			if el.hasClass('door')
				id = el.attr('id')

				level = id+'.html'
				window.game.last_level = window.game.current_level
				window.game.load_level(level)

			if el.hasClass('action01')
				b = $('#bridge').first().data('entity')
				@destroy_entity b

			if el.hasClass('min')
				window.game.min = 'min'
				window.game.swap_resources()
				@destroy_entity @interact

				o = $('.action01').first().data('entity')
				@destroy_entity o
				

			if el.hasClass('max')
				window.game.min = 'max'
				window.game.swap_resources()
				@destroy_entity @interact

				o = $('.action01').first().data('entity')
				@destroy_entity o
				
	destroy_entity: (entity)->
		entity.element.detach()
		game.box2Dworld.DestroyBody( entity.Body  )
		if entity.dynamic
			list = game.dynamic_objects
		else
			list = game.static_objects
		idx = list.indexOf(entity)
		if idx isnt -1
			list.splice(idx, 1)


	keydown: (e)->
		if e.keyCode in [32, 87, 38]
			@keys['up'] = 1
		if e.keyCode in [68, 39]
			@keys['right'] = 1
		else if e.keyCode in [65, 37]
			@keys['left'] = 1

		if e.keyCode in [88]
			@use_trigger()
	keyup: (e)->
		if e.keyCode in [32, 87, 38]
			@keys['up'] = 0
		if e.keyCode in [68, 39]
			@keys['right'] = 0
		else if e.keyCode in [65, 37]
			@keys['left'] = 0

window.entities =
	Entity: Entity
	Sentient: Sentient
	Player: Player
				