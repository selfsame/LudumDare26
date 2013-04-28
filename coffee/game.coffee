$(window).ready ->
	window.game =
		box2Dworld: 0
		current_level: 0
		current_level_style: 0
		game_area_position: [0,0]
		debugdraw: 1
		player: 0
		init: ()->
			$(window).keydown (e)->
				console.log e.keyCode
				if window.game.player
					window.game.player.keydown e
			$(window).keyup (e)->
				console.log e.keyup
				if window.game.player
					window.game.player.keyup e




		load_level: (name)->
			g_o = $('#game_level').offset()
			@game_area_position = [g_o.left, g_o.top]
			@static_objects = []
			@dynamic_objects = []
			$.get './levels/'+name, (data)->

				temp = $('<div></div>')
				temp.html data
				if @current_level_style
					@current_level_style.detach()
					@current_level_style = 0
				style = temp.children('style')
				$('head').append style
				@current_level_style = style
				$('#game_level').html ''
				for div in temp.children('div')
					console.log '-- ', div
					$('#game_level').append $(div)
				window.game.setup_level_physics()

				


		insert_player: ()->
			pel = $('<div id="player"></div>')
			$('#centered').append pel
			pel.css
				left:10
				top:10
			@player = new Player(pel[0], 1)
			@dynamic_objects.push @player

		setup_level_physics: ()->
			b2Vec2 = Box2D.Common.Math.b2Vec2
			b2AABB = Box2D.Collision.b2AABB
			b2BodyDef = Box2D.Dynamics.b2BodyDef
			b2Body = Box2D.Dynamics.b2Body
			b2FixtureDef = Box2D.Dynamics.b2FixtureDef
			b2Fixture = Box2D.Dynamics.b2Fixture
			b2World = Box2D.Dynamics.b2World
			b2MassData = Box2D.Collision.Shapes.b2MassData
			b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
			b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
			b2DebugDraw = Box2D.Dynamics.b2DebugDraw
			b2MouseJointDef = Box2D.Dynamics.Joints.b2MouseJointDef
			@box2Dworld = new b2World(new b2Vec2(0, 20), true)
			world = @box2Dworld


			for div in $('#game_level').children()

				entity = new Entity(div)

				if $(div).hasClass 'dynamic'
					@dynamic_objects.push entity
				else
					@static_objects.push entity

				

			@insert_player()


			if @debugdraw
				debugDraw = new b2DebugDraw()
				debugDraw.SetSprite document.getElementById("game_area").getContext("2d")
				debugDraw.SetDrawScale 1.0
				debugDraw.SetFillAlpha 0.5
				debugDraw.SetLineThickness 1.0
				debugDraw.SetFlags b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit
				@box2Dworld.SetDebugDraw debugDraw

				world.DrawDebugData()

		create_body: (x,y,w,h, angle=0, dynamic=0)->
			console.log 'creating physics body'
			b2FixtureDef = Box2D.Dynamics.b2FixtureDef
			b2Fixture = Box2D.Dynamics.b2Fixture
			b2AABB = Box2D.Collision.b2AABB
			b2BodyDef = Box2D.Dynamics.b2BodyDef
			b2Body = Box2D.Dynamics.b2Body
			b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape

			#bodyDef.type = b2Body.b2_dynamicBody

			fixDef = new b2FixtureDef
			fixDef.density = 1.0
			fixDef.friction = 0.8
			fixDef.restitution = 0.2
			bodyDef = new b2BodyDef
			if not dynamic
				bodyDef.type = b2Body.b2_staticBody
			else
				bodyDef.type = b2Body.b2_dynamicBody

			fixDef.shape = new b2PolygonShape
			fixDef.shape.SetAsBox w, h
			
			
			bodyDef.angle = angle
			bodyDef.position.Set x, y
			
			@box2Dworld.CreateBody(bodyDef).CreateFixture fixDef

		get_element_rotation: (obj)->
			obj = $(obj)
			matrix = obj.css("-webkit-transform") or obj.css("-moz-transform") or obj.css("-ms-transform") or obj.css("-o-transform") or obj.css("transform")
			if matrix isnt "none"
			  values = matrix.split("(")[1].split(")")[0].split(",")
			  a = values[0]
			  b = values[1]
			  radians = Math.atan2(b, a) 
			else
			  radians = 0


		update_world: ()->

			requestAnimationFrame(window.game.update_world)
			window.game.box2Dworld.Step( (1 / 10), 10, 10 )
			if window.game.debugdraw

				window.game.box2Dworld.DrawDebugData()
			window.game.box2Dworld.ClearForces()

			for entity in window.game.dynamic_objects
				entity.update()



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

			@max_force = 300.0 * @Body.GetMass()

		update: ()->
			x = @Body.m_xf.position.x - @w/2
			y = @Body.m_xf.position.y - @h/2

			gp = window.game.game_area_position
			
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
				@element.offset( {left:x+gp[0], top:y+gp[1]} )

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
			p = @Body.GetPosition()
			@Body.ApplyForce( v, p )

		apply_impulse: (x, y)->
			x = x * @max_force
			y = y * @max_force
			v = new Box2D.Common.Math.b2Vec2(x,y)
			p = @Body.GetPosition()
			@Body.ApplyImpulse( v, p )

	class Player extends Sentient
		init: ()->
			@_cached_x = 0
			@_cached_y = 0
			@_cached_degrees = 0
			@_show_rotation = 1
			@_keep_upright = 1
			@keys = {}
			@move_intent = [0,0]

		update_other: ()->
			if @keys['up'] is 1
				@apply_impulse(0, -1)

			@move_intent[0] = 0
			if @keys['right'] is 1
				@move_intent[0] = .1

			if @keys['left'] is 1
				@move_intent[0] = -.1

			@apply_force()
			

		keydown: (e)->
			if e.keyCode in [87, 38]
				@keys['up'] = 1
			else if e.keyCode in [68, 39]
				@keys['right'] = 1
			else if e.keyCode in [65, 37]
				@keys['left'] = 1
		keyup: (e)->
			if e.keyCode in [87, 38]
				@keys['up'] = 0
			else if e.keyCode in [68, 39]
				@keys['right'] = 0
			else if e.keyCode in [65, 37]
				@keys['left'] = 0
				




	window.game.init()
	window.game.load_level 'level03.html'
	window.game.update_world()