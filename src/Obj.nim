import aglet, strutils, sequtils

type
  ObjData = object
    pos*: seq[Vec3f]
    nor*: seq[Vec3f]
    txc*: seq[Vec2f]

  ObjVertex = tuple[pos, nor: Vec3f, txc: Vec2f]

iterator pairs*(obj: ObjData): (int, ObjVertex) =
  assert obj.pos.len == obj.nor.len
  assert obj.txc.len == obj.pos.len or obj.txc.len == 0
  let
    numVertices = obj.pos.len
    haveTexCoords = obj.txc.len == 0

  for i in 0 ..< numVertices:
    yield (i, (
      pos: obj.pos[i],
      nor: obj.nor[i],
      txc: (if haveTexCoords: obj.txc[i] else: vec2f(0.0))
    ))

iterator items*(obj: ObjData): ObjVertex =
  for (i, v) in obj.pairs():
    yield v

func toVec[N : static[int]](strs: seq[string]): Vec[N, float32] =
  assert strs.len == N
  for i in 0 ..< N:
    result.arr[i] = parseFloat(strs[i])

type ObjIndices = tuple[pos, nor, txc: int]
const objIndexNotSet = -1

func faceToIndices(restOfLine: seq[string]): seq[ObjIndices] =
  assert restOfLine.len in [3, 4], "We only support quads or triangles."
  for face in restOfLine:
    let indices = face.split("/").mapIt(it.parseInt()).mapIt(it - 1)
    assert indices.len in [2, 3]
    assert indices.allIt(it >= 0)

    let
      haveTexCoords = (indices.len == 3)
      posIndex = indices[0]
      norIndex = (if haveTexCoords: indices[2] else: indices[1])
      txcIndex = (if haveTexCoords: indices[1] else: objIndexNotSet)

    result.add (posIndex, norIndex, txcIndex)

func parseObj*(fileContents: string): ObjData =
  var
    uniquePos: seq[Vec3f]
    uniqueNor: seq[Vec3f]
    uniqueTxc: seq[Vec2f]

  for line in fileContents.splitLines():
    let splitLine = line.splitWhitespace()
    if splitLine.len == 0 or splitLine[0].startsWith("#"):
      continue

    let
      token = splitLine[0]
      restOfLine = splitLine[1 ..< splitLine.len]


    case token
    of "v" : uniquePos.add toVec[3](restOfLine)
    of "vn": uniqueNor.add toVec[3](restOfLine)
    of "vt": uniqueTxc.add toVec[2](restOfLine)
    of "f" :
      let indices = faceToIndices(restOfLine)

      template addVertex(triangle: ObjIndices): untyped =
        assert triangle.pos < uniquePos.len
        result.pos.add uniquePos[triangle.pos]
        assert triangle.nor < uniqueNor.len
        result.nor.add uniqueNor[triangle.nor]
        if triangle.txc != objIndexNotSet:
          assert triangle.txc < uniqueTxc.len
          result.txc.add uniqueTxc[triangle.txc]

      case restOfLine.len
      of 3:
        # Triangle
        for idx in indices:
          addVertex idx
      of 4:
        # Quad
        let
          a = indices[0]
          b = indices[1]
          c = indices[2]
          d = indices[3]

        addVertex a
        addVertex b
        addVertex c

        addVertex c
        addVertex d
        addVertex a
      else:
        # This should be caught by the assert in faceToIndices.
        assert false
    else:
      continue
