physics_stuff = ()->
  
  
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
  world = new b2World(new b2Vec2(0, 10), true)
  fixDef = new b2FixtureDef
  fixDef.density = 1.0
  fixDef.friction = 0.5
  fixDef.restitution = 0.2
  bodyDef = new b2BodyDef
  bodyDef.type = b2Body.b2_staticBody
  fixDef.shape = new b2PolygonShape
  fixDef.shape.SetAsBox 20, 2
  bodyDef.position.Set 10, 400 / 30 + 1.8
  world.CreateBody(bodyDef).CreateFixture fixDef
  bodyDef.position.Set 10, -1.8
  world.CreateBody(bodyDef).CreateFixture fixDef
  fixDef.shape.SetAsBox 2, 14
  bodyDef.position.Set -1.8, 13
  world.CreateBody(bodyDef).CreateFixture fixDef
  bodyDef.position.Set 21.8, 13
  world.CreateBody(bodyDef).CreateFixture fixDef
  bodyDef.type = b2Body.b2_dynamicBody

  


  
  #mouse
  handleMouseMove = (e) ->
    window.mouseX = (e.clientX - window.canvasPosition.x) / 30
    window.mouseY = (e.clientY - window.canvasPosition.y) / 30
  getBodyAtMouse = ->
    window.mousePVec = new b2Vec2(window.mouseX, window.mouseY)
    aabb = new b2AABB()
    aabb.lowerBound.Set window.mouseX - 0.001, window.mouseY - 0.001
    aabb.upperBound.Set window.mouseX + 0.001, window.mouseY + 0.001
    # Query the world for overlapping shapes.
    selectedBody = null
    world.QueryAABB getBodyCB, aabb
    console.log "body at mouse: ", selectedBody
    selectedBody
  getBodyCB = (fixture) ->
    unless fixture.GetBody().GetType() is b2Body.b2_staticBody
      if fixture.GetShape().TestPoint(fixture.GetBody().GetTransform(), window.mousePVec)
        selectedBody = fixture.GetBody()
        return false
    true
  
  update = ->
    if window.isMouseDown and (not mouseJoint)

      body = getBodyAtMouse()
      if body
        md = new b2MouseJointDef()
        md.bodyA = world.GetGroundBody()
        md.bodyB = body
        md.target.Set mouseX, mouseY
        md.collideConnected = true
        md.maxForce = 300.0 * body.GetMass()
        mouseJoint = world.CreateJoint(md)
        body.SetAwake true
    if mouseJoint
      if isMouseDown
        mouseJoint.SetTarget new b2Vec2(mouseX, mouseY)
      else
        world.DestroyJoint mouseJoint
        mouseJoint = null
    world.Step 1 / 60, 10, 10
    world.DrawDebugData()
    world.ClearForces()
  
  getElementPosition = (element) ->
    elem = element
    tagname = ""
    x = 0
    y = 0
    while (typeof (elem) is "object") and (typeof (elem.tagName) isnt "undefined")
      y += elem.offsetTop
      x += elem.offsetLeft
      tagname = elem.tagName.toUpperCase()
      elem = 0  if tagname is "BODY"
      elem = elem.offsetParent  if typeof (elem.offsetParent) is "object"  if typeof (elem) is "object"
    x: x
    y: y


  debugDraw = new b2DebugDraw()
  debugDraw.SetSprite document.getElementById("game_area").getContext("2d")
  debugDraw.SetDrawScale 30.0
  debugDraw.SetFillAlpha 0.5
  debugDraw.SetLineThickness 1.0
  debugDraw.SetFlags b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit
  world.SetDebugDraw debugDraw
  window.setInterval update, 1000 / 60
  mouseX = undefined
  mouseY = undefined
  mousePVec = undefined
  isMouseDown = undefined
  selectedBody = undefined
  mouseJoint = undefined
  window.canvasPosition = getElementPosition(document.getElementById("game_area"))
  

  
  i = 0

  while i < 10
    if Math.random() > 0.5
      fixDef.shape = new b2PolygonShape
      fixDef.shape.SetAsBox Math.random() + 0.1, Math.random() + 0.1
    else
      fixDef.shape = new b2CircleShape(Math.random() + 0.1)
    bodyDef.position.x = Math.random() * 10
    bodyDef.position.y = Math.random() * 10
    world.CreateBody(bodyDef).CreateFixture fixDef
    ++i
  
  

 