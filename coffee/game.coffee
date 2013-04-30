Entity = window.entities.Entity
Sentient = window.entities.Sentient
Player = window.entities.Player

window.requestAnimFrame = ((callback) ->
    window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
      window.setTimeout callback, 1000 / 60
  )()

$(window).ready ->
	window.game =
		box2Dworld: 0
		scale: 30
		current_level: 0
		current_level_background: 0
		current_level_style: 0
		current_level__background_style: 0
		game_area_position: [0,0]
		debugdraw: 0
		player: 0
		game_w: 800
		game_h: 600
		max_velocity: 10
		max_walk: 7
		min: 'max'
		backgrounds: 
			'background01.html': ['level01.html']
			'empty.html': ['level02.html'] #empty
		init: ()->
			$(window).keydown (e)->
				console.log e.keyCode
				if window.game.player
					window.game.player.keydown e
			$(window).keyup (e)->
				#console.log e.keyup
				if window.game.player
					window.game.player.keyup e

			$(window).mousedown (e)->
				x = e.clientX - window.game.game_area_position[0]
				x += window.game.player.x * window.game.scale - window.game.game_w/2
				x = x / window.game.scale

				y = e.clientY - window.game.game_area_position[1]
				y += window.game.player.y * window.game.scale - window.game.game_h/2
				y = y / window.game.scale

				console.log x, y

				window.game.getBodyAtPoint(x, y)


		swap_resources: ()->
			for child in $('#game_level img, #background img, #game_entities img')
				st = $(child).attr('src')
				st = st.split('/')
				st = st[ st.length-1]
				$(child).attr('src', './img/'+@min+'/'+st)

			$('#player .anim').css('background-image', 'url(./img/'+@min+'/sheet.png )')

			for ent in $('#game_level, #background, #game_entities').find('*')
				b = $(ent).css('border-image')
				if b not in ['none', '']
					console.log b
					b = b.split('(')[1]
					b = b.split(')')
					r = b[b.length-1]
					b = b[0]
					b = b.split('/')
					b = b[b.length-1]
					$(ent).css('border-image', 'url(./img/'+@min+'/'+b+') '+r )


		load_level: (name)->
			g_o = $('#game_level').offset()
			@game_area_position = [g_o.left, g_o.top]
			@static_objects = []
			@dynamic_objects = []
			$('#game_entities').html ''
			$('#background').html ''

			@current_level = name

			bg = 'empty.html'
			for key of @backgrounds
				if name in @backgrounds[key]
					bg = key
			$('#game_level').hide()
			$.get './levels/'+bg, (data)->

				temp = $('<div></div>')
				temp.html data
				if @current_level_background_style
					@current_level_background_style.detach()
					@current_level_background_style = 0
				style = temp.children('style')
				$('head').append style
				@current_level_background_style = style
				$('#background').html ''
				window.t = temp
				#console.log data
				for div in temp.children('div, img')
					#console.log '-- ', div
					$('#background').append $(div)


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
					for div in temp.children('div, img, p, h1')
						#console.log '-- ', div
						$('#game_level').append $(div)

					$('#game_level').imagesLoaded ()->
						$('#game_level').show()
						window.game.setup_level_physics()

						if window.game.min is 'min'
							window.game.swap_resources()

				


		insert_player: ()->
			if @player
				@player.element.detach()


			pel = $('<div id="player" class="player"><div class="anim"></div></div>')
			$('#game_entities').append pel
			pel.css
				left:650
				top:230
			@player = new Player(pel[0], 1)

			@dynamic_objects.push @player

		contact_add: (point)->
			ab = window.game.get_contact_entities point
			if ab[0].dynamic
				ab[0].contact_add ab[1], point
			if ab[1].dynamic
				ab[1].contact_add ab[0], point
		contact_begin: (point)->
			ab = window.game.get_contact_entities point
			if ab[0].dynamic
				ab[0].contact_begin ab[1], point
			if ab[1].dynamic
				ab[1].contact_begin ab[0], point
		contact_persist: (point)->
			ab = window.game.get_contact_entities point
			if ab[0].dynamic
				ab[0].contact_persist ab[1], point
			if ab[1].dynamic
				ab[1].contact_persist ab[0], point
		contact_remove: (point)->
			ab = window.game.get_contact_entities point
			if ab[0].dynamic
				ab[0].contact_remove ab[1], point
			if ab[1].dynamic
				ab[1].contact_remove ab[0], point

		get_contact_entities: (point)->
			A = point.m_fixtureA.m_body.GetUserData()
			B = point.m_fixtureB.m_body.GetUserData()
			return [A, B]


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

			@ContactListener = new Box2D.Dynamics.b2ContactListener()
			console.log @ContactListener
			@ContactListener.Add = @contact_add
			@ContactListener.BeginContact = @contact_begin
			@ContactListener.Persist = @contact_persist
			@ContactListener.EndContact = @contact_remove

			@box2Dworld.SetContactListener @ContactListener


			console.log @ContactListener

			for div in $('#game_level').children()
				if $(div).hasClass 'nocollide'
					n = 0
				else
					entity = new Entity(div)

					if $(div).hasClass 'dynamic'
						@dynamic_objects.push entity
						$(div).detach()
						$('#game_entities').append $(div)
					else
						@static_objects.push entity

				

			@insert_player()



			if @debugdraw
				debugDraw = new b2DebugDraw()
				debugDraw.SetSprite document.getElementById("game_area").getContext("2d")
				debugDraw.SetDrawScale @scale
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
			fixDef.friction = 1.2
			fixDef.restitution = 0.2
			bodyDef = new b2BodyDef
			if not dynamic
				bodyDef.type = b2Body.b2_staticBody
			else
				bodyDef.type = b2Body.b2_dynamicBody

			fixDef.shape = new b2PolygonShape
			fixDef.shape.SetAsBox w / @scale, h / @scale
			
			
			bodyDef.angle = angle
			bodyDef.position.Set x / @scale, y / @scale
			
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

			window.requestAnimFrame(window.game.update_world)

			for entity in window.game.dynamic_objects
				entity.pre_step_update()

			window.game.box2Dworld.Step( (1 / 30), 20, 20 )
			if window.game.debugdraw

				window.game.box2Dworld.DrawDebugData()
			window.game.box2Dworld.ClearForces()

			for entity in window.game.dynamic_objects
				entity.update()

			window.game.move_layers()

		getBodyAtPoint: (x,y)->
			b2Vec2 = Box2D.Common.Math.b2Vec2
			b2AABB = Box2D.Collision.b2AABB
			entities = []
			getBodyCB = (fixture) ->
				if fixture.m_body.m_userData
					entities.push fixture.m_body.m_userData
					return true
				return true
				#unless fixture.GetBody().GetType() is b2Body.b2_staticBody
				#	if fixture.GetShape().TestPoint(fixture.GetBody().GetTransform(), window.mousePVec)
				#		selectedBody = fixture.GetBody()
				#		return false
				#true
			
			window.mousePVec = new b2Vec2(x, y)
			aabb = new b2AABB()
			aabb.lowerBound.Set x - 0.001, y - 0.001
			aabb.upperBound.Set x + 0.001, y + 0.001
			# Query the world for overlapping shapes.
			selectedBody = null
			@box2Dworld.QueryAABB getBodyCB, aabb
			entities



		move_layers: ()->
			if @player
				


				x = @player.x * @scale - @game_w/2
				y = @player.y * @scale - @game_h/2
				g_o = $('#game_level').offset()
				#@game_area_position = [g_o.left+x, g_o.top+y]
				#console.log 'move layers, ', @player, x, y
				for layer, i in $('#background').children()
					$(layer).css
						'left':  (-x / i)*.4   #-(x-gp[0])
						'top':  (-y  / i)*.4  #-(y-gp[1])

				$('#game_level, #game_area, #game_entities').css
					'left':  (-x )
					'top':  (-y  )
				#@game_area_position[0]
				#$('#background, #game_level, #game_area').css
				#	'left': -x
				#	'top': -y



	window.game.init()
	window.game.load_level 'level05.html'
	window.game.update_world()