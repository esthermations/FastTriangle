import
  aglet,
  aglet/uniform,
  aglet/window,
  aglet/window/glfw,
  glm/mat_transform,
  Obj,
  print

type
  Vertex = object
    position: Vec3f
    colour  : Vec3f

const
  testVertices = [
    Vertex(position: vec3f( 0.0,  0.5,  0.0),
           colour  : vec3f( 1.0,  0.0,  0.0),),
    Vertex(position: vec3f(-0.5, -0.5,  0.0),
           colour  : vec3f( 0.0,  1.0,  0.0),),
    Vertex(position: vec3f( 0.5, -0.5,  0.0),
           colour  : vec3f( 0.0,  0.0,  1.0),)
  ]

  vertSource = glsl(slurp("./shader.vert"))
  fragSource = glsl(slurp("./shader.frag"))

when isMainModule:

  setStdIoUnbuffered()

  var agl = initAglet()
  agl.initWindow()

  var win = agl.newWindowGlfw(
    1280, 720, "Hello!", winHints(resizable = false)
  )

  win.swapInterval = 1

  var
    objModel = parseObj(readFile("./barrel.obj"))
    program = newProgram[Vertex](win, vertSource, fragSource)
    mesh    = newMesh[Vertex](win, muStatic, dpTriangles)

  print objModel.pos.len

  var vertices: seq[Vertex]

  for i, vertex in objModel:
    let v = Vertex(position: vertex.pos, colour: vertex.nor)
    vertices.add v

  mesh.uploadVertices vertices
  #mesh.uploadVertices testVertices

  let drawParams = defaultDrawParams()

  let
    cameraPos = vec3f(0.0, 10.0, +10.0)
    targetPos = vec3f(0.0)
    up        = vec3f(0.0, 1.0, 0.0)
    view = lookAtRH[float32](cameraPos, targetPos, up)
    proj = perspectiveRH[float32]( 45.0, 16.0 / 9.0, 0.1, 100.0)

  while not win.closeRequested:
    win.pollEvents do (ev: InputEvent):
      discard

    var frame = win.render()
    frame.clearColor(rgba(0.2, 0.2, 1.0, 1.0))
    frame.draw(program, mesh, uniforms { view: view, proj: proj }, drawParams)
    frame.finish()
